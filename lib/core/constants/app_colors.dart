import 'package:flutter/material.dart';

/// الألوان الرسمية المعتمدة للمشروع
/// تصميم رسمي، هادئ، خالٍ من التدرجات اللونية
class AppColors {
  AppColors._();

  // اللون الأساسي: كحلي رسمي
  static const Color primary = Color(0xFF102A43);
  static const Color primaryDark = Color(0xFF0A1C2E);
  static const Color primaryLight = Color(0xFF243B53);

  // الخلفيات
  static const Color background = Color(0xFFf8f8f8);
  static const Color surface = Color(0xFFffffff);
  static const Color segmentBackground = Color(0xFFeaeaea);

  static const Color chipBackground = Color(0xFFF1F5F9);
  static const Color highlightBackground = Color(0xFff8f8f8);
  static const Color searchBackground = Color(0xFFEEEEEE);
  static const Color charcoal = Color(0xFF1E1E1E);

  // عمليات التوريد: أخضر
  static const Color supplyGreen = Color(0xFF15803D);
  static const Color supplyLight = Color(0xFFDCFCE7);

  // عمليات الصرف: أحمر
  static const Color dispenseRed = Color(0xFFB91C1C);
  static const Color dispenseLight = Color(0xFFFEE2E2);

  // النصوص والعناصر الحيادية
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDarkSlate = Color(0xFF1E293B);
  static const Color textSlate = Color(0xFF334155);
  static const Color textWhite = Colors.white;

  // الحدود والفواصل
  static const Color border = Color(0xFFCBD5E1);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFF1F5F9);
  static const Color divider = Color(0xFFE2E8F0);

  // حالات النظام
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFEFF6FF);
  static const Color infoText = Color(0xFF1D4ED8);
  static const Color success = Color(0xFF16A34A);

  // أزرار وإجراءات السحب (Slidable Actions)
  static const Color actionEdit = Color(0xFF3B82F6);
  static const Color actionDelete = Color(0xFFEF4444);
  static const Color actionArchive = Color(0xFFF59E0B);

  // التراكبات والظلال
  static const Color overlay = Color(0x8C000000);
  static const Color overlayLight = Color(0x1F000000);
  static const Color shadowSubtle = Color(0x0F000000);
}
