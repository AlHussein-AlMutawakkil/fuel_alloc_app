import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/analysis_controller.dart';
import '../../controllers/backup_controller.dart';
import '../../controllers/stations_controller.dart';
import '../../controllers/transactions_controller.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/custom_modal_sheet.dart';
import '../../core/widgets/one_ui_card.dart';
import '../../core/widgets/operation_entry_sheet.dart';
import '../../core/widgets/transaction_details_dialog.dart';
import '../../models/fuel_type_metrics.dart';
import '../../models/transaction_model.dart';
import '../accounts/account_transactions_view.dart';
import '../settings/backup_settings_view.dart';

/// الشاشة الرئيسية (لوحة التحكم العامة ومراقبة الأرصدة) بنمط One UI
class HomeView extends StatefulWidget {
  final ValueChanged<int>? onNavigateToTab;

  const HomeView({
    super.key,
    this.onNavigateToTab,
  });

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool _isStationsExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    await Future.wait([
      context.read<TransactionsController>().fetchDashboardData(),
      context.read<StationsController>().fetchStations(),
      context.read<AnalysisController>().loadAnalysisData(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: OneUiAppBar(
        showBackButton: false,
        titleWidget: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              AppAssets.appIconTransparent,
              width: AppDimensions.iconLarge + 4,
              height: AppDimensions.iconLarge + 4,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: AppDimensions.spaceM),
            const Text(
              AppStrings.appNameEn,
              style: TextStyle(
                fontWeight: AppTypography.weightBold,
                fontSize: AppTypography.sizeH2,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          Consumer<BackupController>(
            builder: (context, backupCtrl, _) {
              final isSyncing = backupCtrl.isSyncing;
              final hasBackup = backupCtrl.localBackups.isNotEmpty ||
                  backupCtrl.isGoogleDriveConnected;

              final IconData backupIcon = isSyncing
                  ? AppIcons.sync
                  : (backupCtrl.isGoogleDriveConnected
                      ? AppIcons.cloudDone
                      : (backupCtrl.localBackups.isNotEmpty
                          ? AppIcons.backup
                          : AppIcons.cloudQueue));

              final Color iconColor =
                  hasBackup ? AppColors.supplyGreen : AppColors.textPrimary;

              return IconButton(
                tooltip: AppStrings.backupTitle,
                icon: Icon(
                  backupIcon,
                  color: iconColor,
                  size: AppDimensions.iconLarge,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BackupSettingsView(),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(width: AppDimensions.spaceXS),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.spaceM,
          ),
          children: [
            // 1. شريط فلترة السنة والشهر
            _buildPeriodFilterRow(),

            // 2. تبويب صنف الوقود العلوي المطابق تماماً لتبويب واجهة الحسابات
            _buildFuelTypeSegmentControl(),

            // 3. كرت ميزان توريد الموردين بتصميم كشف الحساب الأنيق والمقتضب
            _buildSupplierSummaryCard(),

            // 4. كرت مخزون وحركة المحطات بتصميم كشف الحساب الأنيق والمقتضب
            _buildStationSummaryCard(),

            // قائمة المحطات المنسدلة عند النقر على كرت مخزون المحطات
            if (_isStationsExpanded) _buildExpandedStationsList(),

            // 5. كرت ميزان الاعتمادات بتصميم كشف الحساب الأنيق والمقتضب
            _buildQuotaSummaryCard(),

            // 6. كرت الإجراءات السريعة
            _buildQuickActionsCard(),

            // 7. كرت آخر العمليات المسجلة
            _buildRecentTransactionsCard(),

            const SizedBox(height: AppDimensions.space3XL),
          ],
        ),
      ),
    );
  }

  static final List<MapEntry<int?, String>> _staticMonthEntries = [
    const MapEntry<int?, String>(null, AppStrings.allMonths),
    const MapEntry<int?, String>(1, AppStrings.monthJan),
    const MapEntry<int?, String>(2, AppStrings.monthFeb),
    const MapEntry<int?, String>(3, AppStrings.monthMar),
    const MapEntry<int?, String>(4, AppStrings.monthApr),
    const MapEntry<int?, String>(5, AppStrings.monthMay),
    const MapEntry<int?, String>(6, AppStrings.monthJun),
    const MapEntry<int?, String>(7, AppStrings.monthJul),
    const MapEntry<int?, String>(8, AppStrings.monthAug),
    const MapEntry<int?, String>(9, AppStrings.monthSep),
    const MapEntry<int?, String>(10, AppStrings.monthOct),
    const MapEntry<int?, String>(11, AppStrings.monthNov),
    const MapEntry<int?, String>(12, AppStrings.monthDec),
  ];

  /// 2. شريط فلترة السنة والشهر بتصميم One UI أنيق
  Widget _buildPeriodFilterRow() {
    return Consumer<TransactionsController>(
      builder: (context, txCtrl, _) {
        final year = txCtrl.dashboardYear;
        final month = txCtrl.dashboardMonth;
        final now = DateTime.now();
        final isDefault = year == now.year && month == now.month;

        final yearLabel = year != null ? '$year' : AppStrings.allYears;
        final monthLabel = month != null
            ? AppStrings.getMonthLabel(month)
            : AppStrings.allMonths;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.fuelCardMaxWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceXL,
                vertical: AppDimensions.spaceXXS,
              ),
              child: Row(
                children: [
                  // فلتر السنة
                  Expanded(
                    child: _buildFilterDropdownButton(
                      label: AppStrings.filterYear,
                      valueText: yearLabel,
                      isSelected: year != null,
                      onTap: () => _showYearPicker(context, txCtrl),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceS),

                  // فلتر الشهر
                  Expanded(
                    child: _buildFilterDropdownButton(
                      label: AppStrings.filterMonth,
                      valueText: monthLabel,
                      isSelected: month != null,
                      onTap: () => _showMonthPicker(context, txCtrl),
                    ),
                  ),

                  // زر إلغاء الفلترة وإعادة التعيين للفترة الافتراضية
                  if (!isDefault) ...[
                    const SizedBox(width: AppDimensions.spaceXS),
                    Tooltip(
                      message: AppStrings.resetFilter,
                      child: Material(
                        color: AppColors.chipBackground,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusL),
                        child: InkWell(
                          onTap: () {
                            txCtrl.setDashboardPeriod(
                              year: now.year,
                              month: now.month,
                            );
                          },
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusL),
                          child: Container(
                            height: 44,
                            width: 44,
                            alignment: Alignment.center,
                            child: const Icon(
                              AppIcons.close,
                              size: AppDimensions.iconMedium,
                              color: AppColors.dispenseRed,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterDropdownButton({
    required String label,
    required String valueText,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? AppColors.infoLight : AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceM,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.borderSubtle,
              width: AppDimensions.borderWidthThin,
            ),
          ),
          child: Row(
            children: [
              Icon(
                AppIcons.calendar,
                size: AppDimensions.iconSmall + 2,
                color: isSelected ? AppColors.primary : AppColors.textTertiary,
              ),
              const SizedBox(width: AppDimensions.spaceS),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: AppTypography.sizeMicro,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textMuted,
                        fontWeight: AppTypography.weightMedium,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      valueText,
                      style: TextStyle(
                        fontSize: AppTypography.sizeBodySecondary - 0.5,
                        color: isSelected
                            ? AppColors.primaryDark
                            : AppColors.textPrimary,
                        fontWeight: isSelected
                            ? AppTypography.weightBold
                            : AppTypography.weightMedium,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                AppIcons.dropdownArrow,
                size: AppDimensions.iconSmall,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showYearPicker(
      BuildContext context, TransactionsController txCtrl) async {
    final availableYears = txCtrl.availableYears;
    final entries = <MapEntry<int?, String>>[
      const MapEntry<int?, String>(null, AppStrings.allYears),
      ...availableYears.map((y) => MapEntry<int?, String>(y, '$y')),
    ];

    final currentYear = txCtrl.dashboardYear;
    final selectedEntry = entries.firstWhere(
      (e) => e.key == currentYear,
      orElse: () => entries.first,
    );

    final picked =
        await CustomModalSheet.showItemPicker<MapEntry<int?, String>>(
      context: context,
      title: AppStrings.selectYear,
      items: entries,
      selectedItem: selectedEntry,
      itemLabel: (e) => e.value,
    );

    if (picked != null) {
      await txCtrl.setDashboardPeriod(
        year: picked.key,
        month: txCtrl.dashboardMonth,
      );
    }
  }

  Future<void> _showMonthPicker(
      BuildContext context, TransactionsController txCtrl) async {
    final currentMonth = txCtrl.dashboardMonth;
    final selectedEntry = _staticMonthEntries.firstWhere(
      (e) => e.key == currentMonth,
      orElse: () => _staticMonthEntries.first,
    );

    final picked =
        await CustomModalSheet.showItemPicker<MapEntry<int?, String>>(
      context: context,
      title: AppStrings.selectMonth,
      items: _staticMonthEntries,
      selectedItem: selectedEntry,
      itemLabel: (e) => e.value,
    );

    if (picked != null) {
      await txCtrl.setDashboardPeriod(
        year: txCtrl.dashboardYear,
        month: picked.key,
      );
    }
  }

  /// 3. تبويب أصناف الوقود المطابق لتبويب واجهة الحسابات تماماً
  Widget _buildFuelTypeSegmentControl() {
    return Consumer<TransactionsController>(
      builder: (context, txCtrl, _) {
        final metricsList = txCtrl.fuelTypeMetrics;
        if (metricsList.isEmpty) return const SizedBox.shrink();

        final currentId =
            txCtrl.dashboardFuelTypeId ?? metricsList.first.fuelTypeId;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.fuelCardMaxWidth,
            ),
            child: Container(
              margin: AppDimensions.paddingSegment,
              padding: AppDimensions.paddingAllXS,
              decoration: const BoxDecoration(
                color: AppColors.segmentBackground,
                borderRadius: AppDimensions.borderRadiusXL,
              ),
              child: Row(
                children: metricsList.map((m) {
                  final isSelected = m.fuelTypeId == currentId;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        txCtrl.setDashboardFuelTypeId(m.fuelTypeId);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.surface
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: isSelected
                              ? const [
                                  BoxShadow(
                                    color: AppColors.shadowSubtle,
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          m.fuelTypeName,
                          style: TextStyle(
                            fontSize: AppTypography.sizeBody,
                            fontWeight: isSelected
                                ? AppTypography.weightBold
                                : AppTypography.weightMedium,
                            color: isSelected
                                ? AppColors.textPrimary
                                : AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 3. كرت ميزان توريد الموردين (مطابق لتصميم FuelSummaryCard في كشف الحساب)
  Widget _buildSupplierSummaryCard() {
    return Consumer<TransactionsController>(
      builder: (context, txCtrl, _) {
        final metrics = txCtrl.currentDashboardFuelMetrics ??
            FuelTypeMetrics(
              fuelTypeId: 1,
              fuelTypeName: AppStrings.fuelPetrol,
              supplierSupplyQuota: 0.0,
              supplierSupplyActual: 0.0,
              stationSupplyActual: 0.0,
              stationDispenseActual: 0.0,
              stationAeration: 0.0,
              stationCurrentStock: 0.0,
              beneficiaryDispenseQuota: 0.0,
              beneficiaryDispenseActual: 0.0,
            );

        final percent = metrics.supplierSupplyPercent.toStringAsFixed(1);
        final ratio = metrics.supplierSupplyRatio;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.fuelCardMaxWidth,
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceXL,
                vertical: AppDimensions.spaceS,
              ),
              padding: AppDimensions.paddingCard,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppDimensions.borderRadius3XL,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowSubtle,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. الصف العلوي: العنوان + شارة النسبة البيضاوية الداكنة
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Expanded(
                        child: Text(
                          AppStrings.supplierSupplyTitle,
                          style: TextStyle(
                            fontSize: AppTypography.sizeH2,
                            fontWeight: AppTypography.weightBold,
                            color: AppColors.textDarkSlate,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spaceM),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spaceL - 2,
                          vertical: AppDimensions.spaceXXS + 0.5,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.charcoal,
                          borderRadius: AppDimensions.borderRadius2XL,
                        ),
                        child: Text(
                          '$percent%',
                          style: const TextStyle(
                            fontSize: AppTypography.sizeSmall + 0.5,
                            fontWeight: AppTypography.weightBold,
                            color: AppColors.textWhite,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // خط فاصل خفيف وناعم تحت الصف العلوي
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: AppDimensions.spaceXS,
                    ),
                    child: Divider(
                      height: AppDimensions.dividerHeight,
                      thickness: AppDimensions.borderWidthHairline,
                      color: AppColors.borderSubtle,
                    ),
                  ),

                  // 2. الجزء الأوسط: الرقم الرئيسي مع أيقونة ✦
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        AppIcons.star,
                        size: AppDimensions.space2XL - 5,
                        color: AppColors.textDarkSlate,
                      ),
                      const SizedBox(width: AppDimensions.spaceXS + 1),
                      Text(
                        AppFormatters.formatQuantity(
                            metrics.supplierRemainingQuota),
                        style: const TextStyle(
                          fontSize: AppTypography.sizeH2 + 1,
                          fontWeight: AppTypography.weightBold,
                          color: AppColors.textDarkSlate,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spaceS),
                      Text(
                        '${AppStrings.unitLiter} ${metrics.fuelTypeName}',
                        style: const TextStyle(
                          fontSize: AppTypography.sizeBody,
                          fontWeight: AppTypography.weightSemiBold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spaceXS + 1),

                  // 3. الجزء السفلي: المربع الرمادي الفاتح لعناصر العمليات المقتضبة
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(
                        maxWidth: AppDimensions.fuelCardMetricsMaxWidth,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.spaceS - 1,
                        horizontal: AppDimensions.spaceM,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.highlightBackground,
                        borderRadius: AppDimensions.borderRadiusL,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  AppFormatters.formatQuantity(
                                      metrics.supplierSupplyQuota),
                                  style: const TextStyle(
                                    fontSize:
                                        AppTypography.sizeBodySecondary + 0.5,
                                    fontWeight: AppTypography.weightBold,
                                    color: AppColors.textDarkSlate,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                const Text(
                                  AppStrings.supplyQuota,
                                  style: TextStyle(
                                    fontSize: AppTypography.sizeMicro,
                                    color: AppColors.textMuted,
                                    fontWeight: AppTypography.weightMedium,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  AppFormatters.formatQuantity(
                                      metrics.supplierSupplyActual),
                                  style: const TextStyle(
                                    fontSize:
                                        AppTypography.sizeBodySecondary + 0.5,
                                    fontWeight: AppTypography.weightBold,
                                    color: AppColors.supplyGreen,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                const Text(
                                  AppStrings.supplyActual,
                                  style: TextStyle(
                                    fontSize: AppTypography.sizeMicro,
                                    color: AppColors.textMuted,
                                    fontWeight: AppTypography.weightMedium,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  AppFormatters.formatQuantity(
                                      metrics.supplierRemainingQuota),
                                  style: const TextStyle(
                                    fontSize:
                                        AppTypography.sizeBodySecondary + 0.5,
                                    fontWeight: AppTypography.weightBold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                const Text(
                                  AppStrings.balanceQuota,
                                  style: TextStyle(
                                    fontSize: AppTypography.sizeMicro,
                                    color: AppColors.textMuted,
                                    fontWeight: AppTypography.weightMedium,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 4. شريط النسبة المدمج
                  const SizedBox(height: AppDimensions.spaceS),
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull),
                    child: LinearProgressIndicator(
                      value: ratio,
                      backgroundColor: AppColors.borderSubtle,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.supplyGreen,
                      ),
                      minHeight: 4.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 4. كرت مخزون وحركة المحطات (مطابق لتصميم FuelSummaryCard في كشف الحساب)
  Widget _buildStationSummaryCard() {
    return Consumer<TransactionsController>(
      builder: (context, txCtrl, _) {
        final metrics = txCtrl.currentDashboardFuelMetrics ??
            FuelTypeMetrics(
              fuelTypeId: 1,
              fuelTypeName: AppStrings.fuelPetrol,
              supplierSupplyQuota: 0.0,
              supplierSupplyActual: 0.0,
              stationSupplyActual: 0.0,
              stationDispenseActual: 0.0,
              stationAeration: 0.0,
              stationCurrentStock: 0.0,
              beneficiaryDispenseQuota: 0.0,
              beneficiaryDispenseActual: 0.0,
            );

        final percent = metrics.stationDispensePercent.toStringAsFixed(1);
        final ratio = metrics.stationDispenseRatio;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.fuelCardMaxWidth,
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceXL,
                vertical: AppDimensions.spaceS,
              ),
              padding: AppDimensions.paddingCard,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppDimensions.borderRadius3XL,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowSubtle,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isStationsExpanded = !_isStationsExpanded;
                  });
                },
                borderRadius: AppDimensions.borderRadius3XL,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. الصف العلوي: العنوان + شارة النسبة البيضاوية الداكنة + سهم التوسيع/الطي
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Expanded(
                          child: Text(
                            AppStrings.stationBalanceAndFlow,
                            style: TextStyle(
                              fontSize: AppTypography.sizeH2,
                              fontWeight: AppTypography.weightBold,
                              color: AppColors.textDarkSlate,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spaceM),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spaceL - 2,
                            vertical: AppDimensions.spaceXXS + 0.5,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.charcoal,
                            borderRadius: AppDimensions.borderRadius2XL,
                          ),
                          child: Text(
                            '$percent%',
                            style: const TextStyle(
                              fontSize: AppTypography.sizeSmall + 0.5,
                              fontWeight: AppTypography.weightBold,
                              color: AppColors.textWhite,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spaceS),
                        AnimatedRotation(
                          turns: _isStationsExpanded ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(
                            AppIcons.dropdownArrow,
                            color: AppColors.textSecondary,
                            size: AppDimensions.iconMedium,
                          ),
                        ),
                      ],
                    ),

                    // خط فاصل خفيف وناعم تحت الصف العلوي
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: AppDimensions.spaceXS,
                      ),
                      child: Divider(
                        height: AppDimensions.dividerHeight,
                        thickness: AppDimensions.borderWidthHairline,
                        color: AppColors.borderSubtle,
                      ),
                    ),

                    // 2. الجزء الأوسط: الرقم الرئيسي مع أيقونة ✦
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          AppIcons.star,
                          size: AppDimensions.space2XL - 5,
                          color: AppColors.textDarkSlate,
                        ),
                        const SizedBox(width: AppDimensions.spaceXS + 1),
                        Text(
                          AppFormatters.formatQuantity(
                              metrics.stationCurrentStock),
                          style: const TextStyle(
                            fontSize: AppTypography.sizeH2 + 1,
                            fontWeight: AppTypography.weightBold,
                            color: AppColors.textDarkSlate,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spaceS),
                        Text(
                          '${AppStrings.unitLiter} ${metrics.fuelTypeName}',
                          style: const TextStyle(
                            fontSize: AppTypography.sizeBody,
                            fontWeight: AppTypography.weightSemiBold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spaceXS + 1),

                    // 3. الجزء السفلي: المربع الرمادي الفاتح لعناصر العمليات المقتضبة
                    Center(
                      child: Container(
                        constraints: const BoxConstraints(
                          maxWidth: AppDimensions.fuelCardMetricsMaxWidth,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDimensions.spaceS - 1,
                          horizontal: AppDimensions.spaceM,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.highlightBackground,
                          borderRadius: AppDimensions.borderRadiusL,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    AppFormatters.formatQuantity(
                                        metrics.stationSupplyActual),
                                    style: const TextStyle(
                                      fontSize:
                                          AppTypography.sizeBodySecondary + 0.5,
                                      fontWeight: AppTypography.weightBold,
                                      color: AppColors.supplyGreen,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  const Text(
                                    AppStrings.actualSupply,
                                    style: TextStyle(
                                      fontSize: AppTypography.sizeMicro,
                                      color: AppColors.textMuted,
                                      fontWeight: AppTypography.weightMedium,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    AppFormatters.formatQuantity(
                                        metrics.stationDispenseActual),
                                    style: const TextStyle(
                                      fontSize:
                                          AppTypography.sizeBodySecondary + 0.5,
                                      fontWeight: AppTypography.weightBold,
                                      color: AppColors.dispenseRed,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  const Text(
                                    AppStrings.actualDispense,
                                    style: TextStyle(
                                      fontSize: AppTypography.sizeMicro,
                                      color: AppColors.textMuted,
                                      fontWeight: AppTypography.weightMedium,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    AppFormatters.formatQuantity(
                                        metrics.stationAeration),
                                    style: const TextStyle(
                                      fontSize:
                                          AppTypography.sizeBodySecondary + 0.5,
                                      fontWeight: AppTypography.weightBold,
                                      color: AppColors.warning,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  const Text(
                                    AppStrings.aerationCommission,
                                    style: TextStyle(
                                      fontSize: AppTypography.sizeMicro,
                                      color: AppColors.textMuted,
                                      fontWeight: AppTypography.weightMedium,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 4. شريط النسبة المدمج
                    const SizedBox(height: AppDimensions.spaceS),
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusFull),
                      child: LinearProgressIndicator(
                        value: ratio,
                        backgroundColor: AppColors.borderSubtle,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.dispenseRed,
                        ),
                        minHeight: 4.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// قائمة المحطات التي يوجد فيها رصيد للصنف المختار مرتبة تنازلياً حسب الكمية (تظهر أسفل كرت مخزون وحركة المحطات عند فتحه)
  Widget _buildExpandedStationsList() {
    return Consumer2<StationsController, TransactionsController>(
      builder: (context, stationsCtrl, txCtrl, _) {
        final currentMetrics = txCtrl.currentDashboardFuelMetrics;
        final currentFuelId = currentMetrics?.fuelTypeId;

        // فلترة المحطات التي تمتلك رصيداً أكبر من الصفر في الصنف المختار وترتيبها تنازلياً حسب الرصيد
        final stationsWithBalance = stationsCtrl.stations
            .map((station) {
              final balance = (station.id != null && currentFuelId != null)
                  ? txCtrl.getStationFuelBalance(station.id!, currentFuelId)
                  : 0.0;
              return (station: station, balance: balance);
            })
            .where((item) => item.balance > 0.0)
            .toList()
          ..sort((a, b) => b.balance.compareTo(a.balance));

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.fuelCardMaxWidth,
            ),
            child: Container(
              margin: const EdgeInsets.only(
                left: AppDimensions.spaceXL,
                right: AppDimensions.spaceXL,
                bottom: AppDimensions.spaceS,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppDimensions.borderRadius3XL,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowSubtle,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: AppDimensions.borderRadius3XL,
                child: stationsWithBalance.isEmpty
                    ? const Padding(
                        padding: AppDimensions.paddingCard,
                        child: Center(
                          child: Text(
                            AppStrings.noStationsForFuelType,
                            style: TextStyle(
                              fontSize: AppTypography.sizeBodySecondary,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: stationsWithBalance.map((item) {
                          return OneUiTile(
                            leading: const Icon(
                              AppIcons.gasStationOutlined,
                              color: AppColors.textSecondary,
                              size: AppDimensions.iconMedium,
                            ),
                            title: item.station.name,
                            subtitle:
                                item.station.location ?? AppStrings.notSpecified,
                            trailing: Text(
                              '${AppFormatters.formatQuantity(item.balance)} ${AppStrings.unitLiter}',
                              style: const TextStyle(
                                fontSize: AppTypography.sizeBodySecondary,
                                fontWeight: AppTypography.weightBold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AccountTransactionsView(
                                    account: item.station.toAccountModel(),
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 5. كرت ميزان الاعتمادات (مطابق لتصميم FuelSummaryCard في كشف الحساب)
  Widget _buildQuotaSummaryCard() {
    return Consumer<TransactionsController>(
      builder: (context, txCtrl, _) {
        final metrics = txCtrl.currentDashboardFuelMetrics ??
            FuelTypeMetrics(
              fuelTypeId: 1,
              fuelTypeName: AppStrings.fuelPetrol,
              supplierSupplyQuota: 0.0,
              supplierSupplyActual: 0.0,
              stationSupplyActual: 0.0,
              stationDispenseActual: 0.0,
              stationAeration: 0.0,
              stationCurrentStock: 0.0,
              beneficiaryDispenseQuota: 0.0,
              beneficiaryDispenseActual: 0.0,
            );

        final percent = metrics.beneficiaryDispensePercent.toStringAsFixed(1);
        final ratio = metrics.beneficiaryDispenseRatio;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.fuelCardMaxWidth,
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceXL,
                vertical: AppDimensions.spaceS,
              ),
              padding: AppDimensions.paddingCard,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppDimensions.borderRadius3XL,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowSubtle,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. الصف العلوي: العنوان + شارة النسبة البيضاوية الداكنة
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Expanded(
                        child: Text(
                          AppStrings.quotaBalanceTitle,
                          style: TextStyle(
                            fontSize: AppTypography.sizeH2,
                            fontWeight: AppTypography.weightBold,
                            color: AppColors.textDarkSlate,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spaceM),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spaceL - 2,
                          vertical: AppDimensions.spaceXXS + 0.5,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.charcoal,
                          borderRadius: AppDimensions.borderRadius2XL,
                        ),
                        child: Text(
                          '$percent%',
                          style: const TextStyle(
                            fontSize: AppTypography.sizeSmall + 0.5,
                            fontWeight: AppTypography.weightBold,
                            color: AppColors.textWhite,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // خط فاصل خفيف وناعم تحت الصف العلوي
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: AppDimensions.spaceXS,
                    ),
                    child: Divider(
                      height: AppDimensions.dividerHeight,
                      thickness: AppDimensions.borderWidthHairline,
                      color: AppColors.borderSubtle,
                    ),
                  ),

                  // 2. الجزء الأوسط: الرقم الرئيسي مع أيقونة ✦
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        AppIcons.star,
                        size: AppDimensions.space2XL - 5,
                        color: AppColors.textDarkSlate,
                      ),
                      const SizedBox(width: AppDimensions.spaceXS + 1),
                      Text(
                        AppFormatters.formatQuantity(
                            metrics.beneficiaryRemainingQuota),
                        style: const TextStyle(
                          fontSize: AppTypography.sizeH2 + 1,
                          fontWeight: AppTypography.weightBold,
                          color: AppColors.textDarkSlate,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spaceS),
                      Text(
                        '${AppStrings.unitLiter} ${metrics.fuelTypeName}',
                        style: const TextStyle(
                          fontSize: AppTypography.sizeBody,
                          fontWeight: AppTypography.weightSemiBold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spaceXS + 1),

                  // 3. الجزء السفلي: المربع الرمادي الفاتح لعناصر العمليات المقتضبة
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(
                        maxWidth: AppDimensions.fuelCardMetricsMaxWidth,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.spaceS - 1,
                        horizontal: AppDimensions.spaceM,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.highlightBackground,
                        borderRadius: AppDimensions.borderRadiusL,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  AppFormatters.formatQuantity(
                                      metrics.beneficiaryDispenseQuota),
                                  style: const TextStyle(
                                    fontSize:
                                        AppTypography.sizeBodySecondary + 0.5,
                                    fontWeight: AppTypography.weightBold,
                                    color: AppColors.textDarkSlate,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                const Text(
                                  AppStrings.dispenseQuota,
                                  style: TextStyle(
                                    fontSize: AppTypography.sizeMicro,
                                    color: AppColors.textMuted,
                                    fontWeight: AppTypography.weightMedium,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  AppFormatters.formatQuantity(
                                      metrics.beneficiaryDispenseActual),
                                  style: const TextStyle(
                                    fontSize:
                                        AppTypography.sizeBodySecondary + 0.5,
                                    fontWeight: AppTypography.weightBold,
                                    color: AppColors.dispenseRed,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                const Text(
                                  AppStrings.dispenseActual,
                                  style: TextStyle(
                                    fontSize: AppTypography.sizeMicro,
                                    color: AppColors.textMuted,
                                    fontWeight: AppTypography.weightMedium,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  AppFormatters.formatQuantity(
                                      metrics.beneficiaryRemainingQuota),
                                  style: const TextStyle(
                                    fontSize:
                                        AppTypography.sizeBodySecondary + 0.5,
                                    fontWeight: AppTypography.weightBold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                const Text(
                                  AppStrings.balanceQuota,
                                  style: TextStyle(
                                    fontSize: AppTypography.sizeMicro,
                                    color: AppColors.textMuted,
                                    fontWeight: AppTypography.weightMedium,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 4. شريط النسبة المدمج
                  const SizedBox(height: AppDimensions.spaceS),
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull),
                    child: LinearProgressIndicator(
                      value: ratio,
                      backgroundColor: AppColors.borderSubtle,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                      minHeight: 4.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 6. كرت الإجراءات السريعة
  Widget _buildQuickActionsCard() {
    return OneUiCard(
      children: [
        const OneUiTile(
          leading: Icon(
            AppIcons.bolt,
            color: AppColors.primary,
            size: AppDimensions.iconMedium + 2,
          ),
          title: AppStrings.quickActions,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceL,
            vertical: AppDimensions.spaceL,
          ),
          child: Row(
            children: [
              // زر صرف وقود
              Expanded(
                child: _buildQuickActionButton(
                  icon: AppIcons.dispense,
                  label: AppStrings.quickDispenseActual,
                  color: AppColors.dispenseRed,
                  bgColor: AppColors.dispenseLight,
                  onTap: () async {
                    final res = await OperationEntrySheet.show(
                      context: context,
                      initialTabIndex: 1,
                      initialDirection: 1,
                    );
                    if (res == true && mounted) {
                      _loadDashboardData();
                    }
                  },
                ),
              ),
              const SizedBox(width: AppDimensions.spaceM),

              // زر توريد لمحطة
              Expanded(
                child: _buildQuickActionButton(
                  icon: AppIcons.supply,
                  label: AppStrings.quickSupplyActual,
                  color: AppColors.supplyGreen,
                  bgColor: AppColors.supplyLight,
                  onTap: () async {
                    final res = await OperationEntrySheet.show(
                      context: context,
                      initialTabIndex: 1,
                      initialDirection: 0,
                    );
                    if (res == true && mounted) {
                      _loadDashboardData();
                    }
                  },
                ),
              ),
              const SizedBox(width: AppDimensions.spaceM),

              // زر تحويل كمية
              Expanded(
                child: _buildQuickActionButton(
                  icon: AppIcons.transfer,
                  label: AppStrings.quickTransfer,
                  color: AppColors.info,
                  bgColor: AppColors.infoLight,
                  onTap: () async {
                    final res = await OperationEntrySheet.show(
                      context: context,
                      initialTabIndex: 0,
                      initialDirection: 0,
                    );
                    if (res == true && mounted) {
                      _loadDashboardData();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.spaceL,
            horizontal: AppDimensions.spaceS,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: AppDimensions.iconLarge,
              ),
              const SizedBox(height: AppDimensions.spaceS),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppTypography.sizeCaption,
                  fontWeight: AppTypography.weightSemiBold,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 8. كرت آخر العمليات المسجلة
  Widget _buildRecentTransactionsCard() {
    return Consumer<TransactionsController>(
      builder: (context, txCtrl, _) {
        final recentList = txCtrl.recentTransactions;

        return OneUiCard(
          children: [
            const OneUiTile(
              leading: Icon(
                AppIcons.statement,
                color: AppColors.primary,
                size: AppDimensions.iconMedium + 2,
              ),
              title: AppStrings.recentTransactions,
            ),
            if (recentList.isEmpty)
              const Padding(
                padding: AppDimensions.paddingTile,
                child: Center(
                  child: Text(
                    AppStrings.noRecentTransactionsYet,
                    style: TextStyle(
                      fontSize: AppTypography.sizeBodySecondary,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              )
            else
              ...recentList.map((tx) {
                return _buildRecentTransactionTile(tx);
              }),
            OneUiTile(
              title: AppStrings.viewAllTransactionsAndAccounts,
              showChevron: false,
              titleColor: AppColors.primary,
              onTap: () {
                widget.onNavigateToTab?.call(1);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentTransactionTile(TransactionModel tx) {
    IconData icon;
    Color color;
    Color bgColor;

    if (tx.isDispense) {
      icon = AppIcons.dispense;
      color = AppColors.dispenseRed;
      bgColor = AppColors.dispenseLight;
    } else if (tx.isSupply) {
      icon = AppIcons.supply;
      color = AppColors.supplyGreen;
      bgColor = AppColors.supplyLight;
    } else if (tx.isTransfer) {
      icon = AppIcons.transfer;
      color = AppColors.info;
      bgColor = AppColors.infoLight;
    } else {
      icon = AppIcons.tabQuota;
      color = AppColors.primary;
      bgColor = AppColors.chipBackground;
    }

    final displayName =
        tx.stationName ?? tx.accountName ?? AppStrings.statement;
    final fuelName = tx.fuelTypeName ?? AppStrings.fuelType;

    return OneUiTile(
      leading: Container(
        width: AppDimensions.avatarSize - 8,
        height: AppDimensions.avatarSize - 8,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: color,
          size: AppDimensions.iconMedium,
        ),
      ),
      title: '$displayName ($fuelName)',
      subtitle:
          '${AppFormatters.formatDate(tx.transactionDate)} • ${tx.typeName ?? ''}',
      trailing: Text(
        '${AppFormatters.formatQuantity(tx.baseQuantityLiters)} ${AppStrings.unitLiter}',
        style: TextStyle(
          fontSize: AppTypography.sizeBodySecondary,
          fontWeight: AppTypography.weightBold,
          color: color,
        ),
      ),
      onTap: () {
        TransactionDetailsDialog.show(
          context: context,
          transaction: tx,
        );
      },
    );
  }
}
