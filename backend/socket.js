import { Table } from "./models/table.model.js";
import TableSession from "./models/table-session.model.js";
import { User } from "./models/user.model.js";
import { Order } from "./models/order.model.js";
import MenuItem from "./models/menuItem.model.js";
import Bill from "./models/bill.model.js";
import { getValue, setValue, deleteCache } from "./services/redis.service.js";
import logger from "./middlewares/logger.middleware.js";
import jwt from "jsonwebtoken";
import Ingredient from "./models/ingredients.model.js";
// Redis keys
const KITCHEN_SOCKET_KEY = "kitchen:socket_id";
const KITCHEN_ORDERS_CACHE = "kitchen:active_orders";

export const CHEF_APP_ROOM_KEY = "chef_apps_room";
export const WAITER_APP_ROOM_KEY = "waiter_apps_room";
export const DELIVERY_DISPATCH_ROOM_KEY = "delivery_dispatch_room"; // New room for livriha-main or similar
export const MANAGER_APP_ROOM_KEY = "manager_apps_room";
export const IOT_SIMULATORS_GENERAL_ROOM_KEY = "iot_simulators_general_room"; // Pour tous les simulateurs IoT (optionnel)

// Pas besoin de constante pour les rooms spécifiques aux appareils, car leur nom sera dynamique.
// Map pour suivre les sockets et informations des simulateurs IoT (si besoin au-delà des rooms)
// const connectedIoTSimulators = new Map(); // simulatorId -> { socketId: socket.id, type: 'oven'/'fridge'/etc. }
// Pour l'instant, nous allons nous appuyer principalement sur les rooms pour le ciblage.
// Socket.IO Middleware for JWT Authentication
const socketAuthMiddleware = async (socket, next) => {
  const token =
    socket.handshake.auth.token ||
    socket.handshake.headers.authorization?.split(" ")[1];
  const clientType = socket.handshake.query.clientType;

  // Define client types that are exempt from token authentication
  const AUTH_EXEMPT_CLIENT_TYPES = [
    "kiosk_app",
    "kitchen_app",
    "waiter_app",
    "delivery_dispatcher_app",
    "iot_simulator_app",
    "manager_app",
    "chef_app",
  ]; // Added 'delivery_dispatcher_app'

  if (AUTH_EXEMPT_CLIENT_TYPES.includes(clientType)) {
    logger.info(
      `Socket Auth: Client type '${clientType}' is exempt from token auth. Socket ID: ${socket.id}`
    );
    // Kiosk and Kitchen apps register themselves via specific events ('register_table', 'register_kitchen')
    // They don't need user authentication at the socket connection level itself.
    return next();
  }

  if (token) {
    try {
      const decoded = jwt.verify(token, process.env.ACCESS_TOKEN_SECRET);
      const user = await User.findById(decoded.userId || decoded.id).select(
        "-password -refreshToken"
      ); // Exclude sensitive fields

      if (!user) {
        logger.warn(
          `Socket Auth: User not found for token. Socket ID: ${socket.id}`
        );
        return next(new Error("Authentication error: User not found"));
      }
      socket.user = user; // Attach user object to the socket instance
      logger.info(`Socket Authenticated: ${socket.id}, UserID: ${user._id}`);
      next();
    } catch (err) {
      logger.warn(
        `Socket Auth: Invalid token. Socket ID: ${socket.id}, Error: ${err.message}`
      );
      next(new Error("Authentication error: Token invalid"));
    }
  } else {
    logger.warn(
      `Socket Auth: No token provided for non-exempt client. Socket ID: ${socket.id}, ClientType: ${clientType}`
    );
    next(
      new Error("Authentication error: Token missing or client type not exempt")
    );
  }
};

