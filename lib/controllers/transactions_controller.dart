import 'package:flutter/foundation.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../models/transaction_model.dart';

/// متحكم إدارة العمليات والقيود المحاسبية
class TransactionsController extends ChangeNotifier {
  final TransactionRepository _repository = TransactionRepository();

  List<TransactionModel> _allTransactions = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedFilter = 'ALL'; // ALL, QUOTA, ACTUAL

  List<Map<String, dynamic>> _stations = [];
  List<Map<String, dynamic>> _fuelTypes = [];
  List<Map<String, dynamic>> _units = [];
  List<Map<String, dynamic>> _transactionTypes = [];

  // Getters
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedFilter => _selectedFilter;

  List<Map<String, dynamic>> get stations => _stations;
  List<Map<String, dynamic>> get fuelTypes => _fuelTypes;
  List<Map<String, dynamic>> get units => _units;
  List<Map<String, dynamic>> get transactionTypes => _transactionTypes;

  /// قائمة العمليات المفلترة
  List<TransactionModel> get transactions {
    return _allTransactions.where((tx) {
      // فلترة بالنوع
      bool matchesFilter = true;
      if (_selectedFilter == 'QUOTA') {
        matchesFilter = tx.isQuota;
      } else if (_selectedFilter == 'ACTUAL') {
        matchesFilter = tx.isActual;
      }

      // فلترة بالبحث
      bool matchesSearch = true;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        matchesSearch = (tx.notes?.toLowerCase().contains(q) ?? false) ||
            (tx.stationName?.toLowerCase().contains(q) ?? false) ||
            (tx.referenceStationName?.toLowerCase().contains(q) ?? false) ||
            (tx.fuelTypeName?.toLowerCase().contains(q) ?? false) ||
            (tx.typeName?.toLowerCase().contains(q) ?? false) ||
            tx.transactionDate.contains(q);
      }

      return matchesFilter && matchesSearch;
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

  /// رصيد محطة معينة حالياً
  Future<double> getStationBalance(int stationId) async {
    return await _repository.getStationBalance(stationId);
  }

  /// رصيد حساب معين حالياً
  Future<double> getAccountBalance(int accountId, bool isSupplier) async {
    return await _repository.getAccountBalance(accountId, isSupplier);
  }

  /// جلب عمليات حساب معين
  Future<void> fetchAccountTransactions(int accountId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _allTransactions = await _repository.getTransactionsByAccountId(accountId);
      await loadFormData();
    } catch (e) {
      debugPrint('Error fetching account transactions: $e');
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

  /// إضافة عملية لحساب
  Future<bool> addTransaction(TransactionModel tx) async {
    try {
      await _repository.insertTransaction(tx);
      if (tx.accountId != null) {
        _allTransactions = await _repository.getTransactionsByAccountId(tx.accountId!);
      }
      notifyListeners();
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
      if (tx.accountId != null) {
        _allTransactions = await _repository.getTransactionsByAccountId(tx.accountId!);
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating transaction: $e');
      return false;
    }
  }

  /// حذف عملية
  Future<bool> deleteTransaction(int id, int accountId) async {
    try {
      await _repository.deleteTransaction(id);
      _allTransactions = await _repository.getTransactionsByAccountId(accountId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting transaction: $e');
      return false;
    }
  }
}
