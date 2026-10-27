/// ثوابت النصوص المركزية في التطبيق (منع النصوص السحرية)
class AppStrings {
  AppStrings._();

  // اسم التطبيق والعناوين العامة
  static const String appNameEn = 'FuelFlow';
  static const String appTitle = 'نظام مخصصات الوقود';
  static const String appVersionOfficial = 'الإصدار: 1.0.0 (رسمي)';
  static const String defaultAppLogo = 'الشعار الافتراضي للنظام';
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
  static const String typeStation = 'محطة';
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
  static const String transfer = 'تحويل';
  static const String fromAccount = 'من حساب';
  static const String toAccount = 'إلى حساب';
  static const String transferOut = 'تحويل';
  static const String transferIn = 'تحويل';
  static const String selectFromAccount = 'اختر الحساب المحوّل منه';
  static const String selectToAccount = 'اختر الحساب المحوّل إليه';
  static const String sameAccountError = 'لا يمكن التحويل لنفس الحساب';
  static const String transferSuccess = 'تمت عملية التحويل بنجاح';
  static const String supply = 'توريد';
  static const String dispense = 'صرف';
  static const String accountOperations = 'عمليات الحساب';
  static const String accountStatement = 'كشف حساب';
  static const String operationsHistory = 'سجل العمليات';
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
  static const String operationData = 'بيانات العملية';
  static const String operationLabel = 'العملية';
  static const String transactionNumber = 'رقم السند';
  static const String transactionNumberLabel = 'رقم العملية';
  static const String transactionDate = 'تاريخ العملية';
  static const String station = 'المحطة';
  static const String executingStation = 'المحطة المنفذة';
  static const String referenceStation = 'مرجع الخصم (محطة أخرى)';
  static const String referenceStationShort = 'م/ المحطة';
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
  static const String recipientLabel = 'المستلم:';
  static const String recipientNameLabel = 'اسم المستلم';
  static const String sameAsAccountName = 'المستلم بنفس اسم الحساب';
  static const String enterRecipientNameHint =
      'اكتب اسم المستلم أو اختر من القائمة...';
  static const String recipientPrefix = 'المستلم: ';

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
  static const String searchHere = 'ابحث هنا';
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
  static const String welcomeGreeting = 'مرحباً بك';
  static const String welcomeToApp = 'نظام مخصصات ومحاسبة الوقود';
  static const String systemStatusHealthy = 'قاعدة البيانات والنظام سليم 100%';
  static const String systemStatusAttention = 'تنبيه في مطابقة البيانات';
  static const String stationsFuelBalance = 'رصيد الوقود بالمحطات';
  static const String supplierSupplyTitle = 'ميزان توريد الموردين';
  static const String supplierSupplyVsActual = 'اعتماد التوريد والتوريد الفعلي';
  static const String supplierSupplyRatioTitle = 'نسبة التوريد الفعلي';
  static const String stationBalanceAndFlow = 'مخزون وحركة المحطات';
  static const String stationInflowVsOutflow = 'الوارد الفعلي والمنصرف الفعلي';
  static const String stationDispenseRatioTitle = 'نسبة المنصرف من الوارد';
  static const String beneficiaryQuotaSummary = 'ميزان صرف المستفيدين';
  static const String selectFuelTypePrompt = 'صنف الوقود:';
  static const String noStationsForFuelType =
      'لا توجد محطات لديها رصيد لهذا الصنف حالياً';
  static const String activeStationsForFuel = 'محطة بها رصيد';
  static const String quotaVsActualSummary = 'ميزان الاعتمادات والمنفذ';
  static const String quotaBalanceTitle = 'ميزان الاعتمادات';

  // الفلترة بالسنوات والشهور
  static const String filterYear = 'السنة';
  static const String filterMonth = 'الشهر';
  static const String allYears = 'كل السنوات';
  static const String allMonths = 'كل الشهور';
  static const String selectYear = 'اختر السنة';
  static const String selectMonth = 'اختر الشهر';
  static const String resetFilter = 'إلغاء الفلترة';
  static const String monthJan = 'يناير (01)';
  static const String monthFeb = 'فبراير (02)';
  static const String monthMar = 'مارس (03)';
  static const String monthApr = 'أبريل (04)';
  static const String monthMay = 'مايو (05)';
  static const String monthJun = 'يونيو (06)';
  static const String monthJul = 'يوليو (07)';
  static const String monthAug = 'أغسطس (08)';
  static const String monthSep = 'سبتمبر (09)';
  static const String monthOct = 'أكتوبر (10)';
  static const String monthNov = 'نوفمبر (11)';
  static const String monthDec = 'ديسمبر (12)';

