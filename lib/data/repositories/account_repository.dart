import '../../models/account_model.dart';
import '../local/database_helper.dart';

/// مستودع إدارة بيانات الحسابات في قاعدة البيانات
class AccountRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<AccountModel>> getAllAccounts() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: 'is_active = ?',
      whereArgs: [1],
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

  Future<int> deleteAccount(int id) async {
    final db = await _dbHelper.database;
    // حذف منطقي (Logical Delete) أو حذف فعلي
    return await db.update(
      'accounts',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
