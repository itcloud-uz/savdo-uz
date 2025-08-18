import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:savdo_uz/face_recognition_service.dart';
import 'package:savdo_uz/services/firestore_service.dart';

class FaceScanScreen extends StatefulWidget {
  const FaceScanScreen({super.key});

  @override
  State<FaceScanScreen> createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends State<FaceScanScreen> {
  final FaceRecognitionService _faceRecognitionService =
      FaceRecognitionService();
  final FirestoreService _firestoreService = FirestoreService();

  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  String _statusMessage = "Xodimlarni yuklash...";
  bool _isProcessing = false;
  bool _faceRecognized = false;

  final List<Map<String, dynamic>> _knownEmployees = [];
  bool _areEmployeesLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadKnownEmployeesAndInitializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _loadKnownEmployeesAndInitializeCamera() async {
    await _loadKnownEmployees();
    await _initializeCamera();
  }

  Future<void> _loadKnownEmployees() async {
    try {
      final employeeDocs = await _firestoreService.getEmployeeFaceData();
      for (var doc in employeeDocs) {
        final data = doc.data() as Map<String, dynamic>;
        final embedding =
            (data['faceEmbedding'] as List<dynamic>).cast<double>().toList();
        _knownEmployees.add(
            {"id": doc.id, "name": data['fullName'], "embedding": embedding});
      }
      if (mounted) {
        setState(() {
          _areEmployeesLoaded = true;
          _statusMessage = _knownEmployees.isEmpty
              ? "Tizimda yuz izi saqlangan xodimlar topilmadi"
              : "Iltimos, yuzingizni doira ichiga joylashtiring";
        });
      }
    } catch (e) {
      if (mounted)
        setState(() => _statusMessage = "Xodimlarni yuklashda xatolik");
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _cameraController = CameraController(frontCamera, ResolutionPreset.medium,
          enableAudio: false, imageFormatGroup: ImageFormatGroup.nv21);
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() => _isCameraInitialized = true);
      if (_areEmployeesLoaded && _knownEmployees.isNotEmpty) {
        _cameraController!.startImageStream(_processImage);
      }
    } catch (e) {
      if (mounted)
        setState(() => _statusMessage = "Kamerani ishga tushirishda xatolik.");
    }
  }

  Future<void> _processImage(CameraImage image) async {
    if (_isProcessing || !mounted) return;
    setState(() => _isProcessing = true);

    try {
      final rotation = _rotationIntToImageRotation(
          _cameraController!.description.sensorOrientation);
      final embedding = await _faceRecognitionService
          .processCameraImageForEmbedding(image, rotation);

      if (embedding != null && mounted) {
        final bestMatch = _findBestMatch(embedding);
        if (bestMatch != null) {
          await _cameraController?.stopImageStream();
          final employeeName = bestMatch['name'];
          final employeeId = bestMatch['id'];
          final lastLog =
              await _firestoreService.getLastAttendanceLogForToday(employeeId);
          String newStatus = 'clock_in';
          String statusMessage = "Xush kelibsiz, $employeeName!";

          if (lastLog != null && lastLog.exists) {
            if ((lastLog.data() as Map<String, dynamic>)['status'] ==
                'clock_in') {
              newStatus = 'clock_out';
              statusMessage = "Xayr, $employeeName! Yaxshi boring.";
            }
          }

          await _firestoreService.logAttendance(
              employeeId, employeeName, newStatus);
          setState(() {
            _faceRecognized = true;
            _statusMessage = statusMessage;
          });
          await Future.delayed(const Duration(seconds: 3));
          if (mounted) Navigator.of(context).pop();
        } else {
          // Bu qism yuz tanilmaganda ishlaydi, xabarni o'zgartirmaymiz
          // _statusMessage = "Yuz tanilmadi. Qaytadan urining.";
        }
      }
    } catch (e) {
      debugPrint("Yuzni tahlil qilishda xatolik: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Map<String, dynamic>? _findBestMatch(List detectedEmbedding) {
    double minDistance = 1.0;
    Map<String, dynamic>? bestMatch;
    for (var employee in _knownEmployees) {
      final double distance =
          _calculateDistance(employee['embedding'], detectedEmbedding);
      if (distance < minDistance) {
        minDistance = distance;
        bestMatch = employee;
      }
    }
    return bestMatch;
  }

  double _calculateDistance(List emb1, List emb2) {
    double distance = 0;
    for (int i = 0; i < emb1.length; i++) {
      distance += pow(emb1[i] - emb2[i], 2);
    }
    return sqrt(distance);
  }

  InputImageRotation _rotationIntToImageRotation(int rotation) {
    switch (rotation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Yuzni Skanerlash")),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _isCameraInitialized
              ? CameraPreview(_cameraController!)
              : const Center(child: CircularProgressIndicator()),
          Container(
              decoration: ShapeDecoration(
                  shape: _FaceOverlayShape(
                      cutoutRadius: 140,
                      color: _faceRecognized
                          ? Colors.green.withOpacity(0.5)
                          : Colors.black.withOpacity(0.5)))),
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: _faceRecognized
                      ? Colors.green
                      : Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(_statusMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaceOverlayShape extends ShapeBorder {
  final double cutoutRadius;
  final Color color;
  _FaceOverlayShape({required this.cutoutRadius, required this.color});

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path.combine(
      PathOperation.difference,
      Path()..addRect(rect),
      Path()
        ..addOval(Rect.fromCircle(
            center: rect.center.translate(0, -40), radius: cutoutRadius)),
    );
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final paint = Paint()..color = color;
    canvas.drawPath(getOuterPath(rect), paint);
  }

  @override
  ShapeBorder scale(double t) => this;
}
