import 'dart:math';
import 'dart:ui' show Rect, Size;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:savdo_uz/models/employee_model.dart';
import 'package:savdo_uz/services/firestore_service.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceRecognitionService {
  final FirestoreService _firestoreService;
  Interpreter? _interpreter;
  Map<String, Employee> _registeredEmployees = {};
  bool _isProcessing = false;

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  FaceRecognitionService(this._firestoreService) {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadModel();
    await _loadRegisteredFaces();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter =
          await Interpreter.fromAsset('assets/ml/mobile_face_net.tflite');
      debugPrint("✅ FaceNet modeli muvaffaqiyatli yuklandi.");
    } catch (e) {
      debugPrint("❌ Modelni yuklashda xatolik: $e");
    }
  }

  Future<void> _loadRegisteredFaces() async {
    try {
      final employees = await _firestoreService.getAllEmployeesWithFaceData();
      _registeredEmployees = {for (var e in employees) e.id!: e};
      debugPrint(
          "✅ ${_registeredEmployees.length} ta xodim yuz ma'lumoti yuklandi.");
    } catch (e) {
      debugPrint("❌ Ro'yxatdan o'tgan yuzlarni yuklashda xatolik: $e");
    }
  }

  Future<List<double>?> getEmbeddingFromImageFile(XFile imageFile) async {
    final inputImage = InputImage.fromFilePath(imageFile.path);
    final faces = await _faceDetector.processImage(inputImage);

    if (faces.isEmpty) {
      debugPrint("⚠️ Rasmdan yuz topilmadi.");
      return null;
    }

    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return null;

    final croppedFace = _cropFace(image, faces.first.boundingBox);
    return _getEmbedding(croppedFace);
  }

  Future<Employee?> predict(
      CameraImage cameraImage, CameraDescription camera) async {
    if (_isProcessing || _interpreter == null) return null;
    _isProcessing = true;

    try {
      final inputImage = _inputImageFromCameraImage(cameraImage, camera);
      if (inputImage == null) return null;

      final List<Face> faces = await _faceDetector.processImage(inputImage);
      if (faces.isEmpty) return null;

      final image = _convertCameraImage(cameraImage);
      if (image == null) return null;

      final croppedFace = _cropFace(image, faces.first.boundingBox);
      final currentEmbedding = _getEmbedding(croppedFace);

      return _compareEmbeddings(currentEmbedding);
    } catch (e) {
      debugPrint("❌ Kamera tasvirini tahlil qilishda xatolik: $e");
      return null;
    } finally {
      _isProcessing = false;
    }
  }

  img.Image _cropFace(img.Image image, Rect boundingBox) {
    final x = boundingBox.left.clamp(0, image.width.toDouble() - 1).toInt();
    final y = boundingBox.top.clamp(0, image.height.toDouble() - 1).toInt();
    final w = boundingBox.width.clamp(1, (image.width - x).toDouble()).toInt();
    final h =
        boundingBox.height.clamp(1, (image.height - y).toDouble()).toInt();

    return img.copyCrop(image, x: x, y: y, width: w, height: h);
  }

  List<double> _getEmbedding(img.Image croppedFace) {
    final resizedFace = img.copyResize(croppedFace, width: 112, height: 112);
    final imageMatrix = _imageToByteListFloat32(resizedFace);

    final input = [
      List.generate(112, (i) {
        return List.generate(112, (j) {
          final idx = (i * 112 + j) * 3;
          return [
            imageMatrix[idx + 0],
            imageMatrix[idx + 1],
            imageMatrix[idx + 2],
          ];
        });
      })
    ];

    final output = List.generate(1, (_) => List<double>.filled(192, 0.0));
    _interpreter!.run(input, output);
    return List<double>.from(output[0]);
  }

  Employee? _compareEmbeddings(List<double> currentEmbedding) {
    double minDistance = double.infinity;
    Employee? bestMatch;

    for (var employee in _registeredEmployees.values) {
      if (employee.faceData.isNotEmpty) {
        final distance = _euclideanDistance(
          List<double>.from(employee.faceData),
          currentEmbedding,
        );

        if (distance < 1.0 && distance < minDistance) {
          minDistance = distance;
          bestMatch = employee;
        }
      }
    }
    return bestMatch;
  }

  double _euclideanDistance(List<double> e1, List<double> e2) {
    double sum = 0.0;
    for (int i = 0; i < e1.length; i++) {
      final d = e1[i] - e2[i];
      sum += d * d;
    }
    return sqrt(sum);
  }

  void dispose() {
    _faceDetector.close();
    _interpreter?.close();
  }

  // --- RASMNI QAYTA ISHLASH FUNKSIYALARI ---
  List<double> _imageToByteListFloat32(img.Image image) {
    final result = List<double>.filled(112 * 112 * 3, 0.0);
    int pixelIndex = 0;
    for (var y = 0; y < 112; y++) {
      for (var x = 0; x < 112; x++) {
        final pixel = image.getPixel(x, y);

        // ✅ image 4.x usuli
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();

        result[pixelIndex++] = (r - 127.5) / 127.5;
        result[pixelIndex++] = (g - 127.5) / 127.5;
        result[pixelIndex++] = (b - 127.5) / 127.5;
      }
    }
    return result;
  }

  img.Image? _convertCameraImage(CameraImage image) {
    if (image.format.group != ImageFormatGroup.yuv420) {
      debugPrint('⚠️ Qo‘llab-quvvatlanmagan format: ${image.format.group}');
      return null;
    }

    final int width = image.width;
    final int height = image.height;

    final Plane planeY = image.planes[0];
    final Plane planeU = image.planes[1];
    final Plane planeV = image.planes[2];

    final Uint8List bytesY = planeY.bytes;
    final Uint8List bytesU = planeU.bytes;
    final Uint8List bytesV = planeV.bytes;

    final int strideY = planeY.bytesPerRow;
    final int strideU = planeU.bytesPerRow;
    final int strideV = planeV.bytesPerRow;
    final int stepU = planeU.bytesPerPixel ?? 1;
    final int stepV = planeV.bytesPerPixel ?? 1;

    final img.Image rgbImage = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      final int uvRow = (y ~/ 2);
      for (int x = 0; x < width; x++) {
        final int uvCol = (x ~/ 2);

        final int indexY = y * strideY + x;
        final int indexU = uvRow * strideU + uvCol * stepU;
        final int indexV = uvRow * strideV + uvCol * stepV;

        final int Y = bytesY[indexY];
        final int U = bytesU[indexU];
        final int V = bytesV[indexV];

        double yf = Y.toDouble();
        double uf = U.toDouble() - 128.0;
        double vf = V.toDouble() - 128.0;

        int r = (yf + 1.402 * vf).round();
        int g = (yf - 0.344136 * uf - 0.714136 * vf).round();
        int b = (yf + 1.772 * uf).round();

        r = r.clamp(0, 255);
        g = g.clamp(0, 255);
        b = b.clamp(0, 255);

        rgbImage.setPixelRgba(x, y, r, g, b, 255);
      }
    }
    return rgbImage;
  }

  InputImage? _inputImageFromCameraImage(
      CameraImage image, CameraDescription camera) {
    final rotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }
}