export const setupSocketIO = (io) => {
  // Store connected table devices
  const connectedTables = new Map();
  // Store connected kitchen devices
  const connectedKitchens = new Map();

  // Apply authentication middleware
  io.use(socketAuthMiddleware);

  io.on("connection", (socket) => {
    const clientType = socket.handshake.query.clientType;
    const userAgent = socket.handshake.headers["user-agent"] || "N/A";
    logger.info(
      `---> SERVER: Socket connected! ID: ${socket.id}, ClientType: ${clientType}, IP: ${socket.handshake.address}, User-Agent: ${userAgent}`
    );

    if (clientType === "manager_app") {
      // Plus de vérification de socket.user ici
      logger.info(
        `   Manager App identified: SocketID ${socket.id}. Joining room: ${MANAGER_APP_ROOM_KEY}`
      );
      socket.join(MANAGER_APP_ROOM_KEY);
      socket.emit("manager_app_registered", {
        success: true,
        message: `Application Gérant connectée.`,
      });
    } else if (clientType === "iot_simulator_app") {
      logger.info(
        `   IoT Simulator App identified: SocketID ${socket.id}. Awaiting 'register_iot_simulator_device' event(s).`
      );
      socket.join(IOT_SIMULATORS_GENERAL_ROOM_KEY);
      socket.emit("iot_simulator_connected", {
        success: true,
        message: "Connecté. Veuillez enregistrer vos appareils simulés.",
      });
    } else if (socket.user) {
      logger.info(
        `   User App authenticated: UserID ${socket.user._id}, SocketID ${socket.id}`
      );
      socket.join(`user_${socket.user._id}`); // Join user-specific room
    } else if (clientType === "kiosk_app") {
      logger.info(`   Kiosk App identified: SocketID ${socket.id}`);
      // Kiosk-specific logic follows in 'register_table'
    } else if (clientType === "kitchen_app") {
      logger.info(
        `   Kitchen App identified: SocketID ${socket.id}. Awaiting 'register_kitchen' event.`
      );
      // Kitchen-specific logic follows in 'register_kitchen'
    } else if (clientType === "waiter_app") {
      // Added condition for waiter_app
      logger.info(
        `   Waiter App identified: SocketID ${socket.id}. Joining room: ${WAITER_APP_ROOM_KEY}`
      );
      socket.join(WAITER_APP_ROOM_KEY);
    } else if (clientType === "delivery_dispatcher_app") {
      // Added for livriha-main or similar
      logger.info(
        `   Delivery Dispatcher App identified: SocketID ${socket.id}. Joining room: ${DELIVERY_DISPATCH_ROOM_KEY}`
      );
      socket.join(DELIVERY_DISPATCH_ROOM_KEY);
    } else if (clientType === "chef_app") {
      // Assurez-vous que 'chef_app' est le clientType envoyé par votre app Flutter
      logger.info(
        `Chef App identified: SocketID ${socket.id}. Joining room: ${CHEF_APP_ROOM_KEY}`
      );
      socket.join(CHEF_APP_ROOM_KEY);
      // Confirmer l'enregistrement à l'application Chef
      socket.emit("chef_app_registered", {
        success: true,
        message: `Application Chef connectée à la room ${CHEF_APP_ROOM_KEY}.`,
      });
    } else {
      logger.warn(
        `   Unidentified client: SocketID ${socket.id}, ClientType: ${clientType}. Waiting for registration or identification if applicable.`
      );
    }

    socket.on("register_iot_simulator_device", (data) => {
      if (clientType !== "iot_simulator_app") {
        logger.warn(
          `Socket ${socket.id} (type: ${clientType}) attempted to register IoT device without being iot_simulator_app.`
        );
        return socket.emit("error", {
          message: "Action non autorisée pour ce type de client.",
        });
      }
      const { deviceId, deviceType } = data;
      if (!deviceId || !deviceType) {
        return socket.emit("error", {
          message: "deviceId et deviceType sont requis.",
        });
      }
      if (!socket.simulatedDevices) {
        socket.simulatedDevices = new Map();
      }
      socket.simulatedDevices.set(deviceId, deviceType);
      const deviceSpecificRoom = `iot_device_${deviceId}`;
      socket.join(deviceSpecificRoom);
      logger.info(
        `IoT Simulator App (Socket ${socket.id}) registered device: ${deviceId} (Type: ${deviceType}). Joined room: ${deviceSpecificRoom}.`
      );
      socket.emit("iot_device_registration_ack", {
        success: true,
        deviceId,
        deviceType,
        room: deviceSpecificRoom,
      });
    });

    // Table app registers itself with its table ID
    socket.on("register_table", async (data) => {
      try {
        const { tableId } = data;

        if (!tableId) {
          socket.emit("error", { message: "Table ID is required" });
          return;
        }

        // Validate table exists
        const table = await Table.findOne({ tableId: tableId });
        if (!table) {
          socket.emit("error", { message: "Table not found" });
          return;
        }

        // Join a room specific to this table
        socket.join(`table_${tableId}`);

        // Store socket ID with table ID for direct messaging
        connectedTables.set(tableId, socket.id);

        logger.info(`Table ${tableId} registered with socket ID: ${socket.id}`);

        socket.emit("table_registered", {
          success: true,
          message: `Table ${tableId} registered successfully`,
          tableData: {
            id: table._id,
            tableId: table.tableId,
            status: table.status,
            isActive: table.isActive,
          },
        });
      } catch (error) {
        logger.error("Error registering table:", error);
        socket.emit("error", { message: "Failed to register table" });
      }
    });

    // Kitchen app registers itself
    socket.on("register_kitchen", async () => {
      try {
        // Store kitchen socket ID in Redis
        const success = await setValue(KITCHEN_SOCKET_KEY, socket.id);
        if (success) {
          logger.info(
            `Kitchen app registered with socket ID: ${socket.id} (Stored in Redis)`
          );
          // Acknowledge registration
          socket.emit("kitchen_registered", { success: true });
          // Optionally, keep joining the room if other logic depends on it
          socket.join("kitchen");
        } else {
          logger.error(
            `Failed to store kitchen socket ID in Redis for: ${socket.id}`
          );
          socket.emit("error", {
            message: "Failed to register kitchen due to Redis error",
          });
        }
      } catch (error) {
        logger.error("Error registering kitchen:", error);
        socket.emit("error", { message: "Failed to register kitchen" });
      }
    });

    // Handle tablet device registration (example - adapt as needed)
    socket.on("register_device_with_table", async (data) => {
      try {
        const { deviceId } = data;
        if (!deviceId) {
          return socket.emit("error", { message: "Device ID is required" });
        }

        // Store tablet socket ID in Redis with device ID (or tableId if preferred)
        const key = `device:${deviceId}:socket_id`;
        const success = await setValue(key, socket.id);
        if (success) {
          logger.info(
            `Device ${deviceId} registered with socket ID: ${socket.id} (Stored in Redis)`
          );
          socket.emit("device_registered", { success: true, deviceId });
        } else {
          logger.error(
            `Failed to store device socket ID in Redis for: ${deviceId}`
          );
          socket.emit("error", {
            message: "Failed to register device due to Redis error",
          });
        }
      } catch (error) {
        logger.error("Error registering device:", error);
        socket.emit("error", { message: "Failed to register device" });
      }
    });

    // Enhanced initiate_session handler for authenticated User App
    socket.on("initiate_session", async (data) => {
      // This event is expected from an AUTHENTICATED User App socket
      if (!socket.user) {
        logger.warn(
          `Initiate session attempt from unauthenticated socket: ${socket.id}`
        );
        return socket.emit("error", {
          message: "Authentication required to start a session.",
        });
      }

      try {
        const { tableDeviceId, userId } = data; // tableDeviceId is the Kiosk's deviceId from QR

        if (!tableDeviceId || !userId) {
          return socket.emit("error", {
            message: "Table Device ID and User ID are required",
          });
        }

        if (socket.user._id.toString() !== userId) {
          logger.warn(
            `User ID mismatch: Socket user ${socket.user._id} vs data userId ${userId}`
          );
          return socket.emit("error", { message: "User ID mismatch." });
        }

        // 1. Find the Kiosk's Table document using its deviceId
        // The Kiosk app should have registered its deviceId as table.tableId
        const table = await Table.findOne({ tableId: tableDeviceId });
        if (!table) {
          return socket.emit("error", {
            message: `Table device ${tableDeviceId} not found or not registered.`,
          });
        }
        if (!table.isActive) {
          return socket.emit("error", {
            message: `Table device ${tableDeviceId} is not active.`,
          });
        }
        // Allow joining if table is 'available' or already 'occupied' (if joining existing session)
        if (table.status !== "available" && table.status !== "occupied") {
          return socket.emit("error", {
            message: `Table ${tableDeviceId} is not available for a new session.`,
          });
        }

        const user = socket.user; // Already fetched by middleware

        // Optional: Check if user already has an active session elsewhere (if 1 session per user rule)
        const existingUserSession = await TableSession.findOne({
          clientId: userId,
          status: "active",
        });
        if (
          existingUserSession &&
          existingUserSession.tableId.toString() !== table._id.toString()
        ) {
          return socket.emit("error", {
            message: "You already have an active session at another table.",
            // sessionId: existingUserSession._id, // Optional: provide info
          });
        }

        // 2. Create or retrieve TableSession
        let session;
        if (table.currentSession && table.status === "occupied") {
          session = await TableSession.findById(table.currentSession).populate(
            "orders"
          );
          if (!session || session.status === "closed") {
            // Create new session if existing one is invalid
            table.currentSession = null; // Clear stale session
          } else {
            // Add user to existing session if not already client (more complex logic for multiple users per session)
            // For now, let's assume one primary clientId for the session.
            logger.info(
              `User ${userId} joining existing session ${session._id} at table ${table.tableId}`
            );
          }
        }

        if (!table.currentSession) {
          session = new TableSession({
            tableId: table._id, // MongoDB ObjectId of the Table
            clientId: userId,
            startTime: new Date(),
            status: "active",
            orders: [], // Initialize with empty orders
          });
          await session.save();
          table.status = "occupied";
          table.currentSession = session._id;
          await table.save();
          const updatedTableForBroadcast = await Table.findById(
            table._id
          ).populate({
            path: "currentSession",
            populate: { path: "clientId", select: "fullName _id" },
          });
          if (updatedTableForBroadcast) {
            await broadcastTableUpdateToChefs(io, updatedTableForBroadcast);
          }
          logger.info(
            `New session ${session._id} started for table ${table.tableId} by user ${userId}`
          );
        }

        // 3. Join User App's socket to the table's room
        socket.join(`table_${table.tableId}`); // table.tableId is Kiosk's device ID
        logger.info(
          `User App socket ${socket.id} (User ${userId}) joined room table_${table.tableId}`
        );

        // 4. Emit "session_started" to Kiosk App in its room
        io.to(`table_${table.tableId}`).emit("session_started", {
          sessionId: session._id.toString(),
          tableId: table.tableId, // Kiosk's device ID (the one it registered with)
          dbTableId: table._id.toString(),
          clientId: session.clientId.toString(),
          customerName: user.fullName || "Customer",
          startTime: session.startTime,
          status: session.status,
          // Include current items if any (from Kiosk if it started adding)
          items: session.orders.reduce(
            (acc, order) =>
              acc.concat(
                order.items.map((item) => ({
                  menuItemId: item.menuItem.toString(),
                  name: item.name,
                  price: item.price,
                  quantity: item.quantity,
                }))
              ),
            []
          ),
        });
        logger.info(`Emitted 'session_started' to room table_${table.tableId}`);

        // 5. Emit "session_created" (or a more descriptive "session_joined") back to the initiating User App
        socket.emit("session_created", {
          sessionId: session._id.toString(),
          tableId: table.tableId, // Kiosk's device ID
          dbTableId: table._id.toString(),
          startTime: session.startTime,
          status: session.status,
          // Send current cart/order items for this session
          items: session.orders.reduce(
            (acc, order) =>
              acc.concat(
                order.items.map((item) => ({
                  menuItemId: item.menuItem.toString(),
                  name: item.name,
                  price: item.price,
                  quantity: item.quantity,
                }))
              ),
            []
          ),
          currentTotal: session.orders.reduce(
            (sum, order) => sum + order.total,
            0
          ),
        });
        logger.info(
          `Emitted 'session_created' back to User App socket ${socket.id}`
        );
      } catch (error) {
        logger.error("Error initiating session via socket:", error);
        socket.emit("error", {
          message: "Failed to initiate session: " + error.message,
        });
      }
    });

    // Handle updates to table session items (cart updates)
    socket.on("update_table_session_item", async (data) => {
      try {
        const { sessionId, tableId, menuItemId, quantity, action } = data;

        if (!sessionId || !tableId || !menuItemId) {
          return socket.emit("error", {
            message: "Session ID, Table ID, and Menu Item ID are required",
          });
        }

        // Validate session exists and is active
        const session = await TableSession.findById(sessionId);
        if (!session) {
          return socket.emit("error", { message: "Session not found" });
        }

        if (session.status !== "active") {
          return socket.emit("error", { message: "Session is not active" });
        }

        // Find or create cart order for this session
        let cartOrder = await Order.findOne({
          sessionId: sessionId,
          status: "cart_active", // Special status for items in cart
        });

        if (!cartOrder) {
          // Create a new cart order
          cartOrder = new Order({
            sessionId: sessionId,
            TableId: session.tableId, // MongoDB ID of the table
            items: [],
            orderType: "Dine In",
            status: "cart_active",
            subtotal: 0,
            total: 0,
          });
        }

        // Get menu item details
        const menuItem = await MenuItem.findById(menuItemId);
        if (!menuItem) {
          return socket.emit("error", { message: "Menu item not found" });
        }

        // Handle the action (add, remove, update)
        let itemIndex = cartOrder.items.findIndex(
          (item) => item.menuItem.toString() === menuItemId
        );

        if (action === "add" || action === "update") {
          if (itemIndex >= 0) {
            // Update existing item
            cartOrder.items[itemIndex].quantity = quantity;
            cartOrder.items[itemIndex].total = menuItem.price * quantity;
          } else {
            // Add new item
            cartOrder.items.push({
              menuItem: menuItemId,
              name: menuItem.name,
              price: menuItem.price,
              quantity: quantity,
              total: menuItem.price * quantity,
              specialInstructions: data.specialInstructions || "",
            });
          }
        } else if (action === "remove") {
          if (itemIndex >= 0) {
            // Remove item
            cartOrder.items.splice(itemIndex, 1);
          }
        }

        // Recalculate totals
        cartOrder.subtotal = cartOrder.items.reduce(
          (sum, item) => sum + item.total,
          0
        );
        cartOrder.total = cartOrder.subtotal; // Add tax, delivery fee, etc. if needed

        // Save the updated cart
        await cartOrder.save();

        // If this is a new cart order, add it to the session
        if (!session.orders.includes(cartOrder._id)) {
          session.orders.push(cartOrder._id);
          await session.save();
        }

        // Broadcast cart update to all clients in the table room
        io.to(`table_${tableId}`).emit("table_session_cart_updated", {
          sessionId: session._id.toString(),
          items: cartOrder.items.map((item) => ({
            menuItemId: item.menuItem.toString(),
            name: item.name,
            price: item.price,
            quantity: item.quantity,
            total: item.total,
            specialInstructions: item.specialInstructions,
          })),
          subtotal: cartOrder.subtotal,
          total: cartOrder.total,
        });

        logger.info(
          `Cart updated for session ${sessionId}, table ${tableId}, item ${menuItemId}, action: ${action}`
        );
      } catch (error) {
        logger.error("Error updating table session item:", error);
        socket.emit("error", {
          message: "Failed to update cart item: " + error.message,
        });
      }
    });

    // Customer app scans QR code (keeping for backward compatibility)
    socket.on("scan_qr_code", async (data) => {
      try {
        const { tableId, userId } = data;

        if (!tableId || !userId) {
          socket.emit("error", {
            message: "Table ID and User ID are required",
          });
          return;
        }

        // Validate table
        const table = await Table.findOne({ tableId: tableId });
        if (!table) {
          socket.emit("error", { message: "Table not found" });
          return;
        }

        if (!table.isActive) {
          socket.emit("error", { message: "Table is not active" });
          return;
        }

        if (table.status !== "available") {
          socket.emit("error", { message: "Table is not available" });
          return;
        }

        // Validate user
        const user = await User.findById(userId);
        if (!user) {
          socket.emit("error", { message: "User not found" });
          return;
        }

        // Check if there's an existing active session for this user
        const existingUserSession = await TableSession.findOne({
          clientId: userId,
          status: "active",
        });

        if (existingUserSession) {
          socket.emit("error", {
            message: "You already have an active session at another table",
            sessionId: existingUserSession._id,
            tableId: existingUserSession.tableId,
          });
          return;
        }

        // Create a new session
        const session = new TableSession({
          tableId: table._id, // Use the MongoDB _id
          clientId: userId,
          startTime: new Date(),
          status: "active",
        });

        await session.save();

        // Update table status
        table.status = "occupied";
        table.currentSession = session._id;
        await table.save();

        // Notify the table app to open the session
        io.to(`table_${tableId}`).emit("session_started", {
          sessionId: session._id,
          tableId: tableId,
          clientId: session.clientId,
          startTime: session.startTime,
          status: session.status,
          customerName: user.fullName || "Customer",
        });

        // Also notify the customer app
        socket.emit("session_created", {
          sessionId: session._id,
          tableId: tableId,
          startTime: session.startTime,
          status: session.status,
        });

        logger.info(
          `Session started for table ${tableId} by user ${userId} via QR scan`
        );
      } catch (error) {
        logger.error("Error processing QR code scan:", error);
        socket.emit("error", { message: "Failed to process QR code scan" });
      }
    });

    // Handle order updates to notify table app
    socket.on("order_placed", async (data) => {
      try {
        const { sessionId, orderId, tableId } = data;

        if (!orderId) {
          socket.emit("error", { message: "Order ID is required" });
          return;
        }

        // Get the order details
        const order = await Order.findById(orderId).populate({
          path: "items.menuItem",
          select: "name image category",
        });

        if (!order) {
          socket.emit("error", { message: "Order not found" });
          return;
        }

        // Get table ID if available
        let orderTableId = null;
        if (order.TableId) {
          // Find the table with this ID
          const table = await Table.findById(order.TableId);
          if (table) {
            orderTableId = table.tableId;
          }
        }

        // If sessionId is provided, notify the table app
        if (sessionId && tableId) {
          io.to(`table_${tableId}`).emit("table_order_finalized", {
            sessionId,
            orderId: order._id.toString(),
            items: order.items.map((item) => ({
              menuItemId: item.menuItem.toString(),
              name: item.name,
              quantity: item.quantity,
              price: item.price,
              total: item.total,
            })),
            total: order.total,
            status: order.status,
            message: "Order has been placed for the table.",
          });
          logger.info(
            `Emitted 'table_order_finalized' for session ${sessionId} to room table_${tableId}`
          );
        }

        logger.info(
          `Order ${orderId} notification sent to table app (kitchen notified via controller)`
        );
      } catch (error) {
        logger.error("Error handling order placed:", error);
        socket.emit("error", { message: "Failed to notify about order" });
      }
    });

    // Handle session end request
    socket.on("end_session", async (data) => {
      try {
        const { sessionId, tableId } = data;

        if (!sessionId) {
          socket.emit("error", { message: "Session ID is required" });
          return;
        }

        // Find the session
        const session = await TableSession.findById(sessionId);
        if (!session) {
          socket.emit("error", { message: "Session not found" });
          return;
        }

        if (session.status === "closed") {
          socket.emit("error", { message: "Session is already closed" });
          return;
        }

        // Check if bill already exists
        let bill = await Bill.findOne({ tableSessionId: sessionId });

        if (!bill) {
          // Get all orders for this session
          const orders = await Order.find({ _id: { $in: session.orders } });

          // Calculate total
          const total = orders.reduce((sum, order) => sum + order.total, 0);

          // Create bill
          bill = new Bill({
            tableSessionId: sessionId,
            total,
            paymentStatus: "pending",
          });

          await bill.save();
        }

        // Update session status
        session.status = "closed";
        session.endTime = new Date();
        await session.save();

        // Update table status
        const table = await Table.findById(session.tableId);
        if (table) {
          table.status = "available";
          table.currentSession = null;
          await table.save();
          await broadcastTableUpdateToChefs(io, table);
        }

        // Notify both table app and customer app
        const effectiveTableId = tableId || (table ? table.tableId : null);
        if (effectiveTableId) {
          io.to(`table_${effectiveTableId}`).emit("session_ended", {
            sessionId,
            bill: {
              id: bill._id,
              total: bill.total,
              paymentStatus: bill.paymentStatus,
            },
          });
        }

        // Also emit back to the caller (e.g., Kiosk app)
        socket.emit("session_ended_confirmation", {
          sessionId,
          bill: {
            id: bill._id,
            total: bill.total,
            paymentStatus: bill.paymentStatus,
          },
        });

        logger.info(`Session ${sessionId} ended and bill created`);
      } catch (error) {
        logger.error("Error ending session:", error);
        socket.emit("error", { message: "Failed to end session" });
      }
    });

    // Handle bill creation notification
    socket.on("bill_created", async (data) => {
      try {
        const { billId, sessionId, tableId } = data;

        if (!billId || !sessionId) {
          socket.emit("error", {
            message: "Bill ID and Session ID are required",
          });
          return;
        }

        // Notify the table app about the bill
        io.to(`table_${tableId}`).emit("bill_ready", {
          billId,
          sessionId,
        });

        logger.info(`Bill ${billId} notification sent to table ${tableId}`);
      } catch (error) {
        logger.error("Error handling bill creation:", error);
        socket.emit("error", { message: "Failed to notify about bill" });
      }
    });

    // Handle reservation events
    socket.on("make_reservation", async (data) => {
      try {
        const { userId, tableId, reservationTime } = data;

        if (!userId || !tableId || !reservationTime) {
          socket.emit("error", {
            message: "User ID, Table ID, and reservation time are required",
          });
          return;
        }

        // Notify admin about new reservation request
        io.emit("new_reservation_request", {
          userId,
          tableId,
          reservationTime,
        });

        logger.info(
          `New reservation request from user ${userId} for table ${tableId}`
        );
      } catch (error) {
        logger.error("Error handling reservation request:", error);
        socket.emit("error", {
          message: "Failed to process reservation request",
        });
      }
    });

    // Handle disconnection
    socket.on("disconnect", async () => {
      logger.info(`Socket disconnected: ${socket.id}`);

      // Check if this was the kitchen socket and remove it from Redis
      try {
        const kitchenSocketId = await getValue(KITCHEN_SOCKET_KEY);
        if (kitchenSocketId === socket.id) {
          await deleteCache(KITCHEN_SOCKET_KEY); // Use deleteCache which calls .del()
          logger.info(
            `Removed disconnected kitchen socket ID from Redis: ${socket.id}`
          );
        }
        // TODO: Add logic here to remove disconnected device sockets if needed
      } catch (error) {
        logger.error(
          `Error cleaning up disconnected socket ${socket.id} from Redis:`,
          error
        );
      }

      // Remove from connected tables if this was a table app
      for (const [tableId, socketId] of connectedTables.entries()) {
        if (socketId === socket.id) {
          connectedTables.delete(tableId);
          logger.info(`Table with ID ${tableId} disconnected`);
          break;
        }
      }

      // Remove from connected kitchens if this was a kitchen app
      for (const [kitchenId, socketId] of connectedKitchens.entries()) {
        if (socketId === socket.id) {
          connectedKitchens.delete(kitchenId);
          logger.info(`Kitchen with ID ${kitchenId} disconnected`);
          break;
        }
      }
    });

    // socket.js - dans io.on("connection", (socket) => { ... })

    // Exemple pour la commande manager_set_fridge_target_temp
    socket.on("manager_set_fridge_target_temp", (data) => {
      // ANCIENNE VÉRIFICATION (si authentification) :
      // if (!socket.user || socket.clientType !== 'manager_app') {
      // NOUVELLE VÉRIFICATION (sans authentification, basée sur le type de client déclaré) :
      // if (socket.clientType !== 'manager_app') {
      //     return socket.emit("error", { message: "Action non autorisée. Client non identifié comme Manager App." });
      // }
      try {
        const { fridgeId, targetTemperature } = data;
        if (!fridgeId || targetTemperature === undefined) {
          return socket.emit("error", {
            message: "Fridge ID et target temperature sont requis.",
          });
        }
        // logger.info(`Manager command from ${socket.id}: set fridge ${fridgeId} target temp to ${targetTemperature}`); // Logger l'ID du socket si user._id n'est pas dispo
        logger.info(
          `Manager command (ClientType: ${socket.clientType}, SocketID: ${socket.id}): set fridge ${fridgeId} target temp to ${targetTemperature}`
        );

        // Le reste de la logique pour trouver le socket du simulateur IoT et émettre la commande
        // via sa room spécifique `iot_device_${fridgeId}` reste identique.
        // Exemple : io.to(`iot_device_${fridgeId}`).emit("set_fridge_target_temp_command", { fridgeId, targetTemperature });
        // (Assurez-vous que le simulateur IoT a bien rejoint cette room après son 'register_iot_simulator_device')

        // Pour l'exemple, on va directement émettre à la room
        const deviceSpecificRoom = `iot_device_${fridgeId}`;
        const connectedSocketsInRoom =
          io.sockets.adapter.rooms.get(deviceSpecificRoom);

        if (connectedSocketsInRoom && connectedSocketsInRoom.size > 0) {
          io.to(deviceSpecificRoom).emit("set_fridge_target_temp_command", {
            fridgeId,
            targetTemperature,
          });
          socket.emit("manager_command_ack", {
            success: true,
            deviceId: fridgeId,
            command: "set_fridge_target_temp",
          });
        } else {
          logger.warn(
            `Aucun simulateur IoT trouvé dans la room ${deviceSpecificRoom} pour la commande du manager.`
          );
          socket.emit("error", {
            message: `Simulateur de réfrigérateur ${fridgeId} non connecté ou non enregistré dans la room.`,
          });
        }
      } catch (error) {
        logger.error("Error processing manager_set_fridge_target_temp:", error);
        socket.emit("error", {
          message: "Échec du réglage de la température cible du réfrigérateur.",
        });
      }
    });

    // Faites des ajustements similaires pour "manager_set_oven_parameters"
    socket.on("manager_set_oven_parameters", (data) => {
      // if (socket.clientType !== 'manager_app') {
      //     return socket.emit("error", { message: "Action non autorisée. Client non identifié comme Manager App." });
      // }
      try {
        const { ovenId, targetTemperature, mode, durationMinutes } = data;
        if (!ovenId /* ajoutez d'autres validations si nécessaire */) {
          return socket.emit("error", { message: "Oven ID est requis." });
        }
        // logger.info(`Manager command from ${socket.id}: set oven ${ovenId} params...`);
        logger.info(
          `Manager command (ClientType: ${socket.clientType}, SocketID: ${socket.id}): set oven ${ovenId} params - Temp: ${targetTemperature}, Mode: ${mode}, Duration: ${durationMinutes}min`
        );

        const commandData = {
          ovenId,
          targetTemperature,
          mode,
          durationMinutes,
        };
        const deviceSpecificRoom = `iot_device_${ovenId}`;
        const connectedSocketsInRoom =
          io.sockets.adapter.rooms.get(deviceSpecificRoom);

        if (connectedSocketsInRoom && connectedSocketsInRoom.size > 0) {
          io.to(deviceSpecificRoom).emit(
            "set_oven_parameters_command",
            commandData
          );
          socket.emit("manager_command_ack", {
            success: true,
            deviceId: ovenId,
            command: "set_oven_parameters",
          });
        } else {
          logger.warn(
            `Aucun simulateur IoT trouvé dans la room ${deviceSpecificRoom} pour la commande du manager.`
          );
          socket.emit("error", {
            message: `Simulateur de four ${ovenId} non connecté ou non enregistré dans la room.`,
          });
        }
      } catch (error) {
        logger.error("Error processing manager_set_oven_parameters:", error);
        socket.emit("error", {
          message: "Échec du réglage des paramètres du four.",
        });
      }
    });
    socket.on("iot_stock_update", async (data) => {
      try {
        const { deviceId, ingredientId, newStockLevel } = data;
        if (
          ingredientId === undefined ||
          newStockLevel === undefined ||
          newStockLevel < 0
        ) {
          return socket.emit("error", {
            message: "Données de mise à jour du stock invalides.",
          });
        }

        const updatedIngredient = await Ingredient.findByIdAndUpdate(
          ingredientId,
          { stock: newStockLevel },
          { new: true }
        );

        if (!updatedIngredient) {
          logger.warn(
            `Mise à jour stock IoT : Ingrédient ${ingredientId} non trouvé.`
          );
          return socket.emit("error", {
            message: `Ingrédient ${ingredientId} non trouvé.`,
          });
        }
        logger.info(
          `Stock mis à jour par IoT ${deviceId} (Socket ${socket.id}): ${updatedIngredient.name}, Nouveau Stock ${updatedIngredient.stock}`
        );

        // APPELER LA FONCTION DE DIFFUSION CENTRALE
        // Passez l'instance `io` qui est disponible dans le scope de `setupSocketIO`
        await broadcastStockChange(
          io,
          updatedIngredient /*._id.toString()*/,
          `iot_simulator_${deviceId}`
        );
        // L'accusé de réception au simulateur qui a initié
        socket.emit("iot_stock_update_ack", {
          success: true,
          ingredientId: updatedIngredient._id.toString(),
          newStockLevel: updatedIngredient.stock,
        });
        console.log(
          `Stock mis à jour par IoT ${deviceId} (Socket ${socket.id}): ${updatedIngredient.name}, Nouveau Stock ${updatedIngredient.stock}`
        );
      } catch (error) {
        logger.error(
          `Erreur lors du traitement de iot_stock_update (initié par IoT) pour device ${data.deviceId}, ingrédient ${data.ingredientId}:`,
          error
        );
        if (!socket.headersSent) {
          socket.emit("error", {
            message: "Échec du traitement de la mise à jour du stock.",
          });
        }
      }
    });

    // 2. Événement: Mise à jour du Statut du Réfrigérateur depuis le Simulateur IoT
    socket.on("iot_fridge_status_update", (data) => {
      // if (socket.clientType !== 'iot_simulator_app' || !socket.simulatedDevices || !socket.simulatedDevices.has(data.deviceId) || socket.simulatedDevices.get(data.deviceId) !== 'refrigerator') {
      //   logger.warn(`Tentative non autorisée de mise à jour du réfrigérateur par socket ${socket.id} pour deviceId ${data.deviceId}`);
      //   return socket.emit("error", { message: "Action non autorisée ou type d'appareil incorrect pour la mise à jour du réfrigérateur." });
      // }

      try {
        const { deviceId, currentTemperature, targetTemperature, status } =
          data; // deviceId est celui du frigo, ex: "fridge_sim_1"

        // Valider les données (ajouter plus de validations si nécessaire)
        if (
          deviceId === undefined ||
          currentTemperature === undefined ||
          targetTemperature === undefined ||
          status === undefined
        ) {
          return socket.emit("error", {
            message: "Données de mise à jour du réfrigérateur invalides.",
          });
        }

        logger.info(
          `Statut Réfrigérateur reçu de IoT ${deviceId} (Socket ${socket.id}): Temp ${currentTemperature}°C, Cible ${targetTemperature}°C, Statut ${status}`
        );

        const fridgeDataForManager = {
          deviceId,
          currentTemperature,
          targetTemperature,
          status,
          timestamp: new Date(),
        };

        io.to(MANAGER_APP_ROOM_KEY).emit(
          "fridge_status_changed",
          fridgeDataForManager
        );
        socket.emit("iot_fridge_status_update_ack", {
          success: true,
          deviceId,
        });
      } catch (error) {
        logger.error(
          `Erreur lors du traitement de iot_fridge_status_update pour device ${data.deviceId}:`,
          error
        );
        socket.emit("error", {
          message:
            "Échec du traitement de la mise à jour du statut du réfrigérateur.",
        });
      }
    });

    // 3. Événement: Mise à jour du Statut du Four depuis le Simulateur IoT
    socket.on("iot_oven_status_update", (data) => {
      // if (socket.clientType !== 'iot_simulator_app' || !socket.simulatedDevices || !socket.simulatedDevices.has(data.deviceId) || socket.simulatedDevices.get(data.deviceId) !== 'oven') {
      //   logger.warn(`Tentative non autorisée de mise à jour du four par socket ${socket.id} pour deviceId ${data.deviceId}`);
      //   return socket.emit("error", { message: "Action non autorisée ou type d'appareil incorrect pour la mise à jour du four." });
      // }

      try {
        const {
          deviceId,
          currentTemperature,
          targetTemperature,
          status,
          mode,
          remainingTimeSeconds,
        } = data; // deviceId est "oven_sim_1"

        if (deviceId === undefined /* ajoutez d'autres validations */) {
          return socket.emit("error", {
            message: "Données de mise à jour du four invalides.",
          });
        }

        logger.info(
          `Statut Four reçu de IoT ${deviceId} (Socket ${socket.id}): Temp ${currentTemperature}°C, Cible ${targetTemperature}°C, Statut ${status}, Mode ${mode}, Temps Restant ${remainingTimeSeconds}s`
        );

        const ovenDataForManager = {
          deviceId,
          currentTemperature,
          targetTemperature,
          status,
          mode,
          remainingTimeSeconds,
          timestamp: new Date(),
        };

        io.to(MANAGER_APP_ROOM_KEY).emit(
          "oven_status_changed",
          ovenDataForManager
        );
        socket.emit("iot_oven_status_update_ack", { success: true, deviceId });
      } catch (error) {
        logger.error(
          `Erreur lors du traitement de iot_oven_status_update pour device ${data.deviceId}:`,
          error
        );
        socket.emit("error", {
          message: "Échec du traitement de la mise à jour du statut du four.",
        });
      }
    });
  });
};

