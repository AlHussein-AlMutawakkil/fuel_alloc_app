import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/accounts_controller.dart';
import '../../controllers/transactions_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/contact_picker_sheet.dart';
import '../../core/widgets/custom_dialog.dart';
import '../../core/widgets/custom_dropdown.dart';
import '../../core/widgets/custom_modal_sheet.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/one_ui_card.dart';
import '../../models/account_model.dart';
import 'account_transactions_view.dart';
import 'widgets/slidable_account_tile.dart';

enum AccountFilterTab { beneficiaries, suppliers, stations }

/// واجهة إدارة الحسابات والمحطات (المستفيدين - الموردين - المحطات) بتصميم One UI
class AccountsView extends StatefulWidget {
  const AccountsView({super.key});

  @override
  State<AccountsView> createState() => _AccountsViewState();
}

class _AccountsViewState extends State<AccountsView> {
  final TextEditingController _searchController = TextEditingController();
  AccountFilterTab _activeTab = AccountFilterTab.beneficiaries;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final accCtrl = context.read<AccountsController>();
      accCtrl.fetchAccounts();
      accCtrl.setTypeFilter(AccountType.beneficiary);
      context.read<TransactionsController>().fetchAllBalancesSummary();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- نوافذ الحسابات ---

  void _showAddEditDialog({AccountModel? account, AccountType? defaultType}) {
    final nameController = TextEditingController(text: account?.name ?? '');
    final phoneController =
        TextEditingController(text: account?.phoneNumber ?? '');
    final locationController =
        TextEditingController(text: account?.location ?? '');
    final commissionController = TextEditingController(
      text: account != null
          ? account.defaultCommissionRate.toString()
          : '2.0',
    );
    AccountType selectedType =
        account?.accountType ?? defaultType ?? AccountType.beneficiary;

    CustomModalSheet.show(
      context: context,
      title: account == null
          ? (selectedType == AccountType.station
              ? AppStrings.addStation
              : (selectedType == AccountType.supplier
                  ? AppStrings.addSupplier
                  : AppStrings.addBeneficiary))
          : (account.accountType == AccountType.station
              ? AppStrings.editStation
              : AppStrings.editAccount),
      contentBuilder: (ctx, setModalState) {
        final isStation = selectedType == AccountType.station;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomModalSheet.buildTextField(
              label: isStation
                  ? AppStrings.stationNameLabel
                  : AppStrings.accountName,
              controller: nameController,
            ),
            const SizedBox(height: AppDimensions.spaceL),
            CustomModalSheet.buildLabel(AppStrings.accountType),
            CustomDropdown<AccountType>(
              value: selectedType,
              borderColor: CustomModalSheet.fieldBorderColor,
              backgroundColor: AppColors.background,
              items: const [
                CustomDropdownItem(
                  value: AccountType.beneficiary,
                  label: AppStrings.typeBeneficiary,
                ),
                CustomDropdownItem(
                  value: AccountType.supplier,
                  label: AppStrings.typeSupplier,
                ),
                CustomDropdownItem(
                  value: AccountType.station,
                  label: AppStrings.typeStation,
                ),
              ],
              onChanged: (val) {
                setModalState(() {
                  selectedType = val;
                });
              },
            ),
            if (isStation) ...[
              const SizedBox(height: AppDimensions.spaceL),
              CustomModalSheet.buildTextField(
                label: AppStrings.locationCityLabel,
                controller: locationController,
              ),
              const SizedBox(height: AppDimensions.spaceL),
              CustomModalSheet.buildTextField(
                label: AppStrings.commissionRatePercentLabel,
                controller: commissionController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
            const SizedBox(height: AppDimensions.spaceL),
            CustomModalSheet.buildTextField(
              label: AppStrings.phoneNumber,
              controller: phoneController,
              keyboardType: TextInputType.phone,
              suffixIcon: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: const Icon(
                  AppIcons.contacts,
                  color: AppColors.primary,
                  size: 20,
                ),
                tooltip: AppStrings.pickFromContacts,
                onPressed: () async {
                  final contact = await ContactPickerSheet.show(context);
                  if (contact != null) {
                    setModalState(() {
                      phoneController.text = contact.phone;
                      if (nameController.text.trim().isEmpty) {
                        nameController.text = contact.name;
                      }
                    });
                  }
                },
              ),
            ),
          ],
        );
      },
      onSave: (ctx) async {
        final name = nameController.text.trim();
        if (name.isEmpty) return;

        final navigator = Navigator.of(ctx);
        final controller = context.read<AccountsController>();
        final commRate =
            double.tryParse(commissionController.text.trim()) ?? 2.0;

        if (account == null) {
          if (selectedType == AccountType.station) {
            await controller.addStation(
              name: name,
              location: locationController.text.trim().isEmpty
                  ? null
                  : locationController.text.trim(),
              phone: phoneController.text.trim().isEmpty
                  ? null
                  : phoneController.text.trim(),
              defaultCommission: commRate,
            );
          } else {
            await controller.addAccount(
              name,
              selectedType,
              phoneController.text.trim().isEmpty
                  ? null
                  : phoneController.text.trim(),
            );
          }
        } else {
          await controller.updateAccount(
            account.copyWith(
              name: name,
              accountType: selectedType,
              location: locationController.text.trim().isEmpty
                  ? null
                  : locationController.text.trim(),
              defaultCommissionRate: commRate,
              phoneNumber: phoneController.text.trim().isEmpty
                  ? null
                  : phoneController.text.trim(),
            ),
          );
        }
        navigator.pop();
      },
    );
  }

  void _deleteAccount(AccountModel account) async {
    final isStation = account.accountType == AccountType.station;
    final confirm = await CustomDialog.showConfirmation(
      context: context,
      title: AppStrings.confirmExclamation,
      message: isStation
          ? AppStrings.confirmDeleteStationMsg
          : AppStrings.confirmDeleteAccountMsg,
      confirmText: AppStrings.ok,
      cancelText: AppStrings.cancel,
      isDanger: true,
    );

    if (confirm && account.id != null && mounted) {
      await context.read<AccountsController>().deleteAccount(account.id!);
      if (mounted) {
        context.read<TransactionsController>().fetchAllBalancesSummary();
      }
    }
  }

  void _archiveAccount(AccountModel account) async {
    final isStation = account.accountType == AccountType.station;
    final confirm = await CustomDialog.showConfirmation(
      context: context,
      title: isStation
          ? AppStrings.archiveStationTitle
          : AppStrings.archiveAccountTitle,
      message: isStation
          ? 'هل تريد أرشفة محطة "${account.name}"؟ سيتم نقلها للأرشيف مع حفظ كافة كشوفاتها وسجلاتها.'
          : AppStrings.confirmArchiveAccountMsg,
      confirmText: AppStrings.archive,
      cancelText: AppStrings.cancel,
      isDanger: false,
    );

    if (confirm && account.id != null && mounted) {
      final success =
          await context.read<AccountsController>().archiveAccount(account.id!);
      if (success && mounted) {
        AppSnackBar.showSuccess(
          context,
          isStation
              ? AppStrings.stationArchivedSuccess
              : AppStrings.accountArchivedSuccess,
        );
        context.read<TransactionsController>().fetchAllBalancesSummary();
      }
    }
  }


  void _navigateToTransactions(AccountModel account) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => AccountTransactionsView(account: account),
      ),
    )
        .then((_) {
      if (mounted) {
        context.read<TransactionsController>().fetchAllBalancesSummary();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountsController>(
      builder: (context, accController, child) {
        final isStationTab = _activeTab == AccountFilterTab.stations;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: _isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: AppTypography.sizeBody + 1,
                    ),
                    cursorColor: AppColors.textWhite,
                    decoration: InputDecoration(
                      hintText: isStationTab
                          ? AppStrings.searchStationsHint
                          : (_activeTab == AccountFilterTab.suppliers
                              ? AppStrings.searchSuppliersHint
                              : AppStrings.searchBeneficiariesHint),
                      hintStyle: TextStyle(
                        color: AppColors.textWhite.withOpacity(0.7),
                      ),
                      border: InputBorder.none,
                    ),
                    onChanged: (val) {
                      accController.setSearchQuery(val);
                    },
                  )
                : Text(
                    isStationTab
                        ? AppStrings.fuelStationsTabTitle
                        : (_activeTab == AccountFilterTab.suppliers
                            ? AppStrings.suppliersTab
                            : AppStrings.beneficiariesTab),
                    style: AppTypography.appBarTitle,
                  ),
            actions: [
              IconButton(
                icon: Icon(_isSearching ? AppIcons.close : AppIcons.search),
                tooltip:
                    _isSearching ? AppStrings.closeSearch : AppStrings.search,
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchController.clear();
                      accController.setSearchQuery('');
                    }
                  });
                },
              ),
              IconButton(
                icon: const Icon(AppIcons.add),
                tooltip: isStationTab
                    ? AppStrings.addStation
                    : (_activeTab == AccountFilterTab.suppliers
                        ? AppStrings.addSupplier
                        : AppStrings.addBeneficiary),
                onPressed: () {
                  _showAddEditDialog(
                    defaultType: isStationTab
                        ? AccountType.station
                        : (_activeTab == AccountFilterTab.suppliers
                            ? AccountType.supplier
                            : AccountType.beneficiary),
                  );
                },
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSegmentControl(accController),
              Expanded(
                child: OneUiListContainer(
                  child: _buildAccountsList(accController),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSegmentControl(AccountsController accController) {
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
            label: AppStrings.beneficiariesTab,
            isSelected: _activeTab == AccountFilterTab.beneficiaries,
            onTap: () {
              setState(() => _activeTab = AccountFilterTab.beneficiaries);
              accController.setTypeFilter(AccountType.beneficiary);
            },
          ),
          _buildSegmentItem(
            label: AppStrings.suppliersTab,
            isSelected: _activeTab == AccountFilterTab.suppliers,
            onTap: () {
              setState(() => _activeTab = AccountFilterTab.suppliers);
              accController.setTypeFilter(AccountType.supplier);
            },
          ),
          _buildSegmentItem(
            label: AppStrings.stationsTab,
            isSelected: _activeTab == AccountFilterTab.stations,
            onTap: () {
              setState(() => _activeTab = AccountFilterTab.stations);
              accController.setTypeFilter(AccountType.station);
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

  Widget _buildAccountsList(AccountsController controller) {
    if (controller.isLoading) {
      return const AppLoadingIndicator();
    }
    if (controller.accounts.isEmpty) {
      final isStation = _activeTab == AccountFilterTab.stations;
      final isSupplier = _activeTab == AccountFilterTab.suppliers;
      return EmptyStateWidget(
        icon: isStation ? AppIcons.gasStationOutlined : AppIcons.accountOutline,
        title: isStation
            ? AppStrings.noStationsRecordedYet
            : (isSupplier
                ? AppStrings.noSuppliersFound
                : AppStrings.noBeneficiariesFound),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: controller.accounts.length,
      itemBuilder: (context, index) {
        final account = controller.accounts[index];
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAccountRow(account),
            const OneUiDivider(
              indent: AppDimensions.dividerIndentCompact,
              endIndent: AppDimensions.dividerIndentCompact,
            ),
          ],
        );
      },
    );
  }

  Widget _buildBalanceLine({
    required String fuelName,
    required double amount,
  }) {
    final isNegative = amount < 0;
    final color = isNegative ? AppColors.dispenseRed : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        '${AppFormatters.formatQuantity(amount)} ${AppStrings.unitLiter} $fuelName',
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontSize: AppTypography.sizeCaption,
          fontWeight: AppTypography.weightSemiBold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildAccountRow(AccountModel account) {
    final isStation = account.accountType == AccountType.station;
    final txCtrl = context.watch<TransactionsController>();
    final balances = isStation
        ? (txCtrl.allStationBalances[account.id] ?? {})
        : (txCtrl.allAccountBalances[account.id] ?? {});
    final petrolBalance = balances[1] ?? 0.0;
    final dieselBalance = balances[2] ?? 0.0;

    final List<Widget> balanceLines = [];
    if (petrolBalance != 0.0) {
      balanceLines.add(_buildBalanceLine(
        fuelName: AppStrings.fuelPetrol,
        amount: petrolBalance,
      ));
    }
    if (dieselBalance != 0.0) {
      balanceLines.add(_buildBalanceLine(
        fuelName: AppStrings.fuelDiesel,
        amount: dieselBalance,
      ));
    }

    String subText = '';
    if (isStation) {
      if (account.location != null && account.location!.trim().isNotEmpty) {
        subText = account.location!;
      } else if (account.phoneNumber != null &&
          account.phoneNumber!.trim().isNotEmpty) {
        subText = account.phoneNumber!;
      } else {
        subText =
            '${AppStrings.commissionRatePrefix}${account.defaultCommissionRate}%';
      }
    } else {
      subText = account.phoneNumber ?? '';
    }

    return SlidableAccountTile(
      key: ValueKey('account_${account.id}'),
      onTap: () => _navigateToTransactions(account),
      onDelete: () => _deleteAccount(account),
      onEdit: () => _showAddEditDialog(account: account),
      onArchive: () => _archiveAccount(account),
      child: Padding(
        padding: AppDimensions.paddingTile,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: const TextStyle(
                      fontSize: AppTypography.sizeH2,
                      fontWeight: AppTypography.weightSemiBold,
                      color: AppColors.textPrimary,
                    ),
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
            if (balanceLines.isNotEmpty) ...[
              const SizedBox(width: AppDimensions.spaceM),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: balanceLines,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
