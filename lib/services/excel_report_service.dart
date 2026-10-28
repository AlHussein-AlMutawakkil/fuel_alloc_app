import 'dart:typed_data';
import 'package:excel/excel.dart';
import '../core/constants/app_strings.dart';
import '../core/utils/formatters.dart';
import '../models/statement_item_model.dart';

/// خدمة تصدير تقارير الإكسل بصيغة XLSX الرسمية
class ExcelReportService {
  ExcelReportService._();

  /// إنشاء ملف Excel لكشف الحساب
  static Future<Uint8List> generateStatementExcel({
    required String reportTitle,
    required String accountName,
    required String fuelTypeName,
    required String periodText,
    required List<StatementItemModel> items,
    required Set<String> visibleColumns,
    double? totalInflow,
    double? totalOutflow,
    double? currentBalance,
  }) async {
    final excel = Excel.createExcel();
    final sheetName = excel.getDefaultSheet() ?? 'Sheet1';
    final sheet = excel[sheetName];
    sheet.isRTL = true;

    // 1. ترويسة التقرير
    sheet.appendRow([TextCellValue(reportTitle)]);
    sheet.appendRow([TextCellValue('${AppStrings.accountName}: $accountName')]);
    sheet.appendRow([TextCellValue('${AppStrings.colFuelType}: $fuelTypeName')]);
    sheet.appendRow([TextCellValue('${AppStrings.statementPeriod}: $periodText')]);
    sheet.appendRow([TextCellValue('')]); // سطر فارغ

    // 2. ترويسة الأعمدة بحسب ما اختاره المستخدم
    final List<CellValue> headers = [];
    headers.add(TextCellValue(AppStrings.serialCol));
    if (visibleColumns.contains('date')) headers.add(TextCellValue(AppStrings.colDate));
    if (visibleColumns.contains('txNumber')) headers.add(TextCellValue(AppStrings.colTxNumber));
    if (visibleColumns.contains('type')) headers.add(TextCellValue(AppStrings.colType));
    if (visibleColumns.contains('fuelType')) headers.add(TextCellValue(AppStrings.colFuelType));
    if (visibleColumns.contains('quantity')) headers.add(TextCellValue(AppStrings.colQuantity));
    if (visibleColumns.contains('unit')) headers.add(TextCellValue(AppStrings.colUnit));
    if (visibleColumns.contains('station')) headers.add(TextCellValue(AppStrings.stationCol));
    if (visibleColumns.contains('recipient')) headers.add(TextCellValue(AppStrings.recipientCol));
    if (visibleColumns.contains('party')) headers.add(TextCellValue(AppStrings.colParty));
    if (visibleColumns.contains('notes')) headers.add(TextCellValue(AppStrings.colNotes));
    if (visibleColumns.contains('balance')) headers.add(TextCellValue(AppStrings.colBalance));

    sheet.appendRow(headers);

    // 3. سطور البيانات
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final List<CellValue> row = [];
      row.add(IntCellValue(i + 1));

      if (visibleColumns.contains('date')) {
        row.add(TextCellValue(item.transactionDate));
      }
      if (visibleColumns.contains('txNumber')) {
        row.add(TextCellValue(item.transactionNumber ?? '-'));
      }
      if (visibleColumns.contains('type')) {
        row.add(TextCellValue(item.typeName ?? '-'));
      }
      if (visibleColumns.contains('fuelType')) {
        row.add(TextCellValue(item.fuelTypeName ?? '-'));
      }
      if (visibleColumns.contains('quantity')) {
        row.add(DoubleCellValue(item.enteredQuantity));
      }
      if (visibleColumns.contains('unit')) {
        row.add(TextCellValue(item.unitName ?? '-'));
      }
      if (visibleColumns.contains('station')) {
        row.add(TextCellValue(item.stationName ?? '-'));
      }
      if (visibleColumns.contains('recipient')) {
        row.add(TextCellValue(item.recipientName ?? '-'));
      }
      if (visibleColumns.contains('party')) {
        final party = item.recipientName?.isNotEmpty == true
            ? item.recipientName!
            : (item.stationName ?? item.referenceNumber ?? '-');
        row.add(TextCellValue(party));
      }
      if (visibleColumns.contains('notes')) {
        row.add(TextCellValue(item.notes ?? ''));
      }
      if (visibleColumns.contains('balance')) {
        row.add(DoubleCellValue(item.runningBalance));
      }

      sheet.appendRow(row);
    }

    // 4. صف الإجماليات
    sheet.appendRow([TextCellValue('')]);
    if (totalInflow != null || totalOutflow != null || currentBalance != null) {
      sheet.appendRow([
        TextCellValue(AppStrings.totalSummaryRow),
        TextCellValue('إجمالي الوارد: ${AppFormatters.formatQuantity(totalInflow ?? 0)}'),
        TextCellValue('إجمالي المنصرف: ${AppFormatters.formatQuantity(totalOutflow ?? 0)}'),
        TextCellValue('الرصيد النهائي: ${AppFormatters.formatQuantity(currentBalance ?? 0)}'),
      ]);
    }

    final fileBytes = excel.save();
    return Uint8List.fromList(fileBytes ?? []);
  }
}

