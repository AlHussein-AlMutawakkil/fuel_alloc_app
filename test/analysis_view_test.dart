import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fuel_alloc_app/controllers/accounts_controller.dart';
import 'package:fuel_alloc_app/controllers/analysis_controller.dart';
import 'package:fuel_alloc_app/controllers/auth_controller.dart';
import 'package:fuel_alloc_app/controllers/backup_controller.dart';
import 'package:fuel_alloc_app/controllers/messaging_controller.dart';
import 'package:fuel_alloc_app/controllers/personal_info_controller.dart';
import 'package:fuel_alloc_app/controllers/stations_controller.dart';
import 'package:fuel_alloc_app/controllers/transactions_controller.dart';
import 'package:fuel_alloc_app/core/constants/app_icons.dart';
import 'package:fuel_alloc_app/core/constants/app_strings.dart';
import 'package:fuel_alloc_app/data/repositories/analysis_repository.dart';
import 'package:fuel_alloc_app/views/settings/analysis_view.dart';
import 'package:fuel_alloc_app/views/settings/settings_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sampleData = AnalysisData(
    isDatabaseIntact: true,
    databaseSizeString: '128 KB',
    totalDatabaseRecords: 45,
    consistencyIssues: [],
    totalAccounts: 12,
    activeAccounts: 10,
    beneficiariesCount: 8,
    stationsCount: 2,
    suppliersCount: 2,
    archivedAccounts: 1,
    deletedAccounts: 1,
    fuelTypesCount: 2,
    fuelTypesDetails: [
      {'name': 'بترول', 'tx_count': 15, 'total_liters': 3500.0},
      {'name': 'ديزل', 'tx_count': 10, 'total_liters': 2200.0},
    ],
    unitsCount: 2,
    unitsDetails: [
      {'name': 'لتر', 'tx_count': 20, 'conversion_factor': 1.0, 'is_base_unit': 1},
      {'name': 'برميل', 'tx_count': 5, 'conversion_factor': 200.0, 'is_base_unit': 0},
    ],
    totalTransactions: 25,
    activeTransactions: 23,
    deletedTransactions: 2,
    supplyQuotaCount: 6,
    supplyQuotaTotalLiters: 6000.0,
    dispenseQuotaCount: 4,
    dispenseQuotaTotalLiters: 4000.0,
    supplyActualCount: 5,
    supplyActualTotalLiters: 5000.0,
    dispenseActualCount: 8,
    dispenseActualTotalLiters: 4500.0,
    aerationCount: 2,
    aerationTotalLiters: 90.0,
    transferCount: 0,
    transferTotalLiters: 0.0,
  );

  Widget buildTestApp(Widget child, {AnalysisData? initialData}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AccountsController()),
        ChangeNotifierProvider(create: (_) => StationsController()),
        ChangeNotifierProvider(create: (_) => TransactionsController()),
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => BackupController()),
        ChangeNotifierProvider(create: (_) => MessagingController()),
        ChangeNotifierProvider(create: (_) => PersonalInfoController()),
        ChangeNotifierProvider(
          create: (_) => AnalysisController(initialData: initialData ?? sampleData),
        ),
      ],
      child: MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: child,
        ),
      ),
    );
  }

  group('Analysis Feature & Settings Tile Integration Tests', () {
    testWidgets(
        '1. SettingsView renders Analysis tile right below Personal Info inside the same card',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestApp(const SettingsView()));
      await tester.pumpAndSettle();

      // Verify Personal Info tile exists
      final personalInfoFinder = find.text(AppStrings.personalInfo);
      expect(personalInfoFinder, findsOneWidget);

      // Verify Analysis tile exists
      final analysisFinder = find.text(AppStrings.analysis);
      expect(analysisFinder, findsOneWidget);

      // Verify Analysis icon is rendered
      expect(find.byIcon(AppIcons.analytics), findsOneWidget);
    });

    testWidgets(
        '2. Tapping Analysis tile in SettingsView navigates to AnalysisView seamlessly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestApp(const SettingsView()));
      await tester.pumpAndSettle();

      // Tap the Analysis tile
      final analysisFinder = find.text(AppStrings.analysis);
      await tester.tap(analysisFinder);
      await tester.pumpAndSettle();

      // Verify AnalysisView is rendered with its title in OneUiAppBar
      expect(find.byType(AnalysisView), findsOneWidget);
      expect(find.text(AppStrings.analysisTitle), findsOneWidget);
    });

    testWidgets(
        '3. AnalysisView renders all One UI diagnostic and breakdown cards correctly including supply quota and dispense quota',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestApp(const AnalysisView()));
      await tester.pumpAndSettle();

      // 1. Health Card
      expect(find.text(AppStrings.systemHealthStatus), findsOneWidget);
      expect(find.text(AppStrings.systemHealthExcellent), findsOneWidget);
      expect(find.text(AppStrings.runDiagnostics), findsOneWidget);

      // 2. Database & Storage Card
      expect(find.text(AppStrings.databaseIntegrity), findsOneWidget);
      expect(find.text(AppStrings.databaseIntegrityOk), findsOneWidget);
      expect(find.text(AppStrings.databaseSize), findsOneWidget);
      expect(find.text(AppStrings.totalDatabaseRecords), findsOneWidget);

      // 3. Accounts Breakdown Card
      expect(find.text(AppStrings.totalAccountsCount), findsOneWidget);
      expect(find.text(AppStrings.beneficiariesCount), findsOneWidget);
      expect(find.text(AppStrings.stationsCount), findsOneWidget);
      expect(find.text(AppStrings.suppliersCount), findsOneWidget);
      expect(find.text(AppStrings.archivedAccountsCount), findsOneWidget);
      expect(find.text(AppStrings.deletedAccounts), findsOneWidget);

      // 4. Transactions Breakdown Card (Explicit separation of quotas and actuals)
      expect(find.text(AppStrings.totalTransactionsCount), findsOneWidget);
      expect(find.text(AppStrings.supplyQuotaTransactionsTitle), findsOneWidget);
      expect(find.text(AppStrings.dispenseQuotaTransactionsTitle), findsOneWidget);
      expect(find.text(AppStrings.supplyActualTransactionsTitle), findsOneWidget);
      expect(find.text(AppStrings.dispenseActualTransactionsTitle), findsOneWidget);
      expect(find.text(AppStrings.aerationTransactionsTitle), findsOneWidget);
      expect(find.text(AppStrings.transferTransactionsTitle), findsOneWidget);
      expect(find.text(AppStrings.deletedTransactionsCount), findsOneWidget);

      // 5. Fuel Types & Units Card
      expect(find.text(AppStrings.fuelTypesCount), findsOneWidget);
      expect(find.text(AppStrings.unitsCount), findsOneWidget);
      expect(find.text('بترول'), findsOneWidget);
      expect(find.text('ديزل'), findsOneWidget);
      expect(find.text('لتر'), findsOneWidget);
      expect(find.text('برميل'), findsOneWidget);
    });

    test('4. Analysis tokens in AppStrings and AppIcons are defined properly', () {
      expect(AppStrings.analysis, equals('التحليل'));
      expect(AppStrings.analysisTitle, isNotEmpty);
      expect(AppStrings.systemHealthStatus, isNotEmpty);
      expect(AppStrings.runDiagnostics, isNotEmpty);
      expect(AppStrings.databaseIntegrity, isNotEmpty);
      expect(AppStrings.totalAccountsCount, isNotEmpty);
      expect(AppStrings.totalTransactionsCount, isNotEmpty);
      expect(AppStrings.supplyQuotaTransactionsTitle, equals('توريد اعتماد'));
      expect(AppStrings.dispenseQuotaTransactionsTitle, equals('صرف اعتماد'));
      expect(AppStrings.supplyActualTransactionsTitle, equals('توريد فعلي'));
      expect(AppStrings.dispenseActualTransactionsTitle, equals('صرف فعلي'));
      expect(AppIcons.analytics, isNotNull);
      expect(AppIcons.healthAndSafety, isNotNull);
    });
  });
}
