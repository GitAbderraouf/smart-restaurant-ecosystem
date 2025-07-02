import express from "express";
import multer from "multer";
import path from "path";
import fs from "fs";

import {
  createMenuItem,
  deleteMenuItem,
  getAllMenuItems,
  getMenuItemDetails,
  getMenuItemsByCategory,
  getMenuItemsByCategoryForAdmin,
  getMenuItemsByDietary,
  getMenuItemsByHealth,
  getPopularMenuItems,
  searchMenuItems,
  updateMenuItem,
  getMenuItemIngredients,
  getAllMasterIngredients,
  getAllStockInfo
} from "../controllers/menu-item.controller.js";
import { isAdmin } from "../middlewares/auth.middleware.js";
import { authenticate } from '../controllers/auth.controller.js';

const router = express.Router();

// --- Multer Configuration for Image Uploads ---
const UPLOADS_DIR = './uploads';

// Ensure uploads directory exists
if (!fs.existsSync(UPLOADS_DIR)){
    fs.mkdirSync(UPLOADS_DIR, { recursive: true });
}

const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, UPLOADS_DIR); // Save files to the 'uploads' directory
    },
    filename: function (req, file, cb) {
        // Create a unique filename: fieldname-timestamp.extension
        cb(null, file.fieldname + '-' + Date.now() + path.extname(file.originalname));
    }
});

const fileFilter = (req, file, cb) => {
    // Accept images only
    if (file.mimetype.startsWith('image/')) {
        cb(null, true);
    } else {
        cb(new Error('Not an image! Please upload only images.'), false);
    }
};

const upload = multer({ 
    storage: storage, 
    limits: {
        fileSize: 1024 * 1024 * 5 // 5MB file size limit
    },
    fileFilter: fileFilter 
});
// --- End Multer Configuration ---

router.get("/", getAllMenuItems);
router.get("/popular", getPopularMenuItems);
router.get("/search", searchMenuItems);
router.get("/category/:categoryName", getMenuItemsByCategory);
router.get("/dietary/:preference", getMenuItemsByDietary);
router.get("/health/:preference", getMenuItemsByHealth);
router.get("/:itemId", getMenuItemDetails);
router.get("/admin/category/:categoryName", getMenuItemsByCategoryForAdmin);
router.get("/:itemId/ingredients", getMenuItemIngredients);
router.get("/ingredients/all-master", getAllMasterIngredients);

// Add the new route for getting all stock information
router.get("/ingredients/stock", getAllStockInfo);

// Use multer middleware for the createMenuItem route to handle single file upload for 'imageFile' field
router.post(
    "/",
    upload.single('imageFile'), // Multer middleware for single file named 'imageFile'
    createMenuItem
);

// For update, we might also want to handle image uploads similarly
// This is a placeholder, decide if update also uses multipart or sticks to base64/URL for image field
router.put(
    "/:itemId",
    authenticate,
    isAdmin,
    upload.single('imageFile'), // Potentially add multer here too if updating with file upload
    updateMenuItem
);

router.delete(
    "/:itemId",
    authenticate, 
    isAdmin,      
    deleteMenuItem
);

export default router;