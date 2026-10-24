import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../local/database_helper.dart';

/// نموذج بيانات تحليل شاملة للتطبيق وقاعدة البيانات
class AnalysisData {
  // صحة النظام وقاعدة البيانات
  final bool isDatabaseIntact;
  final String databaseSizeString;
  final int totalDatabaseRecords;
  final List<String> consistencyIssues;

  // إحصائيات الحسابات
  final int totalAccounts;
  final int activeAccounts;
  final int beneficiariesCount;
  final int stationsCount;
  final int suppliersCount;
  final int archivedAccounts;
  final int deletedAccounts;

  // إحصائيات الأصناف والوحدات
  final int fuelTypesCount;
  final List<Map<String, dynamic>> fuelTypesDetails;
  final int unitsCount;
  final List<Map<String, dynamic>> unitsDetails;

  // إحصائيات العمليات
  final int totalTransactions;
  final int activeTransactions;
  final int deletedTransactions;

  // تفصيل العمليات الدقيق
  final int supplyQuotaCount;
  final double supplyQuotaTotalLiters;
  final int dispenseQuotaCount;
  final double dispenseQuotaTotalLiters;
  final int supplyActualCount;
  final double supplyActualTotalLiters;
  final int dispenseActualCount;
  final double dispenseActualTotalLiters;
  final int aerationCount;
  final double aerationTotalLiters;
  final int transferCount;
  final double transferTotalLiters;

  const AnalysisData({
    required this.isDatabaseIntact,
    required this.databaseSizeString,
    required this.totalDatabaseRecords,
    required this.consistencyIssues,
    required this.totalAccounts,
    required this.activeAccounts,
    required this.beneficiariesCount,
    required this.stationsCount,
    required this.suppliersCount,
    required this.archivedAccounts,
    required this.deletedAccounts,
    required this.fuelTypesCount,
    required this.fuelTypesDetails,
    required this.unitsCount,
    required this.unitsDetails,
    required this.totalTransactions,
    required this.activeTransactions,
    required this.deletedTransactions,
    required this.supplyQuotaCount,
    required this.supplyQuotaTotalLiters,
    required this.dispenseQuotaCount,
    required this.dispenseQuotaTotalLiters,
    required this.supplyActualCount,
    required this.supplyActualTotalLiters,
    required this.dispenseActualCount,
    required this.dispenseActualTotalLiters,
    required this.aerationCount,
    required this.aerationTotalLiters,
    required this.transferCount,
    required this.transferTotalLiters,
  });

  // Getters للتوافق
  int get quotaCount => supplyQuotaCount + dispenseQuotaCount;
  double get quotaTotalLiters => supplyQuotaTotalLiters + dispenseQuotaTotalLiters;
  int get supplyCount => supplyActualCount;
  double get supplyTotalLiters => supplyActualTotalLiters;
  int get dispenseCount => dispenseActualCount;
  double get dispenseTotalLiters => dispenseActualTotalLiters;
}

