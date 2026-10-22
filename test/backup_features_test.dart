import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fuel_alloc_app/controllers/backup_controller.dart';
import 'package:fuel_alloc_app/core/constants/app_strings.dart';
import 'package:fuel_alloc_app/core/widgets/app_switch.dart';
import 'package:fuel_alloc_app/core/widgets/custom_button.dart';
import 'package:fuel_alloc_app/models/backup_model.dart';
import 'package:fuel_alloc_app/services/backup_archive_service.dart';
import 'package:fuel_alloc_app/views/settings/auto_clean_settings_view.dart';
import 'package:fuel_alloc_app/views/settings/backup_settings_view.dart';
import 'package:fuel_alloc_app/views/settings/backup_type_settings_view.dart';
import 'package:fuel_alloc_app/views/settings/backups_list_view.dart';
import 'package:fuel_alloc_app/views/settings/compression_encryption_settings_view.dart';
import 'package:fuel_alloc_app/views/settings/scheduled_backup_settings_view.dart';

void main() {
  group('BackupController Unit Tests', () {
    test('Default backup controller values match specifications', () {
      final controller = BackupController();
      expect(controller.backupType, equals(BackupType.full));
      expect(controller.backupTypeTitle, equals(AppStrings.backupFullTitle));
      expect(controller.incrementalFrequency, equals(IncrementalFrequency.days7));
      expect(controller.incrementalCustomDays, equals(7));
      expect(controller.forceFullBackupNextRun, isFalse);
      expect(controller.isScheduleEnabled, isTrue);
      expect(controller.scheduleFrequency, equals(ScheduleFrequency.daily));
      expect(controller.dailyTime, equals(const TimeOfDay(hour: 0, minute: 0)));
      expect(controller.formattedDailyTime, contains('12:00'));
      expect(controller.scheduleStatusSummary, contains(AppStrings.scheduleEnabledDaily));
      expect(controller.autoBackupEnabled, isFalse);
      expect(controller.localBackups.isEmpty, isTrue);
      expect(controller.cloudBackups.isEmpty, isTrue);

      // Default new feature values
      expect(controller.wifiOnlySync, isFalse);
      expect(controller.storageLocation, equals(BackupStorageLocation.internal));
      expect(controller.isCompressionEnabled, isFalse);
      expect(controller.isEncryptionEnabled, isFalse);
      expect(controller.deleteBeforeLastFull, isFalse);
      expect(controller.localRetentionPolicy, equals(RetentionPolicy.none));
    });

    test('Creating a local backup adds a new backup to localBackups', () {
      final controller = BackupController();
      final initialCount = controller.localBackups.length;
      final newBackup = controller.createLocalBackup();

      expect(controller.localBackups.length, equals(initialCount + 1));
      expect(newBackup.isCloud, isFalse);
      expect(newBackup.fileName, startsWith('fuel_alloc_backup_'));
      expect(newBackup.type, equals(BackupType.full));
      expect(newBackup.fileName, endsWith('.db'));
    });

    test('Creating backup with compression/encryption creates .zip file', () {
      final controller = BackupController();
      controller.setCompressionAndEncryption(
        isCompressionEnabled: true,
        isEncryptionEnabled: true,
        password: 'secure_password_123',
      );
      expect(controller.isCompressionEnabled, isTrue);
      expect(controller.isEncryptionEnabled, isTrue);
      expect(controller.encryptionPassword, equals('secure_password_123'));

      final newBackup = controller.createLocalBackup();
      expect(newBackup.fileName, endsWith('.zip'));
    });

    test('Updating backup type and schedule reflects in getters', () {
      final controller = BackupController();
      controller.setBackupType(BackupType.incremental);
      expect(controller.backupType, equals(BackupType.incremental));
      expect(controller.backupTypeTitle, equals(AppStrings.backupIncrementalTitle));

      controller.setScheduleFrequency(ScheduleFrequency.weekly);
      expect(controller.scheduleStatusSummary, equals(AppStrings.scheduleEnabledWeekly));

      controller.toggleSchedule(false);
      expect(controller.scheduleStatusSummary, equals(AppStrings.scheduleDisabled));
    });

    test('BackupModel formats sizes and dates cleanly', () {
      final item = BackupModel(
        id: 'test_1',
        fileName: 'backup_test.db',
        createdAt: DateTime(2026, 10, 21, 14, 30),
        sizeBytes: 2048 * 1024,
        type: BackupType.full,
      );

      expect(item.formattedSize, contains('2.0'));
      expect(item.formattedDate, contains('2026/10/21'));
      expect(item.typeBadge, equals(AppStrings.backupFullBadge));
    });

    test('Incremental backup promotes to full backup when forced or cycle expires', () {
      final controller = BackupController();
      controller.setBackupType(BackupType.incremental);
      controller.setIncrementalOptions(forceNext: true);

      expect(controller.forceFullBackupNextRun, isTrue);

      final b1 = controller.createLocalBackup();
      expect(b1.type, equals(BackupType.full));
      expect(b1.fileName, contains('_full.db'));
      expect(controller.forceFullBackupNextRun, isFalse);
      expect(controller.lastFullBackupDate, isNotNull);

      final b2 = controller.createLocalBackup();
      expect(b2.type, equals(BackupType.incremental));
      expect(b2.fileName, contains('_incr.db'));
    });

    test('Archive mode creates or updates fuel_alloc_archive_main.db', () {
      final controller = BackupController();
      controller.setBackupType(BackupType.archive);

      final b = controller.createLocalBackup();
      expect(b.type, equals(BackupType.archive));
      expect(b.fileName, equals('fuel_alloc_archive_main.db'));
    });

    test('Auto clean settings updates and retention policy application', () async {
      final controller = BackupController();
      controller.setAutoCleanSettings(
        deleteBeforeLastFull: true,
        localPolicy: RetentionPolicy.count,
        localDays: 30,
        localCount: 2,
        keepLatestLocalCopy: true,
        deleteUnuploadedBackups: false,
        cloudPolicy: RetentionPolicy.days,
        cloudDays: 60,
        cloudCount: 10,
        cloudPermanentDelete: false,
      );

      expect(controller.deleteBeforeLastFull, isTrue);
      expect(controller.localRetentionPolicy, equals(RetentionPolicy.count));
      expect(controller.localRetentionCount, equals(2));
      expect(controller.cloudRetentionPolicy, equals(RetentionPolicy.days));
      expect(controller.cloudRetentionDays, equals(60));

      // Create 4 backups and check auto clean retains count
      controller.createLocalBackup();
      controller.createLocalBackup();
      controller.createLocalBackup();
      controller.createLocalBackup();

      await controller.applyAutoClean();
      expect(controller.localBackups.length, lessThanOrEqualTo(2));
    });

    test('Wi-Fi only sync and storage location toggling', () {
      final controller = BackupController();

      controller.toggleWifiOnlySync(true);
      expect(controller.wifiOnlySync, isTrue);

      controller.setStorageLocation(BackupStorageLocation.external);
      expect(controller.storageLocation, equals(BackupStorageLocation.external));
    });

    test('Google Drive sync getters provide correct localized strings', () {
      final controller = BackupController();
      expect(controller.lastCloudSyncFormatted, equals(AppStrings.noSyncYet));
      expect(controller.isSyncing, isFalse);
    });

    test('restoreLocalBackup returns false for non-existent file gracefully', () async {
      final controller = BackupController();
      final result = await controller.restoreLocalBackup('non_existent_file.db');
      expect(result, isFalse);
    });
  });

  group('BackupArchiveService ZIP Compression & Encryption Unit Tests', () {
    test('Compressing to ZIP and extracting validates correctly', () async {
      final tempDir = Directory.systemTemp.createTempSync('archive_test_');
      final sourceFile = File('${tempDir.path}/test_db.db');
      await sourceFile.writeAsString('Test SQLite database content for fuel alloc app');

      final targetZip = File('${tempDir.path}/test_db.zip');
      await BackupArchiveService.compressDatabaseFile(
        sourceDbFile: sourceFile,
        targetZipFile: targetZip,
      );

      expect(await targetZip.exists(), isTrue);
      expect(await BackupArchiveService.isZipFile(targetZip), isTrue);
      expect(await BackupArchiveService.isZipFile(sourceFile), isFalse);

      final extractedFile = File('${tempDir.path}/extracted_db.db');
      await BackupArchiveService.extractDatabaseFile(
        sourceZipFile: targetZip,
        targetDbFile: extractedFile,
      );

      expect(await extractedFile.exists(), isTrue);
      expect(await extractedFile.readAsString(), equals(await sourceFile.readAsString()));

      tempDir.deleteSync(recursive: true);
    });
  });

  group('BackupSettingsView Full Navigation & One UI Integration Tests', () {
    Widget buildTestApp({BackupController? controller}) {
      return ChangeNotifierProvider(
        create: (_) => controller ?? BackupController(),
        child: const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: BackupSettingsView(),
          ),
        ),
      );
    }

    testWidgets('Renders all 4 One UI cards and tiles correctly', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Card 1
      expect(find.text(AppStrings.createLocalBackup), findsOneWidget);
      expect(find.text(AppStrings.restoreLocalBackup), findsOneWidget);

      // Card 2
      expect(find.text(AppStrings.backupType), findsOneWidget);
      expect(find.text(AppStrings.scheduledBackupTitle), findsOneWidget);
      expect(find.text(AppStrings.autoCleanTitle), findsOneWidget);
      expect(find.text(AppStrings.compressionEncryptionTitle), findsOneWidget);
      expect(find.text(AppStrings.backupStorageLocation), findsOneWidget);

      // Card 3
      expect(find.text(AppStrings.viewBackups), findsOneWidget);

      // Card 4
      expect(find.text(AppStrings.cloudBackup), findsOneWidget);
      expect(find.text(AppStrings.autoBackup), findsOneWidget);
      expect(find.text(AppStrings.wifiOnlyTitle), findsOneWidget);
      expect(find.byType(AppSwitch), findsNWidgets(2)); // Auto Backup + Wi-Fi Only
    });

    testWidgets('Tapping backupType opens BackupTypeSettingsView', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.backupType));
      await tester.pumpAndSettle();

      expect(find.byType(BackupTypeSettingsView), findsOneWidget);
      expect(find.text(AppStrings.backupFullTitle), findsOneWidget);
      expect(find.text(AppStrings.backupArchiveTitle), findsOneWidget);
      expect(find.text(AppStrings.backupIncrementalTitle), findsOneWidget);
      expect(find.byType(CustomButton), findsNWidgets(2)); // Save & Cancel
    });

    testWidgets('Tapping scheduledBackupTitle opens ScheduledBackupSettingsView', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.scheduledBackupTitle));
      await tester.pumpAndSettle();

      expect(find.byType(ScheduledBackupSettingsView), findsOneWidget);
      expect(find.text(AppStrings.scheduleRecurringBackups), findsOneWidget);
      expect(find.text(AppStrings.daily), findsOneWidget);
      expect(find.text(AppStrings.weekly), findsOneWidget);
      expect(find.text(AppStrings.hourly), findsOneWidget);
      expect(find.text(AppStrings.disableNotifications), findsOneWidget);
    });

    testWidgets('Tapping autoCleanTitle opens AutoCleanSettingsView', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.autoCleanTitle));
      await tester.pumpAndSettle();

      expect(find.byType(AutoCleanSettingsView), findsOneWidget);
      expect(find.text(AppStrings.autoCleanSubtitle), findsOneWidget);
      expect(find.text(AppStrings.incrementalBackupsHeader), findsOneWidget);
      expect(find.text(AppStrings.localBackupSection), findsOneWidget);
    });

    testWidgets('Tapping compressionEncryptionTitle opens CompressionEncryptionSettingsView',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.compressionEncryptionTitle));
      await tester.pumpAndSettle();

      expect(find.byType(CompressionEncryptionSettingsView), findsOneWidget);
      expect(find.text(AppStrings.compressBackups), findsOneWidget);
      expect(find.text(AppStrings.encryptBackups), findsOneWidget);
    });

    testWidgets('Tapping viewBackups opens BackupsListView with local and cloud segments',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = BackupController();
      controller.createLocalBackup();

      await tester.pumpWidget(buildTestApp(controller: controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.viewBackups));
      await tester.pumpAndSettle();

      expect(find.byType(BackupsListView), findsOneWidget);
      expect(find.text(AppStrings.tabLocal), findsOneWidget);
      expect(find.text(AppStrings.tabCloud), findsOneWidget);
      expect(find.text(AppStrings.restore), findsWidgets);
      expect(find.text(AppStrings.share), findsWidgets);
      expect(find.text(AppStrings.delete), findsWidgets);
    });

    testWidgets('BackupSettingsView has zero chevron/arrow icons in setting tiles', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Ensure no chevron or forward arrow icons are present in the settings screen
      expect(find.byIcon(Icons.chevron_left), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
      expect(find.byIcon(Icons.arrow_forward_ios), findsNothing);
      expect(find.byIcon(Icons.arrow_back_ios), findsNothing);
    });
  });

  group('Incremental Options in BackupTypeSettingsView', () {
    testWidgets('Selecting incremental option reveals sub-options and checkbox', (tester) async {
      final controller = BackupController();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: controller,
          child: const MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: BackupTypeSettingsView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially incremental sub-options are hidden
      expect(find.text(AppStrings.createFullBackupNew), findsNothing);

      // Tap on incremental
      await tester.tap(find.text(AppStrings.backupIncrementalTitle));
      await tester.pumpAndSettle();

      // Incremental sub-options are now visible
      expect(find.text(AppStrings.createFullBackupNew), findsOneWidget);
      expect(find.text(AppStrings.every7Days), findsOneWidget);
      expect(find.text(AppStrings.chooseDays), findsOneWidget);
      expect(find.text(AppStrings.everyMonth), findsOneWidget);
      expect(find.text(AppStrings.forceFullBackupNextRun), findsOneWidget);
    });
  });

  group('Screenshot UI Specifications Verification Tests', () {
    testWidgets('AutoCleanSettingsView renders all sections matching Screenshot 1', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = BackupController();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: controller,
          child: const MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: AutoCleanSettingsView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header subtitle
      expect(find.text(AppStrings.autoCleanSubtitle), findsOneWidget);

      // Verify Incremental card & switch
      expect(find.text(AppStrings.incrementalBackupsHeader), findsOneWidget);
      expect(find.text(AppStrings.deleteBeforeLastFull), findsOneWidget);
      expect(find.text(AppStrings.deleteBeforeLastFullDesc), findsOneWidget);

      // Verify Local backup section
      expect(find.text(AppStrings.localBackupSection), findsOneWidget);
      expect(find.text(AppStrings.noDeletion), findsWidgets);
      expect(find.text(AppStrings.keepForDays), findsWidgets);
      expect(find.text(AppStrings.keepLastCount), findsWidgets);
      expect(find.text(AppStrings.keepLatestLocalCopy), findsOneWidget);
      expect(find.text(AppStrings.deleteUnuploadedBackups), findsOneWidget);

      // Verify Cloud sections
      expect(find.text(AppStrings.googleDriveSection), findsOneWidget);
      expect(find.text(AppStrings.dropboxSection), findsOneWidget);
    });

    testWidgets('CompressionEncryptionSettingsView renders components matching Screenshot 2',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = BackupController();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: controller,
          child: const MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: CompressionEncryptionSettingsView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Compress and Encrypt switches
      expect(find.text(AppStrings.compressBackups), findsOneWidget);
      expect(find.text(AppStrings.encryptBackups), findsOneWidget);
      expect(find.text(AppStrings.compressBackupsDesc), findsOneWidget);
      expect(find.text(AppStrings.encryptBackupsDesc), findsOneWidget);

      // Toggling encrypt backups reveals red warning and password fields
      await tester.tap(find.text(AppStrings.encryptBackups));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.encryptionPasswordWarning), findsOneWidget);
      expect(find.text(AppStrings.enterPassword), findsWidgets);
      expect(find.text(AppStrings.confirmPassword), findsWidgets);
      expect(find.text(AppStrings.save), findsOneWidget);
      expect(find.text(AppStrings.cancel), findsOneWidget);
    });
  });
}