  static String getMonthLabel(int month) {
    switch (month) {
      case 1:
        return monthJan;
      case 2:
        return monthFeb;
      case 3:
        return monthMar;
      case 4:
        return monthApr;
      case 5:
        return monthMay;
      case 6:
        return monthJun;
      case 7:
        return monthJul;
      case 8:
        return monthAug;
      case 9:
        return monthSep;
      case 10:
        return monthOct;
      case 11:
        return monthNov;
      case 12:
        return monthDec;
      default:
        return '$month';
    }
  }

  static const String quickActions = 'إجراءات سريعة';
  static const String quickDispenseActual = 'صرف وقود';
  static const String quickSupplyActual = 'توريد لمحطة';
  static const String quickTransfer = 'تحويل كمية';
  static const String stationsStockStatus = 'رصيد المحطات الحي';
  static const String recentTransactions = 'آخر العمليات المسجلة';
  static const String viewAllTransactionsAndAccounts =
      'عرض كافة الحسابات والعمليات';
  static const String noRecentTransactionsYet = 'لا توجد عمليات مسجلة حديثاً';
  static const String noStationsWithBalance =
      'لا توجد محطات لديها رصيد متاح حالياً';
  static const String stockAdequate = 'كافٍ';
  static const String stockLow = 'منخفض';
  static const String totalAvailableStock = 'إجمالي المخزون';
  static const String executionPercentage = 'نسبة التنفيذ';
  static const String remainingQuotaBalance = 'المتبقي من الاعتماد';
  static const String registeredStations = 'محطات معتمدة';
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
  static const String backup = 'النسخ الاحتياطي';
  static const String backupTitle = 'النسخ الاحتياطي';
  static const String backupSubtitle =
      'إنشاء واستعادة النسخ الاحتياطية لقاعدة البيانات';
  static const String createLocalBackup = 'إنشاء نسخة احتياطية محلية';
  static const String createLocalBackupDesc =
      'تصدير نسخة كاملة من البيانات إلى التخزين الداخلي';
  static const String restoreLocalBackup = 'استعادة نسخة احتياطية';
  static const String restoreLocalBackupDesc =
      'استرجاع البيانات من نسخة سابقة محفوظة';
  static const String cloudBackup = 'النسخ الاحتياطي السحابي';
  static const String cloudBackupDesc = 'المزامنة السحابية مع Google Drive';
  static const String autoBackup = 'النسخ الاحتياطي التلقائي';
  static const String autoBackupDesc =
      'أخذ نسخة احتياطية دورياً لحماية بياناتك';
  static const String backupSuccessMsg = 'تم إنشاء النسخة الاحتياطية بنجاح';
  static const String restoreSuccessMsg = 'تمت استعادة البيانات بنجاح';
  static const String googleDriveConnected = 'متصل بـ Google Drive';
  static const String googleDriveNotConnected = 'غير متصل';
  static const String connectGoogleDrive = 'ربط حساب Google';
  static const String disconnectGoogleDrive = 'تسجيل الخروج';
  static const String switchGoogleAccount = 'تبديل الحساب';
  static const String lastCloudSyncPrefix = 'آخر مزامنة: ';
  static const String noSyncYet = 'لم تتم المزامنة السحابية بعد';
  static const String syncNow = 'مزامنة الآن';
  static const String syncing = 'جاري المزامنة...';
  static const String cloudSyncSuccess =
      'تمت المزامنة والرفع إلى Google Drive بنجاح';
  static const String cloudRestoreSuccess =
      'تمت استعادة البيانات من النسخة السحابية بنجاح';
  static const String cloudSyncError = 'حدث خطأ أثناء الاتصال بـ Google Drive';
  static const String confirmDisconnectGoogleTitle = 'فصل حساب Google';
  static const String confirmDisconnectGoogleMsg =
      'هل تريد حقاً تسجيل الخروج وفصل الربط مع Google Drive؟';
  static const String googleAccount = 'حساب Google';
  static const String restoreFailed =
      'فشلت استعادة البيانات أو أن ملف النسخة غير صالح';
  static const String restoreLatestBackup = 'استعادة الأحدث';
  static const String viewAllBackups = 'استعراض الكل';
  static const String restoreConfirmPrompt =
      'هل تريد استعادة أحدث نسخة احتياطية محلية أم استعراض جميع النسخ؟';

