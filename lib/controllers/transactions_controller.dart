import 'package:flutter/foundation.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../models/transaction_model.dart';

/// متحكم إدارة العمليات والقيود المحاسبية
class TransactionsController extends ChangeNotifier {
  final TransactionRepository _repository = TransactionRepository();

  List<TransactionModel> _allTransactions = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedFilter =
      'ALL'; // ALL, QUOTA, ACTUAL, SUPPLY, DISPENSE, AERATION
  int? _selectedFuelTypeId;

  List<Map<String, dynamic>> _stations = [];
  List<Map<String, dynamic>> _fuelTypes = [];
  List<Map<String, dynamic>> _units = [];
  List<Map<String, dynamic>> _transactionTypes = [];

  // Getters
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedFilter => _selectedFilter;
  int? get selectedFuelTypeId => _selectedFuelTypeId;

  List<Map<String, dynamic>> get stations => _stations;
  List<Map<String, dynamic>> get fuelTypes => _fuelTypes;
  List<Map<String, dynamic>> get units => _units;
  List<Map<String, dynamic>> get transactionTypes => _transactionTypes;

  void setSelectedFuelTypeId(int? fuelTypeId) {
    if (_selectedFuelTypeId != fuelTypeId) {
      _selectedFuelTypeId = fuelTypeId;
      notifyListeners();
    }
  }

