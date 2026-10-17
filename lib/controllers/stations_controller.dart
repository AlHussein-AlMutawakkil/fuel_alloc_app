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

  /// حذف محطة
  Future<bool> deleteStation(int id) async {
    try {
      await _repository.deleteStation(id);
      await fetchStations();
      return true;
    } catch (e) {
      debugPrint('Error deleting station: $e');
      return false;
    }
  }
}
