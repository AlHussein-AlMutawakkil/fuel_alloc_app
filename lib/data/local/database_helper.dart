import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// مدير قاعدة البيانات المحلية SQLite
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'fuel_allocation.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onOpen: (db) async {
        final columns = await db.rawQuery('PRAGMA table_info(transactions)');
        final hasRef = columns.any((c) => c['name'] == 'reference_number');
        if (!hasRef) {
          await db.execute(
              'ALTER TABLE transactions ADD COLUMN reference_number TEXT;');
        }
        final hasRecipient = columns.any((c) => c['name'] == 'recipient_name');
        if (!hasRecipient) {
          await db.execute(
              'ALTER TABLE transactions ADD COLUMN recipient_name TEXT;');
        }
        final hasDeleted = columns.any((c) => c['name'] == 'is_deleted');
        if (!hasDeleted) {
          await db.execute(
              'ALTER TABLE transactions ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0;');
        }
        final hasTxDeletedAt = columns.any((c) => c['name'] == 'deleted_at');
        if (!hasTxDeletedAt) {
          await db
              .execute('ALTER TABLE transactions ADD COLUMN deleted_at TEXT;');
        }

        final accCols = await db.rawQuery('PRAGMA table_info(accounts)');
        final hasArchived = accCols.any((c) => c['name'] == 'is_archived');
        if (!hasArchived) {
          await db.execute(
              'ALTER TABLE accounts ADD COLUMN is_archived INTEGER NOT NULL DEFAULT 0;');
        }
        final hasAccDeletedAt = accCols.any((c) => c['name'] == 'deleted_at');
        if (!hasAccDeletedAt) {
          await db.execute('ALTER TABLE accounts ADD COLUMN deleted_at TEXT;');
        }
        final hasAccLocation = accCols.any((c) => c['name'] == 'location');
        if (!hasAccLocation) {
          await db.execute('ALTER TABLE accounts ADD COLUMN location TEXT;');
        }
        final hasAccCommission =
            accCols.any((c) => c['name'] == 'default_commission_rate');
        if (!hasAccCommission) {
          await db.execute(
              'ALTER TABLE accounts ADD COLUMN default_commission_rate REAL NOT NULL DEFAULT 2.0;');
        }

        final stCols = await db.rawQuery('PRAGMA table_info(stations)');
        final hasStArchived = stCols.any((c) => c['name'] == 'is_archived');
        if (!hasStArchived) {
          await db.execute(
              'ALTER TABLE stations ADD COLUMN is_archived INTEGER NOT NULL DEFAULT 0;');
        }
        final hasStDeletedAt = stCols.any((c) => c['name'] == 'deleted_at');
        if (!hasStDeletedAt) {
          await db.execute('ALTER TABLE stations ADD COLUMN deleted_at TEXT;');
        }

        // جدول الإعدادات العامة (Settings)
        await db.execute('''
          CREATE TABLE IF NOT EXISTS app_settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          );
        ''');

        // التأكد من وجود نوعي عملية التحويل في transaction_types وتحديث الاسم إلى "تحويل"
        await db.execute('''
          INSERT OR IGNORE INTO transaction_types (id, name, code)
          VALUES 
            (6, 'تحويل', 'TRANSFER_OUT'),
            (7, 'تحويل', 'TRANSFER_IN');
        ''');
        await db.execute('''
          UPDATE transaction_types SET name = 'تحويل' WHERE id IN (6, 7);
        ''');

        // ترحيل بيانات المحطات من جدول stations إلى جدول accounts الموحد (إن وجدت)
        final tables = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='stations'");
        if (tables.isNotEmpty) {
          final existingStations = await db.rawQuery('SELECT * FROM stations');
          for (final st in existingStations) {
            final stName = st['name'] as String;
            final existingAcc = await db.query(
              'accounts',
              where: 'name = ? AND account_type = ?',
              whereArgs: [stName, 'STATION'],
            );
            int newAccId;
            if (existingAcc.isEmpty) {
              newAccId = await db.insert('accounts', {
                'name': stName,
                'account_type': 'STATION',
                'phone_number': st['phone_number'],
                'location': st['location'],
                'default_commission_rate':
                    (st['default_commission_rate'] as num?)?.toDouble() ?? 2.0,
                'is_active': st['is_active'] ?? 1,
                'is_archived': st['is_archived'] ?? 0,
                'deleted_at': st['deleted_at'],
                'created_at':
                    st['created_at'] ?? DateTime.now().toIso8601String(),
              });
            } else {
              newAccId = existingAcc.first['id'] as int;
            }
            final oldStId = st['id'] as int;
            await db.rawUpdate(
                'UPDATE transactions SET station_id = ? WHERE station_id = ?',
                [newAccId, oldStId]);
            await db.rawUpdate(
                'UPDATE transactions SET reference_station_id = ? WHERE reference_station_id = ?',
                [newAccId, oldStId]);
          }
        }
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. جدول الحسابات الموحد (الموردين والعملاء والمحطات)
    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        account_type TEXT NOT NULL, -- 'SUPPLIER' أو 'BENEFICIARY' أو 'STATION'
        phone_number TEXT,
        location TEXT,
        default_commission_rate REAL NOT NULL DEFAULT 2.0,
        is_active INTEGER NOT NULL DEFAULT 1,
        is_archived INTEGER NOT NULL DEFAULT 0,
        deleted_at TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // 2. جدول المحطات
    await db.execute('''
      CREATE TABLE stations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        location TEXT,
        phone_number TEXT,
        default_commission_rate REAL NOT NULL DEFAULT 2.0, -- عمولة التهوية
        is_active INTEGER NOT NULL DEFAULT 1,
        is_archived INTEGER NOT NULL DEFAULT 0,
        deleted_at TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // 3. جدول الوحدات والتحويلات
    await db.execute('''
      CREATE TABLE units (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        conversion_factor REAL NOT NULL, -- معامل التحويل إلى لتر
        is_base_unit INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 4. جدول الأصناف (أنواع الوقود)
    await db.execute('''
      CREATE TABLE fuel_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // 5. جدول أنواع العمليات
    await db.execute('''
      CREATE TABLE transaction_types (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        code TEXT NOT NULL
      )
    ''');

    // 6. جدول العمليات والقيود المحاسبية
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_number TEXT UNIQUE,
        transaction_date TEXT NOT NULL,
        type_id INTEGER NOT NULL,
        account_id INTEGER,
        station_id INTEGER,
        reference_station_id INTEGER,
        fuel_type_id INTEGER,
        unit_id INTEGER NOT NULL,
        entered_quantity REAL NOT NULL,
        base_quantity_liters REAL NOT NULL,
        reference_number TEXT,
        recipient_name TEXT,
        parent_transaction_id INTEGER,
        notes TEXT,
        created_at TEXT NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        deleted_at TEXT,
        FOREIGN KEY (account_id) REFERENCES accounts (id),
        FOREIGN KEY (station_id) REFERENCES stations (id),
        FOREIGN KEY (reference_station_id) REFERENCES stations (id),
        FOREIGN KEY (unit_id) REFERENCES units (id),
        FOREIGN KEY (parent_transaction_id) REFERENCES transactions (id)
      )
    ''');

    // جدول الإعدادات العامة (Settings)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');

    // تهيئة البيانات الافتراضية
    await _insertInitialData(db);
  }

  Future<void> _insertInitialData(Database db) async {
    // إدراج إعداد سلة المحذوفات الافتراضي (مفعلة)
    await db.insert(
        'app_settings',
        {
          'key': 'recycle_bin_enabled',
          'value': 'true',
        },
        conflictAlgorithm: ConflictAlgorithm.ignore);

    // إدراج الوحدات الافتراضية
    await db.insert(
        'units', {'name': 'لتر', 'conversion_factor': 1.0, 'is_base_unit': 1});
    await db.insert(
        'units', {'name': 'دبة', 'conversion_factor': 20.0, 'is_base_unit': 0});
    await db.insert('units',
        {'name': 'برميل', 'conversion_factor': 200.0, 'is_base_unit': 0});

    // إدراج الأصناف الافتراضية
    await db.insert('fuel_types', {'name': 'بترول', 'is_active': 1});
    await db.insert('fuel_types', {'name': 'ديزل', 'is_active': 1});

    // إدراج أنواع العمليات
    await db.insert('transaction_types',
        {'id': 1, 'name': 'توريد اعتماد', 'code': 'SUPPLY_QUOTA'});
    await db.insert('transaction_types',
        {'id': 2, 'name': 'توريد فعلي', 'code': 'SUPPLY_ACTUAL'});
    await db.insert('transaction_types',
        {'id': 3, 'name': 'عمولة تهوية', 'code': 'AERATION_COMMISSION'});
    await db.insert('transaction_types',
        {'id': 4, 'name': 'صرف اعتماد', 'code': 'DISPENSE_QUOTA'});
    await db.insert('transaction_types',
        {'id': 5, 'name': 'صرف فعلي', 'code': 'DISPENSE_ACTUAL'});
    await db.insert('transaction_types',
        {'id': 6, 'name': 'تحويل', 'code': 'TRANSFER_OUT'});
    await db.insert(
        'transaction_types', {'id': 7, 'name': 'تحويل', 'code': 'TRANSFER_IN'});
  }

  /// فحص هل سلة المحذوفات مفعلة
  Future<bool> isRecycleBinEnabled() async {
    final db = await database;
    final res = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['recycle_bin_enabled'],
    );
    if (res.isEmpty) return true;
    return res.first['value'] == 'true';
  }

  /// تغيير إعداد سلة المحذوفات
  Future<void> setRecycleBinEnabled(bool enabled) async {
    final db = await database;
    await db.insert(
      'app_settings',
      {'key': 'recycle_bin_enabled', 'value': enabled ? 'true' : 'false'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// الحصول على المسار الفعلي لملف قاعدة البيانات المحلي
  Future<String> getDatabaseFilePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'fuel_allocation.db');
  }

  /// إغلاق اتصال قاعدة البيانات الحالي بأمان
  Future<void> closeDatabase() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }

  /// استبدال واستعادة ملف قاعدة البيانات من مسار محدد
  Future<bool> restoreDatabaseFromFile(String sourceFilePath) async {
    final sourceFile = File(sourceFilePath);
    if (!await sourceFile.exists()) return false;

    // التحقق من صحة الملف (ترويسة SQLite)
    final bytes = await sourceFile.openRead(0, 16).first;
    final header = String.fromCharCodes(bytes);
    if (!header.startsWith('SQLite format 3')) {
      return false; // ملف غير صالح أو تالف
    }

    final targetPath = await getDatabaseFilePath();
    await closeDatabase();
    await sourceFile.copy(targetPath);
    await database; // إعادة فتح وتهيئة الاتصال
    return true;
  }
}
