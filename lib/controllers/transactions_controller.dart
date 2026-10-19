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

  /// الأصناف التي توجد لها عمليات مسجلة فعلياً للحساب/المحطة الحالي
  List<Map<String, dynamic>> get activeFuelTypes {
    final activeIds = _allTransactions
        .map((tx) => tx.fuelTypeId)
        .whereType<int>()
        .toSet();
    if (activeIds.isEmpty) return [];
    return _fuelTypes.where((ft) => activeIds.contains(ft['id'])).toList();
  }

  /// جميع العمليات الحالية للحساب/المحطة دون فلترة بصنف الوقود
  List<TransactionModel> get allTransactions =>
      List.unmodifiable(_allTransactions);

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
            (tx.recipientName?.toLowerCase().contains(q) ?? false) ||
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

  List<String> _recipientsList = [];
  List<String> get recipientsList => _recipientsList;

  /// رصيد محطة معينة حالياً (اختيارياً لصنف محدد)
  Future<double> getStationBalance(int stationId, {int? fuelTypeId}) async {
    return await _repository.getStationBalance(stationId,
        fuelTypeId: fuelTypeId);
  }

  /// رصيد حساب معين حالياً (اختيارياً لصنف محدد)
  Future<double> getAccountBalance(int accountId, bool isSupplier,
      {int? fuelTypeId}) async {
    return await _repository.getAccountBalance(accountId, isSupplier,
        fuelTypeId: fuelTypeId);
  }

  /// جلب قائمة المستلمين المميزين
  Future<List<String>> fetchRecipients() async {
    try {
      _recipientsList = await _repository.getDistinctRecipients();
      notifyListeners();
      return _recipientsList;
    } catch (e) {
      debugPrint('Error loading recipients: $e');
      return [];
    }
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
      final activeIds = _allTransactions
          .map((tx) => tx.fuelTypeId)
          .whereType<int>()
          .toSet();

      if (defaultFuelTypeId != null && activeIds.contains(defaultFuelTypeId)) {
        _selectedFuelTypeId = defaultFuelTypeId;
      } else if (activeIds.isNotEmpty) {
        if (_selectedFuelTypeId == null ||
            !activeIds.contains(_selectedFuelTypeId)) {
          _selectedFuelTypeId = activeIds.first;
        }
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
      final activeIds = _allTransactions
          .map((tx) => tx.fuelTypeId)
          .whereType<int>()
          .toSet();

      if (defaultFuelTypeId != null && activeIds.contains(defaultFuelTypeId)) {
        _selectedFuelTypeId = defaultFuelTypeId;
      } else if (activeIds.isNotEmpty) {
        if (_selectedFuelTypeId == null ||
            !activeIds.contains(_selectedFuelTypeId)) {
          _selectedFuelTypeId = activeIds.first;
        }
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
      _recipientsList = await _repository.getDistinctRecipients();
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

  List<TransactionModel> _deletedTransactions = [];
  List<TransactionModel> get deletedTransactions => _deletedTransactions;

  Map<int, Map<int, double>> _allAccountBalances = {};
  Map<int, Map<int, double>> _allStationBalances = {};
  Map<int, Map<int, double>> get allAccountBalances => _allAccountBalances;
  Map<int, Map<int, double>> get allStationBalances => _allStationBalances;

  /// جلب ملخص أرصدة كافة الحسابات والمحطات لكافة الأصناف
  Future<void> fetchAllBalancesSummary() async {
    try {
      _allAccountBalances = await _repository.getAllAccountFuelBalances();
      _allStationBalances = await _repository.getAllStationFuelBalances();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching all balances summary: $e');
    }
  }

  /// جلب العمليات المحذوفة
  Future<void> fetchDeletedTransactions() async {
    _isLoading = true;
    notifyListeners();
    try {
      _deletedTransactions = await _repository.getDeletedTransactions();
    } catch (e) {
      debugPrint('Error fetching deleted transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// استعادة عملية من سلة المحذوفات
  Future<bool> restoreTransaction(int id) async {
    try {
      await _repository.restoreTransaction(id);
      await fetchDeletedTransactions();
      await fetchAllBalancesSummary();
      await reloadCurrentView();
      return true;
    } catch (e) {
      debugPrint('Error restoring transaction: $e');
      return false;
    }
  }

  /// حذف نهائي لعملية من قاعدة البيانات
  Future<bool> permanentlyDeleteTransaction(int id) async {
    try {
      await _repository.permanentlyDeleteTransaction(id);
      await fetchDeletedTransactions();
      return true;
    } catch (e) {
      debugPrint('Error permanently deleting transaction: $e');
      return false;
    }
  }

  /// حذف عملية لحساب (سلة المحذوفات أو حذف نهائي)
  Future<bool> deleteTransaction(int id, int accountId,
      {bool? forcePermanent}) async {
    try {
      await _repository.deleteTransaction(id, forcePermanent: forcePermanent);
      _allTransactions =
          await _repository.getTransactionsByAccountId(accountId);
      await fetchAllBalancesSummary();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting transaction: $e');
      return false;
    }
  }

  /// حذف عملية لمحطة (سلة المحذوفات أو حذف نهائي)
  Future<bool> deleteStationTransaction(int id, int stationId,
      {bool? forcePermanent}) async {
    try {
      await _repository.deleteTransaction(id, forcePermanent: forcePermanent);
      _allTransactions =
          await _repository.getTransactionsByStationId(stationId);
      await fetchAllBalancesSummary();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting station transaction: $e');
      return false;
    }
  }
}
