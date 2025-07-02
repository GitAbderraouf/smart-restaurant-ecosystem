import mongoose from 'mongoose';
import MenuItem from "../models/menuItem.model.js";
import Ingredient from "../models/ingredients.model.js";
import { uploadImage, deleteImage } from "../services/cloudinaryService.js";
// Import Redis service
import redisService, { getCache, setCache, deleteCache, getValue, setValue } from '../services/redis.service.js';
import logger from '../middlewares/logger.middleware.js';
import fs from 'fs'; // Import fs to delete temp file after upload

// Cache key constants
const ALL_MENU_ITEMS_CACHE = 'menu:all';
const MENU_ITEM_DETAILS_CACHE_PREFIX = 'menu:item:';
const POPULAR_MENU_ITEMS_CACHE = 'menu:popular';
const SEARCH_MENU_ITEMS_CACHE_PREFIX = 'menu:search:';
const DIETARY_MENU_ITEMS_CACHE_PREFIX = 'menu:dietary:';
const HEALTH_MENU_ITEMS_CACHE_PREFIX = 'menu:health:';
const MENU_ITEM_INGREDIENTS_CACHE_PREFIX = 'menu:item:ingredients:';
const ALL_MASTER_INGREDIENTS_CACHE = 'ingredients:master:all';
const ALL_STOCK_INFO_CACHE = 'ingredients:stock:all';
// Cache expiration time (e.g., 1 hour)
const CACHE_EXPIRATION = 3600;
const ALL_STOCK_INFO_CACHE_EXPIRATION = 60; // 5 minutes
// Get all menu items
export const getAllMenuItems = async (req, res, next) => {
  try {
    // Try to get from cache first
    if (redisService.isConnected()) {
      const cachedMenuItems = await getCache(ALL_MENU_ITEMS_CACHE);
      if (cachedMenuItems) {
        logger.info(`Cache hit for key: ${ALL_MENU_ITEMS_CACHE}`);
        return res.status(200).json({ menuItems: cachedMenuItems });
      }
      logger.info(`Cache miss for key: ${ALL_MENU_ITEMS_CACHE}`);
    } else {
      logger.warn(`Redis not connected, skipping cache check for key: ${ALL_MENU_ITEMS_CACHE}`);
    }

    // No population needed or possible for a string category
    const menuItems = await MenuItem.find({ isAvailable: true });

    // Format response (category is just a string)
    const formattedMenuItems = menuItems.map((item) => ({
      id: item._id,
      name: item.name,
      description: item.description,
      price: item.price,
      image: item.image,
      category: item.category, // Direct string access
      dietaryInfo: item.dietaryInfo,
      healthInfo: item.healthInfo,
      isPopular: item.isPopular,
      preparationTime: item.preparationTime,
      addons: item.addons,
    }));

    // Store in cache if Redis is connected
    if (redisService.isConnected()) {
      await setCache(ALL_MENU_ITEMS_CACHE, formattedMenuItems, CACHE_EXPIRATION);
      logger.info(`Cached data for key: ${ALL_MENU_ITEMS_CACHE}`);
    }

    res.status(200).json({ menuItems: formattedMenuItems });
  } catch (error) {
    next(error);
  }
};

// Get menu items by category name - KEEPING EXISTING IMPLEMENTATION
export const getMenuItemsByCategory = async (req, res, next) => {
  const { categoryName } = req.params; // Get category name from params

  if (!categoryName) {
    return res.status(400).json({ message: "Category name parameter is required." });
  }

  // Define a unique cache key for this category
  const cacheKey = `menu:category:${categoryName}`;

  try {
    // 1. Try fetching from cache first
    if (redisService.isConnected()) {
      const cachedMenuItems = await getCache(cacheKey);
      if (cachedMenuItems) {
        logger.info(`Cache hit for key: ${cacheKey}`);
        return res.status(200).json({ menuItems: cachedMenuItems });
      }
      logger.info(`Cache miss for key: ${cacheKey}`);
    } else {
       logger.warn(`Redis not connected, skipping cache check for key: ${cacheKey}`);
    }


    // 2. If cache miss or Redis not connected, fetch from DB
    const menuItems = await MenuItem.find({
      category: categoryName,
      isAvailable: true,
    });

    // Format response
    const formattedMenuItems = menuItems.map((item) => ({
      id: item._id,
      name: item.name,
      description: item.description,
      price: item.price,
      image: item.image,
      category: item.category, // Direct string access
      dietaryInfo: item.dietaryInfo,
      healthInfo: item.healthInfo,
      preparationTime: item.preparationTime,
      isPopular: item.isPopular,
      addons: item.addons,
    }));

     // 3. Store the result in cache if Redis is connected
     if (redisService.isConnected()) {
        await setCache(cacheKey, formattedMenuItems, CACHE_EXPIRATION);
        logger.info(`Cached data for key: ${cacheKey}`);
     }


    res.status(200).json({ menuItems: formattedMenuItems });
  } catch (error) {
    next(error);
  }
};


