import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with WidgetsBindingObserver {
  late final MobileScannerController _scannerController;

  bool _isScanCompleted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false, // Torch dastlab o‘chiq
      autoStart: true, // Ruxsat, on-start avtomatik yoqiladi
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final hasPerm = _scannerController.value.hasCameraPermission;
    if (!hasPerm) return;

    if (state == AppLifecycleState.resumed) {
      _scannerController.start();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _scannerController.stop();
    }
  }

  void _handleBarcodeDetection(BarcodeCapture capture) {
    if (!_isScanCompleted && capture.barcodes.isNotEmpty) {
      final String? code = capture.barcodes.first.rawValue;
      if (code != null) {
        setState(() => _isScanCompleted = true);
        Navigator.pop(context, code);
      }
    }
  }

  void _toggleTorch() {
    _scannerController.toggleTorch();
    setState(() {}); // Qiymatni yangilash uchun
  }

  @override
  Widget build(BuildContext context) {
    final torch = _scannerController.value.torchState;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shtrix‑kodi skanerlang'),
        actions: [
          IconButton(
            icon: Icon(
              torch == TorchState.on ? Icons.flash_on : Icons.flash_off,
              color: torch == TorchState.on ? Colors.yellow : Colors.grey,
            ),
            onPressed: _toggleTorch,
            tooltip: 'Chiroq',
          ),
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
