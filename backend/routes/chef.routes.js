import express from "express";
import { getAllTablesWithStatus, verifyReservationByQR,notifyKitchenOfPreOrder,getReservationsForTable } from "../controllers/tableChef.controller.js";

const router = express.Router();


router.get("/tables", getAllTablesWithStatus);
router.get('/tables/:tableMongoId/reservations', getReservationsForTable);
router.get('/reservations/verify-qr/:reservationId', verifyReservationByQR);
router.post('/kitchen/notify-preorder', notifyKitchenOfPreOrder);

export default router;