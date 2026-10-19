import '../../models/transaction_model.dart';
import '../local/database_helper.dart';

/// مستودع إدارة بيانات العمليات والقيود في قاعدة البيانات
class TransactionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// جلب كافة عمليات حساب معين مع البيانات المرتبطة
  Future<List<TransactionModel>> getTransactionsByAccountId(
      int accountId) async {
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
      WHERE t.account_id = ? AND t.is_deleted = 0 AND t.type_id != 3
      ORDER BY t.transaction_date DESC, t.id DESC
    ''', [accountId]);

    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  /// جلب كافة عمليات محطة معينة (وارد فعلي، منصرف فعلي، عمولة تهوية، مقاصات)
  Future<List<TransactionModel>> getTransactionsByStationId(
      int stationId) async {
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
      ORDER BY t.transaction_date DESC, t.id DESC
    ''', [stationId, stationId, stationId]);

    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  /// حساب رصيد المحطة الفعلي المتاح حالياً باللتر (لكل الأصناف أو لصنف محدد)
  /// (التوريدات الفعلية) - (عمولات التهوية) - (المنصرف الفعلي منها أو من مرجعها) +/- التحويلات
  Future<double> getStationBalance(int stationId, {int? fuelTypeId}) async {
    final db = await _dbHelper.database;
    final String fuelFilter = fuelTypeId != null ? ' AND fuel_type_id = ?' : '';
    final List<dynamic> args = fuelTypeId != null
        ? [
            stationId,
            fuelTypeId,
            stationId,
            fuelTypeId,
            stationId,
            stationId,
            fuelTypeId
          ]
        : [stationId, stationId, stationId, stationId];

    final res = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(CASE 
          WHEN type_id = 2 THEN base_quantity_liters 
          WHEN type_id = 3 THEN -base_quantity_liters 
          WHEN type_id = 5 THEN -base_quantity_liters 
          WHEN type_id = 7 THEN base_quantity_liters 
          WHEN type_id = 6 THEN -base_quantity_liters 
          ELSE 0 
        END), 0.0) AS balance
      FROM transactions
      WHERE is_deleted = 0 AND (
        (type_id IN (2, 3) AND station_id = ?$fuelFilter)
        OR (type_id = 5 AND COALESCE(reference_station_id, station_id) = ?$fuelFilter)
        OR (type_id IN (6, 7) AND (station_id = ? OR account_id = ?)$fuelFilter)
      )
    ''', args);

    return (res.first['balance'] as num?)?.toDouble() ?? 0.0;
  }

  /// حساب الرصيد المتاح لحساب عميل أو مورد حالياً باللتر (لكل الأصناف أو لصنف محدد)
  Future<double> getAccountBalance(int accountId, bool isSupplier,
      {int? fuelTypeId}) async {
    final db = await _dbHelper.database;
    final String fuelFilter = fuelTypeId != null ? ' AND fuel_type_id = ?' : '';
    final List<dynamic> args =
        fuelTypeId != null ? [accountId, fuelTypeId] : [accountId];

    if (isSupplier) {
      // للمورد: توريد اعتماد (+) - توريد فعلي (-) + وارد تحويل (+) - صادر تحويل (-)
      final res = await db.rawQuery('''
        SELECT 
          COALESCE(SUM(CASE 
            WHEN type_id = 1 THEN base_quantity_liters 
            WHEN type_id = 2 THEN -base_quantity_liters 
            WHEN type_id = 7 THEN base_quantity_liters 
            WHEN type_id = 6 THEN -base_quantity_liters 
            ELSE 0 
          END), 0.0) AS balance
        FROM transactions
        WHERE is_deleted = 0 AND account_id = ?$fuelFilter
      ''', args);
      return (res.first['balance'] as num?)?.toDouble() ?? 0.0;
    } else {
      // للعميل: صرف اعتماد (+) - صرف فعلي (-) + وارد تحويل (+) - صادر تحويل (-)
      final res = await db.rawQuery('''
        SELECT 
          COALESCE(SUM(CASE 
            WHEN type_id = 4 THEN base_quantity_liters 
            WHEN type_id = 5 THEN -base_quantity_liters 
            WHEN type_id = 7 THEN base_quantity_liters 
            WHEN type_id = 6 THEN -base_quantity_liters 
            ELSE 0 
          END), 0.0) AS balance
        FROM transactions
        WHERE is_deleted = 0 AND account_id = ?$fuelFilter
      ''', args);
      return (res.first['balance'] as num?)?.toDouble() ?? 0.0;
    }
  }

  /// جلب ملخص أرصدة الحسابات لجميع أنواع الوقود النشطة دفعة واحدة
  /// Return: Map<accountId, Map<fuelTypeId, balance>>
  Future<Map<int, Map<int, double>>> getAllAccountFuelBalances() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> rows = await db.rawQuery('''
      SELECT 
        t.account_id,
        t.fuel_type_id,
        a.account_type,
        SUM(CASE 
          WHEN a.account_type = 'SUPPLIER' THEN 
            (CASE 
              WHEN t.type_id = 1 THEN t.base_quantity_liters 
              WHEN t.type_id = 2 THEN -t.base_quantity_liters 
              WHEN t.type_id = 7 THEN t.base_quantity_liters 
              WHEN t.type_id = 6 THEN -t.base_quantity_liters 
              ELSE 0 
            END)
          ELSE 
            (CASE 
              WHEN t.type_id = 4 THEN t.base_quantity_liters 
              WHEN t.type_id = 5 THEN -t.base_quantity_liters 
              WHEN t.type_id = 7 THEN t.base_quantity_liters 
              WHEN t.type_id = 6 THEN -t.base_quantity_liters 
              ELSE 0 
            END)
        END) AS balance
      FROM transactions t
      JOIN accounts a ON t.account_id = a.id
      WHERE t.is_deleted = 0 AND t.account_id IS NOT NULL AND t.fuel_type_id IS NOT NULL
      GROUP BY t.account_id, t.fuel_type_id, a.account_type
    ''');

    final Map<int, Map<int, double>> result = {};
    for (final r in rows) {
      final accountId = r['account_id'] as int;
      final fuelTypeId = r['fuel_type_id'] as int;
      final balance = (r['balance'] as num?)?.toDouble() ?? 0.0;
      result.putIfAbsent(accountId, () => {})[fuelTypeId] = balance;
    }
    return result;
  }

  /// جلب ملخص أرصدة المحطات لجميع أنواع الوقود النشطة دفعة واحدة
  /// Return: Map<stationId, Map<fuelTypeId, balance>>
  Future<Map<int, Map<int, double>>> getAllStationFuelBalances() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> rows = await db.rawQuery('''
      SELECT 
        station_id,
        fuel_type_id,
        SUM(delta) AS balance
      FROM (
        SELECT 
          station_id,
          fuel_type_id,
          CASE 
            WHEN type_id = 2 THEN base_quantity_liters
            WHEN type_id = 3 THEN -base_quantity_liters
            ELSE 0
          END AS delta
        FROM transactions
        WHERE is_deleted = 0 AND type_id IN (2, 3) AND station_id IS NOT NULL AND fuel_type_id IS NOT NULL

        UNION ALL

        SELECT 
          COALESCE(reference_station_id, station_id) AS station_id,
          fuel_type_id,
          -base_quantity_liters AS delta
        FROM transactions
        WHERE is_deleted = 0 AND type_id = 5 AND COALESCE(reference_station_id, station_id) IS NOT NULL AND fuel_type_id IS NOT NULL

        UNION ALL

        SELECT 
          COALESCE(station_id, account_id) AS station_id,
          fuel_type_id,
          CASE 
            WHEN type_id = 7 THEN base_quantity_liters
            WHEN type_id = 6 THEN -base_quantity_liters
            ELSE 0
          END AS delta
        FROM transactions
        WHERE is_deleted = 0 AND type_id IN (6, 7) AND COALESCE(station_id, account_id) IS NOT NULL AND fuel_type_id IS NOT NULL
      )
      GROUP BY station_id, fuel_type_id
    ''');

    final Map<int, Map<int, double>> result = {};
    for (final r in rows) {
      final stationId = r['station_id'] as int;
      final fuelTypeId = r['fuel_type_id'] as int;
      final balance = (r['balance'] as num?)?.toDouble() ?? 0.0;
      result.putIfAbsent(stationId, () => {})[fuelTypeId] = balance;
    }
    return result;
  }

  /// جلب العمليات المحذوفة (سلة المحذوفات)
  Future<List<TransactionModel>> getDeletedTransactions() async {
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
      WHERE t.is_deleted = 1
      ORDER BY t.deleted_at DESC, t.transaction_date DESC, t.id DESC
    ''');

    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  /// استعادة عملية من سلة المحذوفات
  Future<int> restoreTransaction(int id) async {
    final db = await _dbHelper.database;
    final txRows = await db.query('transactions',
        columns: ['parent_transaction_id'], where: 'id = ?', whereArgs: [id]);
    final parentId =
        txRows.isNotEmpty ? txRows.first['parent_transaction_id'] as int? : null;
    final rootId = parentId ?? id;

    return await db.update(
      'transactions',
      {'is_deleted': 0, 'deleted_at': null},
      where: 'id = ? OR parent_transaction_id = ?',
      whereArgs: [rootId, rootId],
    );
  }

  /// حذف نهائي لعملية من قاعدة البيانات
  Future<int> permanentlyDeleteTransaction(int id) async {
    final db = await _dbHelper.database;
    final txRows = await db.query('transactions',
        columns: ['parent_transaction_id'], where: 'id = ?', whereArgs: [id]);
    final parentId =
        txRows.isNotEmpty ? txRows.first['parent_transaction_id'] as int? : null;
    final rootId = parentId ?? id;

    await db.delete('transactions',
        where: 'parent_transaction_id = ?', whereArgs: [rootId]);
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [rootId],
    );
  }

  /// جلب أسماء المستلمين المسجلين سابقاً بدون تكرار
  Future<List<String>> getDistinctRecipients() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> res = await db.rawQuery('''
      SELECT DISTINCT recipient_name
      FROM transactions
      WHERE recipient_name IS NOT NULL AND TRIM(recipient_name) != ''
      ORDER BY recipient_name ASC
    ''');
    return res.map((r) => r['recipient_name'] as String).toList();
  }

  /// إدراج عملية جديدة مع التوليد الآلي لعمولة التهوية عند التوريد الفعلي
  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await _dbHelper.database;

    // توليد رقم عملية فريد
    String txNumber = transaction.transactionNumber?.trim() ?? '';
    if (txNumber.isEmpty) {
      final now = DateTime.now();
      txNumber =
          'TX-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(8)}';
    }

    final data = transaction.toMap();
    data['transaction_number'] = txNumber;

    final txId = await db.insert('transactions', data);

    // إذا كانت العملية توريد فعلي إلى محطة (type_id = 2)، يتم إنشاء قيد عمولة التهوية آلياً للمحطة فقط (account_id = null)
    if (transaction.typeId == 2 && transaction.stationId != null) {
      final stationList = await db.query(
        'accounts',
        columns: ['default_commission_rate'],
        where: 'id = ?',
        whereArgs: [transaction.stationId],
      );
      double rate = 2.0;
      if (stationList.isNotEmpty) {
        rate = (stationList.first['default_commission_rate'] as num?)
                ?.toDouble() ??
            2.0;
      }
      final commissionLiters = transaction.baseQuantityLiters * (rate / 100.0);
      if (commissionLiters > 0) {
        await db.insert('transactions', {
          'transaction_number': 'COM-$txNumber',
          'transaction_date': transaction.transactionDate,
          'type_id': 3, // عمولة تهوية
          'account_id': null, // عمولة التهوية تخص المحطة حصراً ولا تظهر للموردين
          'station_id': transaction.stationId,
          'fuel_type_id': transaction.fuelTypeId,
          'unit_id': 1, // لتر
          'entered_quantity': commissionLiters,
          'base_quantity_liters': commissionLiters,
          'parent_transaction_id': txId,
          'notes': 'عمولة تهوية ($rate%) تابعة للتوريد رقم $txNumber',
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    }

    return txId;
  }

  /// تعديل قيد موجود
  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await _dbHelper.database;
    final data = transaction.toMap();
    return await db.update(
      'transactions',
      data,
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  /// حذف عملية مع أي قيود تابعة لها (نقل لسلة المحذوفات أو حذف نهائي)
  Future<int> deleteTransaction(int id, {bool? forcePermanent}) async {
    final db = await _dbHelper.database;
    final isRecycle = forcePermanent == true
        ? false
        : await _dbHelper.isRecycleBinEnabled();

    final txRows = await db.query('transactions',
        columns: ['parent_transaction_id'], where: 'id = ?', whereArgs: [id]);
    final parentId =
        txRows.isNotEmpty ? txRows.first['parent_transaction_id'] as int? : null;
    final rootId = parentId ?? id;

    if (!isRecycle) {
      return await permanentlyDeleteTransaction(rootId);
    }

    return await db.update(
      'transactions',
      {
        'is_deleted': 1,
        'deleted_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ? OR parent_transaction_id = ?',
      whereArgs: [rootId, rootId],
    );
  }

  /// إدراج عملية تحويل بين حسابين (قيد مزدوج: صادر ووارد)
  Future<bool> insertTransfer({
    required int fromAccountId,
    required String fromAccountName,
    required int toAccountId,
    required String toAccountName,
    required int fuelTypeId,
    required int unitId,
    required double enteredQuantity,
    required double baseQuantityLiters,
    required String transactionDate,
    String? referenceNumber,
    String? notes,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final dateClean = transactionDate.replaceAll('/', '-');
    final refNum = referenceNumber?.trim();
    final customNotes = notes?.trim();

    final txNumberBase =
        'TR-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(8)}';

    return await db.transaction<bool>((txn) async {
      final fromAccQuery = await txn.query('accounts',
          columns: ['account_type'],
          where: 'id = ?',
          whereArgs: [fromAccountId]);
      final toAccQuery = await txn.query('accounts',
          columns: ['account_type'], where: 'id = ?', whereArgs: [toAccountId]);

      final isFromStation = fromAccQuery.isNotEmpty &&
          fromAccQuery.first['account_type'] == 'STATION';
      final isToStation = toAccQuery.isNotEmpty &&
          toAccQuery.first['account_type'] == 'STATION';

      // 1. قيد تحويل صادر (خصم من المحول منه)
      final outTxId = await txn.insert('transactions', {
        'transaction_number': '$txNumberBase-1',
        'transaction_date': dateClean,
        'type_id': 6, // تحويل (خصم)
        'account_id': fromAccountId,
        'station_id': isFromStation ? fromAccountId : null,
        'fuel_type_id': fuelTypeId,
        'unit_id': unitId,
        'entered_quantity': enteredQuantity,
        'base_quantity_liters': baseQuantityLiters,
        'reference_number': refNum,
        'recipient_name': toAccountName,
        'notes': customNotes,
        'created_at': now.toIso8601String(),
        'is_deleted': 0,
      });

      // 2. قيد تحويل وارد (إضافة للمحول إليه)، مرتبط بالقيد الأول
      await txn.insert('transactions', {
        'transaction_number': '$txNumberBase-2',
        'transaction_date': dateClean,
        'type_id': 7, // تحويل (إضافة)
        'account_id': toAccountId,
        'station_id': isToStation ? toAccountId : null,
        'parent_transaction_id': outTxId,
        'fuel_type_id': fuelTypeId,
        'unit_id': unitId,
        'entered_quantity': enteredQuantity,
        'base_quantity_liters': baseQuantityLiters,
        'reference_number': refNum,
        'recipient_name': fromAccountName,
        'notes': customNotes,
        'created_at': now.toIso8601String(),
        'is_deleted': 0,
      });

      return true;
    });
  }

  /// جلب المحطات المعتمدة من جدول الحسابات
  Future<List<Map<String, dynamic>>> getStations() async {
    final db = await _dbHelper.database;
    return await db.query(
      'accounts',
      where: 'account_type = ? AND is_active = ? AND is_archived = ?',
      whereArgs: ['STATION', 1, 0],
      orderBy: 'name ASC',
    );
  }

  /// جلب أنواع الوقود المعتمدة
  Future<List<Map<String, dynamic>>> getFuelTypes() async {
    final db = await _dbHelper.database;
    return await db.query(
      'fuel_types',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'id ASC',
    );
  }

  /// جلب الوحدات ومعاملات التحويل
  Future<List<Map<String, dynamic>>> getUnits() async {
    final db = await _dbHelper.database;
    return await db.query(
      'units',
      orderBy: 'conversion_factor ASC',
    );
  }

  /// جلب أنواع العمليات
  Future<List<Map<String, dynamic>>> getTransactionTypes() async {
    final db = await _dbHelper.database;
    return await db.query(
      'transaction_types',
      orderBy: 'id ASC',
    );
  }
}
