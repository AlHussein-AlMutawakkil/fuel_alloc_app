import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/reports_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/custom_modal_sheet.dart';
import '../../../models/account_model.dart';
import '../../../models/station_model.dart';

/// نتيجة خيارات الفلترة المحددة من النافذة
class ReportFilterResult {
  final AccountModel? selectedAccount;
  final StationModel? selectedStation;
  final int? selectedFuelTypeId;
  final String selectedOperationType;
  final DateTime? fromDate;
  final DateTime? toDate;
  final Set<String> visibleColumns;

  const ReportFilterResult({
    this.selectedAccount,
    this.selectedStation,
    this.selectedFuelTypeId,
    required this.selectedOperationType,
    this.fromDate,
    this.toDate,
    required this.visibleColumns,
  });
}

/// نافذة خيارات وفلترة التقرير وخيارات الإظهار الموحدة (مطابقة لجميع متطلبات التصميم)
class ReportFilterSheet extends StatefulWidget {
  final AccountType accountType;
  final AccountModel? initialAccount;
  final StationModel? initialStation;
  final int? initialFuelTypeId;
  final String initialOperationType;
  final DateTime? initialFromDate;
  final DateTime? initialToDate;
  final Set<String>? initialVisibleColumns;

  const ReportFilterSheet({
    super.key,
    required this.accountType,
    this.initialAccount,
    this.initialStation,
    this.initialFuelTypeId,
    this.initialOperationType = 'ALL',
    this.initialFromDate,
    this.initialToDate,
    this.initialVisibleColumns,
  });

  static Future<ReportFilterResult?> show({
    required BuildContext context,
    required AccountType accountType,
    AccountModel? initialAccount,
    StationModel? initialStation,
    int? initialFuelTypeId,
    String initialOperationType = 'ALL',
    DateTime? initialFromDate,
    DateTime? initialToDate,
    Set<String>? initialVisibleColumns,
  }) {
    return showModalBottomSheet<ReportFilterResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ReportFilterSheet(
        accountType: accountType,
        initialAccount: initialAccount,
        initialStation: initialStation,
        initialFuelTypeId: initialFuelTypeId,
        initialOperationType: initialOperationType,
        initialFromDate: initialFromDate,
        initialToDate: initialToDate,
        initialVisibleColumns: initialVisibleColumns,
      ),
    );
  }

  @override
  State<ReportFilterSheet> createState() => _ReportFilterSheetState();
}

class _ReportFilterSheetState extends State<ReportFilterSheet> {
  AccountModel? _selectedAccount;
  StationModel? _selectedStation;
  int? _selectedFuelTypeId;
  late String _selectedOperationType;
  DateTime? _fromDate;
  DateTime? _toDate;

  late Set<String> _visibleColumns;

  static const List<MapEntry<String, String>> _availableColumns = [
    MapEntry('date', AppStrings.colDate),
    MapEntry('txNumber', AppStrings.colTxNumber),
    MapEntry('type', AppStrings.colType),
    MapEntry('fuelType', AppStrings.colFuelType),
    MapEntry('quantity', AppStrings.colQuantity),
    MapEntry('unit', AppStrings.colUnit),
    MapEntry('station', AppStrings.stationCol),
    MapEntry('recipient', AppStrings.recipientCol),
    MapEntry('notes', AppStrings.colNotes),
    MapEntry('balance', AppStrings.colBalance),
  ];

