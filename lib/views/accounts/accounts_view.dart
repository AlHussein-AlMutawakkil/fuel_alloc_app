import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/accounts_controller.dart';
import '../../controllers/stations_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_dialog.dart';
import '../../core/widgets/custom_modal_sheet.dart';
import '../../models/account_model.dart';
import '../../models/station_model.dart';
import 'account_transactions_view.dart';
import 'station_transactions_view.dart';
import 'widgets/slidable_account_tile.dart';
import '../../core/widgets/one_ui_card.dart';

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
            const SizedBox(height: 12),
            CustomModalSheet.buildLabel(AppStrings.accountType),
            Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: CustomModalSheet.fieldBorderColor, width: 1.2),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<AccountType>(
                  isExpanded: true,
                  value: selectedType,
                  icon: const Icon(Icons.keyboard_arrow_down,
                      color: Color(0xFF64748B), size: 18),
                  items: const [
                    DropdownMenuItem(
                      value: AccountType.beneficiary,
                      child: Text(AppStrings.typeBeneficiary,
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF1E293B))),
                    ),
                    DropdownMenuItem(
                      value: AccountType.supplier,
                      child: Text(AppStrings.typeSupplier,
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF1E293B))),
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

  void _archiveAccount(AccountModel account) async {
    final confirm = await CustomDialog.showConfirmation(
      context: context,
      title: 'أرشفة الحساب',
      message:
          'هل تريد أرشفة "${account.name}"؟ سيتم نقله للأرشيف مع حفظ كافة عملياته وسجلاته.',
      confirmText: 'أرشفة',
      cancelText: 'إلغاء',
      isDanger: false,
    );

    if (confirm && account.id != null && mounted) {
      await context.read<AccountsController>().deleteAccount(account.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تمت أرشفة ${account.name} بنجاح'),
            backgroundColor: const Color(0xFFF59E0B),
            behavior: SnackBarBehavior.floating,
          ),
        );
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

  void _archiveStation(StationModel station) async {
    final confirm = await CustomDialog.showConfirmation(
      context: context,
      title: 'أرشفة المحطة',
      message:
          'هل تريد أرشفة محطة "${station.name}"؟ سيتم نقلها للأرشيف مع حفظ كافة كشوفاتها وسجلاتها.',
      confirmText: 'أرشفة',
      cancelText: 'إلغاء',
      isDanger: false,
    );

    if (confirm && station.id != null && mounted) {
      await context.read<StationsController>().deleteStation(station.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تمت أرشفة ${station.name} بنجاح'),
            backgroundColor: const Color(0xFFF59E0B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => StationTransactionsView(station: station),
      ),
    )
        .then((_) {
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
          backgroundColor: const Color(0xfff8f8f8),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: _isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      hintText: isStationTab
                          ? 'بحث في المحطات أو الموقع...'
                          : (_activeTab == AccountFilterTab.suppliers
                              ? 'بحث في الموردين أو الهاتف...'
                              : 'بحث في المستفيدين أو الهاتف...'),
                      hintStyle:
                          TextStyle(color: Colors.white.withOpacity(0.7)),
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
                        ? 'محطات الوقود'
                        : (_activeTab == AccountFilterTab.suppliers
                            ? 'الموردين'
                            : 'المستفيدين'),
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
                tooltip: isStationTab
                    ? 'إضافة محطة'
                    : (_activeTab == AccountFilterTab.suppliers
                        ? 'إضافة مورد'
                        : 'إضافة مستفيد'),
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
              // 1. شريط التبويبات الكبسولي المطابق تماماً للصورة (المستفيدين - الموردين - المحطات)
              _buildSegmentControl(accController, stationsController),

              // 2. كرت القائمة الأبيض الموحد ذو الزوايا الدائرية الكاملة One UI
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

  /// شريط التبويبات الثلاثي الكبسولي (مطابق للصورة تماماً: أنثى / ذكر / صوتي -> المستفيدين / الموردين / المحطات)
  Widget _buildSegmentControl(
    AccountsController accController,
    StationsController stationsController,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: const Color(0xfff1f1f1), // خلفية رمادية فاتحة وناعمة One UI
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildSegmentItem(
            label: 'المستفيدين',
            isSelected: _activeTab == AccountFilterTab.beneficiaries,
            onTap: () {
              setState(() => _activeTab = AccountFilterTab.beneficiaries);
              accController.setTypeFilter(AccountType.beneficiary);
            },
          ),
          _buildSegmentItem(
            label: 'الموردين',
            isSelected: _activeTab == AccountFilterTab.suppliers,
            onTap: () {
              setState(() => _activeTab = AccountFilterTab.suppliers);
              accController.setTypeFilter(AccountType.supplier);
            },
          ),
          _buildSegmentItem(
            label: 'المحطات',
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
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? const Color(0xFF0F172A)
                  : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  // --- قائمة الحسابات بنمط القائمة المفتوحة مع فواصل ناعمة ---

  Widget _buildAccountsList(AccountsController controller) {
    if (controller.isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (controller.accounts.isEmpty) {
      return Center(
        child: Text(
          _activeTab == AccountFilterTab.suppliers
              ? 'لا يوجد موردين مسجلين حتى الآن'
              : 'لا يوجد مستفيدين مسجلين حتى الآن',
          style: AppTextStyles.bodySecondary,
        ),
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
            const OneUiDivider(indent: 12, endIndent: 12),
          ],
        );
      },
    );
  }

  /// عنصر الحساب بنمط One UI: اسم عريض + سطر فرعي، بدون ثلاث نقاط، قابل للسحب لليمين
  Widget _buildAccountRow(AccountModel account) {
    final hasPhone =
        account.phoneNumber != null && account.phoneNumber!.trim().isNotEmpty;

    return SlidableAccountTile(
      key: ValueKey('account_${account.id}'),
      onTap: () => _navigateToTransactions(account),
      onDelete: () => _deleteAccount(account),
      onEdit: () => _showAddEditDialog(account: account),
      onArchive: () => _archiveAccount(account),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (hasPhone) ...[
                    const SizedBox(height: 4),
                    Text(
                      account.phoneNumber!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- قائمة المحطات بنمط القائمة المفتوحة مع فواصل ناعمة ---

  Widget _buildStationsList(StationsController controller) {
    if (controller.isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (controller.stations.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد محطات مسجلة حتى الآن',
          style: AppTextStyles.bodySecondary,
        ),
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
            const OneUiDivider(indent: 12, endIndent: 12),
          ],
        );
      },
    );
  }

  /// عنصر المحطة بنمط One UI: اسم عريض + سطر فرعي، بدون ثلاث نقاط، قابل للسحب لليمين
  Widget _buildStationRow(StationModel station) {
    String subText = '';
    if (station.location != null && station.location!.trim().isNotEmpty) {
      subText = station.location!;
    } else if (station.phoneNumber != null &&
        station.phoneNumber!.trim().isNotEmpty) {
      subText = station.phoneNumber!;
    } else {
      subText = 'نسبة التهوية: ${station.defaultCommissionRate}%';
    }

    return SlidableAccountTile(
      key: ValueKey('station_${station.id}'),
      onTap: () => _navigateToStationTransactions(station),
      onDelete: () => _deleteStation(station),
      onEdit: () => _showAddEditStationDialog(station: station),
      onArchive: () => _archiveStation(station),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    station.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subText,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
