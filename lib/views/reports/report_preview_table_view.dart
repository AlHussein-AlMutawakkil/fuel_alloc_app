import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/personal_info_controller.dart';
import '../../controllers/reports_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/one_ui_card.dart';
import '../../models/account_model.dart';
import '../../models/statement_item_model.dart';
import '../../models/station_model.dart';
import '../../services/excel_report_service.dart';
import '../../services/pdf_report_service.dart';
import 'widgets/export_options_sheet.dart';
import 'widgets/report_filter_sheet.dart';

/// واجهة معاينة التقرير بالجدول الرسمي المعتمد (مع زري فلتر وتصدير)
class ReportPreviewTableView extends StatefulWidget {
  final AccountType accountType;
  final AccountModel? initialAccount;
  final StationModel? initialStation;
  final int? initialFuelTypeId;
  final String initialOperationType;
  final DateTime? initialFromDate;
  final DateTime? initialToDate;
  final Set<String> visibleColumns;

  const ReportPreviewTableView({
    super.key,
    required this.accountType,
    this.initialAccount,
    this.initialStation,
    this.initialFuelTypeId,
    this.initialOperationType = 'ALL',
    this.initialFromDate,
    this.initialToDate,
    required this.visibleColumns,
  });

  @override
  State<ReportPreviewTableView> createState() => _ReportPreviewTableViewState();
}

class _ReportPreviewTableViewState extends State<ReportPreviewTableView> {
  late AccountModel? _account;
  late StationModel? _station;
  late int? _fuelTypeId;
  late String _operationType;
  late DateTime? _fromDate;
  late DateTime? _toDate;
  late Set<String> _visibleColumns;

