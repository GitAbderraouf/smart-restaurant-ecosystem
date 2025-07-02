// lib/Pages/unpaid_bill_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hungerz/cubits/unpaid_bill_cubit/unpaid_bill_cubit.dart'; // Pour le Cubit
import 'package:hungerz/models/unpaid_bill_model.dart';
import 'package:hungerz/Themes/colors.dart'; // Vos couleurs (kMainColor)
import 'package:intl/intl.dart'; // Pour le formatage des dates
// import 'package:hungerz/Locale/locales.dart'; // Si vous avez besoin de traductions

class UnpaidBillDetailPage extends StatelessWidget {
  final UnpaidBillModel bill;

  const UnpaidBillDetailPage({Key? key, required this.bill}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sessionDetails = bill.tableSessionDetails;
    // final locale = AppLocalizations.of(context)!; // Décommentez si vous utilisez des traductions

    return Scaffold(
      appBar: AppBar(
        title: Text("Détail Facture #${bill.id.substring(0, 6)}..."), // Titre de la page
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 1, // Légère élévation pour séparer de la TabBar si OrderPage en a une visible
        iconTheme: IconThemeData(color: Theme.of(context).textTheme.bodyLarge?.color),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Informations générales de la facture
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Facture pour Table: ${sessionDetails.tableDisplayName}",
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: kMainColor),
                    ),
                    SizedBox(height: 8),
                    _buildDetailRow(Icons.calendar_today_outlined,
                        "Date de session: ${DateFormat('EEEE, d MMMM yyyy', /*locale.locale.languageCode*/).format(sessionDetails.startTime.toLocal())}"),
                    _buildDetailRow(Icons.access_time_outlined,
                        "Heure de début: ${DateFormat('HH:mm', /*locale.locale.languageCode*/).format(sessionDetails.startTime.toLocal())}"),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "TOTAL À PAYER:",
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "${bill.total.toStringAsFixed(2)} DA",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: kMainColor, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                     SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Chip(
                        label: Text(
                          bill.paymentStatus == 'pending' ? "En attente de paiement" : bill.paymentStatus.toUpperCase(),
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                        ),
                        backgroundColor: bill.paymentStatus == 'pending' ? Colors.orange.shade700 : Colors.green.shade600,
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            // Section Détail des articles
            Text(
              "Articles Commandés:",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 10),
            if (sessionDetails.items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(child: Text("Aucun article dans cette session.")),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(), // Pour désactiver le scroll de cette ListView interne
                itemCount: sessionDetails.items.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[300]),
                itemBuilder: (context, index) {
                  final item = sessionDetails.items[index];
                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                    leading: (item.image != null && item.image!.isNotEmpty)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item.image!, // Assurez-vous que l'URL est complète
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(width: 60, height: 60, color: Colors.grey[200], child: Icon(Icons.fastfood_outlined, color: Colors.grey[400], size: 30)),
                            ),
                          )
                        : CircleAvatar(child: Icon(Icons.fastfood_outlined, color: Colors.grey[600]), radius: 30, backgroundColor: Colors.grey[200]),
                    title: Text("${item.quantity} x ${item.name}", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
                    subtitle: item.price != null ? Text("Prix unitaire: ${item.price!.toStringAsFixed(2)} DA", style: TextStyle(color: Colors.grey[700])) : null,
                    trailing: item.price != null
                        ? Text(
                            "${(item.quantity * item.price!).toStringAsFixed(2)} DA",
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: kMainColor),
                          )
                        : null,
                  );
                },
              ),
            SizedBox(height: 30),

            // Bouton Payer
            if (bill.paymentStatus == 'pending') // Afficher le bouton seulement si la facture est impayée
              BlocConsumer<UnpaidBillCubit, UnpaidBillState>(
                listener: (context, state) {
                  if (state is BillPaymentSuccess && state.billId == bill.id) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Paiement de la facture #${bill.id.substring(0,6)} réussi !"), backgroundColor: Colors.green),
                    );
                    // Revenir à la page précédente (OrderPage) qui devrait se rafraîchir
                    Navigator.of(context).pop(true); // Envoyer 'true' pour indiquer un succès
                  } else if (state is BillPaymentFailure && state.billId == bill.id) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Échec du paiement: ${state.message}"), backgroundColor: Colors.red),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is BillPaymentProcessing && state.billId == bill.id) {
                    return Center(child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: CircularProgressIndicator(color: kMainColor),
                    ));
                  }
                  return Center(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.payment, color: Colors.white),
                      label: Text("Payer ${bill.total.toStringAsFixed(2)} DA Maintenant", style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        context.read<UnpaidBillCubit>().payBill(bill); // Utilise la méthode simplifiée
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kMainColor,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                      ),
                    ),
                  );
                },
              ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(fontSize: 15, color: Colors.black87))),
        ],
      ),
    );
  }
}