// ingredient.model.js
import mongoose from "mongoose";

const ingredientCategories = [
  'Boulangerie',
  'Viandes & Volailles',
  'Alternatives Végétales',
  'Fromages & Produits Laitiers',
  'Sauces & Condiments',
  'Légumes',
  'Accompagnements',
  'Herbes & Aromates',
  'Condiments & Conserves',
  'Fruits',
  'Épices & Assaisonnements',
  'Féculents & Céréales',
  'Poissons & Fruits de Mer',
  'Produits Frais',
  'Fruits Secs',
  'Préparations',
  'Épicerie Sucrée',
  'Boissons & Caféterie',
  'Desserts & Glaces',
  'Épicerie Sèche'
  // Ajoutez 'Autre' si vous pensez en avoir besoin pour des cas non listés
];

const ingredientSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, "Le nom de l'ingrédient est requis."],
      unique: true, // Assure que chaque nom d'ingrédient est unique
      trim: true,   // Enlève les espaces superflus
    },
    unit: {
      type: String,
      required: [true, "L'unité de mesure est requise (ex: g, kg, ml, l, pièce)."],
      trim: true,
    },
    stock: {
      type: Number,
      required: [true, "Le stock actuel est requis."],
      default: 0,
      min: [0, "Le stock ne peut pas être négatif."],
    },
    // Optionnel: Seuil de stock bas pour alertes
    lowStockThreshold: {
        type: Number,
        default: 0,
    },


// Dans votre ingredient.model.js
// ...
category: {
  type: String,
  required: [true, "La catégorie de l'ingrédient est requise."],
  trim: true,
  enum: ingredientCategories 
},
    // Optionnel: Fournisseur, coût, etc.
    // supplier: { type: String },
    // costPerUnit: { type: Number },
  },
  {
    timestamps: true, // Ajoute createdAt et updatedAt
  }
);

const Ingredient = mongoose.model("Ingredient", ingredientSchema);

export default Ingredient;