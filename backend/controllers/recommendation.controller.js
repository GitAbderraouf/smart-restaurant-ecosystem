// controllers/recommendationController.js
import { User } from '../models/user.model.js';
import  MenuItem  from '../models/menuItem.model.js';
import { Rating } from '../models/rating.model.js'; // Notre nouveau modèle
import mongoose from 'mongoose';
//npm import * as tf from '@tensorflow/tfjs-node';// TensorFlow.js pour Node.js

function dotProduct(vecA, vecB) {
  if (!vecA || !vecB || vecA.length !== vecB.length) {
    // console.warn("Tentative de produit scalaire avec des vecteurs incompatibles ou non définis:", vecA, vecB);
    return 0; // Retourne 0 si les vecteurs sont invalides pour éviter les erreurs
  }
  let product = 0;
  for (let i = 0; i < vecA.length; i++) {
    product += vecA[i] * vecB[i];
  }
  return product;
}

// Fonction utilitaire pour initialiser un vecteur avec des petites valeurs aléatoires
function randomVector(size, scale = 0.01) {
  return Array(size).fill(0).map(() => (Math.random() - 0.5) * scale);
}

export const trainAndGenerateRecommendationsJS = async (req, res) => {
  console.log("🚀 Début de l'entraînement du modèle de recommandation (JavaScript SGD)...");
  const startTime = Date.now();

  try {
    // 1. Récupérer les données
    console.log("📚 [1/7] Récupération des données...");
    const allRatings = await Rating.find({})
      .populate('user', '_id')
      .populate('menuItem', '_id')
      .lean();

    const allDbUsersForRecGeneration = await User.find({}).select('_id favorites').lean();
    const existingUserIds = new Set(allDbUsersForRecGeneration.map(u => u._id.toString()));
    
    const allDbMenuItems = await MenuItem.find({}).select('_id').lean();
    const existingMenuItemIds = new Set(allDbMenuItems.map(item => item._id.toString()));

    console.log(`📊 ${allRatings.length} notes trouvées, ${existingUserIds.size} utilisateurs existants, ${existingMenuItemIds.size} articles existants.`);

    if (allRatings.length < 10) {
      const message = "Pas assez de notes pour un entraînement significatif.";
      console.warn(`⚠️ ${message}`);
      if (res) return res.status(200).json({ message });
      return;
    }

    // 2. Préparer les données pour l'entraînement
    console.log("🛠️ [2/7] Préparation des données pour l'entraînement...");
    const userToIntegerIndex = new Map();
    const itemToIntegerIndex = new Map();
    const integerIndexToUserId = []; 
    const integerIndexToItemId = []; 

    let nextUserIntegerIndex = 0;
    let nextItemIntegerIndex = 0;

    const userRatingsSum = new Map();
    allRatings.forEach(r => {
      if (r.user && r.user._id) {
        const userIdStr = r.user._id.toString();
        if (!userRatingsSum.has(userIdStr)) {
          userRatingsSum.set(userIdStr, { sum: 0, count: 0 });
        }
        const userData = userRatingsSum.get(userIdStr);
        userData.sum += r.rating;
        userData.count += 1;
      }
    });

    const userMeanRatings = new Map();
    userRatingsSum.forEach((data, userIdStr) => {
      userMeanRatings.set(userIdStr, data.count > 0 ? data.sum / data.count : 3);
    });
    console.log(`📊 Moyennes des notes par utilisateur calculées pour ${userMeanRatings.size} utilisateurs (incluant potentiellement des utilisateurs supprimés).`);

    const trainingData = [];
    allRatings.forEach(r => {
      if (r.user && r.user._id && r.menuItem && r.menuItem._id) {
        const userIdStr = r.user._id.toString();
        const menuItemIdStr = r.menuItem._id.toString();
        const userMean = userMeanRatings.get(userIdStr) || 3;

        let currentUserIntIndex = userToIntegerIndex.get(userIdStr);
        if (currentUserIntIndex === undefined) {
          currentUserIntIndex = nextUserIntegerIndex++;
          userToIntegerIndex.set(userIdStr, currentUserIntIndex);
          integerIndexToUserId[currentUserIntIndex] = userIdStr;
        }

        let currentItemIntIndex = itemToIntegerIndex.get(menuItemIdStr);
        if (currentItemIntIndex === undefined) {
          currentItemIntIndex = nextItemIntegerIndex++;
          itemToIntegerIndex.set(menuItemIdStr, currentItemIntIndex);
          integerIndexToItemId[currentItemIntIndex] = menuItemIdStr;
        }
        
        trainingData.push({
            userIndex: currentUserIntIndex,
            itemIndex: currentItemIntIndex,
            normalizedRating: r.rating - userMean,
            originalUserId: userIdStr,
        });
      }
    });
    
    if (trainingData.length === 0) {
      const message = "Données de notation valides insuffisantes après mapping.";
      console.warn(`⚠️ ${message}`);
      if (res) return res.status(200).json({ message });
      return;
    }

    const numModelUsers = nextUserIntegerIndex;
    const numModelItems = nextItemIntegerIndex;
    console.log(`📊 Données prêtes pour l'entraînement : ${trainingData.length} échantillons, ${numModelUsers} utilisateurs uniques dans le modèle, ${numModelItems} articles uniques dans le modèle.`);

    console.log(`⚙️ [3/7] Initialisation des paramètres du modèle...`);
    const embeddingDim = 10;
    const learningRate = 0.05; 
    const lambda = 0.01;       
    const epochs = 50;         
    console.log(`Hyperparamètres: embeddingDim=${embeddingDim}, learningRate=${learningRate}, lambda=${lambda}, epochs=${epochs}`);

    let userEmbeddings = Array(numModelUsers).fill(null).map(() => randomVector(embeddingDim));
    let itemEmbeddings = Array(numModelItems).fill(null).map(() => randomVector(embeddingDim));
    let userBiases = Array(numModelUsers).fill(0).map(() => (Math.random() - 0.5) * 0.01);
    let itemBiases = Array(numModelItems).fill(0).map(() => (Math.random() - 0.5) * 0.01);

    console.log("⏳ [4/7] Début de l'entraînement SGD...");
    for (let epoch = 0; epoch < epochs; epoch++) {
      let currentEpochErrorSum = 0;
      trainingData.sort(() => Math.random() - 0.5);

      for (const sample of trainingData) {
        const u = sample.userIndex;
        const i = sample.itemIndex;
        const normalizedActualRating = sample.normalizedRating;

        if (u === undefined || i === undefined || !userEmbeddings[u] || !itemEmbeddings[i] || userBiases[u] === undefined || itemBiases[i] === undefined) {
            continue; 
        }

        const predictedNormalizedRating = dotProduct(userEmbeddings[u], itemEmbeddings[i]) + userBiases[u] + itemBiases[i];
        const error = normalizedActualRating - predictedNormalizedRating;
        currentEpochErrorSum += error * error;

        userBiases[u] += learningRate * (error - lambda * userBiases[u]);
        itemBiases[i] += learningRate * (error - lambda * itemBiases[i]);

        for (let d = 0; d < embeddingDim; d++) {
          const userFactorVal = userEmbeddings[u][d];
          const itemFactorVal = itemEmbeddings[i][d];
          userEmbeddings[u][d] += learningRate * (error * itemFactorVal - lambda * userFactorVal);
          itemEmbeddings[i][d] += learningRate * (error * userFactorVal - lambda * itemFactorVal);
        }
      }
      const mse = trainingData.length > 0 ? currentEpochErrorSum / trainingData.length : 0;
      console.log(`Epoch ${epoch + 1}/${epochs} - MSE: ${mse.toFixed(5)}`);
      if (mse < 0.005 && epoch > 10) { 
          console.log("💡 Convergence anticipée potentiellement atteinte.");
          break;
      }
    }
    console.log("✅ Entraînement SGD terminé.");

    console.log("💾 [5/7] Mise à jour des cfFeatures des articles...");
    let updatedItemCfFeaturesCount = 0;
    for (let i_idx = 0; i_idx < numModelItems; i_idx++) {
      const menuItemIdStrToUpdate = integerIndexToItemId[i_idx];
      if (existingMenuItemIds.has(menuItemIdStrToUpdate)) {
        await MenuItem.findByIdAndUpdate(menuItemIdStrToUpdate, {
          $set: { cfFeatures: itemEmbeddings[i_idx] }
        }).exec();
        updatedItemCfFeaturesCount++;
      }
    }
    console.log(`⚙️ cfFeatures mis à jour pour ${updatedItemCfFeaturesCount} articles existants.`);

    console.log("🎁 [6/7] Génération des recommandations ET Mise à jour des utilisateurs (méthode save())...");
    let usersProcessedAndSavedCount = 0; 

    for (const dbUserLean of allDbUsersForRecGeneration) {
      const userIdStr = dbUserLean._id.toString();
      
      const userDocument = await User.findById(userIdStr); 
      if (!userDocument) {
        console.warn(`⚠️ Utilisateur ${userIdStr} non trouvé en DB pour la mise à jour via .save(). Skip.`);
        continue;
      }

      let oldRecommendationsInDocStrings = [];
      if (userDocument.recommandations && Array.isArray(userDocument.recommandations)) {
        oldRecommendationsInDocStrings = userDocument.recommandations
          .map(id => id ? id.toString() : null) 
          .filter(id => id !== null); 
      } else {
        console.warn(`⚠️ Pour ${userIdStr}, userDocument.recommandations AVANT modif était undefined ou n'est pas un tableau. Initialisé comme tableau vide en mémoire. Valeur originale:`, userDocument.recommandations);
        userDocument.recommandations = []; 
      }
      console.log(`📄 Pour ${userIdStr}, AVANT modif en mémoire - Recommandations DB: [${oldRecommendationsInDocStrings.join(', ')}]`);

      const userIntIndex = userToIntegerIndex.get(userIdStr);
      
      // Mettre à jour cfParams sur le document
      if (userIntIndex !== undefined && userEmbeddings[userIntIndex] && userBiases[userIntIndex] !== undefined) {
        if (!userDocument.cfParams) userDocument.cfParams = {};
        userDocument.cfParams.w = userEmbeddings[userIntIndex];
        userDocument.cfParams.b = userBiases[userIntIndex];
        console.log(`⚙️ cfParams pour ${userIdStr} préparés pour la sauvegarde.`);
      } else {
        if (!userDocument.cfParams) userDocument.cfParams = {}; // S'assurer que cfParams existe pour lastTrained
        console.log(`⚙️ Utilisateur ${userIdStr} non trouvé dans les données d'entraînement pour cfParams, seul lastTrained sera mis à jour pour cfParams.`);
      }
      userDocument.cfParams.lastTrained = new Date();


      // Générer les recommandations
      const userMean = userMeanRatings.get(userIdStr) || 3;
      let topNRecommendationObjectIds = [];

      if (userIntIndex !== undefined && userEmbeddings[userIntIndex] && userBiases[userIntIndex] !== undefined) {
        const currentUserEmbedding = userEmbeddings[userIntIndex];
        const currentUserBias = userBiases[userIntIndex];
        const recommendationsWithScores = [];

        const itemsToStrictlyExclude = new Set();
        allRatings
          .filter(r => r.user && r.user._id.toString() === userIdStr && r.source === 'manual_order')
          .forEach(r => { if (r.menuItem) itemsToStrictlyExclude.add(r.menuItem._id.toString()); });
        if (dbUserLean.favorites) {
          dbUserLean.favorites.forEach(favId => itemsToStrictlyExclude.add(favId.toString()));
        }

        let candidateItemsCount = 0;
        for (const dbMenuItem of allDbMenuItems) {
          const menuItemIdStr = dbMenuItem._id.toString();
          if (itemsToStrictlyExclude.has(menuItemIdStr)) continue;

          const itemIntIndexForRec = itemToIntegerIndex.get(menuItemIdStr); // Renommé pour clarté
          if (itemIntIndexForRec === undefined || !itemEmbeddings[itemIntIndexForRec] || itemBiases[itemIntIndexForRec] === undefined) continue;
          
          candidateItemsCount++;
          const currentItemEmbedding = itemEmbeddings[itemIntIndexForRec];
          const currentItemBias = itemBiases[itemIntIndexForRec];
          const predictedNormalizedRating = dotProduct(currentUserEmbedding, currentItemEmbedding) + currentUserBias + currentItemBias;
          const predictedOriginalScaleRating = predictedNormalizedRating + userMean;

          if (!isFinite(predictedOriginalScaleRating)) { 
            console.warn(`⚠️ Score non fini pour item ${menuItemIdStr} et user ${userIdStr}: ${predictedOriginalScaleRating}.`);
            continue; 
          }
          recommendationsWithScores.push({ menuItemId: dbMenuItem._id, predictedRating: predictedOriginalScaleRating });
        }
        
        console.log(`👤 Pour ${userIdStr}: ${candidateItemsCount} articles candidats initiaux. ${recommendationsWithScores.length} candidats avec scores finis.`);
        recommendationsWithScores.sort((a, b) => b.predictedRating - a.predictedRating);
        
        if (recommendationsWithScores.length > 0) {
          console.log(`🏆 Top scores (jusqu'à 12) pour ${userIdStr}:`, recommendationsWithScores.slice(0, 12).map(r => ({id: r.menuItemId.toString(), score: r.predictedRating.toFixed(3) })));
        }
        topNRecommendationObjectIds = recommendationsWithScores.slice(0, 10).map(rec => rec.menuItemId);
      } else {
        console.log(`⏩ Pas de cfParams appris pour ${userIdStr}, les recommandations seront vides.`);
      }
      
      userDocument.recommandations = topNRecommendationObjectIds;
      console.log(`📝 Pour ${userIdStr}, user.recommandations en mémoire PRÊT pour .save(): [${userDocument.recommandations.map(id => id ? id.toString() : 'null').join(', ')}]`);

      try {
        const savedUser = await userDocument.save();
        
        console.log(`🔬 Juste après .save() pour ${userIdStr}:`);
        console.log(`   Type de savedUser: ${typeof savedUser}`);
        if (savedUser) {
          console.log(`   Type de savedUser.recommandations: ${typeof savedUser.recommandations}`);
          console.log(`   savedUser.recommandations est un tableau ?: ${Array.isArray(savedUser.recommandations)}`);
          if (savedUser.recommandations && Array.isArray(savedUser.recommandations)) {
            console.log(`   Longueur de savedUser.recommandations: ${savedUser.recommandations.length}`);
            console.log(`   Contenu de savedUser.recommandations (JSON.stringify): ${JSON.stringify(savedUser.recommandations)}`);
          } else {
            console.warn(`   ⚠️ savedUser.recommandations N'EST PAS un tableau ou est undefined/null APRÈS save.`);
          }
          console.log(`   Valeur de savedUser.updatedAt: ${savedUser.updatedAt}`);
        } else {
            console.error(`   ❌ savedUser est null ou undefined APRÈS save pour ${userIdStr}!`);
        }

        // Vérification pour le comptage
        if (savedUser && savedUser.recommandations) { // Vérifie que savedUser et savedUser.recommandations existent
            usersProcessedAndSavedCount++;
        } else if (savedUser && !savedUser.recommandations) { // savedUser existe mais pas le champ recos (étrange)
            console.warn(`INFO: savedUser pour ${userIdStr} existe mais savedUser.recommandations est manquant. Compte comme traité.`);
            usersProcessedAndSavedCount++; // On compte quand même si la sauvegarde principale a fonctionné
        } else { // savedUser est null/undefined
            console.warn(`INFO: savedUser est null/undefined pour ${userIdStr}, non compté comme traité avec succès.`);
        }

      } catch (saveError) {
        console.error(`❌ Erreur lors de user.save() pour ${userIdStr}:`, saveError);
      }
    }
    console.log(`👍 Processus de mise à jour des utilisateurs terminé pour ${usersProcessedAndSavedCount} utilisateurs (cfParams et recommandations).`);

    const endTime = Date.now();
    const durationInSeconds = (endTime - startTime) / 1000;
    console.log(`🎉 [7/7] Terminé ! Durée totale: ${durationInSeconds.toFixed(2)} secondes.`);
    
    if (res) {
      res.status(200).json({ 
        message: "Modèle (JS SGD) entraîné, cfParams et recommandations mis à jour (méthode save(), logs détaillés post-save).",
        durationSeconds: durationInSeconds.toFixed(2),
        usersProcessed: usersProcessedAndSavedCount 
      });
    }
    
  } catch (error) {
    console.error("❌ Erreur critique globale:", error);
    if (res && !res.headersSent) {
      res.status(500).json({ message: "Erreur serveur globale.", error: error.message });
    }
  }
};


