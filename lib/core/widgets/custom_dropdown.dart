import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_icons.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';

/// عنصر في القائمة المنسدلة الموحدة
class CustomDropdownItem<T> {
  final T value;
  final String label;
  final Widget? icon;

  const CustomDropdownItem({
    required this.value,
    required this.label,
    this.icon,
  });
}

/// القائمة المنسدلة الموحدة (مكون مشترك لجميع شاشات التطبيق)
class CustomDropdown<T> extends StatelessWidget {
  final String? label;
  final String? hint;
  final T? value;
  final List<CustomDropdownItem<T>> items;
  final ValueChanged<T>? onChanged;
  final String? Function(T?)? validator;
  final Widget? prefixIcon;
  final Widget? trailing;
  final Widget? icon;
  final Widget? customTrigger;
  final double? menuWidth;
  final bool enabled;
  final Color? backgroundColor;
  final Color? borderColor;
  final BorderRadius? borderRadius;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;

  const CustomDropdown({
    super.key,
    this.label,
    this.hint,
    required this.items,
    this.value,
    this.onChanged,
    this.validator,
    this.prefixIcon,
    this.trailing,
    this.icon,
    this.customTrigger,
    this.menuWidth,
    this.enabled = true,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.height,
    this.padding,
    this.textStyle,
    this.hintStyle,
  });

  void _showDropdownMenu(BuildContext context) async {
    if (!enabled || items.isEmpty) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final RenderBox? overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;

    final RelativeRect position;
    if (overlay != null) {
      position = RelativeRect.fromRect(
        Rect.fromPoints(
          renderBox.localToGlobal(Offset.zero, ancestor: overlay),
          renderBox.localToGlobal(
            renderBox.size.bottomRight(Offset.zero),
            ancestor: overlay,
          ),
        ),
        Offset.zero & overlay.size,
      );
    } else {
      final Offset offset = renderBox.localToGlobal(Offset.zero);
      final Size size = renderBox.size;
      position = RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height + AppDimensions.spaceXS,
        offset.dx + size.width,
        offset.dy + size.height + AppDimensions.spaceXS,
      );
    }

    final double triggerWidth = renderBox.size.width;
    final double computedMinWidth = menuWidth ??
        (triggerWidth < 180 ? 180.0 : triggerWidth).clamp(160.0, 500.0);
    final double computedMaxWidth = menuWidth ??
        (triggerWidth < 220 ? 220.0 : triggerWidth).clamp(200.0, 500.0);

    final selected = await showMenu<T>(
      context: context,
      position: position,
      elevation: 6,
      shadowColor: AppColors.shadowSubtle,
      color: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: AppDimensions.borderRadius3XL,
        side: BorderSide(
          color: AppColors.borderSubtle,
          width: AppDimensions.borderWidthThin,
        ),
      ),
      constraints: BoxConstraints(
        minWidth: computedMinWidth,
        maxWidth: computedMaxWidth,
      ),
      items: items.map((item) {
        final isSelected = item.value == value;

        return PopupMenuItem<T>(
          value: item.value,
          padding: EdgeInsets.zero,
          height: AppDimensions.iconDisplay,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceS,
                vertical: AppDimensions.spaceXXS,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceL,
                vertical: AppDimensions.spaceM,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.highlightBackground
                    : Colors.transparent,
                borderRadius: AppDimensions.borderRadiusL,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // النص في اليمين (RTL)
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item.icon != null) ...[
                          item.icon!,
                          const SizedBox(width: AppDimensions.spaceM),
                        ],
                        Flexible(
                          child: Text(
                            item.label,
                            style: TextStyle(
                              fontSize: AppTypography.sizeBody,
                              fontWeight: isSelected
                                  ? AppTypography.weightBold
                                  : AppTypography.weightMedium,
                              color: isSelected
                                  ? AppColors.textDarkSlate
                                  : AppColors.textSlate,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // علامة الصح في اليسار (RTL) عند الاختيار فقط
                  if (isSelected)
                    const Icon(
                      AppIcons.check,
                      size: AppDimensions.iconRegular,
                      color: AppColors.textDarkSlate,
                    )
                  else
                    const SizedBox(width: AppDimensions.iconRegular),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );

    if (selected != null && onChanged != null) {
      onChanged!(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? AppDimensions.borderRadius2XL;

    if (customTrigger != null) {
      return InkWell(
        onTap: enabled ? () => _showDropdownMenu(context) : null,
        borderRadius: effectiveBorderRadius,
        child: customTrigger!,
      );
    }

    String? currentLabel;
    Widget? currentIcon;
    try {
      final selectedItem = items.firstWhere((it) => it.value == value);
      currentLabel = selectedItem.label;
      currentIcon = selectedItem.icon;
    } catch (_) {
      currentLabel = null;
    }

    Widget content = Container(
      height: height ?? AppDimensions.inputHeight,
      padding: padding ?? AppDimensions.paddingInputDense,
      decoration: BoxDecoration(
        color: enabled
            ? (backgroundColor ?? AppColors.background)
            : AppColors.chipBackground,
        borderRadius: effectiveBorderRadius,
        border: Border.all(
          color: borderColor ?? AppColors.borderLight,
          width: AppDimensions.borderWidthThin,
        ),
      ),
      child: Row(
        children: [
          if (prefixIcon != null) ...[
            prefixIcon!,
            const SizedBox(width: AppDimensions.spaceM),
          ] else if (currentIcon != null) ...[
            currentIcon,
            const SizedBox(width: AppDimensions.spaceM),
          ],
          Expanded(
            child: Text(
              currentLabel ?? hint ?? AppStrings.selectEllipsis,
              style: currentLabel != null
                  ? (textStyle ??
                      const TextStyle(
                        fontSize: AppTypography.sizeBodySecondary,
                        fontWeight: AppTypography.weightSemiBold,
                        color: AppColors.textDarkSlate,
                      ))
                  : (hintStyle ??
                      const TextStyle(
                        fontSize: AppTypography.sizeBodySecondary,
                        fontWeight: AppTypography.weightRegular,
                        color: AppColors.textMuted,
                      )),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) ...[
            trailing!,
            const SizedBox(width: AppDimensions.spaceS),
          ],
          icon ??
              Icon(
                AppIcons.dropdownArrow,
                size: AppDimensions.iconRegular,
                color: enabled ? AppColors.textTertiary : AppColors.textMuted,
              ),
        ],
      ),
    );

    if (label != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label!,
            style: AppTypography.bodySecondary.copyWith(
              fontWeight: AppTypography.weightSemiBold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceS),
          InkWell(
            onTap: enabled ? () => _showDropdownMenu(context) : null,
            borderRadius: effectiveBorderRadius,
            child: content,
          ),
        ],
      );
    }

    return InkWell(
      onTap: enabled ? () => _showDropdownMenu(context) : null,
      borderRadius: effectiveBorderRadius,
      child: content,
    );
  }
}
