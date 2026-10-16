/// ثوابت النصوص المركزية في التطبيق (منع النصوص السحرية)
class AppStrings {
  AppStrings._();

  // اسم التطبيق والعناوين العامة
  static const String appTitle = 'نظام مخصصات الوقود';

  // شريط التبويب السفلي
  static const String navHome = 'الرئيسية';
  static const String navAccounts = 'الحسابات';
  static const String navReports = 'التقارير';

  // القائمة الجانبية
  static const String drawerData = 'البيانات';
  static const String dataUnits = 'الوحدات';
  static const String dataStations = 'المحطات';
  static const String dataFuelTypes = 'الأصناف';

  // شاشة الحسابات
  static const String accountsTitle = 'إدارة الحسابات';
  static const String allAccounts = 'الكل';
  static const String beneficiaries = 'المستفيدين (العملاء)';
  static const String suppliers = 'الموردين (الجهة العليا)';
  static const String addAccount = 'إضافة حساب جديد';
  static const String editAccount = 'تعديل بيانات الحساب';
  static const String deleteAccount = 'حذف الحساب';
  static const String accountName = 'اسم الحساب';
  static const String accountType = 'نوع الحساب';
  static const String phoneNumber = 'رقم الهاتف';
  static const String searchAccountHint = 'بحث بالاسم أو رقم الهاتف...';
  static const String noAccountsFound = 'لا توجد حسابات مسجلة';
  static const String typeBeneficiary = 'مستفيد';
  static const String typeSupplier = 'مورد';

  // العمليات
  static const String supplyQuota = 'توريد اعتماد';
  static const String supplyActual = 'توريد فعلي';
  static const String aerationCommission = 'عمولة تهوية';
  static const String dispenseQuota = 'صرف اعتماد';
  static const String dispenseActual = 'صرف فعلي';
  static const String accountOperations = 'عمليات الحساب';
  static const String accountStatement = 'كشف حساب';
  static const String newOperation = 'تسجيل عملية جديدة';
  static const String addOperation = 'إضافة عملية';
  static const String viewTransactions = 'عرض العمليات';
  static const String noTransactionsFound = 'لا توجد عمليات مسجلة لهذا الحساب';
  static const String searchTransactionHint = 'بحث بالبيان أو المحطة...';
  static const String totalQuota = 'إجمالي الاعتماد';
  static const String totalActual = 'إجمالي المنفذ الفعلي';
  static const String balanceQuota = 'الرصيد المتبقي';
  static const String totalOperations = 'عدد العمليات';
  static const String operationDetails = 'تفاصيل العملية';
  static const String transactionNumber = 'رقم السند';
  static const String transactionDate = 'تاريخ العملية';
  static const String station = 'المحطة';
  static const String executingStation = 'المحطة المنفذة';
  static const String referenceStation = 'مرجع الخصم (محطة أخرى)';
  static const String selectStation = 'اختر المحطة';
  static const String selectExecutingStation = 'اختر المحطة المنفذة';
  static const String selectReferenceStation = 'اختر المحطة المرجعية';
  static const String transferQuotaNotice = 'صرف بمقاصة من محطة أخرى';
  static const String fuelType = 'نوع الوقود';
  static const String selectFuelType = 'اختر نوع الوقود';
  static const String operationType = 'نوع العملية';
  static const String selectOperationType = 'اختر نوع العملية';
  static const String unit = 'الوحدة';
  static const String quantity = 'الكمية';
  static const String equivalentInLiters = 'المعادل باللتر';
  static const String statement = 'البيان';
  static const String notes = 'البيان';
  static const String confirmDeleteTransactionTitle = 'تأكيد حذف العملية';
  static const String confirmDeleteTransactionMsg =
      'هل أنت متأكد من حذف هذا القيد من سجل الحساب؟';
  static const String quotaFilter = 'الاعتمادات';
  static const String actualFilter = 'الفعلي';
  static const String allFilter = 'الكل';

  // إضافات الأرصدة المباشرة
  static const String liveBalance = 'الأرصدة الحالية المتاحة:';
  static const String accountBalance = 'رصيد الحساب:';
  static const String stationBalance = 'رصيد المحطة:';
  static const String refresh = 'تحديث السجل';
  static const String withoutStation = '(بدون محطة)';
  static const String noStationHint = 'بدون محطة';
  static const String invalidQuantity = 'يرجى إدخال كمية صحيحة أكبر من الصفر';
  static const String transactionDeletedSuccess = 'تم حذف العملية بنجاح';
  static const String recordFirstOperation = 'تسجيل أول عملية لهذا الحساب';
  static const String suppliedQuota = 'التوريد المعتمد';
  static const String suppliedActual = 'التوريد الفعلي';
  static const String differenceBalance = 'الفارق / المتبقي';
  static const String equivalentBalanceLabel = 'المكافئ للرصيد المتبقي:';
  static const String notSpecified = 'غير محدد';
  static const String operation = 'عملية';

  // ملصقات نافذة التفاصيل
  static const String labelTransactionNumber = 'رقم السند:';
  static const String labelOperationType = 'نوع العملية:';
  static const String labelDate = 'التاريخ:';
  static const String labelStation = 'المحطة:';
  static const String labelReferenceStation = 'مرجع الخصم:';
  static const String labelFuelType = 'نوع الوقود:';
  static const String labelEnteredQuantity = 'الكمية المدخلة:';
  static const String labelEquivalentLiters = 'المعادل باللتر:';
  static const String labelStatement = 'البيان:';

  // الوحدات
  static const String unitLiter = 'لتر';
  static const String unitDabba = 'دبة';
  static const String unitBarrel = 'برميل';

  // أزرار وإجراءات
  static const String save = 'حفظ';
  static const String cancel = 'إلغاء';
  static const String confirm = 'تأكيد';
  static const String delete = 'حذف';
  static const String edit = 'تعديل';
  static const String details = 'تفاصيل';
  static const String close = 'إغلاق';
  static const String back = 'رجوع';

  // تنبيهات ورسائل
  static const String confirmDeleteTitle = 'تأكيد الحذف';
  static const String confirmDeleteMessage = 'هل أنت متأكد من حذف هذا الحساب؟';
  static const String requiredField = 'هذا الحقل مطلوب';
  static const String operationSuccess = 'تمت العملية بنجاح';
  static const String operationFailed = 'حدث خطأ أثناء تنفيذ العملية';
}
