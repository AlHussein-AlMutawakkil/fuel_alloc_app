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
  bool _micEnabled = false;
  bool _cameraEnabled = true;
  bool _photosEnabled = true;
  bool _contactsEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkContactsPermission();
  }

  Future<void> _checkContactsPermission() async {
    try {
      final granted = await FlutterContacts.requestPermission(readonly: true);
      if (mounted) {
        setState(() => _contactsEnabled = granted);
      }
    } catch (_) {}
  }

  Widget _buildPermissionRow({
    required IconData icon,
    required String title,
    required bool isEnabled,
    required ValueChanged<bool> onChanged,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          onChanged(!isEnabled);
        },
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
                icon: AppIcons.mic,
                title: AppStrings.micPermission,
                isEnabled: _micEnabled,
                onChanged: (val) => setState(() => _micEnabled = val),
              ),
              _buildPermissionRow(
                icon: AppIcons.camera,
                title: AppStrings.cameraPermission,
                isEnabled: _cameraEnabled,
                onChanged: (val) => setState(() => _cameraEnabled = val),
              ),
              _buildPermissionRow(
                icon: AppIcons.photos,
                title: AppStrings.photosPermission,
                isEnabled: _photosEnabled,
                onChanged: (val) => setState(() => _photosEnabled = val),
              ),
              _buildPermissionRow(
                icon: AppIcons.contacts,
                title: AppStrings.contactsPermission,
                isEnabled: _contactsEnabled,
                onChanged: (val) async {
                  try {
                    final granted = await FlutterContacts.requestPermission(
                        readonly: true);
                    if (!mounted || !context.mounted) return;
                    setState(() => _contactsEnabled = granted);
                    if (granted) {
                      AppSnackBar.showSuccess(
                          context, AppStrings.operationSuccess);
                    } else {
                      AppSnackBar.showError(
                          context, AppStrings.contactsPermissionDenied);
                    }
                  } catch (e) {
                    if (!mounted || !context.mounted) return;
                    AppSnackBar.showError(
                        context, AppStrings.operationFailed);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
