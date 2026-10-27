import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/accounts_controller.dart';
import '../../controllers/analysis_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/backup_controller.dart';
import '../../controllers/personal_info_controller.dart';
import '../../controllers/stations_controller.dart';
import '../../controllers/transactions_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/one_ui_card.dart';
import '../../core/widgets/operation_entry_sheet.dart';
import '../../core/widgets/transaction_details_dialog.dart';
import '../accounts/station_transactions_view.dart';
import '../accounts/widgets/fuel_summary_card.dart';
import '../settings/analysis_view.dart';
import '../settings/backup_settings_view.dart';

/// الشاشة الرئيسية (لوحة التحكم العامة) بنمط Samsung One UI الموحد
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _selectedFuelId = 1; // 1: بترول, 2: ديزل

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAllData();
    });
  }

  Future<void> _refreshAllData() async {
    if (!mounted) return;
    await Future.wait([
      context.read<TransactionsController>().fetchAllBalancesSummary(),
      context.read<AccountsController>().fetchAccounts(),
      context.read<StationsController>().fetchStations(),
      context.read<AnalysisController>().loadAnalysisData(),
      context.read<PersonalInfoController>().loadPersonalInfo(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: _refreshAllData,
          child: Consumer6<
              TransactionsController,
              AccountsController,
              StationsController,
              PersonalInfoController,
              AuthController,
              AnalysisController>(
            builder: (context, txCtrl, accCtrl, stCtrl, personalCtrl, authCtrl,
                analysisCtrl, _) {
              return ListView(
                padding: const EdgeInsets.only(bottom: AppDimensions.space4XL),
                children: [
                  // 1. الترويسة العلوية الترحيبية وفحص سلامة النظام
                  _buildHeader(personalCtrl, authCtrl, analysisCtrl),

                  // 2. بطاقة المؤشرات والأرصدة الكلية للأصناف
                  _buildFuelBalancesSection(txCtrl),

                  const SizedBox(height: AppDimensions.spaceS),

                  // 3. شريط الوصول السريع للعمليات الميدانية
                  _buildQuickActionsSection(),

                  const SizedBox(height: AppDimensions.spaceS),

                  // 4. حالة ومخزون المحطات النشطة
                  _buildStationsStockSection(stCtrl),

                  const SizedBox(height: AppDimensions.spaceS),

                  // 5. آخر العمليات الميدانية المسجلة
                  _buildRecentTransactionsSection(txCtrl),

                  const SizedBox(height: AppDimensions.spaceS),

                  // 6. بطاقة أمان البيانات والنسخ الاحتياطي
                  _buildBackupCard(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // --- 1. الترويسة العلوية ---
  Widget _buildHeader(
    PersonalInfoController personalCtrl,
    AuthController authCtrl,
    AnalysisController analysisCtrl,
  ) {
    final hasLogo = personalCtrl.info.logoPath != null &&
        File(personalCtrl.info.logoPath!).existsSync();
    final displayName = personalCtrl.info.arabicName.trim().isNotEmpty
        ? personalCtrl.info.arabicName.trim()
        : (authCtrl.isLoggedIn && authCtrl.displayName.trim().isNotEmpty
            ? authCtrl.displayName.trim()
            : AppStrings.welcomeBack);

    final isHealthy = analysisCtrl.isSystemHealthy;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spaceXL,
        AppDimensions.spaceXL,
        AppDimensions.spaceXL,
        AppDimensions.spaceM,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // الشعار أو الأيقونة الدائرية
          Container(
            width: AppDimensions.avatarSize,
            height: AppDimensions.avatarSize,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.borderLight,
                width: AppDimensions.borderWidthThin,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasLogo
                ? Image.file(
                    File(personalCtrl.info.logoPath!),
                    fit: BoxFit.cover,
                  )
                : const Center(
                    child: Icon(
                      AppIcons.gasStation,
                      color: AppColors.textWhite,
                      size: AppDimensions.iconLarge,
                    ),
                  ),
          ),
          const SizedBox(width: AppDimensions.spaceL),

          // التحية والاسم
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  AppStrings.welcomeBack,
                  style: TextStyle(
                    fontSize: AppTypography.sizeCaption,
                    color: AppColors.textTertiary,
                    fontWeight: AppTypography.weightMedium,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceXXS),
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: AppTypography.sizeH2 + 1,
                    fontWeight: AppTypography.weightBold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spaceS),

          // شارة فحص حالة النظام التفاعلية
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnalysisView()),
              );
            },
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceL,
                vertical: AppDimensions.spaceS - 1,
              ),
              decoration: BoxDecoration(
                color:
                    isHealthy ? AppColors.supplyLight : AppColors.warningLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                border: Border.all(
                  color: isHealthy ? AppColors.supplyGreen : AppColors.warning,
                  width: AppDimensions.borderWidthHairline,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isHealthy ? AppIcons.checkCircleRounded : AppIcons.info,
                    size: AppDimensions.iconSmall,
                    color:
                        isHealthy ? AppColors.supplyGreen : AppColors.warning,
                  ),
                  const SizedBox(width: AppDimensions.spaceXS),
                  Text(
                    isHealthy
                        ? AppStrings.secureAndHealthy
                        : AppStrings.needsAttention,
                    style: TextStyle(
                      fontSize: AppTypography.sizeMicro + 1,
                      fontWeight: AppTypography.weightBold,
                      color:
                          isHealthy ? AppColors.supplyGreen : AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. بطاقة المؤشرات والأرصدة الكلية للأصناف ---
  Widget _buildFuelBalancesSection(TransactionsController txCtrl) {
    final fuelTypes = txCtrl.fuelTypes.isNotEmpty
        ? txCtrl.fuelTypes
        : [
            {'id': 1, 'name': AppStrings.fuelPetrol},
            {'id': 2, 'name': AppStrings.fuelDiesel},
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSectionHeader(
          title: AppStrings.fuelBalancesOverview,
          icon: AppIcons.gasStation,
          trailing: IconButton(
            icon: const Icon(
              AppIcons.refresh,
              size: AppDimensions.iconMedium,
              color: AppColors.textTertiary,
            ),
            tooltip: AppStrings.quickRefresh,
            onPressed: () {
              txCtrl.fetchAllBalancesSummary();
            },
          ),
        ),
        FuelSummarySlider(
          fuelTypes: fuelTypes,
          selectedFuelId: _selectedFuelId,
          onFuelChanged: (newId) {
            setState(() {
              _selectedFuelId = newId;
            });
          },
          cardBuilder: (fuelId, fuelName) {
            // استخراج إجماليات الصنف من ملخص العمليات الكلي
            double totalQuota = 0.0;
            double totalDispensed = 0.0;

            final summaryRow = txCtrl.fuelTotalsSummary.firstWhere(
              (r) => r['fuel_type_id'] == fuelId,
              orElse: () => <String, dynamic>{},
            );

            if (summaryRow.isNotEmpty) {
              totalQuota = (summaryRow['total_quota'] as num?)?.toDouble() ?? 0.0;
              totalDispensed =
                  (summaryRow['total_actual_dispensed'] as num?)?.toDouble() ?? 0.0;
            }

            final balance = totalQuota - totalDispensed;

            // حساب إجمالي المخزون الحالي في المحطات لهذا الصنف
            double stationStock = 0.0;
            for (final stBalances in txCtrl.allStationBalances.values) {
              stationStock += (stBalances[fuelId] ?? 0.0);
            }

            return FuelCardData(
              title: AppStrings.fuelBalancesOverview,
              fuelName: fuelName,
              balance: balance,
              secondaryTag: stationStock > 0
                  ? '${AppFormatters.formatQuantity(stationStock)} ${AppStrings.unitLiter}'
                  : null,
              metrics: [
                FuelCardMetric(
                  value: totalQuota,
                  label: AppStrings.allocatedQuota,
                  valueColor: AppColors.primary,
                ),
                FuelCardMetric(
                  value: totalDispensed,
                  label: AppStrings.actualDispensed,
                  valueColor: AppColors.dispenseRed,
                ),
                FuelCardMetric(
                  value: balance,
                  label: AppStrings.balanceQuota,
                  valueColor: AppColors.supplyGreen,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // --- 3. شريط الوصول السريع للعمليات الميدانية ---
  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSectionHeader(
          title: AppStrings.quickActions,
          icon: AppIcons.flash,
        ),
        OneUiCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceL,
            vertical: AppDimensions.spaceL,
          ),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // زر صرف مخصص
                _buildQuickActionItem(
                  icon: AppIcons.dispense,
                  label: AppStrings.dispenseQuotaAction,
                  iconColor: AppColors.dispenseRed,
                  backgroundColor: AppColors.dispenseLight,
                  onTap: () {
                    OperationEntrySheet.show(
                      context: context,
                      initialTabIndex: 0,
                      initialDirection: 1, // صرف
                    ).then((_) {
                      if (mounted) _refreshAllData();
                    });
                  },
                ),

                // زر تغذية مخصص
                _buildQuickActionItem(
                  icon: AppIcons.supply,
                  label: AppStrings.supplyQuotaAction,
                  iconColor: AppColors.supplyGreen,
                  backgroundColor: AppColors.supplyLight,
                  onTap: () {
                    OperationEntrySheet.show(
                      context: context,
                      initialTabIndex: 0,
                      initialDirection: 0, // توريد
                    ).then((_) {
                      if (mounted) _refreshAllData();
                    });
                  },
                ),

                // زر تحويل كميات
                _buildQuickActionItem(
                  icon: AppIcons.transfer,
                  label: AppStrings.transferAction,
                  iconColor: AppColors.info,
                  backgroundColor: AppColors.infoLight,
                  onTap: () {
                    OperationEntrySheet.show(
                      context: context,
                      initialTabIndex: 3, // تحويل
                    ).then((_) {
                      if (mounted) _refreshAllData();
                    });
                  },
                ),

                // زر تسجيل حركة عامة
                _buildQuickActionItem(
                  icon: AppIcons.addRounded,
                  label: AppStrings.registerOperation,
                  iconColor: AppColors.textPrimary,
                  backgroundColor: AppColors.chipBackground,
                  onTap: () {
                    OperationEntrySheet.show(context: context).then((_) {
                      if (mounted) _refreshAllData();
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceXS),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: AppDimensions.iconMedium + 2,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spaceS),
              Text(
                label,
                style: const TextStyle(
                  fontSize: AppTypography.sizeCaption,
                  fontWeight: AppTypography.weightSemiBold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 4. مخزون المحطات النشطة ---
  Widget _buildStationsStockSection(StationsController stCtrl) {
    final stations = stCtrl.stations;
    if (stations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSectionHeader(
          title: AppStrings.stationsOverview,
          icon: AppIcons.gasStation,
        ),
        OneUiCard(
          children: stations.take(4).map((station) {
            return OneUiTile(
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.chipBackground,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: const Icon(
                  AppIcons.gasStation,
                  color: AppColors.primary,
                  size: AppDimensions.iconMedium,
                ),
              ),
              title: station.name,
              subtitle: station.location ?? AppStrings.station,
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${AppFormatters.formatQuantity(station.currentBalance)} ${AppStrings.unitLiter}',
                    style: const TextStyle(
                      fontSize: AppTypography.sizeBody,
                      fontWeight: AppTypography.weightBold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Text(
                    AppStrings.stationStock,
                    style: TextStyle(
                      fontSize: AppTypography.sizeMicro,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              showChevron: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StationTransactionsView(station: station),
                  ),
                ).then((_) {
                  if (mounted) _refreshAllData();
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // --- 5. آخر العمليات الميدانية المسجلة ---
  Widget _buildRecentTransactionsSection(TransactionsController txCtrl) {
    final recent = txCtrl.recentTransactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSectionHeader(
          title: AppStrings.recentOperations,
          icon: AppIcons.statement,
        ),
        if (recent.isNotEmpty)
          OneUiCard(
            children: recent.take(5).map((tx) {
              final isSupply = tx.isSupply;
              final isDispense = tx.isDispense;
              final isTransfer = tx.typeId == 6 || tx.typeId == 7;

              IconData txIcon = AppIcons.gasStation;
              Color iconColor = AppColors.primary;
              Color iconBg = AppColors.chipBackground;

              if (isSupply) {
                txIcon = AppIcons.supply;
                iconColor = AppColors.supplyGreen;
                iconBg = AppColors.supplyLight;
              } else if (isDispense) {
                txIcon = AppIcons.dispense;
                iconColor = AppColors.dispenseRed;
                iconBg = AppColors.dispenseLight;
              } else if (isTransfer) {
                txIcon = AppIcons.transfer;
                iconColor = AppColors.info;
                iconBg = AppColors.infoLight;
              }

              final title = tx.accountName ??
                  tx.stationName ??
                  tx.typeName ??
                  AppStrings.operationLabel;

              final subtitle = [
                if (tx.fuelTypeName != null) tx.fuelTypeName!,
                AppFormatters.formatTransactionDateTime(
                    tx.transactionDate, tx.createdAt),
                if (tx.recipientName != null && tx.recipientName!.isNotEmpty)
                  tx.recipientName!,
              ].join(' • ');

              final quantityPrefix = isSupply ? '+' : (isDispense ? '-' : '');
              final quantityColor = isSupply
                  ? AppColors.supplyGreen
                  : (isDispense ? AppColors.dispenseRed : AppColors.textPrimary);

              return OneUiTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: Icon(
                    txIcon,
                    color: iconColor,
                    size: AppDimensions.iconMedium,
                  ),
                ),
                title: title,
                subtitle: subtitle,
                trailing: Text(
                  '$quantityPrefix ${AppFormatters.formatQuantity(tx.baseQuantityLiters)} ${AppStrings.unitLiter}',
                  style: TextStyle(
                    fontSize: AppTypography.sizeBody,
                    fontWeight: AppTypography.weightBold,
                    color: quantityColor,
                  ),
                ),
                showChevron: true,
                onTap: () {
                  TransactionDetailsDialog.show(
                    context: context,
                    transaction: tx,
                  );
                },
              );
            }).toList(),
          )
        else
          const OneUiCard(
            padding: EdgeInsets.symmetric(vertical: AppDimensions.spaceXL),
            children: [
              EmptyStateWidget(
                icon: AppIcons.statement,
                title: AppStrings.noRecentOperations,
              ),
            ],
          ),
      ],
    );
  }

  // --- 6. بطاقة أمان البيانات والنسخ الاحتياطي ---
  Widget _buildBackupCard() {
    return Consumer<BackupController>(
      builder: (context, backupCtrl, _) {
        final lastBackupText = backupCtrl.lastCloudSyncFormatted;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSectionHeader(
              title: AppStrings.backupAndSecurity,
              icon: AppIcons.security,
            ),
            OneUiCard(
              children: [
                OneUiTile(
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.infoLight,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusM),
                    ),
                    child: const Icon(
                      AppIcons.backup,
                      color: AppColors.info,
                      size: AppDimensions.iconMedium,
                    ),
                  ),
                  title: AppStrings.cloudBackup,
                  subtitle: lastBackupText,
                  showChevron: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BackupSettingsView(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // --- عنوان القسم الموحد ---
  Widget _buildSectionHeader({
    required String title,
    Widget? trailing,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spaceXL,
        AppDimensions.spaceL,
        AppDimensions.spaceXL,
        AppDimensions.spaceS,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: AppDimensions.iconSmall + 2,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: AppDimensions.spaceS),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: AppTypography.sizeBody + 1,
                  fontWeight: AppTypography.weightBold,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
