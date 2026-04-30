import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../services/face_id_service.dart';
import 'face_overlay_painter.dart';

class FaceRegistrationScreen extends StatefulWidget {
  final int employeeId;
  final String employeeName;
  final Future<void> Function(List<double> embedding) onSuccess;

  const FaceRegistrationScreen({super.key, required this.employeeId, required this.employeeName, required this.onSuccess});

  @override
  State<FaceRegistrationScreen> createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen> with TickerProviderStateMixin {
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

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _scanLineAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut));
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    final front = _cameras!.firstWhere((c) => c.lensDirection == CameraLensDirection.front);
    _cameraController = CameraController(front, ResolutionPreset.high, enableAudio: false, imageFormatGroup: ImageFormatGroup.nv21);
    await _cameraController!.initialize();
    _cameraController!.startImageStream(_onCameraFrame);
    setState(() => _isCameraReady = true);
  }

  void _onCameraFrame(CameraImage image) async {
    if (_isProcessingFrame || _hasRegistered) return;
    _isProcessingFrame = true;
    try {
      final faceInfo = await FaceIdService.instance.detectFaceFromCameraImage(image, InputImageRotation.rotation270deg);
      if (faceInfo == null) {
        _updateState(FaceScanState.searching, 'Đưa khuôn mặt vào khung');
      } else if (faceInfo.isBlinking && _scanState == FaceScanState.waitingBlink) {
        _updateState(FaceScanState.capturing, 'Đang chụp...');
        _captureAndRegister();
      } else {
        _lastDetected = faceInfo;
        _updateState(FaceScanState.waitingBlink, 'Vui lòng nháy mắt');
      }
    } finally { _isProcessingFrame = false; }
  }

  Future<void> _captureAndRegister() async {
    _hasRegistered = true;
    await _cameraController!.stopImageStream();
    final xFile = await _cameraController!.takePicture();
    final bytes = await xFile.readAsBytes();
    final embedding = await FaceIdService.instance.extractEmbedding(bytes, _lastDetected!.face.boundingBox);
    await widget.onSuccess(embedding);
    _updateState(FaceScanState.success, 'Đăng ký thành công!');
  }

  void _updateState(FaceScanState state, String guide) {
    if (mounted) setState(() { _scanState = state; _guideText = guide; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_isCameraReady) Transform.scale(scaleX: -1, child: CameraPreview(_cameraController!)),
          CustomPaint(painter: FaceOverlayPainter(circleRadius: 150, overlayColor: Colors.black.withOpacity(0.6))),
          Center(child: Text(_guideText, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
          if (_scanState == FaceScanState.success) const Center(child: Icon(Icons.check_circle, color: Colors.green, size: 100)),
        ],
      ),
    );
  }

  @override
  void dispose() { _cameraController?.dispose(); _scanLineController.dispose(); super.dispose(); }
}
