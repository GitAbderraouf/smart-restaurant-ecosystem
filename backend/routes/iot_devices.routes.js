
import express from 'express';
import { getRefrigeratorState } from '../controllers/refrigerator.controller.js';
import { getOvenState } from '../controllers/oven.controller.js';
const router = express.Router();
router.get('/refrigerators/:deviceId', getRefrigeratorState);
router.get('/ovens/:deviceId', getOvenState);
export default router;