  @override
  void initState() {
    super.initState();
    _account = widget.initialAccount;
    _station = widget.initialStation;
    _fuelTypeId = widget.initialFuelTypeId;
    _operationType = widget.initialOperationType;
    _fromDate = widget.initialFromDate;
    _toDate = widget.initialToDate;
    _visibleColumns = Set<String>.from(widget.visibleColumns);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyFiltersToController();
    });
  }

  void _applyFiltersToController() {
    final ctrl = context.read<ReportsController>();
    if (widget.accountType == AccountType.station) {
      if (_station != null) ctrl.setSelectedStation(_station);
    } else {
      if (_account != null) ctrl.setSelectedAccount(_account);
    }
    ctrl.setStatementFuelTypeId(_fuelTypeId);
    ctrl.setStatementFilter(_operationType);
    ctrl.setStatementDateRange(_fromDate, _toDate);
  }

  String get _reportTitle {
    switch (widget.accountType) {
      case AccountType.supplier:
        return AppStrings.reportSupplierStatementTitle;
      case AccountType.station:
        return AppStrings.reportStationStatementTitle;
      case AccountType.beneficiary:
        return AppStrings.reportBeneficiaryStatementTitle;
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _getPeriodText() {
    if (_fromDate != null && _toDate != null) {
      return 'من ${_formatDate(_fromDate)} إلى ${_formatDate(_toDate)}';
    } else if (_fromDate != null) {
      return 'من ${_formatDate(_fromDate)}';
    } else if (_toDate != null) {
      return 'حتى ${_formatDate(_toDate)}';
    }
    return AppStrings.allDates;
  }

  String _getFuelTypeName(ReportsController ctrl) {
    if (_fuelTypeId == null) return AppStrings.selectFuelType;
    final match = ctrl.fuelTypes.firstWhere(
      (f) => f['id'] == _fuelTypeId,
      orElse: () => {'name': ''},
    );
    return match['name'] ?? '';
  }

  String _getOperationTypeLabel() {
    switch (_operationType) {
      case 'QUOTA':
        return AppStrings.tabQuota;
      case 'ACTUAL':
        return AppStrings.tabActual;
      case 'TRANSFER':
        return AppStrings.tabTransfer;
      case 'SUPPLY':
        return AppStrings.supplyTransactionsTitle;
      case 'DISPENSE':
        return AppStrings.dispenseTransactionsTitle;
      case 'AERATION':
        return AppStrings.aerationTransactionsTitle;
      default:
        return AppStrings.allOperations;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportsCtrl = context.watch<ReportsController>();
    final items = reportsCtrl.statementItems;
    final isLoading = reportsCtrl.isStatementLoading;

    final accountName = _station?.name ?? _account?.name ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: OneUiAppBar(
        title: _reportTitle,
        showBackButton: true,
        actions: [
          // 1. زر "فلتر" (مطابق للصور المرفقة)
          _buildAppBarActionButton(
            label: AppStrings.filterBtn,
            icon: AppIcons.filterAction,
            onTap: () => _openFilterSheet(context),
          ),
          const SizedBox(width: AppDimensions.spaceXS),

          // 2. زر "تصدير" (مطابق للصور المرفقة)
          _buildAppBarActionButton(
            label: AppStrings.exportBtn,
            icon: AppIcons.exportAction,
            onTap: () => _openExportSheet(reportsCtrl),
          ),
          const SizedBox(width: AppDimensions.spaceM),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // كرت تفاصيل الحساب والفلترة الحالية أعلى الجدول
          _buildActiveFiltersBar(reportsCtrl, accountName, items.length),

          // جسم التقرير: جدول رسمي كامل
          Expanded(
            child: isLoading
                ? const Center(child: AppLoadingIndicator())
                : (items.isEmpty
                    ? const Center(
                        child: EmptyStateWidget(
                          icon: AppIcons.tableChart,
                          title: AppStrings.noStatementTransactions,
                          subtitle:
                              'انقر على زر "فلتر" في الأعلى لتعديل خيارات البحث',
                        ),
                      )
                    : _buildOfficialDataTable(items)),
          ),
        ],
      ),
      bottomNavigationBar: (items.isNotEmpty && !isLoading)
          ? _buildStickyTotalsBar(reportsCtrl)
          : null,
    );
  }

  /// زر الإجراء في الـ AppBar (فلتر / تصدير)
  Widget _buildAppBarActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.chipBackground,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: AppTypography.sizeMicro + 1,
                  fontWeight: AppTypography.weightBold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon,
                  size: AppDimensions.iconSmall + 2,
                  color: AppColors.textPrimary),
            ],
          ),
        ),
      ),
    );
  }

  /// كرت تفاصيل الحساب وخيارات التقرير أعلى الجدول
  Widget _buildActiveFiltersBar(
    ReportsController ctrl,
    String accountName,
    int count,
  ) {
    String accountCategoryLabel;
    switch (widget.accountType) {
      case AccountType.supplier:
        accountCategoryLabel = 'حساب مورد معتمد';
        break;
      case AccountType.station:
        accountCategoryLabel = 'حساب محطة معتمدة';
        break;
      case AccountType.beneficiary:
        accountCategoryLabel = 'حساب جهة مستفيدة';
        break;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppDimensions.spaceM,
        AppDimensions.spaceM,
        AppDimensions.spaceM,
        AppDimensions.spaceNone,
      ),
      padding: const EdgeInsets.all(AppDimensions.spaceL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.chipBackground,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: const Icon(
                  AppIcons.account,
                  size: AppDimensions.iconMedium + 2,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppDimensions.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      accountCategoryLabel,
                      style: const TextStyle(
                        fontSize: AppTypography.sizeCaption,
                        color: AppColors.textSecondary,
                        fontWeight: AppTypography.weightMedium,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      accountName.isNotEmpty ? accountName : AppStrings.accountName,
                      style: const TextStyle(
                        fontSize: AppTypography.sizeBody + 3,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.chipBackground,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Text(
                  '$count ${AppStrings.operationsCountSuffix}',
                  style: const TextStyle(
                    fontSize: AppTypography.sizeMicro + 1,
                    fontWeight: AppTypography.weightBold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceM),
          Wrap(
            spacing: AppDimensions.spaceS,
            runSpacing: AppDimensions.spaceXS,
            children: [
              _buildFilterBadge(AppIcons.category, _getFuelTypeName(ctrl)),
              _buildFilterBadge(AppIcons.tabActual, _getOperationTypeLabel()),
              _buildFilterBadge(AppIcons.calendar, _getPeriodText()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.chipBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppDimensions.iconMicro + 1, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: AppTypography.sizeMicro,
              color: AppColors.textSecondary,
              fontWeight: AppTypography.weightMedium,
            ),
          ),
        ],
      ),
    );
  }

  /// الجدول الرسمي المعتمد (Official Data Table)
  Widget _buildOfficialDataTable(List<StatementItemModel> items) {
    double totalIn = 0.0;
    double totalOut = 0.0;
    for (final it in items) {
      totalIn += it.inflow;
      totalOut += it.outflow;
    }
    final latestBalance = items.isNotEmpty ? items.first.runningBalance : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // حساب العرض الكلي الدقيق لجميع الأعمدة المختارة
              Builder(builder: (ctx) {
                double totalWidth = 45.0; // تسلسل
                if (_visibleColumns.contains('date')) totalWidth += 95.0;
                if (_visibleColumns.contains('txNumber')) totalWidth += 110.0;
                if (_visibleColumns.contains('type')) totalWidth += 100.0;
                if (_visibleColumns.contains('fuelType')) totalWidth += 85.0;
                if (_visibleColumns.contains('quantity')) totalWidth += 90.0;
                if (_visibleColumns.contains('unit')) totalWidth += 65.0;
                if (_visibleColumns.contains('station')) totalWidth += 110.0;
                if (_visibleColumns.contains('recipient')) totalWidth += 110.0;
                if (_visibleColumns.contains('party')) totalWidth += 130.0;
                if (_visibleColumns.contains('notes')) totalWidth += 140.0;
                if (_visibleColumns.contains('balance')) totalWidth += 105.0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ترويسة الجدول
                    Container(
                      width: totalWidth,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(AppDimensions.radiusL),
                          topRight: Radius.circular(AppDimensions.radiusL),
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildHeaderCell(AppStrings.serialCol, width: 45),
                          if (_visibleColumns.contains('date'))
                            _buildHeaderCell(AppStrings.colDate, width: 95),
                          if (_visibleColumns.contains('txNumber'))
                            _buildHeaderCell(AppStrings.colTxNumber, width: 110),
                          if (_visibleColumns.contains('type'))
                            _buildHeaderCell(AppStrings.colType, width: 100),
                          if (_visibleColumns.contains('fuelType'))
                            _buildHeaderCell(AppStrings.colFuelType, width: 85),
                          if (_visibleColumns.contains('quantity'))
                            _buildHeaderCell(AppStrings.colQuantity, width: 90),
                          if (_visibleColumns.contains('unit'))
                            _buildHeaderCell(AppStrings.colUnit, width: 65),
                          if (_visibleColumns.contains('station'))
                            _buildHeaderCell(AppStrings.stationCol, width: 110),
                          if (_visibleColumns.contains('recipient'))
                            _buildHeaderCell(AppStrings.recipientCol, width: 110),
                          if (_visibleColumns.contains('party'))
                            _buildHeaderCell(AppStrings.colParty, width: 130),
                          if (_visibleColumns.contains('notes'))
                            _buildHeaderCell(AppStrings.colNotes, width: 140),
                          if (_visibleColumns.contains('balance'))
                            _buildHeaderCell(AppStrings.colBalance, width: 105),
                        ],
                      ),
                    ),

                    // سطور البيانات
                    ...List.generate(items.length, (index) {
                      final item = items[index];
                      final isEven = index % 2 == 0;
                      final rowBg = isEven
                          ? AppColors.surface
                          : AppColors.highlightBackground;

                      return Container(
                        width: totalWidth,
                        color: rowBg,
                        child: Row(
                          children: [
                            _buildDataCell('${index + 1}',
                                width: 45, align: TextAlign.center),
                            if (_visibleColumns.contains('date'))
                              _buildDataCell(item.transactionDate,
                                  width: 95, align: TextAlign.center),
                            if (_visibleColumns.contains('txNumber'))
                              _buildDataCell(item.transactionNumber ?? '-',
                                  width: 110, align: TextAlign.center),
                            if (_visibleColumns.contains('type'))
                              _buildDataCell(item.typeName ?? '-',
                                  width: 100, align: TextAlign.center),
                            if (_visibleColumns.contains('fuelType'))
                              _buildDataCell(item.fuelTypeName ?? '-',
                                  width: 85, align: TextAlign.center),
                            if (_visibleColumns.contains('quantity'))
                              _buildDataCell(
                                AppFormatters.formatQuantity(item.enteredQuantity),
                                width: 90,
                                align: TextAlign.center,
                                bold: true,
                              ),
                            if (_visibleColumns.contains('unit'))
                              _buildDataCell(item.unitName ?? '-',
                                  width: 65, align: TextAlign.center),
                            if (_visibleColumns.contains('station'))
                              _buildDataCell(item.stationName ?? '-', width: 110),
                            if (_visibleColumns.contains('recipient'))
                              _buildDataCell(item.recipientName ?? '-', width: 110),
                            if (_visibleColumns.contains('party'))
                              _buildDataCell(
                                item.recipientName ?? item.stationName ?? '-',
                                width: 130,
                              ),
                            if (_visibleColumns.contains('notes'))
                              _buildDataCell(item.notes ?? '', width: 140),
                            if (_visibleColumns.contains('balance'))
                              _buildDataCell(
                                AppFormatters.formatQuantity(item.runningBalance),
                                width: 105,
                                align: TextAlign.center,
                                bold: true,
                                textColor: AppColors.primary,
                              ),
                          ],
                        ),
                      );
                    }),

                    // صف الإجماليات الختامي على كامل عرض الجدول دون أي انقطاع
                    Container(
                      width: totalWidth,
                      decoration: const BoxDecoration(
                        color: AppColors.chipBackground,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(AppDimensions.radiusL),
                          bottomRight: Radius.circular(AppDimensions.radiusL),
                        ),
                        border: Border(
                          top: BorderSide(color: AppColors.border, width: 1.5),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSummaryFooterBadge(
                            title: 'الإجمالي الكلي',
                            value: '${items.length} حركة (${AppFormatters.formatQuantity(totalIn + totalOut)} لتر)',
                            color: AppColors.textPrimary,
                          ),
                          _buildSummaryFooterBadge(
                            title: 'إجمالي الوارد',
                            value: '${AppFormatters.formatQuantity(totalIn)} لتر',
                            color: AppColors.supplyGreen,
                          ),
                          _buildSummaryFooterBadge(
                            title: 'إجمالي المنصرف',
                            value: '${AppFormatters.formatQuantity(totalOut)} لتر',
                            color: AppColors.dispenseRed,
                          ),
                          _buildSummaryFooterBadge(
                            title: 'الرصيد النهائي',
                            value: '${AppFormatters.formatQuantity(latestBalance)} لتر',
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text, {required double width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: AppTypography.sizeMicro + 1,
          fontWeight: AppTypography.weightBold,
          color: AppColors.textWhite,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDataCell(
    String text, {
    required double width,
    TextAlign align = TextAlign.right,
    bool bold = false,
    Color textColor = AppColors.textPrimary,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      alignment: align == TextAlign.center
          ? Alignment.center
          : (align == TextAlign.right
              ? Alignment.centerRight
              : Alignment.centerLeft),
      child: Text(
        text,
        style: TextStyle(
          fontSize: AppTypography.sizeMicro + 0.5,
          fontWeight:
              bold ? AppTypography.weightBold : AppTypography.weightMedium,
          color: textColor,
        ),
        textAlign: align,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// فتح شيت الفلترة وتحديث الخيارات
  Future<void> _openFilterSheet(BuildContext context) async {
    final result = await ReportFilterSheet.show(
      context: context,
      accountType: widget.accountType,
      initialAccount: _account,
      initialStation: _station,
      initialFuelTypeId: _fuelTypeId,
      initialOperationType: _operationType,
      initialFromDate: _fromDate,
      initialToDate: _toDate,
      initialVisibleColumns: _visibleColumns,
    );

    if (result != null) {
      setState(() {
        _account = result.selectedAccount;
        _station = result.selectedStation;
        _fuelTypeId = result.selectedFuelTypeId;
        _operationType = result.selectedOperationType;
        _fromDate = result.fromDate;
        _toDate = result.toDate;
        _visibleColumns = result.visibleColumns;
      });
      _applyFiltersToController();
    }
  }

  Widget _buildSummaryFooterBadge({
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$title: ',
          style: const TextStyle(
            fontSize: AppTypography.sizeMicro + 0.5,
            fontWeight: AppTypography.weightBold,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: AppTypography.sizeBodySecondary,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  /// التبويب السفلي الثابت للجدول على كامل عرض الشاشة (الإجمالي الكلي، الوارد، المنصرف، الرصيد النهائي)
  Widget _buildStickyTotalsBar(ReportsController reportsCtrl) {
    final items = reportsCtrl.statementItems;
    double totalIn = 0.0;
    double totalOut = 0.0;
    for (final it in items) {
      totalIn += it.inflow;
      totalOut += it.outflow;
    }
    final latestBalance = items.isNotEmpty ? items.first.runningBalance : 0.0;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.borderLight, width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.overlayLight,
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceM,
        vertical: AppDimensions.spaceM,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: _buildMetricCol(
                title: 'الإجمالي الكلي',
                value: '${AppFormatters.formatQuantity(totalIn + totalOut)} لتر',
                color: AppColors.textPrimary,
              ),
            ),
            Container(width: 1, height: 36, color: AppColors.borderLight),
            Expanded(
              child: _buildMetricCol(
                title: 'إجمالي الوارد',
                value: '${AppFormatters.formatQuantity(totalIn)} لتر',
                color: AppColors.supplyGreen,
              ),
            ),
            Container(width: 1, height: 36, color: AppColors.borderLight),
            Expanded(
              child: _buildMetricCol(
                title: 'إجمالي المنصرف',
                value: '${AppFormatters.formatQuantity(totalOut)} لتر',
                color: AppColors.dispenseRed,
              ),
            ),
            Container(width: 1, height: 36, color: AppColors.borderLight),
            Expanded(
              child: _buildMetricCol(
                title: 'الرصيد النهائي',
                value: '${AppFormatters.formatQuantity(latestBalance)} لتر',
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCol({
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: AppTypography.sizeMicro,
            color: AppColors.textSecondary,
            fontWeight: AppTypography.weightMedium,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: AppTypography.sizeBodySecondary,
            fontWeight: AppTypography.weightBold,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// فتح شيت التصدير (PDF / Excel)
  Future<void> _openExportSheet(
    ReportsController reportsCtrl,
  ) async {
    final pInfo = context.read<PersonalInfoController>().info;
    final format = await ExportOptionsSheet.show(context: context);
    if (format == null || !mounted) return;
    final accountName = _station?.name ?? _account?.name ?? '';
    final fuelName = _getFuelTypeName(reportsCtrl);
    final periodText = _getPeriodText();
    final items = reportsCtrl.statementItems;

    double totalIn = 0.0;
    double totalOut = 0.0;
    for (final it in items) {
      totalIn += it.inflow;
      totalOut += it.outflow;
    }
    final latestBalance = items.isNotEmpty ? items.first.runningBalance : 0.0;

    if (format == ExportFormat.pdf) {
      final pdfBytes = await PdfReportService.generateStatementPdf(
        reportTitle: _reportTitle,
        accountName: accountName,
        accountPhone: _station?.phoneNumber ?? _account?.phoneNumber,
        location: _station?.location,
        periodText: periodText,
        fuelTypeName: fuelName,
        items: items,
        personalInfo: pInfo,
        totalInflow: totalIn,
        totalOutflow: totalOut,
        currentBalance: latestBalance,
      );
      await PdfReportService.printDocument(
        pdfBytes: pdfBytes,
        documentName: '${_reportTitle}_$accountName',
      );
    } else {
      final excelBytes = await ExcelReportService.generateStatementExcel(
        reportTitle: _reportTitle,
        accountName: accountName,
        fuelTypeName: fuelName,
        periodText: periodText,
        items: items,
        visibleColumns: _visibleColumns,
        totalInflow: totalIn,
        totalOutflow: totalOut,
        currentBalance: latestBalance,
      );
      await PdfReportService.shareDocument(
        pdfBytes: excelBytes,
        fileName: 'كشف_حساب_$accountName',
      );
      if (!mounted) return;
      AppSnackBar.showSuccess(
          context, 'تم تجهيز ملف Excel بنجاح وجاري المشاركة');
    }
  }
}
