import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmate/core/constants/app_colors.dart';
import 'package:workmate/presentation/viewmodels/viewmodels.dart';
import 'package:workmate/core/constants/app_routes.dart';
import 'change_password_screen.dart';
import 'qr_screen.dart';
import 'bank_account_screen.dart';
import 'package:workmate/presentation/views/profile/face_registration_screen.dart';
import 'package:workmate/core/i18n/app_translations.dart';
import 'package:workmate/core/utils/support_utils.dart';
import 'personal_info_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    final user = vm.user;
    final lang = vm.selectedLanguage;

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    String t(String key) => AppTranslations.getText(lang, key);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(t('settings'), style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Summary Header (Mini Profile Card)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primarySurface,
                    backgroundImage: (user.avatarUrl.isNotEmpty) 
                      ? NetworkImage(user.avatarUrl.startsWith('http') 
                          ? user.avatarUrl 
                          : 'http://10.0.2.2:5000${user.avatarUrl}') 
                      : null,
                    child: (user.avatarUrl.isEmpty) 
                      ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U', 
                          style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 20))
                      : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontSize: 16)),
                        Text(user.employeeCode, style: const TextStyle(fontFamily: 'Nunito', color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textSecondary),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalInfoScreen())),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _SectionHeader(title: t('account_management')),
            _SettingTile(
              icon: Icons.account_balance_rounded, color: AppColors.primary, label: t('bank_account'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BankAccountScreen())),
            ),
            _SettingTile(
              icon: Icons.face_retouching_natural_rounded, color: AppColors.success, label: t('face_id_security'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FaceRegistrationScreen(
                employeeId: user.id, employeeName: user.name, onSuccess: (emb) async { Navigator.pop(context); },
              ))),
            ),
            _SettingTile(
              icon: Icons.qr_code_rounded, color: AppColors.wsMeeting, label: t('qr_code'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QRScreen())),
            ),
            
            const SizedBox(height: 24),
            _SectionHeader(title: t('settings')),
            _SettingTile(
              icon: Icons.lock_outline_rounded, color: AppColors.error, label: t('change_password'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
            ),
            _SettingTile(
              icon: Icons.language_rounded, color: AppColors.info, label: t('language'),
              trailing: Text(lang == 'vi' ? 'Tiếng Việt' : 'English', style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 12)),
              onTap: () => _showLanguageDialog(context, vm),
            ),
            _SettingTile(
              icon: Icons.help_outline_rounded, color: AppColors.textSecondary, label: t('help'),
              onTap: () => SupportUtils.showSupportOptions(context),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton.icon(
                onPressed: () async {
                  context.read<NotificationViewModel>().clear();
                  await context.read<AuthViewModel>().logout();
                  if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
                },
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: Text(t('logout'), style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error.withOpacity(0.1),
                  foregroundColor: AppColors.error,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.error, width: 1)),
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, ProfileViewModel vm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Chọn ngôn ngữ / Select Language', style: TextStyle(fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 24),
          _LangOption(label: '🇻🇳  Tiếng Việt', isSelected: vm.selectedLanguage == 'vi', onTap: () { vm.setLanguage('vi'); Navigator.pop(context); }),
          const SizedBox(height: 12),
          _LangOption(label: '🇬🇧  English', isSelected: vm.selectedLanguage == 'en', onTap: () { vm.setLanguage('en'); Navigator.pop(context); }),
        ]),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 12),
    child: Text(title, style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 1)),
  );
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;
  const _SettingTile({required this.icon, required this.color, required this.label, this.trailing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 20, color: color)),
        title: Text(label, style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _LangOption({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity, padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primarySurface : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
      ),
      child: Row(children: [
        Text(label, style: TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: AppColors.textPrimary)),
        const Spacer(),
        if (isSelected) const Icon(Icons.check_circle_rounded, color: AppColors.primary),
      ]),
    ),
  );
}
