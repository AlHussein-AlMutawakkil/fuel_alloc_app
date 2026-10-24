import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../data/local/database_helper.dart';
import '../models/personal_info_model.dart';

/// متحكم إدارة البيانات الشخصية وهوية المنشأة
class PersonalInfoController extends ChangeNotifier {
  PersonalInfoModel _info = const PersonalInfoModel();
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  PersonalInfoModel get info => _info;
  bool get isLoading => _isLoading;

  PersonalInfoController() {
    loadPersonalInfo();
  }

  /// تحميل البيانات الشخصية من قاعدة البيانات
  Future<void> loadPersonalInfo() async {
    _isLoading = true;
    notifyListeners();
    try {
      _info = await DatabaseHelper.instance.getPersonalInfo();
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  /// حفظ نسخة من الملف المختار في مجلد المستندات الدائم للتطبيق
  Future<String?> _copyToPermanentStorage(XFile file, String prefix) async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final assetsDir = Directory(p.join(docDir.path, 'personal_assets'));
      if (!await assetsDir.exists()) {
        await assetsDir.create(recursive: true);
      }
      final extension = p.extension(file.path).isEmpty ? '.png' : p.extension(file.path);
      final fileName = '${prefix}_${DateTime.now().millisecondsSinceEpoch}$extension';
      final targetPath = p.join(assetsDir.path, fileName);
      final savedFile = await File(file.path).copy(targetPath);
      return savedFile.path;
    } catch (_) {
      return null;
    }
  }

  /// اختيار الشعار من المعرض أو الكاميرا
  Future<bool> pickLogo(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source);
      if (picked != null) {
        final path = await _copyToPermanentStorage(picked, 'logo');
        if (path != null) {
          _info = _info.copyWith(logoPath: path);
          await DatabaseHelper.instance.savePersonalInfo(_info);
          notifyListeners();
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  /// حذف الشعار
  Future<void> removeLogo() async {
    _info = _info.copyWith(clearLogoPath: true);
    await DatabaseHelper.instance.savePersonalInfo(_info);
    notifyListeners();
  }

  /// اختيار الختم من المعرض أو الكاميرا
  Future<bool> pickStamp(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source);
      if (picked != null) {
        final path = await _copyToPermanentStorage(picked, 'stamp');
        if (path != null) {
          _info = _info.copyWith(stampPath: path);
          await DatabaseHelper.instance.savePersonalInfo(_info);
          notifyListeners();
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  /// حذف الختم
  Future<void> removeStamp() async {
    _info = _info.copyWith(clearStampPath: true);
    await DatabaseHelper.instance.savePersonalInfo(_info);
    notifyListeners();
  }

  /// اختيار التوقيع من المعرض أو الكاميرا
  Future<bool> pickSignature(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source);
      if (picked != null) {
        final path = await _copyToPermanentStorage(picked, 'signature');
        if (path != null) {
          _info = _info.copyWith(signaturePath: path);
          await DatabaseHelper.instance.savePersonalInfo(_info);
          notifyListeners();
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  /// حذف التوقيع
  Future<void> removeSignature() async {
    _info = _info.copyWith(clearSignaturePath: true);
    await DatabaseHelper.instance.savePersonalInfo(_info);
    notifyListeners();
  }

  /// تحديث نسبة حجم الشعار
  Future<void> setLogoScale(int percent) async {
    final clamped = percent.clamp(10, 200);
    _info = _info.copyWith(logoScalePercent: clamped);
    await DatabaseHelper.instance.savePersonalInfo(_info);
    notifyListeners();
  }

  /// تحديث نسبة حجم الختم
  Future<void> setStampScale(int percent) async {
    final clamped = percent.clamp(10, 200);
    _info = _info.copyWith(stampScalePercent: clamped);
    await DatabaseHelper.instance.savePersonalInfo(_info);
    notifyListeners();
  }

  /// تحديث نسبة حجم التوقيع
  Future<void> setSignatureScale(int percent) async {
    final clamped = percent.clamp(10, 200);
    _info = _info.copyWith(signatureScalePercent: clamped);
    await DatabaseHelper.instance.savePersonalInfo(_info);
    notifyListeners();
  }

  /// تبديل إعداد تضمين البيانات الشخصية في النسخ الاحتياطي
  Future<void> toggleIncludeInBackup(bool include) async {
    _info = _info.copyWith(includeInBackup: include);
    await DatabaseHelper.instance.savePersonalInfo(_info);
    notifyListeners();
  }

  /// حفظ البيانات الشخصية النصية والكاملة
  Future<void> saveGeneralInfo({
    required String arabicName,
    required String englishName,
    required String arabicAddress,
    required String englishAddress,
    required String contactNumbers,
  }) async {
    _info = _info.copyWith(
      arabicName: arabicName.trim(),
      englishName: englishName.trim(),
      arabicAddress: arabicAddress.trim(),
      englishAddress: englishAddress.trim(),
      contactNumbers: contactNumbers.trim(),
    );
    await DatabaseHelper.instance.savePersonalInfo(_info);
    notifyListeners();
  }
}
