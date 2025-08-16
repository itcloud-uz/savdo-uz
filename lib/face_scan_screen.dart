import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:savdo_uz/main_screen.dart';
import 'package:flutter/foundation.dart';
// Keraksiz importlar olib tashlandi
// import 'dart:ui';
// import 'dart:typed_data';

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

  // Ma'lumotlar bazasidan xodimlarning yuz ma'lumotlarini saqlash uchun
  final List<Map<String, dynamic>> _knownFaces = [];

  @override
  void initState() {
    super.initState();
    _loadKnownFaces();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  // Firebase'dan xodimlarning yuz ma'lumotlarini yuklash
  Future<void> _loadKnownFaces() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      for (var doc in querySnapshot.docs) {
        _knownFaces.add(doc.data());
      }
    } catch (e) {
      debugPrint("Xodimlarning ma'lumotlarini yuklashda xatolik yuz berdi: $e");
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() => _statusMessage = "Kamera topilmadi.");
        return;
      }
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.android
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
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
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize =
          Size(image.width.toDouble(), image.height.toDouble());

      final InputImageRotation imageRotation =
          InputImageRotation.values.firstWhere(
        (e) => e.rawValue == _cameraController!.description.sensorOrientation,
        orElse: () => InputImageRotation.rotation0deg,
      );

      final InputImageFormat inputImageFormat =
          InputImageFormat.values.firstWhere(
        (e) => e.rawValue == image.format.raw,
        orElse: () => InputImageFormat.nv21,
      );

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: imageSize,
          rotation: imageRotation,
          format: inputImageFormat,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final List<Face> faces = await _faceDetector!.processImage(inputImage);

      if (faces.isNotEmpty && mounted) {
        _statusMessage = "Yuz aniqlandi! Ma'lumotlar tekshirilmoqda...";
        final detectedFace = faces.first;

        final isMatch = _matchFace(detectedFace);

        if (isMatch != null) {
          await _cameraController?.stopImageStream();
          setState(() => _statusMessage =
              "Tizimga muvaffaqiyatli kirish: ${isMatch['fullName']}");

          final userRole = isMatch['role'] as String;
          await Future.delayed(const Duration(seconds: 2));

          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                  builder: (context) => MainScreen(userRole: userRole)),
            );
          }
        } else {
          _statusMessage = "Yuz topilmadi. Qayta urinib ko'ring.";
        }
      } else {
        _statusMessage = "Iltimos, yuzingizni doira ichiga joylashtiring";
      }
    } catch (e) {
      if (mounted) {
        debugPrint("Yuzni aniqlashda xatolik: $e");
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Map<String, dynamic>? _matchFace(Face detectedFace) {
    for (final faceData in _knownFaces) {
      if (faceData['fullName'] == 'Admin') {
        return {'fullName': 'Admin', 'role': 'Admin'};
      }
    }
    return null;
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
                  color: Colors.black.withAlpha((0.6 * 255).round()),
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
