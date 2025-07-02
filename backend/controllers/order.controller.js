import { Table } from "../models/table.model.js"
import { Order } from "../models/order.model.js"
import MenuItem from "../models/menuItem.model.js"
import TableSession from "../models/table-session.model.js"
import { User } from "../models/user.model.js"
import redisService, { getCache, setCache, deleteCache } from '../services/redis.service.js';
import { notifyKitchenAboutNewOrder, notifyKitchenAboutOrderUpdate, notifyWaiterAppsAboutReadyDineInOrder, WAITER_APP_ROOM_KEY,broadcastStockChange,notifyDeliveryDispatchAboutReadyOrder } from '../socket.js'
import logger from '../middlewares/logger.middleware.js'
import Ingredient from "../models/ingredients.model.js"
import mongoose from "mongoose"
import { Reservation } from "../models/reservation.model.js";
import { Rating } from "../models/rating.model.js"
// Define cache keys
const KITCHEN_ORDERS_CACHE = 'kitchen:active_orders'
const COMPLETED_ORDERS_CACHE = 'kitchen:completed_orders'
const WAITER_READY_ORDERS_CACHE = 'waiter:ready_dine_in_orders';
const WAITER_SERVED_DINE_IN_ORDERS_CACHE = 'waiter:served_dine_in_orders';
const PENDING_READY_ORDERS_CACHE = 'orders:pending_ready';
const SERVED_ORDERS_CACHE = 'orders:served';
const ALL_ORDERS_CACHE = 'orders:all_simplified';
const DELIVERED_ORDERS_CACHE = 'orders:delivered';
// Add cache key constants
const ORDER_DETAILS_CACHE_PREFIX = 'order:details:';
const USER_ORDERS_CACHE_PREFIX = 'order:user:';
const SESSION_ORDERS_CACHE_PREFIX = 'order:session:';
const RATINGS_CACHE_PREFIX = 'order:ratings:';

// Cache expiration times (in seconds)
const ORDER_DETAILS_CACHE_EXPIRATION = 3600; // 1 hour
const USER_ORDERS_CACHE_EXPIRATION = 1800; // 30 minutes
const SESSION_ORDERS_CACHE_EXPIRATION = 1800;

const PENDING_READY_ORDERS_CACHE_EXPIRATION = 30; // 30 seconds
const SERVED_ORDERS_CACHE_EXPIRATION = 60; // 60 seconds
// Create a new order
const ALL_ORDERS_CACHE_EXPIRATION = 300; // 5 minutes
const DELIVERED_ORDERS_CACHE_EXPIRATION = 120; // 2 minutes, adjust as needed


// Create a new order
function convertToStockUnit(recipeQuantity, recipeUnit, stockUnit, ingredientNameForLog) {
    if (!recipeUnit || !stockUnit) {
        logger.warn(`Unité de recette ou de stock manquante pour l'ingrédient ${ingredientNameForLog}. Conversion impossible.`);
        throw new Error(`Unité manquante pour la conversion pour l'ingrédient ${ingredientNameForLog}.`);
    }

    const rUnit = recipeUnit.toLowerCase().trim();
    const sUnit = stockUnit.toLowerCase().trim();

    if (rUnit === sUnit) {
        return recipeQuantity;
    }

    if (rUnit === 'g' && sUnit === 'kg') return recipeQuantity / 1000;
    if (rUnit === 'kg' && sUnit === 'g') return recipeQuantity * 1000;
    if (rUnit === 'ml' && sUnit === 'l') return recipeQuantity / 1000;
    if (rUnit === 'l' && sUnit === 'ml') return recipeQuantity * 1000;
    
    logger.error(`Conversion d'unité non supportée de '${rUnit}' vers '${sUnit}' pour l'ingrédient ${ingredientNameForLog}.`);
    throw new Error(`Conversion d'unité non supportée de ${rUnit} vers ${sUnit} pour l'ingrédient ${ingredientNameForLog}.`);
}


