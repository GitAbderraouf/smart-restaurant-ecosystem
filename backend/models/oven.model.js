// models/oven.model.js
import mongoose from "mongoose";

const ovenSchema = new mongoose.Schema(
  {
    deviceId: { // Identifiant unique pour le simulateur et la communication socket
      type: String,
      required: [true, "L'identifiant de l'appareil (deviceId) est requis."],
      unique: true,
      trim: true,
      // Exemple: "oven_sim_1"
    },
    friendlyName: { // Nom lisible
      type: String,
      required: [true, "Un nom convivial pour le four est requis."],
      trim: true,
      default: "Four Connecté",
    },
    deviceType: {
      type: String,
      default: "oven",
    },
    status: {
      type: String,
      enum: ["on", "off", "preheating", "heating", "cooling_down", "idle", "error"],
      default: "off",
    },
    currentTemperature: {
      type: Number,
      default: 20, // Température ambiante en °C
    },
    targetTemperature: {
      type: Number,
      default: 180, // Température cible typique en °C
    },
    mode: { // Mode de cuisson, comme mentionné pour le "Four Intelligent" [cite: 107]
      type: String,
      enum: ["bake", "grill", "convection", "defrost", "keep_warm", "off"],
      default: "off",
    },
    isLightOn: {
      type: Boolean,
      default: false,
    },
    isDoorOpen: { // Un capteur de porte pourrait être pertinent pour un four intelligent
      type: Boolean,
      default: false,
    },
    remainingTimeSeconds: { // Temps de cuisson restant en secondes
      type: Number,
      default: 0,
    },
    location: {
      type: String,
      trim: true,
      optional: true,
    },
    // Pourrait inclure des alertes spécifiques, comme mentionné dans votre rapport [cite: 107]
    // alerts: [{
    //   type: String, // ex: "preheat_complete", "cooking_complete", "temperature_error"
    //   message: String,
    //   timestamp: Date
    // }],
    lastReportedAt: {
      type: Date,
    },
    notes: {
      type: String,
      trim: true,
      optional: true,
    }
  },
  {
    timestamps: true, // Ajoute createdAt et updatedAt
  }
);

const Oven = mongoose.model("Oven", ovenSchema);

export default Oven;