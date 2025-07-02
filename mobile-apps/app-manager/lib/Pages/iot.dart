import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hungerz_store/Themes/colors.dart'; // Assurez-vous que ce chemin est correct pour vos couleurs
// Si vous n'avez pas kMainColor, etc., vous pouvez les remplacer par Theme.of(context).primaryColor, etc.
import 'package:hungerz_store/cubits/appliance_status_cubit/appliance_status_cubit.dart'; // Ajustez le chemin si nécessaire
import 'package:hungerz_store/services/manager_socket_service.dart'; // Pour FridgeStatusData, OvenStatusData
import 'package:flutter_animate/flutter_animate.dart';
// import 'package:intl/intl.dart'; // Si vous avez besoin de formater des timestamps pour les données d'appareils

class ApplianceStatusPage extends StatelessWidget {
  const ApplianceStatusPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Le Cubit ApplianceStatusCubit est supposé être fourni plus haut dans l'arbre des widgets,
    // par exemple dans votre main.dart ou un widget de navigation principal.
    // Si ce n'est pas le cas, vous devriez l'envelopper dans un BlocProvider ici :
    // return BlocProvider(
    //   create: (context) => ApplianceStatusCubit(context.read<ManagerSocketService>()), // Assurez-vous que ManagerSocketService est accessible
    //   child: _ApplianceStatusView(),
    // );
    return _ApplianceStatusView();
  }
}

class _ApplianceStatusView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Fallback colors si k-variables ne sont pas définies dans Themes/colors.dart
    const Color kMainColorFallback = Colors.deepPurple; // Exemple
    const Color kTextColorFallback = Colors.black87;
    const Color kLightTextColorFallback = Colors.black54;

    final Color mainColor = kMainColor ?? kMainColorFallback;
    // final Color textColor = kTextColor ?? kTextColorFallback; // Utilisé via theme.textTheme
    // final Color lightTextColor = kLightTextColor ?? kLightTextColorFallback; // Utilisé via theme.textTheme

    return Scaffold(
      appBar: AppBar(
        title: Text('État des Équipements',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 1, // Légère élévation pour la démarcation
      ),
      body: BlocBuilder<ApplianceStatusCubit, ApplianceStatusState>(
        builder: (context, state) {
          if (state is ApplianceStatusInitial) {
            // Si vous avez une méthode fetchInitialApplianceStatuses dans le cubit, appelez-la ici ou dans initState du parent.
            // ex: context.read<ApplianceStatusCubit>().fetchInitialApplianceStatuses();
            return Center(
                child: Text("Initialisation...",
                    style: theme.textTheme.bodyMedium));
          } else if (state is ApplianceStatusLoading) {
            return Center(
                child: CircularProgressIndicator(color: mainColor));
          } else if (state is ApplianceStatusLoaded) {
            if (state.fridgeStatus == null && state.ovenStatus == null) {
              return _buildEmptyState(context, mainColor);
            }
            return RefreshIndicator(
              onRefresh: () async {
                // Optionnel: si vous avez une méthode pour rafraîchir manuellement via API
                // await context.read<ApplianceStatusCubit>().fetchInitialApplianceStatuses();
                // Pour l'instant, les mises à jour viennent des sockets.
              },
              color: mainColor,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  if (state.fridgeStatus != null)
                    FridgeStatusCard(
                            fridgeData: state.fridgeStatus!,
                            mainColor: mainColor)
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideY(
                            begin: 0.2,
                            end: 0,
                            curve: Curves.easeOutCubic),
                  if (state.fridgeStatus == null)
                    _buildWaitingCard(context, "Réfrigérateur",
                        "En attente de données...", mainColor),
                  const SizedBox(height: 20),
                  if (state.ovenStatus != null)
                    OvenStatusCard(
                            ovenData: state.ovenStatus!, mainColor: mainColor)
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 150.ms)
                        .slideY(
                            begin: 0.2,
                            end: 0,
                            curve: Curves.easeOutCubic),
                  if (state.ovenStatus == null)
                    _buildWaitingCard(
                        context, "Four", "En attente de données...", mainColor),
                ],
              ),
            );
          } else if (state is ApplianceStatusError) {
            return Center(
                child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("Erreur de chargement: ${state.message}",
                  style: TextStyle(color: Colors.red.shade700), textAlign: TextAlign.center,),
            ));
          }
          return Center(
              child: Text("Aucune donnée d'équipement disponible.",
                  style: theme.textTheme.bodyMedium));
        },
      ),
    );
  }

  Widget _buildWaitingCard(
      BuildContext context, String title, String message, Color mainColor) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
            const SizedBox(height: 16),
            CircularProgressIndicator(
                strokeWidth: 2.5,
                color: mainColor.withOpacity(0.7)),
            const SizedBox(height: 16),
            Text(message, style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color)),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildEmptyState(BuildContext context, Color mainColor) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.thermostat_auto_outlined, size: 80, color: (kLightTextColor ?? Colors.grey.shade400)),
            const SizedBox(height: 20),
            Text(
              'Aucun équipement connecté',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Les données de statut du réfrigérateur et du four apparaîtront ici lorsqu\'ils seront actifs et enverront des informations.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 30),
            // Optionnel: Bouton pour tenter un rafraîchissement manuel
            // ElevatedButton.icon(
            //   icon: Icon(Icons.refresh_rounded, color: Colors.white),
            //   label: Text('Rafraîchir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: mainColor,
            //     padding: EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            //   ),
            //   onPressed: () {
            //      // context.read<ApplianceStatusCubit>().fetchInitialApplianceStatuses();
            //   },
            // )
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms);
  }
}

