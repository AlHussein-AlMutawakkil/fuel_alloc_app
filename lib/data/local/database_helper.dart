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
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. جدول الحسابات الموحد (الموردين والعملاء)
    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        account_type TEXT NOT NULL, -- 'SUPPLIER' أو 'BENEFICIARY'
        phone_number TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
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
        parent_transaction_id INTEGER,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (account_id) REFERENCES accounts (id),
        FOREIGN KEY (station_id) REFERENCES stations (id),
        FOREIGN KEY (reference_station_id) REFERENCES stations (id),
        FOREIGN KEY (unit_id) REFERENCES units (id),
        FOREIGN KEY (parent_transaction_id) REFERENCES transactions (id)
      )
    ''');

    // تهيئة البيانات الافتراضية
    await _insertInitialData(db);
  }

  Future<void> _insertInitialData(Database db) async {
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
  }
}
