import 'dart:typed_data';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'package:savdo_uz/models/employee_model.dart';
import 'package:savdo_uz/services/firestore_service.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class FaceRecognitionService {
  late Interpreter _interpreter;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      enableContours: false,
      enableClassification: false,
    ),
  );

  final FirestoreService _firestoreService;
  // Xotirada saqlanadigan xodimlar ro'yxati
  Map<String, Employee> _registeredEmployees = {};

  FaceRecognitionService(BuildContext context)
      : _firestoreService = context.read<FirestoreService>() {
    _loadModel();
    _loadRegisteredFaces();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter =
          await Interpreter.fromAsset('assets/ml/mobile_face_net.tflite');
      print("FaceNet modeli muvaffaqiyatli yuklandi.");
    } catch (e) {
      print("Modelni yuklashda xatolik: $e");
    }
  }

  // Firestore'dan barcha yuz ma'lumotlarini yuklab olish
  Future<void> _loadRegisteredFaces() async {
    final employees = await _firestoreService.getEmployeesWithFaceData();
    _registeredEmployees = {for (var e in employees) e.id!: e};
    print(
        "${_registeredEmployees.length} ta xodimning yuz ma'lumoti yuklandi.");
  }

  // Rasm faylidan (masalan, xodim qo'shishda) embedding olish
  Future<List<double>?> getEmbeddingFromImageFile(XFile imageFile) async {
    final inputImage = InputImage.fromFilePath(imageFile.path);
    final faces = await _faceDetector.processImage(inputImage);

    if (faces.isEmpty) {
      print("Rasmdan yuz topilmadi.");
      return null;
    }

    final fileBytes = await imageFile.readAsBytes();
    final image = img.decodeImage(fileBytes);
    if (image == null) return null;

    final croppedFace = _cropFace(image, faces[0].boundingBox);
    return _getEmbedding(croppedFace);
  }

  // Kameradan kelgan tasvirdan eng o'xshash xodimni topish
  Future<Employee?> predict(
      CameraImage cameraImage, CameraDescription camera) async {
    if (_isProcessing) return null;
    _isProcessing = true;

    try {
      final inputImage =
          _inputImageFromCameraImage(cameraImage, camera.sensorOrientation);
      if (inputImage == null) return null;

      final List<Face> faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) return null;

      final image = _convertCameraImage(cameraImage);
      if (image == null) return null;

      final face = faces[0];
      final croppedFace = _cropFace(image, face.boundingBox);

      final currentEmbedding = _getEmbedding(croppedFace);

      return _compareEmbeddings(currentEmbedding);
    } finally {
      _isProcessing = false;
    }
  }

  bool _isProcessing = false;

  // Yuzni qirqib olish
  img.Image _cropFace(img.Image image, Rect boundingBox) {
    return img.copyCrop(
      image,
      x: boundingBox.left.toInt(),
      y: boundingBox.top.toInt(),
      width: boundingBox.width.toInt(),
      height: boundingBox.height.toInt(),
    );
  }

  // Qirqilgan yuzdan embedding (192 o'lchamli vektor) olish
  List<double> _getEmbedding(img.Image croppedFace) {
    final resizedFace = img.copyResize(croppedFace, width: 112, height: 112);
    final imageMatrix = _imageToByteListFloat32(resizedFace);

    final input = [
      imageMatrix.reshape([1, 112, 112, 3])
    ];
    final output = List.filled(1 * 192, 0.0).reshape([1, 192]);

    _interpreter.run(input, output);
    return List<double>.from(output[0]);
  }

  // Joriy embedding'ni xotiradagi barcha embedding'lar bilan solishtirish
  Employee? _compareEmbeddings(List<double> currentEmbedding) {
    double minDistance = double.infinity;
    Employee? bestMatch;

    for (var employee in _registeredEmployees.values) {
      if (employee.faceEmbedding != null &&
          employee.faceEmbedding!.isNotEmpty) {
        final distance =
            _euclideanDistance(employee.faceEmbedding!, currentEmbedding);
        // O'xshashlik chegarasi (bu qiymatni o'zgartirib, aniqlikni sozlash mumkin)
        if (distance < 1.0 && distance < minDistance) {
          minDistance = distance;
          bestMatch = employee;
        }
      }
    }
    return bestMatch;
  }

  // Ikki vektor orasidagi Evklid masofasini hisoblash
  double _euclideanDistance(List<double> e1, List<double> e2) {
    double sum = 0.0;
    for (int i = 0; i < e1.length; i++) {
      sum += pow(e1[i] - e2[i], 2);
    }
    return sqrt(sum);
  }

  // --- RASMNI QAYTA ISHLASH YORDAMCHI FUNKSIYALARI ---

  Float32List _imageToByteListFloat32(img.Image image) {
    final convertedBytes = Float32List(112 * 112 * 3);
    final buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < 112; i++) {
      for (var j = 0; j < 112; j++) {
        final pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (pixel.r - 127.5) / 127.5;
        buffer[pixelIndex++] = (pixel.g - 127.5) / 127.5;
        buffer[pixelIndex++] = (pixel.b - 127.5) / 127.5;
      }
    }
    return convertedBytes;
  }

  InputImage? _inputImageFromCameraImage(
      CameraImage image, int sensorOrientation) {
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final imageRotation =
        InputImageRotationValue.fromRawValue(sensorOrientation);
    if (imageRotation == null) return null;

    return InputImage.fromBytes(
      bytes: _concatenatePlanes(image.planes),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: imageRotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  img.Image? _convertCameraImage(CameraImage image) {
    if (image.format.group == ImageFormatGroup.yuv420) {
      return _convertYUV420(image);
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      return _convertBGRA8888(image);
    }
    return null;
  }

  img.Image _convertBGRA8888(CameraImage image) {
    return img.Image.fromBytes(
        width: image.width,
        height: image.height,
        bytes: image.planes[0].bytes.buffer,
        order: img.ChannelOrder.bgra);
  }

  img.Image _convertYUV420(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel!;
    final imageYUV = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int uvIndex =
            uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
        final int index = y * width + x;
        final yp = image.planes[0].bytes[index];
        final up = image.planes[1].bytes[uvIndex];
        final vp = image.planes[2].bytes[uvIndex];
        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
            .round()
            .clamp(0, 255);
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
        imageYUV.setPixelRgba(x, y, r, g, b, 255);
      }
    }
    return imageYUV;
  }

  void dispose() {
    _faceDetector.close();
    _interpreter.close();
  }
}
