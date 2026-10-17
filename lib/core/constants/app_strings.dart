/// ثوابت النصوص المركزية في التطبيق (منع النصوص السحرية)
class AppStrings {
  AppStrings._();

  // اسم التطبيق والعناوين العامة
  static const String appTitle = 'نظام مخصصات الوقود';
  static const String appVersionOfficial = 'الإصدار: 1.0.0 (رسمي)';
  static const String aboutAppDescription =
      'نظام متكامل لإدارة ومحاسبة مخصصات واعتمادات الوقود ومطابقة كشوفات الحسابات والمحطات بدقة وموثوقية.';

  // شريط التبويب السفلي
  static const String navHome = 'الرئيسية';
  static const String navAccounts = 'الحسابات';
  static const String navReports = 'التقارير';
  static const String navSettings = 'الإعدادات';

  // القائمة الجانبية والدليل
  static const String drawerData = 'البيانات';
  static const String dataUnits = 'الوحدات';
  static const String dataStations = 'المحطات';
  static const String dataFuelTypes = 'الأصناف';
  static const String fuelTypesDirectory = 'دليل أصناف الوقود';
  static const String unitsDirectory = 'دليل الوحدات';
  static const String stationsDirectory = 'دليل محطات الوقود';
  static const String approvedUnitsList = 'قائمة الوحدات المعتمدة';
  static const String approvedStationsList = 'قائمة المحطات المعتمدة';
  static const String registeredFuelTypes = 'الأصناف المسجلة';

  // شاشة الحسابات والتبويبات
  static const String accountsTitle = 'إدارة الحسابات';
  static const String allAccounts = 'الكل';
  static const String beneficiaries = 'المستفيدين (العملاء)';
  static const String suppliers = 'الموردين (الجهة العليا)';
  static const String beneficiariesTab = 'المستفيدين';
  static const String suppliersTab = 'الموردين';
  static const String stationsTab = 'المحطات';
  static const String fuelStationsTabTitle = 'محطات الوقود';
  static const String addAccount = 'إضافة حساب جديد';
  static const String editAccount = 'تعديل بيانات الحساب';
  static const String deleteAccount = 'حذف الحساب';
  static const String archiveAccountTitle = 'أرشفة الحساب';
  static const String archiveStationTitle = 'أرشفة المحطة';
  static const String accountName = 'اسم الحساب';
  static const String accountType = 'نوع الحساب';
  static const String phoneNumber = 'رقم الهاتف';
  static const String searchAccountHint = 'بحث بالاسم أو رقم الهاتف...';
  static const String searchStationsHint = 'بحث في المحطات أو الموقع...';
  static const String searchSuppliersHint = 'بحث في الموردين أو الهاتف...';
  static const String searchBeneficiariesHint =
      'بحث في المستفيدين أو الهاتف...';
  static const String searchStationTransactionsHint =
      'بحث في عمليات المحطة أو التاريخ أو البيان...';
  static const String noAccountsFound = 'لا توجد حسابات مسجلة';
  static const String noBeneficiariesFound = 'لا يوجد مستفيدين مسجلين حتى الآن';
  static const String noSuppliersFound = 'لا يوجد موردين مسجلين حتى الآن';
  static const String noStationsRecordedYet = 'لا توجد محطات مسجلة بعد';
  static const String noUnitsRecordedYet = 'لا توجد وحدات مسجلة بعد';
  static const String noFuelTypesRecordedYet = 'لا توجد أصناف مسجلة بعد';
  static const String noStationTransactionsFound =
      'لا توجد عمليات مسجلة لهذه المحطة حتى الآن';
  static const String typeBeneficiary = 'مستفيد';
  static const String typeSupplier = 'مورد';
  static const String addBeneficiary = 'إضافة مستفيد';
  static const String addSupplier = 'إضافة مورد';
  static const String addStation = 'إضافة محطة';
  static const String editStation = 'تعديل محطة';
  static const String addFuelType = 'إضافة صنف';
  static const String editFuelType = 'تعديل صنف';
  static const String fuelTypeNameLabel = 'اسم الصنف';
  static const String addUnit = 'إضافة وحدة';
  static const String editUnit = 'تعديل وحدة';
  static const String unitNameLabel = 'اسم الوحدة';
  static const String conversionFactorLabel = 'معامل التحويل إلى لتر';
  static const String stationNameLabel = 'اسم المحطة';
  static const String locationCityLabel = 'الموقع / المدينة';
  static const String commissionRatePercentLabel = 'نسبة عمولة التهوية (%)';
  static const String commissionRatePrefix = 'نسبة التهوية: ';
  static const String commissionRateLabel = 'عمولة التهوية: ';
  static const String baseUnitBadge = 'أساسية';
  static const String countPrefix = 'العدد: ';

