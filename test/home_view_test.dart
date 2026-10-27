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
import 'package:fuel_alloc_app/core/constants/app_strings.dart';
import 'package:fuel_alloc_app/views/home/home_view.dart';
import 'package:fuel_alloc_app/views/main_layout_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestWidget({Widget? child}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AccountsController()),
        ChangeNotifierProvider(create: (_) => StationsController()),
        ChangeNotifierProvider(create: (_) => TransactionsController()),
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => BackupController()),
        ChangeNotifierProvider(create: (_) => MessagingController()),
        ChangeNotifierProvider(create: (_) => PersonalInfoController()),
        ChangeNotifierProvider(create: (_) => AnalysisController()),
      ],
      child: MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const HomeView(),
        ),
      ),
    );
  }

  group('HomeView & Dashboard Integration Tests', () {
    testWidgets(
        '1. HomeView renders app header, backup status icon, supplier and station metrics cards, and quick actions',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // Header
      expect(find.text(AppStrings.appNameEn), findsOneWidget);

      // Backup status icon tooltip
      expect(find.byTooltip(AppStrings.backupTitle), findsOneWidget);

      // Year and Month Period Filter (defaults to real-world current year and month)
      final now = DateTime.now();
      expect(find.text(AppStrings.filterYear), findsOneWidget);
      expect(find.text('${now.year}'), findsOneWidget);
      expect(find.text(AppStrings.filterMonth), findsOneWidget);
      expect(find.text(AppStrings.getMonthLabel(now.month)), findsOneWidget);

      // Supplier Supply Quota Card (FuelSummaryCard style)
      expect(find.text(AppStrings.supplierSupplyTitle), findsOneWidget);
      expect(find.text(AppStrings.supplyQuota), findsOneWidget);
      expect(find.text(AppStrings.supplyActual), findsOneWidget);

      // Station Stock & Flow Card (FuelSummaryCard style)
      expect(find.text(AppStrings.stationBalanceAndFlow), findsOneWidget);
      expect(find.text(AppStrings.actualSupply), findsOneWidget);
      expect(find.text(AppStrings.actualDispense), findsOneWidget);
      expect(find.text(AppStrings.aerationCommission), findsOneWidget);

      // Quota Balance Card (FuelSummaryCard style)
      expect(find.text(AppStrings.quotaBalanceTitle), findsOneWidget);
      expect(find.text(AppStrings.dispenseQuota), findsOneWidget);
      expect(find.text(AppStrings.dispenseActual), findsOneWidget);
      expect(find.text(AppStrings.balanceQuota), findsNWidgets(2));

      // Percentages are now displayed in the dark oval badges on the 3 cards
      expect(find.text('0.0%'), findsNWidgets(3));

      // Quick Actions
      expect(find.text(AppStrings.quickActions), findsOneWidget);
      expect(find.text(AppStrings.quickDispenseActual), findsOneWidget);
      expect(find.text(AppStrings.quickSupplyActual), findsOneWidget);
      expect(find.text(AppStrings.quickTransfer), findsOneWidget);

      // Transactions Card
      expect(find.text(AppStrings.recentTransactions), findsOneWidget);
      expect(
          find.text(AppStrings.viewAllTransactionsAndAccounts), findsOneWidget);

      // Station Summary Card expands and displays station list below when tapped
      await tester.tap(find.text(AppStrings.stationBalanceAndFlow));
      await tester.pumpAndSettle();
      expect(find.byType(HomeView), findsOneWidget);
    });

    testWidgets('2. MainLayoutView initializes with HomeView at index 0',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(child: const MainLayoutView()));
      await tester.pump();

      // Should be on Home tab displaying Quick Actions and Dashboard
      expect(find.byType(HomeView), findsOneWidget);
      expect(find.text(AppStrings.quickActions), findsOneWidget);
    });
  });
}