export const getMenuItemsByCategoryForAdmin = async (req, res, next) => {
  const { categoryName } = req.params; // Get category name from params

  if (!categoryName) {
    return res.status(400).json({ message: "Category name parameter is required." });
  }

  // Define a unique cache key for admin category view (different from user view)
  const cacheKey = `menu:admin:category:${categoryName}`;

  try {
    // 1. Try fetching from cache first
    if (redisService.isConnected()) {
      const cachedMenuItems = await getCache(cacheKey);
      if (cachedMenuItems) {
        logger.info(`Cache hit for admin category view: ${cacheKey}`);
        return res.status(200).json({ menuItems: cachedMenuItems });
      }
      logger.info(`Cache miss for admin category view: ${cacheKey}`);
    } else {
      logger.warn(`Redis not connected, skipping cache check for admin category view: ${cacheKey}`);
    }

    // 2. If cache miss or Redis not connected, fetch from DB
    // Note: No filter for isAvailable - we want all items for admin view
    const menuItems = await MenuItem.find({
      category: categoryName
    });

    // Format response - include isAvailable status
    const formattedMenuItems = menuItems.map((item) => ({
      id: item._id,
      name: item.name,
      description: item.description,
      price: item.price,
      image: item.image,
      category: item.category,
      dietaryInfo: item.dietaryInfo,
      healthInfo: item.healthInfo,
      preparationTime: item.preparationTime,
      isPopular: item.isPopular,
      isAvailable: item.isAvailable, // Include availability status for admin
      addons: item.addons,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt
    }));

    // 3. Store the result in cache if Redis is connected
    if (redisService.isConnected()) {
      // Use a shorter cache expiration for admin views since they might need to see changes sooner
      const ADMIN_CACHE_EXPIRATION = 300; // 5 minutes
      await setCache(cacheKey, formattedMenuItems, ADMIN_CACHE_EXPIRATION);
      logger.info(`Cached admin category data for key: ${cacheKey}`);
    }

    res.status(200).json({ 
      menuItems: formattedMenuItems,
      totalCount: formattedMenuItems.length,
      availableCount: formattedMenuItems.filter(item => item.isAvailable).length
    });
  } catch (error) {
    logger.error(`Error in getMenuItemsByCategoryForAdmin: ${error.message}`, error);
    next(error);
  }
};
// Get menu item details
export const getMenuItemDetails = async (req, res, next) => {
  try {
    const { itemId } = req.params;
    const cacheKey = `${MENU_ITEM_DETAILS_CACHE_PREFIX}${itemId}`;

    // Try to get from cache first
    if (redisService.isConnected()) {
      const cachedMenuItem = await getCache(cacheKey);
      if (cachedMenuItem) {
        logger.info(`Cache hit for key: ${cacheKey}`);
        return res.status(200).json({ menuItem: cachedMenuItem });
      }
      logger.info(`Cache miss for key: ${cacheKey}`);
    } else {
      logger.warn(`Redis not connected, skipping cache check for key: ${cacheKey}`);
    }

    // No population needed
    const menuItem = await MenuItem.findById(itemId);

    if (!menuItem) {
      return res.status(404).json({ message: "Menu item not found" });
    }

    // Format response (category is a string)
    const formattedMenuItem = {
      id: menuItem._id,
      name: menuItem.name,
      description: menuItem.description,
      price: menuItem.price,
      image: menuItem.image,
      category: menuItem.category, // Direct string access
      dietaryInfo: menuItem.dietaryInfo,
      healthInfo: menuItem.healthInfo,
      preparationTime: menuItem.preparationTime,
      isPopular: menuItem.isPopular,
      addons: menuItem.addons,
    };

    // Store in cache if Redis is connected
    if (redisService.isConnected()) {
      await setCache(cacheKey, formattedMenuItem, CACHE_EXPIRATION);
      logger.info(`Cached data for key: ${cacheKey}`);
    }

    res.status(200).json({ menuItem: formattedMenuItem });
  } catch (error) {
    next(error);
  }
};

