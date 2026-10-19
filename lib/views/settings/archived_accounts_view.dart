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

/// واجهة الأرشيف بنمط One UI لعرض الحسابات المؤرشفة وإلغاء أرشفتها
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
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spaceL,
                    vertical: AppDimensions.spaceM,
                  ),
                  itemCount: accCtrl.archivedAccounts.length,
                  itemBuilder: (ctx, index) {
                    final account = accCtrl.archivedAccounts[index];
                    final isSupplier =
                        account.accountType == AccountType.supplier;

                    return Card(
                      margin:
                          const EdgeInsets.only(bottom: AppDimensions.spaceM),
                      color: AppColors.surface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusL),
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
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusM),
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
                                      const SizedBox(
                                          width: AppDimensions.spaceS),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppDimensions.spaceS + 2,
                                          vertical: 2,
                                        ),
                                          decoration: BoxDecoration(
                                            color: isSupplier
                                                ? AppColors.primary
                                                    .withOpacity(0.1)
                                                : AppColors.supplyGreen
                                                    .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              AppDimensions.radiusS),
                                        ),
                                        child: Text(
                                          isSupplier
                                              ? AppStrings.typeSupplier
                                              : AppStrings.typeBeneficiary,
                                          style: TextStyle(
                                            fontSize:
                                                AppTypography.sizeCaption - 1,
                                            fontWeight:
                                                AppTypography.weightBold,
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
                                        fontSize:
                                            AppTypography.sizeBodySecondary,
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
                                  borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusM),
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
                ),
    );
  }
}
