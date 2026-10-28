import 'package:flutter/foundation.dart';
import '../data/repositories/account_repository.dart';
import '../data/repositories/report_repository.dart';
import '../data/repositories/transaction_repository.dart';
import '../models/account_model.dart';
import '../models/personal_info_model.dart';
import '../models/reconciliation_item_model.dart';
import '../models/statement_item_model.dart';
import '../models/station_model.dart';
import '../services/pdf_report_service.dart';

/// متحكم إدارة تقارير ومطابقات النظام
class ReportsController extends ChangeNotifier {
  final ReportRepository _reportRepository = ReportRepository();
  final AccountRepository _accountRepository = AccountRepository();
  final TransactionRepository _txRepository = TransactionRepository();

  // 1. تبويب التصنيف النشط في الشاشة الرئيسية
  int _selectedCategoryIndex = 0; // 0: كشوفات, 1: مطابقة, 2: حركة, 3: إحصائيات

  // 2. حالة كشف الحساب
  AccountModel? _selectedAccount;
  StationModel? _selectedStation;
  int? _statementFuelTypeId;
  DateTime? _statementFromDate;
  DateTime? _statementToDate;
  String _statementFilter = 'ALL';
  List<StatementItemModel> _statementItems = [];
  bool _isStatementLoading = false;

  // 3. حالة المطابقة
  int? _reconciliationFuelTypeId;
  String _reconciliationSearch = '';
  ReconciliationStatus? _reconciliationStatusFilter;
  List<ReconciliationItemModel> _reconciliationItems = [];
  bool _isReconciliationLoading = false;

  // 4. القوائم المرجعية
  List<AccountModel> _allAccounts = [];
  List<StationModel> _allStations = [];
  List<Map<String, dynamic>> _fuelTypes = [];

  // Getters
  int get selectedCategoryIndex => _selectedCategoryIndex;
  AccountModel? get selectedAccount => _selectedAccount;
  StationModel? get selectedStation => _selectedStation;
  int? get statementFuelTypeId => _statementFuelTypeId;
  DateTime? get statementFromDate => _statementFromDate;
  DateTime? get statementToDate => _statementToDate;
  String get statementFilter => _statementFilter;
  List<StatementItemModel> get statementItems => List.unmodifiable(_statementItems);
  bool get isStatementLoading => _isStatementLoading;

  int? get reconciliationFuelTypeId => _reconciliationFuelTypeId;
  String get reconciliationSearch => _reconciliationSearch;
  ReconciliationStatus? get reconciliationStatusFilter => _reconciliationStatusFilter;
  List<ReconciliationItemModel> get reconciliationItems => List.unmodifiable(_reconciliationItems);
  bool get isReconciliationLoading => _isReconciliationLoading;

  List<AccountModel> get allAccounts => _allAccounts;
  List<StationModel> get allStations => _allStations;
  List<Map<String, dynamic>> get fuelTypes => _fuelTypes;

  List<AccountModel> get suppliers =>
      _allAccounts.where((a) => a.accountType == AccountType.supplier).toList();

  List<AccountModel> get beneficiaries =>
      _allAccounts.where((a) => a.accountType == AccountType.beneficiary).toList();

  void setCategoryIndex(int index) {
    if (_selectedCategoryIndex != index) {
      _selectedCategoryIndex = index;
      notifyListeners();
    }
  }

  /// تحميل البيانات المرجعية الأساسية
  Future<void> initializeData() async {
    try {
      final futures = await Future.wait([
        _accountRepository.getAllAccounts(),
        _accountRepository.getStations(),
        _txRepository.getFuelTypes(),
      ]);

      _allAccounts = futures[0] as List<AccountModel>;
      final stList = futures[1] as List<AccountModel>;
      _allStations = stList.map((a) => StationModel.fromAccountModel(a)).toList();
      _fuelTypes = futures[2] as List<Map<String, dynamic>>;

      if (_fuelTypes.isNotEmpty && _statementFuelTypeId == null) {
        _statementFuelTypeId = _fuelTypes.first['id'] as int;
      }
      if (_fuelTypes.isNotEmpty && _reconciliationFuelTypeId == null) {
        _reconciliationFuelTypeId = _fuelTypes.first['id'] as int;
      }
    } catch (e) {
      debugPrint('Error initializing reports data: $e$e');
    }

    notifyListeners();
  }

