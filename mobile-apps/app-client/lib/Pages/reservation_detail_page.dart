
// lib/pages/reservation_detail_page.dart

import 'package:flutter/material.dart';
 // Importer votre modèle de réservation
import 'package:hungerz/Locale/locales.dart'; // Pour les textes localisés
 // Pour kMainColor et autres couleurs de thème
import 'package:hungerz/models/reservation_model.dart';
import 'package:intl/intl.dart'; // Pour le formatage de date/heure
import 'package:qr_flutter/qr_flutter.dart'; // Importer le package QR Code

class ReservationDetailPage extends StatelessWidget {
  final ReservationModel reservation;

  const ReservationDetailPage({Key? key, required this.reservation}) : super(key: key);

  // Helper pour afficher une ligne de détail (icône + texte)
  Widget _buildDetailRow(BuildContext context, IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          SizedBox(width: 12),
          Text("$title : ", style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }

  // Helper pour la couleur du statut
  Color _getStatusColor(String status, BuildContext context) {
     switch (status.toLowerCase()) {
       case 'confirmed': return Colors.green.shade600;
       case 'pending': return Colors.orange.shade600;
       case 'completed': return Colors.blue.shade600;
       case 'cancelled': return Colors.red.shade600;
       case 'no-show': return Colors.grey.shade700;
       default: return Theme.of(context).disabledColor;
     }
  }


  @override
  Widget build(BuildContext context) {
    var locale = AppLocalizations.of(context)!;
    // Formatteurs pour date et heure (vous pouvez les rendre statiques ou les définir une fois)
    final DateFormat dateFormatter = DateFormat('EEEE, d MMMM yyyy', locale.locale.languageCode);
    final DateFormat timeFormatter = DateFormat('HH:mm', locale.locale.languageCode);

    return Scaffold(
      appBar: AppBar(
        title: Text( "Détails Réservation",style: Theme.of(context).textTheme.bodyLarge,),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 1, // Légère ombre
        iconTheme: IconThemeData(color: Theme.of(context).textTheme.bodyLarge?.color), // Couleur du bouton retour
        titleTextStyle: Theme.of(context).textTheme.titleLarge, // Style du titre
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center( // Centrer le contenu principal
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, // Centrer les éléments horizontalement
            children: [
              // Titre principal avec l'ID court
              Text(
                "${ 'Réservation'} #${reservation.id.length > 8 ? reservation.id.substring(0,8) : reservation.id}...",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),

              // Carte pour les détails de la réservation
              Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(context, Icons.calendar_today_outlined,  "Date", dateFormatter.format(reservation.reservationTime)),
                      _buildDetailRow(context, Icons.access_time_outlined,  "Heure", timeFormatter.format(reservation.reservationTime)),
                      _buildDetailRow(context, Icons.people_alt_outlined,  "Personnes", "${reservation.guests}"),
                      _buildDetailRow(context, Icons.bookmark_border_outlined,  "Statut",
                         (reservation.status.isNotEmpty ? reservation.status[0].toUpperCase() + reservation.status.substring(1) : 'Inconnu')),
                      SizedBox(height: 8),
                      // Couleur du statut
                      Row(
                        children: [
                           SizedBox(width: 32), // Pour aligner avec le texte au-dessus
                           Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                 color: _getStatusColor(reservation.status, context),
                                 borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                (reservation.status.isNotEmpty ? reservation.status[0].toUpperCase() + reservation.status.substring(1) : 'Inconnu'),
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                           ),
                        ],
                      ),

                       if (reservation.preselectedItems != null && reservation.preselectedItems!.isNotEmpty) ...[
                         SizedBox(height: 12),
                         Text("${ "Pré-commande"} :", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                         SizedBox(height: 4),
                         Padding(
                           padding: const EdgeInsets.only(left: 16.0),
                           child: Column( // Pour que chaque item soit sur sa propre ligne
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: reservation.preselectedItems!.map((item) => Padding(
                               padding: const EdgeInsets.symmetric(vertical: 2.0),
                               // Assurez-vous que 'item' a bien 'name' ou adaptez pour récupérer le nom via 'menuItemId'
                               child: Text("• ${item['quantity']}x ${item['name'] ?? item['menuItemId']}",
                                          style: Theme.of(context).textTheme.bodyMedium),
                             )).toList(),
                           ),
                         ),
                       ],
                       if (reservation.specialRequests != null && reservation.specialRequests!.isNotEmpty) ...[
                          SizedBox(height: 12),
                          Text("${ "Demandes spéciales"} :", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: Text(reservation.specialRequests!, style: Theme.of(context).textTheme.bodyMedium),
                          )
                       ]
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              // --- Affichage du QR Code ---
              Text(
                 "Présentez ce QR Code à l'accueil :",
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              if (reservation.id.isNotEmpty) // Assure que l'ID n'est pas vide
                Container(
                  padding: EdgeInsets.all(8), // Petit padding autour du QR Code
                  decoration: BoxDecoration(
                    color: Colors.white, // Fond blanc pour une meilleure lisibilité du QR
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12) // Coins arrondis
                  ),
                  child: QrImageView( // Depuis le package qr_flutter
                    data: reservation.id, // Le contenu du QR Code est l'ID de la réservation
                    version: QrVersions.auto, // Laisse le package choisir la version
                    size: 220.0,              // Taille du QR Code
                    gapless: false,           // Laisse un petit bord blanc (recommandé)
                    // Optionnel: Ajouter un logo au centre
                    // embeddedImage: AssetImage('assets/images/logo_qr_center.png'), // Votre logo
                    // embeddedImageStyle: QrEmbeddedImageStyle(size: Size(40, 40)),
                    errorStateBuilder: (cxt, err) { // Gérer les erreurs de génération
                      return Container(
                        child: Center(
                          child: Text(
                             "Erreur de génération du QR code.",
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                Text("ID de réservation invalide pour générer le QR Code."),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}