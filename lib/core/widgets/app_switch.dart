import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// مفتاح التبديل الموحد والأنيق المعتمد بنمط التطبيق
class AppSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Color? inactiveTrackColor;

  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.inactiveTrackColor,
  });

  @override
  Widget build(BuildContext context) {
    const double width = 48.0;
    const double height = 26.0;
    const double thumbSize = 20.0;
    const double padding = 3.0;

    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final effectiveActiveColor = activeColor ?? AppColors.charcoal;
    final effectiveInactiveColor = inactiveTrackColor ?? AppColors.border;

    return GestureDetector(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: width,
        height: height,
        padding: const EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: value ? effectiveActiveColor : effectiveInactiveColor,
          borderRadius: BorderRadius.circular(height / 2),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: value
              ? (isRtl ? Alignment.centerLeft : Alignment.centerRight)
              : (isRtl ? Alignment.centerRight : Alignment.centerLeft),
          child: Container(
            width: thumbSize,
            height: thumbSize,
            decoration: const BoxDecoration(
              color: AppColors.textWhite,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowSubtle,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
