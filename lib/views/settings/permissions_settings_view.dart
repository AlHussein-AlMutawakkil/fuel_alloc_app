import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_strings.dart';
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
  bool _photosEnabled = false;
  bool _cameraEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  /// التحقق الصامت والمباشر من النظام لحالة كافة الأذونات
  Future<void> _checkPermissions() async {
    try {
      final contactsStatus = await Permission.contacts.status;
      final cameraStatus = await Permission.camera.status;

      // الصور: التحقق من إذن photos أو storage
      bool photosGranted = false;
      if (Platform.isAndroid) {
        final photosStatus = await Permission.photos.status;
        final storageStatus = await Permission.storage.status;
        photosGranted = photosStatus.isGranted || storageStatus.isGranted;
      } else {
        final photosStatus = await Permission.photos.status;
        photosGranted = photosStatus.isGranted;
      }

      if (mounted) {
        setState(() {
          _contactsEnabled = contactsStatus.isGranted;
          _cameraEnabled = cameraStatus.isGranted;
          _photosEnabled = photosGranted;
        });
      }
    } catch (_) {}
  }

  Future<void> _handlePermissionRequest({
    required Permission permission,
    required String deniedMsg,
  }) async {
    try {
      final status = await permission.status;
      if (status.isGranted) {
        // إذا كان مفعلاً مسبقاً، فتح إعدادات التطبيق في الهاتف لإدارته
        await openAppSettings();
        return;
      }

      final res = await permission.request();
      await _checkPermissions();
      if (!mounted) return;
      if (res.isGranted) {
        AppSnackBar.showSuccess(context, AppStrings.operationSuccess);
      } else if (res.isPermanentlyDenied) {
        await openAppSettings();
      } else {
        AppSnackBar.showError(context, deniedMsg);
      }
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.showError(context, AppStrings.operationFailed);
    }
  }

  Future<void> _handlePhotosPermissionRequest() async {
    try {
      Permission perm = Permission.photos;
      final photosStatus = await Permission.photos.status;
      final storageStatus = await Permission.storage.status;
      if (photosStatus.isGranted || storageStatus.isGranted) {
        await openAppSettings();
        return;
      }

      // طلب الإذن المناسب
      var res = await perm.request();
      if (!res.isGranted && Platform.isAndroid) {
        res = await Permission.storage.request();
      }

      await _checkPermissions();
      if (!mounted) return;
      if (res.isGranted) {
        AppSnackBar.showSuccess(context, AppStrings.operationSuccess);
      } else if (res.isPermanentlyDenied) {
        await openAppSettings();
      } else {
        AppSnackBar.showError(context, AppStrings.photosPermissionDenied);
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
              OneUiTile(
                leading: const Icon(
                  AppIcons.photos,
                  color: AppColors.textPrimary,
                  size: AppDimensions.iconMedium + 2,
                ),
                title: AppStrings.photosPermission,
                trailing: Icon(
                  _photosEnabled
                      ? AppIcons.checkCircleRounded
                      : AppIcons.cancelRounded,
                  color:
                      _photosEnabled ? AppColors.success : AppColors.textMuted,
                  size: 18,
                ),
                onTap: _handlePhotosPermissionRequest,
              ),
              OneUiTile(
                leading: const Icon(
                  AppIcons.camera,
                  color: AppColors.textPrimary,
                  size: AppDimensions.iconMedium + 2,
                ),
                title: AppStrings.cameraPermission,
                trailing: Icon(
                  _cameraEnabled
                      ? AppIcons.checkCircleRounded
                      : AppIcons.cancelRounded,
                  color:
                      _cameraEnabled ? AppColors.success : AppColors.textMuted,
                  size: 18,
                ),
                onTap: () => _handlePermissionRequest(
                  permission: Permission.camera,
                  deniedMsg: AppStrings.cameraPermissionDenied,
                ),
              ),
              OneUiTile(
                leading: const Icon(
                  AppIcons.contacts,
                  color: AppColors.textPrimary,
                  size: AppDimensions.iconMedium + 2,
                ),
                title: AppStrings.contactsPermission,
                trailing: Icon(
                  _contactsEnabled
                      ? AppIcons.checkCircleRounded
                      : AppIcons.cancelRounded,
                  color: _contactsEnabled
                      ? AppColors.success
                      : AppColors.textMuted,
                  size: 18,
                ),
                onTap: () => _handlePermissionRequest(
                  permission: Permission.contacts,
                  deniedMsg: AppStrings.contactsPermissionDenied,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