// --- Carte pour le Réfrigérateur ---
class FridgeStatusCard extends StatelessWidget {
  final FridgeStatusData fridgeData;
  final Color mainColor; // Pass mainColor for consistency

  const FridgeStatusCard(
      {Key? key, required this.fridgeData, required this.mainColor})
      : super(key: key);

  IconData _getFridgeStatusIcon(String status) {
    status = status.toLowerCase();
    if (status.contains('door_open')) return Icons.door_front_door_outlined;
    if (status.contains('error') || status.contains('fault')) return Icons.error_outline_rounded;
    if (status.contains('cooling')) return Icons.ac_unit_rounded;
    if (status.contains('idle') || status.contains('stable')) return Icons.thermostat_rounded;
    return Icons.check_circle_outline_rounded;
  }

  Color _getFridgeStatusColor(String status, BuildContext context) {
    status = status.toLowerCase();
    if (status.contains('door_open')) return Colors.orange.shade700;
    if (status.contains('error') || status.contains('fault')) return Colors.red.shade700;
    if (status.contains('cooling')) return Colors.blue.shade600;
    return Colors.green.shade600;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusIcon = _getFridgeStatusIcon(fridgeData.status);
    final statusColor = _getFridgeStatusColor(fridgeData.status, context);

    // Tolérance de température (ex: +/- 2°C)
    bool isTempOk = (fridgeData.currentTemperature - fridgeData.targetTemperature).abs() <= 2.0;

    return Card(
      elevation: 4,
      shadowColor: Colors.grey.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.kitchen_rounded, size: 32, color: mainColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Réfrigérateur", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                      if (fridgeData.deviceId.isNotEmpty)
                        Text(fridgeData.deviceId, style: theme.textTheme.bodySmall?.copyWith(color: kLightTextColor ?? Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
            Divider(height: 28, thickness: 0.8, color: Colors.grey.shade300),
            _buildInfoRow(context, "Statut:", fridgeData.status.replaceAll('_', ' ').capitalizeFirstLetter(),
                icon: statusIcon, iconColor: statusColor, valueColor: statusColor, isStatus: true),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTemperatureDisplay("Actuelle", fridgeData.currentTemperature, isOk: isTempOk, theme: theme, alertColor: Colors.orange.shade700),
                _buildTemperatureDisplay("Cible", fridgeData.targetTemperature, theme: theme),
              ],
            ),
            // Vous pouvez ajouter un timestamp ici si fridgeData l'inclut
            // SizedBox(height: 10),
            // Text("Dernière MàJ: ${DateFormat('HH:mm:ss').format(fridgeData.timestamp)}", style: theme.textTheme.caption),
          ],
        ),
      ),
    );
  }
}

// --- Carte pour le Four ---
class OvenStatusCard extends StatelessWidget {
  final OvenStatusData ovenData;
  final Color mainColor;

  const OvenStatusCard(
      {Key? key, required this.ovenData, required this.mainColor})
      : super(key: key);

