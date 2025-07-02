// controllers/tableChefController.js

import { Table } from '../models/table.model.js'; // Adaptez le chemin vers votre modèle Table
import TableSession from '../models/table-session.model.js'; // Adaptez le chemin
import { User } from '../models/user.model.js'; // Adaptez le chemin
import logger from '../middlewares/logger.middleware.js'; // Votre logger
import { Reservation } from '../models/reservation.model.js';
import { Order } from '../models/order.model.js';
import MenuItem from '../models/menuItem.model.js';

import Ingredient from '../models/ingredients.model.js'; // Assurez-vous que le chemin est correct

import { 
    notifyKitchenAboutNewOrder, 
    broadcastStockChange,
    broadcastTableUpdateToChefs // Assurez-vous que cette fonction est importée/disponible
} from '../socket.js'; // Ou le chemin vers votre fichier socket.js si différent
import mongoose from 'mongoose'; 
/**
 * @desc Get all tables with their current status and active session details
 * @route GET /api/chef/tables
 * @access Private (pour le Serveur-Chef)
 */
export const getAllTablesWithStatus = async (req, res) => {
  try {
    const tablesFromDB = await Table.find({})
      .populate({
        path: 'currentSession', // Chemin vers le champ de référence dans le modèle Table
        model: 'TableSession',   // Nom du modèle référencé
        populate: {            // Peuplement imbriqué
          path: 'clientId',      // Chemin vers le champ de référence dans TableSession
          model: 'User',         // Nom du modèle User
          select: '_id fullName email phoneNumber' // Sélectionnez les champs utilisateur nécessaires
        }
      })
      .lean(); // .lean() pour obtenir des objets JS simples, plus rapide pour la lecture

    const tablesForChef = tablesFromDB.map(table => {
      let sessionDetails = null;
      if (table.status === 'occupied' && table.currentSession) {
        const session = table.currentSession; // C'est maintenant l'objet session peuplé
        const client = session.clientId;   // C'est maintenant l'objet client peuplé

        sessionDetails = {
          sessionId: session._id?.toString(),
          customerId: client?._id?.toString(),
          customerName: client?.fullName,
          startTime: session.startTime?.toISOString(),
        };
      }

      return {
        _id: table._id.toString(),             // ObjectId de la Table Mongoose
        tableId: table.tableId,               // L'identifiant String unique de la tablette
        name: table.name || `Table ${table.tableId ? table.tableId.slice(-4) : table._id.toString().slice(-4)}`, // Si vous ajoutez un champ 'name' à table.model.js
        status: table.status,                 // "available", "occupied", "reserved", "cleaning"
        isActive: table.isActive || false,    // Statut d'activité de la tablette
        // currentSession: table.currentSession?._id?.toString(), // ID de la session Mongoose (optionnel si détails ci-dessous)
        
        // Champs dénormalisés pour le modèle Flutter TableModel.fromJson
        currentSessionId: sessionDetails?.sessionId,
        currentCustomerId: sessionDetails?.customerId,
        currentCustomerName: sessionDetails?.customerName,
        sessionStartTime: sessionDetails?.startTime,
      };
    });

    res.status(200).json({
      success: true,
      count: tablesForChef.length,
      tables: tablesForChef,
    });

  } catch (error) {
    logger.error(`Error in getAllTablesWithStatus: ${error.message}`);
    res.status(500).json({ success: false, message: "Erreur serveur lors de la récupération des tables." });
  }
};