/**
 * Notify kitchen about a new order
 * @param {object} io - Socket.IO server instance
 * @param {object} order - The new order object (mongoose document expected)
 */
export const notifyKitchenAboutNewOrder = async (io, order) => {
  try {
    // --- Section existante pour notifier la Cuisine ---
    const kitchenSocketId = await getValue(KITCHEN_SOCKET_KEY); //

    if (!kitchenSocketId) {
      logger.warn("No kitchen app registered, cannot notify about new order");
      // Ne retournez pas 'false' immédiatement si la cuisine n'est pas là,
      // car nous voulons toujours essayer de notifier le four.
      // Ou, si la notification à la cuisine est critique, vous pouvez choisir de retourner.
      // Pour l'instant, on continue pour le four.
    } else {
      const formattedOrder = {
        id: order._id.toString(),
        orderNumber: order._id.toString().slice(-6).toUpperCase(),
        items: order.items.map((item) => ({
          name: item.name,
          quantity: item.quantity,
          specialInstructions: item.specialInstructions || "",
          category: item.menuItem?.category || null,
        })),
        orderType: order.orderType,
        tableId: order.TableId?.toString() || order.deviceId || null,
        status: order.status,
        createdAt: order.createdAt,
      };

      io.to(kitchenSocketId).emit("new_kitchen_order", formattedOrder);

      // La ligne suivante pour `deleteCache` est spécifique à votre logique de cache.
      // Si KITCHEN_ORDERS_CACHE est utilisé par la cuisine pour ses commandes actives, c'est pertinent.
      await deleteCache(KITCHEN_ORDERS_CACHE); //

      logger.info(
        `Notified kitchen (${kitchenSocketId}) about new order: ${order._id}`
      );
    }

    // --- NOUVELLE Section pour notifier le Simulateur de Four ---
    const OVEN_SIMULATOR_DEVICE_ID = "oven_sim_1"; // L'ID de votre simulateur de four
    const ovenSpecificRoom = `iot_device_${OVEN_SIMULATOR_DEVICE_ID}`; // La room unique du four

    // Vérifier si le simulateur de four est dans sa room
    // `io.sockets.adapter.rooms.get(roomName)` renvoie un Set des socket IDs dans la room, ou undefined.
    const connectedSocketsInOvenRoom =
      io.sockets.adapter.rooms.get(ovenSpecificRoom);

    if (connectedSocketsInOvenRoom && connectedSocketsInOvenRoom.size > 0) {
      // Générer une température cible aléatoire pour le four
      const minTemp = 160; // °C
      const maxTemp = 220; // °C
      // Arrondir aux 5 degrés les plus proches
      const randomTargetTemperature =
        Math.round((Math.random() * (maxTemp - minTemp) + minTemp) / 5) * 5;

      const ovenPayload = {
        deviceId: OVEN_SIMULATOR_DEVICE_ID,
        // Vous avez dit que l'orderId n'était pas nécessaire, donc on ne l'inclut pas dans 'orderDetails' pour le four.
        // On peut garder une raison générique pour le contexte.
        triggerReason: `Activation pour commande cuisine (ID de commande interne: ${order._id.toString()})`,
        defaultParameters: {
          targetTemperature: parseFloat(randomTargetTemperature.toFixed(1)),
          mode: "bake", // Mode par défaut
          durationMinutes: 20, // Préchauffer et maintenir, pas de cycle minuté
          turnLightOn: true,
        },
      };

      logger.info(
        `New order ${
          order._id
        } also triggers oven. Notifying oven simulator ${OVEN_SIMULATOR_DEVICE_ID} in room ${ovenSpecificRoom} with params: ${JSON.stringify(
          ovenPayload.defaultParameters
        )}`
      );

      // Émettre à la room spécifique du four
      io.to(ovenSpecificRoom).emit("kitchen_new_order_for_oven", ovenPayload);
    } else {
      logger.warn(
        `Oven simulator ${OVEN_SIMULATOR_DEVICE_ID} not connected or not in its room (${ovenSpecificRoom}). Cannot notify for order ${order._id}.`
      );
    }

    return true; // Indique que la tentative de notification (cuisine et/ou four) a été faite.
  } catch (error) {
    logger.error(
      `Error in notifyKitchenAboutNewOrder (processing for kitchen and/or oven) for order ${order?._id}:`,
      error
    );
    return false;
  }
};

