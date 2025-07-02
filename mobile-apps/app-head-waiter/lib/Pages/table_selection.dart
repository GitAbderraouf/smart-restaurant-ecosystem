// file: pages/table_selection_page.dart
// Tous les widgets UI (TableCardWidget, TableReservationsDialog, NotifyKitchenDialog)
// sont maintenant DANS CE FICHIER.

import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:hungerz_ordering/Locale/locales.dart'; // Supprimé car texte hardcodé
import 'package:hungerz_ordering/Pages/login.dart';
import 'package:hungerz_ordering/Theme/colors.dart';
import 'package:hungerz_ordering/cubits/tables_status_cubit.dart';
import 'package:hungerz_ordering/models/allModels.dart';
import 'package:hungerz_ordering/pages/qr_scanner_page.dart';
import 'package:intl/intl.dart';
import 'dart:async';

// Extension pour capitaliser la première lettre (utilisée dans les dialogues)
extension StringExtensionCapitalizeInternal on String {
  String capitalizeFirstLetter() {
    if (isEmpty) return "";
    if (length == 1) return toUpperCase();
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}


// WIDGET: TableCardWidget (Intégré ici)
class TableCardWidget extends StatelessWidget {
  final TableModel table;
  final VoidCallback onTap;
  final String durationOrStatusText;
  final String itemsText;
  final Color tableColor;

  const TableCardWidget({
    Key? key,
    required this.table,
    required this.onTap,
    required this.durationOrStatusText,
    required this.itemsText,
    required this.tableColor,
  }) : super(key: key);

