import 'package:flutter/foundation.dart';
import '../core/constants/app_strings.dart';
import '../data/local/database_helper.dart';
import '../services/google_drive_service.dart';

/// متحكم حالة تسجيل الدخول وبيانات حساب المستخدم الفعلي (Auth & User Profile Controller)
class AuthController extends ChangeNotifier {
  final GoogleDriveService _driveService = GoogleDriveService.instance;
  bool _manualOverride = false;
  String? _manualUserName;
  String? _manualEmail;
  String? _manualPhotoUrl;

  // الحفظ المؤقت المحلي للبيانات لظهور فوري دون وميض أو تأخير
  String? _cachedUserName;
  String? _cachedEmail;
  String? _cachedPhotoUrl;
  bool _cachedIsLoggedIn = false;

  AuthController() {
    _driveService.addListener(_onDriveAuthChanged);
    _initAuth();
  }

  void _onDriveAuthChanged() {
    if (_driveService.isSignedIn) {
      _cachedIsLoggedIn = true;
      _cachedUserName = _driveService.currentUser?.displayName;
      _cachedEmail = _driveService.currentUser?.email;
      _cachedPhotoUrl = _driveService.currentUser?.photoUrl;
      _saveProfileLocally();
    }
    notifyListeners();
  }

  Future<void> _initAuth() async {
    // 1. استرجاع البيانات المحفوظة محلياً فوراً لمنع الوميض وظهور "غير مسجل"
    try {
      final db = DatabaseHelper.instance;
      final savedLogin = await db.getSetting('auth_is_logged_in');
      if (savedLogin == 'true') {
        _cachedIsLoggedIn = true;
        _cachedUserName = await db.getSetting('auth_user_name');
        _cachedEmail = await db.getSetting('auth_user_email');
        _cachedPhotoUrl = await db.getSetting('auth_photo_url');
        notifyListeners();
      }
    } catch (_) {}

    // 2. الفحص الصامت مع Google Drive والتحديث في الخلفية دون هز الواجهة
    try {
      final account = await _driveService.initSilentSignIn();
      if (account != null) {
        _cachedIsLoggedIn = true;
        _cachedUserName = account.displayName;
        _cachedEmail = account.email;
        _cachedPhotoUrl = account.photoUrl;
        await _saveProfileLocally();
      } else if (!_manualOverride) {
        if (!_driveService.isSignedIn && _cachedIsLoggedIn) {
          // في حال عدم توفر اتصال بالشبكة، نحتفظ بالبيانات المحلية ولا نقوم بتسجيل الخروج
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveProfileLocally() async {
    try {
      final db = DatabaseHelper.instance;
      await db.setSetting('auth_is_logged_in', _cachedIsLoggedIn ? 'true' : 'false');
      if (_cachedUserName != null) await db.setSetting('auth_user_name', _cachedUserName!);
      if (_cachedEmail != null) await db.setSetting('auth_user_email', _cachedEmail!);
      if (_cachedPhotoUrl != null) await db.setSetting('auth_photo_url', _cachedPhotoUrl!);
    } catch (_) {}
  }

  Future<void> _clearProfileLocally() async {
    try {
      final db = DatabaseHelper.instance;
      await db.setSetting('auth_is_logged_in', 'false');
      await db.setSetting('auth_user_name', '');
      await db.setSetting('auth_user_email', '');
      await db.setSetting('auth_photo_url', '');
    } catch (_) {}
  }

  bool get isLoggedIn {
    if (_manualOverride) return true;
    return _driveService.isSignedIn || _cachedIsLoggedIn;
  }

  String? get userName {
    if (_manualOverride) return _manualUserName;
    return _driveService.currentUser?.displayName ?? _cachedUserName;
  }

  String? get email {
    if (_manualOverride) return _manualEmail;
    return _driveService.currentUser?.email ?? _cachedEmail;
  }

  String? get photoUrl {
    if (_manualOverride) return _manualPhotoUrl;
    return _driveService.currentUser?.photoUrl ?? _cachedPhotoUrl;
  }

  /// عنوان الملف الشخصي:
  /// إذا كان مسجلاً يعرض اسم المستخدم الفعلي من Google، وإذا كان غير مسجل يعرض "غير مسجل"
  String get displayName =>
      isLoggedIn && userName != null && userName!.trim().isNotEmpty
          ? userName!
          : AppStrings.unregisteredUser;

  /// النص الفرعي للملف الشخصي:
  /// إذا كان مسجلاً يُعرض البريد الإلكتروني الفعلي لحساب Google،
  /// وإذا كان غير مسجل يُعرض "تسجيل الدخول / ربط بحساب"
  String get displaySubtitle =>
      isLoggedIn && email != null && email!.trim().isNotEmpty
          ? email!
          : AppStrings.loginOrLinkAccount;

  /// نص قيمة كرت الحساب:
  /// إذا كان مسجلاً يُعرض البريد الإلكتروني، وإذا كان غير مسجل يُعرض "غير مسجل"
  String get accountStatusText =>
      isLoggedIn && email != null && email!.trim().isNotEmpty
          ? email!
          : AppStrings.unlinkedAccount;

  /// تسجيل الدخول الفعلي بحساب Google
  Future<bool> signInWithGoogle() async {
    try {
      final account = await _driveService.signIn();
      _manualOverride = false;
      if (account != null) {
        _cachedIsLoggedIn = true;
        _cachedUserName = account.displayName;
        _cachedEmail = account.email;
        _cachedPhotoUrl = account.photoUrl;
        await _saveProfileLocally();
      }
      notifyListeners();
      return account != null;
    } catch (_) {
      return false;
    }
  }

  /// تسجيل الخروج وفك الارتباط الفعلي بحساب Google
  Future<void> logout() async {
    _manualOverride = false;
    _manualUserName = null;
    _manualEmail = null;
    _manualPhotoUrl = null;
    _cachedIsLoggedIn = false;
    _cachedUserName = null;
    _cachedEmail = null;
    _cachedPhotoUrl = null;
    await _clearProfileLocally();
    await _driveService.signOut();
    notifyListeners();
  }

  /// تبديل الحساب
  Future<bool> switchAccount() async {
    await logout();
    return await signInWithGoogle();
  }

  /// تسجيل الدخول البرمجي (للاختبارات الآلية أو الضبط اليدوي)
  void login({
    required String name,
    required String email,
    String? photoUrl,
  }) {
    _manualOverride = true;
    _manualUserName = name;
    _manualEmail = email;
    _manualPhotoUrl = photoUrl;
    notifyListeners();
  }

  @override
  void dispose() {
    _driveService.removeListener(_onDriveAuthChanged);
    super.dispose();
  }
}
