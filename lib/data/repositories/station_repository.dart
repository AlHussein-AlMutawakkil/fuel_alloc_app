import '../../models/station_model.dart';
import '../local/database_helper.dart';

/// مستودع إدارة بيانات المحطات في قاعدة البيانات
class StationRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// جلب كافة المحطات مع رصيد كل محطة المتاح حالياً باللتر
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
           WHERE (t.type_id IN (2, 3) AND t.station_id = s.id)
              OR (t.type_id = 5 AND COALESCE(t.reference_station_id, t.station_id) = s.id)
          ), 0.0) AS balance
      FROM stations s
      WHERE s.is_active = 1
      ORDER BY s.name ASC
    ''');
    return maps.map((map) => StationModel.fromMap(map)).toList();
  }

  /// إضافة محطة جديدة
  Future<int> insertStation(StationModel station) async {
    final db = await _dbHelper.database;
    return await db.insert('stations', station.toMap());
  }

  /// تعديل بيانات محطة
  Future<int> updateStation(StationModel station) async {
    final db = await _dbHelper.database;
    return await db.update(
      'stations',
      station.toMap(),
      where: 'id = ?',
      whereArgs: [station.id],
    );
  }

  /// حذف محطة منطقياً
  Future<int> deleteStation(int id) async {
    final db = await _dbHelper.database;
    return await db.update(
      'stations',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