export const createOrder = async (req, res, next) => {
  const mongoSession = await mongoose.startSession();
  mongoSession.startTransaction();

  const criticalIngredientIds = new Set();
  const affectedIngredientIdsForBroadcast = new Set(); // NOUVEAU: Pour stocker les ID à diffuser

  try {
    const { userId, items, deliveryAddress, deliveryInstructions, paymentMethod, sessionId, tableId, orderType, deviceId } =
      req.body;

    if (!items || !items.length || !orderType) {
      await mongoSession.abortTransaction();
      mongoSession.endSession();
      return res.status(400).json({ message: "Items and order type are required" });
    }
    if (orderType === 'Dine In' && !tableId && !deviceId) {
      await mongoSession.abortTransaction();
      mongoSession.endSession();
      return res.status(400).json({ message: "Table ID or Device ID is required for Dine In orders" });
    }
    
    if (userId) {
      const user = await User.findById(userId).session(mongoSession);
      if (!user) {
        await mongoSession.abortTransaction();
        mongoSession.endSession();
        return res.status(404).json({ message: "User not found" });
      }
    }

    let subtotal = 0;
    const orderItems = [];
    // const potentiallyUnavailableMenuItemIds = new Set(); // Ancienne logique, remplacée/fusionnée

    for (const item of items) {
      const { menuItemId, quantity, specialInstructions } = item;

      if (!menuItemId || !quantity) {
        await mongoSession.abortTransaction();
        mongoSession.endSession();
        return res.status(400).json({ message: "Menu item ID and quantity are required for each item" });
      }

      // MODIFIÉ : s'assurer que 'ingredients.ingredient' est bien populé pour lire ingredientDoc.unit etc.
      const menuItem = await MenuItem.findById(menuItemId)
        .populate({ 
            path: 'ingredients.ingredient', 
            model: 'Ingredient' // Assurez-vous que le nom du modèle est correct
        })
        .session(mongoSession);

      if (!menuItem) {
        await mongoSession.abortTransaction();
        mongoSession.endSession();
        return res.status(404).json({ message: `Menu item with ID ${menuItemId} not found` });
      }

      if (!menuItem.isAvailable) {
        await mongoSession.abortTransaction();
        mongoSession.endSession();
        return res.status(400).json({ message: `Menu item ${menuItem.name} is not available` });
      }

      if (menuItem.ingredients && menuItem.ingredients.length > 0) {
        for (const recipeIngredient of menuItem.ingredients) {
          if (!recipeIngredient.ingredient || !recipeIngredient.ingredient._id) { // Vérification plus robuste
            logger.warn(`Ingrédient non trouvé ou non peuplé pour ${menuItem.name} (référence: ${recipeIngredient.ingredient}), vérifiez la consistance des données. Annulation de la commande.`);
            await mongoSession.abortTransaction();
            mongoSession.endSession();
            return res.status(500).json({ message: `Données d'ingrédient incohérentes pour ${menuItem.name}. Contactez l'administrateur.` });
          }

          const ingredientDoc = recipeIngredient.ingredient; // C'est maintenant le document Ingrédient peuplé
          const recipeQuantityPerDish = recipeIngredient.quantity;
          const recipeUnit = recipeIngredient.unit; // Unité de la recette
          const stockUnit = ingredientDoc.unit; // Unité de stock de l'ingrédient

          let quantityInStockUnit;
          try {
            quantityInStockUnit = convertToStockUnit(recipeQuantityPerDish, recipeUnit, stockUnit, ingredientDoc.name);
          } catch (conversionError) {
            logger.error(`Erreur de conversion d'unité pour ${ingredientDoc.name} dans ${menuItem.name}: ${conversionError.message}`);
            await mongoSession.abortTransaction();
            mongoSession.endSession();
            return res.status(400).json({ message: `Erreur de configuration d'unité pour l'ingrédient ${ingredientDoc.name}. ${conversionError.message}` });
          }
          
          const totalQuantityToDeductInStockUnit = quantityInStockUnit * quantity;

          // Il est préférable de récupérer l'ingrédient à nouveau pour s'assurer qu'on a la dernière version du stock avant la déduction,
          // surtout dans un environnement concurrentiel, mais pour la simplicité de la transaction, on utilise celui déjà peuplé.
          // Si le stock est insuffisant, on le note mais on traite quand même la commande comme dans votre logique.
          if (ingredientDoc.stock < totalQuantityToDeductInStockUnit) {
            logger.warn(`Stock insuffisant pour l'ingrédient ${ingredientDoc.name} (stock: ${ingredientDoc.stock} ${stockUnit}, requis: ${totalQuantityToDeductInStockUnit} ${stockUnit}) pour ${menuItem.name}, mais la commande est traitée.`);
          }
          
          ingredientDoc.stock -= totalQuantityToDeductInStockUnit;
          affectedIngredientIdsForBroadcast.add(ingredientDoc._id.toString()); // NOUVEAU: Ajouter pour la diffusion

          if (ingredientDoc.stock <= 0) {
            criticalIngredientIds.add(ingredientDoc._id.toString());
          } else if (ingredientDoc.lowStockThreshold > 0 && ingredientDoc.stock < ingredientDoc.lowStockThreshold) {
            logger.info(`ALERTE STOCK BAS: ${ingredientDoc.name} - stock actuel: ${ingredientDoc.stock} ${stockUnit}, seuil: ${ingredientDoc.lowStockThreshold} ${stockUnit}`);
            criticalIngredientIds.add(ingredientDoc._id.toString());
          }

          await ingredientDoc.save({ session: mongoSession });
        }
      }

      const itemPrice = menuItem.price;
      const itemTotal = itemPrice * quantity;
      subtotal += itemTotal;

      orderItems.push({
        menuItem: menuItemId, name: menuItem.name, price: itemPrice, image: menuItem.image,
        quantity, total: itemTotal, specialInstructions: specialInstructions || "",
        productId: `prod_${menuItem.name.replace(/\s+/g, '_')}`,
      });
    }

    const deliveryFee = orderType === "Delivery" ? 500 : 0; // Adaptez cette valeur
    const finalTotal = subtotal + deliveryFee;

    let tableDbId = null;
    if (tableId) {
      const table = await Table.findOne({ tableId: tableId }).session(mongoSession);
      if (table) {
        tableDbId = table._id;
      }
    }

    const newOrder = new Order({
      user: userId, items: orderItems, TableId: tableDbId, deviceId: deviceId,
      subtotal, deliveryFee, total: finalTotal, orderType, status: 'pending',
      paymentStatus: "pending", paymentMethod: paymentMethod || "cash",
      deliveryAddress: deliveryAddress || {
        address: orderType === "Dine In" ? "Dine-in" : "Pick up at restaurant",
        apartment: "", landmark: "", latitude: 0, longitude: 0,
      },
      deliveryInstructions: deliveryInstructions || "",
    });

    await newOrder.save({ session: mongoSession });

    if (sessionId) {
      const tableSessionDoc = await TableSession.findById(sessionId).session(mongoSession);
      if (!tableSessionDoc) {
        await mongoSession.abortTransaction();
        mongoSession.endSession();
        return res.status(404).json({ message: "Session not found" });
      }
      tableSessionDoc.orders.push(newOrder._id);
      await tableSessionDoc.save({ session: mongoSession });

      // MODIFIÉ: Utilisation de newOrder
      if (req.io && tableId) {
        // Préparez un payload plus complet si nécessaire pour la table
        const orderDataForTable = { 
            orderId: newOrder._id.toString(), 
            items: newOrder.items.map(i => ({name: i.name, quantity: i.quantity})),
            total: newOrder.total 
        };
        req.io.to(`table_${tableId}`).emit("new_order_for_table", orderDataForTable);
      }
    }

    await mongoSession.commitTransaction(); // Valider la transaction principale

    // --- DÉBUT DES NOUVELLES FONCTIONNALITÉS POST-TRANSACTION ---

    // 1. Mettre à jour la disponibilité des MenuItems (votre logique existante)
    if (criticalIngredientIds.size > 0) {
      logger.info(`Ingrédients avec stock critique détectés: ${Array.from(criticalIngredientIds).join(', ')}. Vérification de la disponibilité des MenuItems.`);
      const menuItemsToRecheck = await MenuItem.find({
        "ingredients.ingredient": { $in: Array.from(criticalIngredientIds) },
        "isAvailable": true 
      }).populate('ingredients.ingredient');

      for (const itemToUpdate of menuItemsToRecheck) {
        let shouldBeUnavailable = false;
        if (itemToUpdate.ingredients && itemToUpdate.ingredients.length > 0) {
          for (const recipeIng of itemToUpdate.ingredients) {
            if (!recipeIng.ingredient) {
              logger.warn(`Ingrédient manquant (ID ref: ${recipeIng.ingredient}) pour ${itemToUpdate.name} lors de la vérification de disponibilité post-commande. Marqué comme non disponible.`);
              shouldBeUnavailable = true; break;
            }
            let quantityNeededInStockUnit;
            try {
              quantityNeededInStockUnit = convertToStockUnit(recipeIng.quantity, recipeIng.unit, recipeIng.ingredient.unit, recipeIng.ingredient.name);
            } catch (conversionError) {
              logger.error(`Erreur de conversion d'unité post-commande pour ${recipeIng.ingredient.name} dans ${itemToUpdate.name}: ${conversionError.message}. Marqué comme non disponible.`);
              shouldBeUnavailable = true; break;
            }
            if (recipeIng.ingredient.stock < quantityNeededInStockUnit) {
              shouldBeUnavailable = true; break; 
            }
          }
        }
        if (shouldBeUnavailable && itemToUpdate.isAvailable) { 
          itemToUpdate.isAvailable = false;
          await itemToUpdate.save();
          logger.info(`MenuItem ${itemToUpdate.name} (ID: ${itemToUpdate._id}) marqué comme non disponible.`);
           // NOUVEAU: Peut-être émettre un événement de mise à jour de menu aux clients ici aussi
           // req.io.emit('menu_item_availability_changed', { menuItemId: itemToUpdate._id, isAvailable: false });
        }
      }
    }

    // 2. Diffuser les changements de stock aux Gérants et Simulateur IoT
    // Assurez-vous que req.io est disponible (passé via middleware ou importé)
    if (req.io) {
      for (const ingredientId of affectedIngredientIdsForBroadcast) {
        const ingredient = await Ingredient.findById(ingredientId);
        await broadcastStockChange(req.io, ingredient, `order_creation_${newOrder._id}`);
      }
    } else {
      logger.warn('req.io non disponible dans createOrder, impossible de diffuser les changements de stock via broadcastStockChange.');
    }

    // 3. Notifier la cuisine ET le four
    // Assurez-vous que 'newOrder' est populé avec les informations nécessaires pour la logique 'requiresOven'
    // dans notifyKitchenAboutNewOrder si vous avez une logique fine.
    // Sinon, `notifyKitchenAboutNewOrder` activera toujours le four comme configuré.
    if (req.io) {
      // Re-populer newOrder si notifyKitchenAboutNewOrder s'attend à des champs spécifiques (comme items.menuItem.requiresOven)
      const populatedOrderForSockets = await Order.findById(newOrder._id)
          .populate({ 
              path: 'items.menuItem', 
              model: 'MenuItem',
              // Si MenuItem a lui-même des références à peupler pour la logique requiresOven :
              // populate: { path: '...' } 
          })
          .populate({ path: 'TableId', model: 'Table' }); // Pour tableId dans la cuisine

      if (['pending', 'confirmed', 'preparing'].includes(populatedOrderForSockets.status)) { // Vérifiez le statut approprié
        await notifyKitchenAboutNewOrder(req.io, populatedOrderForSockets);
      }
    } else {
      logger.warn('req.io non available in createOrder, cannot send kitchen/oven notification.');
    }
    // --- FIN DES NOUVELLES FONCTIONNALITÉS POST-TRANSACTION ---

    mongoSession.endSession();
    res.status(201).json({ 
      success: true, 
      message: 'Order created successfully', 
      order: newOrder // Renvoyer la commande créée
    });

  } catch (error) {
    if (mongoSession.inTransaction()) {
      await mongoSession.abortTransaction();
    }
    mongoSession.endSession();

    logger.error('Error creating order:', error);
    if (error.name === 'ValidationError') {
      return res.status(400).json({ success: false, message: 'Validation Error', errors: error.errors });
    }
    if (error.message && error.message.includes("Conversion d'unité non supportée")) {
      return res.status(400).json({ success: false, message: error.message });
    }
    // Utilisez next(error) si vous avez un gestionnaire d'erreurs global Express
    // sinon, renvoyez une réponse d'erreur générique.
    return res.status(500).json({ success: false, message: 'Internal Server Error creating order' }); 
     next(error); // Si vous avez un error handler middleware
  }
};




