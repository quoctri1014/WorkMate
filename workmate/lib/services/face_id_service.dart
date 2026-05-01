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
  final bool isLowLight;
  const DetectedFaceInfo({
    required this.face, 
    required this.isBlinking, 
    required this.isTooClose, 
    required this.isTooFar, 
    required this.isCentered,
    this.isLowLight = false,
  });
}

class FaceIdService {
  FaceIdService._internal();
  static final FaceIdService instance = FaceIdService._internal();

  FaceDetector? _faceDetector;
  Interpreter? _interpreter;
  bool _isInitialized = false;
  bool _isInitializing = false;
  static const double _matchThreshold = 0.70;
  static const int _modelInputSize = 112;

  Future<void> initialize() async {
    if (_isInitialized) return;
    if (_isInitializing) {
      // Đợi cho đến khi quá trình khởi tạo khác hoàn tất
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }

    _isInitializing = true;
    try {
      print('[FaceIdService] Đang khởi tạo FaceDetector...');
      _faceDetector = FaceDetector(options: FaceDetectorOptions(
        enableLandmarks: true,
        enableClassification: true,
        enableTracking: true,
        performanceMode: FaceDetectorMode.fast,
      ));
      
      print('[FaceIdService] Đang nạp model TFLite...');
      _interpreter = await Interpreter.fromAsset(
        'assets/mobilefacenet.tflite', 
        options: InterpreterOptions()..threads = 4
      );
      
      _isInitialized = true;
      print('[FaceIdService] Khởi tạo FaceIdService THÀNH CÔNG');
    } catch (e) {
      print('[FaceIdService] Lỗi khởi tạo: $e');
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  Future<DetectedFaceInfo?> detectFaceFromCameraImage(CameraImage image, InputImageRotation rotation) async {
    if (!_isInitialized || _faceDetector == null) return null;

    final format = _getInputImageFormat(image.format.group);
    if (format == null) return null;

    final bytes = image.planes[0].bytes;
    
    // Kiểm tra độ sáng (đơn giản bằng cách tính trung bình giá trị pixel plane 0 - Luminance)
    double avgBrightness = 0;
    // Lấy mẫu một số điểm để tiết kiệm hiệu năng
    int step = bytes.length ~/ 100; 
    int sum = 0;
    int count = 0;
    for (int i = 0; i < bytes.length; i += step) {
      sum += bytes[i];
      count++;
    }
    avgBrightness = sum / count;
    bool isLowLight = avgBrightness < 45; // Ngưỡng tối thường khoảng 40-50

    final inputImage = InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: ui.Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );

    final faces = await _faceDetector!.processImage(inputImage);
    if (faces.isEmpty) {
      return isLowLight ? DetectedFaceInfo(
        face: Face(boundingBox: Rect.zero, landmarks: {}, contours: {}),
        isBlinking: false, isTooClose: false, isTooFar: false, isCentered: false,
        isLowLight: true,
      ) : null;
    }

    final face = faces.first;
    final faceSizeRatio = face.boundingBox.width / image.width;

    return DetectedFaceInfo(
      face: face,
      isBlinking: (face.leftEyeOpenProbability ?? 1.0) < 0.2 && (face.rightEyeOpenProbability ?? 1.0) < 0.2,
      isTooClose: faceSizeRatio > 0.65,
      isTooFar: faceSizeRatio < 0.15,
      isCentered: (face.boundingBox.center.dx - image.width / 2).abs() / image.width < 0.20 &&
                  (face.boundingBox.center.dy - image.height / 2).abs() / image.height < 0.20,
      isLowLight: isLowLight,
    );
  }

  InputImageFormat? _getInputImageFormat(ImageFormatGroup group) {
    if (group == ImageFormatGroup.bgra8888) return InputImageFormat.bgra8888;
    if (group == ImageFormatGroup.nv21) return InputImageFormat.nv21;
    if (group == ImageFormatGroup.yuv420) return InputImageFormat.yuv420;
    return null;
  }

  Future<List<double>> extractEmbedding(Uint8List bytes, Rect rect) async {
    final raw = img.decodeImage(bytes);
    if (raw == null || _interpreter == null) return [];
    
    // Đảm bảo rect nằm trong khung hình
    int left = rect.left.toInt().clamp(0, raw.width);
    int top = rect.top.toInt().clamp(0, raw.height);
    int width = rect.width.toInt().clamp(0, raw.width - left);
    int height = rect.height.toInt().clamp(0, raw.height - top);

    final cropped = img.copyCrop(raw, x: left, y: top, width: width, height: height);
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

  void dispose() { 
    _faceDetector?.close(); 
    _interpreter?.close(); 
    _isInitialized = false; 
  }
}
