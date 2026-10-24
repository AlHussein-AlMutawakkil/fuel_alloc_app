/// نموذج المتغير الديناميكي المستخدم في القوالب
class TemplatePlaceholder {
  final String tag;
  final String arabicTag;
  final String label;
  final String example;

  const TemplatePlaceholder({
    required this.tag,
    required this.arabicTag,
    required this.label,
    required this.example,
  });
}

/// نموذج قالب الرسائل النصية
class MessageTemplateModel {
  final int? id;
  final String key;
  final String title;
  final String targetType; // 'STATION' | 'BENEFICIARY' | 'SUPPLIER' | 'ANY'
  final String operationType; // 'DISPENSE' | 'SUPPLY' | 'TRANSFER' | 'ALL'
  final String content;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  const MessageTemplateModel({
    this.id,
    required this.key,
    required this.title,
    required this.targetType,
    required this.operationType,
    required this.content,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  /// قائمة المتغيرات المدعومة في قوالب الرسائل
  static const List<TemplatePlaceholder> supportedPlaceholders = [
    TemplatePlaceholder(
      tag: '{account_name}',
      arabicTag: '{اسم_العميل}',
      label: 'اسم العميل / الطرف',
      example: 'شركة النور',
    ),
    TemplatePlaceholder(
      tag: '{station_name}',
      arabicTag: '{اسم_المحطة}',
      label: 'اسم المحطة',
      example: 'محطة السلام',
    ),
    TemplatePlaceholder(
      tag: '{operation_type}',
      arabicTag: '{نوع_العملية}',
      label: 'نوع العملية',
      example: 'صرف اعتماد',
    ),
    TemplatePlaceholder(
      tag: '{quantity}',
      arabicTag: '{الكمية}',
      label: 'الكمية',
      example: '500',
    ),
    TemplatePlaceholder(
      tag: '{unit}',
      arabicTag: '{الوحدة}',
      label: 'الوحدة',
      example: 'لتر',
    ),
    TemplatePlaceholder(
      tag: '{fuel_type}',
      arabicTag: '{نوع_الوقود}',
      label: 'نوع الوقود',
      example: 'ديزل',
    ),
    TemplatePlaceholder(
      tag: '{remaining_balance}',
      arabicTag: '{الرصيد_المتبقي}',
      label: 'الرصيد المتبقي',
      example: '1,250',
    ),
    TemplatePlaceholder(
      tag: '{transaction_no}',
      arabicTag: '{رقم_العملية}',
      label: 'رقم العملية',
      example: 'TX-10024',
    ),
    TemplatePlaceholder(
      tag: '{reference_no}',
      arabicTag: '{رقم_المرجع}',
      label: 'رقم السند / المرجع',
      example: 'REF-889',
    ),
    TemplatePlaceholder(
      tag: '{recipient_name}',
      arabicTag: '{اسم_المستلم}',
      label: 'المستلم / السائق',
      example: 'أحمد علي',
    ),
    TemplatePlaceholder(
      tag: '{date}',
      arabicTag: '{التاريخ}',
      label: 'تاريخ العملية',
      example: '2026/10/24',
    ),
    TemplatePlaceholder(
      tag: '{notes}',
      arabicTag: '{الملاحظات}',
      label: 'الملاحظات',
      example: 'سيارة هايلوكس رقم 1234',
    ),
  ];

  /// القوالب الافتراضية التأسيسية
  static const String defaultStationDispense =
      'أمر صرف وقود:\n'
      'الإخوة في {اسم_المحطة} المحترمين، يرجى صرف كمية {الكمية} {الوحدة} من {نوع_الوقود} '
      'لصالح {اسم_العميل} (المستلم: {اسم_المستلم}). '
      'رقم العملية: {رقم_العملية}، مرجع: {رقم_المرجع}.';

  static const String defaultBeneficiaryDispense =
      'عزيزي {اسم_العميل}،\n'
      'تم بنجاح تنفيذ {نوع_العملية} بكمية {الكمية} {الوحدة} ({نوع_الوقود}) عبر {اسم_المحطة}. '
      'رصيدك المتبقي: {الرصيد_المتبقي} {الوحدة}. '
      'رقم العملية: {رقم_العملية}. شكراً لتعاملكم معنا.';

  static const String defaultSupplierSupply =
      'إشعار توريد وقود:\n'
      'تم بنجاح قيد توريد كمية {الكمية} {الوحدة} من {نوع_الوقود} لصالح {اسم_العميل} '
      'إلى {اسم_المحطة}. رقم العملية: {رقم_العملية}.';

  static const String defaultTransfer =
      'إشعار تحويل وقود:\n'
      'تم بنجاح تنفيذ عملية تحويل كمية {الكمية} {الوحدة} من {نوع_الوقود}. '
      'الطرف: {اسم_العميل}. الرصيد الحالي: {الرصيد_المتبقي} {الوحدة}. '
      'رقم العملية: {رقم_العملية}.';

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'template_key': key,
      'title': title,
      'target_type': targetType,
      'operation_type': operationType,
      'content': content,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
      'updated_at': updatedAt ?? DateTime.now().toIso8601String(),
    };
  }

  factory MessageTemplateModel.fromMap(Map<String, dynamic> map) {
    return MessageTemplateModel(
      id: map['id'] as int?,
      key: (map['template_key'] ?? map['key']) as String,
      title: map['title'] as String,
      targetType: (map['target_type'] ?? 'ANY') as String,
      operationType: (map['operation_type'] ?? 'ALL') as String,
      content: map['content'] as String,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  MessageTemplateModel copyWith({
    int? id,
    String? key,
    String? title,
    String? targetType,
    String? operationType,
    String? content,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return MessageTemplateModel(
      id: id ?? this.id,
      key: key ?? this.key,
      title: title ?? this.title,
      targetType: targetType ?? this.targetType,
      operationType: operationType ?? this.operationType,
      content: content ?? this.content,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
