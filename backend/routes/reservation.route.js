import express from "express";
import {
    getAvailability,
    createReservation,
    getReservations,
    getConfirmedReservations,
    getCompletedReservations,
    getCancelledReservations,
    cancelReservation,
    getReservationsByDateRange
} from "../controllers/reservation.controller.js";
import { protect, isAdmin } from "../middlewares/auth.middleware.js";

const router = express.Router();

// Public routes
router.get("/availability", getAvailability);
router.get("/confirmed",   getConfirmedReservations);
router.get("/completed",  getCompletedReservations);
router.get("/cancelled",  getCancelledReservations);
router.patch("/:reservationId/cancel", cancelReservation);
// Protected routes for regular users
router.get('/date-range',  getReservationsByDateRange);
router.post("/", protect, createReservation);
router.get("/", protect, getReservations);

// Admin routes for reservation management


export default router;
