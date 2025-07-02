// models/refrigerator.model.js
import mongoose from "mongoose";

const refrigeratorSchema = new mongoose.Schema(
  {
    deviceId: { // Identifiant unique pour le simulateur et la communication socket
      type: String,
      required: [true, "L'identifiant de l'appareil (deviceId) est requis."],
      unique: true,
      trim: true,
      // Exemple: "fridge_sim_1"
    },
    friendlyName: { // Nom lisible pour l'interface d'administration/gérant
      type: String,
      required: [true, "Un nom convivial pour le réfrigérateur est requis."],
      trim: true,
      default: "Réfrigérateur Connecté",
    },
    deviceType: {
      type: String,
      default: "refrigerator",
    },
    status: {
      type: String,
      enum: ["on", "off", "cooling", "idle", "door_open", "error"],
      default: "off",
    },
    currentTemperature: {
      type: Number,
      default: 4, // Température typique en °C
    },
    targetTemperature: {
      type: Number,
      default: 4, // Température cible en °C
    },
    location: { // Où se trouve physiquement cet appareil
      type: String,
      trim: true,
      optional: true,
    },
    // Pourrait inclure des alertes spécifiques, comme mentionné dans votre rapport [cite: 104]
    // alerts: [{
    //   type: String, // ex: "temperature_high", "door_ajar"
    //   message: String,
    //   timestamp: Date,
    //   severity: String // "warning", "critical"
    // }],
    lastReportedAt: { // Quand le simulateur a envoyé des données pour la dernière fois
      type: Date,
    },
    // Champs additionnels potentiels basés sur "suivi potentiel produits" [cite: 104]
    // monitoredProducts: [{
    //   productId: { type: mongoose.Schema.Types.ObjectId, ref: 'Product' }, // si vous avez un modèle Produit
    //   quantity: Number,
    //   addedAt: Date,
    //   expiresAt: Date
    // }],
    notes: {
      type: String,
      trim: true,
      optional: true,
    }
  },
  {
    timestamps: true, // Ajoute createdAt et updatedAt automatiquement
  }
);

const Refrigerator = mongoose.model("Refrigerator", refrigeratorSchema);

export default Refrigerator;