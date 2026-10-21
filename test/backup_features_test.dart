import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fuel_alloc_app/controllers/backup_controller.dart';
import 'package:fuel_alloc_app/core/constants/app_strings.dart';
import 'package:fuel_alloc_app/core/widgets/app_switch.dart';
import 'package:fuel_alloc_app/core/widgets/custom_button.dart';
import 'package:fuel_alloc_app/models/backup_model.dart';
import 'package:fuel_alloc_app/views/settings/backup_settings_view.dart';
import 'package:fuel_alloc_app/views/settings/backup_type_settings_view.dart';
import 'package:fuel_alloc_app/views/settings/backups_list_view.dart';
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
    });

    test('Creating a local backup adds a new backup to localBackups', () {
      final controller = BackupController();
      final initialCount = controller.localBackups.length;
      final newBackup = controller.createLocalBackup();

      expect(controller.localBackups.length, equals(initialCount + 1));
      expect(newBackup.isCloud, isFalse);
      expect(newBackup.fileName, startsWith('fuel_alloc_backup_'));
      expect(newBackup.type, equals(BackupType.full));
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

    test('Google Drive sync getters provide correct localized strings', () {
      final controller = BackupController();
      expect(controller.lastCloudSyncFormatted, equals(AppStrings.noSyncYet));
      expect(controller.isSyncing, isFalse);
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

    testWidgets('Renders all 4 One UI cards and AppSwitch correctly', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Card 1
      expect(find.text(AppStrings.createLocalBackup), findsOneWidget);
      expect(find.text(AppStrings.restoreLocalBackup), findsOneWidget);

      // Card 2
      expect(find.text(AppStrings.backupType), findsOneWidget);
      expect(find.text(AppStrings.scheduledBackupTitle), findsOneWidget);

      // Card 3
      expect(find.text(AppStrings.viewBackups), findsOneWidget);

      // Card 4
      expect(find.text(AppStrings.cloudBackup), findsOneWidget);
      expect(find.text(AppStrings.autoBackup), findsOneWidget);
      expect(find.byType(AppSwitch), findsOneWidget);
    });

    testWidgets('Tapping backupType opens BackupTypeSettingsView', (tester) async {
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

    testWidgets('Tapping viewBackups opens BackupsListView with local and cloud segments',
        (tester) async {
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
}