/// مستودع تحليل وفحص النظام والبيانات
class AnalysisRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// تنفيذ فحص شامل واستخراج بيانات التحليل الفعلي
  Future<AnalysisData> fetchFullAnalysis() async {
    final db = await _dbHelper.database;

    // 1. فحص سلامة قاعدة البيانات
    bool isIntact = true;
    try {
      final integrityResult = await db.rawQuery('PRAGMA integrity_check;');
      if (integrityResult.isNotEmpty) {
        final val = integrityResult.first.values.first.toString().toLowerCase();
        isIntact = val == 'ok';
      }
    } catch (_) {
      isIntact = false;
    }

    // 2. حجم قاعدة البيانات
    String dbSizeStr = '0 KB';
    try {
      final dbPath = await getDatabasesPath();
      final file = File(join(dbPath, 'fuel_allocation.db'));
      if (await file.exists()) {
        final bytes = await file.length();
        if (bytes < 1024) {
          dbSizeStr = '$bytes B';
        } else if (bytes < 1024 * 1024) {
          dbSizeStr = '${(bytes / 1024).toStringAsFixed(1)} KB';
        } else {
          dbSizeStr = '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
        }
      }
    } catch (_) {}

    // 3. إجمالي السجلات عبر الجداول
    int totalRecords = 0;
    final tableNames = [
      'accounts',
      'stations',
      'fuel_types',
      'units',
      'transactions',
      'message_templates',
      'personal_info',
    ];
    for (final table in tableNames) {
      try {
        final count = Sqflite.firstIntValue(
                await db.rawQuery('SELECT COUNT(*) FROM $table')) ??
            0;
        totalRecords += count;
      } catch (_) {}
    }

    // 4. إحصائيات الحسابات
    final totalAccounts = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM accounts')) ??
        0;
    final activeAccounts = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM accounts WHERE is_active = 1 AND is_archived = 0 AND deleted_at IS NULL')) ??
        0;
    final beneficiaries = Sqflite.firstIntValue(await db.rawQuery(
            "SELECT COUNT(*) FROM accounts WHERE account_type = 'BENEFICIARY' AND is_active = 1 AND is_archived = 0 AND deleted_at IS NULL")) ??
        0;
    final stations = Sqflite.firstIntValue(await db.rawQuery(
            "SELECT COUNT(*) FROM accounts WHERE account_type = 'STATION' AND is_active = 1 AND is_archived = 0 AND deleted_at IS NULL")) ??
        0;
    final suppliers = Sqflite.firstIntValue(await db.rawQuery(
            "SELECT COUNT(*) FROM accounts WHERE account_type = 'SUPPLIER' AND is_active = 1 AND is_archived = 0 AND deleted_at IS NULL")) ??
        0;
    final archivedAccounts = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM accounts WHERE is_archived = 1 AND deleted_at IS NULL')) ??
        0;
    final deletedAccounts = Sqflite.firstIntValue(await db
            .rawQuery('SELECT COUNT(*) FROM accounts WHERE is_active = 0 OR deleted_at IS NOT NULL')) ??
        0;

    // 5. إحصائيات الأصناف
    final fuelTypesCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM fuel_types')) ??
        0;
    final fuelTypesRows = await db.rawQuery('''
      SELECT 
        ft.id, 
        ft.name, 
        COUNT(t.id) as tx_count, 
        COALESCE(SUM(t.base_quantity_liters), 0.0) as total_liters 
      FROM fuel_types ft
      LEFT JOIN transactions t ON t.fuel_type_id = ft.id AND t.is_deleted = 0
      GROUP BY ft.id, ft.name
      ORDER BY total_liters DESC, ft.id ASC
    ''');
    final fuelTypesDetails = fuelTypesRows.map((r) => Map<String, dynamic>.from(r)).toList();

    // 6. إحصائيات الوحدات
    final unitsCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM units')) ??
        0;
    final unitsRows = await db.rawQuery('''
      SELECT 
        u.id, 
        u.name, 
        u.conversion_factor, 
        u.is_base_unit,
        COUNT(t.id) as tx_count
      FROM units u
      LEFT JOIN transactions t ON t.unit_id = u.id AND t.is_deleted = 0
      GROUP BY u.id, u.name, u.conversion_factor, u.is_base_unit
      ORDER BY u.id ASC
    ''');
    final unitsDetails = unitsRows.map((r) => Map<String, dynamic>.from(r)).toList();

    // 7. إحصائيات العمليات
    final totalTransactions = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM transactions')) ??
        0;
    final activeTransactions = Sqflite.firstIntValue(await db
            .rawQuery('SELECT COUNT(*) FROM transactions WHERE is_deleted = 0')) ??
        0;
    final deletedTransactions = Sqflite.firstIntValue(await db
            .rawQuery('SELECT COUNT(*) FROM transactions WHERE is_deleted = 1')) ??
        0;

    // تفصيل العمليات حسب النوع
    final typeRows = await db.rawQuery('''
      SELECT 
        type_id, 
        COUNT(id) as cnt, 
        COALESCE(SUM(base_quantity_liters), 0.0) as total_liters
      FROM transactions
      WHERE is_deleted = 0
      GROUP BY type_id
    ''');

    int supplyQCount = 0;
    double supplyQLiters = 0.0;
    int dispenseQCount = 0;
    double dispenseQLiters = 0.0;
    int supActualCount = 0;
    double supActualLiters = 0.0;
    int dispActualCount = 0;
    double dispActualLiters = 0.0;
    int aerCount = 0;
    double aerLiters = 0.0;
    int trCount = 0;
    double trLiters = 0.0;

    for (final row in typeRows) {
      final tid = row['type_id'] as int;
      final cnt = row['cnt'] as int;
      final liters = (row['total_liters'] as num).toDouble();

      if (tid == 1) {
        // توريد اعتماد (SUPPLY_QUOTA)
        supplyQCount += cnt;
        supplyQLiters += liters;
      } else if (tid == 4) {
        // صرف اعتماد (DISPENSE_QUOTA)
        dispenseQCount += cnt;
        dispenseQLiters += liters;
      } else if (tid == 2) {
        // توريد فعلي (SUPPLY_ACTUAL)
        supActualCount += cnt;
        supActualLiters += liters;
      } else if (tid == 5) {
        // صرف فعلي (DISPENSE_ACTUAL)
        dispActualCount += cnt;
        dispActualLiters += liters;
      } else if (tid == 3) {
        // عمولة تهوية (AERATION_COMMISSION)
        aerCount += cnt;
        aerLiters += liters;
      } else if (tid == 6 || tid == 7) {
        // تحويلات صادر ووارد (TRANSFER)
        trCount += cnt;
        trLiters += liters;
      }
    }

    // 8. فحص تناسق القيود
    final consistencyIssues = <String>[];
    try {
      final orphanedTx = Sqflite.firstIntValue(await db.rawQuery('''
        SELECT COUNT(*) FROM transactions 
        WHERE account_id IS NOT NULL 
          AND account_id NOT IN (SELECT id FROM accounts) 
          AND is_deleted = 0
      ''')) ?? 0;
      if (orphanedTx > 0) {
        consistencyIssues.add('توجد $orphanedTx عملية مرتبطة بحسابات غير موجودة');
      }

      final invalidQuantities = Sqflite.firstIntValue(await db.rawQuery('''
        SELECT COUNT(*) FROM transactions 
        WHERE base_quantity_liters < 0 AND is_deleted = 0
      ''')) ?? 0;
      if (invalidQuantities > 0) {
        consistencyIssues.add('توجد $invalidQuantities عملية بكميات سالبة غير صحيحة');
      }
    } catch (_) {}

    return AnalysisData(
      isDatabaseIntact: isIntact,
      databaseSizeString: dbSizeStr,
      totalDatabaseRecords: totalRecords,
      consistencyIssues: consistencyIssues,
      totalAccounts: totalAccounts,
      activeAccounts: activeAccounts,
      beneficiariesCount: beneficiaries,
      stationsCount: stations,
      suppliersCount: suppliers,
      archivedAccounts: archivedAccounts,
      deletedAccounts: deletedAccounts,
      fuelTypesCount: fuelTypesCount,
      fuelTypesDetails: fuelTypesDetails,
      unitsCount: unitsCount,
      unitsDetails: unitsDetails,
      totalTransactions: totalTransactions,
      activeTransactions: activeTransactions,
      deletedTransactions: deletedTransactions,
      supplyQuotaCount: supplyQCount,
      supplyQuotaTotalLiters: supplyQLiters,
      dispenseQuotaCount: dispenseQCount,
      dispenseQuotaTotalLiters: dispenseQLiters,
      supplyActualCount: supActualCount,
      supplyActualTotalLiters: supActualLiters,
      dispenseActualCount: dispActualCount,
      dispenseActualTotalLiters: dispActualLiters,
      aerationCount: aerCount,
      aerationTotalLiters: aerLiters,
      transferCount: trCount,
      transferTotalLiters: trLiters,
    );
  }
}
