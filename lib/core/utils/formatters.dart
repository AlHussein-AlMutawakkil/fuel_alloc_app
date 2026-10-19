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

  /// تنسيق تاريخ ووقت العملية للعرض بنمط: dd/MM/yyyy (HH:mm)
  static String formatTransactionDateTime(String? dateStr, [String? createdAtStr]) {
    if (dateStr == null || dateStr.trim().isEmpty) return '-';

    DateTime? txDate;
    try {
      txDate = DateTime.parse(dateStr.trim().replaceAll('/', '-'));
    } catch (_) {}

    DateTime? createdDate;
    if (createdAtStr != null && createdAtStr.trim().isNotEmpty) {
      try {
        createdDate = DateTime.parse(createdAtStr.trim());
      } catch (_) {}
    }

    if (txDate == null && createdDate == null) {
      return dateStr;
    }

    final dateToFormat = txDate ?? createdDate!;
    final formattedDate = DateFormat('dd/MM/yyyy').format(dateToFormat);

    final timeSource = createdDate ??
        (txDate != null && (txDate.hour != 0 || txDate.minute != 0)
            ? txDate
            : null);
    if (timeSource != null) {
      final formattedTime = DateFormat('HH:mm').format(timeSource);
      return '$formattedDate ($formattedTime)';
    }

    return formattedDate;
  }

  /// تحويل اللترات إلى دباب وبراميل للعرض الإحصائي
  /// الدبة = 20 لتر، البرميل = 200 لتر
  static String formatEquivalents(double liters) {
    final dabbas = liters / 20.0;
    final barrels = liters / 200.0;
    return '${formatQuantity(dabbas)} ${AppStrings.unitDabba}  |  ${formatQuantity(barrels)} ${AppStrings.unitBarrel}';
  }

  /// تفقيط الكمية بالكلمات العربية مع الوحدة والصنف
  /// مثال: 20 -> "عشرون لتر بترول"
  /// مثال: 1 -> "واحد دبة بترول"
  static String formatTafqeetQuantity(
    double quantity, {
    String? unitName,
    String? fuelTypeName,
  }) {
    if (quantity <= 0) return '';
    final words = tafqeetNumber(quantity);
    final parts = [words];
    if (unitName != null && unitName.trim().isNotEmpty) {
      parts.add(unitName.trim());
    }
    if (fuelTypeName != null && fuelTypeName.trim().isNotEmpty) {
      parts.add(fuelTypeName.trim());
    }
    return parts.join(' ');
  }

  /// تحويل الرقم إلى تفقيط عربي فصيح
  static String tafqeetNumber(num value) {
    if (value == 0) return 'صفر';

    final isNegative = value < 0;
    final absVal = value.abs();
    final intPart = absVal.floor();
    final fracPart = ((absVal - intPart) * 100).round();

    if (intPart == 0 && fracPart == 0) return 'صفر';

    final parts = <String>[];

    final billions = (intPart ~/ 1000000000) % 1000;
    final millions = (intPart ~/ 1000000) % 1000;
    final thousands = (intPart ~/ 1000) % 1000;
    final ones = intPart % 1000;

    if (billions > 0) {
      if (billions == 1) {
        parts.add('مليار');
      } else if (billions == 2) {
        parts.add('ملياران');
      } else if (billions >= 3 && billions <= 10) {
        parts.add('${_convertThreeDigits(billions)} مليارات');
      } else {
        parts.add('${_convertThreeDigits(billions)} مليار');
      }
    }

    if (millions > 0) {
      if (millions == 1) {
        parts.add('مليون');
      } else if (millions == 2) {
        parts.add('مليونان');
      } else if (millions >= 3 && millions <= 10) {
        parts.add('${_convertThreeDigits(millions)} ملايين');
      } else {
        parts.add('${_convertThreeDigits(millions)} مليون');
      }
    }

    if (thousands > 0) {
      if (thousands == 1) {
        parts.add('ألف');
      } else if (thousands == 2) {
        parts.add('ألفان');
      } else if (thousands >= 3 && thousands <= 10) {
        parts.add('${_convertThreeDigits(thousands)} آلاف');
      } else {
        parts.add('${_convertThreeDigits(thousands)} ألف');
      }
    }

    if (ones > 0) {
      parts.add(_convertThreeDigits(ones));
    }

    var text = parts.isEmpty ? 'صفر' : parts.join(' و');

    if (fracPart > 0) {
      if (fracPart % 10 == 0) {
        final fracDigit = fracPart ~/ 10;
        text += ' فاصلة ${_convertThreeDigits(fracDigit)}';
      } else {
        text += ' فاصلة ${_convertThreeDigits(fracPart)}';
      }
    }

    return isNegative ? 'سالب $text' : text;
  }

  static String _convertThreeDigits(int n) {
    if (n == 0) return '';
    final hundreds = n ~/ 100;
    final remainder = n % 100;

    final parts = <String>[];

    if (hundreds > 0) {
      const hundredsWords = [
        '',
        'مائة',
        'مائتان',
        'ثلاثمائة',
        'أربعمائة',
        'خمسمائة',
        'ستمائة',
        'سبعمائة',
        'ثمانمائة',
        'تسعمائة',
      ];
      parts.add(hundredsWords[hundreds]);
    }

    if (remainder > 0) {
      if (remainder < 20) {
        const onesWords = [
          '',
          'واحد',
          'اثنان',
          'ثلاثة',
          'أربعة',
          'خمسة',
          'ستة',
          'سبعة',
          'ثمانية',
          'تسعة',
          'عشرة',
          'أحد عشر',
          'اثنا عشر',
          'ثلاثة عشر',
          'أربعة عشر',
          'خمسة عشر',
          'ستة عشر',
          'سبعة عشر',
          'ثمانية عشر',
          'تسعة عشر',
        ];
        parts.add(onesWords[remainder]);
      } else {
        final ones = remainder % 10;
        final tens = remainder ~/ 10;

        const onesWords = [
          '',
          'واحد',
          'اثنان',
          'ثلاثة',
          'أربعة',
          'خمسة',
          'ستة',
          'سبعة',
          'ثمانية',
          'تسعة',
        ];
        const tensWords = [
          '',
          '',
          'عشرون',
          'ثلاثون',
          'أربعون',
          'خمسون',
          'ستون',
          'سبعون',
          'ثمانون',
          'تسعون',
        ];

        if (ones > 0) {
          parts.add('${onesWords[ones]} و${tensWords[tens]}');
        } else {
          parts.add(tensWords[tens]);
        }
      }
    }

    return parts.join(' و');
  }
}