  /// قائمة العمليات المفلترة بحسب نوع الحركة وصنف الوقود والبحث
  List<TransactionModel> get transactions {
    return _allTransactions.where((tx) {
      // 1. فلترة بالنوع
      bool matchesFilter = true;
      if (_selectedFilter == 'QUOTA') {
        matchesFilter = tx.isQuota;
      } else if (_selectedFilter == 'ACTUAL') {
        matchesFilter = tx.isActual;
      } else if (_selectedFilter == 'SUPPLY') {
        matchesFilter = tx.typeId == 2;
      } else if (_selectedFilter == 'DISPENSE') {
        matchesFilter = tx.typeId == 5;
      } else if (_selectedFilter == 'AERATION') {
        matchesFilter = tx.typeId == 3;
      }

      // 2. فلترة بصنف الوقود المعروض بالكرت (بترول / ديزل)
      bool matchesFuel = true;
      if (_selectedFuelTypeId != null) {
        matchesFuel = tx.fuelTypeId == _selectedFuelTypeId;
      }

      // 3. فلترة بالبحث
      bool matchesSearch = true;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        matchesSearch = (tx.notes?.toLowerCase().contains(q) ?? false) ||
            (tx.stationName?.toLowerCase().contains(q) ?? false) ||
            (tx.referenceStationName?.toLowerCase().contains(q) ?? false) ||
            (tx.accountName?.toLowerCase().contains(q) ?? false) ||
            (tx.fuelTypeName?.toLowerCase().contains(q) ?? false) ||
            (tx.typeName?.toLowerCase().contains(q) ?? false) ||
            tx.transactionDate.contains(q);
      }

      return matchesFilter && matchesFuel && matchesSearch;
    }).toList();
  }

  /// إجمالي الاعتماد باللتر
  double get totalQuotaLiters {
    return _allTransactions
        .where((tx) => tx.isQuota)
        .fold(0.0, (sum, tx) => sum + tx.baseQuantityLiters);
  }

  /// إجمالي المنفذ الفعلي باللتر
  double get totalActualLiters {
    return _allTransactions
        .where((tx) => tx.isActual)
        .fold(0.0, (sum, tx) => sum + tx.baseQuantityLiters);
  }

  /// الرصيد المتبقي (الاعتماد - الفعلي)
  double get balanceLiters {
    return totalQuotaLiters - totalActualLiters;
  }

  /// إجمالي عمولة التهوية باللتر إن وجدت
  double get totalAerationLiters {
    return _allTransactions
        .where((tx) => tx.isAeration)
        .fold(0.0, (sum, tx) => sum + tx.baseQuantityLiters);
  }

  /// إجمالي الاعتماد لصنف معين باللتر
  double getQuotaLitersForFuel(int fuelTypeId) {
    return _allTransactions
        .where((tx) => tx.isQuota && tx.fuelTypeId == fuelTypeId)
        .fold(0.0, (sum, tx) => sum + tx.baseQuantityLiters);
  }

  /// إجمالي المنفذ الفعلي لصنف معين باللتر
  double getActualLitersForFuel(int fuelTypeId) {
    return _allTransactions
        .where((tx) => tx.isActual && tx.fuelTypeId == fuelTypeId)
        .fold(0.0, (sum, tx) => sum + tx.baseQuantityLiters);
  }

  /// الرصيد المتبقي لصنف معين باللتر
  double getBalanceLitersForFuel(int fuelTypeId) {
    return getQuotaLitersForFuel(fuelTypeId) -
        getActualLitersForFuel(fuelTypeId);
  }

  /// الوارد الفعلي لمحطة لصنف معين
  double getStationSupplyForFuel(int fuelTypeId) {
    if (_currentStationId == null) return 0.0;
    return _allTransactions
        .where((tx) =>
            tx.typeId == 2 &&
            tx.stationId == _currentStationId &&
            tx.fuelTypeId == fuelTypeId)
        .fold(0.0, (sum, tx) => sum + tx.baseQuantityLiters);
  }

  /// المنصرف الفعلي من محطة لصنف معين
  double getStationDispenseForFuel(int fuelTypeId) {
    if (_currentStationId == null) return 0.0;
    return _allTransactions
        .where((tx) =>
            tx.typeId == 5 &&
            (tx.referenceStationId ?? tx.stationId) == _currentStationId &&
            tx.fuelTypeId == fuelTypeId)
        .fold(0.0, (sum, tx) => sum + tx.baseQuantityLiters);
  }

  /// عمولة التهوية لمحطة لصنف معين
  double getStationAerationForFuel(int fuelTypeId) {
    if (_currentStationId == null) return 0.0;
    return _allTransactions
        .where((tx) =>
            tx.typeId == 3 &&
            tx.stationId == _currentStationId &&
            tx.fuelTypeId == fuelTypeId)
        .fold(0.0, (sum, tx) => sum + tx.baseQuantityLiters);
  }

  /// الرصيد المتبقي بمحطة لصنف معين
  double getStationBalanceForFuel(int fuelTypeId) {
    return getStationSupplyForFuel(fuelTypeId) -
        (getStationDispenseForFuel(fuelTypeId) +
            getStationAerationForFuel(fuelTypeId));
  }

  /// رصيد محطة معينة حالياً
  Future<double> getStationBalance(int stationId) async {
    return await _repository.getStationBalance(stationId);
  }

  /// رصيد حساب معين حالياً
  Future<double> getAccountBalance(int accountId, bool isSupplier) async {
    return await _repository.getAccountBalance(accountId, isSupplier);
  }

  int? _currentAccountId;
  int? _currentStationId;

  int? get currentAccountId => _currentAccountId;
  int? get currentStationId => _currentStationId;

  /// إحصائيات كشف المحطة باللتر
  double get stationTotalSupplyLiters {
    if (_currentStationId == null) return 0.0;
    return _allTransactions
        .where((tx) => tx.typeId == 2 && tx.stationId == _currentStationId)
        .fold(0.0, (sum, tx) => sum + tx.baseQuantityLiters);
  }

  double get stationTotalDispenseLiters {
    if (_currentStationId == null) return 0.0;
    return _allTransactions
        .where((tx) =>
            tx.typeId == 5 &&
            (tx.referenceStationId ?? tx.stationId) == _currentStationId)
        .fold(0.0, (sum, tx) => sum + tx.baseQuantityLiters);
  }

  double get stationTotalAerationLiters {
    if (_currentStationId == null) return 0.0;
    return _allTransactions
        .where((tx) => tx.typeId == 3 && tx.stationId == _currentStationId)
        .fold(0.0, (sum, tx) => sum + tx.baseQuantityLiters);
  }

  double get stationNetBalanceLiters {
    return stationTotalSupplyLiters -
        (stationTotalDispenseLiters + stationTotalAerationLiters);
  }

  /// جلب عمليات حساب معين
  Future<void> fetchAccountTransactions(int accountId,
      {int? defaultFuelTypeId}) async {
    _currentAccountId = accountId;
    _currentStationId = null;
    _isLoading = true;
    notifyListeners();

    try {
      _allTransactions =
          await _repository.getTransactionsByAccountId(accountId);
      await loadFormData();
      if (defaultFuelTypeId != null) {
        _selectedFuelTypeId = defaultFuelTypeId;
      } else if (_fuelTypes.isNotEmpty) {
        final exists = _fuelTypes.any((ft) => ft['id'] == _selectedFuelTypeId);
        if (!exists) {
          _selectedFuelTypeId = _fuelTypes.first['id'] as int;
        }
      }
    } catch (e) {
      debugPrint('Error fetching account transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// جلب كافة عمليات محطة معينة (للمطابقة والمحاسبة)
  Future<void> fetchStationTransactions(int stationId,
      {int? defaultFuelTypeId}) async {
    _currentStationId = stationId;
    _currentAccountId = null;
    _isLoading = true;
    notifyListeners();

    try {
      _allTransactions =
          await _repository.getTransactionsByStationId(stationId);
      await loadFormData();
      if (defaultFuelTypeId != null) {
        _selectedFuelTypeId = defaultFuelTypeId;
      } else if (_fuelTypes.isNotEmpty) {
        final exists = _fuelTypes.any((ft) => ft['id'] == _selectedFuelTypeId);
        if (!exists) {
          _selectedFuelTypeId = _fuelTypes.first['id'] as int;
        }
      }
    } catch (e) {
      debugPrint('Error fetching station transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// تحميل البيانات المرجعية المساعدة
  Future<void> loadFormData() async {
    try {
      _stations = await _repository.getStations();
      _fuelTypes = await _repository.getFuelTypes();
      _units = await _repository.getUnits();
      _transactionTypes = await _repository.getTransactionTypes();
    } catch (e) {
      debugPrint('Error loading form reference data: $e');
    }
  }

  /// تعيين فلتر العرض
  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  /// تعيين نص البحث
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// إعادة تحميل العمليات النشطة حالياً (لحساب أو لمحطة)
  Future<void> reloadCurrentView() async {
    if (_currentAccountId != null) {
      _allTransactions =
          await _repository.getTransactionsByAccountId(_currentAccountId!);
    } else if (_currentStationId != null) {
      _allTransactions =
          await _repository.getTransactionsByStationId(_currentStationId!);
    }
    notifyListeners();
  }

  /// إضافة عملية لحساب أو محطة
  Future<bool> addTransaction(TransactionModel tx) async {
    try {
      await _repository.insertTransaction(tx);
      await reloadCurrentView();
      return true;
    } catch (e) {
      debugPrint('Error adding transaction: $e');
      return false;
    }
  }

  /// تعديل عملية قائمة
  Future<bool> updateTransaction(TransactionModel tx) async {
    try {
      await _repository.updateTransaction(tx);
      await reloadCurrentView();
      return true;
    } catch (e) {
      debugPrint('Error updating transaction: $e');
      return false;
    }
  }

  /// حذف عملية لحساب
  Future<bool> deleteTransaction(int id, int accountId) async {
    try {
      await _repository.deleteTransaction(id);
      _allTransactions =
          await _repository.getTransactionsByAccountId(accountId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting transaction: $e');
      return false;
    }
  }

  /// حذف عملية لمحطة
  Future<bool> deleteStationTransaction(int id, int stationId) async {
    try {
      await _repository.deleteTransaction(id);
      _allTransactions =
          await _repository.getTransactionsByStationId(stationId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting station transaction: $e');
      return false;
    }
  }
}
