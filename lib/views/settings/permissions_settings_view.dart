import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
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

class _PermissionsSettingsViewState extends State<PermissionsSettingsView> {
  bool _contactsEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionSilently();
  }

  /// التحقق الصامت من حالة الإذن دون إظهار نافذة منبثقة للمستخدم
  Future<void> _checkPermissionSilently() async {
    try {
      // محاولة قراءة خفيفة، إذا كان الإذن ممنوحاً مسبقاً في النظام سيعيد جهات الاتصال بنجاح
      // وإذا لم يكن ممنوحاً سينتقل إلى catch دون إظهار أي نافذة مطالبة للمستخدم
      await FlutterContacts.getContacts(
        withProperties: false,
        withThumbnail: false,
        withPhoto: false,
      );
      if (mounted) {
        setState(() => _contactsEnabled = true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _contactsEnabled = false);
      }
    }
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
      final granted = await FlutterContacts.requestPermission(readonly: true);
      if (!mounted) return;
      setState(() => _contactsEnabled = granted);
      if (granted) {
        AppSnackBar.showSuccess(context, AppStrings.operationSuccess);
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
