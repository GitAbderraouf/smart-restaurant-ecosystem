// qr_scanner_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hungerz/services/socket_service.dart'; // UserAppSocketService
// import 'view_cart.dart'; // Suppression de l'import si plus utilisé directement ici

class QRScannerPage extends StatefulWidget {
  // Le callback onScan est conservé pour l'instant, mais son rôle pourrait être réévalué.
  // S'il n'est plus utilisé par BookingRow pour une logique critique, il pourrait être simplifié/supprimé.
  final void Function(String scannedValue, String userId) onScan;

  const QRScannerPage({Key? key, required this.onScan}) : super(key: key);

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  bool _permissionGranted = false;
  // SUPPRIMER : Les abonnements aux streams ne sont plus gérés ici
  // StreamSubscription? _sessionJoinedSubscription;
  // StreamSubscription? _socketErrorSubscription;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();

    // SUPPRIMER : La logique d'écoute des événements socketService.onSessionJoined
    // et socketService.onError est retirée d'ici.
    // TableSessionCubit sera le principal écouteur pour ces événements de session.
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (mounted) {
      setState(() {
        _permissionGranted = status.isGranted;
      });
    }
  }

  void _handleScannedCode(String scannedTableId) {
    print('QRScannerPage: Scanned Table ID: $scannedTableId. Initiating session via service.');
    
    // Appelle le service pour initier la session.
    // TableSessionCubit écoutera les événements résultants de ce service.
    UserAppSocketService().initiateTableSession(scannedTableId);

    // Vous pouvez toujours appeler widget.onScan si BookingRow a besoin d'être notifié
    // que le scan a été tenté, mais il ne devrait pas gérer la logique de session.
    // Le paramètre userId semble non pertinent ici si l'ID utilisateur est géré côté serveur ou service.
    // widget.onScan(scannedTableId, ""); // À réévaluer si widget.onScan est toujours nécessaire

    // IMPORTANT : Pas de navigation ni de SnackBar géré directement ici.
    // La QRScannerPage attendra d'être fermée (pop) par TableSessionCubit.
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionGranted) {
      return Scaffold(
        appBar: AppBar(title: Text('Scan QR Code')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'La permission d\'utiliser la caméra est requise pour scanner les codes QR. Veuillez accorder la permission pour continuer.',
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _requestCameraPermission,
                child: Text('Accorder la permission Caméra'),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text('Scan QR Code')),
      body: MobileScanner(
        onDetect: (capture) {
          final barcode = capture.barcodes.first;
          if (barcode.rawValue != null) {
            // S'assurer de ne traiter qu'un seul scan et que la page est toujours active
            if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
              _handleScannedCode(barcode.rawValue!);
            }
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    // SUPPRIMER : Annulation des abonnements, car ils n'existent plus ici.
    // _sessionJoinedSubscription?.cancel();
    // _socketErrorSubscription?.cancel();
    super.dispose();
  }
}