// Create new menu item
export const createMenuItem = async (req, res, next) => {
  try {
    const {
      name,
      description,
      price,
      category, 
      dietaryInfo, // Expected as array of strings e.g. ["vegetarian", "glutenFree"]
      healthInfo,  // Expected as array of strings
      ingredients, // Expected as array of { name, quantity, unit, id? (optional master ingredient id) }
      isAvailable,
      isPopular,
      preparationTime,
      cfFeatures,
      matrixIndex,
    } = req.body;
    // Image is now handled by req.file if uploaded, or can fallback to req.body.image (e.g. URL for existing image)
    let imageFromBody = req.body.image; 

    if (!name || !price || !category) {
      return res
        .status(400)
        .json({ message: "Name, price, and category are required" });
    }

    let imageUrl = null; 

    if (req.file) { // A file was uploaded via multer
      try {
        const uploadResult = await uploadImage(req.file.path, "hungerz_kiosk/menu_items");
        imageUrl = uploadResult.secure_url;
        // Clean up the temporarily stored file after successful upload to Cloudinary
        fs.unlink(req.file.path, (err) => {
          if (err) logger.error('Failed to delete temporary uploaded file:', err);
        });
      } catch (uploadError) {
         logger.error("Cloudinary service upload error during create (from file):", uploadError);
         // Attempt to clean up file even if upload failed
         if (req.file && req.file.path) {
            fs.unlink(req.file.path, (err) => {
              if (err) logger.error('Failed to delete temporary file after failed upload:', err);
            });
         }
         return next(uploadError);
      }
    } else if (imageFromBody && typeof imageFromBody === 'string') { 
      // No file uploaded, but an image string (URL or base64) might be in the body
      // This retains compatibility if you pass a direct URL or base64 (though base64 for new uploads is discouraged now)
      try {
        // uploadImage service can handle URLs or base64 if it's designed to
        const uploadResult = await uploadImage(imageFromBody, "hungerz_kiosk/menu_items");
        imageUrl = uploadResult.secure_url;
      } catch (uploadError) {
         logger.error("Cloudinary service upload error during create (from body string):", uploadError);
         return next(uploadError);
      }
    }

    // Process dietaryInfo from array to object
    const processedDietaryInfo = {};
    const allDietaryKeys = ['vegetarian', 'vegan', 'glutenFree', 'lactoseFree'];
    allDietaryKeys.forEach(key => processedDietaryInfo[key] = false);
    if (dietaryInfo && Array.isArray(dietaryInfo)) {
      dietaryInfo.forEach(tag => {
        if (allDietaryKeys.includes(tag)) {
          processedDietaryInfo[tag] = true;
        }
      });
    }

    // Process healthInfo from array to object
    const processedHealthInfo = {};
    const allHealthKeys = ['low_carb', 'low_fat', 'low_sugar', 'low_sodium'];
    allHealthKeys.forEach(key => processedHealthInfo[key] = false);
    if (healthInfo && Array.isArray(healthInfo)) {
      healthInfo.forEach(tag => {
        if (allHealthKeys.includes(tag)) {
          processedHealthInfo[tag] = true;
        }
      });
    }

    // Process ingredients
    const processedIngredients = [];
    if (ingredients && Array.isArray(ingredients)) {
      for (const ingData of ingredients) {
        let foundIngredientRef;
        // Prefer ID if valid ObjectId is provided, otherwise fallback to name
        if (ingData.id && mongoose.Types.ObjectId.isValid(ingData.id)) {
          foundIngredientRef = await Ingredient.findById(ingData.id);
        }
        if (!foundIngredientRef && ingData.name) { 
          foundIngredientRef = await Ingredient.findOne({ name: ingData.name });
        }

        if (foundIngredientRef) {
          if (ingData.quantity !== undefined && ingData.unit !== undefined) {
            processedIngredients.push({
              ingredient: foundIngredientRef._id,
              quantity: parseFloat(ingData.quantity),
              unit: ingData.unit,
            });
          } else {
            logger.warn(`Skipping ingredient '${ingData.name || ingData.id}' for new menu item due to missing quantity or unit.`);
          }
        } else {
          logger.warn(`Master ingredient with id '${ingData.id}' or name '${ingData.name}' not found. Skipping for new menu item.`);
        }
      }
    }

    const menuItem = new MenuItem({
      name,
      description,
      price,
      image: imageUrl,
      category,
      dietaryInfo: processedDietaryInfo, // Use processed object
      healthInfo: processedHealthInfo,   // Use processed object
      ingredients: processedIngredients, // Use processed ingredients list
      cfFeatures,
      matrixIndex,
      isAvailable: isAvailable !== undefined ? isAvailable : true,
      isPopular: isPopular !== undefined ? isPopular : false,
      preparationTime: preparationTime || 15,
    });

    await menuItem.save();

    // --- Cache Invalidation (simplified, review if specific ingredient caches need invalidation) ---
    if (redisService.isConnected()) {
      const categoryCacheKey = `menu:category:${menuItem.category}`;
      await deleteCache(categoryCacheKey);
      logger.info(`Invalidated cache for key: ${categoryCacheKey} (item created)`);
      
      const adminCategoryCacheKey = `menu:admin:category:${menuItem.category}`;
      await deleteCache(adminCategoryCacheKey);
      logger.info(`Invalidated cache for admin category key: ${adminCategoryCacheKey} (item created)`);

      await deleteCache(ALL_MENU_ITEMS_CACHE);
      logger.info(`Invalidated cache for key: ${ALL_MENU_ITEMS_CACHE} (item created)`);
      
      if (menuItem.isPopular) {
        await deleteCache(POPULAR_MENU_ITEMS_CACHE);
        logger.info(`Invalidated cache for key: ${POPULAR_MENU_ITEMS_CACHE} (popular item created)`);
      }
      
      // Invalidate relevant dietary/health caches
      Object.keys(processedDietaryInfo).forEach(async key => {
        if (processedDietaryInfo[key] === true) {
          await deleteCache(`${DIETARY_MENU_ITEMS_CACHE_PREFIX}${key}`);
          logger.info(`Invalidated cache for key: ${DIETARY_MENU_ITEMS_CACHE_PREFIX}${key} (item created)`);
        }
      });
      Object.keys(processedHealthInfo).forEach(async key => {
        if (processedHealthInfo[key] === true) {
          await deleteCache(`${HEALTH_MENU_ITEMS_CACHE_PREFIX}${key}`);
          logger.info(`Invalidated cache for key: ${HEALTH_MENU_ITEMS_CACHE_PREFIX}${key} (item created)`);
        }
      });
    }
    // --- End Cache Invalidation ---

    // Return the created item, including populated fields for consistency if possible, or at least IDs
    // For create, returning a simpler representation is common.
    // If the frontend needs full details immediately, consider populating after save and before responding.
    res.status(201).json({
      message: "Menu item created successfully",
      menuItem: {
        id: menuItem._id.toString(),
        name: menuItem.name,
        price: menuItem.price,
        image: menuItem.image,
        category: menuItem.category,
        isAvailable: menuItem.isAvailable,
        isPopular: menuItem.isPopular,
        dietaryInfo: menuItem.dietaryInfo, // Will be the object form
        healthInfo: menuItem.healthInfo,   // Will be the object form
        ingredients: menuItem.ingredients.map(ing => ({ // Map to a more frontend-friendly version if needed, or ensure client can handle this structure
            ingredient: ing.ingredient.toString(), // ObjectId of master ingredient
            quantity: ing.quantity,
            unit: ing.unit,
            _id: ing._id.toString() // ID of this specific ingredient entry in the array
        })),
        preparationTime: menuItem.preparationTime
      },
    });
  } catch (error) {
    logger.error(`Error in createMenuItem: ${error.message}`, error);
    // If an image was uploaded and an error occurred later, try to clean up the temp file
    if (req.file && req.file.path) {
        fs.unlink(req.file.path, (unlinkErr) => {
            if (unlinkErr) logger.error('Failed to delete temporary file during error handling:', unlinkErr);
        });
    }
    next(error);
  }
};