// Get order details
export const getOrderDetails = async (req, res, next) => {
  try {
    const { orderId } = req.params;
    const cacheKey = `${ORDER_DETAILS_CACHE_PREFIX}${orderId}`;

    // Try to get from cache first
    if (redisService.isConnected && redisService.isConnected()) {
      const cachedOrder = await getCache(cacheKey);
      if (cachedOrder) {
        logger.info(`Cache hit for key: ${cacheKey}`);
        return res.status(200).json({ order: cachedOrder });
      }
      logger.info(`Cache miss for key: ${cacheKey}`);
    } else {
      logger.warn(`Redis not connected, skipping cache check for key: ${cacheKey}`);
    }

    const order = await Order.findById(orderId).populate({
      path: "items.menuItem",
      select: "name image price",
    });

    if (!order) {
      return res.status(404).json({ message: "Order not found" });
    }

    // Store in cache if Redis is connected
    if (redisService.isConnected && redisService.isConnected()) {
      await setCache(cacheKey, order, ORDER_DETAILS_CACHE_EXPIRATION);
      logger.info(`Cached data for key: ${cacheKey}`);
    }

    res.status(200).json({ order });
  } catch (error) {
    logger.error(`Error in getOrderDetails: ${error.message}`, error);
    next(error);
  }
};

// Update order status
export const updateOrderStatus = async (req, res, next) => {
  try {
    const { orderId } = req.params;
    const { status } = req.body;

    logger.info(`Updating status for order ${orderId}. Received body: ${JSON.stringify(req.body)}. Received status: ${status}`);

    // Validation
    if (!status) {
      logger.warn(`Order ${orderId}: Update failed - New status is required. Body was: ${JSON.stringify(req.body)}`);
      return res.status(400).json({ success: false, message: 'New status is required' });
    }
    const order = await Order.findById(orderId);
    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }

    const previousStatus = order.status;
    if (previousStatus === status) {
      return res.status(200).json({ 
        success: true, // Indicate success even if no change
        message: 'Order status is already ' + status, 
        order 
      });
    }

    // Update status and save
    order.status = status;
    order.updatedAt = new Date();
    
    // If status is changing to ready_for_pickup, set the readyAt timestamp
    //adde now 
    if (status === 'ready_for_pickup' && order.readyAt === undefined) {
      order.readyAt = new Date();
    }
    
    await order.save();

    // --- Notify Kitchen via Socket.IO --- 
    if (req.io) {
      const kitchenRelevantStatuses = ['pending', 'confirmed', 'preparing', 'ready_for_pickup', 'completed', 'cancelled'];
      const wasRelevant = kitchenRelevantStatuses.includes(previousStatus);
      const isRelevant = kitchenRelevantStatuses.includes(status);
      
      if (wasRelevant || isRelevant) {
        // Pass req.io to the notification function
        await notifyKitchenAboutOrderUpdate(req.io, order, previousStatus);
      }

      // --- Notify Waiter Apps if Dine In order is ready for pickup ---
      if (order.orderType === "Dine In" && order.status === "ready_for_pickup") {
        await notifyWaiterAppsAboutReadyDineInOrder(req.io, order);
      }
      // -------------------------------------------------------------

      // --- Notify Delivery Dispatcher if Delivery order is ready for pickup ---
      if (order.orderType === "Delivery" && order.status === "ready_for_pickup") {
        // Make sure to populate user details if not already populated, as notifyDeliveryDispatchAboutReadyOrder expects it.
        // The 'order' object here might already be populated depending on how it was fetched or saved before this point.
        // If 'order.user' is just an ID, notifyDeliveryDispatchAboutReadyOrder handles re-fetching.
        await notifyDeliveryDispatchAboutReadyOrder(req.io, order);
        logger.info(`Attempted to notify delivery dispatch for order ${order._id}`);
      }
      // --------------------------------------------------------------------

    } else {
      logger.warn('req.io not available in updateOrderStatus, cannot send socket notification.');
    }
    // ------------------------------------

    // --- Cache Invalidation ---
    if (redisService.isConnected()) {
      // 1. Invalidate order details cache
      const orderCacheKey = `${ORDER_DETAILS_CACHE_PREFIX}${orderId}`;
      await deleteCache(orderCacheKey);
      logger.info(`Invalidated cache for key: ${orderCacheKey} (status updated)`);
      
      // 2. Invalidate user orders cache if user ID is available
      if (order.user) {
        const userCacheKey = `${USER_ORDERS_CACHE_PREFIX}${order.user}`;
        await deleteCache(userCacheKey);
        logger.info(`Invalidated cache for key: ${userCacheKey} (order status updated)`);
      }
      
      // 3. Invalidate session orders cache if this order is part of a session
      const session = await TableSession.findOne({ orders: orderId });
      if (session) {
        const sessionCacheKey = `${SESSION_ORDERS_CACHE_PREFIX}${session._id}`;
        await deleteCache(sessionCacheKey);
        logger.info(`Invalidated cache for key: ${sessionCacheKey} (order status updated)`);
      }
      
      // 4. Invalidate kitchen orders caches based on status
      const completedStatuses = ['ready_for_pickup', 'completed', 'cancelled'];
      const activeStatuses = ['pending', 'confirmed', 'preparing'];
      
      // If status changed between active and completed, invalidate both caches
      if (
        (activeStatuses.includes(previousStatus) && completedStatuses.includes(status)) ||
        (completedStatuses.includes(previousStatus) && activeStatuses.includes(status))
      ) {
        await deleteCache(KITCHEN_ORDERS_CACHE);
        await deleteCache(COMPLETED_ORDERS_CACHE);
        logger.info(`Invalidated kitchen order caches (status changed between active/completed)`);
      }
      // If status changed within active statuses, invalidate active cache
      else if (activeStatuses.includes(previousStatus) && activeStatuses.includes(status)) {
        await deleteCache(KITCHEN_ORDERS_CACHE);
        logger.info(`Invalidated active kitchen orders cache (active status updated)`);
      }
      // If status changed within completed statuses, invalidate completed cache
      else if (completedStatuses.includes(previousStatus) && completedStatuses.includes(status)) {
        await deleteCache(COMPLETED_ORDERS_CACHE);
        logger.info(`Invalidated completed kitchen orders cache (completed status updated)`);
      }
    }
    // --- End Cache Invalidation ---
    
    res.status(200).json({ 
      success: true, 
      message: 'Order status updated successfully', 
      order 
    });

  } catch (error) {
    logger.error(`Error updating order status for ${req.params.orderId}:`, error);
    next(error);
  }
};

// Get orders by user
export const getOrdersByUser = async (req, res, next) => {
  try {
    const { userId } = req.params;
    const { status } = req.query;
    
    // Create a cache key that includes the status filter if present
    const cacheKey = status 
      ? `${USER_ORDERS_CACHE_PREFIX}${userId}:status:${status}`
      : `${USER_ORDERS_CACHE_PREFIX}${userId}`;

    // Try to get from cache first
    if (redisService.isConnected()) {
      const cachedOrders = await getCache(cacheKey);
      if (cachedOrders) {
        logger.info(`Cache hit for key: ${cacheKey}`);
        return res.status(200).json({ orders: cachedOrders });
      }
      logger.info(`Cache miss for key: ${cacheKey}`);
    } else {
      logger.warn(`Redis not connected, skipping cache check for key: ${cacheKey}`);
    }

    const query = { user: userId };
    if (status) {
      query.status = status;
    }

    const orders = await Order.find(query)
      .populate("restaurant", "name logo")
      .select("items subtotal total status createdAt")
      .sort({ createdAt: -1 });

    // Store in cache if Redis is connected
    if (redisService.isConnected()) {
      await setCache(cacheKey, orders, USER_ORDERS_CACHE_EXPIRATION);
      logger.info(`Cached data for key: ${cacheKey}`);
    }

    res.status(200).json({ orders });
  } catch (error) {
    logger.error(`Error in getOrdersByUser: ${error.message}`, error);
    next(error);
  }
};

