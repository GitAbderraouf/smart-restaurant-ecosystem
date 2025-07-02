import express from "express"
import {
  getBillById,
  getBillByTableSession,
  getAllBills,
  updateBillPaymentStatus,
  generateBillForSession,
  endSessionAndGenerateBill,
  getMyUnpaidBills,
  markBillAsPaid,
} from "../controllers/bill.controller.js"
import { protect } from "../middlewares/auth.middleware.js"
import { isAdmin } from "../middlewares/auth.middleware.js";

const router = express.Router()

// Public routes
//router.get("/:billId", getBillById)
//router.get("/session/:sessionId", getBillByTableSession)
router.get("/my-unpaid",protect,getMyUnpaidBills)
router.post("/:billId/mark-as-paid",protect,markBillAsPaid)
// Admin routes
// router.get("/", protect, isAdmin, getAllBills)
// router.put("/:billId/payment", protect, updateBillPaymentStatus)
// router.post("/session/:sessionId", protect, generateBillForSession)
// router.post("/session/:sessionId/end",isAdmin , endSessionAndGenerateBill)
router.get("/:billId", getBillById)
router.get("/session/:sessionId", getBillByTableSession)

// Admin routes
router.get("/", protect, isAdmin, getAllBills)
router.put("/:billId/payment", protect, updateBillPaymentStatus)
router.post("/session/:sessionId", protect, generateBillForSession)
router.post("/session/:sessionId/end",isAdmin , endSessionAndGenerateBill)

export default router