// Update menu item
export const updateMenuItem = async (req, res, next) => {
  try {
    const { itemId } = req.params;
    const updateData = req.body; // Get all potential update fields
    let { image, ingredients, dietaryInfo, healthInfo } = req.body; // Destructure specific fields

    const menuItem = await MenuItem.findById(itemId);

    if (!menuItem) {
      return res.status(404).json({ message: "Menu item not found" });
    }

    const oldImageUrl = menuItem.image;
    const oldCategory = menuItem.category; 
    let newImageUrl = oldImageUrl; 

    // Handle image update (existing logic)
    if (image !== undefined) {
      if (image === null) {
          newImageUrl = null;
          if (oldImageUrl && oldImageUrl.includes("cloudinary.com")) {
              try { await deleteImage(oldImageUrl); logger.info(`Deleted old menu item image via service (set to null): ${oldImageUrl}`); } 
              catch (deleteError) { logger.error(`Service error deleting old menu item image: ${deleteError.message}`); }
          }
      } else if (typeof image === 'string') { 
           try {
               const uploadResult = await uploadImage(image, "hungerz_kiosk/menu_items");
               newImageUrl = uploadResult.secure_url;
               if (oldImageUrl && oldImageUrl.includes("cloudinary.com") && oldImageUrl !== newImageUrl) {
                   try { await deleteImage(oldImageUrl); logger.info(`Deleted old menu item image via service: ${oldImageUrl}`); } 
                   catch (deleteError) { logger.error(`Service error deleting old menu item image: ${deleteError.message}`);}
               }
           } catch (uploadError) {
               logger.error("Cloudinary service upload error during update:", uploadError);
               return next(uploadError);
           }
      }
      if (newImageUrl !== oldImageUrl) {
          menuItem.image = newImageUrl;
      }
    }
    // Remove fields handled separately from updateData to avoid double processing or incorrect direct assignment
    delete updateData.image;
    delete updateData.ingredients;
    delete updateData.dietaryInfo;
    delete updateData.healthInfo;

    // Store old values for cache invalidation
    const oldDietaryInfoForCache = { ...menuItem.dietaryInfo };
    const oldHealthInfoForCache = { ...menuItem.healthInfo };
    const oldIsPopular = menuItem.isPopular;

    // Update other fields dynamically from updateData (name, price, description, category, isAvailable, isPopular, preparationTime)
    Object.keys(updateData).forEach(key => {
        if (updateData[key] !== undefined && key !== '_id') { // Ensure not overwriting _id
             menuItem[key] = updateData[key];
        }
    });

    // Handle dietaryInfo update (convert array from frontend to object for backend schema)
    if (dietaryInfo && Array.isArray(dietaryInfo)) {
      const newDietaryInfo = {};
      // Assuming menuItem.dietaryInfo is an object like { vegetarian: false, vegan: false, ... }
      // Reset all to false first based on existing keys in schema or a predefined list
      const allDietaryKeys = ['vegetarian', 'vegan', 'glutenFree', 'lactoseFree']; // Or Object.keys(menuItem.toObject().dietaryInfo || {})
      allDietaryKeys.forEach(key => newDietaryInfo[key] = false);
      dietaryInfo.forEach(tag => {
        if (allDietaryKeys.includes(tag)) { // Check if tag is a valid key
          newDietaryInfo[tag] = true;
        }
      });
      menuItem.dietaryInfo = newDietaryInfo;
    }

    // Handle healthInfo update (convert array from frontend to object for backend schema)
    if (healthInfo && Array.isArray(healthInfo)) {
      const newHealthInfo = {};
      const allHealthKeys = ['low_carb', 'low_fat', 'low_sugar', 'low_sodium']; // Or Object.keys(menuItem.toObject().healthInfo || {})
      allHealthKeys.forEach(key => newHealthInfo[key] = false);
      healthInfo.forEach(tag => {
        if (allHealthKeys.includes(tag)) { // Check if tag is a valid key
          newHealthInfo[tag] = true;
        }
      });
      menuItem.healthInfo = newHealthInfo;
    }
    
    // Handle ingredients update
    if (ingredients && Array.isArray(ingredients)) {
      const newIngredientsList = [];
      for (const ingData of ingredients) {
        let foundIngredientRef;
        if (ingData.id && mongoose.Types.ObjectId.isValid(ingData.id)) {
          foundIngredientRef = await Ingredient.findById(ingData.id);
        }
        if (!foundIngredientRef && ingData.name) { // Fallback to name if ID is not valid/provided or not found
          foundIngredientRef = await Ingredient.findOne({ name: ingData.name });
        }

        if (foundIngredientRef) {
          if (ingData.quantity !== undefined && ingData.unit !== undefined) {
            newIngredientsList.push({
              ingredient: foundIngredientRef._id,
              quantity: parseFloat(ingData.quantity),
              unit: ingData.unit,
            });
          } else {
            logger.warn(`Skipping ingredient '${ingData.name || ingData.id}' due to missing quantity or unit in update payload.`);
          }
        } else {
          logger.warn(`Ingredient with id '${ingData.id}' or name '${ingData.name}' not found in master list. Skipping.`);
          // Optionally, here you could create a new Ingredient in the master list if business logic allows
          // For now, we skip if not found to avoid creating incomplete master ingredients.
        }
      }
      menuItem.ingredients = newIngredientsList;
    }

    const updatedMenuItem = await menuItem.save();
    const newCategory = updatedMenuItem.category;

    // Populate ingredients for the response to match frontend expectations
    const populatedItemForResponse = await MenuItem.findById(updatedMenuItem._id)
      .populate({
        path: 'ingredients.ingredient',
        model: 'Ingredient',
        select: 'name' // Select name, id is included by default
      });

    const formattedIngredientsForResponse = populatedItemForResponse.ingredients.map(item => ({
      id: item.ingredient._id.toString(), // Master Ingredient ID
      name: item.ingredient.name,       // Master Ingredient name
      quantity: item.quantity,          // Quantity for this menu item
      unit: item.unit,                  // Unit for this menu item
      _id: item._id.toString()          // Sub-document ID, useful if frontend needs to differentiate entries
    }));

    // --- Cache Invalidation ---
    if (redisService.isConnected()) {
      // Invalidate old category cache if category changed
      if (oldCategory !== newCategory) {
          const oldCacheKey = `menu:category:${oldCategory}`;
          await deleteCache(oldCacheKey);
          logger.info(`Invalidated cache for key: ${oldCacheKey} (category changed)`);
      }
      
      const newCacheKey = `menu:category:${newCategory}`; // New/current category
      await deleteCache(newCacheKey);
      logger.info(`Invalidated cache for key: ${newCacheKey} (item updated)`);

      const itemCacheKey = `${MENU_ITEM_DETAILS_CACHE_PREFIX}${updatedMenuItem._id}`;
      await deleteCache(itemCacheKey);
      logger.info(`Invalidated cache for key: ${itemCacheKey} (item updated)`);
      
      const itemIngredientsCacheKey = `${MENU_ITEM_INGREDIENTS_CACHE_PREFIX}${updatedMenuItem._id}`;
      await deleteCache(itemIngredientsCacheKey); // Invalidate ingredients cache for this item
      logger.info(`Invalidated cache for key: ${itemIngredientsCacheKey} (item ingredients updated)`);
      
      await deleteCache(ALL_MENU_ITEMS_CACHE);
      logger.info(`Invalidated cache for key: ${ALL_MENU_ITEMS_CACHE} (item updated)`);
      
      if (oldIsPopular !== updatedMenuItem.isPopular || updateData.isAvailable !== undefined || menuItem.isAvailable !== updatedMenuItem.isAvailable ) {
        await deleteCache(POPULAR_MENU_ITEMS_CACHE);
        logger.info(`Invalidated cache for key: ${POPULAR_MENU_ITEMS_CACHE} (item popularity/availability changed)`);
      }
      
      // Optimized cache invalidation for dietaryInfo
      const currentDietaryInfo = updatedMenuItem.dietaryInfo.toObject ? updatedMenuItem.dietaryInfo.toObject() : updatedMenuItem.dietaryInfo;
      const dietaryKeysToInvalidate = new Set();
      Object.entries(oldDietaryInfoForCache).forEach(([key, value]) => { if(value) dietaryKeysToInvalidate.add(key); });
      Object.entries(currentDietaryInfo).forEach(([key, value]) => { if(value) dietaryKeysToInvalidate.add(key); });
      dietaryKeysToInvalidate.forEach(async key => {
          await deleteCache(`${DIETARY_MENU_ITEMS_CACHE_PREFIX}${key}`);
          logger.info(`Invalidated cache for key: ${DIETARY_MENU_ITEMS_CACHE_PREFIX}${key} (dietary info changed)`);
      });
      
      // Optimized cache invalidation for healthInfo
      const currentHealthInfo = updatedMenuItem.healthInfo.toObject ? updatedMenuItem.healthInfo.toObject() : updatedMenuItem.healthInfo;
      const healthKeysToInvalidate = new Set();
      Object.entries(oldHealthInfoForCache).forEach(([key, value]) => { if(value) healthKeysToInvalidate.add(key); });
      Object.entries(currentHealthInfo).forEach(([key, value]) => { if(value) healthKeysToInvalidate.add(key); });
      healthKeysToInvalidate.forEach(async key => {
          await deleteCache(`${HEALTH_MENU_ITEMS_CACHE_PREFIX}${key}`);
          logger.info(`Invalidated cache for key: ${HEALTH_MENU_ITEMS_CACHE_PREFIX}${key} (health info changed)`);
      });
    }
    // --- End Cache Invalidation ---

    res.status(200).json({
      message: "Menu item updated successfully",
      menuItem: { 
        id: updatedMenuItem._id.toString(), // Ensure ID is string
        name: updatedMenuItem.name,
        price: updatedMenuItem.price,
        image: updatedMenuItem.image,
        category: updatedMenuItem.category,
        isAvailable: updatedMenuItem.isAvailable,
        dietaryInfo: updatedMenuItem.dietaryInfo,
        healthInfo: updatedMenuItem.healthInfo,
        ingredients: formattedIngredientsForResponse // Use the formatted ingredients
      },
    });
  } catch (error) {
    logger.error(`Error in updateMenuItem: ${error.message}`, error);
    next(error);
  }
};