/**
 * Notify kitchen about order status update
 * @param {object} io - Socket.IO server instance
 * @param {object} order - The updated order (mongoose document expected)
 * @param {string} previousStatus - Previous order status
 */
export const notifyKitchenAboutOrderUpdate = async (
  io,
  order,
  previousStatus
) => {
  try {
    // Get kitchen socket ID from Redis
    const kitchenSocketId = await getValue(KITCHEN_SOCKET_KEY);

    if (!kitchenSocketId) {
      logger.warn(
        "No kitchen app registered, cannot notify about order update"
      );
      return false;
    }

    // Format order update for kitchen display
    const orderUpdate = {
      id: order._id.toString(),
      orderNumber: order._id.toString().slice(-6).toUpperCase(),
      status: order.status,
      previousStatus, // Send previous status for client logic
      updatedAt: order.updatedAt || new Date(), // Use order updatedAt if available
    };

    // Emit event directly to kitchen socket
    io.to(kitchenSocketId).emit("order_status_updated", orderUpdate);

    // Invalidate kitchen orders cache *after* successful emission
    await deleteCache(KITCHEN_ORDERS_CACHE);

    logger.info(
      `Notified kitchen (${kitchenSocketId}) about order update: ${order._id} (${previousStatus} -> ${order.status})`
    );
    return true;
  } catch (error) {
    logger.error(
      `Error notifying kitchen about order update ${order?._id}:`,
      error
    );
    return false;
  }
};

