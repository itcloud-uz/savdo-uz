import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:savdo_uz/main_screen.dart';
import 'package:savdo_uz/face_recognition_service.dart';
// import 'package:flutter/foundation.dart'; // <-- KERAKSIZ IMPORT OLIB TASHLANDI

class FaceScanScreen extends StatefulWidget {
  const FaceScanScreen({super.key});

  @override
  State<FaceScanScreen> createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends State<FaceScanScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  String _statusMessage = "Kamerani ishga tushirish...";
  bool _isProcessing = false;

  final FaceRecognitionService _faceRecognitionService =
      FaceRecognitionService();
  final List<Map<String, dynamic>> _knownUsers = [];
  bool _areUsersLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadKnownUsersAndInitializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _faceRecognitionService.dispose();
    super.dispose();
  }

  Future<void> _loadKnownUsersAndInitializeCamera() async {
    await _loadKnownUsers();
    await _initializeCamera();
  }

  Future<void> _loadKnownUsers() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('faceEmbedding') &&
            data['faceEmbedding'] != null) {
          final embedding = (data['faceEmbedding'] as List<dynamic>)
              .map((e) => e as double)
              .toList();

          _knownUsers.add({
            "fullName": data['fullName'],
            "role": data['role'],
            "embedding": embedding,
          });
        }
      }
      setState(() {
        _areUsersLoaded = true;
        _statusMessage = _knownUsers.isEmpty
            ? "Tizimda yuz izi saqlangan xodimlar topilmadi"
            : "Iltimos, yuzingizni doira ichiga joylashtiring";
      });
    } catch (e) {
      debugPrint("Xodimlarni yuklashda xatolik: $e");
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

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() => _isCameraInitialized = true);

      if (_areUsersLoaded && _knownUsers.isNotEmpty) {
        _cameraController!.startImageStream(_processImage);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMessage = "Kamerani ishga tushirishda xatolik.");
    }
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

  void _processImage(CameraImage image) async {
    if (_isProcessing || !_areUsersLoaded || !mounted) return;

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
          setState(() => _statusMessage = "${bestMatch['fullName']} tanildi!");

          await Future.delayed(const Duration(seconds: 2));

          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                  builder: (context) =>
                      MainScreen(userRole: bestMatch['role'])),
            );
          }
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

  Map<String, dynamic>? _findBestMatch(List detectedEmbedding) {
    double minDistance = double.infinity;
    Map<String, dynamic>? bestMatch;

    for (var user in _knownUsers) {
      final double distance =
          _calculateDistance(user['embedding'], detectedEmbedding);
      if (distance < minDistance) {
        minDistance = distance;
        bestMatch = user;
      }
    }

    if (minDistance < 1.0) {
      // Aniqlik darajasi
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
      appBar: AppBar(title: const Text("Yuzni Skanerlash orqali kirish")),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_isCameraInitialized && _cameraController!.value.isInitialized)
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
                    color: _statusMessage.contains("tanildi")
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
                  color: const Color.fromRGBO(0, 0, 0, 0.7),
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
