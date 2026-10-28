import '../../models/reconciliation_item_model.dart';
import '../../models/statement_item_model.dart';
import '../../models/transaction_model.dart';
import '../local/database_helper.dart';

/// مستودع بيانات التقارير والمطابقات المحاسبية
class ReportRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// جلب كشف حساب تفصيلي لمورد أو مستفيد مع حساب الرصيد التراكمي الجاري
  Future<List<StatementItemModel>> getAccountStatement({
    required int accountId,
    required bool isSupplier,
    int? fuelTypeId,
    String? fromDate,
    String? toDate,
    String? filterType, // 'ALL', 'QUOTA', 'ACTUAL', 'TRANSFER'
  }) async {
    final db = await _dbHelper.database;

    // استعلام كافة العمليات مرتبة تصاعدياً من الأقدم للأحدث لحساب الرصيد الجاري بدقة
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        t.*,
        tt.name AS type_name,
        tt.code AS type_code,
        s.name AS station_name,
        rs.name AS reference_station_name,
        ft.name AS fuel_type_name,
        u.name AS unit_name,
        u.conversion_factor AS unit_factor,
        a.name AS account_name,
        a.phone_number AS account_phone
      FROM transactions t
      LEFT JOIN transaction_types tt ON t.type_id = tt.id
      LEFT JOIN accounts s ON t.station_id = s.id
      LEFT JOIN accounts rs ON t.reference_station_id = rs.id
      LEFT JOIN fuel_types ft ON t.fuel_type_id = ft.id
      LEFT JOIN units u ON t.unit_id = u.id
      LEFT JOIN accounts a ON t.account_id = a.id
      WHERE t.account_id = ? AND t.is_deleted = 0 AND t.type_id != 3
      ORDER BY t.transaction_date ASC, t.id ASC
    ''', [accountId]);

    final allTransactions = maps.map((m) => TransactionModel.fromMap(m)).toList();

    // خريطة لتتبع الرصيد التراكمي لكل صنف وقود بشكل مستقل
    final Map<int, double> runningBalancesPerFuel = {};
    final List<StatementItemModel> statementItems = [];

    final cleanFromDate = fromDate?.replaceAll('/', '-');
    final cleanToDate = toDate?.replaceAll('/', '-');

    for (final tx in allTransactions) {
      final fId = tx.fuelTypeId ?? 0;
      double currentBalance = runningBalancesPerFuel[fId] ?? 0.0;

      double inflow = 0.0;
      double outflow = 0.0;

      if (isSupplier) {
        // حساب المورد:
        // توريد اعتماد (1) = موجب (إضافة رصيد اعتماد)
        // توريد فعلي (2) = سالب (استهلاك من الاعتماد وتوريد للمحطة)
        // تحويل وارد (7) = موجب
        // تحويل صادر (6) = سالب
        if (tx.typeId == 1) {
          inflow = tx.baseQuantityLiters;
        } else if (tx.typeId == 2) {
          outflow = tx.baseQuantityLiters;
        } else if (tx.typeId == 7) {
          inflow = tx.baseQuantityLiters;
        } else if (tx.typeId == 6) {
          outflow = tx.baseQuantityLiters;
        }
      } else {
        // حساب المستفيد:
        // صرف اعتماد (4) = موجب (إضافة رصيد اعتماد)
        // صرف فعلي (5) = سالب (استهلاك من الاعتماد وصرف من المحطة)
        // تحويل وارد (7) = موجب
        // تحويل صادر (6) = سالب
        if (tx.typeId == 4) {
          inflow = tx.baseQuantityLiters;
        } else if (tx.typeId == 5) {
          outflow = tx.baseQuantityLiters;
        } else if (tx.typeId == 7) {
          inflow = tx.baseQuantityLiters;
        } else if (tx.typeId == 6) {
          outflow = tx.baseQuantityLiters;
        }
      }

      currentBalance += (inflow - outflow);
      runningBalancesPerFuel[fId] = currentBalance;

      // تطبيق الفلاتر على عرض البنود مع الحفاظ على سلامة الرصيد التراكمي
      final txDate = tx.transactionDate.replaceAll('/', '-');

      if (fuelTypeId != null && tx.fuelTypeId != fuelTypeId) {
        continue;
      }

      if (cleanFromDate != null && cleanFromDate.isNotEmpty && txDate.compareTo(cleanFromDate) < 0) {
        continue;
      }

      if (cleanToDate != null && cleanToDate.isNotEmpty && txDate.compareTo(cleanToDate) > 0) {
        continue;
      }

      if (filterType != null && filterType != 'ALL') {
        if (filterType == 'QUOTA' && !tx.isQuota) continue;
        if (filterType == 'ACTUAL' && !tx.isActual) continue;
        if (filterType == 'TRANSFER' && !tx.isTransfer) continue;
      }

      statementItems.add(StatementItemModel(
        transaction: tx,
        runningBalance: currentBalance,
        inflow: inflow,
        outflow: outflow,
      ));
    }

    // إرجاع البنود مرتبة تنازلياً (الأحدث أولاً) لتسهيل القراءة في الواجهة
    return statementItems.reversed.toList();
  }

  /// جلب كشف حساب تفصيلي لمحطة وقود (وارد، منصرف، تهوية، تحويلات، رصيد مخزون)
  Future<List<StatementItemModel>> getStationStatement({
    required int stationId,
    int? fuelTypeId,
    String? fromDate,
    String? toDate,
    String? filterType, // 'ALL', 'SUPPLY', 'DISPENSE', 'AERATION', 'TRANSFER'
  }) async {
    final db = await _dbHelper.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        t.*,
        tt.name AS type_name,
        tt.code AS type_code,
        s.name AS station_name,
        rs.name AS reference_station_name,
        ft.name AS fuel_type_name,
        u.name AS unit_name,
        u.conversion_factor AS unit_factor,
        a.name AS account_name,
        a.phone_number AS account_phone
      FROM transactions t
      LEFT JOIN transaction_types tt ON t.type_id = tt.id
      LEFT JOIN accounts s ON t.station_id = s.id
      LEFT JOIN accounts rs ON t.reference_station_id = rs.id
      LEFT JOIN fuel_types ft ON t.fuel_type_id = ft.id
      LEFT JOIN units u ON t.unit_id = u.id
      LEFT JOIN accounts a ON t.account_id = a.id
      WHERE (t.station_id = ? OR t.reference_station_id = ? OR t.account_id = ?) AND t.is_deleted = 0
      ORDER BY t.transaction_date ASC, t.id ASC
    ''', [stationId, stationId, stationId]);

    final allTransactions = maps.map((m) => TransactionModel.fromMap(m)).toList();
    final Map<int, double> runningStockPerFuel = {};
    final List<StatementItemModel> statementItems = [];

    final cleanFromDate = fromDate?.replaceAll('/', '-');
    final cleanToDate = toDate?.replaceAll('/', '-');

    for (final tx in allTransactions) {
      final fId = tx.fuelTypeId ?? 0;
      double currentStock = runningStockPerFuel[fId] ?? 0.0;

      double inflow = 0.0;
      double outflow = 0.0;

      // حركة المحطة:
      // توريد فعلي وارد للمحطة (type_id = 2) = وارد (+)
      // عمولة تهوية مخصومة (type_id = 3) = منصرف (-)
      // صرف فعلي للعملاء من المحطة (type_id = 5) = منصرف (-)
      // تحويل وارد (type_id = 7) = وارد (+)
      // تحويل صادر (type_id = 6) = منصرف (-)
      if (tx.typeId == 2 && tx.stationId == stationId) {
        inflow = tx.baseQuantityLiters;
      } else if (tx.typeId == 3 && tx.stationId == stationId) {
        outflow = tx.baseQuantityLiters;
      } else if (tx.typeId == 5 && (tx.referenceStationId == stationId || (tx.referenceStationId == null && tx.stationId == stationId))) {
        outflow = tx.baseQuantityLiters;
      } else if (tx.typeId == 7 && (tx.stationId == stationId || tx.accountId == stationId)) {
        inflow = tx.baseQuantityLiters;
      } else if (tx.typeId == 6 && (tx.stationId == stationId || tx.accountId == stationId)) {
        outflow = tx.baseQuantityLiters;
      }

      currentStock += (inflow - outflow);
      runningStockPerFuel[fId] = currentStock;

      final txDate = tx.transactionDate.replaceAll('/', '-');

      if (fuelTypeId != null && tx.fuelTypeId != fuelTypeId) {
        continue;
      }

      if (cleanFromDate != null && cleanFromDate.isNotEmpty && txDate.compareTo(cleanFromDate) < 0) {
        continue;
      }

      if (cleanToDate != null && cleanToDate.isNotEmpty && txDate.compareTo(cleanToDate) > 0) {
        continue;
      }

      if (filterType != null && filterType != 'ALL') {
        if (filterType == 'SUPPLY' && tx.typeId != 2) continue;
        if (filterType == 'DISPENSE' && tx.typeId != 5) continue;
        if (filterType == 'AERATION' && tx.typeId != 3) continue;
        if (filterType == 'TRANSFER' && !tx.isTransfer) continue;
      }

      statementItems.add(StatementItemModel(
        transaction: tx,
        runningBalance: currentStock,
        inflow: inflow,
        outflow: outflow,
      ));
    }

    return statementItems.reversed.toList();
  }

  /// جلب تقرير مطابقة أرصدة الموردين لكافة الأصناف
  Future<List<ReconciliationItemModel>> getSupplierReconciliation({
    int? fuelTypeId,
    String? searchQuery,
    ReconciliationStatus? statusFilter,
  }) async {
    final db = await _dbHelper.database;

    final String fuelFilter = fuelTypeId != null ? 'AND ft.id = $fuelTypeId' : '';

    final List<Map<String, dynamic>> rows = await db.rawQuery('''
      SELECT 
        a.id AS account_id,
        a.name AS account_name,
        a.phone_number,
        ft.id AS fuel_type_id,
        ft.name AS fuel_type_name,
        COALESCE(SUM(CASE WHEN t.type_id = 1 THEN t.base_quantity_liters ELSE 0 END), 0.0) AS quota,
        COALESCE(SUM(CASE WHEN t.type_id = 2 THEN t.base_quantity_liters ELSE 0 END), 0.0) AS actual,
        COALESCE(SUM(CASE WHEN t.type_id = 7 THEN t.base_quantity_liters ELSE 0 END), 0.0) AS transfers_in,
        COALESCE(SUM(CASE WHEN t.type_id = 6 THEN t.base_quantity_liters ELSE 0 END), 0.0) AS transfers_out
      FROM accounts a
      CROSS JOIN fuel_types ft
      LEFT JOIN transactions t ON t.account_id = a.id AND t.fuel_type_id = ft.id AND t.is_deleted = 0
      WHERE a.account_type = 'SUPPLIER' AND a.is_active = 1 AND a.is_archived = 0
        AND ft.is_active = 1 $fuelFilter
      GROUP BY a.id, a.name, a.phone_number, ft.id, ft.name
      ORDER BY a.name ASC, ft.id ASC
    ''');

    final list = rows.map((r) {
      final quota = (r['quota'] as num?)?.toDouble() ?? 0.0;
      final actual = (r['actual'] as num?)?.toDouble() ?? 0.0;
      final tIn = (r['transfers_in'] as num?)?.toDouble() ?? 0.0;
      final tOut = (r['transfers_out'] as num?)?.toDouble() ?? 0.0;
      final balance = quota - actual + tIn - tOut;
      final ratio = quota > 0 ? (actual / quota).clamp(0.0, 1.0) : (balance <= 0 ? 1.0 : 0.0);

      return ReconciliationItemModel(
        accountId: r['account_id'] as int,
        accountName: r['account_name'] as String,
        accountType: 'SUPPLIER',
        phoneNumber: r['phone_number'] as String?,
        fuelTypeId: r['fuel_type_id'] as int,
        fuelTypeName: r['fuel_type_name'] as String,
        quota: quota,
        actual: actual,
        transfersIn: tIn,
        transfersOut: tOut,
        balance: balance,
        ratio: ratio,
      );
    }).where((item) {
      // إخفاء الحسابات التي ليس لها أي حركة إذا كانت أرصدتها صفر
      if (item.quota == 0 && item.actual == 0 && item.balance == 0) {
        return false;
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        if (!item.accountName.toLowerCase().contains(q) &&
            !(item.phoneNumber?.contains(q) ?? false)) {
          return false;
        }
      }
      if (statusFilter != null && item.status != statusFilter) {
        return false;
      }
      return true;
    }).toList();

    return list;
  }

  /// جلب تقرير مطابقة مخزون المحطات
  Future<List<ReconciliationItemModel>> getStationReconciliation({
    int? fuelTypeId,
    String? searchQuery,
    ReconciliationStatus? statusFilter,
  }) async {
    final db = await _dbHelper.database;
    final String fuelFilter = fuelTypeId != null ? 'AND ft.id = $fuelTypeId' : '';

    final List<Map<String, dynamic>> stations = await db.query(
      'accounts',
      where: 'account_type = ? AND is_active = ? AND is_archived = ?',
      whereArgs: ['STATION', 1, 0],
      orderBy: 'name ASC',
    );

    final List<Map<String, dynamic>> fuelTypes = await db.rawQuery('''
      SELECT id, name FROM fuel_types WHERE is_active = 1 $fuelFilter ORDER BY id ASC
    ''');

    final List<ReconciliationItemModel> results = [];

    for (final st in stations) {
      final stId = st['id'] as int;
      final stName = st['name'] as String;
      final phone = st['phone_number'] as String?;
      final location = st['location'] as String?;
      final rate = (st['default_commission_rate'] as num?)?.toDouble() ?? 2.0;

      for (final ft in fuelTypes) {
        final fId = ft['id'] as int;
        final fName = ft['name'] as String;

        // حساب مكونات حركة المحطة
        final res = await db.rawQuery('''
          SELECT 
            COALESCE(SUM(CASE WHEN type_id = 2 THEN base_quantity_liters ELSE 0 END), 0.0) AS supply_actual,
            COALESCE(SUM(CASE WHEN type_id = 3 THEN base_quantity_liters ELSE 0 END), 0.0) AS aeration,
            COALESCE(SUM(CASE WHEN type_id = 5 THEN base_quantity_liters ELSE 0 END), 0.0) AS dispense_actual,
            COALESCE(SUM(CASE WHEN type_id = 7 THEN base_quantity_liters ELSE 0 END), 0.0) AS transfers_in,
            COALESCE(SUM(CASE WHEN type_id = 6 THEN base_quantity_liters ELSE 0 END), 0.0) AS transfers_out
          FROM (
            SELECT type_id, base_quantity_liters FROM transactions 
            WHERE is_deleted = 0 AND fuel_type_id = ? AND type_id IN (2, 3) AND station_id = ?

            UNION ALL

            SELECT type_id, base_quantity_liters FROM transactions
            WHERE is_deleted = 0 AND fuel_type_id = ? AND type_id = 5 AND COALESCE(reference_station_id, station_id) = ?

            UNION ALL

            SELECT type_id, base_quantity_liters FROM transactions
            WHERE is_deleted = 0 AND fuel_type_id = ? AND type_id IN (6, 7) AND (station_id = ? OR account_id = ?)
          )
        ''', [fId, stId, fId, stId, fId, stId, stId]);

        final row = res.first;
        final supply = (row['supply_actual'] as num?)?.toDouble() ?? 0.0;
        final aeration = (row['aeration'] as num?)?.toDouble() ?? 0.0;
        final dispense = (row['dispense_actual'] as num?)?.toDouble() ?? 0.0;
        final tIn = (row['transfers_in'] as num?)?.toDouble() ?? 0.0;
        final tOut = (row['transfers_out'] as num?)?.toDouble() ?? 0.0;

        final balance = supply - aeration - dispense + tIn - tOut;
        final netAvailableToDispense = supply - aeration;
        final ratio = netAvailableToDispense > 0
            ? (dispense / netAvailableToDispense).clamp(0.0, 1.0)
            : 0.0;

        if (supply == 0 && dispense == 0 && balance == 0) {
          continue;
        }

        final item = ReconciliationItemModel(
          accountId: stId,
          accountName: stName,
          accountType: 'STATION',
          phoneNumber: phone,
          location: location,
          fuelTypeId: fId,
          fuelTypeName: fName,
          actual: supply,
          aeration: aeration,
          quota: netAvailableToDispense,
          transfersIn: tIn,
          transfersOut: tOut,
          balance: balance,
          ratio: ratio,
          commissionRate: rate,
        );

        if (searchQuery != null && searchQuery.isNotEmpty) {
          final q = searchQuery.toLowerCase();
          if (!stName.toLowerCase().contains(q) &&
              !(location?.toLowerCase().contains(q) ?? false) &&
              !(phone?.contains(q) ?? false)) {
            continue;
          }
        }

        if (statusFilter != null && item.status != statusFilter) {
          continue;
        }

        results.add(item);
      }
    }

    return results;
  }

  /// جلب تقرير مطابقة اعتمادات المستفيدين
  Future<List<ReconciliationItemModel>> getBeneficiaryReconciliation({
    int? fuelTypeId,
    String? searchQuery,
    ReconciliationStatus? statusFilter,
  }) async {
    final db = await _dbHelper.database;
    final String fuelFilter = fuelTypeId != null ? 'AND ft.id = $fuelTypeId' : '';

    final List<Map<String, dynamic>> rows = await db.rawQuery('''
      SELECT 
        a.id AS account_id,
        a.name AS account_name,
        a.phone_number,
        ft.id AS fuel_type_id,
        ft.name AS fuel_type_name,
        COALESCE(SUM(CASE WHEN t.type_id = 4 THEN t.base_quantity_liters ELSE 0 END), 0.0) AS quota,
        COALESCE(SUM(CASE WHEN t.type_id = 5 THEN t.base_quantity_liters ELSE 0 END), 0.0) AS actual,
        COALESCE(SUM(CASE WHEN t.type_id = 7 THEN t.base_quantity_liters ELSE 0 END), 0.0) AS transfers_in,
        COALESCE(SUM(CASE WHEN t.type_id = 6 THEN t.base_quantity_liters ELSE 0 END), 0.0) AS transfers_out
      FROM accounts a
      CROSS JOIN fuel_types ft
      LEFT JOIN transactions t ON t.account_id = a.id AND t.fuel_type_id = ft.id AND t.is_deleted = 0
      WHERE a.account_type = 'BENEFICIARY' AND a.is_active = 1 AND a.is_archived = 0
        AND ft.is_active = 1 $fuelFilter
      GROUP BY a.id, a.name, a.phone_number, ft.id, ft.name
      ORDER BY a.name ASC, ft.id ASC
    ''');

    final list = rows.map((r) {
      final quota = (r['quota'] as num?)?.toDouble() ?? 0.0;
      final actual = (r['actual'] as num?)?.toDouble() ?? 0.0;
      final tIn = (r['transfers_in'] as num?)?.toDouble() ?? 0.0;
      final tOut = (r['transfers_out'] as num?)?.toDouble() ?? 0.0;
      final balance = quota - actual + tIn - tOut;
      final ratio = quota > 0 ? (actual / quota).clamp(0.0, 1.0) : (balance <= 0 ? 1.0 : 0.0);

      return ReconciliationItemModel(
        accountId: r['account_id'] as int,
        accountName: r['account_name'] as String,
        accountType: 'BENEFICIARY',
        phoneNumber: r['phone_number'] as String?,
        fuelTypeId: r['fuel_type_id'] as int,
        fuelTypeName: r['fuel_type_name'] as String,
        quota: quota,
        actual: actual,
        transfersIn: tIn,
        transfersOut: tOut,
        balance: balance,
        ratio: ratio,
      );
    }).where((item) {
      if (item.quota == 0 && item.actual == 0 && item.balance == 0) {
        return false;
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        if (!item.accountName.toLowerCase().contains(q) &&
            !(item.phoneNumber?.contains(q) ?? false)) {
          return false;
        }
      }
      if (statusFilter != null && item.status != statusFilter) {
        return false;
      }
      return true;
    }).toList();

    return list;
  }
}

