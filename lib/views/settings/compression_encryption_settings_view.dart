import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/backup_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/app_switch.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/one_ui_card.dart';

/// شاشة إعدادات الضغط والتشفير بنمط One UI مطابقة للقطة الشاشة الثانية
class CompressionEncryptionSettingsView extends StatefulWidget {
  const CompressionEncryptionSettingsView({super.key});

  @override
  State<CompressionEncryptionSettingsView> createState() =>
      _CompressionEncryptionSettingsViewState();
}

class _CompressionEncryptionSettingsViewState
    extends State<CompressionEncryptionSettingsView> {
  late bool _isCompressionEnabled;
  late bool _isEncryptionEnabled;

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    final controller = context.read<BackupController>();
    _isCompressionEnabled = controller.isCompressionEnabled;
    _isEncryptionEnabled = controller.isEncryptionEnabled;
    _passwordController.text = controller.encryptionPassword;
    _confirmPasswordController.text = controller.encryptionPassword;
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_isEncryptionEnabled) {
      final pass = _passwordController.text.trim();
      final confirm = _confirmPasswordController.text.trim();

      if (pass.isEmpty) {
        AppSnackBar.showError(context, AppStrings.passwordRequired);
        return;
      }

      if (pass != confirm) {
        AppSnackBar.showError(context, AppStrings.passwordMismatch);
        return;
      }
    }

    final controller = context.read<BackupController>();
    controller.setCompressionAndEncryption(
      isCompressionEnabled: _isCompressionEnabled,
      isEncryptionEnabled: _isEncryptionEnabled,
      password: _isEncryptionEnabled ? _passwordController.text.trim() : '',
    );

    AppSnackBar.showSuccess(context, AppStrings.settingsSavedSuccess);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const OneUiAppBar(
        title: AppStrings.compressionEncryptionTitle,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.spaceL,
              ),
              children: [
                OneUiCard(
                  children: [
                    // 1. مفتاح ضغط النسخ الاحتياطية
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isCompressionEnabled = !_isCompressionEnabled;
                          if (!_isCompressionEnabled && _isEncryptionEnabled) {
                            _isEncryptionEnabled = false;
                          }
                        });
                      },
                      child: Padding(
                        padding: AppDimensions.paddingTile,
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppStrings.compressBackups,
                                    style: TextStyle(
                                      fontSize: AppTypography.sizeH2,
                                      fontWeight: AppTypography.weightSemiBold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: AppDimensions.spaceXXS),
                                  Text(
                                    AppStrings.compressBackupsDesc,
                                    style: TextStyle(
                                      fontSize: AppTypography.sizeCaption,
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AppSwitch(
                              value: _isCompressionEnabled,
                              onChanged: (val) {
                                setState(() {
                                  _isCompressionEnabled = val;
                                  if (!val && _isEncryptionEnabled) {
                                    _isEncryptionEnabled = false;
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 2. مفتاح تشفير النسخ الاحتياطية
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isEncryptionEnabled = !_isEncryptionEnabled;
                          if (_isEncryptionEnabled) {
                            _isCompressionEnabled = true;
                          }
                        });
                      },
                      child: Padding(
                        padding: AppDimensions.paddingTile,
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppStrings.encryptBackups,
                                    style: TextStyle(
                                      fontSize: AppTypography.sizeH2,
                                      fontWeight: AppTypography.weightSemiBold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: AppDimensions.spaceXXS),
                                  Text(
                                    AppStrings.encryptBackupsDesc,
                                    style: TextStyle(
                                      fontSize: AppTypography.sizeCaption,
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AppSwitch(
                              value: _isEncryptionEnabled,
                              onChanged: (val) {
                                setState(() {
                                  _isEncryptionEnabled = val;
                                  if (val) {
                                    _isCompressionEnabled = true;
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // التنبيه التحذيري بالأحمر وحقول كلمة المرور
                    if (_isEncryptionEnabled) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppDimensions.space2XL,
                          vertical: AppDimensions.spaceS,
                        ),
                        child: Text(
                          AppStrings.encryptionPasswordWarning,
                          style: TextStyle(
                            fontSize: AppTypography.sizeCaption,
                            fontWeight: AppTypography.weightMedium,
                            color: AppColors.dispenseRed,
                            height: 1.4,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.space2XL,
                          vertical: AppDimensions.spaceM,
                        ),
                        child: CustomTextField(
                          label: AppStrings.enterPassword,
                          hint: AppStrings.enterPassword,
                          controller: _passwordController,
                          obscureText: true,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.space2XL,
                          vertical: AppDimensions.spaceM,
                        ),
                        child: CustomTextField(
                          label: AppStrings.confirmPassword,
                          hint: AppStrings.confirmPassword,
                          controller: _confirmPasswordController,
                          obscureText: true,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // الأزرار السفلية (حفظ + إلغاء)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceXL,
              vertical: AppDimensions.spaceL,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(
                  color: AppColors.borderLight,
                  width: AppDimensions.borderWidthThin,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: AppStrings.save,
                      variant: ButtonVariant.dark,
                      onPressed: _onSave,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceL),
                  Expanded(
                    child: CustomButton(
                      text: AppStrings.cancel,
                      variant: ButtonVariant.neutral,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
