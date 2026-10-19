import '../../models/account_model.dart';
import '../local/database_helper.dart';

/// مستودع إدارة بيانات الحسابات في قاعدة البيانات
class AccountRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// جلب كافة الحسابات النشطة غير المؤرشفة وغير المحذوفة
  Future<List<AccountModel>> getAllAccounts() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: 'is_active = ? AND is_archived = ?',
      whereArgs: [1, 0],
      orderBy: 'name ASC',
    );
    return maps.map((map) => AccountModel.fromMap(map)).toList();
  }

  /// جلب الحسابات المؤرشفة
  Future<List<AccountModel>> getArchivedAccounts() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: 'is_active = ? AND is_archived = ?',
      whereArgs: [1, 1],
      orderBy: 'name ASC',
    );
    return maps.map((map) => AccountModel.fromMap(map)).toList();
  }

  /// جلب الحسابات المحذوفة (سلة المحذوفات) مع عدد العمليات وتاريخ الحذف
  Future<List<AccountModel>> getDeletedAccounts() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        a.*, 
        COUNT(t.id) AS operations_count
      FROM accounts a
      LEFT JOIN transactions t ON (t.account_id = a.id OR t.station_id = a.id OR t.reference_station_id = a.id) AND t.is_deleted = 0
      WHERE a.is_active = 0
      GROUP BY a.id
      ORDER BY a.deleted_at DESC, a.name ASC
    ''');
    return maps.map((map) => AccountModel.fromMap(map)).toList();
  }

  /// جلب كافة المحطات النشطة غير المؤرشفة
  Future<List<AccountModel>> getStations() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: 'account_type = ? AND is_active = ? AND is_archived = ?',
      whereArgs: ['STATION', 1, 0],
      orderBy: 'name ASC',
    );
    return maps.map((map) => AccountModel.fromMap(map)).toList();
  }

  Future<int> insertAccount(AccountModel account) async {
    final db = await _dbHelper.database;
    return await db.insert('accounts', account.toMap());
  }

  Future<int> updateAccount(AccountModel account) async {
    final db = await _dbHelper.database;
    return await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  /// نقل الحساب لسلة المحذوفات (أو حذف نهائي إذا كانت السلة معطلة)
  Future<int> deleteAccount(int id, {bool? forcePermanent}) async {
    final db = await _dbHelper.database;
    final isRecycleEnabled = forcePermanent == true
        ? false
        : await _dbHelper.isRecycleBinEnabled();

    if (!isRecycleEnabled) {
      return await permanentlyDeleteAccount(id);
    }

    return await db.update(
      'accounts',
      {
        'is_active': 0,
        'deleted_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// أرشفة الحساب
  Future<int> archiveAccount(int id) async {
    final db = await _dbHelper.database;
    return await db.update(
      'accounts',
      {'is_archived': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// إلغاء أرشفة الحساب واستعادته للنشط
  Future<int> unarchiveAccount(int id) async {
    final db = await _dbHelper.database;
    return await db.update(
      'accounts',
      {'is_archived': 0, 'is_active': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// استعادة الحساب من سلة المحذوفات
  Future<int> restoreAccount(int id) async {
    final db = await _dbHelper.database;
    return await db.update(
      'accounts',
      {'is_active': 1, 'is_archived': 0, 'deleted_at': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// حذف نهائي للحساب من قاعدة البيانات
  Future<int> permanentlyDeleteAccount(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