  String _formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) return "N/A";
    final duration = Duration(seconds: totalSeconds);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      final hours = twoDigits(duration.inHours);
      return "$hours:$minutes:$seconds";
    }
    return "$minutes:$seconds";
  }

  IconData _getOvenStatusIcon(String status) {
    status = status.toLowerCase();
    if (status.contains('error') || status.contains('fault')) return Icons.error_outline_rounded;
    if (status.contains('preheating')) return Icons.timer_outlined;
    if (status.contains('baking') || status.contains('cooking') || status.contains('heating')) return Icons.outdoor_grill_outlined; // ou Icons.restaurant_menu
    if (status.contains('ready') || status.contains('completed') || status.contains('idle')) return Icons.check_circle_outline_rounded;
    if (status.contains('off')) return Icons.power_settings_new_rounded;
    return Icons.thermostat_auto_outlined;
  }

  Color _getOvenStatusColor(String status, BuildContext context) {
     status = status.toLowerCase();
    if (status.contains('error') || status.contains('fault')) return Colors.red.shade700;
    if (status.contains('preheating')) return Colors.orange.shade700;
    if (status.contains('baking') || status.contains('cooking') || status.contains('heating')) return Colors.blue.shade600;
    if (status.contains('off')) return kLightTextColor ?? Colors.grey.shade600;
    return Colors.green.shade600;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusIcon = _getOvenStatusIcon(ovenData.status);
    final statusColor = _getOvenStatusColor(ovenData.status, context);
    bool isTempOk = (ovenData.currentTemperature - ovenData.targetTemperature).abs() <= 10.0; // Tolérance plus grande pour le four

    return Card(
      elevation: 4,
      shadowColor: Colors.grey.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.outdoor_grill_outlined, size: 32, color: mainColor),
                const SizedBox(width: 12),
                 Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Four", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                      if (ovenData.deviceId.isNotEmpty)
                        Text(ovenData.deviceId, style: theme.textTheme.bodySmall?.copyWith(color: kLightTextColor ?? Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
            Divider(height: 28, thickness: 0.8, color: Colors.grey.shade300),
            _buildInfoRow(context, "Statut:", ovenData.status.replaceAll('_', ' ').capitalizeFirstLetter(),
                icon: statusIcon, iconColor: statusColor, valueColor: statusColor, isStatus: true),
            const SizedBox(height: 8),
            _buildInfoRow(context, "Mode:", ovenData.mode.capitalizeFirstLetter(), icon: Icons.settings_ethernet_rounded),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTemperatureDisplay("Actuelle", ovenData.currentTemperature, isOk: isTempOk, theme: theme, alertColor: Colors.orange.shade700),
                _buildTemperatureDisplay("Cible", ovenData.targetTemperature, theme: theme),
              ],
            ),
            if (ovenData.remainingTimeSeconds > 0 &&
                (ovenData.status.toLowerCase().contains('baking') ||
                    ovenData.status.toLowerCase().contains('cooking') ||
                    ovenData.status.toLowerCase().contains('heating')))
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: _buildInfoRow(
                    context, "Temps Restant:", _formatDuration(ovenData.remainingTimeSeconds),
                    icon: Icons.hourglass_bottom_rounded, iconColor: Colors.blue.shade700),
              ),
          ],
        ),
      ),
    );
  }
}

// Widget utilitaire pour les lignes d'information
Widget _buildInfoRow(BuildContext context, String label, String value,
    {IconData? icon, Color? iconColor, Color? valueColor, bool isStatus = false}) {
  final theme = Theme.of(context);
  // Fallback colors
  final Color defaultIconColor = kMainColor ?? Theme.of(context).primaryColor;
  final Color defaultLabelColor = kLightTextColor ?? Colors.grey.shade600;
  final Color defaultValueColor = kTextColor ?? theme.textTheme.bodyLarge?.color ?? Colors.black;


  return Row(
    crossAxisAlignment: isStatus ? CrossAxisAlignment.center : CrossAxisAlignment.start,
    children: [
      if (icon != null) ...[
        Icon(icon, size: isStatus ? 22 : 20, color: iconColor ?? defaultIconColor),
        const SizedBox(width: 10),
      ],
      Container(
        constraints: BoxConstraints(minWidth: 90), // Pour aligner les valeurs
        child: Text(
          label,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: defaultLabelColor, fontWeight: FontWeight.w500),
        ),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isStatus ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? defaultValueColor,
              fontSize: isStatus ? 16 : 15,
              ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

// Widget utilitaire pour afficher la température (similaire à celui de l'artefact)
Widget _buildTemperatureDisplay(String label, double temp, {bool? isOk, required ThemeData theme, Color? alertColor}) {
  Color defaultTextColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
  Color lightTextColor = theme.textTheme.bodyMedium?.color ?? Colors.grey.shade600;
  
  Color tempColor = defaultTextColor;
  if (isOk != null) {
    tempColor = isOk ? Colors.green.shade700 : (alertColor ?? Colors.orange.shade700);
  }

  return Column(
    children: [
      Text(label, style: theme.textTheme.labelLarge?.copyWith(color: lightTextColor)), // labelLarge pour un peu plus de proéminence
      const SizedBox(height: 6),
      Text(
        "${temp.toStringAsFixed(1)}°C",
        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: tempColor),
      ),
    ],
  );
}

// Extension pour capitaliser la première lettre (utile pour les statuts/modes)
extension StringExtension on String {
  String capitalizeFirstLetter() {
    if (this.isEmpty) return "";
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}