  // نوع النسخة الاحتياطية
  static const String backupType = 'نوع النسخة الاحتياطية';
  static const String backupTypeSubtitle =
      'حدد آلية حفظ وأرشفة بيانات العمليات والحسابات';
  static const String backupFullTitle = 'النسخ الاحتياطية الكاملة';
  static const String backupFullDesc =
      'أنشئ دائماً نسخاً احتياطية جديدة بجميع بيانات وسجلات العمليات والحسابات المتاحة.';
  static const String backupArchiveTitle = 'وضع الأرشيف';
  static const String backupArchiveDesc =
      'أضف العمليات وسجلات الحسابات الجديدة إلى ملف النسخة الاحتياطية نفسه.';
  static const String backupIncrementalTitle = 'النسخ الاحتياطية التزايدية';
  static const String backupIncrementalDesc =
      'أنشئ ملفات جديدة لكل نسخة احتياطية لكن احفظ فقط العمليات وسجلات الحسابات الجديدة منذ آخر نسخة احتياطية.';
  static const String createFullBackupNew = 'إنشاء نسخة احتياطية كاملة جديدة';
  static const String every7Days = 'بعد كل 7 أيام';
  static const String everyMonth = 'كل شهر';
  static const String chooseDays = 'اختر الأيام';
  static const String forceFullBackupNextRun =
      'فرض نسخة احتياطية كاملة في تشغيل النسخ الاحتياطي التالي';

  // إعدادات النسخ الاحتياطي المجدول
  static const String scheduledBackupTitle = 'إعدادات النسخ الاحتياطي المجدول';
  static const String scheduleRecurringBackups = 'جدولة نسخ احتياطية متكررة';
  static const String keepDataProtectedDesc = 'حافظ على بياناتك محمية باستمرار';
  static const String daily = 'يوميًا';
  static const String atTimePrefix = 'في ';
  static const String change = 'تغيير';
  static const String repeatDaily = 'كرّر كل يوم';
  static const String weekly = 'أسبوعيًا';
  static const String hourly = 'كل ساعة';
  static const String hideAdvancedOptions = 'إخفاء الخيارات المتقدمة';
  static const String showAdvancedOptions = 'عرض الخيارات المتقدمة';
  static const String disableNotifications = 'تعطيل الإشعارات';
  static const String disableNotificationsDesc =
      'بعد اكتمال نسخة احتياطية مجدولة بنجاح';

  // عرض النسخ الاحتياطية
  static const String backupsListTitle = 'النسخ الاحتياطية';
  static const String viewBackups = 'عرض النسخ الاحتياطية';
  static const String viewBackupsDesc =
      'استعراض وإدارة ملفات النسخ السابقة محلياً وسحابياً';
  static const String tabLocal = 'محلي';
  static const String tabCloud = 'سحابي';
  static const String noLocalBackups = 'لا توجد نسخ احتياطية محلية';
  static const String noCloudBackups = 'لا توجد نسخ احتياطية سحابية';
  static const String localBackupEmptyDesc =
      'يمكنك إنشاء نسخة جديدة لحفظ بياناتك في أي وقت.';
  static const String cloudBackupEmptyDesc =
      'قم بربط حساب سحابي للمزامنة والوصول للنسخ السحابية.';
  static const String backupDate = 'التاريخ';
  static const String backupSize = 'الحجم';
  static const String backupTypeIntro =
      'كيف ترغب في إدارة وحفظ النسخ الاحتياطية لقاعدة البيانات والعمليات؟';
  static const String share = 'مشاركة';
  static const String repeatDaysPrefix = 'كرّر كل ';
  static const String days = 'أيام';
  static const String customDaysTitle = 'تخصيص عدد الأيام';
  static const String daysCount = 'عدد الأيام';
  static const String enterDaysCount = 'أدخل عدد الأيام';
  static const String scheduleDisabled = 'معطل';
  static const String scheduleEnabledDaily = 'مفعل - يوميًا';
  static const String scheduleEnabledWeekly = 'مفعل - أسبوعيًا';
  static const String scheduleEnabledHourly = 'مفعل - كل ساعة';
  static const String backupFullBadge = 'كاملة';
  static const String backupArchiveBadge = 'أرشيف';
  static const String backupIncrementalBadge = 'تزايدية';
  static const String backupShareSuccess = 'تمت مشاركة النسخة الاحتياطية بنجاح';
  static const String backupDeleteSuccess = 'تم حذف النسخة الاحتياطية بنجاح';
  static const String confirmDeleteBackupTitle = 'تأكيد حذف النسخة';
  static const String confirmDeleteBackupMsg =
      'هل تريد حذف ملف النسخة الاحتياطية هذا نهائياً؟';
  static const String settingsSavedSuccess = 'تم حفظ الإعدادات بنجاح';
  static const String amSuffix = 'ص';
  static const String pmSuffix = 'م';
  static const String timePrefixAt = 'في ';
  static const String customDaysDialogTitle = 'تحديد دورية الأيام';
  static const String customDaysSuffix = ' يوم';

