import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_icons.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import 'custom_text_field.dart';

/// المكون المشترك الموحد لكافة النوافذ المنبثقة في التطبيق
/// (إضافة حساب، إضافة محطة، إضافة صنف)
/// بتصميم One UI العصري الموحد
class CustomModalSheet {
  CustomModalSheet._();

  // لون حدود الحقول الموحد الناعم
  static const Color fieldBorderColor = AppColors.borderLight;

  /// فتح نافذة منبثقة موحدة في كافة شاشات التطبيق
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget Function(BuildContext ctx, StateSetter setState)
        contentBuilder,
    required Future<void> Function(BuildContext ctx) onSave,
    String saveText = AppStrings.confirm,
    String cancelText = AppStrings.cancel,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.overlay,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setModalState) {
            return Center(
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spaceXL,
                  vertical: AppDimensions.space2XL,
                ),
                constraints: const BoxConstraints(
                  maxWidth: AppDimensions.modalMaxWidth,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppDimensions.borderRadius3XL,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.overlayLight,
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: AppDimensions.borderRadius3XL,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(dialogCtx).viewInsets.bottom,
                    ),
                    child: SingleChildScrollView(
                      padding: AppDimensions.paddingModal,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. الشريط العلوي: العنوان وزر الإغلاق
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: AppTypography.sizeH2,
                                    fontWeight: AppTypography.weightBold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  AppIcons.closeRounded,
                                  color: AppColors.textTertiary,
                                  size: AppDimensions.iconMedium,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: AppDimensions.space4XL,
                                  minHeight: AppDimensions.space4XL,
                                ),
                                onPressed: () => Navigator.of(dialogCtx).pop(),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.spaceL + 6),

                          // 2. محتوى الحقول
                          contentBuilder(dialogCtx, setModalState),
                          const SizedBox(height: AppDimensions.space3XL),

                          // 3. شريط الأزرار السفلي (إلغاء رمادي يميناً، وتأكيد أسود يساراً في RTL)
                          Row(
                            children: [
                              // زر الإلغاء على اليمين
                              Expanded(
                                child: InkWell(
                                  onTap: () => Navigator.of(dialogCtx).pop(),
                                  borderRadius: AppDimensions.borderRadius2XL,
                                  child: Container(
                                    height: AppDimensions.inputHeight,
                                    decoration: const BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius:
                                          AppDimensions.borderRadius2XL,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      cancelText,
                                      style: const TextStyle(
                                        fontSize: AppTypography.sizeBody + 1,
                                        fontWeight:
                                            AppTypography.weightSemiBold,
                                        color: AppColors.textSlate,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppDimensions.spaceL),

                              // زر التأكيد الأسود على اليسار
                              Expanded(
                                child: InkWell(
                                  onTap: () => onSave(dialogCtx),
                                  borderRadius: AppDimensions.borderRadius2XL,
                                  child: Container(
                                    height: AppDimensions.inputHeight,
                                    decoration: const BoxDecoration(
                                      color: AppColors.charcoal,
                                      borderRadius:
                                          AppDimensions.borderRadius2XL,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      saveText,
                                      style: const TextStyle(
                                        fontSize: AppTypography.sizeBody + 1,
                                        fontWeight:
                                            AppTypography.weightSemiBold,
                                        color: AppColors.textWhite,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// بناء عنوان الحقل الموحد
  static Widget buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceS),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: AppTypography.sizeCaption,
          fontWeight: AppTypography.weightMedium,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }

  /// بناء حقل إدخال نصي موحد بنسبة 100%
  static Widget buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool readOnly = false,
    VoidCallback? onTap,
    ValueChanged<String>? onChanged,
  }) {
    return CustomTextField(
      label: label,
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      variant: TextFieldVariant.oneUi,
    );
  }

  /// نافذة اختيار موحدة مطابقة تماماً للتصميم المعتمد (BottomSheet متكيف وقابل للبحث)
  static Future<T?> showItemPicker<T>({
    required BuildContext context,
    required String title,
    required List<T> items,
    required String Function(T item) itemLabel,
    String searchHint = AppStrings.searchHere,
    String emptyText = AppStrings.noAccountsFound,
    T? selectedItem,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.overlay,
      builder: (ctx) {
        return _ItemPickerSheet<T>(
          title: title,
          items: items,
          itemLabel: itemLabel,
          searchHint: searchHint,
          emptyText: emptyText,
          selectedItem: selectedItem,
        );
      },
    );
  }
}

class _ItemPickerSheet<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T item) itemLabel;
  final String searchHint;
  final String emptyText;
  final T? selectedItem;

  const _ItemPickerSheet({
    required this.title,
    required this.items,
    required this.itemLabel,
    required this.searchHint,
    required this.emptyText,
    this.selectedItem,
  });

  @override
  State<_ItemPickerSheet<T>> createState() => _ItemPickerSheetState<T>();
}

class _ItemPickerSheetState<T> extends State<_ItemPickerSheet<T>> {
  final TextEditingController _searchController = TextEditingController();
  String _filterText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = widget.items.where((item) {
      if (_filterText.isEmpty) return true;
      return widget
          .itemLabel(item)
          .toLowerCase()
          .contains(_filterText.toLowerCase());
    }).toList();

    final mediaQuery = MediaQuery.of(context);
    final availableHeight =
        mediaQuery.size.height - mediaQuery.viewInsets.bottom;
    final maxHeight = availableHeight * 0.85;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: mediaQuery.viewInsets.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: maxHeight,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppDimensions.radiusCard),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. مقبض السحب العلوي (Handle Bar)
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(
                        top: AppDimensions.spaceL,
                        bottom: AppDimensions.spaceL,
                      ),
                      width: AppDimensions.handleWidth,
                      height: AppDimensions.handleHeight,
                      decoration: BoxDecoration(
                        color: AppColors.charcoal,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.handleHeight / 2,
                        ),
                      ),
                    ),
                  ),

                  // 2. العنوان في المنتصف (Title)
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppDimensions.spaceL,
                    ),
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: AppTypography.sizeH2,
                        fontWeight: AppTypography.weightBold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),

                  // 3. خط فاصل كامل العرض تحت العنوان
                  const Divider(
                    height: AppDimensions.dividerHeight,
                    thickness: AppDimensions.borderWidthThin,
                    color: AppColors.borderLight,
                  ),

                  // 4. حقل البحث الرمادي مع الأيقونة ونص "ابحث هنا"
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spaceXL,
                      vertical: AppDimensions.spaceL,
                    ),
                    child: Container(
                      height: AppDimensions.inputHeight,
                      decoration: const BoxDecoration(
                        color: AppColors.searchBackground,
                        borderRadius: AppDimensions.borderRadiusXL,
                      ),
                      alignment: Alignment.center,
                      child: TextField(
                        controller: _searchController,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: AppTypography.sizeBody,
                          color: AppColors.textPrimary,
                          fontWeight: AppTypography.weightMedium,
                        ),
                        decoration: InputDecoration(
                          hintText: widget.searchHint,
                          hintStyle: const TextStyle(
                            fontSize: AppTypography.sizeBody,
                            color: AppColors.textSecondary,
                            fontWeight: AppTypography.weightRegular,
                          ),
                          prefixIcon: const Icon(
                            AppIcons.search,
                            size: AppDimensions.iconMedium + 2,
                            color: AppColors.charcoal,
                          ),
                          suffixIcon: _filterText.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    AppIcons.closeRounded,
                                    size: AppDimensions.iconSmall,
                                    color: AppColors.textTertiary,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _filterText = '';
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spaceM,
                            vertical: 12.0,
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _filterText = val.trim();
                          });
                        },
                      ),
                    ),
                  ),

                  // 5. قائمة العناصر مع الفواصل الأفقية
                  Flexible(
                    child: filteredItems.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppDimensions.space4XL,
                              horizontal: AppDimensions.space2XL,
                            ),
                            child: Center(
                              child: Text(
                                widget.emptyText,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: AppTypography.sizeBody,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.only(
                              bottom: AppDimensions.spaceL,
                            ),
                            itemCount: filteredItems.length,
                            separatorBuilder: (context, index) => const Divider(
                              height: AppDimensions.dividerHeight,
                              thickness: AppDimensions.borderWidthLight,
                              color: AppColors.borderLight,
                              indent: AppDimensions.spaceXL,
                              endIndent: AppDimensions.spaceXL,
                            ),
                            itemBuilder: (context, index) {
                              final item = filteredItems[index];
                              return InkWell(
                                onTap: () {
                                  Navigator.of(context).pop(item);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppDimensions.space2XL,
                                    vertical: AppDimensions.spaceL + 2,
                                  ),
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    widget.itemLabel(item),
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: AppTypography.sizeBody + 1,
                                      fontWeight: AppTypography.weightBold,
                                      color: AppColors.charcoal,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