// Get orders by session
export const getOrdersBySession = async (req, res, next) => {
  try {
    const { sessionId } = req.params;
    const cacheKey = `${SESSION_ORDERS_CACHE_PREFIX}${sessionId}`;

    // Try to get from cache first
    if (redisService.isConnected()) {
      const cachedSessionData = await getCache(cacheKey);
      if (cachedSessionData) {
        logger.info(`Cache hit for key: ${cacheKey}`);
        return res.status(200).json(cachedSessionData);
      }
      logger.info(`Cache miss for key: ${cacheKey}`);
    } else {
      logger.warn(`Redis not connected, skipping cache check for key: ${cacheKey}`);
    }

    const session = await TableSession.findById(sessionId);
    if (!session) {
      return res.status(404).json({ message: "Session not found" });
    }

    const orders = await Order.find({ _id: { $in: session.orders } })
      .populate({
        path: "items.menuItem",
        select: "name image isVeg",
      })
      .sort({ createdAt: -1 });

    // Calculate session total
    const sessionTotal = orders.reduce((total, order) => total + order.total, 0);

    const sessionData = {
      sessionId: session._id,
      tableId: session.tableId,
      status: session.status,
      startTime: session.startTime,
      endTime: session.endTime,
      orders,
      sessionTotal,
    };

    // Store in cache if Redis is connected
    if (redisService.isConnected()) {
      await setCache(cacheKey, sessionData, SESSION_ORDERS_CACHE_EXPIRATION);
      logger.info(`Cached data for key: ${cacheKey}`);
    }

    res.status(200).json(sessionData);
  } catch (error) {
    logger.error(`Error in getOrdersBySession: ${error.message}`, error);
    next(error);
  }
};

// Get active kitchen orders (for API polling / initial load)
export const getKitchenOrders = async (req, res, next) => {
  try {
    // Try to get from cache first
    const cachedOrders = await getCache(KITCHEN_ORDERS_CACHE)
    
    if (cachedOrders) {
      logger.info('Serving active kitchen orders from cache')
      return res.status(200).json({ orders: cachedOrders })
    }

    logger.info('Fetching active kitchen orders from DB')
    // Define active statuses for the kitchen view
    const activeStatuses = ["pending", "confirmed", "preparing"]
    const orders = await Order.find({
      status: { $in: activeStatuses },
    })
      .populate({
        path: "items.menuItem",
        select: "name image category", // Select only needed fields
      })
      // Consider populating TableId if needed for table number/name
      // .populate({ path: 'TableId', select: 'tableId' }) 
      .sort({ createdAt: 1 }) // Oldest first

    // Format orders for kitchen display
    const formattedOrders = orders.map(order => {
      // Calculate elapsed time in minutes (consider doing this on client)
      const elapsedMinutes = Math.floor((new Date() - order.createdAt) / (1000 * 60))
      const elapsedTimeString = `${Math.floor(elapsedMinutes / 60)}:${(elapsedMinutes % 60).toString().padStart(2, "0")}`

      return {
        id: order._id.toString(),
        orderNumber: order._id.toString().slice(-6).toUpperCase(),
        items: order.items.map((item) => ({
          name: item.name,
          quantity: item.quantity,
          specialInstructions: item.specialInstructions || '',
          category: item.menuItem?.category || null, // Use optional chaining
        })),
        orderType: order.orderType,
        // Use deviceId from order if TableId isn't populated/available
        tableId: order.TableId?.tableId || order.deviceId || null, 
        status: order.status,
        createdAt: order.createdAt,
        elapsedTime: elapsedTimeString, 
      }
    })

    // Cache the result for 30 seconds (short TTL for active orders)
    await setCache(KITCHEN_ORDERS_CACHE, formattedOrders, 30)

    res.status(200).json({ orders: formattedOrders })
  } catch (error) {
    logger.error('Error getting active kitchen orders:', error)
    next(error)
  }
}

// Get completed kitchen orders (for Past Orders screen)
export const getCompletedKitchenOrders = async (req, res, next) => {
  try {
    // Try to get from cache first
    const cachedOrders = await getCache(COMPLETED_ORDERS_CACHE)
    
    if (cachedOrders) {
      logger.info('Serving completed kitchen orders from cache')
      return res.status(200).json({ orders: cachedOrders })
    }

    logger.info('Fetching completed kitchen orders from DB')
    // Define completed statuses for this view
    const completedStatuses = ["ready_for_pickup", "completed", "cancelled"] 
    const limit = parseInt(req.query.limit || '50', 10) // Base 10

    const orders = await Order.find({
      status: { $in: completedStatuses },
    })
      .populate({
        path: "items.menuItem",
        select: "name category", // Select only needed fields
      })
      // .populate({ path: 'TableId', select: 'tableId' })
      .sort({ updatedAt: -1 }) // Most recently updated first
      .limit(limit)

    // Format orders for display
    const formattedOrders = orders.map(order => ({
      id: order._id.toString(),
      orderNumber: order._id.toString().slice(-6).toUpperCase(),
      items: order.items.map(item => ({
        name: item.name,
        quantity: item.quantity,
        specialInstructions: item.specialInstructions || '',
        category: item.menuItem?.category || null,
      })),
      orderType: order.orderType,
      tableId: order.TableId?.tableId || order.deviceId || null,
      status: order.status,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt, // Include updated time for completed orders
    }))

    // Cache the result for 60 seconds (longer TTL for completed)
    await setCache(COMPLETED_ORDERS_CACHE, formattedOrders, 60)

    res.status(200).json({ orders: formattedOrders })
  } catch (error) {
    logger.error('Error fetching completed kitchen orders:', error)
    next(error)
  }
}

