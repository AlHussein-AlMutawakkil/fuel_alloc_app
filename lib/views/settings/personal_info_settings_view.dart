import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../controllers/personal_info_controller.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/app_switch.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/one_ui_card.dart';

/// واجهة إعدادات البيانات الشخصية وهوية المنشأة بنمط One UI مدمج ورسمي
class PersonalInfoSettingsView extends StatefulWidget {
  const PersonalInfoSettingsView({super.key});

  @override
  State<PersonalInfoSettingsView> createState() =>
      _PersonalInfoSettingsViewState();
}

class _PersonalInfoSettingsViewState extends State<PersonalInfoSettingsView> {
  late final TextEditingController _arabicNameController;
  late final TextEditingController _englishNameController;
  late final TextEditingController _arabicAddressController;
  late final TextEditingController _englishAddressController;
  late final TextEditingController _contactNumbersController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _arabicNameController = TextEditingController();
    _englishNameController = TextEditingController();
    _arabicAddressController = TextEditingController();
    _englishAddressController = TextEditingController();
    _contactNumbersController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final controller =
          Provider.of<PersonalInfoController>(context, listen: false);
      _arabicNameController.text = controller.info.arabicName;
      _englishNameController.text = controller.info.englishName;
      _arabicAddressController.text = controller.info.arabicAddress;
      _englishAddressController.text = controller.info.englishAddress;
      _contactNumbersController.text = controller.info.contactNumbers;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _arabicNameController.dispose();
    _englishNameController.dispose();
    _arabicAddressController.dispose();
    _englishAddressController.dispose();
    _contactNumbersController.dispose();
    super.dispose();
  }

  void _showImageSourcePicker({
    required BuildContext parentContext,
    required Future<bool> Function(ImageSource source) onPick,
  }) {
    showModalBottomSheet(
      context: parentContext,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusCard),
          ),
        ),
        padding: const EdgeInsets.all(AppDimensions.spaceXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: AppDimensions.handleWidth,
                height: AppDimensions.handleHeight,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.spaceL),
            CustomButton(
              text: AppStrings.selectImageFromGallery,
              icon: AppIcons.image,
              variant: ButtonVariant.primary,
              onPressed: () async {
                Navigator.pop(sheetCtx);
                if (Platform.isAndroid) {
                  final status = await Permission.photos.status;
                  final storage = await Permission.storage.status;
                  if (!status.isGranted && !storage.isGranted) {
                    var req = await Permission.photos.request();
                    if (!req.isGranted) {
                      req = await Permission.storage.request();
                    }
                    if (!req.isGranted && parentContext.mounted) {
                      AppSnackBar.showError(
                          parentContext, AppStrings.photosPermissionDenied);
                      return;
                    }
                  }
                }
                final ok = await onPick(ImageSource.gallery);
                if (ok && parentContext.mounted) {
                  AppSnackBar.showSuccess(
                      parentContext, AppStrings.savePersonalInfoSuccess);
                }
              },
            ),
            const SizedBox(height: AppDimensions.spaceM),
            CustomButton(
              text: AppStrings.selectImageFromCamera,
              icon: AppIcons.photoCamera,
              variant: ButtonVariant.secondary,
              onPressed: () async {
                Navigator.pop(sheetCtx);
                final camStatus = await Permission.camera.request();
                if (!camStatus.isGranted) {
                  if (parentContext.mounted) {
                    AppSnackBar.showError(
                        parentContext, AppStrings.cameraPermissionDenied);
                  }
                  return;
                }
                final ok = await onPick(ImageSource.camera);
                if (ok && parentContext.mounted) {
                  AppSnackBar.showSuccess(
                      parentContext, AppStrings.savePersonalInfoSuccess);
                }
              },
            ),
            const SizedBox(height: AppDimensions.spaceM),
            CustomButton(
              text: AppStrings.cancel,
              variant: ButtonVariant.secondary,
              onPressed: () => Navigator.pop(sheetCtx),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppDimensions.space2XL,
        right: AppDimensions.space2XL,
        top: AppDimensions.spaceL,
        bottom: AppDimensions.spaceS,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: AppTypography.sizeBodySecondary,
          fontWeight: AppTypography.weightBold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildCompactMediaTile({
    required BuildContext context,
    required String title,
    required String selectLabel,
    required String sizeLabel,
    required String? imagePath,
    required int scalePercent,
    required Future<bool> Function(ImageSource source) onPick,
    required VoidCallback onRemove,
    required ValueChanged<int> onScaleChanged,
    required IconData defaultIcon,
    String? defaultAssetImage,
  }) {
    final hasImage = imagePath != null &&
        imagePath.isNotEmpty &&
        File(imagePath).existsSync();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceXL,
        vertical: AppDimensions.spaceM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // السطر الأول: المعاينة المصغرة + العنوان والحالة + أزرار الاختيار والحذف
          Row(
            children: [
              // مربع المعاينة المصغر الأنيق
              Container(
                width: 52,
                height: 52,
                padding: (hasImage || defaultAssetImage == null)
                    ? EdgeInsets.zero
                    : const EdgeInsets.all(AppDimensions.spaceXS),
                decoration: BoxDecoration(
                  color: AppColors.chipBackground,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  border: Border.all(color: AppColors.borderLight),
                ),
                clipBehavior: Clip.antiAlias,
                child: hasImage
                    ? Image.file(
                        File(imagePath),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          defaultIcon,
                          size: AppDimensions.iconLarge,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : (defaultAssetImage != null
                        ? Image.asset(
                            defaultAssetImage,
                            fit: BoxFit.contain,
                          )
                        : Icon(
                            defaultIcon,
                            size: AppDimensions.iconLarge,
                            color: AppColors.textSecondary,
                          )),
              ),
              const SizedBox(width: AppDimensions.spaceM),

              // اسم العنصر وحالته
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: AppTypography.sizeBody,
                        fontWeight: AppTypography.weightBold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceXXS),
                    Text(
                      hasImage
                          ? AppStrings.changeImage
                          : (defaultAssetImage != null
                              ? AppStrings.defaultAppLogo
                              : AppStrings.noImageSelected),
                      style: const TextStyle(
                        fontSize: AppTypography.sizeCaption,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // زر الاختيار / التعديل بنمط مدمج
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spaceM,
                    vertical: AppDimensions.spaceS,
                  ),
                ),
                icon: const Icon(AppIcons.image, size: AppDimensions.iconSmall),
                label: Text(
                  hasImage ? AppStrings.changeImage : selectLabel,
                  style: const TextStyle(
                    fontSize: AppTypography.sizeCaption,
                    fontWeight: AppTypography.weightSemiBold,
                  ),
                ),
                onPressed: () => _showImageSourcePicker(
                  parentContext: context,
                  onPick: onPick,
                ),
              ),

              // زر الحذف إن وجدت صورة
              if (hasImage) ...[
                const SizedBox(width: AppDimensions.spaceXS),
                IconButton(
                  tooltip: AppStrings.removeImage,
                  icon: const Icon(
                    AppIcons.delete,
                    color: AppColors.dispenseRed,
                    size: AppDimensions.iconMedium,
                  ),
                  onPressed: onRemove,
                ),
              ],
            ],
          ),

          const SizedBox(height: AppDimensions.spaceM),

          // سطر نسبة الحجم: معتمد كلياً على اللون الأساسي للتطبيق AppColors.primary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sizeLabel,
                style: const TextStyle(
                  fontSize: AppTypography.sizeCaption,
                  color: AppColors.textSecondary,
                  fontWeight: AppTypography.weightMedium,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spaceM,
                  vertical: AppDimensions.spaceXXS,
                ),
                decoration: BoxDecoration(
                  color: AppColors.chipBackground,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Text(
                  '$scalePercent%',
                  style: const TextStyle(
                    fontSize: AppTypography.sizeCaption,
                    fontWeight: AppTypography.weightBold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),

          // شريط النسبة المئوية المدمج باللون الأساسي
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.borderLight,
              thumbColor: AppColors.primary,
            ),
            child: Slider(
              value: scalePercent.toDouble().clamp(10, 200),
              min: 10,
              max: 200,
              divisions: 19,
              onChanged: (val) => onScaleChanged(val.round()),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSave(PersonalInfoController controller) async {
    await controller.saveGeneralInfo(
      arabicName: _arabicNameController.text,
      englishName: _englishNameController.text,
      arabicAddress: _arabicAddressController.text,
      englishAddress: _englishAddressController.text,
      contactNumbers: _contactNumbersController.text,
    );
    if (mounted) {
      AppSnackBar.showSuccess(context, AppStrings.savePersonalInfoSuccess);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PersonalInfoController>(
      builder: (context, controller, _) {
        final info = controller.info;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: const OneUiAppBar(
            title: AppStrings.personalInfoViewTitle,
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.spaceL,
            ),
            children: [
              // 1. بطاقة المعلومات العامة والعناوين
              _buildSectionHeader(AppStrings.generalInfoSection),
              OneUiCard(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppDimensions.spaceM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CustomTextField(
                          label: AppStrings.arabicNameLabel,
                          hint: AppStrings.arabicNameHint,
                          controller: _arabicNameController,
                          prefixIcon: const Icon(AppIcons.badge,
                              size: AppDimensions.iconMedium),
                        ),
                        const SizedBox(height: AppDimensions.spaceM),
                        CustomTextField(
                          label: AppStrings.englishNameLabel,
                          hint: AppStrings.englishNameHint,
                          controller: _englishNameController,
                          prefixIcon: const Icon(AppIcons.badge,
                              size: AppDimensions.iconMedium),
                        ),
                        const SizedBox(height: AppDimensions.spaceM),
                        CustomTextField(
                          label: AppStrings.arabicAddressLabel,
                          hint: AppStrings.arabicAddressHint,
                          controller: _arabicAddressController,
                          prefixIcon: const Icon(AppIcons.location,
                              size: AppDimensions.iconMedium),
                        ),
                        const SizedBox(height: AppDimensions.spaceM),
                        CustomTextField(
                          label: AppStrings.englishAddressLabel,
                          hint: AppStrings.englishAddressHint,
                          controller: _englishAddressController,
                          prefixIcon: const Icon(AppIcons.location,
                              size: AppDimensions.iconMedium),
                        ),
                        const SizedBox(height: AppDimensions.spaceM),
                        CustomTextField(
                          label: AppStrings.contactNumbersLabel,
                          hint: AppStrings.contactNumbersHint,
                          controller: _contactNumbersController,
                          keyboardType: TextInputType.phone,
                          prefixIcon: const Icon(AppIcons.phone,
                              size: AppDimensions.iconMedium),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // 2. بطاقة الشعار والختم والتوقيع (مدمجة وأنيقة في كرت واحد بنمط One UI)
              _buildSectionHeader(AppStrings.brandingSection),
              OneUiCard(
                children: [
                  // الشعار (Logo)
                  _buildCompactMediaTile(
                    context: context,
                    title: AppStrings.logoLabel,
                    selectLabel: AppStrings.selectLogo,
                    sizeLabel: AppStrings.logoSizePercentLabel,
                    imagePath: info.logoPath,
                    scalePercent: info.logoScalePercent,
                    onPick: controller.pickLogo,
                    onRemove: controller.removeLogo,
                    onScaleChanged: controller.setLogoScale,
                    defaultIcon: AppIcons.image,
                    defaultAssetImage: AppAssets.appIconTransparent,
                  ),

                  // الختم الرسمي (Stamp)
                  _buildCompactMediaTile(
                    context: context,
                    title: AppStrings.stampLabel,
                    selectLabel: AppStrings.selectStamp,
                    sizeLabel: AppStrings.stampSizePercentLabel,
                    imagePath: info.stampPath,
                    scalePercent: info.stampScalePercent,
                    onPick: controller.pickStamp,
                    onRemove: controller.removeStamp,
                    onScaleChanged: controller.setStampScale,
                    defaultIcon: AppIcons.stamp,
                  ),

                  // التوقيع المعتمد (Signature)
                  _buildCompactMediaTile(
                    context: context,
                    title: AppStrings.signatureLabel,
                    selectLabel: AppStrings.selectSignature,
                    sizeLabel: AppStrings.signatureSizePercentLabel,
                    imagePath: info.signaturePath,
                    scalePercent: info.signatureScalePercent,
                    onPick: controller.pickSignature,
                    onRemove: controller.removeSignature,
                    onScaleChanged: controller.setSignatureScale,
                    defaultIcon: AppIcons.draw,
                  ),
                ],
              ),

              // 3. بطاقة النسخ الاحتياطي
              _buildSectionHeader(AppStrings.backupInclusionSection),
              OneUiCard(
                children: [
                  OneUiTile(
                    leading: const Icon(
                      AppIcons.backupDatabase,
                      color: AppColors.textPrimary,
                      size: AppDimensions.iconMedium + 2,
                    ),
                    title: AppStrings.includePersonalInfoInBackupTitle,
                    trailing: AppSwitch(
                      value: info.includeInBackup,
                      onChanged: (val) => controller.toggleIncludeInBackup(val),
                    ),
                    onTap: () =>
                        controller.toggleIncludeInBackup(!info.includeInBackup),
                  ),
                ],
              ),

              // 4. زر الحفظ الرئيسي
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spaceXL,
                  vertical: AppDimensions.spaceM,
                ),
                child: CustomButton(
                  text: AppStrings.savePersonalInfo,
                  icon: AppIcons.check,
                  onPressed: () => _handleSave(controller),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
