import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool _isScanCompleted = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _handleBarcodeDetection(BarcodeCapture capture) {
    if (!_isScanCompleted && capture.barcodes.isNotEmpty) {
      final String? code = capture.barcodes.first.rawValue;
      if (code != null) {
        setState(() {
          _isScanCompleted = true;
        });
        Navigator.pop(context, code);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shtrix-kodni skanerlang'),
        actions: [
          // 🔦 Chiroq (torch) tugmasi
          ValueListenableBuilder<TorchState>(
            valueListenable: _scannerController.torchState,
            builder: (context, state, child) {
              return IconButton(
                icon: Icon(
                  state == TorchState.on ? Icons.flash_on : Icons.flash_off,
                  color: state == TorchState.on ? Colors.yellow : Colors.grey,
                ),
                onPressed: () => _scannerController.toggleTorch(),
                tooltip: 'Chiroq',
              );
            },
          ),
          // 📷 Kamera almashtirish tugmasi
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _scannerController.switchCamera(),
            tooltip: 'Kamera',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleBarcodeDetection,
          ),
          // 📦 Skanner ramkasi
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 4),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