/**
 * Notify waiter apps about a "Dine In" order that is ready for pickup.
 * @param {object} io - Socket.IO server instance
 * @param {object} order - The order object (mongoose document expected)
 */
export const notifyWaiterAppsAboutReadyDineInOrder = async (io, order) => {
  // Ensure the order has readyAt timestamp set
  if (!order.readyAt && order.status === "ready_for_pickup") {
    order.readyAt = new Date();
    await order.save();
  }
  try {
    if (order.orderType !== "Dine In" || order.status !== "ready_for_pickup") {
      logger.info(
        `Order ${order._id} is not a 'Dine In' order or not 'ready_for_pickup'. No notification sent to waiters.`
      );
      return false;
    }
    
    const tableId = order.TableId
    
    console.log(tableId);
    const table= await Table.findById(tableId);
    console.log(table);
  if (!table || !table.name) {
  logger.warn(`Table not found or missing name for ID ${tableId}`);
  return false;
  }

const tableName = table.name.split(' ')[1] || "Unknown";

    // Format order for waiter app display (similar to kitchen, adjust as needed)
    const formattedOrder = {
      id: order._id.toString(),
      orderNumber: order._id.toString().slice(-6).toUpperCase(),
      items: order.items.map((item) => ({
        productId: item.productId || `prod_${item.name}`, // Ensure productId is present
        name: item.name,
        quantity: item.quantity,
        specialInstructions: item.specialInstructions || "",
        // Add other item details waiters might need
      })),
      orderType: order.orderType,
      tableId: order.TableId?.tableId || order.deviceId || tableName || "N/A", // Ensure tableId is present for Dine In
      status: order.status,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt || new Date(),
      // Add any other specific fields waiters might need
    };

    io.to(WAITER_APP_ROOM_KEY).emit("dine_in_order_ready", formattedOrder);
    logger.info(
      `Notified waiter apps in room '${WAITER_APP_ROOM_KEY}' about ready Dine In order: ${order._id}, Table: ${formattedOrder.tableId}`
    );
    return true;
  } catch (error) {
    logger.error(
      `Error notifying waiter apps about ready Dine In order ${order?._id}:`,
      error
    );
    return false;
  }
};

