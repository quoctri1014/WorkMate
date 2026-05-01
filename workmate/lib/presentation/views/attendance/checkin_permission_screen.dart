import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmate/core/constants/app_colors.dart';
import 'checkin_face_screen.dart';

class CheckInPermissionScreen extends StatefulWidget {
  const CheckInPermissionScreen({super.key});

  @override
  State<CheckInPermissionScreen> createState() => _CheckInPermissionScreenState();
}

class _CheckInPermissionScreenState extends State<CheckInPermissionScreen> {
  bool _cameraGranted = false;
  bool _locationGranted = false;
  bool _wifiGranted = false;
  bool _galleryGranted = false;

  bool get _allGranted => _cameraGranted && _locationGranted && _wifiGranted && _galleryGranted;

  @override
  void initState() {
    super.initState();
    _checkCurrentPermissions();
  }

  Future<void> _checkCurrentPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final locationStatus = await Permission.location.status;
    final wifiStatus = await Permission.locationWhenInUse.status; // WiFi needs location
    final galleryStatus = await Permission.photos.status;

    setState(() {
      _cameraGranted = cameraStatus.isGranted;
      _locationGranted = locationStatus.isGranted;
      _wifiGranted = wifiStatus.isGranted;
      _galleryGranted = galleryStatus.isGranted || galleryStatus.isLimited;
    });
  }

  Future<void> _requestPermission(String type) async {
    PermissionStatus status;
    if (type == 'camera') {
      status = await Permission.camera.request();
      if (status.isGranted) setState(() => _cameraGranted = true);
    } else if (type == 'location') {
      status = await Permission.location.request();
      if (status.isGranted) setState(() => _locationGranted = true);
    } else if (type == 'wifi') {
      status = await Permission.locationWhenInUse.request();
      if (status.isGranted) setState(() => _wifiGranted = true);
    } else if (type == 'gallery') {
      status = await Permission.photos.request();
      if (status.isGranted || status.isLimited) setState(() => _galleryGranted = true);
    }
    
    // Nếu bị từ chối vĩnh viễn mới nhắc mở Settings
    if (await Permission.camera.isPermanentlyDenied || 
        await Permission.location.isPermanentlyDenied) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Cần quyền hệ thống'),
            content: const Text('Quyền này đã bị từ chối vĩnh viễn. Vui lòng mở Cài đặt để cấp quyền thủ công.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('HỦY')),
              TextButton(onPressed: () {
                openAppSettings();
                Navigator.pop(ctx);
              }, child: const Text('CÀI ĐẶT')),
            ],
          ),
        );
      }
    }
  }

  Future<void> _onContinue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('permissions_granted', true);
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CheckInFaceScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text('Cấp quyền ứng dụng', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text('Để WorkMate hoạt động chính xác, vui lòng cấp các quyền sau:', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 32),
              
              _PermissionItem(icon: Icons.camera_alt_rounded, label: 'Camera', sub: 'Sử dụng cho Face ID', isOk: _cameraGranted, onTap: () => _requestPermission('camera')),
              _PermissionItem(icon: Icons.location_on_rounded, label: 'Vị trí GPS', sub: 'Xác định phạm vi làm việc', isOk: _locationGranted, onTap: () => _requestPermission('location')),
              _PermissionItem(icon: Icons.wifi_rounded, label: 'WiFi/Mạng', sub: 'Xác thực mạng nội bộ', isOk: _wifiGranted, onTap: () => _requestPermission('wifi')),
              _PermissionItem(icon: Icons.photo_library_rounded, label: 'Thư viện ảnh', sub: 'Tải minh chứng báo nghỉ', isOk: _galleryGranted, onTap: () => _requestPermission('gallery')),

              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _allGranted ? _onContinue : null,
                  child: const Text('TIẾP TỤC'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final bool isOk;
  final VoidCallback onTap;
  const _PermissionItem({required this.icon, required this.label, required this.sub, required this.isOk, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: isOk ? AppColors.successLight : AppColors.background, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: isOk ? AppColors.success : AppColors.primary)),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 11)),
      trailing: isOk ? const Icon(Icons.check_circle_rounded, color: AppColors.success) : TextButton(onPressed: onTap, child: const Text('Cấp phép')),
    );
  }
}