// function dotProduct(vecA, vecB) {
//   let product = 0;
//   for (let i = 0; i < vecA.length; i++) {
//     product += vecA[i] * vecB[i];
//   }
//   return product;
// }

// // Fonction utilitaire pour initialiser un vecteur avec des petites valeurs aléatoires
// function randomVector(size, scale = 0.01) {
//   return Array(size).fill(0).map(() => (Math.random() - 0.5) * scale);
// }


// export const trainAndGenerateRecommendationsJS = async (req, res) => {
//   console.log("Début de l'entraînement du modèle de recommandation (JavaScript SGD)...");
//   const startTime = Date.now();

//   try {
//     // 1. Récupérer les données
//     const allRatings = await Rating.find({})
//       .populate('user', '_id')
//       .populate('menuItem', '_id')
//       .lean(); // .lean() pour des objets JS simples et plus de performance

//     const existingUserIds = new Set((await User.find({}).select('_id').lean()).map(u => u._id.toString()));
//     const existingMenuItemIds = new Set((await MenuItem.find({}).select('_id').lean()).map(item => item._id.toString()));

//     if (allRatings.length < 10) { // Seuil pour un entraînement un minimum significatif
//       const message = "Pas assez de notes pour un entraînement significatif.";
//       console.log(message);
//       if (res) return res.status(200).json({ message });
//       return;
//     }

