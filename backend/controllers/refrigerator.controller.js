// refrigerator.controller.js (exemple)
import Refrigerator from '../models/refrigerator.model.js'; // Ajustez le chemin
import logger from '../middlewares/logger.middleware.js';

export const getRefrigeratorState = async (req, res, next) => {
  try {
    const { deviceId } = req.params;
    const fridge = await Refrigerator.findOne({ deviceId: deviceId });

    if (!fridge) {
      return res.status(404).json({ message: `Réfrigérateur avec deviceId ${deviceId} non trouvé.` });
    }
    // Renvoyer les champs pertinents pour l'état initial du simulateur
    res.status(200).json({
      deviceId: fridge.deviceId,
      friendlyName: fridge.friendlyName,
      isOn: fridge.status !== 'off', // Déduire isOn de status
      currentStatusText: fridge.status, // Ou un getter dans le modèle Mongoose
      currentTemperature: fridge.currentTemperature,
      targetTemperature: fridge.targetTemperature,
      isDoorOpen: fridge.status === 'door_open', // Exemple
      // ...autres champs de votre schéma Refrigerator si besoin
    });
  } catch (error) {
    logger.error(`Erreur dans getRefrigeratorState pour ${req.params.deviceId}: ${error.message}`, error);
    next(error);
  }
};