/**
 * Function to add to order.controller.js after order.save() in createOrder
 * Notifies all clients in the table room about the finalized order
 * @param {object} req - Express request object with io attached
 * @param {object} order - The newly created order
 */
export const notifyTableAboutFinalizedOrder = async (req, order) => {
  try {
    if (
      !req.io ||
      order.orderType !== "Dine In" ||
      !order.TableId ||
      !order.sessionId
    ) {
      return false;
    }

    const tableDoc = await Table.findById(order.TableId);
    if (!tableDoc) {
      logger.warn(
        `Table not found for order ${order._id} with TableId ${order.TableId}`
      );
      return false;
    }

    req.io.to(`table_${tableDoc.tableId}`).emit("table_order_finalized", {
      sessionId: order.sessionId.toString(),
      orderId: order._id.toString(),
      items: order.items.map((i) => ({
        menuItemId: i.menuItem.toString(),
        name: i.name,
        quantity: i.quantity,
        total: i.total,
      })),
      total: order.total,
      message: "Order has been placed for the table.",
    });

    logger.info(
      `Emitted 'table_order_finalized' for session ${order.sessionId} to room table_${tableDoc.tableId}`
    );
    return true;
  } catch (error) {
    logger.error(
      `Error notifying table about finalized order ${order?._id}:`,
      error
    );
    return false;
  }
};