//     // 2. Préparer les données pour l'entraînement
//     console.log("Préparation des données...");
//     const userToIntegerIndex = new Map();
//     const itemToIntegerIndex = new Map();
//     const integerIndexToUserId = [];
//     const integerIndexToItemId = [];

//     let nextUserIntegerIndex = 0;
//     let nextItemIntegerIndex = 0;

//     // Calculer la note moyenne pour chaque utilisateur (pour la normalisation)
//     const userRatingsSum = new Map();
//     allRatings.forEach(r => {
//       if (r.user && r.user._id) { // Vérifier que r.user et r.user._id existent
//         const userIdStr = r.user._id.toString();
//         if (!userRatingsSum.has(userIdStr)) {
//           userRatingsSum.set(userIdStr, { sum: 0, count: 0 });
//         }
//         const userData = userRatingsSum.get(userIdStr);
//         userData.sum += r.rating;
//         userData.count += 1;
//       }
//     });

//     const userMeanRatings = new Map();
//     userRatingsSum.forEach((data, userIdStr) => {
//       userMeanRatings.set(userIdStr, data.count > 0 ? data.sum / data.count : 3); // 3 comme moyenne par défaut si pas de notes
//     });

//     const trainingData = []; // Contient [userIndex, itemIndex, normalizedRating, originalUserIdStr]

