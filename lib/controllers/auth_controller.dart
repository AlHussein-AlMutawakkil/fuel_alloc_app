import 'package:flutter/foundation.dart';
import '../core/constants/app_strings.dart';

/// متحكم حالة تسجيل الدخول وبيانات حساب المستخدم (Auth & User Profile Controller)
class AuthController extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _userName;
  String? _email;
  String? _photoUrl;

  bool get isLoggedIn => _isLoggedIn;
  String? get userName => _userName;
  String? get email => _email;
  String? get photoUrl => _photoUrl;

  /// عنوان الملف الشخصي:
  /// إذا كان مسجلاً يعرض اسم المستخدم الفعلي، وإذا كان غير مسجل يعرض "غير مسجل"
  String get displayName =>
      _isLoggedIn && _userName != null && _userName!.trim().isNotEmpty
          ? _userName!
          : AppStrings.unregisteredUser;

  /// النص الفرعي للملف الشخصي:
  /// إذا كان مسجلاً يُعرض البريد الإلكتروني بدلاً من "تعديل الملف الشخصي"،
  /// وإذا كان غير مسجل يُعرض "تسجيل الدخول / ربط بحساب"
  String get displaySubtitle =>
      _isLoggedIn && _email != null && _email!.trim().isNotEmpty
          ? _email!
          : AppStrings.loginOrLinkAccount;

  /// نص قيمة كرت الحساب:
  /// إذا كان مسجلاً يُعرض البريد الإلكتروني، وإذا كان غير مسجل يُعرض "غير مسجل"
  String get accountStatusText =>
      _isLoggedIn && _email != null && _email!.trim().isNotEmpty
          ? _email!
          : AppStrings.unlinkedAccount;

  /// تسجيل الدخول أو ربط الحساب
  void login({
    required String name,
    required String email,
    String? photoUrl,
  }) {
    _isLoggedIn = true;
    _userName = name;
    _email = email;
    _photoUrl = photoUrl;
    notifyListeners();
  }

  /// تسجيل الخروج وفك الارتباط
  void logout() {
    _isLoggedIn = false;
    _userName = null;
    _email = null;
    _photoUrl = null;
    notifyListeners();
  }

  /// تسجيل دخول تجريبي لغرض العرض والاختبار السلس
  void simulateDemoLogin({
    String name = AppStrings.profileTitle,
    String email = 'almutawakkil@example.com',
  }) {
    login(name: name, email: email);
  }
}