export const verifyReservationByQR = async (req, res) => {
  const { reservationId } = req.params;

  if (!reservationId) {
    return res.status(400).json({ success: false, message: "L'ID de la réservation est requis." });
  }

  try {
    const reservation = await Reservation.findById(reservationId)
      .populate('userId', '_id fullName email phoneNumber') // Peuple les infos du client
      .populate('tableId', '_id tableId name status isActive') // Peuple les infos de la table Mongoose
      .populate({
        path: 'preSelectedMenu.menuItemId', // Peuple les détails de chaque plat dans le menu présélectionné
        model: 'MenuItem',
        select: '_id name price description category image' // Champs du MenuItem à renvoyer
      });

    if (!reservation) {
      return res.status(404).json({ success: false, message: "Réservation non trouvée." });
    }

    // --- Logique de Validation de la Réservation ---
    // 1. Vérifier le statut de la réservation
    if (reservation.status !== 'confirmed') {
      return res.status(400).json({ 
        success: false, 
        message: `Cette réservation n'est pas confirmée. Statut actuel: ${reservation.status}.` 
      });
    }

    // 2. Vérifier la date et l'heure
    const now = new Date();
    const reservationTime = new Date(reservation.reservationTime);
    
    // Vérifier si c'est le bon jour
    const isSameDay = now.getFullYear() === reservationTime.getFullYear() &&
                      now.getMonth() === reservationTime.getMonth() &&
                      now.getDate() === reservationTime.getDate();

    if (!isSameDay) {
      return res.status(400).json({ 
        success: false, 
        message: "La date de cette réservation ne correspond pas à aujourd'hui." 
      });
    }

    // Vérifier si l'heure n'est pas excessivement dépassée (ex: plus de 60 minutes de retard)
    // ou trop en avance (ex: plus de 2 heures avant)
    const timeDifferenceMinutes = (now.getTime() - reservationTime.getTime()) / (1000 * 60);
    const maxAllowedLateMinutes = 60; // Permettre jusqu'à 60 min de retard
    const maxAllowedEarlyMinutes = 600; // Permettre d'arriver jusqu'à 120 min en avance

    if (timeDifferenceMinutes > maxAllowedLateMinutes) {
      return res.status(400).json({ 
        success: false, 
        message: "L'heure de cette réservation est dépassée de plus de " + maxAllowedLateMinutes + " minutes." 
      });
    }
    if (timeDifferenceMinutes < -maxAllowedEarlyMinutes) {
         return res.status(400).json({ 
            success: false, 
            message: "Il est trop tôt pour cette réservation (plus de " + maxAllowedEarlyMinutes/60 + " heures avant)." 
        });
    }
    
    // --- Formatage des données pour la réponse ---
    // Le 'userId' est déjà peuplé avec les champs sélectionnés
    // Le 'tableId' (dans la réservation) est déjà peuplé
    // Les 'menuItemId' dans 'preSelectedMenu' sont déjà peuplés

    const reservationDetailsForChef = {
      _id: reservation._id.toString(),
      userId: reservation.userId ? { // Si l'utilisateur est peuplé
        _id: reservation.userId._id.toString(),
        fullName: reservation.userId.fullName,
        email: reservation.userId.email,
        phoneNumber: reservation.userId.phoneNumber
      } : null, // Ou juste reservation.userId.toString() si vous ne peuplez que l'ID
      customerName: reservation.userId?.fullName || 'Client Inconnu', // Pour le modèle Flutter
      tableId: reservation.tableId?._id.toString(), // ObjectId de la table Mongoose
      reservationTime: reservation.reservationTime.toISOString(),
      guests: reservation.guests,
      status: reservation.status,
      preSelectedMenu: reservation.preSelectedMenu.map(item => ({
        menuItemId: item.menuItemId ? { // Si le plat est peuplé
            _id: item.menuItemId._id.toString(),
            name: item.menuItemId.name,
            price: item.menuItemId.price,
            // Ajoutez d'autres champs de menuItem si nécessaire pour l'app Chef
        } : { _id: item.menuItemId?.toString() || null }, // Fallback si menuItemId n'est pas peuplé (juste l'ID)
        quantity: item.quantity,
        specialInstructions: item.specialInstructions
      })),
      specialRequests: reservation.specialRequests
    };
    
    // Détails de la table Mongoose associée (peut être null si la réservation n'a pas de tableId)
    let tableDetailsForChef = null;
    if (reservation.tableId) {
      tableDetailsForChef = {
        _id: reservation.tableId._id.toString(),
        tableId: reservation.tableId.tableId, // L'ID String de la tablette
        name: reservation.tableId.name || `Table ${reservation.tableId.tableId ? reservation.tableId.tableId.slice(-4) : reservation.tableId._id.toString().slice(-4)}`,
        status: reservation.tableId.status,
        isActive: reservation.tableId.isActive
      };
    }

    res.status(200).json({
      success: true,
      message: "Réservation valide.",
      reservation: reservationDetailsForChef,
      table: tableDetailsForChef // Informations sur la table Mongoose réservée
    });

  } catch (error) {
    logger.error(`Error in verifyReservationByQR for ID ${reservationId}: ${error.message}`);
    if (error.name === 'CastError') { // Si l'ID n'est pas un ObjectId Mongoose valide
        return res.status(400).json({ success: false, message: "Format de l'ID de réservation invalide." });
    }
    res.status(500).json({ success: false, message: "Erreur serveur lors de la vérification de la réservation." });
  }
};