// Update payment status
export const updatePaymentStatus = async (req, res, next) => {
  try {
    const { orderId } = req.params;
    const { paymentStatus, paymentId } = req.body;

    if (!paymentStatus) {
      return res.status(400).json({ message: "Payment status is required" });
    }

    const order = await Order.findById(orderId);

    if (!order) {
      return res.status(404).json({ message: "Order not found" });
    }

    // Update payment status
    order.paymentStatus = paymentStatus;
    if (paymentId) {
      order.paymentId = paymentId;
    }
    await order.save();

    // If this order is part of a session and all orders are paid, update session status
    let sessionUpdated = false;
    const session = await TableSession.findOne({ orders: orderId });
    if (session && session.status === "payment_pending") {
      const unpaidOrders = await Order.countDocuments({
        _id: { $in: session.orders },
        paymentStatus: { $ne: "paid" },
      });

      if (unpaidOrders === 0) {
        session.status = "closed";
        session.endTime = new Date();
        await session.save();
        sessionUpdated = true;

        // Update table status
        const table = await Table.findById(session.tableId);
        if (table) {
          table.status = "cleaning";
          table.currentSession = null;
          await table.save();
        }
      }
    }

    // --- Cache Invalidation ---
    if (redisService.isConnected()) {
      // 1. Invalidate order details cache
      const orderCacheKey = `${ORDER_DETAILS_CACHE_PREFIX}${orderId}`;
      await deleteCache(orderCacheKey);
      logger.info(`Invalidated cache for key: ${orderCacheKey} (payment status updated)`);
      
      // 2. Invalidate user orders cache if user ID is available
      if (order.user) {
        const userCacheKey = `${USER_ORDERS_CACHE_PREFIX}${order.user}`;
        await deleteCache(userCacheKey);
        logger.info(`Invalidated cache for key: ${userCacheKey} (payment status updated)`);
      }
      
      // 3. Invalidate session orders cache if this order is part of a session
      if (session) {
        const sessionCacheKey = `${SESSION_ORDERS_CACHE_PREFIX}${session._id}`;
        await deleteCache(sessionCacheKey);
        logger.info(`Invalidated cache for key: ${sessionCacheKey} (payment status updated)`);
      }
    }
    // --- End Cache Invalidation ---

    res.status(200).json({
      message: "Payment status updated successfully",
      order: {
        id: order._id,
        paymentStatus: order.paymentStatus,
        paymentId: order.paymentId,
      },
      sessionUpdated,
    });
  } catch (error) {
    logger.error(`Error in updatePaymentStatus: ${error.message}`, error);
    next(error);
  }
};
export const submitOrderRatings = async (req, res) => {
  try {
    const userId = req.user.id; // Depuis le middleware d'authentification
    const { orderId } = req.params; 
    const { itemRatings } = req.body; // Attendu comme [{ menuItemId: "...", ratingValue: N }, ...]

    if (!itemRatings || !Array.isArray(itemRatings) || itemRatings.length === 0) {
      return res.status(400).json({ message: "Aucune notation fournie." });
    }

    // 1. Valider la commande et les droits de l'utilisateur
    const order = await Order.findOne({ _id: orderId, user: userId });
    if (!order) {
       return res.status(403).json({ message: "Commande non trouvée ou accès non autorisé pour noter." });
    }
    // Optionnel: Permettre de noter uniquement les commandes avec un certain statut (ex: "delivered")
    if (order.status !== "delivered") { 
        return res.status(400).json({ message: "Vous ne pouvez noter que les commandes qui ont été livrées." });
    }

    const operationsForRatingCollection = [];
const itemRatingUpdatesForOrder = new Map(); // Semble être pour une autre logique (mise à jour de la commande ?)

for (const itemRating of itemRatings) { // itemRatings est l'array des notes envoyées par le client
  // Validation de base
  if (!itemRating.menuItemId || typeof itemRating.ratingValue !== 'number' || itemRating.ratingValue < 1 || itemRating.ratingValue > 5) {
    console.warn(`Notation invalide ou menuItemId manquant pour l'article: ${JSON.stringify(itemRating)}. Ignorée.`);
    continue; 
  }
  
  operationsForRatingCollection.push({
    updateOne: {
      filter: { user: userId, menuItem: itemRating.menuItemId },
      update: {
        $set: { // $set met à jour les champs ou les ajoute s'ils n'existent pas sur le document trouvé
          rating: itemRating.ratingValue,
          source: "manual_order", 
          // Les champs user et menuItem sont redondants dans $set SI l'objectif est SEULEMENT d'insérer
          // des nouveaux documents basés sur le filtre. Mais pour un upsert, si le document existe,
          // $set s'assure que ces valeurs sont bien celles attendues (au cas où elles auraient pu changer,
          // bien que pour user et menuItem dans un filtre, ce soit peu probable).
          // Pour une insertion (upsert où rien n'est trouvé), les champs du filtre sont utilisés comme base
          // et sont fusionnés avec ceux de $set.
          user: userId,
          menuItem: itemRating.menuItemId,
        },
        // Si vous voulez vous assurer que ces champs sont présents seulement à la création (insert)
        // et non ré-écrasés lors d'une mise à jour d'un document existant par $set,
        // vous pourriez utiliser $setOnInsert en plus de $set pour les champs user et menuItem:
        // $setOnInsert: { user: userId, menuItem: itemRating.menuItemId }
        // Mais votre $set actuel est correct et simple pour un upsert.
      },
      upsert: true, // Crucial: insère si le document n'existe pas, sinon met à jour.
    },
  });

  itemRatingUpdatesForOrder.set(itemRating.menuItemId.toString(), itemRating.ratingValue);
}

// Vérification si des opérations valides ont été préparées
// La condition itemRatingUpdatesForOrder.size === 0 est peut-être liée à la logique de mise à jour de la commande,
// pas directement à la sauvegarde dans la collection Rating.
if (operationsForRatingCollection.length === 0 /* && itemRatingUpdatesForOrder.size === 0 */) {
  // Si operationsForRatingCollection est vide, cela signifie qu'aucune notation valide n'a été traitée.
  // logger.warn("Aucune opération de notation valide à effectuer pour la collection Rating.");
  // return res.status(400).json({ message: "Aucune notation valide fournie." }); // Le return ici dépend du flux global
}

// Mettre à jour la collection globale Rating
if (operationsForRatingCollection.length > 0) {
  await Rating.bulkWrite(operationsForRatingCollection);
  logger.info("Notations globales enregistrées/mises à jour dans la collection Rating.");
}

    // 3. Mettre à jour les notes DANS le document Order lui-même
    let orderItemsUpdatedCount = 0;
    order.items.forEach(item => {
      // Assurez-vous que item.menuItem existe et n'est pas null
      if (item.menuItem) {
        const menuItemIdStr = item.menuItem.toString(); 
        if (itemRatingUpdatesForOrder.has(menuItemIdStr)) {
          // IMPORTANT: Assurez-vous que votre orderItemSchema dans order.model.js
          // a un champ comme 'userRating: { type: Number }'
          item.currentUserRating = itemRatingUpdatesForOrder.get(menuItemIdStr); 
          orderItemsUpdatedCount++;
        }
      }
    });

    if (orderItemsUpdatedCount > 0) {
      // Marquer le tableau 'items' comme modifié est crucial pour Mongoose
      // lorsque l'on modifie des éléments d'un tableau d'objets imbriqués.
      order.markModified('items'); 
      await order.save();
      logger.info(`${orderItemsUpdatedCount} article(s) noté(s) dans le document Order ID: ${orderId}`);
    } else {
      logger.info(`Aucun article à mettre à jour avec une note dans le document Order ID: ${orderId}. Cela peut arriver si les menuItemId ne correspondent pas ou si les notes sont invalides.`);
    }

    // --- Cache Invalidation ---
    if (redisService.isConnected && redisService.isConnected()) {
      // 1. Invalidate order details cache
      const orderCacheKey = `${ORDER_DETAILS_CACHE_PREFIX}${orderId}`;
      await deleteCache(orderCacheKey);
      logger.info(`Invalidated cache for key: ${orderCacheKey} (ratings updated)`);
      
      // 2. Invalidate user orders cache
      const userCacheKey = `${USER_ORDERS_CACHE_PREFIX}${userId}`;
      await deleteCache(userCacheKey);
      logger.info(`Invalidated cache for key: ${userCacheKey} (ratings updated)`);
      
      // 3. Invalidate ratings cache if you have one
      const ratingsCacheKey = `${RATINGS_CACHE_PREFIX}${userId}`;
      await deleteCache(ratingsCacheKey);
      logger.info(`Invalidated cache for key: ${ratingsCacheKey} (ratings updated)`);
    }
    // --- End Cache Invalidation ---

    res.status(200).json({ message: "Notations enregistrées avec succès." });

  } catch (error) {
    logger.error(`Error in submitOrderRatings: ${error.message}`, error);
    res.status(500).json({ message: "Erreur serveur.", error: error.message });
  }
};
export const getMyOrders = async (req, res) => {
  try {
    const userId = req.user._id; // Utilisateur extrait du token JWT

    const orders = await Order.find({ user: userId })
      .sort({ createdAt: -1 }) // Trier par date de création, les plus récentes en premier
      // Les items contiennent déjà les détails dénormalisés (nom, prix).
      // Si vous avez besoin de l'image du menuItem et qu'elle n'est pas dans order.items,
      // vous pourriez envisager de la stocker dans order.items lors de la création de la commande,
      // ou faire une population plus complexe ici si 'menuItem' dans 'items' est juste l'ID.
      // Exemple de population si 'items.menuItem' est un ObjectId et que vous voulez l'image:
      // .populate({
      //   path: 'items.menuItem', // Chemin vers le champ ObjectId dans le sous-document
      //   select: 'name image' // Sélectionner les champs 'name' et 'image' du modèle MenuItem
      // })
      // Cependant, votre schéma 'orderItemSchema' a déjà 'name' et 'price'.
      // Si 'image' est aussi dans 'orderItemSchema' (dénormalisé), pas besoin de populate pour ça.
      .exec();

    // if (!orders || orders.length === 0) { // Retourner une liste vide est souvent préférable à un 404
    //   return res.status(200).json([]);
    // }

    res.status(200).json(orders);

  } catch (error) {
    console.error("Erreur lors de la récupération de mes commandes:", error);
    res.status(500).json({ message: 'Erreur serveur lors de la récupération des commandes.', error: error.message });
  }
};


