import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// مؤشر التحميل المركزي الموحد
class AppLoadingIndicator extends StatelessWidget {
  final Color? color;
  final double size;
  final double strokeWidth;

  const AppLoadingIndicator({
    super.key,
    this.color,
    this.size = AppDimensions.space3XL,
    this.strokeWidth = AppDimensions.borderWidthThick,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: strokeWidth,
          color: color ?? AppColors.primary,
        ),
      ),
    );
  }
}
