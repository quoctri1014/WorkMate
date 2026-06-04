import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:workmate/core/constants/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:workmate/presentation/viewmodels/viewmodels.dart';
import 'package:workmate/core/utils/date_utils.dart';
import 'package:intl/intl.dart';
import 'qr_scanner_screen.dart';

class QRScreen extends StatelessWidget {
  const QRScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final homeVm = context.watch<HomeViewModel>();
    final user = homeVm.user;
    final companyName = homeVm.companyConfig?.companyName ?? 'QUẬN 12'.tr();

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_rounded, color: Theme.of(context).colorScheme.onSurface, size: 20), onPressed: () => Navigator.pop(context)),
        title: Text('Mã QR cá nhân', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface, fontSize: 17)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(24), boxShadow: Theme.of(context).brightness == Brightness.dark ? null : AppColors.cardShadow),
              child: Column(children: [
                Text(user.name, style: TextStyle(fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 4),
                Text(user.employeeCode, style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 20),
                QrImageView(data: qrData, version: QrVersions.auto, size: 200, backgroundColor: Colors.white, eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.black)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : AppColors.primarySurface, borderRadius: BorderRadius.circular(10)),
                  child: Text('Dùng để chấm công & xác thực', style: TextStyle(fontFamily: 'Nunito', fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? Colors.blue[300] : AppColors.primary, fontWeight: FontWeight.w600)),
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
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const QRScannerScreen()));
                },
                icon: Icon(Icons.qr_code_scanner_rounded, color: Theme.of(context).colorScheme.primary),
                label: Text('Quét mã QR đồng nghiệp', style: TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