//     allRatings.forEach(r => {
//       if (r.user && r.user._id && r.menuItem && r.menuItem._id) {
//         const userIdStr = r.user._id.toString();
//         const menuItemIdStr = r.menuItem._id.toString();
//         const userMean = userMeanRatings.get(userIdStr) || 3; // Moyenne globale/par défaut

//         let currentUserIntIndex = userToIntegerIndex.get(userIdStr);
//         if (currentUserIntIndex === undefined) {
//           currentUserIntIndex = nextUserIntegerIndex++;
//           userToIntegerIndex.set(userIdStr, currentUserIntIndex);
//           integerIndexToUserId[currentUserIntIndex] = userIdStr;
//         }

//         let currentItemIntIndex = itemToIntegerIndex.get(menuItemIdStr);
//         if (currentItemIntIndex === undefined) {
//           currentItemIntIndex = nextItemIntegerIndex++;
//           itemToIntegerIndex.set(menuItemIdStr, currentItemIntIndex);
//           integerIndexToItemId[currentItemIntIndex] = menuItemIdStr;
//         }
        
//         trainingData.push({
//             userIndex: currentUserIntIndex,
//             itemIndex: currentItemIntIndex,
//             normalizedRating: r.rating - userMean, // Entraînement sur les notes normalisées
//             originalUserId: userIdStr, // Pour pouvoir récupérer la moyenne user plus tard
//             originalRating: r.rating // Utile pour le calcul d'erreur non normalisée si besoin
//         });
//       }
//     });
    
