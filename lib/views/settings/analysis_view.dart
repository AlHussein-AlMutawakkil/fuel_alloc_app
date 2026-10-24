import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/analysis_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/widgets.dart';

/// واجهة تحليل التطبيق والنظام وإحصائيات العمليات والحسابات بنمط One UI
class AnalysisView extends StatefulWidget {
  const AnalysisView({super.key});

  @override
  State<AnalysisView> createState() => _AnalysisViewState();
}

class _AnalysisViewState extends State<AnalysisView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalysisController>().loadAnalysisData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: OneUiAppBar(
        title: AppStrings.analysisTitle,
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(
              AppIcons.refresh,
              color: AppColors.textPrimary,
              size: AppDimensions.iconMedium + 2,
            ),
            tooltip: AppStrings.quickRefresh,
            onPressed: () {
              context.read<AnalysisController>().loadAnalysisData();
            },
          ),
        ],
      ),
      body: Consumer<AnalysisController>(
        builder: (context, controller, _) {
          if (controller.isLoading && controller.data == null) {
            return const Center(child: AppLoadingIndicator());
          }

          final data = controller.data;
          if (data == null) {
            return Center(
              child: EmptyStateWidget(
                icon: AppIcons.analytics,
                title: AppStrings.analysisTitle,
                subtitle: AppStrings.systemHealthIssues,
                actionText: AppStrings.quickRefresh,
                onAction: () => controller.loadAnalysisData(),
              ),
            );
          }

          final isHealthy = controller.isSystemHealthy;

          return ListView(
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.spaceL,
            ),
            children: [
              // 1. بطاقة صحة وسلامة النظام الرئيسية مع زر الفحص الفوري
              OneUiCard(
                padding: const EdgeInsets.all(AppDimensions.spaceXL),
                showDividers: false,
                children: [
                  Row(
                    children: [
                      Container(
                        width: AppDimensions.avatarSize,
                        height: AppDimensions.avatarSize,
                        decoration: BoxDecoration(
                          color: isHealthy
                              ? AppColors.supplyLight
                              : AppColors.warningLight,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isHealthy
                              ? AppIcons.checkCircleRounded
                              : AppIcons.info,
                          color: isHealthy
                              ? AppColors.supplyGreen
                              : AppColors.warning,
                          size: AppDimensions.iconExtraLarge,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spaceL),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              AppStrings.systemHealthStatus,
                              style: TextStyle(
                                fontSize: AppTypography.sizeH2,
                                fontWeight: AppTypography.weightBold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppDimensions.spaceXXS),
                            Text(
                              isHealthy
                                  ? AppStrings.systemHealthExcellent
                                  : AppStrings.systemHealthIssues,
                              style: TextStyle(
                                fontSize: AppTypography.sizeBodySecondary,
                                color: isHealthy
                                    ? AppColors.supplyGreen
                                    : AppColors.warning,
                                fontWeight: AppTypography.weightMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spaceL),
                  CustomButton(
                    text: AppStrings.runDiagnostics,
                    icon: AppIcons.healthAndSafety,
                    isLoading: controller.isRunningDiagnostics,
                    onPressed: () async {
                      await controller.runFullDiagnostics();
                      if (context.mounted &&
                          controller.lastDiagnosticsMessage != null) {
                        AppSnackBar.showSuccess(
                          context,
                          controller.lastDiagnosticsMessage!,
                        );
                      }
                    },
                  ),
                ],
              ),

              // 2. كرت التخزين وفحص قاعدة البيانات
              OneUiCard(
                children: [
                  OneUiTile(
                    leading: const Icon(
                      AppIcons.backupDatabase,
                      color: AppColors.textPrimary,
                      size: AppDimensions.iconMedium + 2,
                    ),
                    title: AppStrings.databaseIntegrity,
                    valueText: data.isDatabaseIntact
                        ? AppStrings.databaseIntegrityOk
                        : AppStrings.systemHealthIssues,
                  ),
                  OneUiTile(
                    leading: const Icon(
                      AppIcons.memory,
                      color: AppColors.textPrimary,
                      size: AppDimensions.iconMedium + 2,
                    ),
                    title: AppStrings.databaseSize,
                    valueText: data.databaseSizeString,
                  ),
                  OneUiTile(
                    leading: const Icon(
                      AppIcons.statement,
                      color: AppColors.textPrimary,
                      size: AppDimensions.iconMedium + 2,
                    ),
                    title: AppStrings.totalDatabaseRecords,
                    valueText: '${data.totalDatabaseRecords}',
                  ),
                  OneUiTile(
                    leading: const Icon(
                      AppIcons.security,
                      color: AppColors.textPrimary,
                      size: AppDimensions.iconMedium + 2,
                    ),
                    title: AppStrings.dataConsistencyCheck,
                    valueText: data.consistencyIssues.isEmpty
                        ? AppStrings.dataConsistencyOk
                        : '${data.consistencyIssues.length}',
                  ),
                ],
              ),

              // 3. كرت تحليل وإحصائيات الحسابات
              OneUiCard(
                children: [
                  OneUiTile(
                    leading: const Icon(
                      AppIcons.navAccountsActive,
                      color: AppColors.textPrimary,
                      size: AppDimensions.iconMedium + 2,
                    ),
                    title: AppStrings.totalAccountsCount,
                    valueText:
                        '${data.totalAccounts} ${AppStrings.accountsCountSuffix}',
                  ),
                  OneUiTile(
                    leading: const Icon(
                      AppIcons.accountOutline,
                      color: AppColors.textPrimary,
                      size: AppDimensions.iconMedium + 2,
                    ),
                    title: AppStrings.beneficiariesCount,
                    valueText:
                        '${data.beneficiariesCount} ${AppStrings.accountsCountSuffix}',
                  ),
                  OneUiTile(
                    leading: const Icon(
                      AppIcons.gasStation,
                      color: AppColors.textPrimary,
                      size: AppDimensions.iconMedium + 2,
                    ),
                    title: AppStrings.stationsCount,
                    valueText:
                        '${data.stationsCount} ${AppStrings.accountsCountSuffix}',
                  ),
                  OneUiTile(
                    leading: const Icon(
                      AppIcons.profile,
                      color: AppColors.textPrimary,
                      size: AppDimensions.iconMedium + 2,
                    ),
                    title: AppStrings.suppliersCount,
                    valueText:
                        '${data.suppliersCount} ${AppStrings.accountsCountSuffix}',
                  ),
                  OneUiTile(
                    leading: const Icon(
                      AppIcons.archive,
                      color: AppColors.textPrimary,
                      size: AppDimensions.iconMedium + 2,
                    ),
                    title: AppStrings.archivedAccountsCount,
                    valueText:
                        '${data.archivedAccounts} ${AppStrings.accountsCountSuffix}',
                  ),
                  OneUiTile(
                    leading: const Icon(
                      AppIcons.recycleBin,
                      color: AppColors.textPrimary,
                      size: AppDimensions.iconMedium + 2,
                    ),
                    title: AppStrings.deletedAccounts,
                    valueText:
                        '${data.deletedAccounts} ${AppStrings.accountsCountSuffix}',
                  ),
                ],
              ),

              // 4. كرت تحليل وتفصيل العمليات والقيود
              OneUiCard(
                children: [
                  OneUiTile(
                    leading: const Icon(
                      AppIcons.statement,
                      color: AppColors.textPrimary,
                      size: AppDimensions.iconMedium + 2,
                    ),
                    title: AppStrings.totalTransactionsCount,
                    valueText:
                        '${data.totalTransactions} ${AppStrings.operationsCountSuffix}',
                  ),
                  OneUiTile(
                    leading: const Icon(
                      AppIcons.tabQuota,
                      color: AppColors.supplyGreen,
                      size: AppDimensions.iconMedium + 2,
                    ),
                    title: AppStrings.supplyQuotaTransactionsTitle,
                    valueText:
                        '${data.supplyQuotaCount} ${AppStrings.operationsCountSuffix} | ${data.supplyQuotaTotalLiters.toStringAsFixed(0)} ${AppStrings.litersUnit}',
                  ),
                  OneUiTile(
                    leading: const Icon(
                      AppIcons.dispense,
                      color: AppColors.dispenseRed,
                      size: AppDimensions.iconMedium + 2,
                    ),
                    title: AppStrings.dispenseQuotaTransactionsTitle,
                    valueText:
                        '${data.dispenseQuotaCount} ${AppStrings.operationsCountSuffix} | ${data.dispenseQuotaTotalLiters.toStringAsFixed(0)} ${AppStrings.litersUnit}',
                  ),
                  OneUiTile(
                    leading: const Icon(
                      AppIcons.supply,
                      color: AppColors.supplyGreen,
                      size: AppDimensions.iconMedium + 2,
                    ),
                    title: AppStrings.supplyActualTransactionsTitle,
                    valueText:
                        '${data.supplyActualCount} ${AppStrings.operationsCountSuffix} | ${data.supplyActualTotalLiters.toStringAsFixed(0)} ${AppStrings.litersUnit}',
                  ),
                  OneUiTile(
                    leading: const Icon(
                      AppIcons.dispense,
                      color: AppColors.dispenseRed,
                      size: AppDimensions.iconMedium + 2,
                    ),
                    title: AppStrings.dispenseActualTransactionsTitle,
                    valueText:
                        '${data.dispenseActualCount} ${AppStrings.operationsCountSuffix} | ${data.dispenseActualTotalLiters.toStringAsFixed(0)} ${AppStrings.litersUnit}',
                  ),
                  OneUiTile(
                    leading: const Icon(
                      AppIcons.tabAeration,
                      color: AppColors.warning,
                      size: AppDimensions.iconMedium + 2,
                    ),
                    title: AppStrings.aerationTransactionsTitle,
                    valueText:
                        '${data.aerationCount} ${AppStrings.operationsCountSuffix} | ${data.aerationTotalLiters.toStringAsFixed(0)} ${AppStrings.litersUnit}',
                  ),
                  OneUiTile(
                    leading: const Icon(
                      AppIcons.transfer,
                      color: AppColors.info,
                      size: AppDimensions.iconMedium + 2,
                    ),
                    title: AppStrings.transferTransactionsTitle,
                    valueText:
                        '${data.transferCount} ${AppStrings.operationsCountSuffix} | ${data.transferTotalLiters.toStringAsFixed(0)} ${AppStrings.litersUnit}',
                  ),
                  OneUiTile(
                    leading: const Icon(
                      AppIcons.recycleBin,
                      color: AppColors.dispenseRed,
                      size: AppDimensions.iconMedium + 2,
                    ),
                    title: AppStrings.deletedTransactionsCount,
                    valueText:
                        '${data.deletedTransactions} ${AppStrings.operationsCountSuffix}',
                  ),
                ],
              ),

              // 5. كرت أصناف الوقود والوحدات
              OneUiCard(
                children: [
                  OneUiTile(
                    leading: const Icon(
                      AppIcons.category,
                      color: AppColors.textPrimary,
                      size: AppDimensions.iconMedium + 2,
                    ),
                    title: AppStrings.fuelTypesCount,
                    valueText: '${data.fuelTypesCount}',
                  ),
                  for (final fuel in data.fuelTypesDetails)
                    OneUiTile(
                      leading: const Icon(
                        AppIcons.gasStationOutlined,
                        color: AppColors.textSecondary,
                        size: AppDimensions.iconMedium,
                      ),
                      title: fuel['name'] as String? ?? '',
                      valueText:
                          '${fuel['tx_count']} ${AppStrings.operationsCountSuffix} (${(fuel['total_liters'] as num).toDouble().toStringAsFixed(0)} ${AppStrings.litersUnit})',
                    ),
                  OneUiTile(
                    leading: const Icon(
                      AppIcons.unit,
                      color: AppColors.textPrimary,
                      size: AppDimensions.iconMedium + 2,
                    ),
                    title: AppStrings.unitsCount,
                    valueText: '${data.unitsCount}',
                  ),
                  for (final unit in data.unitsDetails)
                    OneUiTile(
                      leading: const Icon(
                        AppIcons.unitOutlined,
                        color: AppColors.textSecondary,
                        size: AppDimensions.iconMedium,
                      ),
                      title: unit['name'] as String? ?? '',
                      valueText:
                          '${unit['tx_count']} ${AppStrings.operationsCountSuffix}',
                    ),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceXL),
            ],
          );
        },
      ),
    );
  }
}