  @override
  void initState() {
    super.initState();
    _selectedAccount = widget.initialAccount;
    _selectedStation = widget.initialStation;
    _selectedFuelTypeId = widget.initialFuelTypeId;
    _selectedOperationType = widget.initialOperationType;
    _fromDate = widget.initialFromDate;
    _toDate = widget.initialToDate;

    _visibleColumns = widget.initialVisibleColumns != null
        ? Set<String>.from(widget.initialVisibleColumns!)
        : {
            'date',
            'txNumber',
            'type',
            'fuelType',
            'quantity',
            'unit',
            'station',
            'recipient',
            'balance',
          };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reportsCtrl = context.read<ReportsController>();
      if (_selectedAccount == null && _selectedStation == null) {
        setState(() {
          if (widget.accountType == AccountType.station) {
            if (reportsCtrl.allStations.isNotEmpty) {
              _selectedStation = reportsCtrl.allStations.first;
            }
          } else if (widget.accountType == AccountType.supplier) {
            if (reportsCtrl.suppliers.isNotEmpty) {
              _selectedAccount = reportsCtrl.suppliers.first;
            }
          } else if (widget.accountType == AccountType.beneficiary) {
            if (reportsCtrl.beneficiaries.isNotEmpty) {
              _selectedAccount = reportsCtrl.beneficiaries.first;
            }
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportsCtrl = context.watch<ReportsController>();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.radiusCard + 4),
          topRight: Radius.circular(AppDimensions.radiusCard + 4),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // شريط الرأس: زر الإغلاق X في أقصى اليسار، والعنوان في المنتصف
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spaceXL,
                AppDimensions.spaceL,
                AppDimensions.spaceXL,
                AppDimensions.spaceS,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft, // زر الإغلاق في أقصى اليسار
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.textPrimary,
                        size: AppDimensions.iconMedium + 4,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const Text(
                    AppStrings.selectFilter, // "اختر الفلتر"
                    style: TextStyle(
                      fontSize: AppTypography.sizeH2,
                      fontWeight: AppTypography.weightSemiBold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const Divider(
              height: 1,
              thickness: AppDimensions.borderWidthHairline,
              color: AppColors.borderLight,
            ),

            // جسم الفلترة: البطاقتان المعتمدتان
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spaceXL,
                  vertical: AppDimensions.spaceL,
                ),
                children: [
                  // 1. البطاقة الأولى: خيارات التقرير
                  _buildReportOptionsCard(reportsCtrl),

                  const SizedBox(height: AppDimensions.spaceL),

                  // 2. البطاقة الثانية: خيارات الإظهار (اختيار الأعمدة)
                  _buildDisplayOptionsCard(),

                  const SizedBox(height: AppDimensions.spaceL),
                ],
              ),
            ),

            // زر "معاينة" باللون الأساسي لتنسيق التطبيق (AppColors.primary)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spaceXL,
                AppDimensions.spaceS,
                AppDimensions.spaceXL,
                AppDimensions.spaceXL,
              ),
              child: SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, // اللون الأساسي المعتمد للتطبيق
                    foregroundColor: AppColors.textWhite,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                    ),
                  ),
                  onPressed: () {
                    AccountModel? account = _selectedAccount;
                    StationModel? station = _selectedStation;
                    if (account == null && station == null) {
                      if (widget.accountType == AccountType.station &&
                          reportsCtrl.allStations.isNotEmpty) {
                        station = reportsCtrl.allStations.first;
                      } else if (widget.accountType == AccountType.supplier &&
                          reportsCtrl.suppliers.isNotEmpty) {
                        account = reportsCtrl.suppliers.first;
                      } else if (widget.accountType == AccountType.beneficiary &&
                          reportsCtrl.beneficiaries.isNotEmpty) {
                        account = reportsCtrl.beneficiaries.first;
                      }
                    }

                    Navigator.of(context).pop(
                      ReportFilterResult(
                        selectedAccount: account,
                        selectedStation: station,
                        selectedFuelTypeId: _selectedFuelTypeId,
                        selectedOperationType: _selectedOperationType,
                        fromDate: _fromDate,
                        toDate: _toDate,
                        visibleColumns: _visibleColumns,
                      ),
                    );
                  },
                  child: const Text(
                    AppStrings.preview, // "معاينة"
                    style: TextStyle(
                      fontSize: AppTypography.sizeBody + 2,
                      fontWeight: AppTypography.weightBold,
                      color: AppColors.textWhite,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 1. البطاقة الأولى: خيارات التقرير (الحساب مثل السابق، والتاريخان في صف واحد)
  Widget _buildReportOptionsCard(ReportsController reportsCtrl) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: AppColors.borderLight, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(
                AppIcons.filterAction,
                size: AppDimensions.iconSmall + 2,
                color: AppColors.primary,
              ),
              SizedBox(width: AppDimensions.spaceS),
              Text(
                AppStrings.reportOptions,
                style: TextStyle(
                  fontSize: AppTypography.sizeBody,
                  fontWeight: AppTypography.weightBold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceL),

          // حقل نوع العملية
          _buildFieldContainer(
            onTap: () async {
              final options = <MapEntry<String, String>>[
                const MapEntry('ALL', AppStrings.allOperations),
                if (widget.accountType == AccountType.station) ...const [
                  MapEntry('SUPPLY', AppStrings.supplyTransactionsTitle),
                  MapEntry('DISPENSE', AppStrings.dispenseTransactionsTitle),
                  MapEntry('AERATION', AppStrings.aerationTransactionsTitle),
                  MapEntry('TRANSFER', AppStrings.transferTransactionsTitle),
                ] else ...const [
                  MapEntry('QUOTA', AppStrings.tabQuota),
                  MapEntry('ACTUAL', AppStrings.tabActual),
                  MapEntry('TRANSFER', AppStrings.tabTransfer),
                ],
              ];
              final picked = await CustomModalSheet.showItemPicker<
                  MapEntry<String, String>>(
                context: context,
                title: AppStrings.colType,
                items: options,
                selectedItem: options.firstWhere(
                  (e) => e.key == _selectedOperationType,
                  orElse: () => options.first,
                ),
                itemLabel: (e) => e.value,
              );
              if (picked != null) {
                setState(() => _selectedOperationType = picked.key);
              }
            },
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _getOperationTypeLabel(),
                    style: const TextStyle(
                      fontSize: AppTypography.sizeBody,
                      fontWeight: AppTypography.weightSemiBold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.textSecondary,
                  size: AppDimensions.iconLarge,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.spaceM),

          // حقل الحساب (مثل السابق: الحساب / المحطة)
          _buildFieldContainer(
            onTap: () {
              if (widget.accountType == AccountType.station) {
                _pickStation(reportsCtrl);
              } else {
                _pickAccount(reportsCtrl);
              }
            },
            child: Row(
              children: [
                const Icon(
                  AppIcons.account,
                  color: AppColors.textSecondary,
                  size: AppDimensions.iconMedium,
                ),
                const SizedBox(width: AppDimensions.spaceM),
                Expanded(
                  child: Text(
                    _getAccountOrStationLabel(),
                    style: TextStyle(
                      fontSize: AppTypography.sizeBody,
                      fontWeight: _hasSelectedAccountOrStation()
                          ? AppTypography.weightSemiBold
                          : AppTypography.weightRegular,
                      color: _hasSelectedAccountOrStation()
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.textSecondary,
                  size: AppDimensions.iconLarge,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.spaceM),

          // حقل صنف الوقود
          _buildFieldContainer(
            onTap: () async {
              final items = [
                const MapEntry<int?, String>(null, AppStrings.allAccounts),
                ...reportsCtrl.fuelTypes.map((ft) => MapEntry<int?, String>(
                    ft['id'] as int, ft['name'] as String)),
              ];
              final picked =
                  await CustomModalSheet.showItemPicker<MapEntry<int?, String>>(
                context: context,
                title: AppStrings.colFuelType,
                items: items,
                selectedItem: items.firstWhere(
                  (e) => e.key == _selectedFuelTypeId,
                  orElse: () => items.first,
                ),
                itemLabel: (e) => e.value,
              );
              if (picked != null) {
                setState(() => _selectedFuelTypeId = picked.key);
              }
            },
            child: Row(
              children: [
                const Icon(
                  AppIcons.category,
                  color: AppColors.textSecondary,
                  size: AppDimensions.iconMedium,
                ),
                const SizedBox(width: AppDimensions.spaceM),
                Expanded(
                  child: Text(
                    _getFuelTypeName(reportsCtrl),
                    style: TextStyle(
                      fontSize: AppTypography.sizeBody,
                      fontWeight: _selectedFuelTypeId != null
                          ? AppTypography.weightSemiBold
                          : AppTypography.weightRegular,
                      color: _selectedFuelTypeId != null
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.textSecondary,
                  size: AppDimensions.iconLarge,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.spaceM),

          // التاريخ من وإلى مثل السابق: في صف واحد متناسق (Row)
          Row(
            children: [
              Expanded(
                child: _buildDateFieldBox(
                  placeholder: AppStrings.fromDateShort, // "من"
                  date: _fromDate,
                  onTap: () => _pickDate(isFrom: true),
                  onClear: () => setState(() => _fromDate = null),
                ),
              ),
              const SizedBox(width: AppDimensions.spaceM),
              Expanded(
                child: _buildDateFieldBox(
                  placeholder: AppStrings.toDateShort, // "الى"
                  date: _toDate,
                  onTap: () => _pickDate(isFrom: false),
                  onClear: () => setState(() => _toDate = null),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 2. البطاقة الثانية: خيارات الإظهار (Display Options)
  Widget _buildDisplayOptionsCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: AppColors.borderLight, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(
                AppIcons.tableChart,
                size: AppDimensions.iconSmall + 2,
                color: AppColors.primary,
              ),
              SizedBox(width: AppDimensions.spaceS),
              Text(
                AppStrings.displayOptions,
                style: TextStyle(
                  fontSize: AppTypography.sizeBody,
                  fontWeight: AppTypography.weightBold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceS),
          const Text(
            'حدد الأعمدة المراد عرضها في جدول التقرير:',
            style: TextStyle(
              fontSize: AppTypography.sizeCaption,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceM),

          // قائمة مربعات الاختيار بنمط خفيف ومريح
          Wrap(
            spacing: AppDimensions.spaceM,
            runSpacing: AppDimensions.spaceS,
            children: _availableColumns.map((col) {
              final isChecked = _visibleColumns.contains(col.key);
              return InkWell(
                onTap: () {
                  setState(() {
                    if (isChecked) {
                      if (_visibleColumns.length > 1) {
                        _visibleColumns.remove(col.key);
                      }
                    } else {
                      _visibleColumns.add(col.key);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: isChecked,
                          activeColor: AppColors.primary,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _visibleColumns.add(col.key);
                              } else if (_visibleColumns.length > 1) {
                                _visibleColumns.remove(col.key);
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spaceXS),
                      Text(
                        col.value,
                        style: TextStyle(
                          fontSize: AppTypography.sizeBodySecondary,
                          fontWeight: isChecked
                              ? AppTypography.weightBold
                              : AppTypography.weightMedium,
                          color: isChecked
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// الحاوية الموحدة لجميع الحقول (بنفس الأبعاد، الحواف، ولون البردر المتناسق 100%)
  Widget _buildFieldContainer({
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceL),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
            border: Border.all(
              color: AppColors.border,
              width: 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }

  /// مربع حقل التاريخ (داخل الصف المشترك)
  Widget _buildDateFieldBox({
    required String placeholder,
    required DateTime? date,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    final hasDate = date != null;
    final dateStr = hasDate
        ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
        : placeholder;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceM),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
            border: Border.all(
              color: AppColors.border,
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                AppIcons.calendar,
                color: AppColors.textSecondary,
                size: AppDimensions.iconSmall + 3,
              ),
              const SizedBox(width: AppDimensions.spaceS),
              Expanded(
                child: Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: AppTypography.sizeBodySecondary,
                    fontWeight: hasDate
                        ? AppTypography.weightSemiBold
                        : AppTypography.weightMedium,
                    color: hasDate ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasDate)
                GestureDetector(
                  onTap: onClear,
                  child: const Icon(
                    Icons.close,
                    size: AppDimensions.iconSmall + 2,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasSelectedAccountOrStation() {
    return _selectedAccount != null || _selectedStation != null;
  }

  String _getAccountOrStationLabel() {
    if (widget.accountType == AccountType.station) {
      return _selectedStation?.name ?? AppStrings.selectStationPrompt;
    }
    return _selectedAccount?.name ?? (widget.accountType == AccountType.supplier ? AppStrings.selectSupplierPrompt : AppStrings.selectBeneficiaryPrompt);
  }

  String _getFuelTypeName(ReportsController reportsCtrl) {
    if (_selectedFuelTypeId == null) return AppStrings.selectFuelType;
    final ft = reportsCtrl.fuelTypes.firstWhere(
      (element) => element['id'] == _selectedFuelTypeId,
      orElse: () => {'name': AppStrings.selectFuelType},
    );
    return ft['name'] as String;
  }

  String _getOperationTypeLabel() {
    switch (_selectedOperationType) {
      case 'QUOTA':
        return AppStrings.tabQuota;
      case 'ACTUAL':
        return AppStrings.tabActual;
      case 'TRANSFER':
        return AppStrings.tabTransfer;
      case 'SUPPLY':
        return AppStrings.supplyTransactionsTitle;
      case 'DISPENSE':
        return AppStrings.dispenseTransactionsTitle;
      case 'AERATION':
        return AppStrings.aerationTransactionsTitle;
      default:
        return AppStrings.allOperations;
    }
  }

  Future<void> _pickAccount(ReportsController reportsCtrl) async {
    final accounts = widget.accountType == AccountType.supplier
        ? reportsCtrl.suppliers
        : reportsCtrl.beneficiaries;

    if (accounts.isEmpty) return;

    final picked = await CustomModalSheet.showItemPicker<AccountModel>(
      context: context,
      title: widget.accountType == AccountType.supplier
          ? AppStrings.selectSupplierPrompt
          : AppStrings.selectBeneficiaryPrompt,
      items: accounts,
      selectedItem: _selectedAccount ?? accounts.first,
      itemLabel: (acc) => acc.name,
    );

    if (picked != null && mounted) {
      setState(() => _selectedAccount = picked);
    }
  }

  Future<void> _pickStation(ReportsController reportsCtrl) async {
    final stations = reportsCtrl.allStations;
    if (stations.isEmpty) return;

    final picked = await CustomModalSheet.showItemPicker<StationModel>(
      context: context,
      title: AppStrings.station,
      items: stations,
      selectedItem: _selectedStation ?? stations.first,
      itemLabel: (st) => st.name,
    );

    if (picked != null && mounted) {
      setState(() => _selectedStation = picked);
    }
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = (isFrom ? _fromDate : _toDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.textWhite,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }
}