//     if (trainingData.length === 0) {
//       const message = "Données de notation valides insuffisantes après mapping.";
//       console.log(message);
//       if (res) return res.status(200).json({ message });
//       return;
//     }

//     const numModelUsers = nextUserIntegerIndex;
//     const numModelItems = nextItemIntegerIndex;

//     // 3. Initialiser les Paramètres du Modèle et Hyperparamètres
//     console.log(`Initialisation pour ${numModelUsers} utilisateurs et ${numModelItems} articles du modèle.`);
//     const embeddingDim = 10; // Comme dans votre code TF.js
//     const learningRate = 0.01; // Taux d'apprentissage
//     const lambda = 0.02;       // Coefficient de régularisation L2
//     const epochs = 20;         // Nombre d'itérations sur les données

//     let userEmbeddings = Array(numModelUsers).fill(null).map(() => randomVector(embeddingDim));
//     let itemEmbeddings = Array(numModelItems).fill(null).map(() => randomVector(embeddingDim));
//     let userBiases = Array(numModelUsers).fill(0).map(() => (Math.random() - 0.5) * 0.01);
//     let itemBiases = Array(numModelItems).fill(0).map(() => (Math.random() - 0.5) * 0.01);

//     // 4. Entraînement avec SGD
//     console.log("Début de l'entraînement SGD...");
//     for (let epoch = 0; epoch < epochs; epoch++) {
//       let currentEpochErrorSum = 0;
//       // Mélanger les données d'entraînement pour chaque époque (important pour SGD)
//       trainingData.sort(() => Math.random() - 0.5);

//       for (const sample of trainingData) {
//         const u = sample.userIndex;
//         const i = sample.itemIndex;
//         const normalizedActualRating = sample.normalizedRating;

//         const userEmbedding_u = userEmbeddings[u];
//         const itemEmbedding_i = itemEmbeddings[i];
//         const userBias_u = userBiases[u];
//         const itemBias_i = itemBiases[i];

//         // Prédiction de la note normalisée
//         const predictedNormalizedRating = dotProduct(userEmbedding_u, itemEmbedding_i) + userBias_u + itemBias_i;
        
//         const error = normalizedActualRating - predictedNormalizedRating;
//         currentEpochErrorSum += error * error; // MSE

//         // Mettre à jour les biais
//         userBiases[u] += learningRate * (error - lambda * userBias_u);
//         itemBiases[i] += learningRate * (error - lambda * itemBias_i);

//         // Mettre à jour les embeddings
//         for (let d = 0; d < embeddingDim; d++) {
//           const uOld = userEmbedding_u[d];
//           const iOld = itemEmbedding_i[d];
//           userEmbeddings[u][d] += learningRate * (error * iOld - lambda * uOld);
//           itemEmbeddings[i][d] += learningRate * (error * uOld - lambda * iOld);
//         }
//       }
//       const mse = currentEpochErrorSum / trainingData.length;
//       console.log(`Époque ${epoch + 1}/${epochs} - MSE: ${mse.toFixed(5)}`);
//       if (mse < 0.01 && epoch > 5) { // Condition d'arrêt simple
//           console.log("Convergence anticipée atteinte.");
//           break;
//       }
//     }
//     console.log("Entraînement SGD terminé.");

//     // 5. Mettre à jour les paramètres pour les utilisateurs et articles EXISTANTS
//     console.log("Mise à jour des paramètres dans la base de données...");
//     for (let u_idx = 0; u_idx < numModelUsers; u_idx++) {
//       const userIdStr = integerIndexToUserId[u_idx];
//       if (existingUserIds.has(userIdStr)) { // Uniquement pour les utilisateurs existants
//         await User.findByIdAndUpdate(userIdStr, {
//           $set: {
//             'cfParams.w': userEmbeddings[u_idx],
//             'cfParams.b': userBiases[u_idx],
//             'cfParams.lastTrained': new Date(),
//           }
//         }).exec();
//       }
//     }

//     for (let i_idx = 0; i_idx < numModelItems; i_idx++) {
//       const menuItemIdStr = integerIndexToItemId[i_idx];
//       if (existingMenuItemIds.has(menuItemIdStr)) { // Uniquement pour les articles existants
//         await MenuItem.findByIdAndUpdate(menuItemIdStr, {
//           $set: {
//             cfFeatures: itemEmbeddings[i_idx],
//             // Si vous ajoutez un champ pour le biais de l'item dans menuItemSchema, mettez-le à jour ici:
//             // 'cfParams.b': itemBiases[i_idx] 
//           }
//         }).exec();
//       }
//     }
//     console.log("Paramètres (embeddings/biais) mis à jour pour les entités existantes.");

//     // 6. Générer et stocker les recommandations pour les utilisateurs EXISTANTS
//     console.log("Génération des recommandations...");
//     const allCurrentUsersFromDB = await User.find({ _id: { $in: Array.from(existingUserIds) } }).select('_id favorites').lean();
//     const allCurrentMenuItemsFromDB = await MenuItem.find({ _id: { $in: Array.from(existingMenuItemIds) } }).select('_id').lean();