export const getReadyDineInOrdersForWaiter = async (req, res, next) => {
  try {
    const cachedOrders = await getCache(WAITER_READY_ORDERS_CACHE);
    if (cachedOrders) {
      logger.info('Serving ready Dine-In orders for waiter app from cache');
      return res.status(200).json({ orders: cachedOrders });
    }

    logger.info('Fetching ready Dine-In orders for waiter app from DB');
    const orders = await Order.find({
      status: "ready_for_pickup",
      orderType: "Dine In",
    })
      .populate({
        path: "items.menuItem",
        select: "name category",
      })
      .sort({ createdAt: 1 });

    const formattedOrders = orders.map(order => {
      // Make sure readyAt is set for all ready_for_pickup orders 
      // This handles legacy data that might not have readyAt set
      if (!order.readyAt && order.status === 'ready_for_pickup') {
        // For existing data without readyAt, we'll set it to now during the fetch
        // In a real system, you might want to use updatedAt as a fallback
        order.readyAt = new Date();
        order.save().catch(err => logger.error('Error saving readyAt time:', err));
      }

      return {
        id: order._id.toString(),
        orderNumber: order.orderNumber || order._id.toString().slice(-6).toUpperCase(),
        items: order.items.map(item => ({
          productId: item.productId || item.menuItem?._id?.toString() || `prod_${item.name}`.replace(/\s+/g, '_'),
          name: item.name,
          quantity: item.quantity,
          specialInstructions: item.specialInstructions || "",
          price: item.price,
          category: item.menuItem?.category || "N/A",
        })),
        orderType: order.orderType,
        tableId: order.TableId?.tableId || order.deviceId || 'N/A',
        status: order.status,
        createdAt: order.createdAt,
        updatedAt: order.updatedAt || new Date(),
        readyAt: order.readyAt || order.updatedAt || new Date(), // Include readyAt, fallback to updatedAt
        totalAmount: order.total,
        paymentStatus: order.paymentStatus,
      };
    });

    await setCache(WAITER_READY_ORDERS_CACHE, formattedOrders, 30);
    res.status(200).json({ orders: formattedOrders });
  } catch (error) {
    logger.error('Error getting ready Dine-In orders for waiter app:', error);
    next(error);
  }
};

export const markOrderAsServedByWaiter = async (req, res, next) => {
  try {
    const { orderId } = req.params;

    const order = await Order.findById(orderId);
    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }

    const previousStatus = order.status;
    if (previousStatus === 'served') {
      return res.status(200).json({
        success: true,
        message: 'Order is already marked as served',
        order,
      });
    }

    // Update status to served
    order.status = 'served';
    order.updatedAt = new Date();
    await order.save();

    // Notify Kitchen (optional, but good for consistency if kitchen tracks served orders)
    // if (req.io) {
    //   await notifyKitchenAboutOrderUpdate(req.io, order, previousStatus);
    // }
    
    // Notify other waiter apps that this order is now served.
    if (req.io) { // Ensure req.io is available
      // WAITER_APP_ROOM_KEY should be imported from socket.js or defined
      req.io.to(WAITER_APP_ROOM_KEY).emit('order_status_updated_to_served', { 
        orderId: order._id.toString(), 
        status: 'served',
        // It's good practice to send the updated order or enough details 
        // for clients to update their state without needing another fetch.
        order: order.toJSON() // Convert Mongoose document to plain JS object
      });
      logger.info(`Emitted 'order_status_updated_to_served' to ${WAITER_APP_ROOM_KEY} for order ${order._id}`);
    } else {
      logger.warn(`req.io not available in markOrderAsServedByWaiter, cannot emit 'order_status_updated_to_served'.`);
    }

    // --- Cache Invalidation (similar to updateOrderStatus) ---
    if (redisService.isConnected()) {
      const orderCacheKey = `${ORDER_DETAILS_CACHE_PREFIX}${orderId}`;
      await deleteCache(orderCacheKey);
      logger.info(`Invalidated cache for key: ${orderCacheKey} (marked as served)`);

      if (order.user) {
        const userCacheKey = `${USER_ORDERS_CACHE_PREFIX}${order.user}`;
        await deleteCache(userCacheKey);
        logger.info(`Invalidated cache for key: ${userCacheKey} (order marked as served)`);
      }

      const session = await TableSession.findOne({ orders: orderId });
     if (session) {
        const sessionCacheKey = `${SESSION_ORDERS_CACHE_PREFIX}${session._id}`;
        await deleteCache(sessionCacheKey);
        logger.info(`Invalidated cache for key: ${sessionCacheKey} (order marked as served)`);
      }
      
      // Invalidate kitchen caches as 'served' is a completed status
      await deleteCache(KITCHEN_ORDERS_CACHE); // Active orders
      await deleteCache(COMPLETED_ORDERS_CACHE); // Completed orders (as it will now appear here)
      logger.info(`Invalidated kitchen order caches (order ${orderId} marked as served)`);
      
      // Invalidate waiter ready orders cache
      await deleteCache(WAITER_READY_ORDERS_CACHE);
      logger.info(`Invalidated waiter ready orders cache (order ${orderId} marked as served)`);
      
      // Invalidate waiter served orders cache
      await deleteCache(WAITER_SERVED_DINE_IN_ORDERS_CACHE);
      logger.info(`Invalidated waiter SERVED orders cache (order ${orderId} marked as served)`);
    }
    // --- End Cache Invalidation ---

    logger.info(`Order ${orderId} marked as served by waiter. Previous status: ${previousStatus}`);
    res.status(200).json({
      success: true,
      message: 'Order marked as served successfully',
      order,
    });

  } catch (error) {
    logger.error(`Error marking order ${req.params.orderId} as served:`, error);
    next(error);
  }
};

// New function to get served Dine-In orders for the waiter app
export const getServedDineInOrdersForWaiter = async (req, res, next) => {
  try {
    const cachedOrders = await getCache(WAITER_SERVED_DINE_IN_ORDERS_CACHE);
    if (cachedOrders) {
      logger.info('Serving served Dine-In orders for waiter app from cache');
      return res.status(200).json({ orders: cachedOrders });
    }

    logger.info('Fetching served Dine-In orders for waiter app from DB');
    const orders = await Order.find({
      status: "served",
      orderType: "Dine In",
    })
      .populate({
        path: "items.menuItem",
        select: "name category",
      })
      // .populate({ path: 'TableId', select: 'tableId name' }) // Optionally populate table details
      .sort({ updatedAt: -1 }); // Sort by recently served

    const formattedOrders = orders.map(order => ({
      id: order._id.toString(),
      orderNumber: order.orderNumber || order._id.toString().slice(-6).toUpperCase(),
      items: order.items.map(item => ({
        productId: item.productId || item.menuItem?._id?.toString() || `prod_${item.name}`.replace(/\s+/g, '_'),
        name: item.name,
        quantity: item.quantity,
        specialInstructions: item.specialInstructions || "",
        price: item.price,
        category: item.menuItem?.category || "N/A",
      })),
      orderType: order.orderType,
      tableId: order.TableId?.tableId || order.deviceId || 'N/A',
      // tableName: order.TableId?.name || null, // If TableId is populated with name
      status: order.status,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt || new Date(),
      totalAmount: order.total,
      paymentStatus: order.paymentStatus,
    }));

    await setCache(WAITER_SERVED_DINE_IN_ORDERS_CACHE, formattedOrders, 120); // Cache for 2 minutes, adjust as needed
    res.status(200).json({ orders: formattedOrders });
  } catch (error) {
    logger.error('Error getting served Dine-In orders for waiter app:', error);
    next(error);
  }
};


