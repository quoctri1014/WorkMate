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
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

// ------------------------------------------------------------------
// Model kết quả nhận diện
// ------------------------------------------------------------------

/// Trạng thái của quá trình quét khuôn mặt
enum FaceScanState {
  idle,           // Chờ
  searching,      // Đang tìm khuôn mặt
  detected,       // Đã thấy khuôn mặt
  waitingBlink,   // Chờ nháy mắt (liveness check)
  capturing,      // Đang chụp
  processing,     // Đang xử lý AI
  success,        // Thành công
  failed,         // Thất bại
}

/// Kết quả so sánh khuôn mặt
class FaceMatchResult {
  final bool isMatch;
  final double distance;     // Khoảng cách Euclidean (< 0.7 là khớp)
  final double confidence;   // Độ tự tin (%)

  const FaceMatchResult({
    required this.isMatch,
    required this.distance,
    required this.confidence,
  });

  @override
  String toString() =>
      'FaceMatchResult(match=$isMatch, dist=${distance.toStringAsFixed(3)}, conf=${confidence.toStringAsFixed(1)}%)';
}

/// Thông tin khuôn mặt đã phát hiện
class DetectedFaceInfo {
  final Face face;
  final bool isBlinking;
  final bool isTooClose;
  final bool isTooFar;
  final bool isCentered;

  const DetectedFaceInfo({
    required this.face,
    required this.isBlinking,
    required this.isTooClose,
    required this.isTooFar,
    required this.isCentered,
  });
}

// ------------------------------------------------------------------
// FaceIdService - Singleton chính
// ------------------------------------------------------------------

class FaceIdService {
  FaceIdService._internal();
  static final FaceIdService instance = FaceIdService._internal();

  // Detector của Google ML Kit
  late final FaceDetector _faceDetector;

  // Interpreter TFLite (MobileFaceNet)
  Interpreter? _interpreter;

  bool _isInitialized = false;

  // Ngưỡng khoảng cách Euclidean để coi là "khớp mặt"
  static const double _matchThreshold = 0.70;

  // Kích thước đầu vào của MobileFaceNet
  static const int _modelInputSize = 112;

  // ------------------------------------------------------------------
  // Khởi tạo
  // ------------------------------------------------------------------

  /// Gọi hàm này 1 lần duy nhất trong main() hoặc initState()
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Cấu hình Face Detector: bật các điểm mốc & phân loại mắt
    final options = FaceDetectorOptions(
      enableLandmarks: true,
      enableClassification: true, // Bật nhận diện mắt mở/nhắm
      enableTracking: true,
      performanceMode: FaceDetectorMode.accurate,
      minFaceSize: 0.15,
    );
    _faceDetector = GoogleMlKit.vision.faceDetector(options);

    // Tải mô hình TFLite từ assets
    await _loadTFLiteModel();

