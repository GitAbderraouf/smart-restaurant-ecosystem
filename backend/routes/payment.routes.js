import express from "express"
import {
  createPaymentIntent,
  processPaymentSuccess,
  processWalletPayment,
  processCOD,
  addToWallet,
  confirmWalletTopup,
  getWallet,
  stripeWebhook,
  sendToBank,
} from "../controllers/payment.controller.js"
import { protect } from "../middlewares/auth.middleware.js"

const router = express.Router()

// Payment intent routes
router.post("/create-payment-intent", createPaymentIntent)
router.post("/success",  processPaymentSuccess)

// Wallet routes
router.post("/wallet",  processWalletPayment)
router.get("/wallet",  getWallet)
router.post("/add-to-wallet",  addToWallet)
router.post("/confirm-wallet-topup",  confirmWalletTopup)
router.post("/send-to-bank",  sendToBank)

// COD route
router.post("/cod",  processCOD)

// Stripe webhook
router.post("/webhook", express.raw({ type: "application/json" }), stripeWebhook)

export default router