// Delete menu item
export const deleteMenuItem = async (req, res, next) => {
  try {
    const { itemId } = req.params;

    const menuItem = await MenuItem.findById(itemId);

    if (!menuItem) {
      return res.status(404).json({ message: "Menu item not found" });
    }
    const categoryToDeleteFrom = menuItem.category; // Get category before deleting

    // Attempt to delete image from Cloudinary using the service
    if (menuItem.image && menuItem.image.includes("cloudinary.com")) {
      try {
        // Call service's deleteImage with the full URL
        const result = await deleteImage(menuItem.image);
        logger.info(`Attempted deletion via service for image: ${menuItem.image} - Result: ${result.result}`);
      } catch (deleteError) {
        logger.error(`Service error deleting menu item image: ${deleteError.message}`);
        // Log error, but continue with item deletion
      }
    }

    // Store dietary and health info for cache invalidation before deleting
    const dietaryInfo = { ...menuItem.dietaryInfo };
    const healthInfo = { ...menuItem.healthInfo };
    const isPopular = menuItem.isPopular;

    // Delete the menu item from the database
    await MenuItem.findByIdAndDelete(itemId);

    // --- Cache Invalidation ---
    if (redisService.isConnected()) {
      // Invalidate category cache
      const cacheKey = `menu:category:${categoryToDeleteFrom}`;
      await deleteCache(cacheKey);
      logger.info(`Invalidated cache for key: ${cacheKey} (item deleted)`);
      
      // Invalidate item details cache
      const itemCacheKey = `${MENU_ITEM_DETAILS_CACHE_PREFIX}${itemId}`;
      await deleteCache(itemCacheKey);
      logger.info(`Invalidated cache for key: ${itemCacheKey} (item deleted)`);
      
      // Invalidate all items cache
      await deleteCache(ALL_MENU_ITEMS_CACHE);
      logger.info(`Invalidated cache for key: ${ALL_MENU_ITEMS_CACHE} (item deleted)`);
      
      // Invalidate popular items cache if item was popular
      if (isPopular) {
        await deleteCache(POPULAR_MENU_ITEMS_CACHE);
        logger.info(`Invalidated cache for key: ${POPULAR_MENU_ITEMS_CACHE} (popular item deleted)`);
      }
      
      // Invalidate dietary caches for preferences that were true
      for (const [key, value] of Object.entries(dietaryInfo)) {
        if (value === true) {
          await deleteCache(`${DIETARY_MENU_ITEMS_CACHE_PREFIX}${key}`);
          logger.info(`Invalidated cache for key: ${DIETARY_MENU_ITEMS_CACHE_PREFIX}${key} (item with dietary info deleted)`);
        }
      }
      
      // Invalidate health caches for preferences that were true
      for (const [key, value] of Object.entries(healthInfo)) {
        if (value === true) {
          await deleteCache(`${HEALTH_MENU_ITEMS_CACHE_PREFIX}${key}`);
          logger.info(`Invalidated cache for key: ${HEALTH_MENU_ITEMS_CACHE_PREFIX}${key} (item with health info deleted)`);
        }
      }
    }
    // --- End Cache Invalidation ---

    res.status(200).json({
      message: "Menu item deleted successfully",
    });
  } catch (error) {
    next(error);
  }
};

