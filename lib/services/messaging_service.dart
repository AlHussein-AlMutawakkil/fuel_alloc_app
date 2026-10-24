import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';

/// خدمة إدارة وتنسيق وإرسال الرسائل النصية وعبر الواتساب
class MessagingService {
  static final MessagingService instance = MessagingService._internal();

  MessagingService._internal();

  /// تنظيف وتجهيز رقم الهاتف
  static String sanitizePhoneNumber(String? rawPhone) {
    if (rawPhone == null) return '';
    // إزالة المسافات، الشُّرَط، والأقواس
    String cleaned = rawPhone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    return cleaned;
  }

  /// تهيئة رقم الهاتف لتطبيق الواتساب (إضافة كود الدولة الافتراضي إن لزم)
  static String formatPhoneForWhatsApp(String phone, {String defaultCountryCode = '967'}) {
    String cleaned = sanitizePhoneNumber(phone);
    if (cleaned.isEmpty) return '';

    // إزالة الصفرين في البداية أو علامة +
    if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    } else if (cleaned.startsWith('00')) {
      cleaned = cleaned.substring(2);
    } else if (cleaned.length == 9 && (cleaned.startsWith('7') || cleaned.startsWith('1'))) {
      // رقم يمني محلي من 9 أرقام يبدأ بـ 7 أو 1
      cleaned = '$defaultCountryCode$cleaned';
    } else if (cleaned.startsWith('0') && cleaned.length == 10) {
      cleaned = '$defaultCountryCode${cleaned.substring(1)}';
    }

    return cleaned;
  }

  /// استبدال كافة المتغيرات في القالب بقيم حقيقية مستخرجة من العملية والحساب
  String populateTemplate({
    required String templateContent,
    required TransactionModel transaction,
    AccountModel? account,
    AccountModel? station,
    double? remainingBalance,
  }) {
    if (templateContent.trim().isEmpty) return '';

    final numberFormat = NumberFormat('#,##0.##', 'en_US');
    final formattedQty = numberFormat.format(transaction.enteredQuantity);
    final formattedBalance = remainingBalance != null
        ? numberFormat.format(remainingBalance)
        : '-';

    String result = templateContent;

    // استخراج أسماء الحقول مع توفير قيم احتياطية تلقائية لمنع الفراغات
    String opTypeName = transaction.typeName ?? '';
    if (opTypeName.isEmpty) {
      switch (transaction.typeId) {
        case 1:
          opTypeName = 'توريد اعتماد';
          break;
        case 2:
          opTypeName = 'توريد فعلي';
          break;
        case 3:
          opTypeName = 'عمولة تهوية';
          break;
        case 4:
          opTypeName = 'صرف اعتماد';
          break;
        case 5:
          opTypeName = 'صرف فعلي';
          break;
        case 6:
        case 7:
          opTypeName = 'تحويل';
          break;
      }
    }

    String fuelName = transaction.fuelTypeName ?? '';
    if (fuelName.isEmpty && transaction.fuelTypeId != null) {
      if (transaction.fuelTypeId == 1) fuelName = 'بترول';
      if (transaction.fuelTypeId == 2) fuelName = 'ديزل';
    }

    String unitName = transaction.unitName ?? '';
    if (unitName.isEmpty) {
      if (transaction.unitId == 1) unitName = 'لتر';
      if (transaction.unitId == 2) unitName = 'دبة';
      if (transaction.unitId == 3) unitName = 'برميل';
    }

    final txNumber = transaction.transactionNumber ??
        (transaction.id != null ? 'TX-${transaction.id}' : '');

    final replacements = <String, String>{
      // اسم العميل أو الحساب
      '{account_name}': account?.name ?? transaction.accountName ?? '',
      '{اسم_العميل}': account?.name ?? transaction.accountName ?? '',
      '{اسم_الحساب}': account?.name ?? transaction.accountName ?? '',
      '{العميل}': account?.name ?? transaction.accountName ?? '',
      '{الحساب}': account?.name ?? transaction.accountName ?? '',

      // اسم المحطة
      '{station_name}': station?.name ?? transaction.stationName ?? '',
      '{اسم_المحطة}': station?.name ?? transaction.stationName ?? '',
      '{المحطة}': station?.name ?? transaction.stationName ?? '',

      // نوع العملية
      '{operation_type}': opTypeName,
      '{نوع_العملية}': opTypeName,
      '{العملية}': opTypeName,

      // الكمية
      '{quantity}': formattedQty,
      '{الكمية}': formattedQty,

      // الوحدة
      '{unit}': unitName,
      '{الوحدة}': unitName,

      // نوع الوقود
      '{fuel_type}': fuelName,
      '{نوع_الوقود}': fuelName,
      '{نوع_الصنف}': fuelName,
      '{الصنف}': fuelName,
      '{الوقود}': fuelName,

      // الرصيد المتبقي
      '{remaining_balance}': formattedBalance,
      '{الرصيد_المتبقي}': formattedBalance,
      '{الرصيد}': formattedBalance,

      // رقم العملية
      '{transaction_no}': txNumber,
      '{رقم_العملية}': txNumber,

      // رقم المرجع / السند
      '{reference_no}': transaction.referenceNumber ?? '-',
      '{رقم_المرجع}': transaction.referenceNumber ?? '-',
      '{رقم_السند}': transaction.referenceNumber ?? '-',
      '{المرجع}': transaction.referenceNumber ?? '-',
      '{السند}': transaction.referenceNumber ?? '-',

      // اسم المستلم / السائق
      '{recipient_name}': transaction.recipientName ?? (account?.name ?? '-'),
      '{اسم_المستلم}': transaction.recipientName ?? (account?.name ?? '-'),
      '{المستلم}': transaction.recipientName ?? (account?.name ?? '-'),
      '{السائق}': transaction.recipientName ?? (account?.name ?? '-'),

      // التاريخ
      '{date}': transaction.transactionDate.split('T').first,
      '{التاريخ}': transaction.transactionDate.split('T').first,

      // الملاحظات
      '{notes}': transaction.notes ?? '',
      '{الملاحظات}': transaction.notes ?? '',
    };

    replacements.forEach((key, value) {
      result = result.replaceAll(key, value);
    });

    return result.trim();
  }

  /// إرسال رسالة SMS عبر فتح تطبيق الرسائل الافتراضي بترميز النسبة المئوية للمسافات (%20)
  Future<bool> sendSms({
    required String phoneNumber,
    required String message,
  }) async {
    final cleaned = sanitizePhoneNumber(phoneNumber);
    if (cleaned.isEmpty) return false;

    try {
      // نستخدم Uri.encodeComponent بدلاً من queryParameters
      // لأن queryParameters في Dart يستخدم application/x-www-form-urlencoded
      // مما يحول المسافات إلى علامات +، بينما تطبيقات SMS في أندرويد تتطلب %20
      final encodedBody = Uri.encodeComponent(message);
      final Uri uri = Uri.parse('sms:$cleaned?body=$encodedBody');

      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      } else {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      return false;
    }
  }

  /// إرسال رسالة عبر تطبيق واتساب
  Future<bool> sendWhatsApp({
    required String phoneNumber,
    required String message,
  }) async {
    final formatted = formatPhoneForWhatsApp(phoneNumber);
    if (formatted.isEmpty) return false;

    try {
      final encodedMessage = Uri.encodeComponent(message);
      // تجربة رابط wa.me المباشر
      final url = Uri.parse('https://wa.me/$formatted?text=$encodedMessage');
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
