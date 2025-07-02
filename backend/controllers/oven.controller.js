// oven.controller.js (exemple)
import Oven from '../models/oven.model.js'; // Ajustez le chemin
import logger from '../middlewares/logger.middleware.js';

export const getOvenState = async (req, res, next) => {
  try {
    const { deviceId } = req.params;
    const oven = await Oven.findOne({ deviceId: deviceId });

    if (!oven) {
      return res.status(404).json({ message: `Four avec deviceId ${deviceId} non trouvé.` });
    }
    res.status(200).json({
      deviceId: oven.deviceId,
      friendlyName: oven.friendlyName,
      isOn: oven.status !== 'off',
      operationalStatus: oven.status, // ou map vers votre enum OvenOperationalStatus en string
      currentTemperature: oven.currentTemperature,
      targetTemperature: oven.targetTemperature,
      selectedMode: oven.mode, // ou map vers votre enum OvenMode en string
      isLightOn: oven.isLightOn,
      isDoorOpen: oven.isDoorOpen,
      targetDurationSeconds: oven.targetDurationSeconds,
      remainingTimeSeconds: oven.remainingTimeSeconds,
      // ...autres champs de votre schéma Oven si besoin
    });
  } catch (error) {
    logger.error(`Erreur dans getOvenState pour ${req.params.deviceId}: ${error.message}`, error);
    next(error);
  }
};