export const getPendingAndReadyOrders = async (req, res, next) => {
    console.log(">>>> INSIDE getPendingAndReadyOrders controller function"); // ADD THIS LOG

  try {
    // Try to get from cache first
    if (redisService.isConnected()) {
      const cachedOrders = await getCache(PENDING_READY_ORDERS_CACHE);
      if (cachedOrders) {
        logger.info('Serving pending and ready orders from cache');
        return res.status(200).json({ orders: cachedOrders });
      }
      logger.info('Cache miss for pending and ready orders');
    } else {
      logger.warn('Redis not connected, skipping cache check for pending and ready orders');
    }

    logger.info('Fetching pending and ready orders from DB');
    const orders = await Order.find({
      status: { $in: ["pending", "ready_for_pickup"] }
    })
      .populate({
        path: "items.menuItem",
        select: "name category"
      })
      .populate({ path: 'user', select: 'fullName mobileNumber' })
      .populate({ path: 'TableId', select: 'tableId' })
      .sort({ createdAt: 1 }); // Oldest first

    const formattedOrders = orders.map(order => {
      const orderObject = order.toObject(); // Ensure we work with a plain object
      return {
        id: orderObject._id.toString(),
        orderNumber: orderObject.orderNumber || orderObject._id.toString().slice(-6).toUpperCase(),
        userName: orderObject.user ? orderObject.user.fullName : "N/A", // Use fullName
        userMobileNumber: orderObject.user ? orderObject.user.mobileNumber : null, // Added mobileNumber
        items: orderObject.items.map(item => ({
          productId: item.productId || (item.menuItem ? item.menuItem._id.toString() : `prod_${item.name}`.replace(/\s+/g, '_')),
          name: item.menuItem ? item.menuItem.name : item.name,
        quantity: item.quantity,
        specialInstructions: item.specialInstructions || "",
          price: item.menuItem ? item.menuItem.price : item.price,
          category: item.menuItem ? item.menuItem.category : "N/A",
      })),
        orderType: orderObject.orderType,
        tableId: orderObject.TableId ? orderObject.TableId.tableId : orderObject.deviceId || null,
        status: orderObject.status,
        createdAt: orderObject.createdAt,
        updatedAt: orderObject.updatedAt || new Date(),
        readyAt: orderObject.readyAt || null,
        totalAmount: orderObject.total,
        paymentStatus: orderObject.paymentStatus,
        paymentMethod: orderObject.paymentMethod || null,
        deliveryAddress: orderObject.deliveryAddress,
        subtotal: orderObject.subtotal,
        deliveryFee: orderObject.deliveryFee,
      };
    });

    // Cache the result if Redis is connected
    if (redisService.isConnected()) {
      await setCache(PENDING_READY_ORDERS_CACHE, formattedOrders, PENDING_READY_ORDERS_CACHE_EXPIRATION);
      logger.info(`Cached pending and ready orders for ${PENDING_READY_ORDERS_CACHE_EXPIRATION} seconds`);
    }

    res.status(200).json({ orders: formattedOrders });
  } catch (error) {
    logger.error('Error getting pending and ready orders:', error);
    next(error);
  }
};

// Get all orders with status served
export const getServedOrders = async (req, res, next) => {
  try {
    // Try to get from cache first
    if (redisService.isConnected()) {
      const cachedOrders = await getCache(SERVED_ORDERS_CACHE);
      if (cachedOrders) {
        logger.info('Serving served orders from cache');
        return res.status(200).json({ orders: cachedOrders });
      }
      logger.info('Cache miss for served orders');
    } else {
      logger.warn('Redis not connected, skipping cache check for served orders');
    }

    logger.info('Fetching served orders from DB');
    const orders = await Order.find({
      status: "served"
    })
      .populate({
        path: "items.menuItem",
        select: "name category"
      })
      .populate({ path: 'user', select: 'fullName mobileNumber' })
      .populate({ path: 'TableId', select: 'tableId' })
      .sort({ updatedAt: -1 }); // Most recently served first

    const formattedOrders = orders.map(order => {
      const orderObject = order.toObject(); // Ensure we work with a plain object
      return {
        id: orderObject._id.toString(),
        orderNumber: orderObject.orderNumber || orderObject._id.toString().slice(-6).toUpperCase(),
        userName: orderObject.user ? orderObject.user.fullName : "N/A", // Use fullName
        userMobileNumber: orderObject.user ? orderObject.user.mobileNumber : null, // Added mobileNumber
        items: orderObject.items.map(item => ({
          productId: item.productId || (item.menuItem ? item.menuItem._id.toString() : `prod_${item.name}`.replace(/\s+/g, '_')),
          name: item.menuItem ? item.menuItem.name : item.name,
        quantity: item.quantity,
        specialInstructions: item.specialInstructions || "",
          price: item.menuItem ? item.menuItem.price : item.price,
          category: item.menuItem ? item.menuItem.category : "N/A",
      })),
        orderType: orderObject.orderType,
        tableId: orderObject.TableId ? orderObject.TableId.tableId : orderObject.deviceId || null,
        status: orderObject.status,
        createdAt: orderObject.createdAt,
        updatedAt: orderObject.updatedAt || new Date(),
        totalAmount: orderObject.total,
        paymentStatus: orderObject.paymentStatus,
        paymentMethod: orderObject.paymentMethod || null,
        deliveryAddress: orderObject.deliveryAddress,
        servedAt: orderObject.updatedAt || new Date(), // Assuming servedAt is similar to updatedAt for served orders
        subtotal: orderObject.subtotal,
        deliveryFee: orderObject.deliveryFee,
        readyAt: orderObject.readyAt || null, // Added readyAt for consistency
      };
    });

    // Cache the result if Redis is connected
    if (redisService.isConnected()) {
      await setCache(SERVED_ORDERS_CACHE, formattedOrders, SERVED_ORDERS_CACHE_EXPIRATION);
      logger.info(`Cached served orders for ${SERVED_ORDERS_CACHE_EXPIRATION} seconds`);
    }

    res.status(200).json({ orders: formattedOrders });
  } catch (error) {
    logger.error('Error getting served orders:', error);
    next(error);
  }
};

export const getAllOrders = async (req, res, next) => {
  try {
    // Try to get from cache first
    if (redisService.isConnected()) {
      const cachedOrders = await getCache(ALL_ORDERS_CACHE);
      if (cachedOrders) {
        logger.info(`Cache hit for key: ${ALL_ORDERS_CACHE}`);
        return res.status(200).json({ orders: cachedOrders });
      }
      logger.info(`Cache miss for key: ${ALL_ORDERS_CACHE}`);
    } else {
      logger.warn(`Redis not connected, skipping cache check for key: ${ALL_ORDERS_CACHE}`);
    }

    // Get all orders with only the requested fields and populate items and item details
    const orders = await Order.find({})
      .populate("user", "name email") // Populate basic user info
      // Populate the 'items' array, and within each item, populate the 'menuItem' field with the 'name'
      .populate({
        path: 'items.menuItem', // Assuming the field in the order item is named 'menuItem'
        select: 'name'          // Select only the 'name' field from the populated menu item
      })
      .select("user items subtotal deliveryFee total orderType orderTime readyAt paymentStatus paymentMethod")
      .sort({ createdAt: -1 });

    // Store in cache if Redis is connected
    if (redisService.isConnected()) {
      await setCache(ALL_ORDERS_CACHE, orders, ALL_ORDERS_CACHE_EXPIRATION);
      logger.info(`Cached data for key: ${ALL_ORDERS_CACHE}`);
    }

    res.status(200).json({ orders });
  } catch (error) {
    logger.error(`Error in getAllOrders: ${error.message}`, error);
    next(error);
  }
};