  IconData _getTableIcon(TableStatus status, bool isActive) {
    if (!isActive) return Icons.power_settings_new_outlined;
    switch (status) {
      case TableStatus.free:
        return Icons.event_seat_outlined;
      case TableStatus.occupied:
        return Icons.people_alt_outlined;
      case TableStatus.reserved:
        return Icons.bookmark_added_outlined;
      case TableStatus.needsAttention:
        return Icons.cleaning_services_rounded;
      case TableStatus.unknown:
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color darkTextColor = Colors.black87;
    final Color lightTextColor = Colors.white;

    bool isBackgroundDark = tableColor.computeLuminance() < 0.45;
    
    Color currentPrimaryTextColor = table.isActive
        ? (isBackgroundDark ? lightTextColor : darkTextColor)
        : Colors.grey.shade700;
    Color currentSecondaryTextColor = table.isActive
        ? (isBackgroundDark ? lightTextColor.withOpacity(0.85) : darkTextColor.withOpacity(0.65))
        : Colors.grey.shade600;
    Color currentIconColor = table.isActive
        ? (isBackgroundDark ? lightTextColor.withOpacity(0.9) : darkTextColor.withOpacity(0.75))
        : Colors.grey.shade600;

    return Material(
      color: table.isActive ? tableColor : Colors.grey.shade300,
      borderRadius: BorderRadius.circular(12),
      elevation: table.isActive ? 5.0 : 1.0,
      shadowColor: Colors.black.withOpacity(0.25),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: currentPrimaryTextColor.withOpacity(0.2),
        highlightColor: currentPrimaryTextColor.withOpacity(0.1),
        child: FadedScaleAnimation(
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        table.displayName,
                        style: theme.textTheme.titleLarge!.copyWith(
                            color: currentPrimaryTextColor,
                            fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(_getTableIcon(table.status, table.isActive), color: currentIconColor, size: 24),
                  ],
                ),
                if (durationOrStatusText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      durationOrStatusText,
                      style: theme.textTheme.bodyMedium!.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: currentSecondaryTextColor),
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const Spacer(),
                Text(
                  itemsText,
                  style: theme.textTheme.bodyMedium!.copyWith(
                      fontSize: 15,
                      color: currentSecondaryTextColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// DIALOGUE: TableReservationsDialog (Intégré ici)
class TableReservationsDialog extends StatelessWidget {
  final TableModel tableInitial;

  const TableReservationsDialog({Key? key, required this.tableInitial}) : super(key: key);

  static void show(BuildContext context, TableModel table) {
    context.read<TablesStatusCubit>().fetchReservationsForTable(table.id);
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: BlocProvider.of<TablesStatusCubit>(context),
        child: TableReservationsDialog(tableInitial: table),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      backgroundColor: theme.cardColor,
      titlePadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 10.0),
      contentPadding: const EdgeInsets.fromLTRB(24.0, 10.0, 24.0, 10.0),
      actionsPadding: const EdgeInsets.fromLTRB(24.0, 10.0, 24.0, 24.0),
      title: Text(
        'Réservations pour ${tableInitial.displayName}',
        style: theme.textTheme.headlineSmall?.copyWith(color: theme.primaryColor, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: BlocBuilder<TablesStatusCubit, TablesStatusState>(
          builder: (context, state) {
            TableModel? currentTableDisplay;
            bool isLoadingReservations = false;

            final currentTablesInState = state.tables;
            if (currentTablesInState != null && currentTablesInState.isNotEmpty) {
              currentTableDisplay = currentTablesInState.firstWhere(
                (t) => t.id == tableInitial.id,
                orElse: () => tableInitial, 
              );
              isLoadingReservations = currentTableDisplay.isLoadingReservations;
              if (currentTableDisplay.id == tableInitial.id && currentTableDisplay.associatedReservations.isEmpty && !currentTableDisplay.isLoadingReservations) {
                 // Si la table de l'état est celle initialement passée, qu'elle n'a pas de résa et qu'elle ne charge pas,
                 // on pourrait supposer qu'il n'y en a pas, ou forcer le chargement si l'initiale en avait.
                 // Pour l'instant, on se fie à isLoadingReservations.
                 // Si isLoadingReservations est false et associatedReservations est vide, on affiche "aucune réservation".
              }
            } else {
              currentTableDisplay = tableInitial;
              isLoadingReservations = true; 
            }


            if (isLoadingReservations) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ));
            }
            
            final reservationsToShow = currentTableDisplay.associatedReservations
                .where((r) => r.status == 'confirmed' || r.reservationTime.isAfter(DateTime.now().subtract(const Duration(hours: 2))))
                .toList();
            reservationsToShow.sort((a, b) => a.reservationTime.compareTo(b.reservationTime));

            if (reservationsToShow.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 30.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event_busy_outlined, size: 48, color: theme.hintColor),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune réservation (confirmée ou récente) pour cette table.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(color: theme.hintColor),
                    ),
                  ],
                ),
              );
            }

            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: reservationsToShow.length,
                itemBuilder: (ctx, index) {
                  final reservation = reservationsToShow[index];
                  return Card(
                    elevation: 3.0,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.primaryColor.withOpacity(0.1),
                          child: Icon(Icons.person_pin_circle_outlined, color: theme.primaryColor, size: 28),
                        ),
                        title: Text(
                          '${reservation.customerName} (${reservation.guestCount} pers.)',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text("Heure: ${DateFormat('HH:mm, dd MMM').format(reservation.reservationTime)} (${reservation.status.capitalizeFirstLetter()})", style: theme.textTheme.bodyMedium),
                            if (reservation.preSelectedMenu.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Text(
                                  "Plats: ${reservation.preSelectedMenu.map((e) => "${e.quantity}x ${e.name}").join(', ')}",
                                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 13),
                                ),
                              ),
                            if (reservation.specialRequests != null && reservation.specialRequests!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Text(
                                  "Demandes: ${reservation.specialRequests}",
                                  style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, fontSize: 13),
                                ),
                              ),
                          ],
                        ),
                        isThreeLine: reservation.preSelectedMenu.isNotEmpty || (reservation.specialRequests != null && reservation.specialRequests!.isNotEmpty),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          ),
          child: Text('Fermer', style: TextStyle(fontSize: 16, color: theme.primaryColor, fontWeight: FontWeight.bold)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

// DIALOGUE: NotifyKitchenDialog (Intégré ici)
class NotifyKitchenDialog extends StatelessWidget {
  final ReservationModel reservation;
  final TableModel? associatedTable;

  const NotifyKitchenDialog({
    Key? key,
    required this.reservation,
    this.associatedTable,
  }) : super(key: key);

  static void show(BuildContext context, ReservationModel reservation, TableModel? table) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: BlocProvider.of<TablesStatusCubit>(context),
        child: NotifyKitchenDialog(reservation: reservation, associatedTable: table),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      backgroundColor: theme.cardColor,
      titlePadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 10.0),
      contentPadding: const EdgeInsets.fromLTRB(24.0, 10.0, 24.0, 20.0),
      actionsPadding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 24.0),
      title: Text(
        "Confirmer Pré-commande",
        style: theme.textTheme.headlineSmall?.copyWith(color: theme.primaryColor, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(context, Icons.person_outline, "Client: ${reservation.customerName}"),
            if (associatedTable != null)
              _buildInfoRow(context, Icons.table_restaurant_outlined, "Table: ${associatedTable!.displayName}"),
            _buildInfoRow(context, Icons.calendar_today_outlined, "Heure Résa: ${DateFormat('HH:mm, dd MMM').format(reservation.reservationTime)}"),
            const SizedBox(height: 16),
            Text(
              "Plats Pré-commandés:",
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
            ),
            const SizedBox(height: 8),
            if (reservation.preSelectedMenu.isEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                child: Text("Aucun plat pré-commandé.", style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
              )
            else
              ...reservation.preSelectedMenu.map((item) => Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                child: Text("- ${item.quantity}x ${item.name} (${(item.price * item.quantity).toStringAsFixed(2)} DA)", style: theme.textTheme.bodyMedium),
              )),
            if (reservation.specialRequests != null && reservation.specialRequests!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                "Demandes Spéciales:",
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                child: Text(reservation.specialRequests!, style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
              ),
            ]
          ],
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          ),
          child: Text("Annuler", style: TextStyle(fontSize: 16, color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7))),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.send_to_mobile_outlined, size: 18),
          label: const Text("Notifier Cuisine", style: TextStyle(fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            foregroundColor: theme.colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            elevation: 3.0,
          ),
          onPressed: () {
            if (context.mounted) {
              context.read<TablesStatusCubit>().notifyKitchenOfPreOrder(
                    reservation,
                    associatedTable?.displayName ?? reservation.tableMongoId ?? 'N/A',
                  );
            }
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.primaryColor.withOpacity(0.8)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.black,
          ))),
        ],
      ),
    );
  }
}


