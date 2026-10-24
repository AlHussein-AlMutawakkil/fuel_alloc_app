import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fuel_alloc_app/controllers/auth_controller.dart';
import 'package:fuel_alloc_app/controllers/personal_info_controller.dart';
import 'package:fuel_alloc_app/core/constants/app_strings.dart';
import 'package:fuel_alloc_app/models/personal_info_model.dart';
import 'package:fuel_alloc_app/views/settings/personal_info_settings_view.dart';
import 'package:fuel_alloc_app/views/settings/settings_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PersonalInfoModel Unit Tests', () {
    test('Default values of PersonalInfoModel are correct', () {
      const model = PersonalInfoModel();
      expect(model.arabicName, isEmpty);
      expect(model.englishName, isEmpty);
      expect(model.arabicAddress, isEmpty);
      expect(model.englishAddress, isEmpty);
      expect(model.contactNumbers, isEmpty);
      expect(model.logoPath, isNull);
      expect(model.stampPath, isNull);
      expect(model.signaturePath, isNull);
      expect(model.logoScalePercent, equals(100));
      expect(model.stampScalePercent, equals(100));
      expect(model.signatureScalePercent, equals(100));
      expect(model.includeInBackup, isTrue);
    });

    test('toMap and fromMap serialize and deserialize accurately', () {
      const model = PersonalInfoModel(
        arabicName: 'شركة الوقود الوطنية',
        englishName: 'National Fuel Co',
        arabicAddress: 'صنعاء - شارع الستين',
        englishAddress: 'Sanaa - 60th St',
        contactNumbers: '777123456, 733123456',
        logoPath: '/data/logo.png',
        stampPath: '/data/stamp.png',
        signaturePath: '/data/sig.png',
        logoScalePercent: 120,
        stampScalePercent: 85,
        signatureScalePercent: 110,
        includeInBackup: false,
      );

      final map = model.toMap();
      final restored = PersonalInfoModel.fromMap(map);

      expect(restored.arabicName, equals(model.arabicName));
      expect(restored.englishName, equals(model.englishName));
      expect(restored.arabicAddress, equals(model.arabicAddress));
      expect(restored.englishAddress, equals(model.englishAddress));
      expect(restored.contactNumbers, equals(model.contactNumbers));
      expect(restored.logoPath, equals(model.logoPath));
      expect(restored.stampPath, equals(model.stampPath));
      expect(restored.signaturePath, equals(model.signaturePath));
      expect(restored.logoScalePercent, equals(120));
      expect(restored.stampScalePercent, equals(85));
      expect(restored.signatureScalePercent, equals(110));
      expect(restored.includeInBackup, isFalse);
    });

    test('copyWith updates specific properties correctly', () {
      const model = PersonalInfoModel(
        arabicName: 'الاسم الأصلي',
        logoScalePercent: 100,
      );

      final updated = model.copyWith(
        arabicName: 'الاسم الجديد',
        logoScalePercent: 150,
        clearLogoPath: true,
      );

      expect(updated.arabicName, equals('الاسم الجديد'));
      expect(updated.logoScalePercent, equals(150));
      expect(updated.logoPath, isNull);
    });
  });

  group('PersonalInfoSettingsView Widget Tests', () {
    testWidgets('Renders all fields, sliders, and backup switch correctly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => PersonalInfoController()),
          ],
          child: const MaterialApp(
            home: PersonalInfoSettingsView(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify View Title
      expect(find.text(AppStrings.personalInfoViewTitle), findsOneWidget);

      // Verify Section Headers
      expect(find.text(AppStrings.generalInfoSection), findsOneWidget);
      expect(find.text(AppStrings.brandingSection), findsOneWidget);
      expect(find.text(AppStrings.logoLabel), findsOneWidget);
      expect(find.text(AppStrings.stampLabel), findsOneWidget);
      expect(find.text(AppStrings.signatureLabel), findsOneWidget);
      expect(find.text(AppStrings.backupInclusionSection), findsOneWidget);

      // Verify General Info Labels
      expect(find.text(AppStrings.arabicNameLabel), findsOneWidget);
      expect(find.text(AppStrings.englishNameLabel), findsOneWidget);
      expect(find.text(AppStrings.arabicAddressLabel), findsOneWidget);
      expect(find.text(AppStrings.englishAddressLabel), findsOneWidget);
      expect(find.text(AppStrings.contactNumbersLabel), findsOneWidget);

      // Verify Media Selection Buttons
      expect(find.text(AppStrings.selectLogo), findsOneWidget);
      expect(find.text(AppStrings.selectStamp), findsOneWidget);
      expect(find.text(AppStrings.selectSignature), findsOneWidget);

      // Verify Size Percent Labels
      expect(find.text(AppStrings.logoSizePercentLabel), findsOneWidget);
      expect(find.text(AppStrings.stampSizePercentLabel), findsOneWidget);
      expect(find.text(AppStrings.signatureSizePercentLabel), findsOneWidget);

      // Verify Backup Option
      expect(find.text(AppStrings.includePersonalInfoInBackupTitle), findsOneWidget);

      // Verify Save Button
      expect(find.text(AppStrings.savePersonalInfo), findsOneWidget);
    });

    testWidgets('Navigating from SettingsView to PersonalInfoSettingsView works seamlessly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthController()),
            ChangeNotifierProvider(create: (_) => PersonalInfoController()),
          ],
          child: const MaterialApp(
            home: SettingsView(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find Personal Info tile in Settings
      expect(find.text(AppStrings.personalInfo), findsOneWidget);

      // Tap Personal Info tile
      await tester.tap(find.text(AppStrings.personalInfo));
      await tester.pumpAndSettle();

      // Verify PersonalInfoSettingsView is open
      expect(find.byType(PersonalInfoSettingsView), findsOneWidget);
      expect(find.text(AppStrings.personalInfoViewTitle), findsOneWidget);
    });
  });
}
