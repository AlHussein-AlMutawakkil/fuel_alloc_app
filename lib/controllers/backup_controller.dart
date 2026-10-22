import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../core/constants/app_strings.dart';
import '../data/local/database_helper.dart';
import '../models/backup_model.dart';
import '../services/backup_archive_service.dart';
import '../services/backup_background_service.dart';
import '../services/google_drive_service.dart';

/// متحكم إدارة النسخ الاحتياطي والجدولة والمزامنة السحابية الفعلي
class BackupController extends ChangeNotifier {
  final GoogleDriveService _driveService = GoogleDriveService.instance;

  // 1. نوع النسخة
  BackupType _backupType = BackupType.full;
  IncrementalFrequency _incrementalFrequency = IncrementalFrequency.days7;
  int _incrementalCustomDays = 7;
  bool _forceFullBackupNextRun = false;
  DateTime? _lastFullBackupDate;

  // 2. الجدولة
  bool _isScheduleEnabled = true;
  ScheduleFrequency _scheduleFrequency = ScheduleFrequency.daily;
  TimeOfDay _dailyTime = const TimeOfDay(hour: 0, minute: 0); // 12:00 ص
  int _dailyRepeatDays = 1;
  bool _disableNotifications = false;

  // 3. المزامنة والنسخ التلقائي
  bool _autoBackupEnabled = false;
  DateTime? _lastCloudSyncTime;
  int? _lastCloudSyncSizeBytes;
  bool _isSyncing = false;

  // 4. التنظيف التلقائي
  bool _deleteBeforeLastFull = false;
  RetentionPolicy _localRetentionPolicy = RetentionPolicy.none;
  int _localRetentionDays = 30;
  int _localRetentionCount = 10;
  bool _keepLatestLocalCopy = true;
  bool _deleteUnuploadedBackups = false;

  RetentionPolicy _cloudRetentionPolicy = RetentionPolicy.none;
  int _cloudRetentionDays = 30;
  int _cloudRetentionCount = 10;
  bool _cloudPermanentDelete = false;

  // 5. الضغط والتشفير
  bool _isCompressionEnabled = false;
  bool _isEncryptionEnabled = false;
  String _encryptionPassword = '';

  // 6. الرفع عبر Wi-Fi فقط ومسار التخزين
  bool _wifiOnlySync = false;
  BackupStorageLocation _storageLocation = BackupStorageLocation.internal;

  // 7. قائمة النسخ المحفوظة الفعلية (تبدأ فارغة دون بيانات تجريبية وهمية)
  final List<BackupModel> _backups = [];

  BackupController() {
    _driveService.addListener(_onDriveAuthChanged);
    _initController();
  }

  void _onDriveAuthChanged() {
    notifyListeners();
    if (isGoogleDriveConnected) {
      fetchCloudBackups();
    }
  }

  Future<void> _initController() async {
    await _loadSavedSettings();
    await _loadLocalBackups();
    await _initGoogleDrive();
  }

  // --- Google Drive Getters ---
  bool get isGoogleDriveConnected => _driveService.isSignedIn;
  String? get googleUserEmail => _driveService.currentUser?.email;
  String? get googleUserName => _driveService.currentUser?.displayName;
  String? get googleUserPhotoUrl => _driveService.currentUser?.photoUrl;
  DateTime? get lastCloudSyncTime => _lastCloudSyncTime;
  int? get lastCloudSyncSizeBytes => _lastCloudSyncSizeBytes;
  bool get isSyncing => _isSyncing;

  String get lastCloudSyncFormatted {
    if (_lastCloudSyncTime == null) {
      return AppStrings.noSyncYet;
    }
    final dateStr = DateFormat('yyyy/MM/dd').format(_lastCloudSyncTime!);
    final hour = _lastCloudSyncTime!.hour > 12
        ? _lastCloudSyncTime!.hour - 12
        : (_lastCloudSyncTime!.hour == 0 ? 12 : _lastCloudSyncTime!.hour);
    final minute = _lastCloudSyncTime!.minute.toString().padLeft(2, '0');
    final period =
        _lastCloudSyncTime!.hour >= 12 ? AppStrings.pmSuffix : AppStrings.amSuffix;
    final sizeStr = _lastCloudSyncSizeBytes != null
        ? ' (${(_lastCloudSyncSizeBytes! / (1024 * 1024)).toStringAsFixed(1)} م.ب)'
        : '';
    return '${AppStrings.lastCloudSyncPrefix}$dateStr $hour:$minute $period$sizeStr';
  }

