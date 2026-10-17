import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_icons.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';

/// الفاصل الخطي الموحد بنمط One UI لكافة قوائم وكروت التطبيق
class OneUiDivider extends StatelessWidget {
  final double indent;
  final double endIndent;
  final double height;
  final double thickness;
  final Color? color;

  const OneUiDivider({
    super.key,
    this.indent = AppDimensions.dividerIndent,
    this.endIndent = AppDimensions.dividerIndent,
    this.height = AppDimensions.dividerHeight,
    this.thickness = AppDimensions.dividerThickness,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: height,
      thickness: thickness,
      color: color ?? AppColors.divider,
      indent: indent,
      endIndent: endIndent,
    );
  }
}

/// كرت One UI الأبيض ذو الزوايا الدائرية الكاملة
class OneUiCard extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final bool showDividers;

  const OneUiCard({
    super.key,
    required this.children,
    this.margin = const EdgeInsets.symmetric(
      horizontal: AppDimensions.spaceXL,
      vertical: AppDimensions.spaceS,
    ),
    this.padding,
    this.borderRadius = AppDimensions.radiusCard,
    this.showDividers = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: showDividers ? _buildSeparatedChildren() : children,
      ),
    );
  }

  List<Widget> _buildSeparatedChildren() {
    if (children.isEmpty) return const [];
    final List<Widget> result = [];
    for (int i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        result.add(const OneUiDivider());
      }
    }
    return result;
  }
}

/// حاوية قائمة One UI الموحدة للقوائم القابلة للتمرير (ListViews)
class OneUiListContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;
  final double borderRadius;

  const OneUiListContainer({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.fromLTRB(
      AppDimensions.spaceXL,
      AppDimensions.spaceNone,
      AppDimensions.spaceXL,
      AppDimensions.spaceXL,
    ),
    this.borderRadius = AppDimensions.radiusCard,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// عنصر سطر داخل كرت One UI
class OneUiTile extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final String? valueText;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final Color? titleColor;

  const OneUiTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.valueText,
    this.trailing,
    this.onTap,
    this.showChevron = false,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: AppDimensions.paddingTile,
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppDimensions.spaceL + 2),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: AppTypography.sizeBody + 1,
                        fontWeight: AppTypography.weightSemiBold,
                        color: titleColor ?? AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: AppDimensions.spaceXXS + 1),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: AppTypography.sizeCaption,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (valueText != null && valueText!.isNotEmpty) ...[
                const SizedBox(width: AppDimensions.spaceM),
                Text(
                  valueText!,
                  style: const TextStyle(
                    fontSize: AppTypography.sizeBodySecondary,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
              if (trailing != null) ...[
                const SizedBox(width: AppDimensions.spaceM),
                trailing!,
              ] else if (showChevron) ...[
                const SizedBox(width: AppDimensions.spaceS),
                const Icon(
                  AppIcons.chevronLeft,
                  color: AppColors.textMuted,
                  size: AppDimensions.iconMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// عنصر خيار اختيار مركزي بنمط One UI (مع أيقونة Icons.check_circle الجاهزة)
class OneUiSelectionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback? onTap;

  const OneUiSelectionTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: AppTypography.sizeH2,
                        fontWeight: AppTypography.weightMedium,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: AppDimensions.spaceXXS + 1),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: AppTypography.sizeBodySecondary,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  AppIcons.checkCircle,
                  color: AppColors.textDarkSlate,
                  size: 15,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// شريط علوي بنمط One UI مطابق للقطات الشاشة
class OneUiAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const OneUiAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = showBackButton && Navigator.canPop(context);
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: canPop ? AppDimensions.spaceS : AppDimensions.space2XL,
      leadingWidth: canPop ? 42 : null,
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      leading: canPop
          ? IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: AppDimensions.iconDisplay,
                minHeight: AppDimensions.iconDisplay,
              ),
              icon: const Icon(
                AppIcons.back,
                size: AppDimensions.iconMedium,
                color: AppColors.textPrimary,
              ),
              tooltip: AppStrings.back,
              onPressed:
                  onBackPressed ?? () => Navigator.of(context).maybePop(),
            )
          : null,
      title: Text(
        title,
        style: AppTypography.oneUiAppBarTitle,
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
