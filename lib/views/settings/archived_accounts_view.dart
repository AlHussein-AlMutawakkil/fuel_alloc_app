import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/accounts_controller.dart';
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

enum ArchiveTab { accounts, stations }

/// واجهة استعراض الحسابات والمحطات المؤرشفة مع إمكانية استعادتها
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
    });
  }

  Future<void> _unarchiveAccount(AccountModel account) async {
    final isStation = account.accountType == AccountType.station;
    final confirm = await CustomDialog.showConfirmation(
      context: context,
      title: isStation
          ? AppStrings.confirmUnarchiveStationTitle
          : AppStrings.confirmUnarchiveTitle,
      message: isStation
          ? AppStrings.confirmUnarchiveStationMsg
          : AppStrings.confirmUnarchiveMsg,
      confirmText: AppStrings.unarchive,
      cancelText: AppStrings.cancel,
      isDanger: false,
    );
    if (!confirm || !mounted) return;

    final success =
        await context.read<AccountsController>().unarchiveAccount(account.id!);
    if (success && mounted) {
      AppSnackBar.showSuccess(
        context,
        isStation
            ? AppStrings.stationUnarchivedSuccess
            : AppStrings.accountUnarchivedSuccess,
      );
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
              context.read<AccountsController>().fetchArchivedAccounts();
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

    final isStationTab = _activeTab == ArchiveTab.stations;
    final filtered = accCtrl.archivedAccounts.where((a) =>
        isStationTab
            ? a.accountType == AccountType.station
            : a.accountType != AccountType.station).toList();

    if (filtered.isEmpty) {
      return EmptyStateWidget(
        icon: isStationTab ? AppIcons.gasStationOutlined : AppIcons.archive,
        title: isStationTab
            ? AppStrings.noArchivedStations
            : AppStrings.noArchivedAccounts,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceL,
        vertical: AppDimensions.spaceM,
      ),
      itemCount: filtered.length,
      itemBuilder: (ctx, index) {
        final account = filtered[index];
        final isStation = account.accountType == AccountType.station;
        final isSupplier = account.accountType == AccountType.supplier;

        final badgeText = isStation
            ? AppStrings.typeStation
            : (isSupplier ? AppStrings.typeSupplier : AppStrings.typeBeneficiary);

        final badgeColor = isStation
            ? AppColors.warning
            : (isSupplier ? AppColors.primary : AppColors.supplyGreen);

        String subText = '';
        if (isStation && account.location != null && account.location!.isNotEmpty) {
          subText = account.location!;
        } else if (account.phoneNumber != null && account.phoneNumber!.isNotEmpty) {
          subText = account.phoneNumber!;
        }

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
                    color: badgeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: Icon(
                    isStation ? AppIcons.gasStation : AppIcons.archive,
                    color: badgeColor,
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
                          Flexible(
                            child: Text(
                              account.name,
                              style: const TextStyle(
                                fontSize: AppTypography.sizeH2,
                                fontWeight: AppTypography.weightBold,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spaceS),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.spaceS + 2,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(AppDimensions.radiusS),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: AppTypography.sizeCaption - 1,
                                fontWeight: AppTypography.weightBold,
                                color: badgeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (subText.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subText,
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

  @override
  Widget build(BuildContext context) {
    final accCtrl = context.watch<AccountsController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const OneUiAppBar(
        title: AppStrings.archiveTitle,
      ),
      body: Column(
        children: [
          _buildSegmentControl(),
          Expanded(
            child: _buildAccountsList(accCtrl),
          ),
        ],
      ),
    );
  }
}