  // التنظيف التلقائي (Auto Clean)
  static const String autoCleanTitle = 'التنظيف التلقائي';
  static const String autoCleanSubtitle =
      'اختر كيفية حذف النسخ الاحتياطية القديمة تلقائياً لكل موقع.';
  static const String incrementalBackupsHeader = 'النسخ الاحتياطية التزايدية';
  static const String deleteBeforeLastFull =
      'حذف النسخ الاحتياطية قبل آخر نسخة احتياطية كاملة';
  static const String deleteBeforeLastFullDesc =
      'أنت تستخدم النسخ الاحتياطية التزايدية، لذا لا ينطبق عليها أي من إعدادات التنظيف أدناه. تحتفظ كل نسخة احتياطية تزايدية بالسجلات المضافة منذ النسخة السابقة فقط، وحذف النسخ الأقدم حسب العمر أو العدد قد يؤدي إلى تعذر الاستعادة. لتنظيف النسخ الاحتياطية المحلية، استخدم الخيار أعلاه لحذف النسخ الاحتياطية التي أنشئت قبل آخر نسخة احتياطية كاملة.';
  static const String localBackupSection = 'نسخة احتياطية محلية';
  static const String localBackupCleanDesc =
      'تم إيقاف حد حجم التخزين السابق للنسخ الاحتياطية المحلية. يرجى اختيار أحد الخيارات أدناه.';
  static const String noDeletion = 'عدم الحذف';
  static const String keepForDays = 'الاحتفاظ بالنسخ الاحتياطية لعدد من الأيام';
  static const String keepForDaysCountUnit = 'أيام';
  static const String keepLastCount =
      'الاحتفاظ بعدد من النسخ الاحتياطية الأخيرة';
  static const String keepLastCountUnit = 'نسخ احتياطية';
  static const String keepLatestLocalCopy =
      'الاحتفاظ بنسخة محلية من أحدث نسخة احتياطية';
  static const String keepLatestLocalCopyDesc =
      'الاحتفاظ بنسخة محلية من أحدث نسخة احتياطية سحابية للاستعادة السريعة';
  static const String deleteUnuploadedBackups =
      'حذف النسخ الاحتياطية التي لم تُرْفَع بعد';
  static const String deleteUnuploadedBackupsDesc =
      'احذف أيضاً النسخ الاحتياطية المحلية التي لا تزال بانتظار الرفع إلى السحابة.';
  static const String googleDriveSection = 'GOOGLE DRIVE';
  static const String dropboxSection = 'DROPBOX';

  // الضغط والتشفير (Compression & Encryption)
  static const String compressionEncryptionTitle = 'الضغط والتشفير';
  static const String compressBackups = 'ضغط النسخ الاحتياطية';
  static const String compressBackupsDesc =
      'اضغط النسخ الاحتياطية باستخدام ضغط ZIP.';
  static const String encryptBackups = 'تشفير النسخ الاحتياطية';
  static const String encryptBackupsDesc =
      'شفّر الملف داخل ملف ZIP باستخدام تشفير AES-256.';
  static const String encryptionPasswordWarning =
      'ملاحظة: إذا نسيت كلمة المرور، فقد تصبح النسخة الاحتياطية غير قابلة للاستخدام.';
  static const String enterPassword = 'ادخال كلمة المرور:';
  static const String confirmPassword = 'تأكيد كلمة المرور:';
  static const String passwordMismatch = 'كلمتا المرور غير متطابقتين';
  static const String passwordRequired =
      'يرجى إدخال كلمة المرور لتفعيل التشفير';
  static const String enterPasswordToRestore =
      'أدخل كلمة مرور فك التشفير للاستعادة';
  static const String invalidPassword = 'كلمة المرور غير صحيحة';

  // مسار الحفظ والواي فاي
  static const String wifiOnlyTitle = 'الرفع عبر Wi-Fi فقط';
  static const String wifiOnlyDesc =
      'تجنب استهلاك بيانات باقة الهاتف عند المزامنة السحابية';
  static const String wifiRequiredMsg =
      'تم تأجيل المزامنة؛ مفعل خيار Wi-Fi فقط والاتصال الحالي عبر بيانات الهاتف';
  static const String backupStorageLocation = 'مسار حفظ النسخ الاحتياطية';
  static const String backupStorageLocationDesc =
      'حدد مكان تخزين النسخ محلياً لضمان عدم فقدانها عند إزالة التطبيق';
  static const String backupStorageInternal = 'مجلد التطبيق الداخلي';
  static const String backupStorageExternal =
      'مجلد المستندات المشترك (دائم حتى بعد حذف التطبيق)';
  static const String storagePermissionDenied =
      'تم رفض إذن التخزين؛ سيتم الحفظ في المجلد الداخلي';

