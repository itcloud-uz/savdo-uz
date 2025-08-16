import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:savdo_uz/main_screen.dart';

class FaceScanScreen extends StatefulWidget {
  const FaceScanScreen({super.key});

  @override
  State<FaceScanScreen> createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends State<FaceScanScreen> {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _isCameraInitialized = false;
  String _statusMessage = "Kamerani ishga tushirish...";
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() => _statusMessage = "Kamera topilmadi.");
        return;
      }
      // Old kamerani topishga harakat qilamiz, bo'lmasa birinchi kamerani olamiz.
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21, // Android uchun mos format
      );
      _faceDetector = FaceDetector(
          options:
              FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate));

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
        _statusMessage = "Iltimos, yuzingizni doira ichiga joylashtiring";
      });
      // Agar kamera ishga tushgan bo'lsa, imageStream'ni boshlaymiz
      _cameraController!.startImageStream(_processImage);
    } catch (e) {
      if (!mounted) return;
      setState(() =>
          _statusMessage = "Kamerani ishga tushirishda xatolik yuz berdi.");
    }
  }

  void _processImage(CameraImage image) async {
    if (_isProcessing || !mounted) return;
    setState(() => _isProcessing = true);

    try {
      // InputImage yaratish uchun CameraImage ma'lumotlarini o'zgartiramiz
      final InputImage inputImage = InputImage.fromBytes(
        bytes: image.planes.first.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation270deg,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );

      final List<Face> faces = await _faceDetector!.processImage(inputImage);

      if (faces.isNotEmpty && mounted) {
        await _cameraController?.stopImageStream();
        setState(() =>
            _statusMessage = "Yuz aniqlandi! Ma'lumotlar tekshirilmoqda...");

        // --- SIMULYATSIYA QISMI ---
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (context) => const MainScreen(userRole: 'Admin')),
          );
        }
      }
    } catch (e) {
      // Xatolikni console'da chop etish va foydalanuvchiga xabar berish
      debugPrint("Yuzni aniqlashda xatolik: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Yuzni Skanerlash")),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_isCameraInitialized &&
              _cameraController != null &&
              _cameraController!.value.isInitialized)
            CameraPreview(_cameraController!)
          else
            const Center(child: CircularProgressIndicator()),
          Center(
            child: Container(
              width: 280,
              height: 380,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(140),
                border: Border.all(
                    color: _statusMessage.contains("aniqlandi")
                        ? Colors.green
                        : Colors.white,
                    width: 4),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(_statusMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500)),
            ),
          )
        ],
      ),
    );
  }
}
