import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class QrScannerPage extends StatefulWidget {
  // Constructeur simplifié : pas de callback onScan, car on utilisera Navigator.pop
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  bool _permissionGranted = false;
  bool _isProcessing = false; // Pour éviter de multiples traitements du même scan

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (mounted) {
      setState(() {
        _permissionGranted = status.isGranted;
      });
    }
  }

  // Cette fonction est appelée lorsque le MobileScanner détecte un code
  void _onQRCodeDetected(BarcodeCapture capture) {
    if (_isProcessing) return; // Si un scan est déjà en cours de traitement, ignorer

    final List<Barcode> barcodes = capture.barcodes;
    String? scannedValue;

    if (barcodes.isNotEmpty) {
      // Prendre la valeur du premier code-barres détecté
      scannedValue = barcodes.first.rawValue;
    }

    if (scannedValue != null && scannedValue.isNotEmpty) {
      // S'assurer que la page est toujours affichée et montée
      if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
        setState(() {
          _isProcessing = true; // Marquer comme étant en traitement
        });
        debugPrint('QR Code Scanné (hungerz_ordering): $scannedValue');
        // Retourner la valeur scannée à la page précédente
        Navigator.pop(context, scannedValue);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionGranted) {
      // Afficher l'interface pour demander la permission si elle n'est pas accordée
      return Scaffold(
        appBar: AppBar(title: const Text('Scanner QR Code')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'La permission d\'utiliser la caméra est requise pour scanner les codes QR. Veuillez accorder la permission pour continuer.',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _requestCameraPermission,
                child: const Text('Accorder la permission Caméra'),
              ),
            ],
          ),
        ),
      );
    }

    // Si la permission est accordée, afficher le scanner
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner QR Code')),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _onQRCodeDetected, // Utiliser la fonction séparée
            errorBuilder: (context, error) {
              // Afficher un message d'erreur simple si la caméra échoue
              return Center(
                child: Text(
                  'Erreur Caméra: ${error.errorCode}', // error.errorCode est plus approprié
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
          // Optionnel : Ajouter une surcouche visuelle pour guider l'utilisateur
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.7, // 70% de la largeur de l'écran
              height: MediaQuery.of(context).size.width * 0.7, // Pour un carré
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.green.withOpacity(0.7), // Couleur de la bordure
                  width: 2, // Épaisseur de la bordure
                ),
                borderRadius: BorderRadius.circular(8), // Coins arrondis
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Pas besoin de disposer d'un contrôleur MobileScanner ici
    // s'il n'est pas explicitement créé et stocké dans l'état.
    // Le widget MobileScanner gère son cycle de vie interne.
    super.dispose();
  }
}
