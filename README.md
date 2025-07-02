# Projet : Réalisation d'un Restaurant Connecté et Intelligent

Ce projet, réalisé dans le cadre d'un mémoire de Licence en Informatique, propose un prototype fonctionnel d'un écosystème complet pour un restaurant connecté et intelligent. 

## 🎯 Problématique

Le secteur de la restauration souffre souvent d'une fragmentation de ses systèmes d'information, entraînant des inefficacités, des erreurs de commande, et une expérience client dégradée. La problématique centrale est de concevoir une architecture assurant une **synchronisation totale et en temps réel** des données et des processus entre toutes les composantes du restaurant. 

## ✨ Solution

La solution est un écosystème technologique intégré où plusieurs applications dédiées et dispositifs connectés interagissent de manière transparente en temps réel. Le cœur du système repose sur une communication instantanée via **WebSockets (Socket.IO)** pour garantir la cohérence des données à travers tout l'écosystème. 

Un **système de recommandation de plats** basé sur le filtrage collaboratif est également intégré pour personnaliser et enrichir l'expérience client. 


## 📱 Écosystème des Applications

L'écosystème se compose des applications suivantes, toutes développées avec Flutter pour une base de code unifiée. 

* **`backend`**: Le serveur central développé en Node.js avec Express.js, gérant la logique métier, la base de données et les communications temps réel via Socket.IO. 
* **`app-client`**: Permet aux clients de consulter le menu, passer des commandes (livraison, à emporter, sur place), réserver une table, payer et recevoir des recommandations de plats personnalisées. 
* **`app-kiosk-tablet`**: Une tablette sur chaque table affichant un QR code pour démarrer une session de commande. Permet la commande directe à table, synchronisée en temps réel avec la cuisine. 
* **`app-kitchen`**: Reçoit instantanément toutes les commandes (client, tablette) et permet au personnel de cuisine de gérer leur préparation et de notifier quand un plat est prêt. 
* **`app-waiter`**: Notifie le personnel de salle lorsqu'un plat est prêt à être servi, en indiquant la table concernée. 
* **`app-head-waiter`**: Permet au responsable de salle de gérer les réservations et de visualiser l'état d'occupation des tables en temps réel. 
* **`app-manager`**: Un tableau de bord pour le gérant, offrant une vue d'ensemble des ventes, la gestion des stocks (avec alertes IoT) et la gestion du catalogue de plats. 
* **`app-delivery`**: Interface pour les livreurs, leur assignant des missions de livraison avec les détails de la commande et l'itinéraire. 
* **`app-iot-simulator`**: Une application pour simuler les équipements connectés (four, réfrigérateur, capteurs de stock) et envoyer des alertes au système, démontrant les capacités de gestion proactive. 

## 🛠️ Stack Technique

### Backend
* **Serveur**: Node.js, Express.js 
* **Base de Données**: MongoDB avec Mongoose 
* **Communication Temps Réel**: Socket.IO 
* **Mise en Cache**: Redis 
* **Authentification**: JSON Web Tokens (JWT) 

### Frontend (Toutes les applications)
* **Framework**: Flutter & Dart 
* **Gestion d'état**: BLoC / Cubit 
* **Communication**: `http` pour les API REST, `socket_io_client` pour les WebSockets 
