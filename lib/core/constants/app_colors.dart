import 'package:flutter/material.dart';

/// الألوان الرسمية المعتمدة للمشروع
/// تصميم رسمي، هادئ، خالٍ من التدرجات اللونية
class AppColors {
  AppColors._();

  // اللون الأساسي: كحلي رسمي
  static const Color primary = Color(0xFF102A43);
  static const Color primaryDark = Color(0xFF0A1C2E);
  static const Color primaryLight = Color(0xFF243B53);

  // الخلفيات: أبيض
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFF8FAFC);

  // عمليات التوريد: أخضر
  static const Color supplyGreen = Color(0xFF15803D);
  static const Color supplyLight = Color(0xFFDCFCE7);

  // عمليات الصرف: أحمر
  static const Color dispenseRed = Color(0xFFB91C1C);
  static const Color dispenseLight = Color(0xFFFEE2E2);

  // النصوص والعناصر الحيادية
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);

  // الحدود والفواصل
  static const Color border = Color(0xFFCBD5E1);
  static const Color divider = Color(0xFFE2E8F0);

  // حالات النظام
  static const Color warning = Color(0xFFD97706);
  static const Color info = Color(0xFF2563EB);
}