// controllers/kitchenChefController.js (ou où vous placez cette logique)

// Nécessaire pour les sessions/transactions Mongoose

// Votre fonction convertToStockUnit (doit être accessible ici)
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


/**
 * @desc Notify kitchen of pre-ordered items from a validated reservation.
 * This will create an order and use logic similar to createOrder for stock and notifications.
 * @route POST /api/chef/kitchen/notify-preorder
 * @access Private (pour le Serveur-Chef)
 */
export const notifyKitchenOfPreOrder = async (req, res) => {
  const { reservationId, tableDisplayName, items: preOrderItemsPayload } = req.body;
  // preOrderItemsPayload est attendu comme: 
  // [{ menuItemId: "mongoId", name: "Nom Plat", quantity: 1, price: 1500 }, ...]

  if (!reservationId || !tableDisplayName || !preOrderItemsPayload || !Array.isArray(preOrderItemsPayload) || preOrderItemsPayload.length === 0) {
    return res.status(400).json({ success: false, message: "Données manquantes ou incorrectes (reservationId, tableDisplayName, items)." });
  }

  const io = req.io; // Assurez-vous que 'io' est attaché à 'req' via middleware
  const mongoSession = await mongoose.startSession();
  mongoSession.startTransaction();

  const affectedIngredientIdsForBroadcast = new Set();
  const criticalIngredientIds = new Set();

  try {
    const reservation = await Reservation.findById(reservationId)
      .populate('userId', '_id fullName') // Peuple pour avoir l'ID et le nom de l'utilisateur
      .populate('tableId') // Peuple la table Mongoose liée à la réservation
      .session(mongoSession);

    if (!reservation) {
      await mongoSession.abortTransaction();
      mongoSession.endSession();
      return res.status(404).json({ success: false, message: "Réservation non trouvée." });
    }

    if (reservation.status !== 'confirmed' 
      //&& reservation.status !== 'validated_qr' && reservation.status !== 'seated'
      ) {
      // Si déjà 'seated' et qu'on re-notifie, c'est peut-être ok, mais à clarifier.
      // Pour l'instant, on accepte 'seated' au cas où on notifierait après avoir assis le client.
      logger.warn(`Tentative de notifier la cuisine pour une réservation avec statut inapproprié: ${reservationId}, statut: ${reservation.status}`);
      await mongoSession.abortTransaction();
      mongoSession.endSession();
      return res.status(400).json({ 
        success: false, 
        message: `La réservation n'est pas dans un état permettant de notifier la cuisine (statut actuel: ${reservation.status}).` 
      });
    }
    
    if (!reservation.tableId || !reservation.tableId._id) {
        await mongoSession.abortTransaction();
        mongoSession.endSession();
        return res.status(400).json({ success: false, message: "Aucune table Mongoose valide n'est assignée à cette réservation." });
    }
    const tableDocFromReservation = reservation.tableId; // C'est le document Table peuplé

    // --- Logique de Déduction des Stocks (inspirée de createOrder) ---
    let subtotal = 0;
    const orderItemsForNewOrder = [];

    for (const preOrderItem of preOrderItemsPayload) {
      const menuItem = await MenuItem.findById(preOrderItem.menuItemId)
        .populate({ path: 'ingredients.ingredient', model: 'Ingredient' })
        .session(mongoSession);

      if (!menuItem) {
        throw new Error(`Plat pré-commandé (ID: ${preOrderItem.menuItemId}) non trouvé.`);
      }
      if (!menuItem.isAvailable) {
        // Vous pourriez vouloir une logique différente ici, peut-être informer le chef
        // que le plat n'est plus disponible au lieu de bloquer.
        // Pour l'instant, on bloque comme dans createOrder.
        throw new Error(`Plat pré-commandé '${menuItem.name}' n'est plus disponible.`);
      }

      // Déduction des ingrédients
      if (menuItem.ingredients && menuItem.ingredients.length > 0) {
        for (const recipeIngredient of menuItem.ingredients) {
          if (!recipeIngredient.ingredient || !recipeIngredient.ingredient._id) {
            logger.error(`Ingrédient non trouvé ou non peuplé pour ${menuItem.name} (référence: ${recipeIngredient.ingredient}) dans une pré-commande. Transaction annulée.`);
            throw new Error(`Données d'ingrédient incohérentes pour ${menuItem.name}.`);
          }
          const ingredientDoc = recipeIngredient.ingredient;
          const recipeQuantityPerDish = recipeIngredient.quantity;
          const recipeUnit = recipeIngredient.unit;
          const stockUnit = ingredientDoc.unit;
          let quantityInStockUnit;
          try {
            quantityInStockUnit = convertToStockUnit(recipeQuantityPerDish, recipeUnit, stockUnit, ingredientDoc.name);
          } catch (conversionError) {
            throw new Error(`Erreur de configuration d'unité pour ${ingredientDoc.name}: ${conversionError.message}`);
          }
          const totalQuantityToDeductInStockUnit = quantityInStockUnit * preOrderItem.quantity;

          if (ingredientDoc.stock < totalQuantityToDeductInStockUnit) {
            logger.warn(`Stock insuffisant pour ${ingredientDoc.name} (pré-commande), mais la commande est traitée.`);
          }
          ingredientDoc.stock -= totalQuantityToDeductInStockUnit;
          affectedIngredientIdsForBroadcast.add(ingredientDoc._id.toString());
          if (ingredientDoc.stock <= 0 || (ingredientDoc.lowStockThreshold > 0 && ingredientDoc.stock < ingredientDoc.lowStockThreshold)) {
            criticalIngredientIds.add(ingredientDoc._id.toString());
          }
          await ingredientDoc.save({ session: mongoSession });
        }
      }

      const itemTotal = menuItem.price * preOrderItem.quantity;
      subtotal += itemTotal;
      orderItemsForNewOrder.push({
        menuItem: menuItem._id,
        name: menuItem.name,
        price: menuItem.price,
        image: menuItem.image,
        quantity: preOrderItem.quantity,
        total: itemTotal,
        specialInstructions: preOrderItem.specialInstructions || reservation.specialRequests || "", // Combiner si pertinent
        productId: `prod_${menuItem.name.replace(/\s+/g, '_')}`,
      });
    }
    // --- Fin Logique de Déduction des Stocks ---

    const finalTotal = subtotal; // Pas de frais de livraison pour une pré-commande sur place

    // Créer ou mettre à jour la session de table
    let tableSession = await TableSession.findOne({ reservationid: reservation._id, status: 'active' }).session(mongoSession);
    if (!tableSession) {
      tableSession = new TableSession({
        tableId: tableDocFromReservation._id,
        clientId: reservation.userId._id,
        startTime: new Date(), // L'heure à laquelle le client est assis / la cuisine est notifiée
        status: 'active',
        reservationid: reservation._id,
        orders: []
      });
    }

    // Créer la nouvelle commande
    const newPreOrder = new Order({
      //user: reservation.userId._id,
      TableId: tableDocFromReservation._id,
      //deviceId: tableDocFromReservation.tableId, // L'ID String de la tablette
      sessionId: tableSession._id,
      items: orderItemsForNewOrder,
      orderType: "Dine In", 
      status: "pending", // La cuisine doit confirmer
      paymentMethod: reservation.paymentMethod || "cash",
      subtotal: subtotal,
      deliveryFee: 0,
      deliveryAddress: {
        address:"Pick up at restaurant",
        apartment: "", landmark: "", latitude: 0, longitude: 0,
      },
      total: finalTotal,
      orderTime: new Date(),
      //isPreOrder: true,
      //reservationIdAssociated: reservation._id // Champ pour lier à la réservation d'origine
    });

    await newPreOrder.save({ session: mongoSession });

    // Ajouter la nouvelle commande à la session et sauvegarder la session
    if (!tableSession.orders.includes(newPreOrder._id)) {
        tableSession.orders.push(newPreOrder._id);
    }
    await tableSession.save({ session: mongoSession });
    
    // Mettre à jour le statut de la réservation
    reservation.status = 'completed'; // ou 'kitchen_notified'
    await reservation.save({ session: mongoSession });

    // Mettre à jour la table (statut, session actuelle)
    const tableToUpdate = await Table.findById(tableDocFromReservation._id).session(mongoSession);
    if (tableToUpdate) {
      tableToUpdate.status = 'occupied';
      tableToUpdate.currentSession = tableSession._id;
      await tableToUpdate.save({ session: mongoSession });
    } else {
      logger.warn(`Table ${tableDocFromReservation._id} non trouvée pour mise à jour du statut après pré-commande.`);
    }
    
    await mongoSession.commitTransaction();
    // --- FIN DE LA TRANSACTION MONGOOSE ---


    // --- OPÉRATIONS POST-TRANSACTION (Notifications, etc.) ---
    // 1. Mettre à jour la disponibilité des MenuItems si des ingrédients sont critiques
    if (criticalIngredientIds.size > 0) {
      logger.info(`Ingrédients avec stock critique (pré-commande): ${Array.from(criticalIngredientIds).join(', ')}.`);
      const menuItemsToRecheck = await MenuItem.find({
        "ingredients.ingredient": { $in: Array.from(criticalIngredientIds) },
        "isAvailable": true 
      }).populate('ingredients.ingredient');

      for (const itemToUpdate of menuItemsToRecheck) {
        let shouldBeUnavailable = false;
        if (itemToUpdate.ingredients && itemToUpdate.ingredients.length > 0) {
          for (const recipeIng of itemToUpdate.ingredients) {
            if (!recipeIng.ingredient) { shouldBeUnavailable = true; break; }
            let quantityNeededInStockUnit;
            try {
              quantityNeededInStockUnit = convertToStockUnit(recipeIng.quantity, recipeIng.unit, recipeIng.ingredient.unit, recipeIng.ingredient.name);
            } catch (e) { shouldBeUnavailable = true; break;}
            if (recipeIng.ingredient.stock < quantityNeededInStockUnit) {
              shouldBeUnavailable = true; break; 
            }
          }
        }
        if (shouldBeUnavailable && itemToUpdate.isAvailable) { 
          itemToUpdate.isAvailable = false;
          await itemToUpdate.save(); // Hors transaction, car c'est une conséquence
          logger.info(`MenuItem ${itemToUpdate.name} marqué NON DISPONIBLE suite à pré-commande.`);
          // Optionnel: io.emit('menu_item_availability_changed', { menuItemId: itemToUpdate._id, isAvailable: false });
        }
      }
    }

    // 2. Diffuser les changements de stock
    if (io) {
      for (const ingredientId of affectedIngredientIdsForBroadcast) {
        // Récupérer l'ingrédient à jour avant de diffuser
        const updatedIngredient = await Ingredient.findById(ingredientId);
        if (updatedIngredient) {
            await broadcastStockChange(io, updatedIngredient, `pre_order_chef_${newPreOrder._id}`);
        }
      }
    }

    // 3. Notifier la cuisine (et le four via la même fonction)
    if (io) {
      const populatedOrderForSockets = await Order.findById(newPreOrder._id)
          .populate({ path: 'items.menuItem', model: 'MenuItem', select: 'name category' }) // Sélectionnez les champs utiles pour la cuisine
          .populate({ path: 'TableId', model: 'Table', select: 'name tableId' }); // Pour le nom/ID de la table

      if (populatedOrderForSockets) {
        await notifyKitchenAboutNewOrder(io, populatedOrderForSockets);
      }
    }

    // 4. Notifier les applications Chef de la mise à jour de la table (après la transaction)
    if (io && tableToUpdate) { // S'assurer que tableToUpdate a été récupéré et sauvegardé
        const finalTableState = await Table.findById(tableToUpdate._id) // Obtenir l'état le plus récent
            .populate({
                path: 'currentSession',
                populate: { path: 'clientId', select: 'fullName _id' }
            });
        if (finalTableState) {
            await broadcastTableUpdateToChefs(io, finalTableState);
        }
    }
    
    mongoSession.endSession();
    res.status(200).json({ 
      success: true, 
      message: "Cuisine notifiée pour la pré-commande. Commande créée.",
      orderId: newPreOrder._id,
      tableStatus: tableToUpdate?.status 
    });

  } catch (error) {
    if (mongoSession.inTransaction()) {
      await mongoSession.abortTransaction();
    }
    mongoSession.endSession();
    logger.error(`Erreur dans notifyKitchenOfPreOrder pour reservation ${reservationId}: ${error.message}\n${error.stack}`);
    res.status(500).json({ success: false, message: error.message || "Erreur serveur lors de la notification à la cuisine." });
  }
};


