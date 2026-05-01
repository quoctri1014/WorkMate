// ============================================================
// face_registration_screen.dart
// Màn hình ĐĂNG KÝ khuôn mặt (THẬT)
// ============================================================

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:workmate/services/face_id_service.dart';

class FaceRegistrationScreen extends StatefulWidget {
  final int employeeId;
  final String employeeName;
  final Future<void> Function(List<double> embedding) onSuccess;

  const FaceRegistrationScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
    required this.onSuccess,
  });

  @override
  State<FaceRegistrationScreen> createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraReady = false;

  FaceScanState _scanState = FaceScanState.searching;
  String _guideText = 'Đưa khuôn mặt vào khung';
  DetectedFaceInfo? _lastDetected;

  bool _isProcessingFrame = false;
  bool _hasRegistered = false;

  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnim;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initCamera();
  }

  void _initAnimations() {
    _scanLineController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _scanLineAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut));
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.05).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      _updateState(FaceScanState.failed, 'Cần quyền Camera!');
      return;
    }

    // Đảm bảo FaceIdService đã khởi tạo xong
    await FaceIdService.instance.initialize();
    
    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) return;
    final frontCamera = _cameras!.firstWhere((c) => c.lensDirection == CameraLensDirection.front, orElse: () => _cameras!.first);
    
    // Sử dụng ResolutionPreset.medium để tăng hiệu năng nhận diện khuôn mặt
    _cameraController = CameraController(
      frontCamera, 
      ResolutionPreset.medium, 
      enableAudio: false, 
      imageFormatGroup: Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.nv21
    );
    
    await _cameraController!.initialize();
    if (!mounted) return;
    _cameraController!.startImageStream(_onCameraFrame);
    setState(() => _isCameraReady = true);
  }

  void _onCameraFrame(CameraImage image) async {
    if (_isProcessingFrame || _hasRegistered) return;
    if (_scanState == FaceScanState.processing || _scanState == FaceScanState.success) return;
    _isProcessingFrame = true;
    try {
      final rotation = _getRotation();
      final faceInfo = await FaceIdService.instance.detectFaceFromCameraImage(image, rotation);
      if (!mounted) return;
      if (faceInfo == null) {
        _updateState(FaceScanState.searching, 'Đưa khuôn mặt vào khung');
      } else if (faceInfo.isTooClose) {
        _updateState(FaceScanState.detected, 'Lùi ra xa hơn một chút');
      } else if (faceInfo.isTooFar) {
        _updateState(FaceScanState.detected, 'Lại gần hơn một chút');
      } else if (!faceInfo.isCentered) {
        _updateState(FaceScanState.detected, 'Đưa mặt vào giữa khung');
      } else if (_scanState != FaceScanState.waitingBlink && _scanState != FaceScanState.capturing) {
        _updateState(FaceScanState.waitingBlink, 'Vui lòng nháy mắt để xác nhận');
        _lastDetected = faceInfo;
      } else if (faceInfo.isBlinking && _scanState == FaceScanState.waitingBlink) {
        _updateState(FaceScanState.capturing, 'Đang chụp...');
        await _captureAndRegister();
      }
    } finally {
      _isProcessingFrame = false;
    }
  }

  Future<void> _captureAndRegister() async {
    if (_cameraController == null) return;
    try {
      await _cameraController!.stopImageStream();
      _updateState(FaceScanState.processing, 'Đang xử lý khuôn mặt...');
      final xFile = await _cameraController!.takePicture();
      final imageBytes = await xFile.readAsBytes();
      final faceRect = _lastDetected!.face.boundingBox;
      final embedding = await FaceIdService.instance.extractEmbedding(imageBytes, faceRect);
      await widget.onSuccess(embedding);
      _hasRegistered = true;
      _updateState(FaceScanState.success, 'Đăng ký thành công!');
    } catch (e) {
      _updateState(FaceScanState.failed, 'Có lỗi xảy ra, thử lại');
      await Future.delayed(const Duration(seconds: 2));
      _cameraController?.startImageStream(_onCameraFrame);
      _updateState(FaceScanState.searching, 'Đưa khuôn mặt vào khung');
    }
  }

  void _updateState(FaceScanState state, String guide) {
    if (!mounted) return;
    setState(() { _scanState = state; _guideText = guide; });
  }

  InputImageRotation _getRotation() {
    final camera = _cameras!.firstWhere((c) => c.lensDirection == CameraLensDirection.front, orElse: () => _cameras!.first);
    switch (camera.sensorOrientation) {
      case 90: return InputImageRotation.rotation90deg;
      case 180: return InputImageRotation.rotation180deg;
      case 270: return InputImageRotation.rotation270deg;
      default: return InputImageRotation.rotation0deg;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_isCameraReady && _cameraController != null) CameraPreview(_cameraController!),
          _buildDarkOverlay(),
          _buildScanFrame(),
          _buildTopBar(),
          _buildBottomGuide(),
          if (_scanState == FaceScanState.success) _buildSuccessOverlay(),
        ],
      ),
    );
  }

  Widget _buildDarkOverlay() {
    return CustomPaint(painter: FaceOverlayPainter(circleRadius: 150, overlayColor: Colors.black.withOpacity(0.6)));
  }

  Widget _buildScanFrame() {
    return Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([_scanLineAnim, _pulseAnim]),
        builder: (context, _) {
          return Transform.scale(
            scale: _pulseAnim.value,
            child: SizedBox(width: 300, height: 300, child: CustomPaint(painter: _ScanCirclePainter(state: _scanState, scanProgress: _scanLineAnim.value))),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios, color: Colors.white)),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('ĐĂNG KÝ KHUÔN MẶT', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  Text(widget.employeeName, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomGuide() {
    final color = _getStateColor();
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: Icon(_getStateIcon(), key: ValueKey(_scanState), color: color, size: 32)),
              const SizedBox(height: 12),
              AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: Text(_guideText, key: ValueKey(_guideText), style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
              const SizedBox(height: 8),
              Text(_getSubText(), style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 80),
            SizedBox(height: 16),
            Text('Đăng ký thành công!', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Khuôn mặt đã được lưu vào hệ thống', style: TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Color _getStateColor() {
    switch (_scanState) {
      case FaceScanState.success: return const Color(0xFF00E676);
      case FaceScanState.failed: return const Color(0xFFFF5252);
      case FaceScanState.waitingBlink: return const Color(0xFFFFD740);
      case FaceScanState.processing: return const Color(0xFF40C4FF);
      default: return Colors.white;
    }
  }

  IconData _getStateIcon() {
    switch (_scanState) {
      case FaceScanState.success: return Icons.check_circle;
      case FaceScanState.failed: return Icons.error;
      case FaceScanState.waitingBlink: return Icons.remove_red_eye;
      case FaceScanState.processing: return Icons.autorenew;
      case FaceScanState.detected: return Icons.face;
      default: return Icons.search;
    }
  }

  String _getSubText() {
    switch (_scanState) {
      case FaceScanState.waitingBlink: return 'Nháy mắt để xác nhận bạn là người thật';
      case FaceScanState.processing: return 'AI đang phân tích khuôn mặt của bạn...';
      case FaceScanState.success: return 'Dữ liệu đã được gửi lên hệ thống';
      default: return 'Giữ khuôn mặt thẳng, đủ ánh sáng';
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _scanLineController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}

class FaceOverlayPainter extends CustomPainter {
  final double circleRadius;
  final Color overlayColor;
  FaceOverlayPainter({required this.circleRadius, required this.overlayColor});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height))..addOval(Rect.fromCircle(center: center, radius: circleRadius))..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, Paint()..color = overlayColor);
  }
  @override
  bool shouldRepaint(FaceOverlayPainter old) => old.circleRadius != circleRadius || old.overlayColor != overlayColor;
}

class _ScanCirclePainter extends CustomPainter {
  final FaceScanState state;
  final double scanProgress;
  _ScanCirclePainter({required this.state, required this.scanProgress});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final color = state == FaceScanState.success ? const Color(0xFF00E676) : state == FaceScanState.failed ? const Color(0xFFFF5252) : state == FaceScanState.waitingBlink ? const Color(0xFFFFD740) : const Color(0xFF40C4FF);
    final dashPaint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.5;
    const dashCount = 24;
    for (int i = 0; i < dashCount; i++) { canvas.drawArc(Rect.fromCircle(center: center, radius: radius), i * (2 * 3.14159 / dashCount), (2 * 3.14159 / dashCount) * 0.7, false, dashPaint); }
    if (state == FaceScanState.searching || state == FaceScanState.detected || state == FaceScanState.waitingBlink) {
      final scanY = center.dy - radius + (size.height - 8) * scanProgress;
      canvas.save();
      canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius)));
      canvas.drawRect(Rect.fromLTWH(center.dx - radius, scanY - 1, radius * 2, 2), Paint()..shader = LinearGradient(colors: [color.withOpacity(0), color.withOpacity(0.6), color.withOpacity(0)]).createShader(Rect.fromLTWH(0, scanY - 1, size.width, 2)));
      canvas.restore();
    }
  }
  @override
  bool shouldRepaint(_ScanCirclePainter old) => old.scanProgress != scanProgress || old.state != state;
}