// Get popular menu items
export const getPopularMenuItems = async (req, res, next) => {
  try {
    // Try to get from cache first
    if (redisService.isConnected()) {
      const cachedMenuItems = await getCache(POPULAR_MENU_ITEMS_CACHE);
      if (cachedMenuItems) {
        logger.info(`Cache hit for key: ${POPULAR_MENU_ITEMS_CACHE}`);
        return res.status(200).json({ menuItems: cachedMenuItems });
      }
      logger.info(`Cache miss for key: ${POPULAR_MENU_ITEMS_CACHE}`);
    } else {
      logger.warn(`Redis not connected, skipping cache check for key: ${POPULAR_MENU_ITEMS_CACHE}`);
    }

    // No population needed
    const popularItems = await MenuItem.find({ isPopular: true, isAvailable: true })
      .limit(10);

    // Format response (category is a string)
    const formattedMenuItems = popularItems.map((item) => ({
      id: item._id,
      name: item.name,
      description: item.description,
      price: item.price,
      image: item.image,
      category: item.category, // Direct string access
      dietaryInfo: item.dietaryInfo,
      healthInfo: item.healthInfo,
      isPopular: item.isPopular,
      preparationTime: item.preparationTime,
      addons: item.addons,
    }));

    // Store in cache if Redis is connected
    if (redisService.isConnected()) {
      await setCache(POPULAR_MENU_ITEMS_CACHE, formattedMenuItems, CACHE_EXPIRATION);
      logger.info(`Cached data for key: ${POPULAR_MENU_ITEMS_CACHE}`);
    }

    res.status(200).json({ menuItems: formattedMenuItems });
  } catch (error) {
    next(error);
  }
};

