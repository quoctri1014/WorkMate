// ============================================================
// checkin_face_screen.dart
// Màn hình CHẤM CÔNG bằng khuôn mặt (THẬT)
// ============================================================

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:workmate/services/face_id_service.dart';
import 'package:workmate/presentation/viewmodels/viewmodels.dart';
import 'package:workmate/data/repositories/api_service.dart';
import 'dart:io';
import 'attendance_success_screen.dart';

class CheckInFaceScreen extends StatefulWidget {
  final bool isCheckIn;
  const CheckInFaceScreen({super.key, this.isCheckIn = true});

  @override
  State<CheckInFaceScreen> createState() => _CheckInFaceScreenState();
}

class _CheckInFaceScreenState extends State<CheckInFaceScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraReady = false;

  FaceScanState _scanState = FaceScanState.searching;
  String _guideText = 'Đưa khuôn mặt vào khung';
  DetectedFaceInfo? _lastDetected;
  FaceMatchResult? _matchResult;

  bool _isProcessingFrame = false;
  bool _isDone = false;

  int _stableFrameCount = 0;
  static const int _requiredStableFrames = 5;

  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnim;
  late AnimationController _resultController;
  late Animation<double> _resultAnim;

  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _initAnimations();
    _initCamera();
  }

  Future<void> _checkPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  }

  void _initAnimations() {
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanLineAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );

    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _resultAnim = CurvedAnimation(
      parent: _resultController,
      curve: Curves.elasticOut,
    );
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) return;

    final frontCamera = _cameras!.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras!.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.nv21,
    );

    await _cameraController!.initialize();
    if (!mounted) return;

    _cameraController!.startImageStream(_onCameraFrame);
    setState(() => _isCameraReady = true);
  }

  void _onCameraFrame(CameraImage image) async {
    if (_isProcessingFrame || _isDone) return;
    _isProcessingFrame = true;

    try {
      final rotation = _getRotation();
      final faceInfo = await FaceIdService.instance.detectFaceFromCameraImage(
        image,
        rotation,
      );

      if (!mounted) return;

      if (faceInfo == null) {
        _stableFrameCount = 0;
        _updateState(FaceScanState.searching, 'Đưa khuôn mặt vào khung');
        return;
      }

      if (faceInfo.isTooClose) {
        _stableFrameCount = 0;
        _updateState(FaceScanState.detected, 'Lùi ra xa hơn');
        return;
      }

      if (faceInfo.isTooFar) {
        _stableFrameCount = 0;
        _updateState(FaceScanState.detected, 'Lại gần hơn');
        return;
      }

      if (!faceInfo.isCentered) {
        _stableFrameCount = 0;
        _updateState(FaceScanState.detected, 'Đưa mặt vào giữa khung');
        return;
      }

      _stableFrameCount++;
      _lastDetected = faceInfo;
      _updateState(FaceScanState.detected, 'Giữ yên...');

      if (_stableFrameCount >= _requiredStableFrames) {
        _stableFrameCount = 0;
        await _captureAndCompare();
      }
    } finally {
      _isProcessingFrame = false;
    }
  }

  Future<void> _captureAndCompare() async {
    if (_cameraController == null || _lastDetected == null) return;

    try {
      await _cameraController!.stopImageStream();
      _updateState(FaceScanState.processing, 'Đang nhận diện...');

      final xFile = await _cameraController!.takePicture();
      final imageBytes = await xFile.readAsBytes();
      final faceRect = _lastDetected!.face.boundingBox;

      final currentEmbedding = await FaceIdService.instance.extractEmbedding(
        imageBytes,
        faceRect,
      );

      final user = context.read<AuthViewModel>().currentUser;
      if (user == null) throw Exception("User not found");

      // Giả lập hoặc gọi API lấy embedding thật
      // Vì tôi chưa cập nhật API nên tôi sẽ tạm thời để logic so sánh ở đây
      // nhma tôi sẽ cập nhật API sớm
      final savedEmbedding = await _api.fetchSavedEmbedding(user.id);
      
      if (savedEmbedding == null) {
        _updateState(FaceScanState.failed, 'Chưa đăng ký khuôn mặt');
        _resetAfterDelay();
        return;
      }

      final result = FaceIdService.instance.compareFaces(
        currentEmbedding,
        savedEmbedding,
      );

      setState(() => _matchResult = result);

      if (result.isMatch) {
        _isDone = true;
        _updateState(FaceScanState.success, 'Nhận diện thành công!');
        _resultController.forward();
        
        // 1. Lấy vị trí GPS
        double? lat, lng;
        try {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 5),
          );
          lat = position.latitude;
          lng = position.longitude;
        } catch (e) {
          debugPrint("GPS Error: $e");
          // Nếu máy ảo không có GPS, dùng tạm tọa độ mẫu để test nếu muốn
          // lat = 10.7946; lng = 106.7218; 
        }

        // 2. Lấy thông tin WiFi
        String? wifiSsid;
        try {
          wifiSsid = await NetworkInfo().getWifiName();
          // Nếu máy ảo trả về null, ta có thể mock để test
          if (wifiSsid == null || wifiSsid.isEmpty) {
            wifiSsid = "WorkMate_Office_5G"; // MOCK cho máy ảo
          }
        } catch (e) {
          debugPrint("WiFi Error: $e");
        }

        // 3. Gửi kết quả chấm công lên server
        final success = await _api.submitCheckIn(
          user.id, 
          currentEmbedding,
          lat: lat,
          lng: lng,
          wifiSsid: wifiSsid,
        );

        if (success) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => AttendanceSuccessScreen(isCheckIn: widget.isCheckIn)),
              );
            }
          });
        } else {
          _updateState(FaceScanState.failed, 'Chấm công thất bại (Sai vị trí/WiFi)');
          _resetAfterDelay();
        }
      } else {
        _updateState(
          FaceScanState.failed,
          'Không khớp (${result.confidence.toStringAsFixed(0)}%)',
        );
        _resultController.forward();
        _resetAfterDelay();
      }
    } catch (e) {
      _updateState(FaceScanState.failed, 'Lỗi xử lý, thử lại');
      _resetAfterDelay();
    }
  }

  void _resetAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      _resultController.reverse();
      setState(() {
        _scanState = FaceScanState.searching;
        _guideText = 'Đưa khuôn mặt vào khung';
        _matchResult = null;
      });
      _cameraController?.startImageStream(_onCameraFrame);
    });
  }

  void _updateState(FaceScanState state, String guide) {
    if (!mounted) return;
    setState(() {
      _scanState = state;
      _guideText = guide;
    });
  }

  InputImageRotation _getRotation() {
    final camera = _cameras!.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras!.first,
    );
    switch (camera.sensorOrientation) {
      case 90:  return InputImageRotation.rotation90deg;
      case 180: return InputImageRotation.rotation180deg;
      case 270: return InputImageRotation.rotation270deg;
      default:  return InputImageRotation.rotation0deg;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_isCameraReady && _cameraController != null)
            Transform.scale(
              scaleX: -1,
              child: CameraPreview(_cameraController!),
            ),
          _buildOverlay(),
          _buildScanRing(),
          _buildTopBar(),
          _buildBottomInfo(),
          if (_matchResult != null) _buildResultBadge(),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return CustomPaint(
      painter: _CheckinOverlayPainter(
        color: Colors.black.withOpacity(0.55),
      ),
    );
  }

  Widget _buildScanRing() {
    return Center(
      child: AnimatedBuilder(
        animation: _scanLineAnim,
        builder: (context, _) {
          return SizedBox(
            width: 280,
            height: 280,
            child: CustomPaint(
              painter: _CheckinRingPainter(
                state: _scanState,
                progress: _scanLineAnim.value,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
              const Expanded(
                child: Text('CHẤM CÔNG', textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomInfo() {
    final color = _getStateColor();
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_scanState == FaceScanState.processing)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF40C4FF))),
                ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(_guideText, key: ValueKey(_guideText),
                  style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
              ),
              const SizedBox(height: 8),
              Text('Hệ thống tự động nhận diện khi phát hiện khuôn mặt',
                style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultBadge() {
    final isSuccess = _matchResult!.isMatch;
    return Positioned(
      top: 0, left: 0, right: 0, bottom: 0,
      child: AnimatedBuilder(
        animation: _resultAnim,
        builder: (context, _) {
          return Transform.scale(
            scale: _resultAnim.value,
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.9), borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isSuccess ? const Color(0xFF00E676) : const Color(0xFFFF5252), width: 1.5)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 64, color: isSuccess ? const Color(0xFF00E676) : const Color(0xFFFF5252)),
                    const SizedBox(height: 16),
                    Text(isSuccess ? 'Chấm công thành công' : 'Không nhận ra',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Độ chính xác: ${_matchResult!.confidence.toStringAsFixed(1)}%',
                      style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getStateColor() {
    switch (_scanState) {
      case FaceScanState.success:  return const Color(0xFF00E676);
      case FaceScanState.failed:   return const Color(0xFFFF5252);
      case FaceScanState.detected: return const Color(0xFFFFD740);
      default:                     return Colors.white;
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _scanLineController.dispose();
    _resultController.dispose();
    super.dispose();
  }
}

class _CheckinOverlayPainter extends CustomPainter {
  final Color color;
  _CheckinOverlayPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: center, radius: 140))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, Paint()..color = color);
  }
  @override
  bool shouldRepaint(_CheckinOverlayPainter old) => old.color != color;
}

class _CheckinRingPainter extends CustomPainter {
  final FaceScanState state;
  final double progress;
  _CheckinRingPainter({required this.state, required this.progress});
  Color get _color {
    switch (state) {
      case FaceScanState.success:  return const Color(0xFF00E676);
      case FaceScanState.failed:   return const Color(0xFFFF5252);
      case FaceScanState.detected: return const Color(0xFFFFD740);
      default:                     return const Color(0xFF40C4FF);
    }
  }
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    canvas.drawCircle(center, radius, Paint()..color = _color.withOpacity(0.15)..style = PaintingStyle.stroke..strokeWidth = 1);
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, -3.14159 / 2, 3.14159 * 2 * (state == FaceScanState.detected ? 1.0 : progress), false,
      Paint()..color = _color..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round);
    if (state == FaceScanState.searching || state == FaceScanState.detected) {
      final scanY = center.dy - radius + size.height * progress;
      canvas.save();
      canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius - 2)));
      canvas.drawRect(Rect.fromLTWH(center.dx - radius, scanY - 1, radius * 2, 2),
        Paint()..color = _color.withOpacity(0.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      canvas.restore();
    }
  }
  @override
  bool shouldRepaint(_CheckinRingPainter old) => old.progress != progress || old.state != state;
}