//     for (const dbUser of allCurrentUsersFromDB) {
//       const userIdStr = dbUser._id.toString();
//       const userIntIndex = userToIntegerIndex.get(userIdStr);
//       const userMean = userMeanRatings.get(userIdStr) || 3; // Récupérer la moyenne de cet utilisateur

//       // Si l'utilisateur n'était pas dans le set d'entraînement (pas de notes), on ne peut pas générer
//       if (userIntIndex === undefined || !userEmbeddings[userIntIndex]) {
//         continue;
//       }

//       const currentUserEmbedding = userEmbeddings[userIntIndex];
//       const currentUserBias = userBiases[userIntIndex];
//       const recommendations = [];

//       const interactedItemIds = new Set();
//       // Récupérer les articles déjà notés par cet utilisateur pour ne pas les recommander
//       allRatings.filter(r => r.user && r.user._id.toString() === userIdStr)
//                 .forEach(r => r.menuItem && interactedItemIds.add(r.menuItem._id.toString()));
//       // Ajouter les favoris pour ne pas les recommander à nouveau s'ils ne sont pas déjà notés
//       if (dbUser.favorites) {
//         dbUser.favorites.forEach(favId => interactedItemIds.add(favId.toString()));
//       }


//       for (const dbMenuItem of allCurrentMenuItemsFromDB) {
//         const menuItemIdStr = dbMenuItem._id.toString();
//         if (interactedItemIds.has(menuItemIdStr)) { // Ne pas recommander les articles déjà vus/notés/favoris
//           continue;
//         }

//         const itemIntIndex = itemToIntegerIndex.get(menuItemIdStr);
//         // Si l'article n'était pas dans le set d'entraînement, on ne peut pas prédire
//         if (itemIntIndex === undefined || !itemEmbeddings[itemIntIndex]) {
//           continue;
//         }

//         const currentItemEmbedding = itemEmbeddings[itemIntIndex];
//         const currentItemBias = itemBiases[itemIntIndex];

//         const predictedNormalizedRating = dotProduct(currentUserEmbedding, currentItemEmbedding) + currentUserBias + currentItemBias;
//         const predictedOriginalScaleRating = predictedNormalizedRating + userMean; // Dénormaliser

//         recommendations.push({ menuItemId: dbMenuItem._id, predictedRating: predictedOriginalScaleRating });
//       }

//       recommendations.sort((a, b) => b.predictedRating - a.predictedRating);
//       const topNRecommendationIds = recommendations.slice(0, 15).map(rec => rec.menuItemId);
      
//       await User.findByIdAndUpdate(dbUser._id, { recommendations: topNRecommendationIds }).exec();
//     }

//     const endTime = Date.now();
//     const durationInSeconds = (endTime - startTime) / 1000;
//     console.log(`Recommandations générées et stockées. Durée totale: ${durationInSeconds.toFixed(2)} secondes.`);
    
//     if (res) {
//       res.status(200).json({ 
//         message: "Modèle (JS SGD) entraîné et recommandations générées avec succès.",
//         durationSeconds: durationInSeconds.toFixed(2)
//       });
//     }
    
//   } catch (error) {
//     console.error("Erreur lors de l'entraînement JS SGD ou de la génération des recommandations:", error);
//     if (res && !res.headersSent) {
//       res.status(500).json({ message: "Erreur serveur pendant l'entraînement JS.", error: error.message });
//     }
//   }
// };

// export const trainAndGenerateRecommendations = async (req, res) => {
//   try {
//     console.log("Début de l'entraînement du modèle de recommandation...");

//     const allRatings = await Rating.find({})
//                             .populate('user', '_id')
//                             .populate('menuItem', '_id');

//     if (allRatings.length < 10) { // Augmenter le seuil pour un entraînement significatif
//       if (res) return res.status(200).json({ message: "Pas assez de notes pour un entraînement significatif." });
//       console.log("Pas assez de notes pour un entraînement significatif.");
//       return;
//     }

//     // 1. Calculer la note moyenne pour chaque utilisateur
//     const userRatingsSum = new Map(); 
//     allRatings.forEach(r => {
//         if (r.user && r.user._id) {
//             const userIdStr = r.user._id.toString();
//             if (!userRatingsSum.has(userIdStr)) {
//                 userRatingsSum.set(userIdStr, { sum: 0, count: 0 });
//             }
//             const userData = userRatingsSum.get(userIdStr);
//             userData.sum += r.rating;
//             userData.count += 1;
//         }
//     });

//     const userMeanRatings = new Map(); 
//     userRatingsSum.forEach((data, userIdStr) => {
//         userMeanRatings.set(userIdStr, data.count > 0 ? data.sum / data.count : 0);
//     });
//     console.log("Notes moyennes par utilisateur calculées.");

//     // 2. Préparer les données pour TensorFlow.js (avec normalisation)
//     const userToIntegerIndex = new Map();
//     const itemToIntegerIndex = new Map();
//     const integerIndexToUser = []; 
//     const integerIndexToItem = []; 

//     let nextUserIntegerIndex = 0;
//     let nextItemIntegerIndex = 0;

