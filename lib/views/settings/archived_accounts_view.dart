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

/// واجهة استعراض الحسابات والمحطات المؤرشفة مع إمكانية استعادتها
class ArchivedAccountsView extends StatefulWidget {
  const ArchivedAccountsView({super.key});

  @override
  State<ArchivedAccountsView> createState() => _ArchivedAccountsViewState();
}

class _ArchivedAccountsViewState extends State<ArchivedAccountsView> {
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

  Widget _buildAccountsList(AccountsController accCtrl) {
    if (accCtrl.isLoading) {
      return const Center(child: AppLoadingIndicator());
    }

    final archived = accCtrl.archivedAccounts;

    if (archived.isEmpty) {
      return const EmptyStateWidget(
        icon: AppIcons.archive,
        title: AppStrings.noArchivedAccounts,
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: archived.length,
      itemBuilder: (ctx, index) {
        final account = archived[index];
        final isStation = account.accountType == AccountType.station;
        final isSupplier = account.accountType == AccountType.supplier;

        final badgeText = isStation
            ? AppStrings.typeStation
            : (isSupplier ? AppStrings.typeSupplier : AppStrings.typeBeneficiary);

        String subText = '';
        if (isStation && account.location != null && account.location!.isNotEmpty) {
          subText = account.location!;
        } else if (account.phoneNumber != null && account.phoneNumber!.isNotEmpty) {
          subText = account.phoneNumber!;
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: AppDimensions.paddingTile,
              child: Row(
                children: [
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
                                  fontWeight: AppTypography.weightSemiBold,
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
                                color: AppColors.segmentBackground,
                                borderRadius:
                                    BorderRadius.circular(AppDimensions.radiusS),
                              ),
                              child: Text(
                                badgeText,
                                style: const TextStyle(
                                  fontSize: AppTypography.sizeCaption - 1,
                                  fontWeight: AppTypography.weightSemiBold,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (subText.isNotEmpty) ...[
                          const SizedBox(height: AppDimensions.spaceXS),
                          Text(
                            subText,
                            style: const TextStyle(
                              fontSize: AppTypography.sizeBodySecondary,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceM),
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
            const OneUiDivider(
              indent: AppDimensions.dividerIndentCompact,
              endIndent: AppDimensions.dividerIndentCompact,
            ),
          ],
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
      body: accCtrl.isLoading
          ? const Center(child: AppLoadingIndicator())
          : accCtrl.archivedAccounts.isEmpty
              ? const EmptyStateWidget(
                  icon: AppIcons.archive,
                  title: AppStrings.noArchivedAccounts,
                )
              : OneUiListContainer(
                  child: _buildAccountsList(accCtrl),
                ),
    );
  }
}