  // --- دوال وإجراءات كشف الحساب ---

  void setSelectedAccount(AccountModel? account) {
    _selectedAccount = account;
    _selectedStation = null;
    notifyListeners();
    if (account != null) {
      fetchStatement();
    }
  }

  void setSelectedStation(StationModel? station) {
    _selectedStation = station;
    _selectedAccount = null;
    notifyListeners();
    if (station != null) {
      fetchStatement();
    }
  }

  void setStatementFuelTypeId(int? fuelTypeId) {
    _statementFuelTypeId = fuelTypeId;
    notifyListeners();
    fetchStatement();
  }

  void setStatementDateRange(DateTime? from, DateTime? to) {
    _statementFromDate = from;
    _statementToDate = to;
    notifyListeners();
    fetchStatement();
  }

  void setStatementFilter(String filter) {
    _statementFilter = filter;
    notifyListeners();
    fetchStatement();
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  /// جلب بنود كشف الحساب الحالي
  Future<void> fetchStatement() async {
    if (_selectedAccount == null && _selectedStation == null) {
      _statementItems = [];
      notifyListeners();
      return;
    }

    _isStatementLoading = true;
    notifyListeners();

    try {
      final fromStr = _formatDate(_statementFromDate);
      final toStr = _formatDate(_statementToDate);

      if (_selectedStation != null) {
        _statementItems = await _reportRepository.getStationStatement(
          stationId: _selectedStation!.id!,
          fuelTypeId: _statementFuelTypeId,
          fromDate: fromStr,
          toDate: toStr,
          filterType: _statementFilter,
        );
      } else if (_selectedAccount != null) {
        final isSupplier = _selectedAccount!.accountType == AccountType.supplier;
        _statementItems = await _reportRepository.getAccountStatement(
          accountId: _selectedAccount!.id!,
          isSupplier: isSupplier,
          fuelTypeId: _statementFuelTypeId,
          fromDate: fromStr,
          toDate: toStr,
          filterType: _statementFilter,
        );
      }
    } catch (_) {
      _statementItems = [];
    } finally {
      _isStatementLoading = false;
      notifyListeners();
    }
  }

  // --- دوال وإجراءات تقارير المطابقة ---

  void setReconciliationFuelTypeId(int? fuelTypeId) {
    _reconciliationFuelTypeId = fuelTypeId;
    notifyListeners();
  }

  void setReconciliationSearch(String query) {
    _reconciliationSearch = query;
    notifyListeners();
  }

  void setReconciliationStatusFilter(ReconciliationStatus? status) {
    _reconciliationStatusFilter = status;
    notifyListeners();
  }

  Future<void> fetchSupplierReconciliation() async {
    _isReconciliationLoading = true;
    notifyListeners();
    try {
      _reconciliationItems = await _reportRepository.getSupplierReconciliation(
        fuelTypeId: _reconciliationFuelTypeId,
        searchQuery: _reconciliationSearch,
        statusFilter: _reconciliationStatusFilter,
      );
    } catch (_) {
      _reconciliationItems = [];
    } finally {
      _isReconciliationLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchStationReconciliation() async {
    _isReconciliationLoading = true;
    notifyListeners();
    try {
      _reconciliationItems = await _reportRepository.getStationReconciliation(
        fuelTypeId: _reconciliationFuelTypeId,
        searchQuery: _reconciliationSearch,
        statusFilter: _reconciliationStatusFilter,
      );
    } catch (_) {
      _reconciliationItems = [];
    } finally {
      _isReconciliationLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchBeneficiaryReconciliation() async {
    _isReconciliationLoading = true;
    notifyListeners();
    try {
      _reconciliationItems = await _reportRepository.getBeneficiaryReconciliation(
        fuelTypeId: _reconciliationFuelTypeId,
        searchQuery: _reconciliationSearch,
        statusFilter: _reconciliationStatusFilter,
      );
    } catch (_) {
      _reconciliationItems = [];
    } finally {
      _isReconciliationLoading = false;
      notifyListeners();
    }
  }

  // --- طباعة ومشاركة التقارير ---

  Future<void> printStatement({
    required PersonalInfoModel personalInfo,
    required String title,
  }) async {
    final accountName = _selectedStation?.name ?? _selectedAccount?.name ?? '';
    final accountPhone = _selectedStation?.phoneNumber ?? _selectedAccount?.phoneNumber;
    final location = _selectedStation?.location;

    String fuelName = 'الكل';
    if (_statementFuelTypeId != null) {
      final match = _fuelTypes.firstWhere(
        (f) => f['id'] == _statementFuelTypeId,
        orElse: () => {'name': ''},
      );
      if (match['name'] != null && match['name'].isNotEmpty) {
        fuelName = match['name'];
      }
    }

    String periodText = 'كامل السجل';
    if (_statementFromDate != null && _statementToDate != null) {
      periodText = 'من ${_formatDate(_statementFromDate)} إلى ${_formatDate(_statementToDate)}';
    } else if (_statementFromDate != null) {
      periodText = 'من ${_formatDate(_statementFromDate)}';
    } else if (_statementToDate != null) {
      periodText = 'حتى ${_formatDate(_statementToDate)}';
    }

    double totalIn = 0.0;
    double totalOut = 0.0;
    for (final it in _statementItems) {
      totalIn += it.inflow;
      totalOut += it.outflow;
    }
    final latestBalance = _statementItems.isNotEmpty ? _statementItems.first.runningBalance : 0.0;

    final bytes = await PdfReportService.generateStatementPdf(
      reportTitle: title,
      accountName: accountName,
      accountPhone: accountPhone,
      location: location,
      periodText: periodText,
      fuelTypeName: fuelName,
      items: _statementItems,
      personalInfo: personalInfo,
      totalInflow: totalIn,
      totalOutflow: totalOut,
      currentBalance: latestBalance,
    );

    await PdfReportService.printDocument(
      pdfBytes: bytes,
      documentName: '${title}_$accountName',
    );
  }

  Future<void> shareStatement({
    required PersonalInfoModel personalInfo,
    required String title,
  }) async {
    final accountName = _selectedStation?.name ?? _selectedAccount?.name ?? '';
    final accountPhone = _selectedStation?.phoneNumber ?? _selectedAccount?.phoneNumber;
    final location = _selectedStation?.location;

    String fuelName = 'الكل';
    if (_statementFuelTypeId != null) {
      final match = _fuelTypes.firstWhere(
        (f) => f['id'] == _statementFuelTypeId,
        orElse: () => {'name': ''},
      );
      if (match['name'] != null && match['name'].isNotEmpty) {
        fuelName = match['name'];
      }
    }

    String periodText = 'كامل السجل';
    if (_statementFromDate != null && _statementToDate != null) {
      periodText = 'من ${_formatDate(_statementFromDate)} إلى ${_formatDate(_statementToDate)}';
    } else if (_statementFromDate != null) {
      periodText = 'من ${_formatDate(_statementFromDate)}';
    } else if (_statementToDate != null) {
      periodText = 'حتى ${_formatDate(_statementToDate)}';
    }

    double totalIn = 0.0;
    double totalOut = 0.0;
    for (final it in _statementItems) {
      totalIn += it.inflow;
      totalOut += it.outflow;
    }
    final latestBalance = _statementItems.isNotEmpty ? _statementItems.first.runningBalance : 0.0;

    final bytes = await PdfReportService.generateStatementPdf(
      reportTitle: title,
      accountName: accountName,
      accountPhone: accountPhone,
      location: location,
      periodText: periodText,
      fuelTypeName: fuelName,
      items: _statementItems,
      personalInfo: personalInfo,
      totalInflow: totalIn,
      totalOutflow: totalOut,
      currentBalance: latestBalance,
    );

    await PdfReportService.shareDocument(
      pdfBytes: bytes,
      fileName: 'كشف_حساب_$accountName',
    );
  }

  Future<void> printReconciliation({
    required PersonalInfoModel personalInfo,
    required String title,
  }) async {
    String fuelName = 'الكل';
    if (_reconciliationFuelTypeId != null) {
      final match = _fuelTypes.firstWhere(
        (f) => f['id'] == _reconciliationFuelTypeId,
        orElse: () => {'name': ''},
      );
      if (match['name'] != null && match['name'].isNotEmpty) {
        fuelName = match['name'];
      }
    }

    final bytes = await PdfReportService.generateReconciliationPdf(
      reportTitle: title,
      fuelTypeName: fuelName,
      items: _reconciliationItems,
      personalInfo: personalInfo,
    );

    await PdfReportService.printDocument(
      pdfBytes: bytes,
      documentName: title,
    );
  }
}