  static const String unregisteredUser = 'غير مسجل';
  static const String loginOrLinkAccount = 'تسجيل الدخول / ربط بحساب';
  static const String unlinkedAccount = 'غير مسجل';
  static const String linkAccount = 'ربط الحساب';
  static const String accountLinkDialogTitle = 'تسجيل الدخول / ربط الحساب';
  static const String accountLinkDialogMsg =
      'يمكنك تسجيل الدخول لربط بياناتك وحفظها سحابياً.';
  static const String alreadyLoggedOutMsg = 'أنت بالفعل غير مسجل الدخول';
  static const String theme = 'المظهر';
  static const String themeSystem = 'النظام';
  static const String themeLight = 'فاتح';
  static const String themeDark = 'مظلم';
  static const String appLanguage = 'لغة التطبيق';
  static const String languageArabic = 'العربية (Arabic)';
  static const String languageEnglish = 'الإنجليزية (English)';
  static const String hapticFeedback = 'ردود فعل لمسية';
  // سلة المحذوفات والأرشيف
  static const String recycleBinTitle = 'سلة المحذوفات';
  static const String recycleBinSubtitle =
      'استعادة أو حذف العمليات والحسابات نهائياً';
  static const String archiveTitle = 'الأرشيف';
  static const String archiveSubtitle = 'عرض الحسابات المؤرشفة واستعادتها';
  static const String tabOperations = 'العمليات';
  static const String tabAccounts = 'الحسابات';
  static const String restore = 'استعادة';
  static const String unarchive = 'إلغاء الأرشفة';
  static const String permanentDelete = 'حذف نهائي';
  static const String emptyRecycleBin = 'سلة المحذوفات فارغة';
  static const String noDeletedOperations = 'لا توجد عمليات محذوفة';
  static const String noDeletedAccounts = 'لا توجد حسابات محذوفة';
  static const String noArchivedAccounts = 'لا توجد حسابات مؤرشفة';
  static const String confirmPermanentDeleteTitle = 'تأكيد الحذف النهائي';
  static const String confirmPermanentDeleteMsg =
      'هل أنت متأكد من الحذف النهائي؟ لا يمكن التراجع عن هذا الإجراء أبداً.';
  static const String confirmRestoreTitle = 'تأكيد الاستعادة';
  static const String confirmRestoreMsg =
      'هل تريد استعادة هذا العنصر من سلة المحذوفات؟';
  static const String confirmUnarchiveTitle = 'تأكيد إلغاء الأرشفة';
  static const String confirmUnarchiveMsg =
      'هل تريد إعادة تنشيط هذا الحساب وإخراجه من الأرشيف؟';
  static const String confirmArchiveAccountMsg =
      'هل تريد نقل هذا الحساب إلى الأرشيف؟';
  static const String itemRestoredSuccess = 'تمت استعادة العنصر بنجاح';
  static const String itemDeletedPermanentSuccess = 'تم الحذف النهائي بنجاح';
  static const String accountArchivedSuccess = 'تمت أرشفة الحساب بنجاح';
  static const String accountUnarchivedSuccess =
      'تمت استعادة الحساب من الأرشيف بنجاح';
  static const String stationArchivedSuccess = 'تمت أرشفة المحطة بنجاح';
  static const String stationUnarchivedSuccess =
      'تمت استعادة المحطة من الأرشيف بنجاح';
  static const String confirmUnarchiveStationTitle = 'تأكيد إلغاء أرشفة المحطة';
  static const String confirmUnarchiveStationMsg =
      'هل تريد إعادة تنشيط هذه المحطة وإخراجها من الأرشيف؟';
  static const String noArchivedStations = 'لا توجد محطات مؤرشفة';
  static const String archivedStationsTab = 'المحطات';
  static const String archivedAccountsTab = 'الحسابات';
  static const String deletedAtPrefix = 'تاريخ الحذف: ';
  static const String operationsCountPrefix = 'العمليات: ';
  static const String viewAccountStatement = 'كشف الحساب';
  static const String viewDetails = 'عرض التفاصيل';
  static const String recycleBinSetting = 'سلة المحذوفات';
  static const String recycleBinSettingDesc =
      'الاحتفاظ بالعناصر المحذوفة في السلة بدلاً من الحذف المباشر';
  static const String enableRecycleBin = 'تفعيل سلة المحذوفات';

