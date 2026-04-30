// ============================================================
// face_id_service.dart
// Dịch vụ nhận diện khuôn mặt - Core AI Logic
// Sử dụng: Google ML Kit (detect) + TFLite MobileFaceNet (embed)
// ============================================================

import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

// --- MODELS ---
enum FaceScanState { idle, searching, detected, waitingBlink, capturing, processing, success, failed }

class FaceMatchResult {
  final bool isMatch;
  final double distance;
  final double confidence;
  const FaceMatchResult({required this.isMatch, required this.distance, required this.confidence});
}

class DetectedFaceInfo {
  final Face face;
  final bool isBlinking;
  final bool isTooClose;
  final bool isTooFar;
  final bool isCentered;
  const DetectedFaceInfo({required this.face, required this.isBlinking, required this.isTooClose, required this.isTooFar, required this.isCentered});
}

class FaceIdService {
  FaceIdService._internal();
  static final FaceIdService instance = FaceIdService._internal();

  late final FaceDetector _faceDetector;
  Interpreter? _interpreter;
  bool _isInitialized = false;
  static const double _matchThreshold = 0.70;
  static const int _modelInputSize = 112;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _faceDetector = FaceDetector(options: FaceDetectorOptions(
      enableLandmarks: true,
      enableClassification: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.accurate,
    ));
    try {
      _interpreter = await Interpreter.fromAsset('assets/mobilefacenet.tflite', options: InterpreterOptions()..threads = 4);
      _isInitialized = true;
    } catch (e) {
      print('[FaceIdService] Lỗi nạp model: $e');
    }
  }

  Future<DetectedFaceInfo?> detectFaceFromCameraImage(CameraImage image, InputImageRotation rotation) async {
    if (!_isInitialized) return null;
    final inputImage = InputImage.fromBytes(
      bytes: image.planes[0].bytes,
      metadata: InputImageMetadata(
        size: ui.Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
    final faces = await _faceDetector.processImage(inputImage);
    if (faces.isEmpty) return null;
    final face = faces.first;
    return DetectedFaceInfo(
      face: face,
      isBlinking: (face.leftEyeOpenProbability ?? 1.0) < 0.2 && (face.rightEyeOpenProbability ?? 1.0) < 0.2,
      isTooClose: face.boundingBox.width / image.width > 0.65,
      isTooFar: face.boundingBox.width / image.width < 0.2,
      isCentered: (face.boundingBox.center.dx - image.width / 2).abs() / image.width < 0.15,
    );
  }

  Future<List<double>> extractEmbedding(Uint8List bytes, Rect rect) async {
    final raw = img.decodeImage(bytes);
    if (raw == null || _interpreter == null) return [];
    final cropped = img.copyCrop(raw, x: rect.left.toInt(), y: rect.top.toInt(), width: rect.width.toInt(), height: rect.height.toInt());
    final resized = img.copyResize(cropped, width: _modelInputSize, height: _modelInputSize);
    
    var input = List.generate(1, (_) => List.generate(_modelInputSize, (y) => List.generate(_modelInputSize, (x) {
      final p = resized.getPixel(x, y);
      return [(p.r / 127.5) - 1.0, (p.g / 127.5) - 1.0, (p.b / 127.5) - 1.0];
    })));

    var output = List.filled(1 * 192, 0.0).reshape([1, 192]);
    _interpreter!.run(input, output);
    final embedding = (output[0] as List).cast<double>();
    final norm = sqrt(embedding.fold(0.0, (s, v) => s + v * v));
    return embedding.map((v) => v / (norm == 0 ? 1 : norm)).toList();
  }

  FaceMatchResult compareFaces(List<double> curr, List<double> saved) {
    double sum = 0;
    for (int i = 0; i < curr.length; i++) sum += pow(curr[i] - saved[i], 2);
    final dist = sqrt(sum);
    return FaceMatchResult(isMatch: dist < _matchThreshold, distance: dist, confidence: ((1 - dist / _matchThreshold) * 100).clamp(0, 100));
  }

  void dispose() { _faceDetector.close(); _interpreter?.close(); }
}