export const getReservationsForTable = async (req, res) => {
  const { tableMongoId } = req.params;

  if (!tableMongoId) {
    return res.status(400).json({ success: false, message: "L'ID de la table (MongoID) est requis." });
  }

  try {
    // Vérifier d'abord si la table existe (optionnel mais bonne pratique)
    const table = await Table.findById(tableMongoId);
    if (!table) {
      return res.status(404).json({ success: false, message: "Table non trouvée." });
    }

    // Définir une plage de dates pour les réservations pertinentes
    // Par exemple, les réservations pour aujourd'hui, ou celles qui ne sont pas encore passées.
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0); // Début de la journée actuelle

    // Vous pourriez vouloir inclure les réservations légèrement passées (ex: arrivées en retard)
    const relevantTimeThreshold = new Date(todayStart.getTime() - (2 * 60 * 60 * 1000)); // Ex: 2 heures avant minuit dernier

    const reservationsFromDB = await Reservation.find({
      tableId: tableMongoId, // Le champ 'tableId' dans ReservationSchema est une réf à Table._id
      status: { $in: ['confirmed', 'seated', 'validated_qr'] }, // Statuts pertinents pour le chef
      reservationTime: { $gte: relevantTimeThreshold } // Réservations à partir d'un certain seuil
    })
    .populate('userId', '_id fullName email phoneNumber') // Peuple les infos du client
    .populate({
        path: 'preSelectedMenu.menuItemId', // Peuple les détails de chaque plat
        model: 'MenuItem',
        select: '_id name price' // Champs du MenuItem à renvoyer
    })
    .sort({ reservationTime: 1 }); // Trier par heure de réservation

    if (!reservationsFromDB || reservationsFromDB.length === 0) {
      return res.status(200).json({ 
        success: true, 
        message: "Aucune réservation pertinente trouvée pour cette table.",
        reservations: [] 
      });
    }

    const formattedReservations = reservationsFromDB.map(reservation => {
      // Le 'userId' est déjà peuplé
      // Les 'menuItemId' dans 'preSelectedMenu' sont déjà peuplés
      return {
        _id: reservation._id.toString(),
        userId: reservation.userId ? { // Si l'utilisateur est peuplé
          _id: reservation.userId._id.toString(),
          fullName: reservation.userId.fullName,
          // email: reservation.userId.email, // Décommentez si besoin
          // phoneNumber: reservation.userId.phoneNumber // Décommentez si besoin
        } : null,
        customerName: reservation.userId?.fullName || 'Client Inconnu', // Pour le modèle Flutter
        tableMongoId: reservation.tableId.toString(), // ObjectId de la table Mongoose
        reservationTime: reservation.reservationTime.toISOString(),
        guests: reservation.guests,
        status: reservation.status,
        preSelectedMenu: reservation.preSelectedMenu.map(item => ({
          menuItemId: item.menuItemId ? { // Si le plat est peuplé
              _id: item.menuItemId._id.toString(),
              name: item.menuItemId.name,
              price: item.menuItemId.price,
          } : { _id: item.menuItemId?.toString() || null }, // Fallback si non peuplé
          quantity: item.quantity,
          specialInstructions: item.specialInstructions // Assurez-vous que ce champ existe sur votre modèle preSelectedMenu
        })),
        specialRequests: reservation.specialRequests
      };
    });

    res.status(200).json({
      success: true,
      count: formattedReservations.length,
      reservations: formattedReservations,
    });

  } catch (error) {
    logger.error(`Error in getReservationsForTable for tableMongoID ${tableMongoId}: ${error.message}`);
    if (error.name === 'CastError') {
        return res.status(400).json({ success: false, message: "Format de l'ID de la table invalide." });
    }
    res.status(500).json({ success: false, message: "Erreur serveur lors de la récupération des réservations." });
  }
};