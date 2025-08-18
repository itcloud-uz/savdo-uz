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
  final FirestoreService _firestoreService =
      FirestoreService(); // Servisdan nusxa olamiz

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
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _faceRecognitionService.dispose();
    super.dispose();
  }

  Future<void> _loadKnownEmployeesAndInitializeCamera() async {
    await _loadKnownEmployees();
    await _initializeCamera();
  }

  /// FirestoreService yordamida yuz izi saqlangan xodimlarni yuklaydi
  Future<void> _loadKnownEmployees() async {
    try {
      // Barcha amallar endi servis orqali
      final employeeDocs = await _firestoreService.getEmployeeFaceData();

      for (var doc in employeeDocs) {
        final data = doc.data() as Map<String, dynamic>;
        final embedding =
            (data['faceEmbedding'] as List<dynamic>).cast<double>().toList();
        _knownEmployees.add({
          "id": doc.id, // Davomatni belgilash uchun ID kerak
          "name": data['fullName'],
          "embedding": embedding,
        });
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

  /// Kamerani ishga tushiradi
  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(frontCamera, ResolutionPreset.medium,
          enableAudio: false);
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

  /// Kameradan kelayotgan har bir kadrni qayta ishlaydi
  Future<void> _processImage(CameraImage image) async {
    if (_isProcessing || !_areEmployeesLoaded || !mounted) return;
    setState(() => _isProcessing = true);

    try {
      final embedding =
          await _faceRecognitionService.processCameraImageForEmbedding(image);

      if (embedding != null && mounted) {
        final bestMatch = _findBestMatch(embedding);

        if (bestMatch != null) {
          await _cameraController?.stopImageStream();
          final employeeName = bestMatch['name'];
          final employeeId = bestMatch['id'];

          // Xodimning oxirgi harakatini tekshiramiz
          final lastLog =
              await _firestoreService.getLastAttendanceLogForToday(employeeId);
          String newStatus = 'clock_in'; // Standart holat - ishga keldi
          String statusMessage = "Xush kelibsiz, $employeeName!";

          if (lastLog != null && lastLog.exists) {
            final lastStatus =
                (lastLog.data() as Map<String, dynamic>)['status'];
            if (lastStatus == 'clock_in') {
              newStatus =
                  'clock_out'; // Agar oxirgi harakat "keldi" bo'lsa, endi "ketdi" bo'ladi
              statusMessage = "Xayr, $employeeName! Yaxshi boring.";
            }
          }

          // Davomatni bazaga yozamiz
          await _firestoreService.logAttendance(
              employeeId, employeeName, newStatus);

          setState(() {
            _faceRecognized = true;
            _statusMessage = statusMessage;
          });

          await Future.delayed(const Duration(seconds: 3));
          if (mounted) Navigator.of(context).pop();
        } else {
          _statusMessage = "Yuz tanilmadi. Qaytadan urining.";
        }
      }
    } catch (e) {
      debugPrint("Yuzni tahlil qilishda xatolik: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// Yuz izlarini solishtirish
  Map<String, dynamic>? _findBestMatch(List detectedEmbedding) {
    double minDistance = double.infinity;
    Map<String, dynamic>? bestMatch;

    for (var employee in _knownEmployees) {
      final double distance =
          _calculateDistance(employee['embedding'], detectedEmbedding);
      if (distance < minDistance) {
        minDistance = distance;
        bestMatch = employee;
      }
    }
    // Agar masofa 1.0 dan kichik bo'lsa, bu o'sha odam deb hisoblaymiz (bu qiymatni o'zgartirish mumkin)
    if (minDistance < 1.0) {
      return bestMatch;
    }
    return null;
  }

  double _calculateDistance(List emb1, List emb2) {
    double distance = 0;
    for (int i = 0; i < emb1.length; i++) {
      distance += pow(emb1[i] - emb2[i], 2);
    }
    return sqrt(distance);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Yuzni Skanerlash")),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_isCameraInitialized && _cameraController!.value.isInitialized)
            CameraPreview(_cameraController!)
          else
            const Center(child: CircularProgressIndicator()),
          _buildFaceOverlay(),
          _buildStatusMessage(),
        ],
      ),
    );
  }

  Widget _buildFaceOverlay() {
    return Center(
      child: Container(
        width: 280,
        height: 380,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: _faceRecognized ? Colors.green : Colors.white, width: 4),
        ),
      ),
    );
  }

  Widget _buildStatusMessage() {
    return Positioned(
      bottom: 50,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(8)),
        child: Text(_statusMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500)),
      ),
    );
  }
}
