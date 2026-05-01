import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:workmate/core/constants/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:workmate/presentation/viewmodels/viewmodels.dart';
import 'package:workmate/core/utils/date_utils.dart';
import 'package:intl/intl.dart';

class QRScreen extends StatelessWidget {
  const QRScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final homeVm = context.watch<HomeViewModel>();
    final user = homeVm.user;
    final companyName = homeVm.companyConfig?.companyName ?? 'QUẬN 12';

    if (user == null) return const Scaffold(body: Center(child: Text('Không tìm thấy thông tin')));

    final qrData = '''
CÔNG TY: $companyName
HỌ TÊN: ${user.name}
MÃ NV: ${user.employeeCode}
NGÀY SINH: ${AppDateUtils.formatDate(user.birthday)}
BỘ PHẬN: ${user.departmentName}
CHỨC VỤ: ${user.position}
SỐ ĐIỆN THOẠI: ${user.phone}
EMAIL: ${user.email}
NGÀY VÀO LÀM: ${AppDateUtils.formatDate(user.joinDate)}
''';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary, size: 20), onPressed: () => Navigator.pop(context)),
        title: const Text('Mã QR cá nhân', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 17)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: AppColors.cardShadow),
              child: Column(children: [
                Text(user.name, style: const TextStyle(fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(user.employeeCode, style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 20),
                QrImageView(data: qrData, version: QrVersions.auto, size: 200, backgroundColor: Colors.white),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(10)),
                  child: const Text('Dùng để chấm công & xác thực', style: TextStyle(fontFamily: 'Nunito', fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
            const SizedBox(height: 28),
            SizedBox(width: double.infinity, height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: qrData));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã sao chép thông tin vào bộ nhớ tạm'), backgroundColor: AppColors.success));
                },
                icon: const Icon(Icons.copy_rounded, color: Colors.white),
                label: const Text('Sao chép thông tin', style: TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
