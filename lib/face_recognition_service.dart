import 'package:flutter/foundation.dart'; // debugPrint va Float32List uchun
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceRecognitionService {
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

  // Rasmdan yuz izini (embedding) olish uchun asosiy funksiya
  Future<List?> processImageForEmbedding(XFile imageFile) async {
    final inputImage = InputImage.fromFilePath(imageFile.path);
    final List<Face> faces = await _faceDetector.processImage(inputImage);

    if (faces.isEmpty) {
      debugPrint("Rasmdan yuz topilmadi.");
      return null;
    }

    // Eng katta yuzni olamiz
    final Face detectedFace = faces.reduce((curr, next) =>
        (curr.boundingBox.width * curr.boundingBox.height) >
                (next.boundingBox.width * next.boundingBox.height)
            ? curr
            : next);

    // Rasmni o'qib, yuzni qirqib olamiz
    final fileBytes = await imageFile.readAsBytes();
    final image = img.decodeImage(fileBytes);
    if (image == null) return null;

    final boundingBox = detectedFace.boundingBox;
    final croppedFace = img.copyCrop(
      image,
      x: boundingBox.left.toInt(),
      y: boundingBox.top.toInt(),
      width: boundingBox.width.toInt(),
      height: boundingBox.height.toInt(),
    );

    // Model uchun kerakli o'lchamga keltiramiz (112x112)
    final resizedFace = img.copyResize(croppedFace, width: 112, height: 112);

    // Rasmni modelga yuborish uchun tayyorlaymiz
    final imageMatrix = _imageToByteListFloat32(resizedFace);

    // Modelga yuborib, natijani (yuz izini) olamiz
    return _getEmbedding(imageMatrix);
  }

  // Modeldan yuz izini olish
  Future<List> _getEmbedding(Float32List imageMatrix) async {
    if (_interpreter == null) {
      await _loadModel();
    }

    // Modelning kirish va chiqish o'lchamlarini aniqlash
    final input = [imageMatrix];
    final output = List.filled(1 * 192, 0.0).reshape([1, 192]);

    _interpreter!.run(input, output);
    return output[0];
  }

  // Rasmni model tushunadigan formatga (Float32List) o'girish
  Float32List _imageToByteListFloat32(img.Image image) {
    final convertedBytes = Float32List(1 * 112 * 112 * 3);
    final buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < 112; i++) {
      for (var j = 0; j < 112; j++) {
        final pixel = image.getPixel(j, i);
        // Piksel ranglarini -1 va 1 oralig'iga normallashtirish
        buffer[pixelIndex++] = (pixel.r - 127.5) / 127.5;
        buffer[pixelIndex++] = (pixel.g - 127.5) / 127.5;
        buffer[pixelIndex++] = (pixel.b - 127.5) / 127.5;
      }
    }
    return convertedBytes.buffer.asFloat32List();
  }

  void dispose() {
    _faceDetector.close();
    _interpreter?.close();
  }
}