  // العمليات والقيود
  static const String supplyQuota = 'توريد اعتماد';
  static const String supplyActual = 'توريد فعلي';
  static const String aerationCommission = 'عمولة تهوية';
  static const String aerationCommissionTitle = 'عمولة التهوية';
  static const String dispenseQuota = 'صرف اعتماد';
  static const String dispenseActual = 'صرف فعلي';
  static const String actualSupply = 'الوارد الفعلي';
  static const String actualDispense = 'المنصرف الفعلي';
  static const String quota = 'اعتماد';
  static const String actual = 'فعلي';
  static const String ratio = 'نسبة';
  static const String supply = 'توريد';
  static const String dispense = 'صرف';
  static const String accountOperations = 'عمليات الحساب';
  static const String accountStatement = 'كشف حساب';
  static const String stationStatementTitle = 'كشف حساب المحطة';
  static const String stationStatementPrefix = 'كشف حساب محطة: ';
  static const String newOperation = 'تسجيل عملية جديدة';
  static const String addOperation = 'إضافة عملية';
  static const String registerOperation = 'تسجيل قيد';
  static const String editOperation = 'تعديل قيد';
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
  static const String referenceStationShort = 'مرجع المحطة';
  static const String selectStation = 'اختر المحطة';
  static const String selectExecutingStation = 'اختر المحطة المنفذة';
  static const String selectReferenceStation = 'اختر المحطة المرجعية';
  static const String selectAccount = 'اختر الحساب';
  static const String transferQuotaNotice = 'صرف بمقاصة من محطة أخرى';
  static const String fuelType = 'نوع الوقود';
  static const String selectFuelType = 'اختر نوع الوقود';
  static const String operationType = 'نوع العملية';
  static const String selectOperationType = 'اختر نوع العملية';
  static const String unit = 'الوحدة';
  static const String quantity = 'الكمية';
  static const String equivalentInLiters = 'المعادل باللتر';
  static const String equivalentPrefix = 'المعادل:';
  static const String statement = 'البيان';
  static const String notes = 'البيان';
  static const String quotaFilter = 'الاعتمادات';
  static const String actualFilter = 'الفعلي';
  static const String allFilter = 'الكل';
  static const String filterSupplyActual = 'وارد فعلي';
  static const String filterDispenseActual = 'منصرف فعلي';
  static const String filterAeration = 'تهوية';
  static const String liveBalance = 'الأرصدة الحالية المتاحة:';
  static const String accountBalance = 'رصيد الحساب:';
  static const String stationBalance = 'رصيد المحطة:';
  static const String refresh = 'تحديث السجل';
  static const String withoutStation = '(بدون محطة)';
  static const String noStationHint = 'بدون محطة';
  static const String invalidQuantity = 'يرجى إدخال كمية صحيحة أكبر من الصفر';
  static const String transactionDeletedSuccess = 'تم حذف العملية بنجاح';
  static const String recordFirstOperation = 'تسجيل أول عملية لهذا الحساب';
  static const String recordFirstStationOperation = 'تسجيل أول عملية في المحطة';
  static const String suppliedQuota = 'التوريد المعتمد';
  static const String suppliedActual = 'التوريد الفعلي';
  static const String differenceBalance = 'الفارق / المتبقي';
  static const String equivalentBalanceLabel = 'المكافئ للرصيد المتبقي:';
  static const String notSpecified = 'غير محدد';
  static const String operation = 'عملية';
  static const String offsetDiscountFromPrefix = 'بمقاصة خصم من: ';
  static const String supplierPrefix = 'المورد: ';
  static const String beneficiaryPrefix = 'العميل: ';

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
  static const String referenceNumberLabel = 'رقم المرجع:';
  static const String linkedAccountLabel = 'الحساب المرتبط:';

