import 'package:intl/intl.dart';
import '../constants/app_strings.dart';

/// دوال مساعدة لتنسيق الأرقام والكميات والتواريخ
class AppFormatters {
  AppFormatters._();

  static final NumberFormat _numberFormat = NumberFormat('#,##0.##', 'en_US');

  /// تنسيق الكمية والأرقام بدون أصفار عشرية زائدة مع فواصل الآلاف
  static String formatQuantity(double quantity) {
    return _numberFormat.format(quantity);
  }

  /// تنسيق التاريخ للعرض
  static String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('yyyy/MM/dd').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  /// تحويل اللترات إلى دباب وبراميل للعرض الإحصائي
  /// الدبة = 20 لتر، البرميل = 200 لتر
  static String formatEquivalents(double liters) {
    final dabbas = liters / 20.0;
    final barrels = liters / 200.0;
    return '${formatQuantity(dabbas)} ${AppStrings.unitDabba}  |  ${formatQuantity(barrels)} ${AppStrings.unitBarrel}';
  }
}