// New function to get all orders with status delivered
export const getDeliveredOrders = async (req, res, next) => {
  try {
    // Try to get from cache first
    if (redisService.isConnected()) {
      const cachedOrders = await getCache(DELIVERED_ORDERS_CACHE);
      if (cachedOrders) {
        logger.info('Serving delivered orders from cache');
        return res.status(200).json({ orders: cachedOrders });
      }
      logger.info('Cache miss for delivered orders');
    } else {
      logger.warn('Redis not connected, skipping cache check for delivered orders');
    }

    logger.info('Fetching delivered orders from DB');
    const orders = await Order.find({
      status: "delivered" // Specifically fetching 'delivered' status
    })
      .populate({
        path: "items.menuItem",
        select: "name category"
      })
      .populate({ path: 'user', select: 'fullName mobileNumber' })
      .populate({ path: 'TableId', select: 'tableId' })
      .sort({ updatedAt: -1 }); // Most recently updated/delivered first

    const formattedOrders = orders.map(order => {
      const orderObject = order.toObject(); // Ensure we work with a plain object
      return {
        id: orderObject._id.toString(),
        orderNumber: orderObject.orderNumber || orderObject._id.toString().slice(-6).toUpperCase(),
        userName: orderObject.user ? orderObject.user.fullName : "N/A",
        userMobileNumber: orderObject.user ? orderObject.user.mobileNumber : null,
        items: orderObject.items.map(item => ({
          productId: item.productId || (item.menuItem ? item.menuItem._id.toString() : `prod_${item.name}`.replace(/\s+/g, '_')),
          name: item.menuItem ? item.menuItem.name : item.name,
          quantity: item.quantity,
          specialInstructions: item.specialInstructions || "",
          price: item.menuItem ? item.menuItem.price : item.price, // Assuming price is on menuItem if populated
          category: item.menuItem ? item.menuItem.category : "N/A",
        })),
        orderType: orderObject.orderType,
        tableId: orderObject.TableId ? orderObject.TableId.tableId : orderObject.deviceId || null,
        status: orderObject.status,
        createdAt: orderObject.createdAt,
        updatedAt: orderObject.updatedAt || new Date(), // Timestamp of when it was marked delivered
        totalAmount: orderObject.total,
        paymentStatus: orderObject.paymentStatus,
        paymentMethod: orderObject.paymentMethod || null,
        deliveryAddress: orderObject.deliveryAddress,
        subtotal: orderObject.subtotal,
        deliveryFee: orderObject.deliveryFee,
        readyAt: orderObject.readyAt || null,
        // You might want to add a specific 'deliveredAt' field to your Order model
        // and populate it when status changes to 'delivered'.
        // For now, 'updatedAt' would reflect the time of the last update (i.e., when it became 'delivered').
        deliveredAt: orderObject.status === 'delivered' ? orderObject.updatedAt : null 
      };
    });

    // Cache the result if Redis is connected
    if (redisService.isConnected()) {
      await setCache(DELIVERED_ORDERS_CACHE, formattedOrders, DELIVERED_ORDERS_CACHE_EXPIRATION);
      logger.info(`Cached delivered orders for ${DELIVERED_ORDERS_CACHE_EXPIRATION} seconds`);
    }

    res.status(200).json({ orders: formattedOrders });
  } catch (error) {
    logger.error('Error getting delivered orders:', error);
    next(error);
  }
};

// New controller function for a driver to accept a task
export const acceptDeliveryTask = async (req, res, next) => {
  try {
    const { orderId } = req.params;
    const order = await Order.findById(orderId);

    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }

    if (order.status !== 'ready_for_pickup') {
      return res.status(400).json({ 
        success: false, 
        message: `Order cannot be accepted. Current status is '${order.status}', expected 'ready_for_pickup'.` 
      });
    }

    const previousStatus = order.status;
    order.status = 'accepted';
    order.updatedAt = new Date();
    // Potentially set a driverId here if it's not already set, e.g.:
    // if (req.user && req.user.id) { // Assuming driver info is in req.user after some auth
    //   order.driverId = req.user.id; 
    // }
    await order.save();

    logger.info(`Order ${orderId} accepted by driver. Status changed from ${previousStatus} to ${order.status}.`);

    // --- Notify relevant parties (e.g., kitchen, customer) ---
    if (req.io) {
      // Notify kitchen if 'accepted' is a relevant status for them
      await notifyKitchenAboutOrderUpdate(req.io, order, previousStatus);
      // TODO: Add any other necessary notifications, e.g., to customer or admin panel
    }

    // --- Cache Invalidation ---
    if (redisService.isConnected()) {
      const orderCacheKey = `${ORDER_DETAILS_CACHE_PREFIX}${orderId}`;
      await deleteCache(orderCacheKey);
      logger.info(`Invalidated cache for key: ${orderCacheKey} (task accepted)`);

      if (order.user) {
        const userCacheKey = `${USER_ORDERS_CACHE_PREFIX}${order.user}`;
        await deleteCache(userCacheKey);
      }
      // Invalidate lists that might contain this order with its old status
      await deleteCache(KITCHEN_ORDERS_CACHE); // If it was in an active list
      await deleteCache(PENDING_READY_ORDERS_CACHE); // It was in ready_for_pickup
      logger.info('Invalidated relevant list caches for accepted task.');
    }

    res.status(200).json({ 
      success: true, 
      message: 'Order accepted successfully', 
      order 
    });

  } catch (error) {
    logger.error(`Error accepting task for order ${req.params.orderId}:`, error);
    next(error);
  }
};

// New controller function for a driver to confirm delivery
export const confirmDelivery = async (req, res, next) => {
  try {
    const { orderId } = req.params;
    const order = await Order.findById(orderId);

    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }

    // Typically, an order would be 'accepted' or perhaps 'out_for_delivery' before being 'delivered'
    if (order.status !== 'accepted') { 
      return res.status(400).json({ 
        success: false, 
        message: `Order cannot be marked delivered. Current status is '${order.status}', expected 'accepted'.` 
      });
    }

    const previousStatus = order.status;
    order.status = 'delivered';
    order.updatedAt = new Date();
    // It's good practice to have a dedicated 'deliveredAt' field.
    // If your Order schema has it, set it here:
    // order.deliveredAt = new Date(); 
    await order.save();

    logger.info(`Order ${orderId} marked as delivered. Status changed from ${previousStatus} to ${order.status}.`);

    // --- Notify relevant parties ---
    if (req.io) {
      // Notify kitchen if 'delivered' is relevant (might move to a completed/archived view)
      await notifyKitchenAboutOrderUpdate(req.io, order, previousStatus);
      // TODO: Notify customer of delivery confirmation
    }

    // --- Cache Invalidation ---
    if (redisService.isConnected()) {
      const orderCacheKey = `${ORDER_DETAILS_CACHE_PREFIX}${orderId}`;
      await deleteCache(orderCacheKey);
      logger.info(`Invalidated cache for key: ${orderCacheKey} (delivery confirmed)`);

      if (order.user) {
        const userCacheKey = `${USER_ORDERS_CACHE_PREFIX}${order.user}`;
        await deleteCache(userCacheKey);
      }
      // Invalidate lists that might contain this order with its old status
      await deleteCache(KITCHEN_ORDERS_CACHE); // If it was in an active list
      await deleteCache(COMPLETED_ORDERS_CACHE); // Now it is completed
      await deleteCache(DELIVERED_ORDERS_CACHE); // Explicitly invalidate the delivered list cache
      await deleteCache(SERVED_ORDERS_CACHE); // If 'delivered' implies 'served' or vice-versa in some contexts

      logger.info('Invalidated relevant list caches for confirmed delivery.');
    }

    res.status(200).json({ 
      success: true, 
      message: 'Delivery confirmed successfully', 
      order 
    });

  } catch (error) {
    logger.error(`Error confirming delivery for order ${req.params.orderId}:`, error);
    next(error);
  }
};