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
import '../../models/account_model.dart';
import '../../models/transaction_model.dart';
import 'custom_dropdown.dart';
import 'custom_modal_sheet.dart';

/// واجهة تسجيل وتعديل القيود والعمليات (مكون مشترك وذكي لكافة شاشات التطبيق)
class OperationEntrySheet extends StatefulWidget {
  final AccountModel? initialAccount;
  final TransactionModel? editTransaction;
  final int initialTabIndex; // 0: اعتماد, 1: فعلي, 2: نسبة
  final int initialDirection; // 0: توريد, 1: صرف
  final int? initialFuelTypeId;
  final int? initialStationId;

  const OperationEntrySheet({
    super.key,
    this.initialAccount,
    this.editTransaction,
    this.initialTabIndex = 0,
    this.initialDirection = 0,
    this.initialFuelTypeId,
    this.initialStationId,
  });

  /// فتح نافذة تسجيل القيد بتنسيق نافذة منبثقة مطابقة للصورة المعتمدة
  static Future<bool?> show({
    required BuildContext context,
    AccountModel? account,
    TransactionModel? editTransaction,
    int initialTabIndex = 0,
    int initialDirection = 0,
    int? initialFuelTypeId,
    int? initialStationId,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.overlay,
      builder: (ctx) => OperationEntrySheet(
        initialAccount: account,
        editTransaction: editTransaction,
        initialTabIndex: initialTabIndex,
        initialDirection: initialDirection,
        initialFuelTypeId: initialFuelTypeId,
        initialStationId: initialStationId,
      ),
    );
  }

  @override
  State<OperationEntrySheet> createState() => _OperationEntrySheetState();
}

class _OperationEntrySheetState extends State<OperationEntrySheet> {
  static const Color _fieldBorderColor = AppColors.borderLight;

  // التبويب العلوي: 0: اعتماد, 1: فعلي, 2: نسبة
  late int _selectedTab;

  // اتجاه الحركة: 0: توريد, 1: صرف
  late int _selectedDirection;

  // الحساب المختار ورصيده المباشر
  AccountModel? _selectedAccount;
  double? _accountBalanceLiters;

  // المحطة المنفذة ورصيدها المتبقي
  int? _selectedStationId;
  double? _stationBalanceLiters;

  // زر إظهار مرجع المحطة (تحويل / مقاصة)
  bool _showReferenceStation = false;
  int? _selectedReferenceStationId;

  // الصنف المختار (بترول / ديزل)
  int? _selectedFuelTypeId;

  // الوحدة المختارة
  int? _selectedUnitId;

  // المتحكمات
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _statementController = TextEditingController();
  final TextEditingController _referenceNumberController =
      TextEditingController();

  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.editTransaction != null;

    if (_isEdit) {
      final tx = widget.editTransaction!;
      if (tx.typeId == 3) {
        _selectedTab = 2; // نسبة
        _selectedDirection = 1;
      } else if (tx.isActual) {
        _selectedTab = 1; // فعلي
        _selectedDirection = tx.typeId == 2 ? 0 : 1;
      } else {
        _selectedTab = 0; // اعتماد
        _selectedDirection = tx.typeId == 1 ? 0 : 1;
      }

      _selectedStationId = tx.stationId;
      _selectedReferenceStationId = tx.referenceStationId;
      _showReferenceStation = tx.referenceStationId != null &&
          tx.referenceStationId != tx.stationId;

      _selectedFuelTypeId = tx.fuelTypeId;
      _selectedUnitId = tx.unitId;
      _quantityController.text = tx.enteredQuantity.toString();
      _dateController.text = tx.transactionDate.replaceAll('-', '/');
      _statementController.text = tx.notes ?? '';
      _referenceNumberController.text = tx.referenceNumber ?? '';
    } else {
      _selectedTab = widget.initialTabIndex;
      _selectedDirection = widget.initialDirection;
      _selectedFuelTypeId = widget.initialFuelTypeId;
      _selectedStationId = widget.initialStationId;

      final now = DateTime.now();
      _dateController.text =
          '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}';
    }

    _selectedAccount = widget.initialAccount;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final txController = context.read<TransactionsController>();
      final accController = context.read<AccountsController>();

