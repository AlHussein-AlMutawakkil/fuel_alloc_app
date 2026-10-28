import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/constants/app_strings.dart';
import '../core/utils/formatters.dart';
import '../models/personal_info_model.dart';
import '../models/reconciliation_item_model.dart';
import '../models/statement_item_model.dart';

/// خدمة إنشاء وطباعة ومشاركة تقارير PDF الرسمية
class PdfReportService {
  PdfReportService._();

  static pw.Font? _cairoRegular;
  static pw.Font? _cairoBold;

  /// تحميل خط Cairo المعتمد لدعم اللغة العربية في الـ PDF
  static Future<void> _loadFonts() async {
    if (_cairoRegular != null && _cairoBold != null) return;
    final regularData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
    _cairoRegular = pw.Font.ttf(regularData);
    _cairoBold = pw.Font.ttf(boldData);
  }

  /// إنشاء ملف PDF رسمي لكشف حساب (مورد / محطة / مستفيد)
  static Future<Uint8List> generateStatementPdf({
    required String reportTitle,
    required String accountName,
    String? accountPhone,
    String? location,
    required String periodText,
    required String fuelTypeName,
    required List<StatementItemModel> items,
    required PersonalInfoModel personalInfo,
    double? totalInflow,
    double? totalOutflow,
    double? currentBalance,
  }) async {
    await _loadFonts();
    final doc = pw.Document();

    // تجهيز صور الشعار والختم والتوقيع إن وجدت
    pw.MemoryImage? logoImage;
    pw.MemoryImage? stampImage;
    pw.MemoryImage? signatureImage;

    try {
      if (personalInfo.logoPath != null && File(personalInfo.logoPath!).existsSync()) {
        final bytes = await File(personalInfo.logoPath!).readAsBytes();
        logoImage = pw.MemoryImage(bytes);
      }
      if (personalInfo.stampPath != null && File(personalInfo.stampPath!).existsSync()) {
        final bytes = await File(personalInfo.stampPath!).readAsBytes();
        stampImage = pw.MemoryImage(bytes);
      }
      if (personalInfo.signaturePath != null && File(personalInfo.signaturePath!).existsSync()) {
        final bytes = await File(personalInfo.signaturePath!).readAsBytes();
        signatureImage = pw.MemoryImage(bytes);
      }
    } catch (_) {}

    final nowStr = AppFormatters.formatTransactionDateTime(DateTime.now().toIso8601String());

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: _cairoRegular,
          bold: _cairoBold,
        ),
        margin: const pw.EdgeInsets.all(24),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ترويسة المنشأة
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logoImage != null)
                    pw.Container(
                      width: 55,
                      height: 55,
                      child: pw.Image(logoImage),
                    )
                  else
                    pw.SizedBox(width: 55),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        personalInfo.arabicName.isNotEmpty ? personalInfo.arabicName : AppStrings.appTitle,
                        style: pw.TextStyle(
                          font: _cairoBold,
                          fontSize: 14,
                          color: PdfColors.blueGrey900,
                        ),
                      ),
                      if (personalInfo.arabicAddress.isNotEmpty)
                        pw.Text(
                          personalInfo.arabicAddress,
                          style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                        ),
                      if (personalInfo.contactNumbers.isNotEmpty)
                        pw.Text(
                          personalInfo.contactNumbers,
                          style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                        ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        AppStrings.officialDocument,
                        style: pw.TextStyle(
                          font: _cairoBold,
                          fontSize: 9,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.Text(
                        nowStr,
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 1, color: PdfColors.blueGrey200),
              pw.SizedBox(height: 6),

              // عنوان التقرير وشريط بيانات الحساب
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.blueGrey50,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      reportTitle,
                      style: pw.TextStyle(
                        font: _cairoBold,
                        fontSize: 12,
                        color: PdfColors.blueGrey900,
                      ),
                    ),
                    pw.Text(
                      '${AppStrings.accountName}: $accountName',
                      style: pw.TextStyle(
                        font: _cairoBold,
                        fontSize: 10,
                        color: PdfColors.blueGrey800,
                      ),
                    ),
                    pw.Text(
                      '${AppStrings.fuelTypeCol}: $fuelTypeName',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey700),
                    ),
                    pw.Text(
                      '${AppStrings.statementPeriod}: $periodText',
                      style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.blueGrey700),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    AppStrings.generatedAutomatically,
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'صفحة ${context.pageNumber} من ${context.pagesCount}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                  ),
                ],
              ),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            // بطاقة ملخص الأرصدة
            if (totalInflow != null || totalOutflow != null || currentBalance != null)
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    if (totalInflow != null)
                      _buildSummaryColumn('إجمالي الوارد / الاعتماد', totalInflow, PdfColors.green800),
                    if (totalOutflow != null)
                      _buildSummaryColumn('إجمالي المنصرف / الفعلي', totalOutflow, PdfColors.red800),
                    if (currentBalance != null)
                      _buildSummaryColumn('الرصيد النهائي الحالي', currentBalance, PdfColors.blue900),
                  ],
                ),
              ),

            // جدول العمليات التفصيلي
            if (items.isEmpty)
              pw.Center(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(30),
                  child: pw.Text(
                    AppStrings.noStatementTransactions,
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ),
              )
            else
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: const {
                  0: pw.FixedColumnWidth(20), // م
                  1: pw.FixedColumnWidth(48), // التاريخ
                  2: pw.FixedColumnWidth(50), // رقم القيد
                  3: pw.FlexColumnWidth(1.4), // البيان
                  4: pw.FixedColumnWidth(42), // الصنف
                  5: pw.FixedColumnWidth(42), // الكمية
                  6: pw.FlexColumnWidth(1.1), // المحطة
                  7: pw.FlexColumnWidth(1.1), // المستلم
                  8: pw.FixedColumnWidth(50), // الرصيد الجاري
                },
                children: [
                  // ترويسة الجدول
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                    children: [
                      _buildTableHeader(AppStrings.serialCol),
                      _buildTableHeader(AppStrings.dateCol),
                      _buildTableHeader(AppStrings.txNumberCol),
                      _buildTableHeader(AppStrings.operationCol),
                      _buildTableHeader(AppStrings.fuelTypeCol),
                      _buildTableHeader(AppStrings.quantityCol),
                      _buildTableHeader(AppStrings.station),
                      _buildTableHeader(AppStrings.recipientCol),
                      _buildTableHeader(AppStrings.runningBalanceCol),
                    ],
                  ),

                  // صفوف البيانات
                  ...List.generate(items.length, (index) {
                    final item = items[index];
                    final isEven = index % 2 == 0;
                    final rowBg = isEven ? PdfColors.white : PdfColors.grey50;

                    final String qtyDisplay =
                        '${AppFormatters.formatQuantity(item.enteredQuantity)} ${item.unitName ?? ''}';
                    final String recipientText = item.recipientName?.isNotEmpty == true
                        ? item.recipientName!
                        : (item.referenceNumber ?? '-');

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(color: rowBg),
                      children: [
                        _buildTableCell('${index + 1}', align: pw.TextAlign.center),
                        _buildTableCell(item.transactionDate, align: pw.TextAlign.center),
                        _buildTableCell(item.transactionNumber ?? '-', align: pw.TextAlign.center),
                        _buildTableCell(item.typeName ?? '-', align: pw.TextAlign.right),
                        _buildTableCell(item.fuelTypeName ?? '-', align: pw.TextAlign.center),
                        _buildTableCell(qtyDisplay, align: pw.TextAlign.center),
                        _buildTableCell(item.stationName ?? '-', align: pw.TextAlign.center),
                        _buildTableCell(recipientText, align: pw.TextAlign.center),
                        _buildTableCell(
                          AppFormatters.formatQuantity(item.runningBalance),
                          align: pw.TextAlign.center,
                          bold: true,
                        ),
                      ],
                    );
                  }),
                ],
              ),

            pw.SizedBox(height: 20),

            // خانة الختم والتوقيع
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      AppStrings.authorizedSignature,
                      style: pw.TextStyle(font: _cairoBold, fontSize: 9, color: PdfColors.grey800),
                    ),
                    pw.SizedBox(height: 8),
                    if (signatureImage != null)
                      pw.Container(width: 80, height: 40, child: pw.Image(signatureImage))
                    else
                      pw.Container(
                        width: 90,
                        height: 35,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300, style: pw.BorderStyle.dashed),
                        ),
                      ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      AppStrings.officialStamp,
                      style: pw.TextStyle(font: _cairoBold, fontSize: 9, color: PdfColors.grey800),
                    ),
                    pw.SizedBox(height: 8),
                    if (stampImage != null)
                      pw.Container(width: 60, height: 40, child: pw.Image(stampImage))
                    else
                      pw.Container(
                        width: 70,
                        height: 35,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300, style: pw.BorderStyle.dashed),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return doc.save();
  }

  /// إنشاء ملف PDF رسمي لتقرير المطابقة والمراقبة
  static Future<Uint8List> generateReconciliationPdf({
    required String reportTitle,
    required String fuelTypeName,
    required List<ReconciliationItemModel> items,
    required PersonalInfoModel personalInfo,
  }) async {
    await _loadFonts();
    final doc = pw.Document();

    pw.MemoryImage? logoImage;
    try {
      if (personalInfo.logoPath != null && File(personalInfo.logoPath!).existsSync()) {
        final bytes = await File(personalInfo.logoPath!).readAsBytes();
        logoImage = pw.MemoryImage(bytes);
      }
    } catch (_) {}

    final nowStr = AppFormatters.formatTransactionDateTime(DateTime.now().toIso8601String());

    double totalQuota = 0.0;
    double totalActual = 0.0;
    double totalBalance = 0.0;

    for (final it in items) {
      totalQuota += it.quota;
      totalActual += it.actual;
      totalBalance += it.balance;
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape, // اتجاه أفقي للتقارير الشاملة
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: _cairoRegular,
          bold: _cairoBold,
        ),
        margin: const pw.EdgeInsets.all(20),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  if (logoImage != null)
                    pw.Container(width: 45, height: 45, child: pw.Image(logoImage))
                  else
                    pw.SizedBox(width: 45),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        personalInfo.arabicName.isNotEmpty ? personalInfo.arabicName : AppStrings.appTitle,
                        style: pw.TextStyle(font: _cairoBold, fontSize: 13, color: PdfColors.blueGrey900),
                      ),
                      pw.Text(
                        reportTitle,
                        style: pw.TextStyle(font: _cairoBold, fontSize: 11, color: PdfColors.blue800),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('${AppStrings.fuelTypeCol}: $fuelTypeName',
                          style: pw.TextStyle(font: _cairoBold, fontSize: 9)),
                      pw.Text(nowStr, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 1, color: PdfColors.blueGrey200),
              pw.SizedBox(height: 6),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(AppStrings.generatedAutomatically,
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
              pw.Text('صفحة ${context.pageNumber} من ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            // بطاقة الملخص الإجمالي
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              decoration: pw.BoxDecoration(
                color: PdfColors.blueGrey50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Text('إجمالي الاعتمادات/الوارد: ${AppFormatters.formatQuantity(totalQuota)} لتر',
                      style: pw.TextStyle(font: _cairoBold, fontSize: 9, color: PdfColors.blueGrey900)),
                  pw.Text('إجمالي الفعلي/المنصرف: ${AppFormatters.formatQuantity(totalActual)} لتر',
                      style: pw.TextStyle(font: _cairoBold, fontSize: 9, color: PdfColors.green900)),
                  pw.Text('إجمالي الرصيد/المخزون: ${AppFormatters.formatQuantity(totalBalance)} لتر',
                      style: pw.TextStyle(font: _cairoBold, fontSize: 9, color: PdfColors.blue900)),
                ],
              ),
            ),

            // جدول المطابقة
            if (items.isEmpty)
              pw.Center(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(30),
                  child: pw.Text(AppStrings.noReconciliationData,
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                ),
              )
            else
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: const {
                  0: pw.FixedColumnWidth(24), // م
                  1: pw.FlexColumnWidth(2.5), // اسم الحساب
                  2: pw.FixedColumnWidth(60), // صنف الوقود
                  3: pw.FixedColumnWidth(65), // الاعتماد
                  4: pw.FixedColumnWidth(65), // الفعلي
                  5: pw.FixedColumnWidth(70), // الرصيد المتبقي
                  6: pw.FixedColumnWidth(55), // نسبة الإنجاز
                  7: pw.FixedColumnWidth(55), // الحالة
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                    children: [
                      _buildTableHeader(AppStrings.serialCol),
                      _buildTableHeader(AppStrings.accountName),
                      _buildTableHeader(AppStrings.fuelTypeCol),
                      _buildTableHeader(AppStrings.quotaCol),
                      _buildTableHeader(AppStrings.actualCol),
                      _buildTableHeader(AppStrings.remainingCol),
                      _buildTableHeader(AppStrings.ratioCol),
                      _buildTableHeader(AppStrings.statusCol),
                    ],
                  ),
                  ...List.generate(items.length, (index) {
                    final item = items[index];
                    final isEven = index % 2 == 0;
                    final rowBg = isEven ? PdfColors.white : PdfColors.grey50;

                    String statusLabel;
                    PdfColor statusColor;
                    if (item.status == ReconciliationStatus.available) {
                      statusLabel = AppStrings.statusAvailable;
                      statusColor = PdfColors.green800;
                    } else if (item.status == ReconciliationStatus.warning) {
                      statusLabel = AppStrings.statusWarning;
                      statusColor = PdfColors.amber800;
                    } else {
                      statusLabel = AppStrings.statusDepleted;
                      statusColor = PdfColors.red800;
                    }

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(color: rowBg),
                      children: [
                        _buildTableCell('${index + 1}', align: pw.TextAlign.center),
                        _buildTableCell(item.accountName, align: pw.TextAlign.right, bold: true),
                        _buildTableCell(item.fuelTypeName, align: pw.TextAlign.center),
                        _buildTableCell(AppFormatters.formatQuantity(item.quota), align: pw.TextAlign.center),
                        _buildTableCell(AppFormatters.formatQuantity(item.actual), align: pw.TextAlign.center),
                        _buildTableCell(AppFormatters.formatQuantity(item.balance), align: pw.TextAlign.center, bold: true),
                        _buildTableCell('${item.percent.toStringAsFixed(1)}%', align: pw.TextAlign.center),
                        _buildTableCell(statusLabel, align: pw.TextAlign.center, textColor: statusColor),
                      ],
                    );
                  }),
                ],
              ),
          ];
        },
      ),
    );

    return doc.save();
  }

  /// إطلاق نافذة الطباعة المباشرة ومعاينة المستند
  static Future<void> printDocument({
    required Uint8List pdfBytes,
    required String documentName,
  }) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: documentName,
    );
  }

  /// مشاركة ملف الـ PDF عبر تطبيقات الجهاز
  static Future<void> shareDocument({
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: '$fileName.pdf',
    );
  }

  // --- عناصر مساعدة للتنسيق والواجهات الداخلية ---

  static pw.Widget _buildTableHeader(String text) {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 3),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: _cairoBold,
          fontSize: 8.5,
          color: PdfColors.white,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.right,
    bool bold = false,
    PdfColor textColor = PdfColors.black,
  }) {
    return pw.Container(
      alignment: align == pw.TextAlign.center
          ? pw.Alignment.center
          : (align == pw.TextAlign.right ? pw.Alignment.centerRight : pw.Alignment.centerLeft),
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: bold ? _cairoBold : _cairoRegular,
          fontSize: 8,
          color: textColor,
        ),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _buildSummaryColumn(String title, double value, PdfColor valueColor) {
    return pw.Column(
      children: [
        pw.Text(
          title,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          '${AppFormatters.formatQuantity(value)} لتر',
          style: pw.TextStyle(font: _cairoBold, fontSize: 10, color: valueColor),
        ),
      ],
    );
  }
}

