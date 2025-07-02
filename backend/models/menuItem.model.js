import mongoose from "mongoose";


const menuItemSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    description: { type: String },
    price: { type: Number, required: true },
    image: { type: String },
    category: {
      type: String, 
      required: true,
    },
    dietaryInfo: {
      vegetarian: Boolean,
      vegan: Boolean,
      glutenFree: Boolean,
      lactoseFree: Boolean,
    },
    healthInfo: {
      low_carb: Boolean,
      low_fat: Boolean,
      low_sugar: Boolean,
      low_sodium: Boolean,
    },
    ingredients: [
      {
        ingredient: { // Utilisation de ObjectId et ref
          type: mongoose.Schema.Types.ObjectId,
          ref: "Ingredient", // Référence au modèle Ingredient
          required: true,
        },
        quantity: {
          type: Number,
          required: [true, "La quantité de l'ingrédient est requise."],
          min: [0, "La quantité ne peut pas être négative."],
        },
        unit: { // Unité pour la quantité DANS CETTE RECETTE
            type: String,
            required: [true, "L'unité de l'ingrédient pour cette recette est requise."]
        }
      },
    ],
    isAvailable: { type: Boolean, default: true },
    isPopular: { type: Boolean, default: false },
    preparationTime: { type: Number }, 
    
    matrixIndex: { type: Number, unique: true, sparse: true },
    cfFeatures: { 
      type: [Number], 
      default: () => Array(10).fill(0).map(() => Math.random())
    },
    
  },
  {
    timestamps: true,
  },
);

const MenuItem = mongoose.model("MenuItem", menuItemSchema);
export default MenuItem;