  // الأصناف والوحدات
  static const String unitLiter = 'لتر';
  static const String unitDabba = 'دبة';
  static const String unitBarrel = 'برميل';
  static const String fuelPetrol = 'بترول';
  static const String fuelGasoline = 'بنزين';
  static const String fuelDiesel = 'ديزل';

  // أزرار وإجراءات
  static const String save = 'حفظ';
  static const String cancel = 'إلغاء';
  static const String confirm = 'تأكيد';
  static const String delete = 'حذف';
  static const String edit = 'تعديل';
  static const String archive = 'أرشفة';
  static const String details = 'تفاصيل';
  static const String close = 'إغلاق';
  static const String back = 'رجوع';
  static const String ok = 'حسناً';
  static const String search = 'بحث';
  static const String closeSearch = 'إغلاق البحث';
  static const String selectEllipsis = 'اختر...';
  static const String zeroDecimal = '0.00';

  // تنبيهات ورسائل
  static const String confirmExclamation = 'تأكيد!';
  static const String confirmDeleteTitle = 'تأكيد الحذف';
  static const String confirmDeleteMessage = 'هل أنت متأكد من حذف هذا الحساب؟';
  static const String confirmDeleteAccountMsg = 'هل تريد حذف هذا الحساب؟';
  static const String confirmDeleteStationMsg = 'هل تريد حذف هذه المحطة؟';
  static const String confirmDeleteFuelTypeMsg = 'هل تريد حذف هذا الصنف؟';
  static const String confirmDeleteUnitMsg = 'هل تريد حذف هذه الوحدة؟';
  static const String confirmDeleteTransactionTitle = 'تأكيد حذف العملية';
  static const String confirmDeleteTransactionMsg =
      'هل أنت متأكد من حذف هذا القيد من سجل الحساب؟';
  static const String confirmDeleteTransactionShortMsg =
      'هل تريد حذف هذا القيد؟';
  static const String confirmDeleteStationTransactionMsg =
      'هل تريد حذف هذا القيد من سجل المحطة؟';
  static const String confirmLogoutTitle = 'تسجيل الخروج';
  static const String confirmLogoutMsg =
      'هل تريد حقاً تسجيل الخروج من التطبيق؟';
  static const String logoutSuccessMsg = 'تم تسجيل الخروج بنجاح';
  static const String requiredField = 'هذا الحقل مطلوب';
  static const String operationSuccess = 'تمت العملية بنجاح';
  static const String operationFailed = 'حدث خطأ أثناء تنفيذ العملية';

  // الشاشات الثابتة ولوحة التحكم
  static const String dashboard = 'الرئيسية';
  static const String homeUnderDevelopmentMsg =
      'سيتم تفعيل لوحة المؤشرات والأرصدة في الخطوة التالية';
  static const String reportsAndReconciliation = 'التقارير والمطابقات';
  static const String reportsUnderDevelopmentMsg =
      'سيتم تفعيل كشوف الحسابات والتقارير المحاسبية في المرحلة المخصصة';

  // الإعدادات
  static const String settingsTitle = 'الإعدادات';
  static const String languageTitle = 'اللغة';
  static const String themeTitle = 'المظهر';
  static const String permissionsTitle = 'الأذونات';
  static const String profileTitle = 'الحسين علي المتوكل';
  static const String editProfile = 'تعديل الملف الشخصي';
  static const String account = 'الحساب';
  static const String theme = 'المظهر';
  static const String themeSystem = 'النظام';
  static const String themeLight = 'فاتح';
  static const String themeDark = 'مظلم';
  static const String appLanguage = 'لغة التطبيق';
  static const String languageArabic = 'العربية (Arabic)';
  static const String languageEnglish = 'الإنجليزية (English)';
  static const String hapticFeedback = 'ردود فعل لمسية';
  static const String permissionsManagement = 'إدارة الأذونات';
  static const String micPermission = 'ميكروفون';
  static const String cameraPermission = 'كاميرا';
  static const String photosPermission = 'صور';
  static const String permissionOn = 'تشغيل';
  static const String permissionOff = 'إغلاق';
  static const String aboutApp = 'حول التطبيق';
  static const String logout = 'تسجيل الخروج';
  static const String underDevelopment = 'تحت التطوير';
}
