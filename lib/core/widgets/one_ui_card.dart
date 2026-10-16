import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// الفاصل الخطي الموحد بنمط One UI لكافة قوائم وكروت التطبيق
class OneUiDivider extends StatelessWidget {
  final double indent;
  final double endIndent;
  final double height;
  final double thickness;
  final Color? color;

  const OneUiDivider({
    super.key,
    this.indent = 16.0,
    this.endIndent = 16.0,
    this.height = 1.5,
    this.thickness = 1.5,
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
    this.margin = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
    this.padding,
    this.borderRadius = 20.0,
    this.showDividers = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
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
    this.margin = const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
    this.borderRadius = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
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
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 15.0),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: titleColor ?? const Color(0xFF0F172A),
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (valueText != null && valueText!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  valueText!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ] else if (showChevron) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_left,
                  color: Color(0xFF94A3B8),
                  size: 20,
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
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
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
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF1E293B),
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
      backgroundColor: const Color(0xfff8f8f8),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: canPop ? 6 : 20,
      leadingWidth: canPop ? 42 : null,
      iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      leading: canPop
          ? IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              icon: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 20,
                color: Color(0xFF0F172A),
              ),
              tooltip: 'رجوع',
              onPressed: onBackPressed ?? () => Navigator.of(context).maybePop(),
            )
          : null,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A),
        ),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