  // جهات الاتصال والأذونات
  static const String permissionsManagement = 'إدارة الأذونات';
  static const String micPermission = 'ميكروفون';
  static const String cameraPermission = 'كاميرا';
  static const String photosPermission = 'صور';
  static const String contactsPermission = 'جهات الاتصال';
  static const String contactsPermissionDesc =
      'الوصول لجهات الاتصال لاختيار وتعبئة أرقام الهواتف والأسماء تلقائياً';
  static const String pickFromContacts = 'اختيار من جهات الاتصال';
  static const String contactsPermissionDenied =
      'تم رفض الإذن بالوصول لجهات الاتصال';
  static const String cameraPermissionDenied = 'تم رفض الإذن بالوصول للكاميرا';
  static const String photosPermissionDenied =
      'تم رفض الإذن بالوصول للصور والاستوديو';
  static const String contactsEmpty = 'لم يتم العثور على جهات اتصال في الهاتف';
  static const String searchContactsHint = 'بحث بالاسم أو رقم الهاتف...';
  static const String selectContact = 'اختر جهة اتصال';
  static const String contactHasNoPhone =
      'جهة الاتصال المحددة لا تحتوي على رقم هاتف';

  // حول التطبيق
  static const String aboutApp = 'حول التطبيق';
  static const String aboutAppHeader = 'حول Fuel Alloc';
  static const String appVersionLabel = 'إصدار التطبيق';
  static const String appVersionNumber = '1.0.0';
  static const String termsOfUse = 'شروط الاستخدام';
  static const String usagePolicy = 'سياسة الاستخدام';
  static const String privacyPolicy = 'اتفاقية الخصوصية';

  static const String logout = 'تسجيل الخروج';
  static const String underDevelopment = 'تحت التطوير';

  // مسار حفظ النسخ والنسخ المتكررة
  static const String backupStorageLocationSelectTitle =
      'تحديد مسار حفظ النسخ الاحتياطية';
  static const String backupStorageInternalTitle = 'ذاكرة التخزين الداخلية';
  static const String backupStorageInternalDesc =
      'مجلد التطبيق الداخلي الآمن (يوصى به)';
  static const String backupStorageExternalTitle = 'ذاكرة التخزين المشتركة';
  static const String backupStorageExternalDesc =
      'مجلد المستندات المشترك (دائم ولا يحذف مع التطبيق)';
  static const String backupStorageCurrentPath = 'المسار الفعلي الحالي:';
  static const String copyPath = 'نسخ المسار';
  static const String pathCopied = 'تم نسخ المسار إلى الحافظة بنجاح';
  static const String backupNoChangesToUpload =
      'لا توجد أي تغييرات جديدة على قاعدة البيانات تستدعي المزامنة';
  static const String cleanDuplicateCloudBackups =
      'تنظيف النسخ السحابية المكررة';
  static const String cleanDuplicatesDesc =
      'حذف النسخ المتطابقة من Google Drive والإبقاء على النسخ الفريدة فقط';
  static const String cleanDuplicatesConfirmTitle =
      'تأكيد تنظيف النسخ السحابية';
  static const String cleanDuplicatesConfirmMsg =
      'سيتم فحص جميع النسخ في Google Drive وحذف النسخ المكررة والمتطابقة تلقائياً لتوفير المساحة وتنظيم السحابة. هل تريد المتابعة؟';
  static const String cleanDuplicatesSuccess =
      'تم تنظيف النسخ المكررة بنجاح وحذف الملفات الزائدة';
  static const String noDuplicatesFound =
      'السحابة منظمة بالفعل، لا توجد نسخ مكررة';
  static const String cleaningDuplicates =
      'جارٍ تنظيف النسخ المكررة من Google Drive...';
  static const String dropboxComingSoon =
      'مزامنة Dropbox قيد التطوير وستتوفر قريباً';
  static const String editCount = 'تعديل العدد';
  static const String editDays = 'تعديل الأيام';

