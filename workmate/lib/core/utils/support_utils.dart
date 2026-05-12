import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:workmate/core/constants/app_colors.dart';

class SupportUtils {
  static const String supportPhone = '0918720115';
  static const String supportEmail = 'quoctri1014@gmail.com';

  static void showSupportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(28, 12, 28, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Liên hệ hỗ trợ',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chúng tôi luôn sẵn sàng hỗ trợ bạn',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            _SupportOption(
              icon: Icons.phone_forwarded_rounded,
              color: const Color(0xFF4CAF50),
              title: 'Gọi tổng đài hỗ trợ',
              subtitle: supportPhone,
              onTap: () async {
                Navigator.pop(ctx);
                final Uri url = Uri.parse('tel:$supportPhone');
                await launchUrl(url, mode: LaunchMode.externalApplication);
              },
            ),
            const SizedBox(height: 12),
            _SupportOption(
              icon: Icons.mail_outline_rounded,
              color: const Color(0xFF2196F3),
              title: 'Gửi Email yêu cầu',
              subtitle: supportEmail,
              onTap: () async {
                Navigator.pop(ctx);
                final Uri url = Uri.parse('mailto:$supportEmail?subject=Hỗ trợ WorkMate');
                await launchUrl(url, mode: LaunchMode.externalApplication);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SupportOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}
