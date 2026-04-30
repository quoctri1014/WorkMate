import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../services/face_id_service.dart';
import 'face_overlay_painter.dart';

class FaceCheckinScreen extends StatefulWidget {
  final Future<List<double>?> Function() fetchSavedEmbedding;
  final Future<void> Function(FaceMatchResult result) onCheckinSuccess;

  const FaceCheckinScreen({super.key, required this.fetchSavedEmbedding, required this.onCheckinSuccess});

  @override
  State<FaceCheckinScreen> createState() => _FaceCheckinScreenState();
}

class _FaceCheckinScreenState extends State<FaceCheckinScreen> with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraReady = false;
  FaceScanState _scanState = FaceScanState.searching;
  String _guideText = 'Đưa khuôn mặt vào khung';
  DetectedFaceInfo? _lastDetected;
  bool _isProcessingFrame = false;
  bool _isDone = false;
  int _stableFrameCount = 0;

  @override
  void initState() {
    super.initState();
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
    if (_isProcessingFrame || _isDone) return;
    _isProcessingFrame = true;
    try {
      final faceInfo = await FaceIdService.instance.detectFaceFromCameraImage(image, InputImageRotation.rotation270deg);
      if (faceInfo != null && faceInfo.isCentered) {
        _stableFrameCount++;
        if (_stableFrameCount >= 5) {
          _stableFrameCount = 0;
          _lastDetected = faceInfo;
          _captureAndCompare();
        }
      } else {
        _stableFrameCount = 0;
        _updateState(FaceScanState.searching, 'Đưa khuôn mặt vào khung');
      }
    } finally { _isProcessingFrame = false; }
  }

  Future<void> _captureAndCompare() async {
    _isDone = true;
    await _cameraController!.stopImageStream();
    _updateState(FaceScanState.processing, 'Đang nhận diện...');
    final xFile = await _cameraController!.takePicture();
    final bytes = await xFile.readAsBytes();
    final currentEmbedding = await FaceIdService.instance.extractEmbedding(bytes, _lastDetected!.face.boundingBox);
    final savedEmbedding = await widget.fetchSavedEmbedding();
    
    if (savedEmbedding != null) {
      final result = FaceIdService.instance.compareFaces(currentEmbedding, savedEmbedding);
      if (result.isMatch) {
        _updateState(FaceScanState.success, 'Thành công!');
        await widget.onCheckinSuccess(result);
      } else {
        _updateState(FaceScanState.failed, 'Không khớp!');
        Future.delayed(const Duration(seconds: 2), () {
          _isDone = false;
          _cameraController?.startImageStream(_onCameraFrame);
        });
      }
    }
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
          CustomPaint(painter: FaceOverlayPainter(circleRadius: 140, overlayColor: Colors.black.withOpacity(0.55))),
          Center(child: Text(_guideText, style: const TextStyle(color: Colors.white, fontSize: 18))),
        ],
      ),
    );
  }

  @override
  void dispose() { _cameraController?.dispose(); super.dispose(); }
}
