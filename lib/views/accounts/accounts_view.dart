import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/accounts_controller.dart';
import '../../controllers/stations_controller.dart';
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
import '../../models/station_model.dart';
import 'account_transactions_view.dart';
import 'station_transactions_view.dart';
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
      context.read<StationsController>().fetchStations();
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
    AccountType selectedType =
        account?.accountType ?? defaultType ?? AccountType.beneficiary;

    CustomModalSheet.show(
      context: context,
      title: account == null ? AppStrings.addAccount : AppStrings.editAccount,
      contentBuilder: (ctx, setModalState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomModalSheet.buildTextField(
              label: AppStrings.accountName,
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
              ],
              onChanged: (val) {
                setModalState(() {
                  selectedType = val;
                });
              },
            ),
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
        if (account == null) {
          await controller.addAccount(name, selectedType, phoneController.text);
        } else {
          await controller.updateAccount(
            account.copyWith(
              name: name,
              accountType: selectedType,
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
    final confirm = await CustomDialog.showConfirmation(
      context: context,
      title: AppStrings.confirmExclamation,
      message: AppStrings.confirmDeleteAccountMsg,
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
    final confirm = await CustomDialog.showConfirmation(
      context: context,
      title: AppStrings.archiveAccountTitle,
      message: AppStrings.confirmArchiveAccountMsg,
      confirmText: AppStrings.archive,
      cancelText: AppStrings.cancel,
      isDanger: false,
    );

    if (confirm && account.id != null && mounted) {
      await context.read<AccountsController>().archiveAccount(account.id!);
      if (mounted) {
        AppSnackBar.showSuccess(context, AppStrings.accountArchivedSuccess);
        context.read<TransactionsController>().fetchAllBalancesSummary();
      }
    }
  }

  // --- نوافذ المحطات ---

  void _showAddEditStationDialog({StationModel? station}) {
    final nameController = TextEditingController(text: station?.name ?? '');
    final locationController =
        TextEditingController(text: station?.location ?? '');
    final phoneController =
        TextEditingController(text: station?.phoneNumber ?? '');
    final commissionController = TextEditingController(
      text: station != null ? station.defaultCommissionRate.toString() : '2.0',
    );

    CustomModalSheet.show(
      context: context,
      title: station == null ? AppStrings.addStation : AppStrings.editStation,
      contentBuilder: (ctx, setModalState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomModalSheet.buildTextField(
              label: AppStrings.stationNameLabel,
              controller: nameController,
            ),
            const SizedBox(height: AppDimensions.spaceL),
            CustomModalSheet.buildTextField(
              label: AppStrings.locationCityLabel,
              controller: locationController,
            ),
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
            const SizedBox(height: AppDimensions.spaceL),
            CustomModalSheet.buildTextField(
              label: AppStrings.commissionRatePercentLabel,
              controller: commissionController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        );
      },
      onSave: (ctx) async {
        final name = nameController.text.trim();
        if (name.isEmpty) return;

        final navigator = Navigator.of(ctx);
        final commRate =
            double.tryParse(commissionController.text.trim()) ?? 2.0;
        final stationsController = context.read<StationsController>();

        if (station == null) {
          await stationsController.addStation(
            name: name,
            location: locationController.text.trim(),
            phone: phoneController.text.trim(),
            defaultCommission: commRate,
          );
        } else {
          await stationsController.updateStation(
            station.copyWith(
              name: name,
              location: locationController.text.trim().isEmpty
                  ? null
                  : locationController.text.trim(),
              phoneNumber: phoneController.text.trim().isEmpty
                  ? null
                  : phoneController.text.trim(),
              defaultCommissionRate: commRate,
            ),
          );
        }
        navigator.pop();
      },
    );
  }

  void _deleteStation(StationModel station) async {
    final confirm = await CustomDialog.showConfirmation(
      context: context,
      title: AppStrings.confirmExclamation,
      message: AppStrings.confirmDeleteStationMsg,
      confirmText: AppStrings.ok,
      cancelText: AppStrings.cancel,
      isDanger: true,
    );

    if (confirm && station.id != null && mounted) {
      await context.read<StationsController>().deleteStation(station.id!);
      if (mounted) {
        context.read<TransactionsController>().fetchAllBalancesSummary();
      }
    }
  }

  void _archiveStation(StationModel station) async {
    final confirm = await CustomDialog.showConfirmation(
      context: context,
      title: AppStrings.archiveStationTitle,
      message:
          'هل تريد أرشفة محطة "${station.name}"؟ سيتم نقلها للأرشيف مع حفظ كافة كشوفاتها وسجلاتها.',
      confirmText: AppStrings.archive,
      cancelText: AppStrings.cancel,
      isDanger: false,
    );

    if (confirm && station.id != null && mounted) {
      final success =
          await context.read<StationsController>().archiveStation(station.id!);
      if (success && mounted) {
        AppSnackBar.showSuccess(context, AppStrings.stationArchivedSuccess);
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

  void _navigateToStationTransactions(StationModel station) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => StationTransactionsView(station: station),
      ),
    )
        .then((_) {
      if (mounted) {
        context.read<StationsController>().fetchStations();
        context.read<TransactionsController>().fetchAllBalancesSummary();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AccountsController, StationsController>(
      builder: (context, accController, stationsController, child) {
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
                      if (isStationTab) {
                        stationsController.setSearchQuery(val);
                      } else {
                        accController.setSearchQuery(val);
                      }
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
                      stationsController.setSearchQuery('');
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
                  if (isStationTab) {
                    _showAddEditStationDialog();
                  } else {
                    _showAddEditDialog(
                      defaultType: _activeTab == AccountFilterTab.suppliers
                          ? AccountType.supplier
                          : AccountType.beneficiary,
                    );
                  }
                },
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSegmentControl(accController, stationsController),
              Expanded(
                child: OneUiListContainer(
                  child: isStationTab
                      ? _buildStationsList(stationsController)
                      : _buildAccountsList(accController),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSegmentControl(
    AccountsController accController,
    StationsController stationsController,
  ) {
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
              stationsController.fetchStations();
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
      return EmptyStateWidget(
        icon: AppIcons.accountOutline,
        title: _activeTab == AccountFilterTab.suppliers
            ? AppStrings.noSuppliersFound
            : AppStrings.noBeneficiariesFound,
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
    final hasPhone =
        account.phoneNumber != null && account.phoneNumber!.trim().isNotEmpty;
    final txCtrl = context.watch<TransactionsController>();
    final balances = txCtrl.allAccountBalances[account.id] ?? {};
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
                  if (hasPhone) ...[
                    const SizedBox(height: AppDimensions.spaceXS),
                    Text(
                      account.phoneNumber!,
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

  Widget _buildStationsList(StationsController controller) {
    if (controller.isLoading) {
      return const AppLoadingIndicator();
    }
    if (controller.stations.isEmpty) {
      return const EmptyStateWidget(
        icon: AppIcons.gasStationOutlined,
        title: AppStrings.noStationsRecordedYet,
      );
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: controller.stations.length,
      itemBuilder: (context, index) {
        final station = controller.stations[index];
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStationRow(station),
            const OneUiDivider(
              indent: AppDimensions.dividerIndentCompact,
              endIndent: AppDimensions.dividerIndentCompact,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStationRow(StationModel station) {
    String subText = '';
    if (station.location != null && station.location!.trim().isNotEmpty) {
      subText = station.location!;
    } else if (station.phoneNumber != null &&
        station.phoneNumber!.trim().isNotEmpty) {
      subText = station.phoneNumber!;
    } else {
      subText =
          '${AppStrings.commissionRatePrefix}${station.defaultCommissionRate}%';
    }

    final txCtrl = context.watch<TransactionsController>();
    final balances = txCtrl.allStationBalances[station.id] ?? {};
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

    return SlidableAccountTile(
      key: ValueKey('station_${station.id}'),
      onTap: () => _navigateToStationTransactions(station),
      onDelete: () => _deleteStation(station),
      onEdit: () => _showAddEditStationDialog(station: station),
      onArchive: () => _archiveStation(station),
      child: Padding(
        padding: AppDimensions.paddingTile,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    station.name,
                    style: const TextStyle(
                      fontSize: AppTypography.sizeH2,
                      fontWeight: AppTypography.weightSemiBold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceXS),
                  Text(
                    subText,
                    style: const TextStyle(
                      fontSize: AppTypography.sizeBodySecondary,
                      color: AppColors.textTertiary,
                    ),
                  ),
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
