// ============================================================
// face_registration_screen.dart
// Màn hình ĐĂNG KÝ khuôn mặt (THẬT) - Hỗ trợ đa hướng (3 mẫu)
// ============================================================

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:workmate/services/face_id_service.dart';

enum RegistrationStep {
  center,
  left,
  right,
  done
}

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
  RegistrationStep _regStep = RegistrationStep.center;
  String _guideText = 'Đưa khuôn mặt vào khung';
  String _debugError = ''; // Lưu lỗi chi tiết để debug
  
  final List<List<double>> _capturedEmbeddings = [];
  DetectedFaceInfo? _lastDetected;

  bool _isProcessingFrame = false;
  bool _hasFinished = false;

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

    try {
      await FaceIdService.instance.initialize();
      
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        _updateState(FaceScanState.failed, 'Không tìm thấy camera');
        return;
      }
      
      CameraDescription? frontCamera;
      try {
        frontCamera = _cameras!.firstWhere((c) => c.lensDirection == CameraLensDirection.front);
      } catch (_) {
        frontCamera = _cameras!.first;
      }
      
      _cameraController = CameraController(
        frontCamera, 
        ResolutionPreset.medium, 
        enableAudio: false,
        imageFormatGroup: Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.yuv420,
      );
      
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() => _isCameraReady = true);
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      _cameraController!.startImageStream(_onCameraFrame);
    } catch (e, stack) {
      _handleError('Lỗi khởi tạo Camera', e, stack);
    }
  }

  void _onCameraFrame(CameraImage image) async {
    if (_isProcessingFrame || _hasFinished) return;
    if (_scanState == FaceScanState.processing || _scanState == FaceScanState.success) return;
    
    _isProcessingFrame = true;
    try {
      final rotation = _getRotation();
      final faceInfo = await FaceIdService.instance.detectFaceFromCameraImage(image, rotation);
      if (!mounted) return;
      
      if (faceInfo == null) {
        _updateState(FaceScanState.searching, _getStepGuide());
      } else if (faceInfo.isTooClose) {
        _updateState(FaceScanState.detected, 'Lùi ra xa hơn một chút');
      } else if (faceInfo.isTooFar) {
        _updateState(FaceScanState.detected, 'Lại gần hơn một chút');
      } else if (!faceInfo.isCentered) {
        _updateState(FaceScanState.detected, 'Đưa mặt vào giữa khung');
      } else {
        _lastDetected = faceInfo;
        
        double headY = faceInfo.face.headEulerAngleY ?? 0; 
        
        bool correctPos = false;
        if (_regStep == RegistrationStep.center) {
          correctPos = headY.abs() < 10;
          if (!correctPos) _updateState(FaceScanState.detected, 'Nhìn thẳng vào camera');
        } else if (_regStep == RegistrationStep.left) {
          correctPos = headY > 15; 
          if (!correctPos) _updateState(FaceScanState.detected, 'Nghiêng mặt sang TRÁI một chút');
        } else if (_regStep == RegistrationStep.right) {
          correctPos = headY < -15; 
          if (!correctPos) _updateState(FaceScanState.detected, 'Nghiêng mặt sang PHẢI một chút');
        }

        if (correctPos) {
          if (_scanState != FaceScanState.waitingBlink && _scanState != FaceScanState.capturing) {
            _updateState(FaceScanState.waitingBlink, 'Giữ nguyên và nháy mắt');
          } else if (faceInfo.isBlinking && _scanState == FaceScanState.waitingBlink) {
            _updateState(FaceScanState.capturing, 'Đang ghi nhận mẫu ${_capturedEmbeddings.length + 1}/3...');
            await _captureSample();
          }
        }
      }
    } catch (e, stack) {
      debugPrint('DEBUG_FACE_ERROR: $e\n$stack');
    } finally {
      _isProcessingFrame = false;
    }
  }

  String _getStepGuide() {
    switch (_regStep) {
      case RegistrationStep.center: return 'Nhìn thẳng vào khung';
      case RegistrationStep.left: return 'Nghiêng mặt sang TRÁI';
      case RegistrationStep.right: return 'Nghiêng mặt sang PHẢI';
      default: return '';
    }
  }

  Future<void> _captureSample() async {
    final controller = _cameraController;
    final lastFace = _lastDetected;
    
    if (controller == null || lastFace == null) return;
    
    try {
      await controller.stopImageStream();
      final xFile = await controller.takePicture();
      final imageBytes = await xFile.readAsBytes();
      
      final embedding = await FaceIdService.instance.extractEmbedding(imageBytes, lastFace.face.boundingBox);
      
      if (embedding.isNotEmpty) {
        _capturedEmbeddings.add(embedding);
      }

      if (_capturedEmbeddings.length < 3) {
        setState(() {
          if (_regStep == RegistrationStep.center) _regStep = RegistrationStep.left;
          else if (_regStep == RegistrationStep.left) _regStep = RegistrationStep.right;
        });
        
        _updateState(FaceScanState.searching, _getStepGuide());
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) controller.startImageStream(_onCameraFrame);
      } else {
        _regStep = RegistrationStep.done;
        await _finishRegistration();
      }
    } catch (e, stack) {
      _handleError('Lỗi chụp ảnh', e, stack);
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) controller.startImageStream(_onCameraFrame);
    }
  }

  Future<void> _finishRegistration() async {
    if (!mounted) return;
    _updateState(FaceScanState.processing, 'Đang tổng hợp dữ liệu gương mặt...');
    
    if (_capturedEmbeddings.isEmpty) {
      _updateState(FaceScanState.failed, 'Không có dữ liệu mẫu!');
      return;
    }

    try {
      List<List<double>> validEmbeddings = _capturedEmbeddings.where((e) => e.length == 192).toList();
      
      if (validEmbeddings.isEmpty) {
        _updateState(FaceScanState.failed, 'Dữ liệu không hợp lệ!');
        return;
      }

      List<double> finalEmbedding = List.filled(192, 0.0);
      for (var emb in validEmbeddings) {
        for (int i = 0; i < 192; i++) {
          finalEmbedding[i] += emb[i];
        }
      }
      for (int i = 0; i < 192; i++) {
        finalEmbedding[i] /= validEmbeddings.length;
      }

      await widget.onSuccess(finalEmbedding);
      
      if (mounted) {
        setState(() {
          _hasFinished = true;
          _scanState = FaceScanState.success;
          _guideText = 'Đăng ký thành công!';
        });
      }
    } catch (e, stack) {
      _handleError('Lỗi tổng hợp', e, stack);
    }
  }

  void _handleError(String title, Object e, StackTrace stack) {
    debugPrint('$title: $e\n$stack');
    if (!mounted) return;
    setState(() {
      _scanState = FaceScanState.failed;
      _guideText = '$title: $e';
      _debugError = stack.toString();
    });
  }

  void _updateState(FaceScanState state, String guide) {
    if (!mounted) return;
    setState(() { _scanState = state; _guideText = guide; _debugError = ''; });
  }

  InputImageRotation _getRotation() {
    if (_cameras == null || _cameras!.isEmpty) return InputImageRotation.rotation0deg;
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
          if (_isCameraReady && _cameraController != null)
            Center(
              child: CameraPreview(_cameraController!),
            ),
          _buildDarkOverlay(),
          _buildScanFrame(),
          _buildTopBar(),
          _buildStepIndicator(),
          _buildBottomGuide(),
          if (_debugError.isNotEmpty) _buildDebugErrorView(),
          if (_scanState == FaceScanState.success) _buildSuccessOverlay(),
        ],
      ),
    );
  }

  Widget _buildDebugErrorView() {
    return Positioned(
      bottom: 200, left: 20, right: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.red.withOpacity(0.9), borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('STACK TRACE:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                SelectableText(_debugError, style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace')),
              ],
            ),
          ),
        ),
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

  Widget _buildStepIndicator() {
    return Positioned(
      top: 120, left: 0, right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          bool isDone = index < _capturedEmbeddings.length;
          bool isCurrent = index == _capturedEmbeddings.length;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: isCurrent ? 40 : 10,
            height: 10,
            decoration: BoxDecoration(
              color: isDone ? const Color(0xFF00E676) : isCurrent ? const Color(0xFF40C4FF) : Colors.white24,
              borderRadius: BorderRadius.circular(5),
            ),
          );
        }),
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
                  const Text('ĐĂNG KÝ ĐA HƯỚNG', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
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
            Text('Hoàn tất!', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Hệ thống đã ghi nhớ các góc cạnh gương mặt bạn', style: TextStyle(color: Colors.white70, fontSize: 14)),
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
    switch (_regStep) {
      case RegistrationStep.center: return 'Bước 1: Nhìn thẳng trực diện';
      case RegistrationStep.left: return 'Bước 2: Nghiêng mặt sang Trái 15-30 độ';
      case RegistrationStep.right: return 'Bước 3: Nghiêng mặt sang Phải 15-30 độ';
      case RegistrationStep.done: return 'Đang xử lý dữ liệu...';
    }
    return '';
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