/**
 * Notify Delivery Dispatch (e.g., livriha-main) about a Delivery order that is ready for pickup.
 * @param {object} io - Socket.IO server instance
 * @param {object} originalOrderData - The order object (mongoose document expected), potentially without populated user.
 */
export const notifyDeliveryDispatchAboutReadyOrder = async (io, originalOrderData) => {
  try {
    if (!originalOrderData || originalOrderData.orderType !== "Delivery" || originalOrderData.status !== "ready_for_pickup") {
      // Not a delivery order or not ready for pickup, so no notification needed for dispatch.
      // logger.info(`Order ${originalOrderData?._id} not eligible for delivery dispatch notification. Type: ${originalOrderData?.orderType}, Status: ${originalOrderData?.status}`);
      return false;
    }

    let order = originalOrderData;
    // Ensure 'user' is populated if order.user is just an ID or not fully populated
    // This is crucial for getting customer details like name and phone number.
    if (order.user && (!(typeof order.user === 'object' && order.user.fullName) || !order.user.phoneNumber) ) {
      const freshOrder = await Order.findById(order._id).populate('user').exec();
      if (freshOrder) {
        order = freshOrder; // Replace order with the freshly populated one
      } else {
        logger.error(`Order ${order._id} not found when attempting to populate user for delivery dispatch. Customer details might be incomplete.`);
        // Proceed with potentially unpopulated user data, or decide to not send if critical info is missing.
      }
    }

    const deliveryOrderPayload = {
      orderId: order._id.toString(),
      orderNumber: order.orderNumber || order._id.toString().slice(-6).toUpperCase(),
      items: order.items.map(item => ({
        menuItemId: item.menuItem ? item.menuItem.toString() : null,
        name: item.name,
        quantity: item.quantity,
        price: item.price,
        total: item.total,
        specialInstructions: item.specialInstructions || ""
      })),
      subtotal: order.subtotal,
      deliveryFee: order.deliveryFee,
      total: order.total,
      deliveryAddress: order.deliveryAddress, // Embedded object from Order model
      customerDetails: order.user && typeof order.user === 'object' ? { // Check if user is populated
        userId: order.user._id.toString(),
        name: order.user.fullName,       // Assumes User model has fullName
        phoneNumber: order.user.phoneNumber // Assumes User model has phoneNumber
      } : {
        name: "N/A",
        phoneNumber: "N/A" // Provide defaults if user not populated
      },
      paymentStatus: order.paymentStatus,
      paymentMethod: order.paymentMethod,
      deliveryInstructions: order.deliveryInstructions || "",
      createdAt: order.createdAt,
      orderTime: order.orderTime, // Field from Order model
      readyAt: order.readyAt || new Date(), // When it became ready, or now if not set
      // Optionally add restaurant details if livriha-main needs them
      // restaurantDetails: { name: "Your Restaurant Name", address: "Restaurant Address", phone: "Restaurant Phone" }
    };

    io.to(DELIVERY_DISPATCH_ROOM_KEY).emit("new_delivery_order_for_dispatch", deliveryOrderPayload);
    logger.info(`Notified delivery dispatchers in room '${DELIVERY_DISPATCH_ROOM_KEY}' about ready delivery order: ${order._id} for user ${deliveryOrderPayload.customerDetails.name}`);
    return true;

  } catch (error) {
    const orderIdForLog = originalOrderData && originalOrderData._id ? originalOrderData._id : 'unknown';
    logger.error(`Error in notifyDeliveryDispatchAboutReadyOrder for order ${orderIdForLog}:`, error);
    return false;
  }
};

