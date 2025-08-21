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
    // Provider orqali servislarni olish
    _faceRecognitionService = context.read<FaceRecognitionService>();
    _firestoreService = context.read<FirestoreService>();
    _initializeCamera();
  }

  /// Kamerani initsializatsiya qilish va oqimni boshlash
  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      // Windows va boshqa platformalarda image streamingni try/catch bilan boshlash
      try {
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
      } catch (e) {
        if (mounted) {
          setState(() {
            _message = "Bu kamera image streamingni qo‘llab-quvvatlamaydi.";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = "Kamerani ishga tushirib bo'lmadi.";
        });
        debugPrint("Kamera initsializatsiyasida xatolik: $e");
      }
    }
  }

  /// Kamera oqimidagi kadrni qayta ishlash
  Future<void> _processImage(
      CameraImage image, CameraDescription camera) async {
    if (!mounted) return;

    setState(() {
      _isProcessing = true;
    });

    final navigator = Navigator.of(context);

    try {
      final Employee? recognizedEmployee =
          await _faceRecognitionService.predict(image, camera);

      if (recognizedEmployee != null) {
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

        if (!mounted) return;
        setState(() {
          _message =
              "${recognizedEmployee.name}, muvaffaqiyatli belgilandi (${status.toUpperCase()})!";
        });

        await Future.delayed(const Duration(seconds: 2));
        if (mounted) navigator.pop();
      } else {
        if (mounted) {
          setState(() {
            _message = "Yuzingizni kameraga yaqinlashtiring";
          });
        }
      }
    } catch (e) {
      debugPrint("Yuzni tanishda xatolik: $e");
      if (mounted) {
        setState(() {
          _message = "Xatolik yuz berdi";
        });
      }
    } finally {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Davomatni Skanerlash')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(_message),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Davomatni Skanerlash')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_cameraController!),
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
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54,
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
