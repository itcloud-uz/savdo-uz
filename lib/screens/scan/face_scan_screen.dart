import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:savdo_uz/models/attendance_log_model.dart';
import 'package:savdo_uz/models/employee_model.dart';
import 'package:savdo_uz/services/face_recognition_service.dart';
import 'package:savdo_uz/services/firestore_service.dart';

class FaceScanScreen extends StatefulWidget {
  const FaceScanScreen({super.key});

  @override
  State<FaceScanScreen> createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends State<FaceScanScreen> {
  CameraController? _cameraController;
  late FaceRecognitionService _faceRecognitionService;
  late FirestoreService _firestoreService;

  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  String _message = "Yuzingizni kameraga yaqinlashtiring";

  @override
  void initState() {
    super.initState();
    _faceRecognitionService = context.read<FaceRecognitionService>();
    _firestoreService = context.read<FirestoreService>();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    // Odatda old kamera `cameras[1]` bo'ladi
    final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first);

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();

    // Yuzlarni tanib olish uchun oqimni boshlash
    _cameraController!.startImageStream((image) {
      if (!_isProcessing) {
        _processImage(image, frontCamera);
      }
    });

    if (mounted) {
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  Future<void> _processImage(
      CameraImage image, CameraDescription camera) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final recognizedEmployee =
          await _faceRecognitionService.predict(image, camera);

      if (recognizedEmployee != null) {
        // Agar xodim tanilsa, oqimni to'xtatamiz
        await _cameraController?.stopImageStream();

        final lastLog = await _firestoreService
            .getLastAttendanceLogForToday(recognizedEmployee.id!);
        final status =
            (lastLog == null || lastLog.status == 'ketdi') ? 'keldi' : 'ketdi';

        final newLog = AttendanceLog(
          employeeId: recognizedEmployee.id!,
          employeeName: recognizedEmployee.name,
          timestamp: DateTime.now(),
          status: status,
        );

        await _firestoreService.logAttendance(newLog);

        setState(() {
          _message =
              "${recognizedEmployee.name}, muvaffaqiyatli belgilandi (${status.toUpperCase()})!";
        });

        // 2 soniyadan keyin orqaga qaytish
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
      } else {
        setState(() {
          _message = "Yuzingizni kameraga yaqinlashtiring";
        });
      }
    } catch (e) {
      print("Yuzni tanishda xatolik: $e");
      setState(() {
        _message = "Xatolik yuz berdi";
      });
    } finally {
      // Qayta ishlashga ruxsat berish
      await Future.delayed(const Duration(milliseconds: 500)); // Kichik pauza
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Davomatni Skanerlash')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_cameraController!),
          // Yuz uchun ramka
          Center(
            child: Container(
              width: 250,
              height: 350,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          // Xabar ko'rsatish uchun
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