//     const usersTensorData = [];
//     const itemsTensorData = [];
//     const normalizedRatingsTensorData = []; 

//     allRatings.forEach(r => {
//       if (r.user && r.user._id && r.menuItem && r.menuItem._id) {
//         const userIdStr = r.user._id.toString();
//         const menuItemIdStr = r.menuItem._id.toString();
//         const userMean = userMeanRatings.get(userIdStr) || 0; 

//         let currentUserIntIndex = userToIntegerIndex.get(userIdStr);
//         if (currentUserIntIndex === undefined) {
//           currentUserIntIndex = nextUserIntegerIndex++;
//           userToIntegerIndex.set(userIdStr, currentUserIntIndex);
//           integerIndexToUser[currentUserIntIndex] = userIdStr;
//         }

//         let currentItemIntIndex = itemToIntegerIndex.get(menuItemIdStr);
//         if (currentItemIntIndex === undefined) {
//           currentItemIntIndex = nextItemIntegerIndex++;
//           itemToIntegerIndex.set(menuItemIdStr, currentItemIntIndex);
//           integerIndexToItem[currentItemIntIndex] = menuItemIdStr;
//         }
        
//         usersTensorData.push(currentUserIntIndex);
//         itemsTensorData.push(currentItemIntIndex);
//         normalizedRatingsTensorData.push(r.rating - userMean); 
//       }
//     });
    
//     if (usersTensorData.length === 0) {
//         if (res) return res.status(200).json({ message: "Données de notation valides insuffisantes après mapping." });
//         console.log("Données de notation valides insuffisantes après mapping.");
//         return;
//     }

//     const numUsers = nextUserIntegerIndex;
//     const numItems = nextItemIntegerIndex;
//     const embeddingDim = 10; 
//     const lambda_ = 0.01; // Coefficient de régularisation L2 (à ajuster)

//     const userTensor = tf.tensor1d(usersTensorData, 'int32');
//     const itemTensor = tf.tensor1d(itemsTensorData, 'int32');
//     const normalizedRatingTensor = tf.tensor1d(normalizedRatingsTensorData); 

//     // 3. Définir et entraîner le modèle
//     const userInput = tf.input({shape: [1], name: 'user_input', dtype: 'int32'});
//     const itemInput = tf.input({shape: [1], name: 'item_input', dtype: 'int32'});

//     const userEmbeddingLayer = tf.layers.embedding({
//         inputDim: numUsers, 
//         outputDim: embeddingDim, 
//         inputLength: 1, 
//         name: 'user_embedding',
//         embeddingsRegularizer: tf.regularizers.l2({l2: lambda_}) // Régularisation L2
//     });
//     const itemEmbeddingLayer = tf.layers.embedding({
//         inputDim: numItems, 
//         outputDim: embeddingDim, 
//         inputLength: 1, 
//         name: 'item_embedding',
//         embeddingsRegularizer: tf.regularizers.l2({l2: lambda_}) // Régularisation L2
//     });

//     const userVec = tf.layers.flatten().apply(userEmbeddingLayer.apply(userInput));
//     const itemVec = tf.layers.flatten().apply(itemEmbeddingLayer.apply(itemInput));
    
//     const dotProduct = tf.layers.dot({axes: 1}).apply([userVec, itemVec]);

//     const userBiasLayer = tf.layers.embedding({
//         inputDim: numUsers, 
//         outputDim: 1, 
//         inputLength: 1, 
//         name: 'user_bias',
//         embeddingsRegularizer: tf.regularizers.l2({l2: lambda_}) // Régularisation L2
//     });
//     const itemBiasLayer = tf.layers.embedding({
//         inputDim: numItems, 
//         outputDim: 1, 
//         inputLength: 1, 
//         name: 'item_bias',
//         embeddingsRegularizer: tf.regularizers.l2({l2: lambda_}) // Régularisation L2
//     });
    
//     const userBiasVec = tf.layers.flatten().apply(userBiasLayer.apply(userInput));
//     const itemBiasVec = tf.layers.flatten().apply(itemBiasLayer.apply(itemInput));

//     let prediction = tf.layers.add().apply([dotProduct, userBiasVec, itemBiasVec]); 

//     const model = tf.model({inputs: [userInput, itemInput], outputs: prediction});
    
//     // La perte de régularisation est ajoutée automatiquement par TensorFlow
//     // lorsque les couches ont des `embeddingsRegularizer` (ou `kernelRegularizer`, `biasRegularizer`).
//     model.compile({optimizer: tf.train.adam(0.005), loss: 'meanSquaredError'});

//     console.log("Résumé du modèle (prédisant des notes normalisées, avec régularisation):", model.summary());
//     console.log(`Entraînement avec numUsers (mappés): ${numUsers}, numItems (mappés): ${numItems}, lambda: ${lambda_}`);

