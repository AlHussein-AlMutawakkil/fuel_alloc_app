import 'package:flutter/material.dart';
import '../core/constants/app_strings.dart';
import '../models/backup_model.dart';

/// متحكم إدارة النسخ الاحتياطي والجدولة
class BackupController extends ChangeNotifier {
  // 1. نوع النسخة
  BackupType _backupType = BackupType.full;
  IncrementalFrequency _incrementalFrequency = IncrementalFrequency.days7;
  int _incrementalCustomDays = 7;
  bool _forceFullBackupNextRun = false;

  // 2. الجدولة
  bool _isScheduleEnabled = true;
  ScheduleFrequency _scheduleFrequency = ScheduleFrequency.daily;
  TimeOfDay _dailyTime = const TimeOfDay(hour: 0, minute: 0); // 12:00 ص
  int _dailyRepeatDays = 1;
  bool _disableNotifications = false;

  // 3. المزامنة والنسخ التلقائي
  bool _autoBackupEnabled = false;

  // 4. قائمة النسخ المحفوظة
  final List<BackupModel> _backups = [
    BackupModel(
      id: 'b1',
      fileName: 'fuel_alloc_backup_2026_10_20_full.db',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      sizeBytes: 1845200,
      type: BackupType.full,
      isCloud: false,
    ),
    BackupModel(
      id: 'b2',
      fileName: 'fuel_alloc_backup_2026_10_15_incr.db',
      createdAt: DateTime.now().subtract(const Duration(days: 6, hours: 5)),
      sizeBytes: 524288,
      type: BackupType.incremental,
      isCloud: false,
    ),
    BackupModel(
      id: 'b3',
      fileName: 'fuel_alloc_backup_2026_10_01_arch.db',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      sizeBytes: 1258291,
      type: BackupType.archive,
      isCloud: false,
    ),
    BackupModel(
      id: 'c1',
      fileName: 'gdrive_fuel_alloc_backup_cloud.db',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      sizeBytes: 1845200,
      type: BackupType.full,
      isCloud: true,
    ),
  ];

  // Getters
  BackupType get backupType => _backupType;
  IncrementalFrequency get incrementalFrequency => _incrementalFrequency;
  int get incrementalCustomDays => _incrementalCustomDays;
  bool get forceFullBackupNextRun => _forceFullBackupNextRun;

  bool get isScheduleEnabled => _isScheduleEnabled;
  ScheduleFrequency get scheduleFrequency => _scheduleFrequency;
  TimeOfDay get dailyTime => _dailyTime;
  int get dailyRepeatDays => _dailyRepeatDays;
  bool get disableNotifications => _disableNotifications;

  bool get autoBackupEnabled => _autoBackupEnabled;

  List<BackupModel> get localBackups =>
      _backups.where((b) => !b.isCloud).toList();

  List<BackupModel> get cloudBackups =>
      _backups.where((b) => b.isCloud).toList();

  /// عنوان نوع النسخة الاحتياطية الحالي
  String get backupTypeTitle {
    switch (_backupType) {
      case BackupType.full:
        return AppStrings.backupFullTitle;
      case BackupType.archive:
        return AppStrings.backupArchiveTitle;
      case BackupType.incremental:
        return AppStrings.backupIncrementalTitle;
    }
  }

  /// نص توقيت اليوم بتنسيق مقروء (مثلاً: 12:00 ص)
  String get formattedDailyTime {
    final hour = _dailyTime.hour > 12
        ? _dailyTime.hour - 12
        : (_dailyTime.hour == 0 ? 12 : _dailyTime.hour);
    final minute = _dailyTime.minute.toString().padLeft(2, '0');
    final period = _dailyTime.hour >= 12 ? AppStrings.pmSuffix : AppStrings.amSuffix;
    return '$hour:$minute $period';
  }

  /// ملخص حالة الجدولة للعرض في البطاقة الرئيسية
  String get scheduleStatusSummary {
    if (!_isScheduleEnabled) {
      return AppStrings.scheduleDisabled;
    }
    switch (_scheduleFrequency) {
      case ScheduleFrequency.daily:
        return '${AppStrings.scheduleEnabledDaily} $formattedDailyTime';
      case ScheduleFrequency.weekly:
        return AppStrings.scheduleEnabledWeekly;
      case ScheduleFrequency.hourly:
        return AppStrings.scheduleEnabledHourly;
    }
  }

  // Setters & Actions
  void setBackupType(BackupType type) {
    _backupType = type;
    notifyListeners();
  }

  void setIncrementalOptions({
    IncrementalFrequency? frequency,
    int? customDays,
    bool? forceNext,
  }) {
    if (frequency != null) _incrementalFrequency = frequency;
    if (customDays != null) _incrementalCustomDays = customDays;
    if (forceNext != null) _forceFullBackupNextRun = forceNext;
    notifyListeners();
  }

  void toggleSchedule(bool enabled) {
    _isScheduleEnabled = enabled;
    notifyListeners();
  }

  void setScheduleFrequency(ScheduleFrequency frequency) {
    _scheduleFrequency = frequency;
    notifyListeners();
  }

  void setDailyTime(TimeOfDay time) {
    _dailyTime = time;
    notifyListeners();
  }

  void setDailyRepeatDays(int days) {
    _dailyRepeatDays = days;
    notifyListeners();
  }

  void toggleNotifications(bool disable) {
    _disableNotifications = disable;
    notifyListeners();
  }

  void toggleAutoBackup(bool enabled) {
    _autoBackupEnabled = enabled;
    notifyListeners();
  }

  /// إنشاء نسخة احتياطية محلية جديدة وحفظها في السجل
  BackupModel createLocalBackup() {
    final now = DateTime.now();
    final typeName = _backupType == BackupType.full
        ? 'full'
        : (_backupType == BackupType.archive ? 'arch' : 'incr');
    final fileName =
        'fuel_alloc_backup_${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}_$typeName.db';

    final newBackup = BackupModel(
      id: 'local_${now.millisecondsSinceEpoch}',
      fileName: fileName,
      createdAt: now,
      sizeBytes: 1920000,
      type: _backupType,
      isCloud: false,
    );

    _backups.insert(0, newBackup);
    notifyListeners();
    return newBackup;
  }

  /// حذف نسخة
  void deleteBackup(String id) {
    _backups.removeWhere((b) => b.id == id);
    notifyListeners();
  }
}
