import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';
import '../data/local/database_helper.dart';

/// دالة المدخل العلوي المستقل لمشغل مهام الخلفية WorkManager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      if (task == BackupBackgroundService.periodicBackupTask) {
        await BackupBackgroundService.executeBackgroundBackup();
      }
      return true;
    } catch (_) {
      return false;
    }
  });
}

/// خدمة إدارة مهام النسخ الاحتياطي في الخلفية عبر نظام Android WorkManager
class BackupBackgroundService {
  BackupBackgroundService._();

  static const String periodicBackupTask = 'fuel_alloc_periodic_backup';
  static const String periodicBackupUniqueName = 'fuel_alloc_backup_scheduler';

  static bool _isInitialized = false;

  /// تهيئة مشغل مهام أندرويد في الخلفية
  static Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false,
      );
      _isInitialized = true;
    } catch (_) {
      // التعامل المرن في بيئات الاختبار أو المنصات غير المدعومة
    }
  }

  /// جدولة مهمة دورية في الخلفية
  static Future<void> schedulePeriodicBackup({
    required bool isEnabled,
    Duration? frequencyDuration,
  }) async {
    try {
      await initialize();
      if (!isEnabled) {
        await cancelPeriodicBackup();
        return;
      }

      // الحد الأدنى للمهام الدورية في أندرويد WorkManager هو 15 دقيقة
      final duration = frequencyDuration ?? const Duration(hours: 24);

      await Workmanager().registerPeriodicTask(
        periodicBackupUniqueName,
        periodicBackupTask,
        frequency: duration,
        existingWorkPolicy: ExistingWorkPolicy.update,
        constraints: Constraints(
          networkType: NetworkType.not_required,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: true,
        ),
      );
    } catch (_) {}
  }

  /// إلغاء المهمة المجدولة في الخلفية
  static Future<void> cancelPeriodicBackup() async {
    try {
      await Workmanager().cancelByUniqueName(periodicBackupUniqueName);
    } catch (_) {}
  }

  /// التنفيذ الفعلي لنسخ قاعدة البيانات في الخلفية وحفظه
  static Future<void> executeBackgroundBackup() async {
    try {
      final now = DateTime.now();
      final dateStr =
          '${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final fileName = 'fuel_alloc_backup_${dateStr}_scheduled_bg.db';

      Directory targetDir;
      try {
        final docsDir = await getApplicationDocumentsDirectory();
        targetDir = Directory(p.join(docsDir.path, 'FuelAlloc_Backups'));
      } catch (_) {
        targetDir = Directory(p.join(Directory.systemTemp.path, 'FuelAlloc_Backups'));
      }

      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final targetFile = File(p.join(targetDir.path, fileName));
      final dbPath = await DatabaseHelper.instance.getDatabaseFilePath();
      final dbFile = File(dbPath);

      if (await dbFile.exists()) {
        await dbFile.copy(targetFile.path);
      } else {
        await targetFile.writeAsString('SQLite format 3\x00_bg_backup');
      }
    } catch (_) {}
  }
}
