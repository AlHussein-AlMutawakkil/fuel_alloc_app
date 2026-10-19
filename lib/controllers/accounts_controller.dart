import 'package:flutter/foundation.dart';
import '../../data/repositories/account_repository.dart';
import '../../models/account_model.dart';

/// متحكم إدارة الحسابات (MVC Controller مع Provider)
class AccountsController extends ChangeNotifier {
  final AccountRepository _repository = AccountRepository();

  List<AccountModel> _allAccounts = [];
  bool _isLoading = false;
  String _searchQuery = '';
  AccountType? _selectedTypeFilter; // null يعني الكل

  List<AccountModel> get accounts {
    return _allAccounts.where((account) {
      // فلترة حسب النوع
      final matchesType = _selectedTypeFilter == null ||
          account.accountType == _selectedTypeFilter;

      // فلترة حسب البحث
      final matchesSearch = _searchQuery.isEmpty ||
          account.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (account.phoneNumber?.contains(_searchQuery) ?? false);

      return matchesType && matchesSearch;
    }).toList();
  }

  /// جلب كافة الحسابات النشطة بدون فلتر التبويب (لأجل نوافذ الإدخال والبحث الذكي)
  List<AccountModel> get allAccounts => List.unmodifiable(_allAccounts);

  bool get isLoading => _isLoading;
  AccountType? get selectedTypeFilter => _selectedTypeFilter;
  String get searchQuery => _searchQuery;

  // جلب الحسابات
  Future<void> fetchAccounts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allAccounts = await _repository.getAllAccounts();
    } catch (e) {
      debugPrint('Error fetching accounts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // تغيير فلتر نوع الحساب
  void setTypeFilter(AccountType? type) {
    _selectedTypeFilter = type;
    notifyListeners();
  }

  // تغيير نص البحث
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // إضافة حساب جديد
  Future<bool> addAccount(String name, AccountType type, String? phone) async {
    try {
      final newAccount = AccountModel(
        name: name.trim(),
        accountType: type,
        phoneNumber: phone?.trim().isEmpty == true ? null : phone?.trim(),
      );
      await _repository.insertAccount(newAccount);
      await fetchAccounts();
      return true;
    } catch (e) {
      debugPrint('Error adding account: $e');
      return false;
    }
  }

  // تعديل حساب
  Future<bool> updateAccount(AccountModel account) async {
    try {
      await _repository.updateAccount(account);
      await fetchAccounts();
      return true;
    } catch (e) {
      debugPrint('Error updating account: $e');
      return false;
    }
  }

  // حذف حساب (نقل لسلة المحذوفات أو حذف نهائي)
  Future<bool> deleteAccount(int id, {bool? forcePermanent}) async {
    try {
      await _repository.deleteAccount(id, forcePermanent: forcePermanent);
      await fetchAccounts();
      return true;
    } catch (e) {
      debugPrint('Error deleting account: $e');
      return false;
    }
  }

  List<AccountModel> _archivedAccounts = [];
  List<AccountModel> get archivedAccounts => _archivedAccounts;

  List<AccountModel> _deletedAccounts = [];
  List<AccountModel> get deletedAccounts => _deletedAccounts;

  /// جلب الحسابات المؤرشفة
  Future<void> fetchArchivedAccounts() async {
    _isLoading = true;
    notifyListeners();
    try {
      _archivedAccounts = await _repository.getArchivedAccounts();
    } catch (e) {
      debugPrint('Error fetching archived accounts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// جلب الحسابات المحذوفة
  Future<void> fetchDeletedAccounts() async {
    _isLoading = true;
    notifyListeners();
    try {
      _deletedAccounts = await _repository.getDeletedAccounts();
    } catch (e) {
      debugPrint('Error fetching deleted accounts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// أرشفة حساب
  Future<bool> archiveAccount(int id) async {
    try {
      await _repository.archiveAccount(id);
      await fetchAccounts();
      await fetchArchivedAccounts();
      return true;
    } catch (e) {
      debugPrint('Error archiving account: $e');
      return false;
    }
  }

  /// إلغاء أرشفة حساب
  Future<bool> unarchiveAccount(int id) async {
    try {
      await _repository.unarchiveAccount(id);
      await fetchAccounts();
      await fetchArchivedAccounts();
      return true;
    } catch (e) {
      debugPrint('Error unarchiving account: $e');
      return false;
    }
  }

  /// استعادة حساب من سلة المحذوفات
  Future<bool> restoreAccount(int id) async {
    try {
      await _repository.restoreAccount(id);
      await fetchAccounts();
      await fetchDeletedAccounts();
      return true;
    } catch (e) {
      debugPrint('Error restoring account: $e');
      return false;
    }
  }

  /// حذف حساب نهائياً من قاعدة البيانات
  Future<bool> permanentlyDeleteAccount(int id) async {
    try {
      await _repository.permanentlyDeleteAccount(id);
      await fetchDeletedAccounts();
      return true;
    } catch (e) {
      debugPrint('Error permanently deleting account: $e');
      return false;
    }
  }
}
