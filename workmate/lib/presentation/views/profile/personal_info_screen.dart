import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmate/data/repositories/api_service.dart';
import 'package:workmate/core/constants/app_colors.dart';
import 'package:workmate/core/utils/date_utils.dart';
import 'package:workmate/presentation/viewmodels/viewmodels.dart';
import 'package:workmate/core/i18n/app_translations.dart';
import 'package:workmate/core/services/upload_service.dart';
import 'dart:io';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  bool _isUploading = false;

  Future<void> _changeAvatar(BuildContext context, ProfileViewModel vm) async {
    final File? image = await UploadService.pickImage();
    if (image == null) return;

    setState(() => _isUploading = true);

    final result = await UploadService.uploadImage(image);
    if (result.success && result.url != null && mounted) {
      final success = await vm.updateAvatar(vm.user!.id.toString(), result.url!);
      if (success && mounted) {
        context.read<HomeViewModel>().updateUserAvatar(result.url!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật ảnh đại diện thành công!')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi cập nhật CSDL sau khi upload')),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${result.error}')),
      );
    }

    if (mounted) setState(() => _isUploading = false);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().fetchUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    final user = vm.user;
    final lang = vm.selectedLanguage;

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    String t(String key) => AppTranslations.getText(lang, key);

    // Xử lý URL ảnh (nếu là đường dẫn tương đối thì thêm base url)
    String avatarUrl = user.avatarUrl;
    if (avatarUrl.isNotEmpty && !avatarUrl.startsWith('http')) {
      avatarUrl = '${ApiService.baseHost}$avatarUrl';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(t('personal_profile'), 
          style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Top Profile Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.primarySurface,
                        backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl.isEmpty 
                          ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                              style: const TextStyle(fontFamily: 'Nunito', fontSize: 40, fontWeight: FontWeight.w800, color: AppColors.primary))
                          : null,
                      ),
                      if (_isUploading)
                        const Positioned.fill(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _changeAvatar(context, vm),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(user.name, style: const TextStyle(fontFamily: 'Nunito', fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(10)),
                    child: Text(user.employeeCode, style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(label: t('department'), value: user.departmentName),
                      Container(width: 1, height: 30, color: AppColors.divider),
                      _StatItem(label: t('position'), value: user.position),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Detailed Info
            _InfoSection(
              title: t('personal_info'),
              items: [
                _InfoRow(icon: Icons.email_rounded, label: t('email'), value: user.email),
                _InfoRow(icon: Icons.phone_rounded, label: t('phone'), value: user.phone),
                _InfoRow(icon: Icons.cake_rounded, label: 'Ngày sinh', value: AppDateUtils.formatDate(user.birthday)),
                _InfoRow(icon: Icons.business_rounded, label: t('company'), value: context.watch<HomeViewModel>().companyConfig?.companyName ?? 'QUẬN 12'),
                _InfoRow(icon: Icons.calendar_today_rounded, label: t('join_date'), value: AppDateUtils.formatDate(user.joinDate)),
              ],
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(fontFamily: 'Nunito', fontSize: 11, color: AppColors.textSecondary)),
  ]);
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _InfoSection({required this.title, required this.items});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: AppColors.cardShadow),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 1)),
        const SizedBox(height: 12),
        ...items,
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontFamily: 'Nunito', fontSize: 11, color: AppColors.textSecondary)),
              Text(value, style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    ),
  );
}