  // --- نظام الرسائل النصية والقوالب ---
  static const String messageSettingsTitle = 'الرسائل النصية والقوالب';
  static const String messageSettingsDesc =
      'إدارة قوالب الرسائل وإشعارات العمليات للمحطات والمستفيدين';
  static const String enableMessagingTitle = 'تفعيل نظام الرسائل';
  static const String enableMessagingDesc =
      'تجهيز وإرسال الإشعارات للمستفيدين والمحطات عند تسجيل العمليات';
  static const String preferredChannelTitle = 'طريقة الإرسال الافتراضية';
  static const String channelSms = 'رسائل نصية (SMS)';
  static const String channelWhatsApp = 'واتساب (WhatsApp)';
  static const String autoPreviewTitle = 'معاينة الرسائل بعد كل عملية';
  static const String autoPreviewDesc =
      'إظهار نافذة مراجعة وتعديل نص الرسالة فور حفظ أي عملية';
  static const String defaultNotifyStationTitle = 'إشعار المحطة افتراضياً';
  static const String defaultNotifyStationDesc =
      'تحديد خيار إرسال أمر الصرف للمحطة تلقائياً في نافذة الإرسال';
  static const String defaultNotifyAccountTitle = 'إشعار المستفيد افتراضياً';
  static const String defaultNotifyAccountDesc =
      'تحديد خيار إرسال الإشعار للعميل أو المستفيد تلقائياً في نافذة الإرسال';
  static const String messageTemplatesSection = 'قوالب الرسائل الديناميكية';
  static const String messageTemplatesSectionDesc =
      'انقر على أي قالب لتعديل صياغته وإضافة المتغيرات الذكية';
  static const String editTemplateTitle = 'تعديل قالب الرسالة';
  static const String templateContentLabel = 'نص القالب';
  static const String availableVariables =
      'المتغيرات الذكية (انقر للإدراج في النص)';
  static const String resetTemplates = 'استعادة القوالب الافتراضية';
  static const String resetTemplatesConfirm =
      'هل أنت متأكد من استعادة كافة القوالب إلى نصوصها الافتراضية الأصلية؟';
  static const String templateUpdatedSuccess = 'تم تحديث القالب بنجاح';
  static const String templatesResetSuccess =
      'تم استعادة القوالب الافتراضية بنجاح';
  static const String sendSmsButton = 'إرسال SMS';
  static const String sendWhatsAppButton = 'إرسال WhatsApp';
  static const String operationMessagesTitle = 'إرسال إشعار العملية';
  static const String beneficiaryNotice = 'إشعار المستفيد / العميل';
  static const String stationOrder = 'أمر صرف المحطة';
  static const String noPhoneAvailable = 'لا يوجد رقم هاتف مسجل';
  static const String customAccountTemplate =
      'قالب رسائل مخصص لهذا الحساب (اختياري)';
  static const String customAccountTemplateHint =
      'اتركه فارغاً للاعتماد على القالب العام';
  static const String enableAccountMessaging =
      'تفعيل إرسال الرسائل لهذا الحساب';
  static const String notificationPhoneLabel = 'رقم هاتف الإشعارات (اختياري)';
  static const String copyMessageText = 'نسخ نص الرسالة';
  static const String messageTextCopied = 'تم نسخ نص الرسالة إلى الحافظة';
  static const String sendFailed =
      'تعذر إطلاق تطبيق الإرسال، يرجى التأكد من توفر التطبيق والرقم';
  static const String stationDispenseOrderTemplateTitle = 'أمر صرف وقود للمحطة';
  static const String beneficiaryDispenseNoticeTemplateTitle =
      'إشعار صرف وقود للمستفيد';
  static const String supplierSupplyNoticeTemplateTitle = 'إشعار توريد وقود';
  static const String transferNoticeTemplateTitle = 'إشعار تحويل وقود';
  static const String closeDialog = 'تم / إنهاء';
  static const String execute = 'تنفيذ';
  static const String verifyMessageNotice =
      'يرجى التحقق من البيانات قبل التنفيذ';

  // --- البيانات الشخصية ---
  static const String personalInfo = 'البيانات الشخصية';
  static const String personalInfoSubtitle =
      'الاسم، العناوين، أرقام التواصل، والشعار والختم والتوقيع';
  static const String personalInfoViewTitle = 'إعدادات البيانات الشخصية';
  static const String generalInfoSection = 'المعلومات الأساسية والعناوين';
  static const String arabicNameLabel = 'الاسم باللغة العربية';
  static const String arabicNameHint = 'أدخل الاسم الرسمي بالعربية';
  static const String englishNameLabel = 'الاسم باللغة الإنجليزية';
  static const String englishNameHint = 'Enter English Name';
  static const String arabicAddressLabel = 'العنوان باللغة العربية';
  static const String arabicAddressHint = 'المدينة، الشارع، المحافظة...';
  static const String englishAddressLabel = 'العنوان باللغة الإنجليزية';
  static const String englishAddressHint = 'City, Street, State...';
  static const String contactNumbersLabel = 'أرقام التواصل';
  static const String contactNumbersHint =
      'أرقام الهواتف أو الواتساب مفصولة بفاصلة';
  static const String brandingSection = 'الشعار والختم والتوقيع';
  static const String logoLabel = 'شعار المنشأة (Logo)';
  static const String stampLabel = 'الختم الرسمي (Stamp)';
  static const String signatureLabel = 'التوقيع المعتمد (Signature)';
  static const String selectLogo = 'اختيار الشعار';
  static const String selectStamp = 'اختيار الختم';
  static const String selectSignature = 'اختيار التوقيع';
  static const String changeImage = 'تغيير الصورة';
  static const String removeImage = 'حذف الصورة';
  static const String noImageSelected = 'لم يتم تحديد صورة بعد';
  static const String logoSizePercentLabel = 'حجم الشعار في المستندات';
  static const String stampSizePercentLabel = 'حجم الختم في المستندات';
  static const String signatureSizePercentLabel = 'حجم التوقيع في المستندات';
  static const String backupInclusionSection =
      'النسخ الاحتياطي للبيانات الشخصية';
  static const String includePersonalInfoInBackupTitle =
      'تضمين البيانات الشخصية في النسخة الاحتياطية';
  static const String includePersonalInfoInBackupDesc =
      'حفظ الأسماء والعناوين وملفات الشعار والختم والتوقيع ضمن ملف النسخة الاحتياطية واستعادتها تلقائياً';
  static const String savePersonalInfo = 'حفظ البيانات الشخصية';
  static const String savePersonalInfoSuccess = 'تم حفظ البيانات الشخصية بنجاح';
  static const String selectImageFromGallery = 'اختيار من المعرض';
  static const String selectImageFromCamera = 'التقاط صورة بالكاميرا';

