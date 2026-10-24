import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fuel_alloc_app/controllers/auth_controller.dart';
import 'package:fuel_alloc_app/core/constants/app_strings.dart';
import 'package:fuel_alloc_app/views/settings/backup_settings_view.dart';
import 'package:fuel_alloc_app/views/settings/settings_view.dart';

void main() {
  group('AuthController Tests', () {
    test('Initial unauthenticated state matches requirements', () {
      final auth = AuthController();
      expect(auth.isLoggedIn, isFalse);
      expect(auth.displayName, equals(AppStrings.unregisteredUser));
      expect(auth.displaySubtitle, equals(AppStrings.loginOrLinkAccount));
      expect(auth.accountStatusText, equals(AppStrings.unlinkedAccount));
    });

    test('Login updates profile name and subtitle to email dynamically', () {
      final auth = AuthController();
      auth.login(
        name: 'الحسين المتوكل',
        email: 'almutawakkil@example.com',
      );

      expect(auth.isLoggedIn, isTrue);
      expect(auth.displayName, equals('الحسين المتوكل'));
      // Subtitle becomes the registered email instead of edit profile
      expect(auth.displaySubtitle, equals('almutawakkil@example.com'));
      expect(auth.accountStatusText, equals('almutawakkil@example.com'));
    });

    test('Logout clears user information and reverts to unregistered state', () async {
      final auth = AuthController();
      auth.login(name: 'مستخدم', email: 'user@test.org');
      expect(auth.isLoggedIn, isTrue);

      await auth.logout();
      expect(auth.isLoggedIn, isFalse);
      expect(auth.displayName, equals(AppStrings.unregisteredUser));
      expect(auth.displaySubtitle, equals(AppStrings.loginOrLinkAccount));
      expect(auth.accountStatusText, equals(AppStrings.unlinkedAccount));
    });
  });

  group('SettingsView Backup & Auth Integration Tests', () {
    testWidgets('SettingsView displays backup tile above recycle bin in same card',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AuthController(),
          child: const MaterialApp(
            home: SettingsView(),
          ),
        ),
      );

      // Verify Unregistered state initially in profile card and Personal Info tile
      expect(find.text(AppStrings.unregisteredUser), findsOneWidget);
      expect(find.text(AppStrings.personalInfo), findsOneWidget);
      expect(find.text(AppStrings.loginOrLinkAccount), findsOneWidget);

      // Verify Backup tile is present
      expect(find.text(AppStrings.backup), findsOneWidget);
      expect(find.text(AppStrings.recycleBinTitle), findsOneWidget);
      expect(find.text(AppStrings.archiveTitle), findsOneWidget);

      // Tapping Backup navigates to BackupSettingsView
      await tester.tap(find.text(AppStrings.backup));
      await tester.pumpAndSettle();

      expect(find.byType(BackupSettingsView), findsOneWidget);
      expect(find.text(AppStrings.createLocalBackup), findsOneWidget);
      expect(find.text(AppStrings.restoreLocalBackup), findsOneWidget);
      expect(find.text(AppStrings.backupStorageLocation), findsOneWidget);
    });
  });
}

