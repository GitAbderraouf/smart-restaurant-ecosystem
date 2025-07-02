// order.model.js (Updated)
import mongoose from "mongoose";

const orderItemSchema = new mongoose.Schema({
  menuItem: { type: mongoose.Schema.Types.ObjectId, ref: "MenuItem", required: true },
  name: { type: String, required: true },
  price: { type: Number, required: true },
  quantity: { type: Number, required: true, default: 1 },
  total: { type: Number, required: true },
  specialInstructions: { type: String },
  image: { type: String },
  currentUserRating: { type: Number },
  addons: [
    {
      name: { type: String },
      price: { type: Number },
    },
  ],
});

const orderSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: "User"},
    items: [orderItemSchema],
    TableId: { type: mongoose.Schema.Types.ObjectId, ref: "Table" },
    subtotal: { type: Number, required: true },
    deliveryFee: { type: Number, required: true },
    total: { type: Number, required: true },
    orderType: {
      type: String,
      enum: ["Take Away", "Delivery", "Dine In"],
      required: true,
    },
    status: {
      type: String,
      enum: ["pending", "confirmed", "preparing", "ready_for_pickup", "out_for_delivery", "delivered", "cancelled", "served" , 'accepted'],
      default: "pending",
    },
    //add now 
    orderTime: { type: Date }, // Timestamp when order was created
    readyAt: { type: Date }, // Timestamp when order was marked as ready_for_pickup
    paymentStatus: { type: String, enum: ["pending", "paid", "failed"], default: "pending" },
    paymentMethod: { type: String, enum: ["card", "cash", "wallet"], default: "cash" },
    paymentId: { type: String },
    deliveryAddress: {
      label: { type: String },
      // Champ Optionnel pour garder l'ID Google Places/maps_local si utile
      place_id: { type: String },
      // Vos champs existants (type et address devraient aussi être requis logiquement)
      type: {
        type: String,
        enum: ["home", "office", "other"],
        default: "home",
        required: true,
      }, // Rendu requis
      address: { type: String, required: true },
      apartment: { type: String },
      building: { type: String },
      landmark: { type: String },
      // Latitude et Longitude sont souvent essentielles pour la livraison
      latitude: { type: Number, required: true }, // Rendu requis
      longitude: { type: Number, required: true }, // Rendu requis
      isDefault: { type: Boolean, default: false },
    },
    deliveryInstructions: { type: String },
    estimatedDeliveryTime: { type: Date },
    actualDeliveryTime: { type: Date },
    driverId: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
  },
  {
    timestamps: true,
  }
);

export const Order = mongoose.model("Order", orderSchema);