//     const history = await model.fit([userTensor, itemTensor], normalizedRatingTensor, { 
//       epochs: 30, 
//       batchSize: 32, 
//       shuffle: true,
//       validationSplit: 0.1, // Optionnel: utiliser une partie des données pour la validation
//       callbacks: [
//           tf.callbacks.earlyStopping({monitor: 'val_loss', patience: 5, minDelta: 0.0005 }), // Monitorer val_loss
//           // Vous pouvez ajouter un callback pour logger la perte de régularisation si besoin,
//           // mais elle est incluse dans la 'loss' et 'val_loss' totales.
//       ]
//     });
//     const finalLoss = history.history.loss.pop() || (history.history.loss.length > 0 ? history.history.loss[history.history.loss.length -1] : 'N/A');
//     const finalValLoss = history.history.val_loss ? (history.history.val_loss.pop() || (history.history.val_loss.length > 0 ? history.history.val_loss[history.history.val_loss.length -1] : 'N/A')) : 'N/A';
//     console.log(`Entraînement terminé. Perte finale: ${finalLoss}, Perte de validation finale: ${finalValLoss}`);

//     // 4. Extraire les embeddings entraînés
//     const userEmbeddings = userEmbeddingLayer.getWeights()[0].arraySync();
//     const itemEmbeddings = itemEmbeddingLayer.getWeights()[0].arraySync();
//     const userBiases = userBiasLayer.getWeights()[0].arraySync();
//     const itemBiases = itemBiasLayer.getWeights()[0].arraySync();

//     // 5. Mettre à jour User.cfParams et MenuItem.cfFeatures
//     console.log("Début de la mise à jour des embeddings dans la DB...");
//     for (let i = 0; i < numUsers; i++) {
//       const userIdStr = integerIndexToUser[i];
//       if (userIdStr && userEmbeddings[i] && userBiases[i]) {
//         await User.findByIdAndUpdate(userIdStr, {
//           $set: {
//             'cfParams.w': userEmbeddings[i],
//             'cfParams.b': userBiases[i][0],
//             'cfParams.lastTrained': new Date(),
//           }
//         });
//       }
//     }

//     for (let i = 0; i < numItems; i++) {
//       const menuItemIdStr = integerIndexToItem[i];
//       if (menuItemIdStr && itemEmbeddings[i] && itemBiases[i]) { 
//         await MenuItem.findByIdAndUpdate(menuItemIdStr, {
//           $set: {
//             cfFeatures: itemEmbeddings[i]
//           }
//         });
//       }
//     }
//     console.log("Embeddings et biais d'articles mis à jour dans la base de données.");

//     // 6. Générer et stocker les recommandations pour chaque utilisateur
//     console.log("Début de la génération des recommandations...");
//     const allDbUsers = await User.find({}).select('_id favorites'); 
//     const allDbMenuItems = await MenuItem.find({}).select('_id');

//     for (const dbUser of allDbUsers) {
//       const userIdStr = dbUser._id.toString();
//       const userIntIndex = userToIntegerIndex.get(userIdStr);
//       const userMean = userMeanRatings.get(userIdStr) || 0; 
      
//       if (userIntIndex === undefined || !userEmbeddings[userIntIndex] || !userBiases[userIntIndex]) continue;

//       const userEmbeddingVector = tf.tensor1d(userEmbeddings[userIntIndex]);
//       const userBiasValue = userBiases[userIntIndex][0];
//       const recommendations = [];

//       const interactedItemIds = new Set();
//       const userSpecificRatings = await Rating.find({ user: dbUser._id }).select('menuItem').lean();
//       userSpecificRatings.forEach(r => interactedItemIds.add(r.menuItem.toString()));
//       dbUser.favorites.forEach(favId => interactedItemIds.add(favId.toString()));

//       for (const dbMenuItem of allDbMenuItems) {
//         const menuItemIdStr = dbMenuItem._id.toString();
//         const itemIntIndex = itemToIntegerIndex.get(menuItemIdStr);

//         if (itemIntIndex === undefined || !itemEmbeddings[itemIntIndex] || !itemBiases[itemIntIndex] || interactedItemIds.has(menuItemIdStr)) {
//           continue;
//         }

//         const itemEmbeddingVector = tf.tensor1d(itemEmbeddings[itemIntIndex]);
//         const itemBiasValue = itemBiases[itemIntIndex][0];
        
//         const dotProductPred = tf.dot(userEmbeddingVector, itemEmbeddingVector).dataSync()[0];
//         const predictedNormalizedRating = dotProductPred + userBiasValue + itemBiasValue;
//         const predictedOriginalScaleRating = predictedNormalizedRating + userMean; 
        
//         recommendations.push({ menuItemId: dbMenuItem._id, predictedRating: predictedOriginalScaleRating });
//       }

//       recommendations.sort((a, b) => b.predictedRating - a.predictedRating);
//       const topNRecommendations = recommendations.slice(0, 15).map(rec => rec.menuItemId);
      
//       await User.findByIdAndUpdate(dbUser._id, { recommendations: topNRecommendations });
//     }

//     console.log("Recommandations générées et stockées pour les utilisateurs.");
//     if (res) {
//         res.status(200).json({ 
//             message: "Modèle entraîné et recommandations générées avec succès.",
//             finalLoss: finalLoss,
//             finalValLoss: finalValLoss 
//         });
//     }
    
//   } catch (error) {
//     console.error("Erreur lors de l'entraînement ou de la génération des recommandations:", error);
//     if (res) {
//         res.status(500).json({ message: "Erreur serveur.", error: error.message });
//     }
//   }
// };

