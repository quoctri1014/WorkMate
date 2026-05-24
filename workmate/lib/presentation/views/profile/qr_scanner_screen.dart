import 'dart:convert';
import \'package:easy_localization/easy_localization.dart\';
import \'package:easy_localization/easy_localization.dart\';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:workmate/core/constants/app_colors.dart';
import 'package:workmate/data/repositories/api_service.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _hasScanned = false;
  Map<String, String>? _scannedInfo;
  String? _rawData;

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() {
      _hasScanned = true;
      _rawData = rawValue;
      _scannedInfo = _parseQRData(rawValue);
    });
  }

  /// Parse dữ liệu QR dạng "KEY: VALUE" mỗi dòng
  Map<String, String> _parseQRData(String data) {
    final result = <String, String>{};
    // Thử parse JSON trước
    try {
      final json = jsonDecode(data);
      if (json is Map) {
        json.forEach((k, v) => result[k.toString()] = v.toString());
        return result;
      }
    } catch (_) {}

    // Parse dạng text "KEY: VALUE"
    for (var line in data.split('\n')) {
      line = line.trim();
      if (line.isEmpty) continue;
      final idx = line.indexOf(':');
      if (idx > 0) {
        final key = line.substring(0, idx).trim();
        final value = line.substring(idx + 1).trim();
        result[key] = value;
      }
    }
    return result;
  }

  void _resetScan() {
    setState(() {
      _hasScanned = false;
      _scannedInfo = null;
      _rawData = null;
    });
  }

  void _openChatWithEmployee() {
    if (_scannedInfo == null) return;
    final name = _scannedInfo!['HỌ TÊN'] ?? _scannedInfo!['name'] ?? 'Đồng nghiệp';
    final code = _scannedInfo!['MÃ NV'] ?? _scannedInfo!['employee_code'] ?? '';

    // Hiển thị dialog nhắn tin nhanh
    final textController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primarySurface,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nhắn tin cho $name', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                    if (code.isNotEmpty)
                      Text('Mã NV: $code', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5)),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    final msg = textController.text.trim();
                    if (msg.isEmpty) return;
                    // TODO: Gửi tin nhắn qua API / Socket
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã gửi tin nhắn cho $name!'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                  child: Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primary.withBlue(200)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Quét mã QR', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          if (_hasScanned)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _resetScan,
              tooltip: 'Quét lại',
            ),
        ],
      ),
      body: Stack(
        children: [
          // Camera view
          if (!_hasScanned)
            MobileScanner(onDetect: _onDetect),

          // QR frame overlay (khi chưa quét)
          if (!_hasScanned) ...[
            Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 3),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Hướng camera vào mã QR của đồng nghiệp',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],

          // Kết quả quét — Thẻ thông tin nhân viên
          if (_hasScanned && _scannedInfo != null)
            _buildResultView(),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    final info = _scannedInfo!;
    final name = info['HỌ TÊN'] ?? info['name'] ?? 'Không rõ';
    final code = info['MÃ NV'] ?? info['employee_code'] ?? '';
    final dept = info['BỘ PHẬN'] ?? info['department'] ?? '';
    final position = info['CHỨC VỤ'] ?? info['position'] ?? '';
    final phone = info['SỐ ĐIỆN THOẠI'] ?? info['phone'] ?? '';
    final email = info['EMAIL'] ?? info['email'] ?? '';
    final company = info['CÔNG TY'] ?? info['company'] ?? '';
    final birthday = info['NGÀY SINH'] ?? '';
    final joinDate = info['NGÀY VÀO LÀM'] ?? '';

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Avatar + Name card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primary.withBlue(200)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: Theme.of(context).brightness == Brightness.dark ? null : [
                    BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white24,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                    if (code.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(code, style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    if (company.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(company, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Info card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: Theme.of(context).brightness == Brightness.dark ? null : [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(tr('detailed_information'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87)),
                    const SizedBox(height: 16),
                    if (dept.isNotEmpty) _buildInfoRow(Icons.business_rounded, tr('department_label'), dept.tr()),
                    if (position.isNotEmpty) _buildInfoRow(Icons.work_rounded, tr('position_label'), position.tr()),
                    if (phone.isNotEmpty) _buildInfoRow(Icons.phone_rounded, tr('phone_label'), phone),
                    if (email.isNotEmpty) _buildInfoRow(Icons.email_rounded, tr('email_label'), email),
                    if (birthday.isNotEmpty) _buildInfoRow(Icons.cake_rounded, tr('birthday'), birthday),
                    if (joinDate.isNotEmpty) _buildInfoRow(Icons.calendar_month_rounded, 'Ngày vào làm', joinDate),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _openChatWithEmployee,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primary.withBlue(200)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text('Nhắn tin', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _resetScan,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code_scanner_rounded, color: Colors.grey.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text('Quét lại', style: TextStyle(color: Colors.grey.shade700, fontSize: 15, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }
}