// Search menu items
export const searchMenuItems = async (req, res, next) => {
  try {
    const { query } = req.query;

    if (!query) {
      return res.status(400).json({ message: "Search query is required" });
    }

    const cacheKey = `${SEARCH_MENU_ITEMS_CACHE_PREFIX}${query}`;

    // Try to get from cache first
    if (redisService.isConnected()) {
      const cachedMenuItems = await getCache(cacheKey);
      if (cachedMenuItems) {
        logger.info(`Cache hit for key: ${cacheKey}`);
        return res.status(200).json({ menuItems: cachedMenuItems });
      }
      logger.info(`Cache miss for key: ${cacheKey}`);
    } else {
      logger.warn(`Redis not connected, skipping cache check for key: ${cacheKey}`);
    }

    // No population needed
    const menuItems = await MenuItem.find({
      $or: [
        { name: { $regex: query, $options: "i" } },
        { description: { $regex: query, $options: "i" } },
        { category: { $regex: query, $options: "i" } } // Search category string
      ],
      isAvailable: true,
    });

    // Format response (category is a string)
    const formattedMenuItems = menuItems.map((item) => ({
      id: item._id,
      name: item.name,
      description: item.description,
      price: item.price,
      image: item.image,
      category: item.category, // Direct string access
      dietaryInfo: item.dietaryInfo,
      healthInfo: item.healthInfo,
      isPopular: item.isPopular,
      preparationTime: item.preparationTime,
      addons: item.addons,
    }));

    // Store in cache if Redis is connected (shorter expiration for search results)
    if (redisService.isConnected()) {
      await setCache(cacheKey, formattedMenuItems, 600); // 10 minutes
      logger.info(`Cached data for key: ${cacheKey}`);
    }

    res.status(200).json({ menuItems: formattedMenuItems });
  } catch (error) {
    next(error);
  }
};

// Get menu items by dietary preferences
export const getMenuItemsByDietary = async (req, res, next) => {
  try {
    const { preference } = req.params;
    const validPreferences = ["vegetarian", "vegan", "glutenFree", "lactoseFree"];

    if (!validPreferences.includes(preference)) {
      return res.status(400).json({ message: "Invalid dietary preference" });
    }

    const cacheKey = `${DIETARY_MENU_ITEMS_CACHE_PREFIX}${preference}`;

    // Try to get from cache first
    if (redisService.isConnected()) {
      const cachedMenuItems = await getCache(cacheKey);
      if (cachedMenuItems) {
        logger.info(`Cache hit for key: ${cacheKey}`);
        return res.status(200).json({ menuItems: cachedMenuItems });
      }
      logger.info(`Cache miss for key: ${cacheKey}`);
    } else {
      logger.warn(`Redis not connected, skipping cache check for key: ${cacheKey}`);
    }

    const query = { isAvailable: true };
    query[`dietaryInfo.${preference}`] = true;

    const menuItems = await MenuItem.find(query);

    const formattedMenuItems = menuItems.map((item) => ({
      id: item._id,
      name: item.name,
      description: item.description,
      price: item.price,
      image: item.image,
      category: item.category,
      dietaryInfo: item.dietaryInfo,
      healthInfo: item.healthInfo,
      isPopular: item.isPopular,
      preparationTime: item.preparationTime,
      addons: item.addons,
    }));

    // Store in cache if Redis is connected
    if (redisService.isConnected()) {
      await setCache(cacheKey, formattedMenuItems, CACHE_EXPIRATION);
      logger.info(`Cached data for key: ${cacheKey}`);
    }

    res.status(200).json({ menuItems: formattedMenuItems });
  } catch (error) {
    next(error);
  }
};

// Get menu items by health preferences
export const getMenuItemsByHealth = async (req, res, next) => {
  try {
    const { preference } = req.params;
    const validPreferences = ["low_carb", "low_fat", "low_sugar", "low_sodium"];

    if (!validPreferences.includes(preference)) {
      return res.status(400).json({ message: "Invalid health preference" });
    }

    const cacheKey = `${HEALTH_MENU_ITEMS_CACHE_PREFIX}${preference}`;

    // Try to get from cache first
    if (redisService.isConnected()) {
      const cachedMenuItems = await getCache(cacheKey);
      if (cachedMenuItems) {
        logger.info(`Cache hit for key: ${cacheKey}`);
        return res.status(200).json({ menuItems: cachedMenuItems });
      }
      logger.info(`Cache miss for key: ${cacheKey}`);
    } else {
      logger.warn(`Redis not connected, skipping cache check for key: ${cacheKey}`);
    }

    const query = { isAvailable: true };
    query[`healthInfo.${preference}`] = true;

    // No population needed
    const menuItems = await MenuItem.find(query);

    // Format response (category is a string)
    const formattedMenuItems = menuItems.map((item) => ({
      id: item._id,
      name: item.name,
      description: item.description,
      price: item.price,
      image: item.image,
      category: item.category, // Direct string access
      dietaryInfo: item.dietaryInfo,
      healthInfo: item.healthInfo,
      isPopular: item.isPopular,
      preparationTime: item.preparationTime,
      addons: item.addons,
    }));

    // Store in cache if Redis is connected
    if (redisService.isConnected()) {
      await setCache(cacheKey, formattedMenuItems, CACHE_EXPIRATION);
      logger.info(`Cached data for key: ${cacheKey}`);
    }

    res.status(200).json({ menuItems: formattedMenuItems });
  } catch (error) {
    next(error);
  }
};