    _isInitialized = true;
  }

  Future<void> _loadTFLiteModel() async {
    try {
      final interpreterOptions = InterpreterOptions()..threads = 4;
      _interpreter = await Interpreter.fromAsset(
        'assets/mobilefacenet.tflite',
        options: interpreterOptions,
      );
    } catch (e) {
      throw Exception(
          '[FaceIdService] Không thể tải mô hình TFLite: $e\n'
          'Hãy đảm bảo file assets/mobilefacenet.tflite tồn tại '
          'và được khai báo trong pubspec.yaml.');
    }
  }

  // ------------------------------------------------------------------
  // BƯỚC 1: Phát hiện khuôn mặt từ CameraImage (stream)
  // ------------------------------------------------------------------

  /// Phân tích 1 frame từ camera stream.
  /// Trả về null nếu không có khuôn mặt.
  Future<DetectedFaceInfo?> detectFaceFromCameraImage(
    CameraImage cameraImage,
    InputImageRotation rotation,
  ) async {
    _assertInitialized();

    final inputImage = _convertCameraImageToInputImage(cameraImage, rotation);
    final faces = await _faceDetector.processImage(inputImage);

    if (faces.isEmpty) return null;

    // Lấy khuôn mặt lớn nhất (gần nhất)
    final face = faces.reduce(
      (a, b) => _faceArea(a) > _faceArea(b) ? a : b,
    );

    final imageWidth = cameraImage.width.toDouble();
    final imageHeight = cameraImage.height.toDouble();

    return DetectedFaceInfo(
      face: face,
      isBlinking: _isBlinking(face),
      isTooClose: _isTooClose(face, imageWidth, imageHeight),
      isTooFar: _isTooFar(face, imageWidth, imageHeight),
      isCentered: _isCentered(face, imageWidth, imageHeight),
    );
  }

  // ------------------------------------------------------------------
  // BƯỚC 2: Trích xuất embedding từ ảnh chụp
  // ------------------------------------------------------------------

  /// Từ 1 ảnh chụp (XFile), crop khuôn mặt và trả về embedding 192 chiều.
  /// Embedding này là "vân tay" của khuôn mặt — dùng để lưu & so sánh.
  Future<List<double>> extractEmbedding(
    Uint8List imageBytes,
    Rect faceRect,
  ) async {
    _assertInitialized();
    if (_interpreter == null) throw Exception('TFLite chưa được tải.');

    // 1. Giải mã ảnh
    final rawImage = img.decodeImage(imageBytes);
    if (rawImage == null) throw Exception('Không thể giải mã ảnh.');

    // 2. Crop khuôn mặt (thêm padding 20% để lấy cả trán & cằm)
    final croppedFace = _cropFaceWithPadding(rawImage, faceRect, padding: 0.2);

    // 3. Resize về 112x112
    final resized = img.copyResize(
      croppedFace,
      width: _modelInputSize,
      height: _modelInputSize,
      interpolation: img.Interpolation.linear,
    );

    // 4. Chuẩn hoá pixel về [-1, 1]
    final input = _normalizeImage(resized);

    // 5. Chạy mô hình TFLite
    final outputShape = _interpreter!.getOutputTensor(0).shape;
    final outputSize = outputShape.reduce((a, b) => a * b);
    final output = List.filled(outputSize, 0.0).reshape(outputShape);

    _interpreter!.run(input, output);

    // 6. Lấy vector embedding (flatten về 1D)
    final embedding = (output[0] as List).cast<double>();
    return _l2Normalize(embedding);
  }

  // ------------------------------------------------------------------
  // BƯỚC 3: So sánh 2 embedding
  // ------------------------------------------------------------------

  /// So sánh embedding hiện tại với embedding đã lưu.
  /// Dùng khoảng cách Euclidean.
  FaceMatchResult compareFaces(
    List<double> currentEmbedding,
    List<double> savedEmbedding,
  ) {
    if (currentEmbedding.length != savedEmbedding.length) {
      throw ArgumentError(
          'Embedding không cùng kích thước: '
          '${currentEmbedding.length} vs ${savedEmbedding.length}');
    }

    final distance = _euclideanDistance(currentEmbedding, savedEmbedding);
    final isMatch = distance < _matchThreshold;

    // Chuyển khoảng cách sang % độ tự tin (0.0 -> 100%, 0.7 -> 0%)
    final confidence = ((1.0 - distance / _matchThreshold) * 100).clamp(0.0, 100.0);

    return FaceMatchResult(
      isMatch: isMatch,
      distance: distance,
      confidence: confidence,
    );
  }

  // ------------------------------------------------------------------
  // Các hàm tiện ích nội bộ
  // ------------------------------------------------------------------

  /// Chuyển CameraImage sang InputImage của ML Kit
  InputImage _convertCameraImageToInputImage(
    CameraImage image,
    InputImageRotation rotation,
  ) {
    final plane = image.planes[0];
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: ui.Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  /// Kiểm tra mắt nhắm (nháy mắt) — dùng cho liveness detection
  bool _isBlinking(Face face) {
    final leftEye = face.leftEyeOpenProbability ?? 1.0;
    final rightEye = face.rightEyeOpenProbability ?? 1.0;
    // Cả 2 mắt đều nhắm hơn 80% -> coi là nháy mắt
    return leftEye < 0.2 && rightEye < 0.2;
  }

  bool _isTooClose(Face face, double imgW, double imgH) {
    final faceW = face.boundingBox.width;
    return faceW / imgW > 0.65;
  }

  bool _isTooFar(Face face, double imgW, double imgH) {
    final faceW = face.boundingBox.width;
    return faceW / imgW < 0.20;
  }

  bool _isCentered(Face face, double imgW, double imgH) {
    final centerX = face.boundingBox.center.dx;
    final centerY = face.boundingBox.center.dy;
    final dx = (centerX - imgW / 2).abs() / imgW;
    final dy = (centerY - imgH / 2).abs() / imgH;
    return dx < 0.15 && dy < 0.15;
  }

  double _faceArea(Face f) =>
      f.boundingBox.width * f.boundingBox.height;

  /// Crop khuôn mặt từ ảnh gốc, có thêm padding
  img.Image _cropFaceWithPadding(
    img.Image source,
    Rect faceRect, {
    double padding = 0.2,
  }) {
    final padW = faceRect.width * padding;
    final padH = faceRect.height * padding;

    final x = (faceRect.left - padW).clamp(0, source.width - 1).toInt();
    final y = (faceRect.top - padH).clamp(0, source.height - 1).toInt();
    final w = (faceRect.width + padW * 2)
        .clamp(1, source.width - x)
        .toInt();
    final h = (faceRect.height + padH * 2)
        .clamp(1, source.height - y)
        .toInt();

    return img.copyCrop(source, x: x, y: y, width: w, height: h);
  }

  /// Chuẩn hoá pixel ảnh về dạng Float32List [-1, 1] cho TFLite
  List<List<List<List<double>>>> _normalizeImage(img.Image image) {
    return List.generate(
      1,
      (_) => List.generate(
        _modelInputSize,
        (y) => List.generate(
          _modelInputSize,
          (x) {
            final pixel = image.getPixel(x, y);
            return [
              (pixel.r / 127.5) - 1.0,
              (pixel.g / 127.5) - 1.0,
              (pixel.b / 127.5) - 1.0,
            ];
          },
        ),
      ),
    );
  }

  /// L2 Normalize: chuẩn hoá vector để khoảng cách Euclidean ổn định hơn
  List<double> _l2Normalize(List<double> vector) {
    final norm = sqrt(vector.fold(0.0, (sum, v) => sum + v * v));
    if (norm == 0) return vector;
    return vector.map((v) => v / norm).toList();
  }

  /// Tính khoảng cách Euclidean giữa 2 vector
  double _euclideanDistance(List<double> a, List<double> b) {
    double sum = 0.0;
    for (int i = 0; i < a.length; i++) {
      final diff = a[i] - b[i];
      sum += diff * diff;
    }
    return sqrt(sum);
  }

  void _assertInitialized() {
    if (!_isInitialized) {
      throw StateError(
          '[FaceIdService] Chưa gọi initialize(). '
          'Hãy gọi await FaceIdService.instance.initialize() trước.');
    }
  }

  /// Giải phóng tài nguyên khi app đóng
  void dispose() {
    _faceDetector.close();
    _interpreter?.close();
    _isInitialized = false;
  }
}