  // --- التحليل وصحة التطبيق ---
  static const String analysis = 'التحليل';
  static const String analysisSubtitle =
      'فحص صحة النظام، إحصائيات الحسابات، تفصيل العمليات والأصناف';
  static const String analysisTitle = 'تحليل التطبيق';
  static const String systemHealthTitle = 'صحة وسلامة النظام';
  static const String systemHealthStatus = 'حالة النظام والتطبيق';
  static const String systemHealthExcellent = 'النظام سليم ومتناسق 100%';
  static const String systemHealthIssues =
      'توجد بعض التنبيهات تحتاج إلى مراجعة';
  static const String databaseIntegrity = 'سلامة قاعدة البيانات';
  static const String databaseIntegrityOk = 'تم التحقق (سليمة تماماً)';
  static const String databaseSize = 'حجم قاعدة البيانات';
  static const String totalDatabaseRecords = 'إجمالي السجلات المخزنة';
  static const String lastBackupDate = 'آخر نسخة احتياطية';
  static const String noBackupFound = 'لا توجد نسخة احتياطية بعد';
  static const String runDiagnostics = 'إجراء فحص فوري للنظام';
  static const String diagnosticsRunning = 'جاري فحص وتدقيق سلامة البيانات...';
  static const String diagnosticsSuccess =
      'اكتمل الفحص: قاعدة البيانات والقيود متطابقة وسليمة 100%';
  static const String accountsAnalysisTitle = 'تحليل وإحصائيات الحسابات';
  static const String totalAccountsCount = 'إجمالي الحسابات';
  static const String activeAccountsCount = 'حسابات نشطة';
  static const String beneficiariesCount = 'المستفيدون (العملاء)';
  static const String stationsCount = 'المحطات';
  static const String suppliersCount = 'الموردون';
  static const String archivedAccountsCount = 'حسابات مؤرشفة';
  static const String deletedAccounts = 'حسابات في سلة المحذوفات';
  static const String transactionsAnalysisTitle = 'تحليل وتفصيل العمليات';
  static const String totalTransactionsCount = 'إجمالي العمليات';
  static const String activeTransactionsCount = 'عمليات نشطة';
  static const String deletedTransactionsCount = 'عمليات في سلة المهملات';
  static const String quotaTransactionsTitle = 'اعتمادات الحصص (مخصصات)';
  static const String supplyQuotaTransactionsTitle = 'توريد اعتماد';
  static const String dispenseQuotaTransactionsTitle = 'صرف اعتماد';
  static const String supplyActualTransactionsTitle = 'توريد فعلي';
  static const String dispenseActualTransactionsTitle = 'صرف فعلي';
  static const String supplyTransactionsTitle = 'توريد فعلي';
  static const String dispenseTransactionsTitle = 'صرف فعلي';
  static const String aerationTransactionsTitle = 'عمولة التهوئة';
  static const String transferTransactionsTitle = 'تحويلات الوقود';
  static const String fuelTypesAndUnitsTitle = 'أصناف الوقود والوحدات';
  static const String fuelTypesCount = 'أصناف الوقود المعرفة';
  static const String unitsCount = 'الوحدات المعرفة';
  static const String dataConsistencyCheck = 'مطابقة وتناسق القيود';
  static const String dataConsistencyOk = 'لا توجد قيود معلقة أو أخطاء حسابية';
  static const String quickRefresh = 'تحديث التحليل';
  static const String litersUnit = 'لتر';
  static const String operationsCountSuffix = 'عملية';
  static const String accountsCountSuffix = 'حساب';
  static const String storageAndDb = 'التخزين وقاعدة البيانات';
  static const String systemOverview = 'نظرة عامة على النظام';
}