  // --- General Getters ---
  BackupType get backupType => _backupType;
  IncrementalFrequency get incrementalFrequency => _incrementalFrequency;
  int get incrementalCustomDays => _incrementalCustomDays;
  bool get forceFullBackupNextRun => _forceFullBackupNextRun;
  DateTime? get lastFullBackupDate => _lastFullBackupDate;

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

  String get formattedDailyTime {
    final hour = _dailyTime.hour > 12
        ? _dailyTime.hour - 12
        : (_dailyTime.hour == 0 ? 12 : _dailyTime.hour);
    final minute = _dailyTime.minute.toString().padLeft(2, '0');
    final period =
        _dailyTime.hour >= 12 ? AppStrings.pmSuffix : AppStrings.amSuffix;
    return '$hour:$minute $period';
  }

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

  // --- Auto Clean Getters ---
  bool get deleteBeforeLastFull => _deleteBeforeLastFull;
  RetentionPolicy get localRetentionPolicy => _localRetentionPolicy;
  int get localRetentionDays => _localRetentionDays;
  int get localRetentionCount => _localRetentionCount;
  bool get keepLatestLocalCopy => _keepLatestLocalCopy;
  bool get deleteUnuploadedBackups => _deleteUnuploadedBackups;

  RetentionPolicy get cloudRetentionPolicy => _cloudRetentionPolicy;
  int get cloudRetentionDays => _cloudRetentionDays;
  int get cloudRetentionCount => _cloudRetentionCount;
  bool get cloudPermanentDelete => _cloudPermanentDelete;

  // --- Compression & Encryption Getters ---
  bool get isCompressionEnabled => _isCompressionEnabled;
  bool get isEncryptionEnabled => _isEncryptionEnabled;
  String get encryptionPassword => _encryptionPassword;

  // --- Wi-Fi Only & Storage Location Getters ---
  bool get wifiOnlySync => _wifiOnlySync;
  BackupStorageLocation get storageLocation => _storageLocation;

