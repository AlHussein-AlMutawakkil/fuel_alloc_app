import 'package:flutter/foundation.dart';
import '../../data/repositories/station_repository.dart';
import '../../models/station_model.dart';

/// متحكم إدارة المحطات وأرصدتها
class StationsController extends ChangeNotifier {
  final StationRepository _repository = StationRepository();

  List<StationModel> _allStations = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<StationModel> get stations {
    return _allStations.where((station) {
      final matchesSearch = _searchQuery.isEmpty ||
          station.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (station.location
                  ?.toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ??
              false) ||
          (station.phoneNumber?.contains(_searchQuery) ?? false);
      return matchesSearch;
    }).toList();
  }

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  /// جلب كافة المحطات مع أرصدتها المحدثة
  Future<void> fetchStations() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allStations = await _repository.getAllStationsWithBalance();
    } catch (e) {
      debugPrint('Error fetching stations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// إضافة محطة جديدة
  Future<bool> addStation({
    required String name,
    String? location,
    String? phone,
    double defaultCommission = 2.0,
  }) async {
    try {
      final newStation = StationModel(
        name: name.trim(),
        location: location?.trim().isEmpty == true ? null : location?.trim(),
        phoneNumber: phone?.trim().isEmpty == true ? null : phone?.trim(),
        defaultCommissionRate: defaultCommission,
      );
      await _repository.insertStation(newStation);
      await fetchStations();
      return true;
    } catch (e) {
      debugPrint('Error adding station: $e');
      return false;
    }
  }

  /// تعديل بيانات محطة
  Future<bool> updateStation(StationModel station) async {
    try {
      await _repository.updateStation(station);
      await fetchStations();
      return true;
    } catch (e) {
      debugPrint('Error updating station: $e');
      return false;
    }
  }

  List<StationModel> _archivedStations = [];
  List<StationModel> get archivedStations => _archivedStations;

  List<StationModel> _deletedStations = [];
  List<StationModel> get deletedStations => _deletedStations;

  /// جلب المحطات المؤرشفة
  Future<void> fetchArchivedStations() async {
    _isLoading = true;
    notifyListeners();
    try {
      _archivedStations = await _repository.getArchivedStations();
    } catch (e) {
      debugPrint('Error fetching archived stations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// جلب المحطات المحذوفة
  Future<void> fetchDeletedStations() async {
    _isLoading = true;
    notifyListeners();
    try {
      _deletedStations = await _repository.getDeletedStations();
    } catch (e) {
      debugPrint('Error fetching deleted stations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// أرشفة محطة
  Future<bool> archiveStation(int id) async {
    try {
      await _repository.archiveStation(id);
      await fetchStations();
      await fetchArchivedStations();
      return true;
    } catch (e) {
      debugPrint('Error archiving station: $e');
      return false;
    }
  }

  /// إلغاء أرشفة محطة
  Future<bool> unarchiveStation(int id) async {
    try {
      await _repository.unarchiveStation(id);
      await fetchStations();
      await fetchArchivedStations();
      return true;
    } catch (e) {
      debugPrint('Error unarchiving station: $e');
      return false;
    }
  }

  /// حذف محطة (نقل لسلة المحذوفات أو نهائياً)
  Future<bool> deleteStation(int id, {bool? forcePermanent}) async {
    try {
      await _repository.deleteStation(id, forcePermanent: forcePermanent);
      await fetchStations();
      return true;
    } catch (e) {
      debugPrint('Error deleting station: $e');
      return false;
    }
  }

  /// استعادة محطة من سلة المحذوفات
  Future<bool> restoreStation(int id) async {
    try {
      await _repository.restoreStation(id);
      await fetchStations();
      await fetchDeletedStations();
      return true;
    } catch (e) {
      debugPrint('Error restoring station: $e');
      return false;
    }
  }

  /// حذف محطة نهائياً من قاعدة البيانات
  Future<bool> permanentlyDeleteStation(int id) async {
    try {
      await _repository.permanentlyDeleteStation(id);
      await fetchDeletedStations();
      return true;
    } catch (e) {
      debugPrint('Error permanently deleting station: $e');
      return false;
    }
  }
}
