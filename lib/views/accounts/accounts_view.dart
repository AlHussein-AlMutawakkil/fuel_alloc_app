import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/accounts_controller.dart';
import '../../controllers/stations_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_dialog.dart';
import '../../core/widgets/custom_modal_sheet.dart';
import '../../models/account_model.dart';
import '../../models/station_model.dart';
import 'account_transactions_view.dart';
import 'station_transactions_view.dart';

enum AccountFilterTab { all, beneficiaries, suppliers, stations }

/// واجهة إدارة الحسابات والمحطات (الكل - عملاء - موردين - محطات)
class AccountsView extends StatefulWidget {
  const AccountsView({super.key});

  @override
  State<AccountsView> createState() => _AccountsViewState();
}

class _AccountsViewState extends State<AccountsView> {
  final TextEditingController _searchController = TextEditingController();
  AccountFilterTab _activeTab = AccountFilterTab.all;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountsController>().fetchAccounts();
      context.read<StationsController>().fetchStations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- نوافذ الحسابات ---

  void _showAddEditDialog({AccountModel? account}) {
    final nameController = TextEditingController(text: account?.name ?? '');
    final phoneController = TextEditingController(text: account?.phoneNumber ?? '');
    AccountType selectedType = account?.accountType ?? AccountType.beneficiary;

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
            const SizedBox(height: 12),
            CustomModalSheet.buildLabel(AppStrings.accountType),
            Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: CustomModalSheet.fieldBorderColor, width: 1.2),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<AccountType>(
                  isExpanded: true,
                  value: selectedType,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B), size: 18),
                  items: const [
                    DropdownMenuItem(
                      value: AccountType.beneficiary,
                      child: Text(AppStrings.typeBeneficiary, style: TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
                    ),
                    DropdownMenuItem(
                      value: AccountType.supplier,
                      child: Text(AppStrings.typeSupplier, style: TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() {
                        selectedType = val;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            CustomModalSheet.buildTextField(
              label: AppStrings.phoneNumber,
              controller: phoneController,
              keyboardType: TextInputType.phone,
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
              phoneNumber: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
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
      title: 'تأكيد!',
      message: 'هل تريد حذف هذا الحساب؟',
      confirmText: 'حسناً',
      cancelText: 'إلغاء',
      isDanger: true,
    );

    if (confirm && account.id != null && mounted) {
      await context.read<AccountsController>().deleteAccount(account.id!);
    }
  }

  // --- نوافذ المحطات ---

  void _showAddEditStationDialog({StationModel? station}) {
    final nameController = TextEditingController(text: station?.name ?? '');
    final locationController = TextEditingController(text: station?.location ?? '');
    final phoneController = TextEditingController(text: station?.phoneNumber ?? '');
    final commissionController = TextEditingController(
      text: station != null ? station.defaultCommissionRate.toString() : '2.0',
    );

    CustomModalSheet.show(
      context: context,
      title: station == null ? 'إضافة محطة' : 'تعديل محطة',
      contentBuilder: (ctx, setModalState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomModalSheet.buildTextField(
              label: 'اسم المحطة',
              controller: nameController,
            ),
            const SizedBox(height: 12),
            CustomModalSheet.buildTextField(
              label: 'الموقع / المدينة',
              controller: locationController,
            ),
            const SizedBox(height: 12),
            CustomModalSheet.buildTextField(
              label: 'رقم الهاتف',
              controller: phoneController,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            CustomModalSheet.buildTextField(
              label: 'نسبة عمولة التهوية (%)',
              controller: commissionController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        );
      },
      onSave: (ctx) async {
        final name = nameController.text.trim();
        if (name.isEmpty) return;

        final navigator = Navigator.of(ctx);
        final commRate = double.tryParse(commissionController.text.trim()) ?? 2.0;
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
              location: locationController.text.trim().isEmpty ? null : locationController.text.trim(),
              phoneNumber: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
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
      title: 'تأكيد!',
      message: 'هل تريد حذف هذه المحطة؟',
      confirmText: 'حسناً',
      cancelText: 'إلغاء',
      isDanger: true,
    );

    if (confirm && station.id != null && mounted) {
      await context.read<StationsController>().deleteStation(station.id!);
    }
  }

  void _navigateToTransactions(AccountModel account) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AccountTransactionsView(account: account),
      ),
    );
  }

  void _navigateToStationTransactions(StationModel station) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StationTransactionsView(station: station),
      ),
    ).then((_) {
      if (mounted) {
        context.read<StationsController>().fetchStations();
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
            leading: Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'القائمة',
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            title: _isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      hintText: isStationTab
                          ? 'بحث في المحطات أو الموقع...'
                          : AppStrings.searchAccountHint,
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
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
                    isStationTab ? 'المحطات' : AppStrings.accountsTitle,
                    style: AppTextStyles.appBarTitle,
                  ),
            actions: [
              IconButton(
                icon: Icon(_isSearching ? Icons.close : Icons.search),
                tooltip: _isSearching ? 'إغلاق البحث' : 'بحث',
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
                icon: const Icon(Icons.add),
                tooltip: isStationTab ? 'إضافة محطة' : 'إضافة',
                onPressed: () {
                  if (isStationTab) {
                    _showAddEditStationDialog();
                  } else {
                    _showAddEditDialog();
                  }
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // تبويبات الفلترة الأربعة: (الكل - عملاء - موردين - محطات)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: AppStrings.allAccounts,
                        isSelected: _activeTab == AccountFilterTab.all,
                        onTap: () {
                          setState(() => _activeTab = AccountFilterTab.all);
                          accController.setTypeFilter(null);
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: AppStrings.beneficiaries,
                        isSelected: _activeTab == AccountFilterTab.beneficiaries,
                        onTap: () {
                          setState(() => _activeTab = AccountFilterTab.beneficiaries);
                          accController.setTypeFilter(AccountType.beneficiary);
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: AppStrings.suppliers,
                        isSelected: _activeTab == AccountFilterTab.suppliers,
                        onTap: () {
                          setState(() => _activeTab = AccountFilterTab.suppliers);
                          accController.setTypeFilter(AccountType.supplier);
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'محطات',
                        isSelected: _activeTab == AccountFilterTab.stations,
                        onTap: () {
                          setState(() => _activeTab = AccountFilterTab.stations);
                          stationsController.fetchStations();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // محتوى القائمة (حسابات أو محطات)
                Expanded(
                  child: isStationTab
                      ? _buildStationsList(stationsController)
                      : _buildAccountsList(accController),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFF64748B),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // --- قائمة الحسابات ---

  Widget _buildAccountsList(AccountsController controller) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (controller.accounts.isEmpty) {
      return const Center(
        child: Text(
          AppStrings.noAccountsFound,
          style: AppTextStyles.bodySecondary,
        ),
      );
    }
    return ListView.separated(
      itemCount: controller.accounts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final account = controller.accounts[index];
        return _buildAccountCard(account);
      },
    );
  }

  Widget _buildAccountCard(AccountModel account) {
    final isSupplier = account.accountType == AccountType.supplier;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _navigateToTransactions(account),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF64748B), width: 1.2),
          ),
          child: Row(
            children: [
              // شارة النوع
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSupplier ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSupplier ? const Color(0xFFBFDBFE) : const Color(0xFFCBD5E1),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  isSupplier ? 'مورد' : 'عميل',
                  style: TextStyle(
                    fontSize: 12,
                    color: isSupplier ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // الاسم ورقم الهاتف
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(account.name, style: AppTextStyles.heading3),
                    if (account.phoneNumber != null && account.phoneNumber!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        account.phoneNumber!,
                        style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),

              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFF64748B), width: 1.2),
                ),
                onSelected: (action) {
                  if (action == 'transactions') {
                    _navigateToTransactions(account);
                  } else if (action == 'edit') {
                    _showAddEditDialog(account: account);
                  } else if (action == 'delete') {
                    _deleteAccount(account);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'transactions',
                    child: Row(
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 18, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(AppStrings.viewTransactions, style: AppTextStyles.body),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                        SizedBox(width: 8),
                        Text(AppStrings.edit, style: AppTextStyles.body),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: Color(0xFFB91C1C)),
                        SizedBox(width: 8),
                        Text(AppStrings.delete, style: TextStyle(color: Color(0xFFB91C1C), fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- قائمة المحطات ---

  Widget _buildStationsList(StationsController controller) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (controller.stations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_gas_station_outlined, size: 52, color: AppColors.textMuted.withOpacity(0.5)),
            const SizedBox(height: 12),
            const Text(
              'لا توجد محطات مسجلة حتى الآن',
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'إضافة أول محطة',
              icon: Icons.add,
              variant: ButtonVariant.secondary,
              onPressed: () => _showAddEditStationDialog(),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: controller.stations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final station = controller.stations[index];
        return _buildStationCard(station);
      },
    );
  }

  Widget _buildStationCard(StationModel station) {
    final balance = station.currentBalance;
    final balanceColor = balance >= 0 ? const Color(0xFF15803D) : const Color(0xFFB91C1C);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _navigateToStationTransactions(station),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF64748B), width: 1.2),
          ),
          child: Row(
            children: [
              // شارة المحطة
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFBFDBFE), width: 0.8),
                ),
                child: const Text(
                  'محطة',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // اسم المحطة وتفاصيلها
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            station.name,
                            style: AppTextStyles.heading3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            '${station.defaultCommissionRate}% تهوية',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (station.location != null && station.location!.isNotEmpty) ...[
                          const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 2),
                          Text(station.location!, style: AppTextStyles.caption),
                          const SizedBox(width: 8),
                        ],
                        if (station.phoneNumber != null && station.phoneNumber!.isNotEmpty) ...[
                          const Icon(Icons.phone_outlined, size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 2),
                          Text(station.phoneNumber!, style: AppTextStyles.caption),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // الرصيد الفعلي في المحطة
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${AppFormatters.formatQuantity(balance)} لتر',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: balanceColor,
                    ),
                  ),
                  const Text(
                    'الرصيد المتاح',
                    style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
              const SizedBox(width: 8),

              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),

              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFF64748B), width: 1.2),
                ),
                onSelected: (action) {
                  if (action == 'transactions') {
                    _navigateToStationTransactions(station);
                  } else if (action == 'edit') {
                    _showAddEditStationDialog(station: station);
                  } else if (action == 'delete') {
                    _deleteStation(station);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'transactions',
                    child: Row(
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 18, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('كشف حساب المحطة', style: AppTextStyles.body),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                        SizedBox(width: 8),
                        Text(AppStrings.edit, style: AppTextStyles.body),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: Color(0xFFB91C1C)),
                        SizedBox(width: 8),
                        Text(AppStrings.delete, style: TextStyle(color: Color(0xFFB91C1C), fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
