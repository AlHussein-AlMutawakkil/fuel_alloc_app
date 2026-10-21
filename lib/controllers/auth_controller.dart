import 'package:flutter/foundation.dart';
import '../core/constants/app_strings.dart';
import '../services/google_drive_service.dart';

/// متحكم حالة تسجيل الدخول وبيانات حساب المستخدم الفعلي (Auth & User Profile Controller)
class AuthController extends ChangeNotifier {
  final GoogleDriveService _driveService = GoogleDriveService.instance;
  bool _manualOverride = false;
  String? _manualUserName;
  String? _manualEmail;
  String? _manualPhotoUrl;

  AuthController() {
    _driveService.addListener(_onDriveAuthChanged);
    _initAuth();
  }

  void _onDriveAuthChanged() {
    notifyListeners();
  }

  Future<void> _initAuth() async {
    await _driveService.initSilentSignIn();
  }

  bool get isLoggedIn {
    if (_manualOverride) return true;
    return _driveService.isSignedIn;
  }

  String? get userName {
    if (_manualOverride) return _manualUserName;
    return _driveService.currentUser?.displayName;
  }

  String? get email {
    if (_manualOverride) return _manualEmail;
    return _driveService.currentUser?.email;
  }

  String? get photoUrl {
    if (_manualOverride) return _manualPhotoUrl;
    return _driveService.currentUser?.photoUrl;
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
    await _driveService.signOut();
    notifyListeners();
  }

  /// تبديل الحساب
  Future<bool> switchAccount() async {
    await _driveService.signOut();
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
