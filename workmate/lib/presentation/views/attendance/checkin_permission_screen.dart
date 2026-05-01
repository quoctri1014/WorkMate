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
  bool _notificationGranted = false;

  bool get _allGranted => _cameraGranted && _locationGranted && _wifiGranted && _galleryGranted && _notificationGranted;

  @override
  void initState() {
    super.initState();
    _checkCurrentPermissions();
  }

  Future<void> _checkCurrentPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final locationStatus = await Permission.location.status;
    final wifiStatus = await Permission.locationWhenInUse.status; 
    final galleryStatus = await Permission.photos.status;
    final notificationStatus = await Permission.notification.status;

    setState(() {
      _cameraGranted = cameraStatus.isGranted;
      _locationGranted = locationStatus.isGranted;
      _wifiGranted = wifiStatus.isGranted;
      _galleryGranted = galleryStatus.isGranted || galleryStatus.isLimited;
      _notificationGranted = notificationStatus.isGranted;
    });
  }

  Future<void> _requestPermission(String type) async {
    PermissionStatus status;
    if (type == 'camera') {
      status = await Permission.camera.request();
    } else if (type == 'location') {
      status = await Permission.location.request();
    } else if (type == 'wifi') {
      status = await Permission.locationWhenInUse.request();
    } else if (type == 'gallery') {
      status = await Permission.photos.request();
    } else if (type == 'notification') {
      status = await Permission.notification.request();
    } else {
      return;
    }
    
    // Luôn cập nhật lại trạng thái sau khi yêu cầu
    await _checkCurrentPermissions();
    
    // Nếu bị từ chối vĩnh viễn (người dùng đã bấm "Không cho phép" 2 lần) mới nhắc mở Settings
    if (status.isPermanentlyDenied && mounted) {
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
              _PermissionItem(icon: Icons.notifications_active_rounded, label: 'Thông báo', sub: 'Nhận tin nhắn, cập nhật mới', isOk: _notificationGranted, onTap: () => _requestPermission('notification')),

              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _allGranted ? _onContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _allGranted ? AppColors.primary : Colors.grey[300],
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('TIẾP TỤC', style: TextStyle(color: _allGranted ? Colors.white : Colors.grey[600], fontWeight: FontWeight.bold)),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isOk ? AppColors.successLight.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isOk ? AppColors.success.withOpacity(0.2) : Colors.grey[200]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isOk ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isOk ? AppColors.successLight : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: isOk ? AppColors.success : AppColors.primary, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                isOk 
                  ? const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24)
                  : Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