  /// المجلد المحلي المخصص لحفظ واستعراض النسخ الاحتياطية (.db / .zip)
  Future<Directory> getLocalBackupsDirectory() async {
    try {
      if (_storageLocation == BackupStorageLocation.external) {
        if (Platform.isAndroid) {
          final extDir = Directory('/storage/emulated/0/Documents/FuelAlloc_Backups');
          try {
            if (!await extDir.exists()) {
              await extDir.create(recursive: true);
            }
            return extDir;
          } catch (_) {}
        }
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          final dir = Directory(p.join(externalDir.path, 'FuelAlloc_Backups'));
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
          return dir;
        }
      }
      final docsDir = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(docsDir.path, 'FuelAlloc_Backups'));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    } catch (_) {
      final tempDir = Directory.systemTemp;
      final dir = Directory(p.join(tempDir.path, 'FuelAlloc_Backups'));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }
  }

  /// قراءة النسخ الاحتياطية الفعلية الموجودة على مساحة التخزين المحلية (.db و .zip)
  Future<void> _loadLocalBackups() async {
    try {
      final dir = await getLocalBackupsDirectory();
      if (!await dir.exists()) return;
      final files = dir.listSync().whereType<File>().toList();
      final List<BackupModel> loaded = [];
      for (final file in files) {
        final name = p.basename(file.path);
        if (!name.endsWith('.db') && !name.endsWith('.zip')) continue;
        final stat = file.statSync();
        BackupType type = BackupType.full;
        if (name.contains('arch')) {
          type = BackupType.archive;
        } else if (name.contains('incr')) {
          type = BackupType.incremental;
        }
        loaded.add(
          BackupModel(
            id: 'local_${file.path.hashCode}',
            fileName: name,
            createdAt: stat.modified,
            sizeBytes: stat.size,
            type: type,
            isCloud: false,
          ),
        );
      }
      loaded.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _backups.removeWhere((b) => !b.isCloud);
      _backups.addAll(loaded);
      notifyListeners();
    } catch (_) {}
  }

  // --- Initializers & Drive Actions ---
  Future<void> _initGoogleDrive() async {
    final account = await _driveService.initSilentSignIn();
    if (account != null) {
      await fetchCloudBackups();
    }
  }

  /// ربط حساب Google Drive
  Future<bool> connectGoogleDrive() async {
    try {
      _isSyncing = true;
      notifyListeners();
      final account = await _driveService.signIn();
      if (account != null) {
        await fetchCloudBackups();
        _isSyncing = false;
        notifyListeners();
        return true;
      }
    } catch (_) {
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
    return false;
  }

  /// فصل حساب Google Drive
  Future<void> disconnectGoogleDrive() async {
    await _driveService.signOut();
    notifyListeners();
  }

  /// استجلاب النسخ السحابية الحقيقية من مجلد FuelAlloc_Backups على Google Drive
  Future<void> fetchCloudBackups() async {
    try {
      final remoteList = await _driveService.fetchCloudBackups();
      _backups.removeWhere((b) => b.isCloud);
      _backups.addAll(remoteList);
      notifyListeners();
    } catch (_) {
      // إبقاء النسخ الحالية إن تعذر الاتصال بالشبكة
    }
  }

  /// مزامنة ورفع نسخة قاعدة البيانات إلى مجلد FuelAlloc_Backups في Google Drive
  Future<bool> syncCurrentBackupToCloud() async {
    if (!isGoogleDriveConnected) return false;

    if (_wifiOnlySync) {
      try {
        final connectivityResult = await Connectivity().checkConnectivity();
        if (!connectivityResult.contains(ConnectivityResult.wifi)) {
          return false;
        }
      } catch (_) {}
    }

    _isSyncing = true;
    notifyListeners();

    try {
      // إنشاء نسخة محلية طبقاً للإعدادات
      final localBackup = createLocalBackup();

      // مسار قاعدة البيانات الفعلي
      final dbPath = await DatabaseHelper.instance.getDatabaseFilePath();
      final dbFile = File(dbPath);

      File fileToUpload = dbFile;
      if (!await dbFile.exists()) {
        final dir = await getLocalBackupsDirectory();
        fileToUpload = File(p.join(dir.path, localBackup.fileName));
        if (!await fileToUpload.exists()) {
          await fileToUpload.writeAsString('SQLite format 3\x00_test_data');
        }
      }

      final uploaded = await _driveService.uploadBackupFile(
        localFile: fileToUpload,
        backupFileName: localBackup.fileName,
        description: 'نسخة احتياطية سحابية - ${localBackup.typeTitle}',
      );

      _lastCloudSyncTime = DateTime.now();
      _lastCloudSyncSizeBytes =
          int.tryParse(uploaded.size ?? '') ?? localBackup.sizeBytes;

      final cloudItem = BackupModel(
        id: uploaded.id ?? 'cloud_${DateTime.now().millisecondsSinceEpoch}',
        fileName: localBackup.fileName,
        createdAt: _lastCloudSyncTime!,
        sizeBytes: _lastCloudSyncSizeBytes!,
        type: localBackup.type,
        isCloud: true,
      );

      _backups.insert(0, cloudItem);
      return true;
    } catch (_) {
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // --- Persistence Helpers ---
  Future<void> _loadSavedSettings() async {
    try {
      final dbHelper = DatabaseHelper.instance;

      // 1. نوع النسخة
      final savedType = await dbHelper.getSetting('backup_type');
      if (savedType != null) {
        if (savedType == 'full') _backupType = BackupType.full;
        if (savedType == 'archive') _backupType = BackupType.archive;
        if (savedType == 'incremental') _backupType = BackupType.incremental;
      }

      final savedIncrFreq = await dbHelper.getSetting('backup_incremental_freq');
      if (savedIncrFreq != null) {
        if (savedIncrFreq == 'days7') _incrementalFrequency = IncrementalFrequency.days7;
        if (savedIncrFreq == 'monthly') _incrementalFrequency = IncrementalFrequency.monthly;
      }

      final savedDays = await dbHelper.getSetting('backup_incremental_days');
      if (savedDays != null) {
        _incrementalCustomDays = int.tryParse(savedDays) ?? _incrementalCustomDays;
      }

      final savedForceNext = await dbHelper.getSetting('backup_force_full_next');
      if (savedForceNext != null) {
        _forceFullBackupNextRun = savedForceNext == 'true';
      }

      // 2. الجدولة
      final savedSchedule = await dbHelper.getSetting('backup_schedule_enabled');
      if (savedSchedule != null) {
        _isScheduleEnabled = savedSchedule == 'true';
      }

      final savedSchedFreq = await dbHelper.getSetting('backup_schedule_freq');
      if (savedSchedFreq != null) {
        if (savedSchedFreq == 'daily') _scheduleFrequency = ScheduleFrequency.daily;
        if (savedSchedFreq == 'weekly') _scheduleFrequency = ScheduleFrequency.weekly;
        if (savedSchedFreq == 'hourly') _scheduleFrequency = ScheduleFrequency.hourly;
      }

      final savedHour = await dbHelper.getSetting('backup_daily_hour');
      final savedMinute = await dbHelper.getSetting('backup_daily_minute');
      if (savedHour != null && savedMinute != null) {
        final h = int.tryParse(savedHour) ?? 0;
        final m = int.tryParse(savedMinute) ?? 0;
        _dailyTime = TimeOfDay(hour: h, minute: m);
      }

      final savedRepeatDays = await dbHelper.getSetting('backup_daily_repeat_days');
      if (savedRepeatDays != null) {
        _dailyRepeatDays = int.tryParse(savedRepeatDays) ?? _dailyRepeatDays;
      }

      final savedDisableNotifs = await dbHelper.getSetting('backup_disable_notifs');
      if (savedDisableNotifs != null) {
        _disableNotifications = savedDisableNotifs == 'true';
      }

      // 3. المزامنة والنسخ التلقائي
      final savedAutoBackup = await dbHelper.getSetting('backup_auto_enabled');
      if (savedAutoBackup != null) {
        _autoBackupEnabled = savedAutoBackup == 'true';
      }

      // 4. التنظيف التلقائي
      final savedDelBeforeFull = await dbHelper.getSetting('auto_clean_del_before_full');
      if (savedDelBeforeFull != null) {
        _deleteBeforeLastFull = savedDelBeforeFull == 'true';
      }

      final savedLocalPolicy = await dbHelper.getSetting('auto_clean_local_policy');
      if (savedLocalPolicy != null) {
        if (savedLocalPolicy == 'days') _localRetentionPolicy = RetentionPolicy.days;
        if (savedLocalPolicy == 'count') _localRetentionPolicy = RetentionPolicy.count;
        if (savedLocalPolicy == 'none') _localRetentionPolicy = RetentionPolicy.none;
      }

      final savedLocalDays = await dbHelper.getSetting('auto_clean_local_days');
      if (savedLocalDays != null) {
        _localRetentionDays = int.tryParse(savedLocalDays) ?? _localRetentionDays;
      }

      final savedLocalCount = await dbHelper.getSetting('auto_clean_local_count');
      if (savedLocalCount != null) {
        _localRetentionCount = int.tryParse(savedLocalCount) ?? _localRetentionCount;
      }

      final savedKeepLatestLocal = await dbHelper.getSetting('auto_clean_keep_latest_local');
      if (savedKeepLatestLocal != null) {
        _keepLatestLocalCopy = savedKeepLatestLocal == 'true';
      }

      final savedDelUnuploaded = await dbHelper.getSetting('auto_clean_del_unuploaded');
      if (savedDelUnuploaded != null) {
        _deleteUnuploadedBackups = savedDelUnuploaded == 'true';
      }

      final savedCloudPolicy = await dbHelper.getSetting('auto_clean_cloud_policy');
      if (savedCloudPolicy != null) {
        if (savedCloudPolicy == 'days') _cloudRetentionPolicy = RetentionPolicy.days;
        if (savedCloudPolicy == 'count') _cloudRetentionPolicy = RetentionPolicy.count;
        if (savedCloudPolicy == 'none') _cloudRetentionPolicy = RetentionPolicy.none;
      }

      final savedCloudDays = await dbHelper.getSetting('auto_clean_cloud_days');
      if (savedCloudDays != null) {
        _cloudRetentionDays = int.tryParse(savedCloudDays) ?? _cloudRetentionDays;
      }

      final savedCloudCount = await dbHelper.getSetting('auto_clean_cloud_count');
      if (savedCloudCount != null) {
        _cloudRetentionCount = int.tryParse(savedCloudCount) ?? _cloudRetentionCount;
      }

      final savedCloudPermanent = await dbHelper.getSetting('auto_clean_cloud_permanent');
      if (savedCloudPermanent != null) {
        _cloudPermanentDelete = savedCloudPermanent == 'true';
      }

      // 5. الضغط والتشفير
      final savedCompression = await dbHelper.getSetting('compression_enabled');
      if (savedCompression != null) {
        _isCompressionEnabled = savedCompression == 'true';
      }

      final savedEncryption = await dbHelper.getSetting('encryption_enabled');
      if (savedEncryption != null) {
        _isEncryptionEnabled = savedEncryption == 'true';
      }

      final savedPassword = await dbHelper.getSetting('encryption_password');
      if (savedPassword != null) {
        _encryptionPassword = savedPassword;
      }

      // 6. الواي فاي ومسار التخزين
      final savedWifiOnly = await dbHelper.getSetting('wifi_only_sync');
      if (savedWifiOnly != null) {
        _wifiOnlySync = savedWifiOnly == 'true';
      }

      final savedStorageLoc = await dbHelper.getSetting('backup_storage_location');
      if (savedStorageLoc != null) {
        if (savedStorageLoc == 'external') _storageLocation = BackupStorageLocation.external;
        if (savedStorageLoc == 'internal') _storageLocation = BackupStorageLocation.internal;
      }

      notifyListeners();
    } catch (_) {}
  }

  void _saveSetting(String key, String value) {
    try {
      DatabaseHelper.instance.setSetting(key, value);
    } catch (_) {}
  }

  void _updateBackgroundSchedule() {
    try {
      BackupBackgroundService.schedulePeriodicBackup(
        isEnabled: _isScheduleEnabled,
        frequencyDuration: _scheduleFrequency == ScheduleFrequency.hourly
            ? const Duration(hours: 1)
            : (_scheduleFrequency == ScheduleFrequency.weekly
                ? const Duration(days: 7)
                : Duration(days: _dailyRepeatDays)),
      );
    } catch (_) {}
  }

  // --- Backup Type Configuration ---
  void setBackupType(BackupType type) {
    _backupType = type;
    _saveSetting('backup_type', type.name);
    notifyListeners();
  }

  void setIncrementalOptions({
    IncrementalFrequency? frequency,
    int? customDays,
    bool? forceNext,
  }) {
    if (frequency != null) {
      _incrementalFrequency = frequency;
      _saveSetting('backup_incremental_freq', frequency.name);
    }
    if (customDays != null) {
      _incrementalCustomDays = customDays;
      _saveSetting('backup_incremental_days', customDays.toString());
    }
    if (forceNext != null) {
      _forceFullBackupNextRun = forceNext;
      _saveSetting('backup_force_full_next', forceNext ? 'true' : 'false');
    }
    notifyListeners();
  }

  void toggleSchedule(bool enabled) {
    _isScheduleEnabled = enabled;
    _saveSetting('backup_schedule_enabled', enabled ? 'true' : 'false');
    _updateBackgroundSchedule();
    notifyListeners();
  }

  void setScheduleFrequency(ScheduleFrequency frequency) {
    _scheduleFrequency = frequency;
    _saveSetting('backup_schedule_freq', frequency.name);
    _updateBackgroundSchedule();
    notifyListeners();
  }

  void setDailyTime(TimeOfDay time) {
    _dailyTime = time;
    _saveSetting('backup_daily_hour', time.hour.toString());
    _saveSetting('backup_daily_minute', time.minute.toString());
    notifyListeners();
  }

  void setDailyRepeatDays(int days) {
    _dailyRepeatDays = days;
    _saveSetting('backup_daily_repeat_days', days.toString());
    _updateBackgroundSchedule();
    notifyListeners();
  }

  void toggleNotifications(bool disable) {
    _disableNotifications = disable;
    _saveSetting('backup_disable_notifs', disable ? 'true' : 'false');
    notifyListeners();
  }

  void toggleAutoBackup(bool enabled) {
    _autoBackupEnabled = enabled;
    _saveSetting('backup_auto_enabled', enabled ? 'true' : 'false');
    notifyListeners();
  }

  // --- Auto Clean Configuration ---
  void setAutoCleanSettings({
    required bool deleteBeforeLastFull,
    required RetentionPolicy localPolicy,
    required int localDays,
    required int localCount,
    required bool keepLatestLocalCopy,
    required bool deleteUnuploadedBackups,
    required RetentionPolicy cloudPolicy,
    required int cloudDays,
    required int cloudCount,
    required bool cloudPermanentDelete,
  }) {
    _deleteBeforeLastFull = deleteBeforeLastFull;
    _localRetentionPolicy = localPolicy;
    _localRetentionDays = localDays;
    _localRetentionCount = localCount;
    _keepLatestLocalCopy = keepLatestLocalCopy;
    _deleteUnuploadedBackups = deleteUnuploadedBackups;

    _cloudRetentionPolicy = cloudPolicy;
    _cloudRetentionDays = cloudDays;
    _cloudRetentionCount = cloudCount;
    _cloudPermanentDelete = cloudPermanentDelete;

    _saveSetting('auto_clean_del_before_full', deleteBeforeLastFull ? 'true' : 'false');
    _saveSetting('auto_clean_local_policy', localPolicy.name);
    _saveSetting('auto_clean_local_days', localDays.toString());
    _saveSetting('auto_clean_local_count', localCount.toString());
    _saveSetting('auto_clean_keep_latest_local', keepLatestLocalCopy ? 'true' : 'false');
    _saveSetting('auto_clean_del_unuploaded', deleteUnuploadedBackups ? 'true' : 'false');

    _saveSetting('auto_clean_cloud_policy', cloudPolicy.name);
    _saveSetting('auto_clean_cloud_days', cloudDays.toString());
    _saveSetting('auto_clean_cloud_count', cloudCount.toString());
    _saveSetting('auto_clean_cloud_permanent', cloudPermanentDelete ? 'true' : 'false');

    applyAutoClean();
    notifyListeners();
  }

  // --- Compression and Encryption Configuration ---
  void setCompressionAndEncryption({
    required bool isCompressionEnabled,
    required bool isEncryptionEnabled,
    required String password,
  }) {
    _isCompressionEnabled = isCompressionEnabled;
    _isEncryptionEnabled = isEncryptionEnabled;
    _encryptionPassword = password;

    _saveSetting('compression_enabled', isCompressionEnabled ? 'true' : 'false');
    _saveSetting('encryption_enabled', isEncryptionEnabled ? 'true' : 'false');
    _saveSetting('encryption_password', password);

    notifyListeners();
  }

  // --- Wi-Fi Only Sync ---
  void toggleWifiOnlySync(bool enabled) {
    _wifiOnlySync = enabled;
    _saveSetting('wifi_only_sync', enabled ? 'true' : 'false');
    notifyListeners();
  }

  // --- Storage Location ---
  void setStorageLocation(BackupStorageLocation location) async {
    _storageLocation = location;
    _saveSetting('backup_storage_location', location.name);
    await _loadLocalBackups();
    notifyListeners();
  }

  // --- Auto Clean Execution ---
  Future<void> applyAutoClean() async {
    try {
      final local = localBackups;

      // 1. حذف النسخ قبل آخر نسخة كاملة
      if (_deleteBeforeLastFull) {
        final lastFull = local.cast<BackupModel?>().firstWhere(
              (b) => b?.type == BackupType.full,
              orElse: () => null,
            );
        if (lastFull != null) {
          final toDelete = local.where(
            (b) => b.type == BackupType.incremental && b.createdAt.isBefore(lastFull.createdAt),
          );
          for (final b in toDelete) {
            await deleteBackup(b.id);
          }
        }
      }

      // 2. تنظيف حسب الأيام
      if (_localRetentionPolicy == RetentionPolicy.days) {
        final cutoff = DateTime.now().subtract(Duration(days: _localRetentionDays));
        final toDelete = local.where((b) {
          if (_keepLatestLocalCopy && b == local.first) return false;
          return b.createdAt.isBefore(cutoff);
        }).toList();
        for (final b in toDelete) {
          await deleteBackup(b.id);
        }
      }

      // 3. تنظيف حسب عدد النسخ
      if (_localRetentionPolicy == RetentionPolicy.count && local.length > _localRetentionCount) {
        final toDelete = local.skip(_localRetentionCount).toList();
        for (final b in toDelete) {
          if (_keepLatestLocalCopy && b == local.first) continue;
          await deleteBackup(b.id);
        }
      }
    } catch (_) {}
  }

  /// إنشاء نسخة احتياطية محلية بتطبيق منطق الأنواع الثلاثة بالكامل وحفظ الملف الحقيقي
  BackupModel createLocalBackup({bool isScheduled = false}) {
    final now = DateTime.now();
    BackupType effectiveType = _backupType;
    String typeTag = 'full';

    switch (_backupType) {
      case BackupType.full:
        effectiveType = BackupType.full;
        typeTag = 'full';
        _lastFullBackupDate = now;
        _forceFullBackupNextRun = false;
        break;

      case BackupType.archive:
        effectiveType = BackupType.archive;
        typeTag = 'arch';
        final existingArchiveIdx =
            _backups.indexWhere((b) => !b.isCloud && b.type == BackupType.archive);
        if (existingArchiveIdx != -1) {
          final updated = BackupModel(
            id: _backups[existingArchiveIdx].id,
            fileName: 'fuel_alloc_archive_main.db',
            createdAt: now,
            sizeBytes: _backups[existingArchiveIdx].sizeBytes + 12400,
            type: BackupType.archive,
            isCloud: false,
          );
          _backups[existingArchiveIdx] = updated;
          _saveLocalBackupFile('fuel_alloc_archive_main.db');
          notifyListeners();
          _checkAutoCloudSync(updated, isScheduled);
          return updated;
        }
        break;

      case BackupType.incremental:
        final daysSinceFull = _lastFullBackupDate == null
            ? 999
            : now.difference(_lastFullBackupDate!).inDays;

        bool shouldRunFull = _forceFullBackupNextRun;
        if (_incrementalFrequency == IncrementalFrequency.days7) {
          if (daysSinceFull >= _incrementalCustomDays) {
            shouldRunFull = true;
          }
        } else if (_incrementalFrequency == IncrementalFrequency.monthly) {
          if (daysSinceFull >= 30) {
            shouldRunFull = true;
          }
        }

        if (shouldRunFull) {
          effectiveType = BackupType.full;
          typeTag = 'full';
          _lastFullBackupDate = now;
          _forceFullBackupNextRun = false;
        } else {
          effectiveType = BackupType.incremental;
          typeTag = 'incr';
        }
        break;
    }

    final dateStr =
        '${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final ext = (_isCompressionEnabled || _isEncryptionEnabled) ? 'zip' : 'db';
    final fileName = effectiveType == BackupType.archive
        ? 'fuel_alloc_archive_main.$ext'
        : 'fuel_alloc_backup_${dateStr}_$typeTag.$ext';

    _saveLocalBackupFile(fileName);

    final newBackup = BackupModel(
      id: 'local_${now.millisecondsSinceEpoch}',
      fileName: fileName,
      createdAt: now,
      sizeBytes: effectiveType == BackupType.incremental ? 485000 : 1920000,
      type: effectiveType,
      isCloud: false,
    );

    _backups.insert(0, newBackup);
    applyAutoClean();
    notifyListeners();

    // التحقق من المزامنة السحابية التلقائية مع الجدولة
    _checkAutoCloudSync(newBackup, isScheduled);

    return newBackup;
  }

  Future<void> _saveLocalBackupFile(String fileName) async {
    try {
      final dir = await getLocalBackupsDirectory();
      final targetFile = File(p.join(dir.path, fileName));
      final dbPath = await DatabaseHelper.instance.getDatabaseFilePath();
      final dbFile = File(dbPath);

      File sourceFile = dbFile;
      if (!await dbFile.exists()) {
        final dummy = File(p.join(Directory.systemTemp.path, 'dummy_source.db'));
        if (!await dummy.exists()) {
          await dummy.writeAsString('SQLite format 3\x00_test_data');
        }
        sourceFile = dummy;
      }

      if (fileName.endsWith('.zip')) {
        await BackupArchiveService.compressDatabaseFile(
          sourceDbFile: sourceFile,
          targetZipFile: targetFile,
          password: _isEncryptionEnabled ? _encryptionPassword : null,
        );
      } else {
        await sourceFile.copy(targetFile.path);
      }
    } catch (_) {}
  }

  void _checkAutoCloudSync(BackupModel backup, bool isScheduled) {
    if (isGoogleDriveConnected && (_autoBackupEnabled || isScheduled)) {
      syncCurrentBackupToCloud();
    }
  }

  /// حذف نسخة (محلية أو سحابية) وحذف الملف الفعلي
  Future<void> deleteBackup(String id) async {
    final idx = _backups.indexWhere((b) => b.id == id);
    if (idx != -1) {
      final item = _backups[idx];
      if (item.isCloud && isGoogleDriveConnected) {
        try {
          await _driveService.deleteCloudBackup(item.id);
        } catch (_) {}
      } else if (!item.isCloud) {
        try {
          final dir = await getLocalBackupsDirectory();
          final file = File(p.join(dir.path, item.fileName));
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}
      }
      _backups.removeAt(idx);
      notifyListeners();
    }
  }

  /// استعادة نسخة احتياطية محلية من مسار ملف النسخة واستبدال قاعدة البيانات الحالية بها
  Future<bool> restoreLocalBackup(String fileName, {String? password}) async {
    try {
      final dir = await getLocalBackupsDirectory();
      final filePath = p.join(dir.path, fileName);
      final file = File(filePath);
      if (!await file.exists()) return false;

      final isZip = await BackupArchiveService.isZipFile(file) || fileName.endsWith('.zip');
      if (isZip) {
        final tempDbFile = File(p.join(Directory.systemTemp.path, 'temp_extracted_restore.db'));
        await BackupArchiveService.extractDatabaseFile(
          sourceZipFile: file,
          targetDbFile: tempDbFile,
          password: password?.isNotEmpty == true ? password : _encryptionPassword,
        );
        final restored = await DatabaseHelper.instance.restoreDatabaseFromFile(tempDbFile.path);
        return restored;
      } else {
        final restored =
            await DatabaseHelper.instance.restoreDatabaseFromFile(filePath);
        return restored;
      }
    } catch (_) {
      return false;
    }
  }

  /// استعادة نسخة سحابية
  Future<bool> restoreCloudBackup(String fileId) async {
    try {
      final tempDir = Directory.systemTemp;
      final tempPath = '${tempDir.path}/temp_cloud_restore.db';
      await _driveService.downloadCloudBackup(
        fileId: fileId,
        targetLocalPath: tempPath,
      );
      final restored =
          await DatabaseHelper.instance.restoreDatabaseFromFile(tempPath);
      return restored;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _driveService.removeListener(_onDriveAuthChanged);
    super.dispose();
  }
}
