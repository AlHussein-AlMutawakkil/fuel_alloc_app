import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/custom_dialog.dart';
import '../../core/widgets/one_ui_card.dart';
import '../data/fuel_types_view.dart';
import '../data/units_view.dart';
import 'language_settings_view.dart';
import 'permissions_settings_view.dart';
import 'theme_settings_view.dart';

/// واجهة الإعدادات بنمط One UI مطابقة للقطات الشاشة
class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  void _showUnderDevelopmentSnackBar(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title (تحت التطوير)'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.local_gas_station, color: Color(0xFF102A43), size: 28),
            SizedBox(width: 10),
            Text('نظام مخصصات الوقود', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الإصدار: 1.0.0 (رسمي)', style: TextStyle(fontSize: 14, color: Color(0xFF475569))),
            SizedBox(height: 8),
            Text(
              'نظام متكامل لإدارة ومحاسبة مخصصات واعتمادات الوقود ومطابقة كشوفات الحسابات والمحطات بدقة وموثوقية.',
              style: TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF1E293B)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() async {
    final confirm = await CustomDialog.showConfirmation(
      context: context,
      title: 'تسجيل الخروج',
      message: 'هل تريد حقاً تسجيل الخروج من التطبيق؟',
      confirmText: 'تسجيل الخروج',
      cancelText: 'إلغاء',
      isDanger: true,
    );
    if (confirm && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تسجيل الخروج بنجاح'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f8f8),
      appBar: const OneUiAppBar(
        title: AppStrings.settingsTitle,
        showBackButton: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        children: [
          // 1. كرت الملف الشخصي للمستخدم
          OneUiCard(
            children: [
              OneUiTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E293B),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.face_retouching_natural,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                title: AppStrings.profileTitle,
                subtitle: AppStrings.editProfile,
                onTap: () => _showUnderDevelopmentSnackBar(AppStrings.editProfile),
              ),
            ],
          ),

          // 2. كرت الحساب
          OneUiCard(
            children: [
              OneUiTile(
                leading: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF0F172A),
                  size: 22,
                ),
                title: AppStrings.account,
                valueText: 'alhossenail776472265...',
                onTap: () => _showUnderDevelopmentSnackBar(AppStrings.account),
              ),
            ],
          ),

          // 3. كرت البيانات (الأصناف والوحدات) بديلاً عن الاشتراك والاستخدام
          OneUiCard(
            children: [
              OneUiTile(
                leading: const Icon(
                  Icons.category_outlined,
                  color: Color(0xFF0F172A),
                  size: 22,
                ),
                title: AppStrings.dataFuelTypes,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FuelTypesView()),
                  );
                },
              ),
              OneUiTile(
                leading: const Icon(
                  Icons.straighten,
                  color: Color(0xFF0F172A),
                  size: 22,
                ),
                title: AppStrings.dataUnits,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UnitsView()),
                  );
                },
              ),
            ],
          ),

          // 4. كرت المظهر واللغة
          OneUiCard(
            children: [
              OneUiTile(
                leading: const Icon(
                  Icons.wb_sunny_outlined,
                  color: Color(0xFF0F172A),
                  size: 22,
                ),
                title: AppStrings.theme,
                valueText: AppStrings.themeLight,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ThemeSettingsView()),
                  );
                },
              ),
              OneUiTile(
                leading: const Icon(
                  Icons.language,
                  color: Color(0xFF0F172A),
                  size: 22,
                ),
                title: AppStrings.appLanguage,
                valueText: 'Arabic (Arabic)',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LanguageSettingsView()),
                  );
                },
              ),
            ],
          ),

          // 5. كرت الأذونات وحول التطبيق
          OneUiCard(
            children: [
              OneUiTile(
                leading: const Icon(
                  Icons.security_outlined,
                  color: Color(0xFF0F172A),
                  size: 22,
                ),
                title: AppStrings.permissionsManagement,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PermissionsSettingsView()),
                  );
                },
              ),
              OneUiTile(
                leading: const Icon(
                  Icons.info_outline,
                  color: Color(0xFF0F172A),
                  size: 22,
                ),
                title: AppStrings.aboutApp,
                onTap: _showAboutDialog,
              ),
            ],
          ),

          // 6. كرت تسجيل الخروج
          OneUiCard(
            children: [
              OneUiTile(
                leading: const Icon(
                  Icons.logout,
                  color: Color(0xFFB91C1C),
                  size: 22,
                ),
                title: AppStrings.logout,
                titleColor: const Color(0xFFB91C1C),
                onTap: _confirmLogout,
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
