import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fuel_alloc_app/controllers/personal_info_controller.dart';
import 'package:fuel_alloc_app/controllers/reports_controller.dart';
import 'package:fuel_alloc_app/core/constants/app_strings.dart';
import 'package:fuel_alloc_app/models/account_model.dart';
import 'package:fuel_alloc_app/models/reconciliation_item_model.dart';
import 'package:fuel_alloc_app/models/statement_item_model.dart';
import 'package:fuel_alloc_app/models/transaction_model.dart';
import 'package:fuel_alloc_app/services/excel_report_service.dart';
import 'package:fuel_alloc_app/views/reports/report_preview_table_view.dart';
import 'package:fuel_alloc_app/views/reports/reports_view.dart';
import 'package:fuel_alloc_app/views/reports/widgets/export_options_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Reports & Reconciliation Models & Controller Unit Tests', () {
    test('1. StatementItemModel calculates running balances and flows correctly', () {
      final tx = TransactionModel(
        id: 1,
        transactionNumber: 'TX-001',
        transactionDate: '2026-10-25',
        typeId: 1,
        fuelTypeId: 1,
        fuelTypeName: 'بترول',
        unitId: 1,
        unitName: 'لتر',
        enteredQuantity: 5000,
        baseQuantityLiters: 5000,
      );

      final item = StatementItemModel(
        transaction: tx,
        runningBalance: 5000,
        inflow: 5000,
        outflow: 0,
      );

      expect(item.id, equals(1));
      expect(item.runningBalance, equals(5000));
      expect(item.inflow, equals(5000));
      expect(item.outflow, equals(0));
      expect(item.isPositive, isTrue);
      expect(item.isNegative, isFalse);
    });

    test('2. ReconciliationItemModel computes status and percentages accurately', () {
      const avail = ReconciliationItemModel(
        accountId: 1,
        accountName: 'شركة النفط اليمنية',
        accountType: 'SUPPLIER',
        fuelTypeId: 1,
        fuelTypeName: 'بترول',
        quota: 10000,
        actual: 4000,
        balance: 6000,
        ratio: 0.40,
      );
      expect(avail.status, equals(ReconciliationStatus.available));
      expect(avail.percent, equals(40.0));

      const warn = ReconciliationItemModel(
        accountId: 2,
        accountName: 'مورد حضرموت',
        accountType: 'SUPPLIER',
        fuelTypeId: 1,
        fuelTypeName: 'بترول',
        quota: 10000,
        actual: 8500,
        balance: 1500,
        ratio: 0.85,
      );
      expect(warn.status, equals(ReconciliationStatus.warning));
      expect(warn.percent, equals(85.0));

      const depleted = ReconciliationItemModel(
        accountId: 3,
        accountName: 'مورد منتهي',
        accountType: 'SUPPLIER',
        fuelTypeId: 1,
        fuelTypeName: 'بترول',
        quota: 5000,
        actual: 5000,
        balance: 0,
        ratio: 1.0,
      );
      expect(depleted.status, equals(ReconciliationStatus.depleted));
      expect(depleted.percent, equals(100.0));
    });

    test('3. ReportsController state updates category tabs and filters cleanly', () {
      final ctrl = ReportsController();
      expect(ctrl.selectedCategoryIndex, equals(0));

      ctrl.setCategoryIndex(1);
      expect(ctrl.selectedCategoryIndex, equals(1));

      ctrl.setStatementFilter('ACTUAL');
      expect(ctrl.statementFilter, equals('ACTUAL'));

      ctrl.setReconciliationSearch('البريقة');
      expect(ctrl.reconciliationSearch, equals('البريقة'));

      ctrl.setReconciliationStatusFilter(ReconciliationStatus.warning);
      expect(ctrl.reconciliationStatusFilter, equals(ReconciliationStatus.warning));
    });
  });

  group('Reports Views & UI Integration Tests', () {
    Widget createTestApp(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ReportsController()),
          ChangeNotifierProvider(create: (_) => PersonalInfoController()),
        ],
        child: MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: child,
          ),
        ),
      );
    }

    testWidgets('4. ReportsView renders One UI Accordion structure matching Screenshot 1',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(const ReportsView()));
      await tester.pump();

      // Verify AppBar title is 'التقارير'
      expect(find.text(AppStrings.navReports), findsOneWidget);

      // Verify Accordion sections
      expect(find.text(AppStrings.categoryStatements), findsOneWidget);
      expect(find.text(AppStrings.categoryReconciliations), findsOneWidget);
      expect(find.text(AppStrings.categoryMovements), findsOneWidget);
      expect(find.text(AppStrings.categoryAnalytics), findsOneWidget);

      // Verify inner report items in expanded accordion
      expect(find.text(AppStrings.reportSupplierStatementTitle), findsOneWidget);
      expect(find.text(AppStrings.reportStationStatementTitle), findsOneWidget);
      expect(find.text(AppStrings.reportBeneficiaryStatementTitle), findsOneWidget);
    });

    testWidgets('5. ExportOptionsSheet displays PDF and Excel options matching Screenshot 3',
        (tester) async {
      ExportFormat? selectedFormat;

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    selectedFormat = await ExportOptionsSheet.show(context: context);
                  },
                  child: const Text('Open Export'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Export'));
      await tester.pumpAndSettle();

      // Header title: 'تصدير كـ'
      expect(find.text(AppStrings.exportAs), findsOneWidget);

      // Options: 'تصدير الى ملف Pdf' and 'تصدير الى ملف Excel'
      expect(find.text(AppStrings.exportToPdf), findsOneWidget);
      expect(find.text(AppStrings.exportToExcel), findsOneWidget);

      // Tap on PDF export
      await tester.tap(find.text(AppStrings.exportToPdf));
      await tester.pumpAndSettle();

      expect(selectedFormat, equals(ExportFormat.pdf));
    });

    testWidgets('6. ReportPreviewTableView renders official table header and actions matching Screenshots 2 & 3',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(
        const ReportPreviewTableView(
          accountType: AccountType.supplier,
          visibleColumns: {'date', 'txNumber', 'type', 'notes', 'inflow', 'outflow', 'balance'},
        ),
      ));
      await tester.pump();

      // Verify Title
      expect(find.text(AppStrings.reportSupplierStatementTitle), findsOneWidget);

      // Verify Action buttons: [فلتر] and [تصدير]
      expect(find.text(AppStrings.filterBtn), findsOneWidget);
      expect(find.text(AppStrings.exportBtn), findsOneWidget);

      // Verify initial empty state placeholder with instructions
      expect(find.text(AppStrings.noStatementTransactions), findsOneWidget);
    });

    test('7. Enforce zero raw Color(0x...) in lib/views/reports/', () {
      final reportsDir = Directory('lib/views/reports');
      expect(reportsDir.existsSync(), isTrue);

      final dartFiles = reportsDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();

      final colorRegex = RegExp(r'Color\(0x[0-9a-fA-F]+\)');
      final violations = <String>[];

      for (final file in dartFiles) {
        final lines = file.readAsLinesSync();
        for (int i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (colorRegex.hasMatch(line)) {
            violations.add('${file.path}:${i + 1}: ${line.trim()}');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Forbidden raw Color() calls found in reports views! All colors must use AppColors:\n${violations.join('\n')}',
      );
    });

    test('8. ExcelReportService generates valid non-empty byte list', () async {
      final tx = TransactionModel(
        id: 101,
        transactionNumber: 'TX-2026',
        transactionDate: '2026-10-28',
        typeId: 1,
        typeName: 'توريد فعلي',
        fuelTypeId: 1,
        fuelTypeName: 'بترول',
        unitId: 1,
        unitName: 'لتر',
        enteredQuantity: 5000,
        baseQuantityLiters: 5000,
      );

      final items = [
        StatementItemModel(
          transaction: tx,
          runningBalance: 5000,
          inflow: 5000,
          outflow: 0,
        ),
      ];

      final excelBytes = await ExcelReportService.generateStatementExcel(
        reportTitle: 'كشف حساب مورد',
        accountName: 'مؤسسة النفط الحديثة',
        fuelTypeName: 'بترول',
        periodText: 'جميع الفترات',
        items: items,
        visibleColumns: {'date', 'txNumber', 'type', 'notes', 'inflow', 'outflow', 'balance'},
        totalInflow: 5000,
        totalOutflow: 0,
        currentBalance: 5000,
      );

      expect(excelBytes, isNotNull);
      expect(excelBytes.isNotEmpty, isTrue);
    });
  });
}