// PAGE PRINCIPALE: TableSelectionPage
class TableSelectionPage extends StatefulWidget {
  @override
  _TableSelectionPageState createState() => _TableSelectionPageState();
}

class _TableSelectionPageState extends State<TableSelectionPage> {
  Timer? _sessionDurationTimer;

  @override
  void initState() {
    super.initState();
    // Le minuteur démarre et appelle setState pour reconstruire et mettre à jour les durées
    _sessionDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) { // MODIFIÉ: Intervalle réduit à 1 seconde
      if (mounted && context.read<TablesStatusCubit>().state.tables != null) {
        // On appelle setState seulement si le widget est toujours monté
        // et qu'il y a des tables à potentiellement mettre à jour.
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _sessionDurationTimer?.cancel();
    super.dispose();
  }

  Color _getTableColor(TableModel table, BuildContext context) {
    final theme = Theme.of(context);
    final Color freeColor = newOrderColor ?? Colors.green.shade600;
    final Color occupiedColor = buttonColor ?? theme.primaryColorDark;
    final Color reservedColor = Colors.blue.shade600;
    final Color attentionColor = Colors.orange.shade700;
    final Color inactiveColor = Colors.grey.shade400;
    final Color unknownColor = Colors.grey.shade500;

    if (!table.isActive) return inactiveColor;

    switch (table.status) {
      case TableStatus.free:
        return freeColor;
      case TableStatus.occupied:
        return occupiedColor;
      case TableStatus.reserved:
        return reservedColor;
      case TableStatus.needsAttention:
        return attentionColor;
      case TableStatus.unknown:
      default:
        return unknownColor;
    }
  }

  String _getDurationOrStatusText(TableModel table) {
    if (table.status == TableStatus.occupied && table.sessionStartTime != null) {
      final duration = DateTime.now().difference(table.sessionStartTime!);
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      if (hours > 0) {
        return "${hours}h ${minutes}min";
      } else if (minutes > 0) {
        return "${minutes}min";
      } else {
        return "${duration.inSeconds}s";
      }
    } else if (table.status == TableStatus.reserved) {
      final upcomingConfirmed = table.associatedReservations
          .where((r) => r.status == 'confirmed' && r.reservationTime.isAfter(DateTime.now().subtract(const Duration(minutes: 15))))
          .toList();
      if (upcomingConfirmed.isNotEmpty) {
        upcomingConfirmed.sort((a, b) => a.reservationTime.compareTo(b.reservationTime));
        return "Résa: ${DateFormat('HH:mm').format(upcomingConfirmed.first.reservationTime)}";
      }
      return "Réservée";
    }
    return "";
  }

  String _getItemsText(TableModel table) {
    if (table.status == TableStatus.occupied) {
      return table.currentCustomerName != null && table.currentCustomerName!.isNotEmpty
          ? "Client: ${table.currentCustomerName!.split(' ').first}"
          : "Occupée";
    } else if (table.status == TableStatus.free && table.isActive) {
      return "Libre";
    } else if (table.status == TableStatus.reserved) {
      final upcomingConfirmed = table.associatedReservations
          .where((r) => r.status == 'confirmed' && r.reservationTime.isAfter(DateTime.now().subtract(const Duration(minutes: 15))))
          .toList();
      if (upcomingConfirmed.isNotEmpty) {
        upcomingConfirmed.sort((a, b) => a.reservationTime.compareTo(b.reservationTime));
        return "${upcomingConfirmed.first.guestCount} pers.";
      }
      return "Réservée";
    } else if (!table.isActive) {
      return "Inactive";
    }
    return "Indisponible";
  }

  Future<void> _scanReservationQrCode(BuildContext context) async {
    try {
      final String? scannedValue = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => const QrScannerPage()),
      );
      if (!mounted) return;
      if (scannedValue != null && scannedValue.isNotEmpty) {
        context.read<TablesStatusCubit>().verifyReservationQR(scannedValue);
      } else if (scannedValue == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scan annulé ou aucun code QR détecté.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur scan: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: GestureDetector(
          onDoubleTap: () {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => LoginUi()));
          },
          child: FadedScaleAnimation(
            child: RichText(
              text: TextSpan(children: <TextSpan>[
                TextSpan(
                    text: 'USTHB',
                    style: theme.textTheme.titleMedium!.copyWith(
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color ?? Colors.white)),
                TextSpan(
                    text: ' Serveur-Chef',
                    style: theme.textTheme.titleMedium!.copyWith(
                        color: theme.primaryColor,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: "Scanner QR Réservation",
            onPressed: () => _scanReservationQrCode(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Rafraîchir",
            onPressed: () {
              context.read<TablesStatusCubit>().refreshTables();
            },
          ),
        ],
      ),
      body: BlocConsumer<TablesStatusCubit, TablesStatusState>(
        listener: (context, state) {
          if (state is ReservationValidated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Réservation pour ${state.reservation.customerName} validée!'),
                backgroundColor: Colors.green.shade700,
              ),
            );
            NotifyKitchenDialog.show(context, state.reservation, state.associatedTable);
          } else if (state is ReservationValidationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Erreur Résa: ${state.errorMessage}"),
                backgroundColor: Colors.red.shade700,
              ),
            );
          } else if (state is KitchenNotificationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage),
                backgroundColor: Colors.green.shade700,
              ),
            );
          } else if (state is KitchenNotificationFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Erreur Cuisine: ${state.errorMessage}"),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
        },
        builder: (context, state) {
          final currentTables = state.tables; 

          if (state is TablesStatusError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 50),
                    const SizedBox(height: 10),
                    Text(
                      "Erreur: ${state.message}",
                      style: TextStyle(color: Colors.red.shade700, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text("Réessayer"),
                      onPressed: () => context.read<TablesStatusCubit>().refreshTables(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        textStyle: const TextStyle(fontSize: 16)
                      ),
                    )
                  ],
                ),
              )
            );
          }

          if (currentTables != null && currentTables.isNotEmpty) {
            // Si on a des tables, on les affiche, même si l'état est Loading (pour un refresh)
            return Container(
              color: theme.scaffoldBackgroundColor.withOpacity(0.5),
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: currentTables.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 5 : (MediaQuery.of(context).size.width > 900 ? 4 : (MediaQuery.of(context).size.width > 600 ? 3 : 2)),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.45,
                ),
                itemBuilder: (context, index) {
                  final table = currentTables[index];
                  final color = _getTableColor(table, context);
                  final timeOrStatusText = _getDurationOrStatusText(table);
                  final itemsText = _getItemsText(table);

                  return TableCardWidget(
                    table: table,
                    onTap: () => TableReservationsDialog.show(context, table),
                    durationOrStatusText: timeOrStatusText,
                    itemsText: itemsText,
                    tableColor: color,
                  );
                },
              ),
            );
          }
          
          // Si c'est un état de chargement et qu'il n'y a pas de tables à afficher
          if (state is TablesStatusLoading) { 
            return const Center(child: CircularProgressIndicator());
          }

          // Cas pour TablesStatusInitial ou si TablesStatusLoaded arrive avec une liste vide
          if (state is TablesStatusInitial || (state is TablesStatusLoaded && (currentTables == null || currentTables.isEmpty))) {
             return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.table_restaurant_outlined, size: 60, color: theme.hintColor),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune table active ou configurée.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(color: theme.hintColor),
                      ),
                    ],
                  ),
                ),
              );
          }
          
          return const Center(child: Text('Initialisation...'));
        },
      ),
    );
  }
}

