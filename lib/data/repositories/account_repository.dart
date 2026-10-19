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

  /// جلب الحسابات المحذوفة (سلة المحذوفات)
  Future<List<AccountModel>> getDeletedAccounts() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: 'is_active = ?',
      whereArgs: [0],
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

  /// نقل الحساب لسلة المحذوفات (حذف منطقي)
  Future<int> deleteAccount(int id) async {
    final db = await _dbHelper.database;
    return await db.update(
      'accounts',
      {'is_active': 0},
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
      {'is_active': 1, 'is_archived': 0},
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