      if (accController.accounts.isEmpty) {
        await accController.fetchAccounts();
      }

      if (_selectedAccount == null &&
          widget.editTransaction?.accountId != null) {
        final matches = accController.accounts.where(
          (a) => a.id == widget.editTransaction!.accountId,
        );
        if (matches.isNotEmpty) {
          _selectedAccount = matches.first;
        }
      }

      if (_selectedAccount == null) {
        final validAccounts = _getFilteredAccounts(accController.accounts);
        if (validAccounts.isNotEmpty) {
          _selectedAccount = validAccounts.first;
        }
      }

      if (_selectedFuelTypeId == null && txController.fuelTypes.isNotEmpty) {
        _selectedFuelTypeId = txController.fuelTypes.first['id'] as int?;
      }
      if (_selectedUnitId == null && txController.units.isNotEmpty) {
        _selectedUnitId = txController.units.first['id'] as int?;
      }
      if (_selectedStationId == null && txController.stations.isNotEmpty) {
        _selectedStationId = txController.stations.first['id'] as int?;
      }

      setState(() {});
      _updateLiveBalances();
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _dateController.dispose();
    _statementController.dispose();
    _referenceNumberController.dispose();
    super.dispose();
  }

  List<AccountModel> _getFilteredAccounts(List<AccountModel> accounts) {
    if (_selectedTab == 2) {
      return accounts;
    }
    if (_selectedDirection == 0) {
      return accounts
          .where((a) => a.accountType == AccountType.supplier)
          .toList();
    } else {
      return accounts
          .where((a) => a.accountType == AccountType.beneficiary)
          .toList();
    }
  }

  Future<void> _updateLiveBalances() async {
    final txController = context.read<TransactionsController>();

    if (_selectedAccount?.id != null) {
      final isSupplier = _selectedAccount!.accountType == AccountType.supplier;
      final bal = await txController.getAccountBalance(
          _selectedAccount!.id!, isSupplier);
      if (mounted) {
        setState(() {
          _accountBalanceLiters = bal;
        });
      }
    } else {
      if (mounted) setState(() => _accountBalanceLiters = null);
    }

    if (_selectedStationId != null) {
      final stBal = await txController.getStationBalance(_selectedStationId!);
      if (mounted) {
        setState(() {
          _stationBalanceLiters = stBal;
        });
      }
    } else {
      if (mounted) setState(() => _stationBalanceLiters = null);
    }
  }

  int _calculateTypeId() {
    if (_selectedTab == 0) {
      return _selectedDirection == 0 ? 1 : 4;
    } else if (_selectedTab == 1) {
      return _selectedDirection == 0 ? 2 : 5;
    } else {
      return 3;
    }
  }

  String _getTitle() {
    return _isEdit ? AppStrings.editOperation : AppStrings.registerOperation;
  }

  @override
  Widget build(BuildContext context) {
    final txController = context.watch<TransactionsController>();
    final accController = context.watch<AccountsController>();

    final fuelTypes = txController.fuelTypes.isNotEmpty
        ? txController.fuelTypes
        : [
            {'id': 1, 'name': AppStrings.fuelPetrol},
            {'id': 2, 'name': AppStrings.fuelDiesel},
          ];

    final units = txController.units.isNotEmpty
        ? txController.units
        : [
            {'id': 1, 'name': AppStrings.unitLiter, 'conversion_factor': 1.0},
            {'id': 2, 'name': AppStrings.unitDabba, 'conversion_factor': 20.0},
            {
              'id': 3,
              'name': AppStrings.unitBarrel,
              'conversion_factor': 200.0
            },
          ];

    _selectedFuelTypeId ??= fuelTypes.first['id'] as int?;
    _selectedUnitId ??= units.first['id'] as int?;

    final enteredQty = double.tryParse(_quantityController.text.trim()) ?? 0.0;
    double unitFactor = 1.0;
    if (_selectedUnitId != null) {
      final u = units.firstWhere(
        (e) => e['id'] == _selectedUnitId,
        orElse: () => {'conversion_factor': 1.0},
      );
      unitFactor = (u['conversion_factor'] as num?)?.toDouble() ?? 1.0;
    }
    final calculatedLiters = enteredQty * unitFactor;

    final currentUnitName = units.firstWhere(
      (e) => e['id'] == _selectedUnitId,
      orElse: () => {'name': AppStrings.unitLiter},
    )['name'] as String;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceXL,
          vertical: AppDimensions.space2XL,
        ),
        constraints:
            const BoxConstraints(maxWidth: AppDimensions.modalMaxWidth),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppDimensions.borderRadius3XL,
          boxShadow: [
            BoxShadow(
              color: AppColors.overlayLight,
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: AppDimensions.borderRadius3XL,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              padding: AppDimensions.paddingModal,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. الشريط العلوي: العنوان وزر الإغلاق
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _getTitle(),
                          style: const TextStyle(
                            fontSize: AppTypography.sizeH2,
                            fontWeight: AppTypography.weightBold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          AppIcons.closeRounded,
                          color: AppColors.textTertiary,
                          size: AppDimensions.iconMedium,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: AppDimensions.space4XL,
                          minHeight: AppDimensions.space4XL,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spaceL + 6),

                  // 2. التبويبات الثلاثة العلوية (اعتماد / فعلي / نسبة)
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: AppDimensions.borderRadius2XL,
                      border: Border.all(
                        color: _fieldBorderColor,
                        width: AppDimensions.borderWidthThin,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTopTabItem(
                            index: 0,
                            label: AppStrings.quota,
                            icon: AppIcons.tabQuota,
                          ),
                        ),
                        Expanded(
                          child: _buildTopTabItem(
                            index: 1,
                            label: AppStrings.actual,
                            icon: AppIcons.tabActual,
                          ),
                        ),
                        Expanded(
                          child: _buildTopTabItem(
                            index: 2,
                            label: AppStrings.ratio,
                            icon: AppIcons.tabAeration,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceL),

                  // 3. زرا الاتجاه (↓ توريد / ↑ صرف)
                  if (_selectedTab != 2) ...[
                    Container(
                      height: AppDimensions.segmentHeight,
                      padding: AppDimensions.paddingAllXS,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: AppDimensions.borderRadius2XL,
                        border: Border.all(
                          color: _fieldBorderColor,
                          width: AppDimensions.borderWidthThin,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedDirection = 0;
                                  final validAccounts = _getFilteredAccounts(
                                      accController.accounts);
                                  if (_selectedAccount == null ||
                                      !validAccounts
                                          .contains(_selectedAccount)) {
                                    _selectedAccount = validAccounts.isNotEmpty
                                        ? validAccounts.first
                                        : null;
                                  }
                                });
                                _updateLiveBalances();
                              },
                              borderRadius: AppDimensions.borderRadiusL,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _selectedDirection == 0
                                      ? AppColors.supplyGreen
                                      : Colors.transparent,
                                  borderRadius: AppDimensions.borderRadiusL,
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      AppIcons.supply,
                                      size: AppDimensions.iconSmall,
                                      color: _selectedDirection == 0
                                          ? AppColors.textWhite
                                          : AppColors.textTertiary,
                                    ),
                                    const SizedBox(
                                        width: AppDimensions.spaceXS),
                                    Text(
                                      AppStrings.supply,
                                      style: TextStyle(
                                        fontSize: AppTypography.sizeBody,
                                        fontWeight: AppTypography.weightBold,
                                        color: _selectedDirection == 0
                                            ? AppColors.textWhite
                                            : AppColors.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spaceXS),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedDirection = 1;
                                  final validAccounts = _getFilteredAccounts(
                                      accController.accounts);
                                  if (_selectedAccount == null ||
                                      !validAccounts
                                          .contains(_selectedAccount)) {
                                    _selectedAccount = validAccounts.isNotEmpty
                                        ? validAccounts.first
                                        : null;
                                  }
                                });
                                _updateLiveBalances();
                              },
                              borderRadius: AppDimensions.borderRadiusL,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _selectedDirection == 1
                                      ? (_selectedTab == 0
                                          ? AppColors.supplyGreen
                                          : AppColors.dispenseRed)
                                      : Colors.transparent,
                                  borderRadius: AppDimensions.borderRadiusL,
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      AppIcons.dispense,
                                      size: AppDimensions.iconSmall,
                                      color: _selectedDirection == 1
                                          ? AppColors.textWhite
                                          : AppColors.textTertiary,
                                    ),
                                    const SizedBox(
                                        width: AppDimensions.spaceXS),
                                    Text(
                                      AppStrings.dispense,
                                      style: TextStyle(
                                        fontSize: AppTypography.sizeBody,
                                        fontWeight: AppTypography.weightBold,
                                        color: _selectedDirection == 1
                                            ? AppColors.textWhite
                                            : AppColors.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceL),
                  ],

                  // 4. حقل الحساب مع الرصيد المباشر
                  _buildFieldLabel(AppStrings.account),
                  InkWell(
                    onTap: () => _openAccountPicker(
                        _getFilteredAccounts(accController.accounts)),
                    borderRadius: AppDimensions.borderRadius2XL,
                    child: Container(
                      height: AppDimensions.inputHeight,
                      padding: AppDimensions.paddingInputDense,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: AppDimensions.borderRadius2XL,
                        border: Border.all(
                          color: _fieldBorderColor,
                          width: AppDimensions.borderWidthThin,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            AppIcons.account,
                            color: AppColors.textTertiary,
                            size: AppDimensions.iconMedium,
                          ),
                          const SizedBox(width: AppDimensions.spaceM),
                          Expanded(
                            child: Text(
                              _selectedAccount?.name ??
                                  AppStrings.selectAccount,
                              style: TextStyle(
                                fontSize: AppTypography.sizeBody,
                                color: _selectedAccount != null
                                    ? AppColors.textDarkSlate
                                    : AppColors.textMuted,
                                fontWeight: _selectedAccount != null
                                    ? AppTypography.weightSemiBold
                                    : AppTypography.weightRegular,
                              ),
                            ),
                          ),
                          if (_accountBalanceLiters != null) ...[
                            Container(
                              padding: AppDimensions.paddingTag,
                              decoration: BoxDecoration(
                                color: AppColors.chipBackground,
                                borderRadius: AppDimensions.borderRadiusXS,
                                border: Border.all(
                                  color: _fieldBorderColor,
                                  width: AppDimensions.borderWidthThin,
                                ),
                              ),
                              child: Text(
                                '${AppFormatters.formatQuantity(_accountBalanceLiters!)} ${AppStrings.unitLiter}',
                                style: TextStyle(
                                  fontSize: AppTypography.sizeCaption,
                                  fontWeight: AppTypography.weightBold,
                                  color: _accountBalanceLiters! >= 0
                                      ? AppColors.supplyGreen
                                      : AppColors.dispenseRed,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppDimensions.spaceS),
                          ],
                          const Icon(
                            AppIcons.dropdownArrowPlain,
                            color: AppColors.textTertiary,
                            size: AppDimensions.iconRegular,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceL),

                  // 5. صف: الكمية والصنف
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel(AppStrings.quantity),
                            Container(
                              height: AppDimensions.inputHeight,
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: AppDimensions.borderRadius2XL,
                                border: Border.all(
                                  color: _fieldBorderColor,
                                  width: AppDimensions.borderWidthThin,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _quantityController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      style: const TextStyle(
                                        fontSize: AppTypography.sizeBody + 1,
                                        fontWeight: AppTypography.weightBold,
                                        color: AppColors.textPrimary,
                                      ),
                                      textAlign: TextAlign.start,
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        border: InputBorder.none,
                                        contentPadding:
                                            AppDimensions.paddingInputDense,
                                        hintText: AppStrings.zeroDecimal,
                                        hintStyle: TextStyle(
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  CustomDropdown<int>(
                                    value: _selectedUnitId,
                                    items: units.map((u) {
                                      return CustomDropdownItem<int>(
                                        value: u['id'] as int,
                                        label: u['name'] as String,
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedUnitId = val;
                                      });
                                    },
                                    customTrigger: Container(
                                      padding: AppDimensions.paddingAllS,
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          right: BorderSide(
                                            color: _fieldBorderColor,
                                            width:
                                                AppDimensions.borderWidthThin,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            currentUnitName,
                                            style: const TextStyle(
                                              fontSize: AppTypography
                                                  .sizeBodySecondary,
                                              fontWeight:
                                                  AppTypography.weightBold,
                                              color: AppColors.textDarkSlate,
                                            ),
                                          ),
                                          const SizedBox(
                                              width: AppDimensions.spaceXXS),
                                          const Icon(
                                            AppIcons.dropdownArrow,
                                            size: AppDimensions.iconSmall,
                                            color: AppColors.textTertiary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spaceM),
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel(AppStrings.fuelType),
                            CustomDropdown<int>(
                              value: _selectedFuelTypeId,
                              borderColor: _fieldBorderColor,
                              backgroundColor: AppColors.background,
                              items: fuelTypes.map((ft) {
                                return CustomDropdownItem<int>(
                                  value: ft['id'] as int,
                                  label: ft['name'] as String,
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedFuelTypeId = val;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // عرض المعادل باللتر
                  if (_selectedUnitId != 1 && calculatedLiters > 0) ...[
                    const SizedBox(height: AppDimensions.spaceXXS + 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spaceXS,
                      ),
                      child: Text(
                        '${AppStrings.equivalentPrefix} ${AppFormatters.formatQuantity(calculatedLiters)} ${AppStrings.unitLiter}',
                        style: const TextStyle(
                          fontSize: AppTypography.sizeSmall,
                          color: AppColors.textTertiary,
                          fontWeight: AppTypography.weightSemiBold,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppDimensions.spaceL),

                  // 6. حقل المحطة
                  if (_selectedTab == 1) ...[
                    if (!_showReferenceStation)
                      _buildFieldLabel(AppStrings.station)
                    else
                      Row(
                        children: [
                          Expanded(
                              flex: 5,
                              child: _buildFieldLabel(AppStrings.station)),
                          const SizedBox(width: AppDimensions.spaceM),
                          Expanded(
                              flex: 5,
                              child: _buildFieldLabel(
                                  AppStrings.referenceStationShort)),
                          const SizedBox(width: 52),
                        ],
                      ),
                    Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: CustomDropdown<int?>(
                            hint: AppStrings.station,
                            value: _selectedStationId,
                            borderColor: _fieldBorderColor,
                            backgroundColor: AppColors.background,
                            items: txController.stations.map((st) {
                              return CustomDropdownItem<int?>(
                                value: st['id'] as int,
                                label: st['name'] as String,
                              );
                            }).toList(),
                            trailing: (!_showReferenceStation &&
                                    _stationBalanceLiters != null)
                                ? Container(
                                    padding: AppDimensions.paddingMiniTag,
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: AppDimensions.borderRadiusM,
                                      border: Border.all(
                                        color: _fieldBorderColor,
                                        width: AppDimensions.borderWidthLight,
                                      ),
                                    ),
                                    child: Text(
                                      '${AppFormatters.formatQuantity(_stationBalanceLiters!)} ${AppStrings.unitLiter}',
                                      style: const TextStyle(
                                        fontSize: AppTypography.sizeSmall,
                                        fontWeight: AppTypography.weightBold,
                                        color: AppColors.textDarkSlate,
                                      ),
                                    ),
                                  )
                                : null,
                            onChanged: (val) {
                              setState(() {
                                _selectedStationId = val;
                              });
                              _updateLiveBalances();
                            },
                          ),
                        ),
                        if (_showReferenceStation) ...[
                          const SizedBox(width: AppDimensions.spaceM),
                          Expanded(
                            flex: 5,
                            child: CustomDropdown<int?>(
                              hint: AppStrings.referenceStationShort,
                              value: _selectedReferenceStationId,
                              borderColor: _fieldBorderColor,
                              backgroundColor: AppColors.background,
                              items: txController.stations.map((st) {
                                return CustomDropdownItem<int?>(
                                  value: st['id'] as int,
                                  label: st['name'] as String,
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedReferenceStationId = val;
                                });
                              },
                            ),
                          ),
                        ],
                        const SizedBox(width: AppDimensions.spaceM),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _showReferenceStation = !_showReferenceStation;
                              if (!_showReferenceStation) {
                                _selectedReferenceStationId = null;
                              }
                            });
                          },
                          borderRadius: AppDimensions.borderRadius2XL,
                          child: Container(
                            width: AppDimensions.inputHeight,
                            height: AppDimensions.inputHeight,
                            decoration: BoxDecoration(
                              color: _showReferenceStation
                                  ? AppColors.charcoal
                                  : AppColors.background,
                              borderRadius: AppDimensions.borderRadius2XL,
                              border: Border.all(
                                color: _showReferenceStation
                                    ? AppColors.charcoal
                                    : _fieldBorderColor,
                                width: AppDimensions.borderWidthThin,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              _showReferenceStation
                                  ? AppIcons.close
                                  : AppIcons.tabActual,
                              size: AppDimensions.iconMedium,
                              color: _showReferenceStation
                                  ? AppColors.textWhite
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spaceL),
                  ],

                  // 7. صف: التاريخ ورقم المرجع
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel(AppStrings.transactionDate),
                            InkWell(
                              onTap: () async {
                                DateTime initial = DateTime.now();
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: initial,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2035),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _dateController.text =
                                        '${picked.year}/${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}';
                                  });
                                }
                              },
                              borderRadius: AppDimensions.borderRadius2XL,
                              child: Container(
                                height: AppDimensions.inputHeight,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppDimensions.spaceL,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: AppDimensions.borderRadius2XL,
                                  border: Border.all(
                                    color: _fieldBorderColor,
                                    width: AppDimensions.borderWidthThin,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          AppIcons.calendar,
                                          size: AppDimensions.iconSmall,
                                          color: AppColors.textTertiary,
                                        ),
                                        const SizedBox(
                                            width: AppDimensions.spaceM),
                                        Text(
                                          _dateController.text,
                                          style: const TextStyle(
                                            fontSize:
                                                AppTypography.sizeBodySecondary,
                                            color: AppColors.textDarkSlate,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Icon(
                                      AppIcons.dropdownArrow,
                                      color: AppColors.textTertiary,
                                      size: AppDimensions.iconRegular,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spaceL - 2),
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel(AppStrings.referenceNumberLabel),
                            Container(
                              height: AppDimensions.inputHeight,
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: AppDimensions.borderRadius2XL,
                                border: Border.all(
                                  color: _fieldBorderColor,
                                  width: AppDimensions.borderWidthThin,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: AppDimensions.spaceL - 2,
                                    ),
                                    child: Icon(
                                      Icons.tag,
                                      color: AppColors.textTertiary,
                                      size: AppDimensions.iconRegular,
                                    ),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _referenceNumberController,
                                      style: const TextStyle(
                                        fontSize:
                                            AppTypography.sizeBodySecondary,
                                      ),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: AppDimensions.spaceXXS,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spaceL),

                  // 8. حقل البيان
                  _buildFieldLabel(AppStrings.statement),
                  Container(
                    height: 65,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: AppDimensions.borderRadius2XL,
                      border: Border.all(
                        color: _fieldBorderColor,
                        width: AppDimensions.borderWidthThin,
                      ),
                    ),
                    child: TextField(
                      controller: _statementController,
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: AppTypography.sizeBodySecondary,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.all(AppDimensions.spaceL - 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space2XL),

                  // 9. شريط الأزرار السفلي
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: AppDimensions.borderRadius2XL,
                          child: Container(
                            height: AppDimensions.inputHeight,
                            decoration: const BoxDecoration(
                              color: AppColors.background,
                              borderRadius: AppDimensions.borderRadius2XL,
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              AppStrings.cancel,
                              style: TextStyle(
                                fontSize: AppTypography.sizeBody + 1,
                                fontWeight: AppTypography.weightSemiBold,
                                color: AppColors.textSlate,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spaceL),
                      Expanded(
                        child: InkWell(
                          onTap: _saveOperation,
                          borderRadius: AppDimensions.borderRadius2XL,
                          child: Container(
                            height: AppDimensions.inputHeight,
                            decoration: const BoxDecoration(
                              color: AppColors.charcoal,
                              borderRadius: AppDimensions.borderRadius2XL,
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              AppStrings.save,
                              style: TextStyle(
                                fontSize: AppTypography.sizeBody + 1,
                                fontWeight: AppTypography.weightSemiBold,
                                color: AppColors.textWhite,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openAccountPicker(List<AccountModel> accounts) async {
    final selected = await CustomModalSheet.showItemPicker<AccountModel>(
      context: context,
      title: AppStrings.account,
      items: accounts,
      itemLabel: (acc) => acc.name,
      searchHint: AppStrings.searchHere,
      emptyText: AppStrings.noAccountsFound,
      selectedItem: _selectedAccount,
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedAccount = selected;
      });
      _updateLiveBalances();
    }
  }

  Future<void> _saveOperation() async {
    final qty = double.tryParse(_quantityController.text.trim());
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.invalidQuantity),
          backgroundColor: AppColors.dispenseRed,
        ),
      );
      return;
    }

    if (_selectedUnitId == null) return;

    final navigator = Navigator.of(context);
    final txController = context.read<TransactionsController>();
    final typeId = _calculateTypeId();
    final isActual = _selectedTab == 1;

    final units = txController.units.isNotEmpty
        ? txController.units
        : [
            {'id': 1, 'name': AppStrings.unitLiter, 'conversion_factor': 1.0},
            {'id': 2, 'name': AppStrings.unitDabba, 'conversion_factor': 20.0},
            {
              'id': 3,
              'name': AppStrings.unitBarrel,
              'conversion_factor': 200.0
            },
          ];
    final u = units.firstWhere(
      (e) => e['id'] == _selectedUnitId,
      orElse: () => {'conversion_factor': 1.0},
    );
    final unitFactor = (u['conversion_factor'] as num?)?.toDouble() ?? 1.0;
    final baseLiters = qty * unitFactor;

    final manualRef = _referenceNumberController.text.trim();

    final tx = TransactionModel(
      id: widget.editTransaction?.id,
      transactionNumber: widget.editTransaction?.transactionNumber,
      transactionDate: _dateController.text.trim().replaceAll('/', '-'),
      typeId: typeId,
      accountId: _selectedAccount?.id,
      stationId: isActual ? _selectedStationId : null,
      referenceStationId:
          isActual ? (_selectedReferenceStationId ?? _selectedStationId) : null,
      fuelTypeId: _selectedFuelTypeId,
      unitId: _selectedUnitId!,
      enteredQuantity: qty,
      baseQuantityLiters: baseLiters,
      referenceNumber: manualRef.isEmpty ? null : manualRef,
      notes: _statementController.text.trim().isEmpty
          ? null
          : _statementController.text.trim(),
    );

    bool success;
    if (_isEdit) {
      success = await txController.updateTransaction(tx);
    } else {
      success = await txController.addTransaction(tx);
    }

    if (success && mounted) {
      navigator.pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.operationSuccess),
          backgroundColor: AppColors.supplyGreen,
        ),
      );
    }
  }

  Widget _buildTopTabItem({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedTab == index;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = index;
          final accController = context.read<AccountsController>();
          final validAccounts = _getFilteredAccounts(accController.accounts);
          if (_selectedAccount == null ||
              !validAccounts.contains(_selectedAccount)) {
            _selectedAccount =
                validAccounts.isNotEmpty ? validAccounts.first : null;
          }
        });
        _updateLiveBalances();
      },
      borderRadius: AppDimensions.borderRadiusXL,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.spaceM,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.charcoal : Colors.transparent,
          borderRadius: AppDimensions.borderRadiusXL,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? AppColors.textWhite : AppColors.textTertiary,
            ),
            const SizedBox(width: AppDimensions.spaceS),
            Text(
              label,
              style: TextStyle(
                fontSize: AppTypography.sizeBodySecondary,
                fontWeight: isSelected
                    ? AppTypography.weightSemiBold
                    : AppTypography.weightMedium,
                color:
                    isSelected ? AppColors.textWhite : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceS),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: AppTypography.sizeCaption,
          fontWeight: AppTypography.weightMedium,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}
