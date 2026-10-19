import '../../models/station_model.dart';
import '../local/database_helper.dart';

/// مستودع إدارة بيانات المحطات (يعمل مباشرة على جدول الحسابات accounts بنوع STATION)
class StationRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// جلب كافة المحطات النشطة غير المؤرشفة مع رصيد كل محطة المتاح حالياً باللتر
  Future<List<StationModel>> getAllStationsWithBalance() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        s.*,
        COALESCE(
          (SELECT SUM(CASE 
             WHEN t.type_id = 2 THEN t.base_quantity_liters 
             WHEN t.type_id = 3 THEN -t.base_quantity_liters 
             WHEN t.type_id = 5 THEN -t.base_quantity_liters 
             ELSE 0 
           END)
           FROM transactions t
           WHERE t.is_deleted = 0 AND ((t.type_id IN (2, 3) AND t.station_id = s.id)
              OR (t.type_id = 5 AND COALESCE(t.reference_station_id, t.station_id) = s.id))
          ), 0.0) AS balance
      FROM accounts s
      WHERE s.account_type = 'STATION' AND s.is_active = 1 AND s.is_archived = 0
      ORDER BY s.name ASC
    ''');
    return maps.map((map) => StationModel.fromMap(map)).toList();
  }

  /// جلب المحطات المؤرشفة
  Future<List<StationModel>> getArchivedStations() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT s.*
      FROM accounts s
      WHERE s.account_type = 'STATION' AND s.is_active = 1 AND s.is_archived = 1
      ORDER BY s.name ASC
    ''');
    return maps.map((map) => StationModel.fromMap(map)).toList();
  }

  /// جلب المحطات المحذوفة في سلة المحذوفات
  Future<List<StationModel>> getDeletedStations() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: "account_type = 'STATION' AND is_active = 0",
      orderBy: 'deleted_at DESC, name ASC',
    );
    return maps.map((map) => StationModel.fromMap(map)).toList();
  }

  /// إضافة محطة جديدة
  Future<int> insertStation(StationModel station) async {
    final db = await _dbHelper.database;
    return await db.insert('accounts', station.toMap());
  }

  /// تعديل بيانات محطة
  Future<int> updateStation(StationModel station) async {
    final db = await _dbHelper.database;
    return await db.update(
      'accounts',
      station.toMap(),
      where: 'id = ?',
      whereArgs: [station.id],
    );
  }

  /// أرشفة المحطة
  Future<int> archiveStation(int id) async {
    final db = await _dbHelper.database;
    return await db.update(
      'accounts',
      {'is_archived': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// إلغاء أرشفة المحطة
  Future<int> unarchiveStation(int id) async {
    final db = await _dbHelper.database;
    return await db.update(
      'accounts',
      {'is_archived': 0, 'is_active': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// حذف محطة (إلى سلة المحذوفات أو نهائياً حسب الإعداد)
  Future<int> deleteStation(int id, {bool? forcePermanent}) async {
    final db = await _dbHelper.database;
    final isRecycle = forcePermanent == true
        ? false
        : await _dbHelper.isRecycleBinEnabled();

    if (!isRecycle) {
      return await permanentlyDeleteStation(id);
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

  /// استعادة المحطة من سلة المحذوفات
  Future<int> restoreStation(int id) async {
    final db = await _dbHelper.database;
    return await db.update(
      'accounts',
      {'is_active': 1, 'is_archived': 0, 'deleted_at': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// حذف نهائي للمحطة
  Future<int> permanentlyDeleteStation(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
