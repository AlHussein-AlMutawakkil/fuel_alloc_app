import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/one_ui_card.dart';

/// واجهة إدارة الأذونات بنمط One UI
class PermissionsSettingsView extends StatefulWidget {
  const PermissionsSettingsView({super.key});

  @override
  State<PermissionsSettingsView> createState() =>
      _PermissionsSettingsViewState();
}

class _PermissionsSettingsViewState extends State<PermissionsSettingsView>
    with WidgetsBindingObserver {
  bool _contactsEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  /// التحقق الصامت والمباشر من النظام لحالة الإذن دون إظهار أي نافذة مطالبة
  Future<void> _checkPermission() async {
    try {
      final status = await Permission.contacts.status;
      if (mounted) {
        setState(() => _contactsEnabled = status.isGranted);
      }
    } catch (_) {}
  }

  Widget _buildPermissionRow({
    required IconData icon,
    required String title,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space2XL,
            vertical: AppDimensions.spaceXL,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: AppColors.textPrimary,
                size: AppDimensions.iconMedium + 2,
              ),
              const SizedBox(width: AppDimensions.spaceL + 2),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppTypography.sizeH2,
                    fontWeight: AppTypography.weightMedium,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                isEnabled
                    ? AppIcons.checkCircleRounded
                    : AppIcons.cancelRounded,
                color: isEnabled ? AppColors.success : AppColors.textMuted,
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handlePermissionRequest() async {
    try {
      final status = await Permission.contacts.status;
      if (status.isGranted) {
        // إذا كان مفعل مسبقاً، فتح إعدادات التطبيق في الهاتف لإدارته
        await openAppSettings();
        return;
      }

      final res = await Permission.contacts.request();
      if (!mounted) return;
      setState(() => _contactsEnabled = res.isGranted);
      if (res.isGranted) {
        AppSnackBar.showSuccess(context, AppStrings.operationSuccess);
      } else if (res.isPermanentlyDenied) {
        await openAppSettings();
      } else {
        AppSnackBar.showError(context, AppStrings.contactsPermissionDenied);
      }
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.showError(context, AppStrings.operationFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const OneUiAppBar(
        title: AppStrings.permissionsTitle,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.spaceXL,
        ),
        children: [
          OneUiCard(
            children: [
              _buildPermissionRow(
                icon: AppIcons.contacts,
                title: AppStrings.contactsPermission,
                isEnabled: _contactsEnabled,
                onTap: _handlePermissionRequest,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