export const getMenuItemIngredients = async (req, res, next) => {
  try {
    const { itemId } = req.params;
    
    if (!itemId) {
      return res.status(400).json({ message: "Menu item ID is required" });
    }
    
    const cacheKey = `${MENU_ITEM_INGREDIENTS_CACHE_PREFIX}${itemId}`;
    
    // Try to get from cache first
    if (redisService.isConnected()) {
      const cachedIngredients = await getCache(cacheKey);
      if (cachedIngredients) {
        logger.info(`Cache hit for key: ${cacheKey}`);
        return res.status(200).json({ ingredients: cachedIngredients });
      }
      logger.info(`Cache miss for key: ${cacheKey}`);
    } else {
      logger.warn(`Redis not connected, skipping cache check for key: ${cacheKey}`);
    }
    
    // Find the menu item first
    const menuItem = await MenuItem.findById(itemId);
    
    if (!menuItem) {
      return res.status(404).json({ message: "Menu item not found" });
    }
    
    // Assuming MenuItem has a field 'ingredients' that is an array of objects
    // with ingredient reference, quantity, and possibly other fields
    // We need to populate the ingredient references to get their details
    const populatedMenuItem = await MenuItem.findById(itemId).populate({
      path: 'ingredients.ingredient',
      model: 'Ingredient',
      select: 'name unit category'
    });
    
    if (!populatedMenuItem || !populatedMenuItem.ingredients) {
      return res.status(200).json({ ingredients: [] });
    }
    
    // Format the response to include only name, quantity, and unit
    const formattedIngredients = populatedMenuItem.ingredients.map(item => ({
      id: item.ingredient._id,
      name: item.ingredient.name,
      quantity: item.quantity,
      unit: item.unit,
      category: item.ingredient.category
    }));
    
    // Store in cache if Redis is connected
    if (redisService.isConnected()) {
      await setCache(cacheKey, formattedIngredients, CACHE_EXPIRATION);
      logger.info(`Cached data for key: ${cacheKey}`);
    }
    
    res.status(200).json({ 
      menuItemId: itemId,
      menuItemName: menuItem.name,
      ingredients: formattedIngredients 
    });
  } catch (error) {
    logger.error(`Error in getMenuItemIngredients: ${error.message}`, error);
    next(error);
  }
};

// Get all master ingredients
export const getAllMasterIngredients = async (req, res, next) => {
  try {
    // Try to get from cache first
    if (redisService.isConnected()) {
      const cachedIngredients = await getCache(ALL_MASTER_INGREDIENTS_CACHE);
      if (cachedIngredients) {
        logger.info(`Cache hit for key: ${ALL_MASTER_INGREDIENTS_CACHE}`);
        return res.status(200).json({ ingredients: cachedIngredients });
      }
      logger.info(`Cache miss for key: ${ALL_MASTER_INGREDIENTS_CACHE}`);
    } else {
      logger.warn(`Redis not connected, skipping cache check for key: ${ALL_MASTER_INGREDIENTS_CACHE}`);
    }

    const ingredients = await Ingredient.find({});

    if (!ingredients) {
      // Should return empty array if no ingredients, not an error,
      // but find will return empty array if none found.
      return res.status(200).json({ ingredients: [] });
    }

    const formattedIngredients = ingredients.map((ing) => ({
      id: ing._id.toString(),
      name: ing.name,
      unit: ing.unit, // Assuming 'unit' is a direct property
      category: ing.category // Assuming 'category' is a direct property
    }));

    // Store in cache if Redis is connected
    if (redisService.isConnected()) {
      await setCache(ALL_MASTER_INGREDIENTS_CACHE, formattedIngredients, CACHE_EXPIRATION);
      logger.info(`Cached data for key: ${ALL_MASTER_INGREDIENTS_CACHE}`);
    }

    res.status(200).json({ ingredients: formattedIngredients });
  } catch (error) {
    logger.error(`Error in getAllMasterIngredients: ${error.message}`, error);
    next(error);
  }
};


export const getAllStockInfo = async (req, res, next) => {
  try {
    // Try to get from cache first
    // if (redisService.isConnected()) {
    //   const cachedStockInfo = await getCache(ALL_STOCK_INFO_CACHE);
    //   if (cachedStockInfo) {
    //     logger.info(`Cache hit for key: ${ALL_STOCK_INFO_CACHE}`);
    //     return res.status(200).json(cachedStockInfo);
    //   }
    //   logger.info(`Cache miss for key: ${ALL_STOCK_INFO_CACHE}`);
    // } else {
    //   logger.warn(`Redis not connected, skipping cache check for key: ${ALL_STOCK_INFO_CACHE}`);
    // }

    // Get all ingredients
    const ingredients = await Ingredient.find({}).sort({ category: 1, name: 1 });

    // Group ingredients by category
    const categorizedIngredients = {};
    const lowStockIngredients = [];
    let totalIngredients = 0;
    let lowStockCount = 0;

    ingredients.forEach(ingredient => {
      totalIngredients++;
      
      // Format the ingredient data
      const formattedIngredient = {
        id: ingredient._id,
        name: ingredient.name,
        stock: ingredient.stock,
        unit: ingredient.unit,
        lowStockThreshold: ingredient.lowStockThreshold,
        isLowStock: ingredient.lowStockThreshold > 0 && ingredient.stock <= ingredient.lowStockThreshold,
        category: ingredient.category,
        createdAt: ingredient.createdAt,
        updatedAt: ingredient.updatedAt
      };

      // Add to categorized list
      if (!categorizedIngredients[ingredient.category]) {
        categorizedIngredients[ingredient.category] = [];
      }
      categorizedIngredients[ingredient.category].push(formattedIngredient);

      // Check if low stock and add to low stock list
      if (formattedIngredient.isLowStock) {
        lowStockIngredients.push(formattedIngredient);
        lowStockCount++;
      }
    });

    // Prepare response
    const stockInfo = {
      totalIngredients,
      lowStockCount,
      lowStockIngredients,
      categorizedIngredients
    };

    // // Store in cache if Redis is connected
    // if (redisService.isConnected()) {
    //   await setCache(ALL_STOCK_INFO_CACHE, stockInfo, ALL_STOCK_INFO_CACHE_EXPIRATION);
    //   logger.info(`Cached data for key: ${ALL_STOCK_INFO_CACHE}`);
    // }

    res.status(200).json(stockInfo);
  } catch (error) {
    logger.error(`Error in getAllStockInfo: ${error.message}`, error);
    next(error);
  }
};