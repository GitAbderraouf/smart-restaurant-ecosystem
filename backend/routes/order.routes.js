import express from "express"
import {
  createOrder,
  getOrderDetails,
  updateOrderStatus,
  getOrdersByUser,
  getOrdersBySession,
  getKitchenOrders,
  updatePaymentStatus,
  getCompletedKitchenOrders,
  getMyOrders,
  submitOrderRatings,
  getReadyDineInOrdersForWaiter,
  markOrderAsServedByWaiter,
  getServedDineInOrdersForWaiter,
  getPendingAndReadyOrders,
  getServedOrders,
  getAllOrders,
  getDeliveredOrders,
  acceptDeliveryTask,
  confirmDelivery
} from '../controllers/order.controller.js';
import { protect , isAdmin } from "../middlewares/auth.middleware.js"

const router = express.Router()

// Define MOST SPECIFIC non-parameterized routes first
router.get("/kitchen/completed",  getCompletedKitchenOrders);
router.get("/kitchenn/active",   getKitchenOrders); // Potential typo: "kitchenn"
router.get("/waiter/ready",  getReadyDineInOrdersForWaiter);
router.get("/waiter/served-dine-in", getServedDineInOrdersForWaiter);
router.get("/pending-ready",  getPendingAndReadyOrders);
router.get("/served",   getServedOrders);
router.get("/delivered", getDeliveredOrders);

// General routes (like POST to "/")
router.post("/", createOrder); // Removed protect for kiosk app
router.get("/", protect,getMyOrders); // Root GET for orders, protected
router.get("/all", getAllOrders);
// THEN Parameterized routes
router.get("/:orderId", protect, getOrderDetails); 
router.put("/:orderId/status",  updateOrderStatus); 
router.put("/:orderId/payment", protect, updatePaymentStatus);
router.get("/user/:userId", protect, getOrdersByUser); // Matches /user/some-user-id
router.get("/session/:sessionId", getOrdersBySession); // Matches /session/some-session-id // Removed protect for kiosk app?
router.post("/:orderId/rate-items", protect,submitOrderRatings)
router.put("/:orderId/mark-served", markOrderAsServedByWaiter);

// New specific routes for delivery lifecycle
router.put("/:orderId/accept-task", acceptDeliveryTask);       // For driver accepting a task
router.put("/:orderId/confirm-delivery", confirmDelivery);  // For driver confirming delivery

// --- Old position of completed route (removed) ---
// router.get("/completed", /* verifyToken, verifyAdmin, */ getCompletedKitchenOrders);

export default router; 