export const broadcastStockChange = async (
  io,
  ingredient,
  sourceOfChange = "unknown"
) => {
  try {
    // Récupérer les détails complets et à jour de l'ingrédient depuis la DB
    // const ingredient = await Ingredient.findById(ingredientId);
    // if (!ingredient) {
    //   logger.warn(`broadcastStockChange: Ingrédient ${ingredientId} non trouvé. Impossible de diffuser.`);
    //   return;
    // }

    const stockDataForBroadcast = {
      ingredientId: ingredient._id.toString(),
      name: ingredient.name,
      unit: ingredient.unit,
      stock: ingredient.stock, // Le stock actuel depuis la DB
      lowStockThreshold: ingredient.lowStockThreshold,
      category: ingredient.category,
      timestamp: new Date(),
      sourceOfChange: sourceOfChange, // Pour savoir d'où vient la modif (ex: 'iot_simulator', 'order_creation')
    };

    // 1. Notifier l'Application Gérant

    io.to(MANAGER_APP_ROOM_KEY).emit(
      "stock_level_changed",
      stockDataForBroadcast
    );
    logger.info(
      `Diffusé 'stock_level_changed' aux managers pour ${ingredient.name}, ${ingredient.stock}. Source: ${sourceOfChange}`
    );

    // 2. Notifier le Simulateur de Stock IoT pour qu'il synchronise son état
    //    (surtout si le changement ne vient pas de lui, comme via 'createOrder')
    const STOCK_SIMULATOR_DEVICE_ID = "stock_manager_sim_1"; // L'ID de votre simulateur de stock
    const stockSimulatorRoom = `iot_device_${STOCK_SIMULATOR_DEVICE_ID}`;

    // On n'envoie la synchro que si la source n'est pas le simulateur lui-même
    // ou si vous voulez toujours envoyer pour confirmer/forcer la synchro.
    // Pour l'instant, envoyons toujours pour que le simulateur soit le reflet exact de la DB.
    io.to(stockSimulatorRoom).emit("stock_level_sync", stockDataForBroadcast);
    logger.info(
      `Diffusé 'stock_level_sync' au simulateur de stock ${STOCK_SIMULATOR_DEVICE_ID} pour ${ingredient.name}.`
    );
  } catch (error) {
    logger.error(
      `Erreur dans broadcastStockChange pour ingredientId ${ingredient}:`,
      error
    );
  }
};

export async function broadcastTableUpdateToChefs(io, tableMongoObject) {
  if (!tableMongoObject) {
    logger.warn(
      "broadcastTableUpdateToChefs: tableMongoObject est null ou undefined."
    );
    return;
  }

  let populatedTable = tableMongoObject;
  // S'assurer que currentSession est peuplé si nécessaire pour obtenir les détails du client
  if (
    tableMongoObject.currentSession &&
    typeof tableMongoObject.currentSession.populate !== "function"
  ) {
    // Si currentSession est juste un ID, il faut le peupler.
    // Si votre modèle Table ne peuple pas automatiquement currentSession.clientId, faites-le ici.
    // Ceci est un exemple, adaptez selon comment vous récupérez `tableMongoObject`
    try {
      const freshTable = await Table.findById(tableMongoObject._id).populate({
        path: "currentSession",
        populate: {
          path: "clientId",
          select: "fullName _id", // Sélectionnez les champs nécessaires de l'utilisateur
        },
      });
      if (freshTable) populatedTable = freshTable;
    } catch (err) {
      logger.error(
        `Erreur lors du peuplement de la session pour la table ${tableMongoObject._id}: ${err}`
      );
    }
  }

  let sessionDetails = null;
  if (populatedTable.status === "occupied" && populatedTable.currentSession) {
    const session = populatedTable.currentSession; // Devrait être l'objet session peuplé
    const client = session.clientId; // Devrait être l'objet client peuplé

    sessionDetails = {
      sessionId: session._id.toString(),
      // Assurez-vous que clientId est bien l'objet User peuplé
      // ou au moins que vous avez accès à son _id et fullName
      customerId: client?._id?.toString(),
      customerName: client?.fullName,
      startTime: session.startTime?.toISOString(),
    };
  }

  const tableDataForChef = {
    _id: populatedTable._id.toString(), // Pour TableModel.id (ObjectId de Mongoose Table)
    tableId: populatedTable.tableId, // Pour TableModel.tabletDeviceId (String unique de la tablette)
    name:
      populatedTable.name ||
      `Table ${
        populatedTable.tableId ? populatedTable.tableId.slice(-4) : "N/A"
      }`, // Nom de la table
    status: populatedTable.status,
    isActive: populatedTable.isActive,
    currentSession: populatedTable.currentSession?._id?.toString(), // ObjectId de la session Mongoose
    // Inclure les détails de la session directement pour simplifier le modèle Flutter
    currentSessionId: sessionDetails?.sessionId, // Répète l'ID de session pour correspondre à TableModel Flutter
    currentCustomerId: sessionDetails?.customerId,
    currentCustomerName: sessionDetails?.customerName,
    sessionStartTime: sessionDetails?.startTime,
    // Ajoutez d'autres champs que TableModel.fromAPI attendrait
  };

  io.to(CHEF_APP_ROOM_KEY).emit("table_status_update", tableDataForChef);
  logger.info(
    `Broadcasted 'table_status_update' to chefs for table ${populatedTable.tableId} (MongoID: ${populatedTable._id})`
  );
}
