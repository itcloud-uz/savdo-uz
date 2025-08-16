// lib/face_recognition_service.dart

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
// ignore: unnecessary_import
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter_plus/tflite_flutter_plus.dart'; // <--- O'ZGARGAN QATOR

class FaceRecognitionService {
  // ... qolgan barcha kod o'zgarishsiz qoladi ...
  Interpreter? _interpreter;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  FaceRecognitionService() {
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter =
          await Interpreter.fromAsset('assets/ml/mobile_face_net.tflite');
    } catch (e) {
      debugPrint("Modelni yuklashda xatolik: $e");
    }
  }

  Future<List?> processImageFileForEmbedding(XFile imageFile) async {
    final inputImage = InputImage.fromFilePath(imageFile.path);
    final faces = await _faceDetector.processImage(inputImage);

    if (faces.isEmpty) {
      debugPrint("Rasmdan yuz topilmadi.");
      return null;
    }

    final fileBytes = await imageFile.readAsBytes();
    final image = img.decodeImage(fileBytes);
    if (image == null) return null;

    return _processFace(faces[0], image);
  }

  Future<List?> processCameraImageForEmbedding(
      CameraImage cameraImage, InputImageRotation rotation) async {
    final inputImage = _inputImageFromCameraImage(cameraImage, rotation);
    if (inputImage == null) return null;

    final faces = await _faceDetector.processImage(inputImage);
    if (faces.isEmpty) return null;

    final image = _convertCameraImage(cameraImage);
    if (image == null) return null;

    return _processFace(faces[0], image);
  }

  List? _processFace(Face face, img.Image image) {
    final boundingBox = face.boundingBox;
    final croppedFace = img.copyCrop(
      image,
      x: boundingBox.left.toInt(),
      y: boundingBox.top.toInt(),
      width: boundingBox.width.toInt(),
      height: boundingBox.height.toInt(),
    );

    final resizedFace = img.copyResize(croppedFace, width: 112, height: 112);
    final imageMatrix = _imageToByteListFloat32(resizedFace);
    return _getEmbedding(imageMatrix);
  }

  List _getEmbedding(Float32List imageMatrix) {
    if (_interpreter == null) return [];

    final input = [imageMatrix];
    final output = List.filled(1 * 192, 0.0).reshape([1, 192]);

    _interpreter!.run(input, output);
    return output[0];
  }

  Float32List _imageToByteListFloat32(img.Image image) {
    final convertedBytes = Float32List(1 * 112 * 112 * 3);
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
    return convertedBytes.buffer.asFloat32List();
  }

  InputImage? _inputImageFromCameraImage(
      CameraImage image, InputImageRotation rotation) {
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    return InputImage.fromBytes(
      bytes: _concatenatePlanes(image.planes),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
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
    _interpreter?.close();
  }
}
