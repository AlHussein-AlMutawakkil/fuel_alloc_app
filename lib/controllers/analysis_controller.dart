import 'package:flutter/foundation.dart';
import '../data/repositories/analysis_repository.dart';

/// متحكم إدارة وتحليل وفحص صحة التطبيق والبيانات
class AnalysisController extends ChangeNotifier {
  final AnalysisRepository _repository;

  AnalysisData? _data;
  bool _isLoading = false;
  bool _isRunningDiagnostics = false;
  String? _lastDiagnosticsMessage;
  DateTime? _lastAnalyzedAt;

  // Getters
  AnalysisData? get data => _data;
  bool get isLoading => _isLoading;
  bool get isRunningDiagnostics => _isRunningDiagnostics;
  String? get lastDiagnosticsMessage => _lastDiagnosticsMessage;
  DateTime? get lastAnalyzedAt => _lastAnalyzedAt;

  // فحص ما إذا كان النظام سليماً تماماً
  bool get isSystemHealthy =>
      _data != null &&
      _data!.isDatabaseIntact &&
      _data!.consistencyIssues.isEmpty;

  AnalysisController({
    AnalysisRepository? repository,
    AnalysisData? initialData,
  })  : _repository = repository ?? AnalysisRepository(),
        _data = initialData {
    if (_data == null) {
      loadAnalysisData();
    }
  }

  /// جلب وتحديث كافة بيانات التحليل
  Future<void> loadAnalysisData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _data = await _repository.fetchFullAnalysis();
      _lastAnalyzedAt = DateTime.now();
    } catch (e) {
      debugPrint('Error loading analysis data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// تشغيل فحص شامل وفوري للنظام والبيانات
  Future<void> runFullDiagnostics() async {
    _isRunningDiagnostics = true;
    _lastDiagnosticsMessage = null;
    notifyListeners();

    try {
      // محاكاة تدقيق متعمق للجداول ومطابقة القيود
      await Future.delayed(const Duration(milliseconds: 500));
      _data = await _repository.fetchFullAnalysis();
      _lastAnalyzedAt = DateTime.now();

      if (isSystemHealthy) {
        _lastDiagnosticsMessage =
            'اكتمل الفحص: قاعدة البيانات والقيود متطابقة وسليمة 100%';
      } else {
        _lastDiagnosticsMessage =
            'تم رصد بعض الملاحظات تحتاج إلى تدقيق في القيود أو الحسابات.';
      }
    } catch (e) {
      _lastDiagnosticsMessage = 'حدث خطأ أثناء فحص النظام: $e';
    } finally {
      _isRunningDiagnostics = false;
      notifyListeners();
    }
  }
}
