import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/accounts_controller.dart';
import '../../controllers/stations_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/custom_dialog.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/one_ui_card.dart';
import '../../models/account_model.dart';
import '../../models/station_model.dart';

enum ArchiveTab { accounts, stations }

/// واجهة الأرشيف بنمط One UI لعرض الحسابات والمحطات المؤرشفة وإلغاء أرشفتها
class ArchivedAccountsView extends StatefulWidget {
  const ArchivedAccountsView({super.key});

  @override
  State<ArchivedAccountsView> createState() => _ArchivedAccountsViewState();
}

class _ArchivedAccountsViewState extends State<ArchivedAccountsView> {
  ArchiveTab _activeTab = ArchiveTab.accounts;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountsController>().fetchArchivedAccounts();
      context.read<StationsController>().fetchArchivedStations();
    });
  }

  Future<void> _unarchiveAccount(AccountModel account) async {
    final confirm = await CustomDialog.showConfirmation(
      context: context,
      title: AppStrings.confirmUnarchiveTitle,
      message: AppStrings.confirmUnarchiveMsg,
      confirmText: AppStrings.unarchive,
      cancelText: AppStrings.cancel,
      isDanger: false,
    );
    if (!confirm || !mounted) return;

    final success =
        await context.read<AccountsController>().unarchiveAccount(account.id!);
    if (success && mounted) {
      AppSnackBar.showSuccess(context, AppStrings.accountUnarchivedSuccess);
    }
  }

  Future<void> _unarchiveStation(StationModel station) async {
    final confirm = await CustomDialog.showConfirmation(
      context: context,
      title: AppStrings.confirmUnarchiveStationTitle,
      message: AppStrings.confirmUnarchiveStationMsg,
      confirmText: AppStrings.unarchive,
      cancelText: AppStrings.cancel,
      isDanger: false,
    );
    if (!confirm || !mounted) return;

    final success =
        await context.read<StationsController>().unarchiveStation(station.id!);
    if (success && mounted) {
      AppSnackBar.showSuccess(context, AppStrings.stationUnarchivedSuccess);
    }
  }

  Widget _buildSegmentControl() {
    return Container(
      margin: AppDimensions.paddingSegment,
      padding: AppDimensions.paddingAllXS,
      decoration: const BoxDecoration(
        color: AppColors.segmentBackground,
        borderRadius: AppDimensions.borderRadiusXL,
      ),
      child: Row(
        children: [
          _buildSegmentItem(
            label: AppStrings.archivedAccountsTab,
            isSelected: _activeTab == ArchiveTab.accounts,
            onTap: () {
              setState(() => _activeTab = ArchiveTab.accounts);
              context.read<AccountsController>().fetchArchivedAccounts();
            },
          ),
          _buildSegmentItem(
            label: AppStrings.archivedStationsTab,
            isSelected: _activeTab == ArchiveTab.stations,
            onTap: () {
              setState(() => _activeTab = ArchiveTab.stations);
              context.read<StationsController>().fetchArchivedStations();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentItem({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : Colors.transparent,
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
            label,
            style: TextStyle(
              fontSize: AppTypography.sizeBody,
              fontWeight: isSelected
                  ? AppTypography.weightBold
                  : AppTypography.weightMedium,
              color:
                  isSelected ? AppColors.textPrimary : AppColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountsList(AccountsController accCtrl) {
    if (accCtrl.isLoading) {
      return const Center(child: AppLoadingIndicator());
    }

    if (accCtrl.archivedAccounts.isEmpty) {
      return const EmptyStateWidget(
        icon: AppIcons.archive,
        title: AppStrings.noArchivedAccounts,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceL,
        vertical: AppDimensions.spaceM,
      ),
      itemCount: accCtrl.archivedAccounts.length,
      itemBuilder: (ctx, index) {
        final account = accCtrl.archivedAccounts[index];
        final isSupplier = account.accountType == AccountType.supplier;

        return Card(
          margin: const EdgeInsets.only(bottom: AppDimensions.spaceM),
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            side: const BorderSide(color: AppColors.borderLight),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceL),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: const Icon(
                    AppIcons.archive,
                    color: AppColors.textSecondary,
                    size: AppDimensions.iconMedium,
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceL),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            account.name,
                            style: const TextStyle(
                              fontSize: AppTypography.sizeH2,
                              fontWeight: AppTypography.weightBold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spaceS),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.spaceS + 2,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isSupplier
                                  ? AppColors.primary.withOpacity(0.1)
                                  : AppColors.supplyGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusS),
                            ),
                            child: Text(
                              isSupplier
                                  ? AppStrings.typeSupplier
                                  : AppStrings.typeBeneficiary,
                              style: TextStyle(
                                fontSize: AppTypography.sizeCaption - 1,
                                fontWeight: AppTypography.weightBold,
                                color: isSupplier
                                    ? AppColors.primary
                                    : AppColors.supplyGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (account.phoneNumber != null &&
                          account.phoneNumber!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          account.phoneNumber!,
                          style: const TextStyle(
                            fontSize: AppTypography.sizeBodySecondary,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(
                    AppIcons.unarchive,
                    size: 16,
                    color: AppColors.textWhite,
                  ),
                  label: const Text(
                    AppStrings.unarchive,
                    style: TextStyle(
                      color: AppColors.textWhite,
                      fontSize: AppTypography.sizeCaption,
                      fontWeight: AppTypography.weightBold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusM),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spaceL,
                      vertical: 8,
                    ),
                  ),
                  onPressed: () => _unarchiveAccount(account),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStationsList(StationsController stCtrl) {
    if (stCtrl.isLoading) {
      return const Center(child: AppLoadingIndicator());
    }

    if (stCtrl.archivedStations.isEmpty) {
      return const EmptyStateWidget(
        icon: AppIcons.archive,
        title: AppStrings.noArchivedStations,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceL,
        vertical: AppDimensions.spaceM,
      ),
      itemCount: stCtrl.archivedStations.length,
      itemBuilder: (ctx, index) {
        final station = stCtrl.archivedStations[index];

        return Card(
          margin: const EdgeInsets.only(bottom: AppDimensions.spaceM),
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            side: const BorderSide(color: AppColors.borderLight),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceL),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: const Icon(
                    AppIcons.gasStation,
                    color: AppColors.textSecondary,
                    size: AppDimensions.iconMedium,
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceL),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station.name,
                        style: const TextStyle(
                          fontSize: AppTypography.sizeH2,
                          fontWeight: AppTypography.weightBold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (station.location != null &&
                          station.location!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          station.location!,
                          style: const TextStyle(
                            fontSize: AppTypography.sizeBodySecondary,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(
                    AppIcons.unarchive,
                    size: 16,
                    color: AppColors.textWhite,
                  ),
                  label: const Text(
                    AppStrings.unarchive,
                    style: TextStyle(
                      color: AppColors.textWhite,
                      fontSize: AppTypography.sizeCaption,
                      fontWeight: AppTypography.weightBold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusM),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spaceL,
                      vertical: 8,
                    ),
                  ),
                  onPressed: () => _unarchiveStation(station),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final accCtrl = context.watch<AccountsController>();
    final stCtrl = context.watch<StationsController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const OneUiAppBar(
        title: AppStrings.archiveTitle,
      ),
      body: Column(
        children: [
          _buildSegmentControl(),
          Expanded(
            child: _activeTab == ArchiveTab.accounts
                ? _buildAccountsList(accCtrl)
                : _buildStationsList(stCtrl),
          ),
        ],
      ),
    );
  }
}
