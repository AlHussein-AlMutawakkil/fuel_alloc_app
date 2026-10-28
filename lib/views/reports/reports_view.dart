import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/reports_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/one_ui_card.dart';
import '../../models/account_model.dart';
import 'reconciliation_report_view.dart';
import 'report_preview_table_view.dart';
import 'widgets/report_filter_sheet.dart';

/// الشاشة الرئيسية لقسم التقارير بنمط One UI المعتمد للتطبيق (مطابقة للصورة 1 بنسبة 100%)
class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  // تتبع حالة طي وتوسيع كل بطاقة من بطاقات One UI
  bool _isStatementsExpanded = true;
  bool _isReconciliationsExpanded = false;
  bool _isMovementsExpanded = false;
  bool _isAnalyticsExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportsController>().initializeData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const OneUiAppBar(
        title: AppStrings.navReports, // "التقارير" فقط
        showBackButton: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.spaceL,
        ),
        children: [
          // 1. كرت كشوفات الحسابات المعتمد (مطابق للصورة 1)
          OneUiCard(
            children: [
              OneUiTile(
                leading: const Icon(
                  AppIcons.statement,
                  color: AppColors.textPrimary,
                  size: AppDimensions.iconMedium + 2,
                ),
                title: AppStrings.categoryStatements,
                titleFontWeight: FontWeight.w900,
                titleFontSize: 17.5,
                trailing: Icon(
                  _isStatementsExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary,
                  size: AppDimensions.iconLarge,
                ),
                onTap: () {
                  setState(() => _isStatementsExpanded = !_isStatementsExpanded);
                },
              ),
              if (_isStatementsExpanded) ...[
                OneUiTile(
                  leading: const Icon(
                    AppIcons.account,
                    color: AppColors.primary,
                    size: AppDimensions.iconMedium + 2,
                  ),
                  title: AppStrings.reportSupplierStatementTitle,
                  titleFontWeight: FontWeight.w500,
                  titleFontSize: 14.5,
                  onTap: () => _openStatementFlow(context, AccountType.supplier),
                ),
                OneUiTile(
                  leading: const Icon(
                    AppIcons.gasStation,
                    color: AppColors.supplyGreen,
                    size: AppDimensions.iconMedium + 2,
                  ),
                  title: AppStrings.reportStationStatementTitle,
                  titleFontWeight: FontWeight.w500,
                  titleFontSize: 14.5,
                  onTap: () => _openStatementFlow(context, AccountType.station),
                ),
                OneUiTile(
                  leading: const Icon(
                    AppIcons.navAccounts,
                    color: AppColors.info,
                    size: AppDimensions.iconMedium + 2,
                  ),
                  title: AppStrings.reportBeneficiaryStatementTitle,
                  titleFontWeight: FontWeight.w500,
                  titleFontSize: 14.5,
                  onTap: () => _openStatementFlow(context, AccountType.beneficiary),
                ),
              ],
            ],
          ),

          // 2. كرت تقارير المطابقات والأرصدة المعتمد
          OneUiCard(
            children: [
              OneUiTile(
                leading: const Icon(
                  AppIcons.balance,
                  color: AppColors.textPrimary,
                  size: AppDimensions.iconMedium + 2,
                ),
                title: AppStrings.categoryReconciliations,
                titleFontWeight: FontWeight.w900,
                titleFontSize: 17.5,
                trailing: Icon(
                  _isReconciliationsExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary,
                  size: AppDimensions.iconLarge,
                ),
                onTap: () {
                  setState(() => _isReconciliationsExpanded = !_isReconciliationsExpanded);
                },
              ),
              if (_isReconciliationsExpanded) ...[
                OneUiTile(
                  leading: const Icon(
                    AppIcons.account,
                    color: AppColors.primary,
                    size: AppDimensions.iconMedium + 2,
                  ),
                  title: AppStrings.reportSupplierReconciliationTitle,
                  titleFontWeight: FontWeight.w500,
                  titleFontSize: 14.5,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ReconciliationReportView(
                          mode: ReconciliationMode.supplier,
                        ),
                      ),
                    );
                  },
                ),
                OneUiTile(
                  leading: const Icon(
                    AppIcons.inventory,
                    color: AppColors.supplyGreen,
                    size: AppDimensions.iconMedium + 2,
                  ),
                  title: AppStrings.reportStationReconciliationTitle,
                  titleFontWeight: FontWeight.w500,
                  titleFontSize: 14.5,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ReconciliationReportView(
                          mode: ReconciliationMode.station,
                        ),
                      ),
                    );
                  },
                ),
                OneUiTile(
                  leading: const Icon(
                    AppIcons.tableChart,
                    color: AppColors.info,
                    size: AppDimensions.iconMedium + 2,
                  ),
                  title: AppStrings.reportBeneficiaryReconciliationTitle,
                  titleFontWeight: FontWeight.w500,
                  titleFontSize: 14.5,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ReconciliationReportView(
                          mode: ReconciliationMode.beneficiary,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),

          // 3. كرت حركة المواد والوقود المعتمد
          OneUiCard(
            children: [
              OneUiTile(
                leading: const Icon(
                  AppIcons.tabActual,
                  color: AppColors.textPrimary,
                  size: AppDimensions.iconMedium + 2,
                ),
                title: AppStrings.categoryMovements,
                titleFontWeight: FontWeight.w900,
                titleFontSize: 17.5,
                trailing: Icon(
                  _isMovementsExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary,
                  size: AppDimensions.iconLarge,
                ),
                onTap: () {
                  setState(() => _isMovementsExpanded = !_isMovementsExpanded);
                },
              ),
              if (_isMovementsExpanded) ...[
                OneUiTile(
                  leading: const Icon(
                    AppIcons.supply,
                    color: AppColors.supplyGreen,
                    size: AppDimensions.iconMedium + 2,
                  ),
                  title: AppStrings.reportSupplyMovementsTitle,
                  titleFontWeight: FontWeight.w500,
                  titleFontSize: 14.5,
                  valueText: 'المرحلة 2',
                  onTap: () => _showNextPhaseNotice(context, AppStrings.reportSupplyMovementsTitle),
                ),
                OneUiTile(
                  leading: const Icon(
                    AppIcons.dispense,
                    color: AppColors.dispenseRed,
                    size: AppDimensions.iconMedium + 2,
                  ),
                  title: AppStrings.reportDispenseMovementsTitle,
                  titleFontWeight: FontWeight.w500,
                  titleFontSize: 14.5,
                  valueText: 'المرحلة 2',
                  onTap: () => _showNextPhaseNotice(context, AppStrings.reportDispenseMovementsTitle),
                ),
                OneUiTile(
                  leading: const Icon(
                    AppIcons.transfer,
                    color: AppColors.actionArchive,
                    size: AppDimensions.iconMedium + 2,
                  ),
                  title: AppStrings.reportTransfersTitle,
                  titleFontWeight: FontWeight.w500,
                  titleFontSize: 14.5,
                  valueText: 'المرحلة 2',
                  onTap: () => _showNextPhaseNotice(context, AppStrings.reportTransfersTitle),
                ),
                OneUiTile(
                  leading: const Icon(
                    AppIcons.tabAeration,
                    color: AppColors.info,
                    size: AppDimensions.iconMedium + 2,
                  ),
                  title: AppStrings.reportAerationTitle,
                  titleFontWeight: FontWeight.w500,
                  titleFontSize: 14.5,
                  valueText: 'المرحلة 2',
                  onTap: () => _showNextPhaseNotice(context, AppStrings.reportAerationTitle),
                ),
              ],
            ],
          ),

          // 4. كرت التحليلات المتقدمة المعتمد
          OneUiCard(
            children: [
              OneUiTile(
                leading: const Icon(
                  AppIcons.analytics,
                  color: AppColors.textPrimary,
                  size: AppDimensions.iconMedium + 2,
                ),
                title: AppStrings.categoryAnalytics,
                titleFontWeight: FontWeight.w900,
                titleFontSize: 17.5,
                trailing: Icon(
                  _isAnalyticsExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary,
                  size: AppDimensions.iconLarge,
                ),
                onTap: () {
                  setState(() => _isAnalyticsExpanded = !_isAnalyticsExpanded);
                },
              ),
              if (_isAnalyticsExpanded) ...[
                OneUiTile(
                  leading: const Icon(
                    AppIcons.dashboard,
                    color: AppColors.primary,
                    size: AppDimensions.iconMedium + 2,
                  ),
                  title: AppStrings.reportGeneralOverviewTitle,
                  titleFontWeight: FontWeight.w500,
                  titleFontSize: 14.5,
                  valueText: 'المرحلة 3',
                  onTap: () => _showNextPhaseNotice(context, AppStrings.reportGeneralOverviewTitle),
                ),
                OneUiTile(
                  leading: const Icon(
                    AppIcons.barChart,
                    color: AppColors.info,
                    size: AppDimensions.iconMedium + 2,
                  ),
                  title: AppStrings.reportPerformanceComparisonTitle,
                  titleFontWeight: FontWeight.w500,
                  titleFontSize: 14.5,
                  valueText: 'المرحلة 3',
                  onTap: () => _showNextPhaseNotice(context, AppStrings.reportPerformanceComparisonTitle),
                ),
              ],
            ],
          ),

          const SizedBox(height: AppDimensions.space3XL),
        ],
      ),
    );
  }

  /// فتح تدفق كشف الحساب: إظهار نافذة الفلترة المعتمدة ثم الانتقال للمعاينة الجدولية
  Future<void> _openStatementFlow(BuildContext context, AccountType accountType) async {
    final result = await ReportFilterSheet.show(
      context: context,
      accountType: accountType,
    );

    if (result != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReportPreviewTableView(
            accountType: accountType,
            initialAccount: result.selectedAccount,
            initialStation: result.selectedStation,
            initialFuelTypeId: result.selectedFuelTypeId,
            initialOperationType: result.selectedOperationType,
            initialFromDate: result.fromDate,
            initialToDate: result.toDate,
            visibleColumns: result.visibleColumns,
          ),
        ),
      );
    }
  }

  /// إشعار المراحل القادمة
  void _showNextPhaseNotice(BuildContext context, String title) {
    AppSnackBar.showInfo(
      context,
      '$title متاح في المرحلة القادمة وفق خطة التطوير',
    );
  }
}
