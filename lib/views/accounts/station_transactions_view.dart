import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/transactions_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_dialog.dart';
import '../../core/widgets/operation_entry_sheet.dart';
import '../../models/station_model.dart';
import '../../models/transaction_model.dart';

/// واجهة كشف حساب وعمليات المحطة (وارد فعلي، منصرف فعلي، عمولة تهوية، ومقاصات)
/// مخصصة للمطابقة والمحاسبة الدورية مع المحطة
class StationTransactionsView extends StatefulWidget {
  final StationModel station;

  const StationTransactionsView({
    super.key,
    required this.station,
  });

  @override
  State<StationTransactionsView> createState() => _StationTransactionsViewState();
}

class _StationTransactionsViewState extends State<StationTransactionsView> {
  final TextEditingController _searchController = TextEditingController();
  final PageController _fuelPageController = PageController();
  bool _isSearching = false;
  int _selectedFuelPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.station.id != null) {
        context.read<TransactionsController>().fetchStationTransactions(widget.station.id!);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fuelPageController.dispose();
    super.dispose();
  }

  void _openAddTransactionDialog() async {
    final controller = context.read<TransactionsController>();
    final fuelTypes = controller.fuelTypes;
    int? currentFuelId;
    if (fuelTypes.isNotEmpty && _selectedFuelPage < fuelTypes.length) {
      currentFuelId = fuelTypes[_selectedFuelPage]['id'] as int;
    } else {
      currentFuelId = controller.selectedFuelTypeId;
    }

    await OperationEntrySheet.show(
      context: context,
      initialTabIndex: 1, // فعلي افتراضياً للمحطات
      initialDirection: 0,
      initialStationId: widget.station.id,
      initialFuelTypeId: currentFuelId,
    );
    if (widget.station.id != null && mounted) {
      context.read<TransactionsController>().fetchStationTransactions(
            widget.station.id!,
            defaultFuelTypeId: currentFuelId,
          );
    }
  }

  void _deleteTransaction(TransactionModel tx) async {
    final confirm = await CustomDialog.showConfirmation(
      context: context,
      title: 'تأكيد!',
      message: 'هل تريد حذف هذا القيد من سجل المحطة؟',
      confirmText: 'حسناً',
      cancelText: 'إلغاء',
      isDanger: true,
    );

    if (confirm && tx.id != null && widget.station.id != null && mounted) {
      final success = await context.read<TransactionsController>().deleteStationTransaction(
            tx.id!,
            widget.station.id!,
          );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.transactionDeletedSuccess),
            backgroundColor: Color(0xFF15803D),
          ),
        );
      }
    }
  }

  void _showTransactionDetails(TransactionModel tx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF64748B), width: 1.2),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(AppStrings.operationDetails, style: AppTextStyles.heading2),
            IconButton(
              icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow(AppStrings.labelOperationType, tx.typeName ?? AppStrings.operation),
            _buildDetailRow(AppStrings.labelDate, AppFormatters.formatDate(tx.transactionDate)),
            if (tx.accountName != null)
              _buildDetailRow('الحساب المرتبط:', tx.accountName!),
            if (tx.stationName != null)
              _buildDetailRow(AppStrings.labelStation, tx.stationName!),
            if (tx.referenceStationName != null && tx.referenceStationName != tx.stationName)
              _buildDetailRow(AppStrings.labelReferenceStation, tx.referenceStationName!),
            _buildDetailRow(AppStrings.labelFuelType, tx.fuelTypeName ?? '-'),
            _buildDetailRow(
              AppStrings.labelEnteredQuantity,
              '${AppFormatters.formatQuantity(tx.enteredQuantity)} ${tx.unitName ?? ''}',
            ),
            _buildDetailRow(
              AppStrings.labelEquivalentLiters,
              '${AppFormatters.formatQuantity(tx.baseQuantityLiters)} ${AppStrings.unitLiter}',
            ),
            if (tx.referenceNumber != null && tx.referenceNumber!.isNotEmpty)
              _buildDetailRow('رقم المرجع:', tx.referenceNumber!),
            if (tx.notes != null && tx.notes!.isNotEmpty)
              _buildDetailRow(AppStrings.labelStatement, tx.notes!),
          ],
        ),
        actions: [
          CustomButton(
            text: AppStrings.close,
            variant: ButtonVariant.secondary,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.body),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionsController>(
      builder: (context, controller, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: _isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      hintText: 'بحث في عمليات المحطة أو التاريخ أو البيان...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                      border: InputBorder.none,
                    ),
                    onChanged: (val) => controller.setSearchQuery(val),
                  )
                : Text(
                    'كشف حساب محطة: ${widget.station.name}',
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
                      controller.setSearchQuery('');
                    }
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: AppStrings.addOperation,
                onPressed: () => _openAddTransactionDialog(),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: AppStrings.refresh,
                onPressed: () {
                  if (widget.station.id != null) {
                    controller.fetchStationTransactions(widget.station.id!);
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
                // 1. بطاقة ملخص أرصدة المحطة للمحاسبة (تتغير بالسحب بين الأصناف)
                _buildStationSummaryCard(controller),
                const SizedBox(height: 12),

                // 3. تبويبات الفلترة
                Row(
                  children: [
                    _buildFilterChip(
                      label: AppStrings.allFilter,
                      isSelected: controller.selectedFilter == 'ALL',
                      onTap: () => controller.setFilter('ALL'),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'وارد فعلي',
                      isSelected: controller.selectedFilter == 'SUPPLY',
                      onTap: () => controller.setFilter('SUPPLY'),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'منصرف فعلي',
                      isSelected: controller.selectedFilter == 'DISPENSE',
                      onTap: () => controller.setFilter('DISPENSE'),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'تهوية',
                      isSelected: controller.selectedFilter == 'AERATION',
                      onTap: () => controller.setFilter('AERATION'),
                    ),
                    const Spacer(),
                    Text(
                      '${AppStrings.totalOperations}: ${_getFilteredTransactions(controller).length}',
                      style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 4. قائمة عمليات المحطة
                Expanded(
                  child: controller.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        )
                      : _getFilteredTransactions(controller).isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.local_gas_station_outlined,
                                    size: 56,
                                    color: AppColors.textMuted.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'لا توجد عمليات مسجلة لهذه المحطة حتى الآن',
                                    style: AppTextStyles.bodySecondary,
                                  ),
                                  const SizedBox(height: 12),
                                  CustomButton(
                                    text: 'تسجيل أول عملية في المحطة',
                                    icon: Icons.add,
                                    variant: ButtonVariant.secondary,
                                    onPressed: () => _openAddTransactionDialog(),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: _getFilteredTransactions(controller).length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final tx = _getFilteredTransactions(controller)[index];
                                return _buildStationTransactionCard(tx);
                              },
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<TransactionModel> _getFilteredTransactions(TransactionsController controller) {
    return controller.transactions;
  }

  /// بطاقة إحصائيات المحطة الموحدة للمحاسبة (تتغير بالسحب بين الأصناف: بترول / ديزل)
  Widget _buildStationSummaryCard(TransactionsController controller) {
    final fuelTypes = controller.fuelTypes.isNotEmpty
        ? controller.fuelTypes
        : [
            {'id': 1, 'name': 'بترول'},
            {'id': 2, 'name': 'ديزل'},
          ];

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _fuelPageController,
            itemCount: fuelTypes.length,
            onPageChanged: (index) {
              setState(() {
                _selectedFuelPage = index;
              });
              if (index < fuelTypes.length) {
                final fuelId = fuelTypes[index]['id'] as int;
                controller.setSelectedFuelTypeId(fuelId);
              }
            },
            itemBuilder: (context, index) {
              final ft = fuelTypes[index];
              final fuelId = ft['id'] as int;
              final fuelName = ft['name'] as String;

              final supply = controller.getStationSupplyForFuel(fuelId);
              final aeration = controller.getStationAerationForFuel(fuelId);
              final dispense = controller.getStationDispenseForFuel(fuelId);
              final balance = controller.getStationBalanceForFuel(fuelId);

              final balanceColor = balance >= 0
                  ? const Color(0xFF15803D)
                  : const Color(0xFFB91C1C);

              final isPetrol = fuelName.contains('بترول') || fuelName.contains('بنزين');
              final fuelBadgeBg = isPetrol ? const Color(0xFFFEF3C7) : const Color(0xFFEFF6FF);
              final fuelBadgeBorder = isPetrol ? const Color(0xFFFDE68A) : const Color(0xFFBFDBFE);
              final fuelBadgeText = isPetrol ? const Color(0xFFB45309) : const Color(0xFF1D4ED8);

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF64748B), width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // رأس البطاقة: اسم المحطة والتهوية + شارة صنف الوقود
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFFBFDBFE), width: 0.8),
                                ),
                                child: Text(
                                  'محطة وقود',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  widget.station.name,
                                  style: AppTextStyles.heading2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // شارة الصنف المستقل
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: fuelBadgeBg,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: fuelBadgeBorder, width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.local_gas_station, size: 14, color: fuelBadgeText),
                              const SizedBox(width: 4),
                              Text(
                                'صنف: $fuelName',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: fuelBadgeText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (widget.station.location != null && widget.station.location!.isNotEmpty)
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textMuted),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    widget.station.location!,
                                    style: AppTextStyles.caption,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          const SizedBox(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'نسبة التهوية: ${widget.station.defaultCommissionRate}%',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1, color: AppColors.divider),
                    ),

                    // شبكة المؤشرات الأربعة للمحطة الخاصة بهذا الصنف
                    Row(
                      children: [
                        // 1. الوارد الفعلي (أخضر +)
                        Expanded(
                          child: _buildMetricItem(
                            title: 'الوارد الفعلي',
                            liters: supply,
                            color: const Color(0xFF15803D),
                          ),
                        ),
                        Container(width: 1, height: 38, color: AppColors.divider),

                        // 2. عمولة التهوية (برتقالي -)
                        Expanded(
                          child: _buildMetricItem(
                            title: 'عمولة التهوية',
                            liters: aeration,
                            color: const Color(0xFFD97706),
                          ),
                        ),
                        Container(width: 1, height: 38, color: AppColors.divider),

                        // 3. المنصرف الفعلي (أحمر -)
                        Expanded(
                          child: _buildMetricItem(
                            title: 'المنصرف الفعلي',
                            liters: dispense,
                            color: const Color(0xFFB91C1C),
                          ),
                        ),
                        Container(width: 1, height: 38, color: AppColors.divider),

                        // 4. الرصيد المتبقي
                        Expanded(
                          child: _buildMetricItem(
                            title: 'الرصيد المتبقي',
                            liters: balance,
                            color: balanceColor,
                            isBold: true,
                          ),
                        ),
                      ],
                    ),

                    // مكافئ الرصيد بالدباب والبراميل
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'المكافئ لرصيد $fuelName المتبقي:',
                            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                          ),
                          Text(
                            AppFormatters.formatEquivalents(balance.abs()),
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // مؤشر التنقل بين الأصناف (نقطتان فقط بدون أسهم أو نصوص)
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(fuelTypes.length, (i) {
            final isSelected = i == _selectedFuelPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isSelected ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMetricItem({
    required String title,
    required double liters,
    required Color color,
    bool isBold = false,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          '${AppFormatters.formatQuantity(liters)} لتر',
          style: TextStyle(
            fontSize: isBold ? 14 : 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          style: AppTextStyles.caption.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  /// بناء بطاقة العملية في سجل المحطة
  Widget _buildStationTransactionCard(TransactionModel tx) {
    // التوريد الفعلي (2): أخضر (+)
    // المنصرف الفعلي (5): أحمر (-)
    // عمولة التهوية (3): برتقالي (-)
    final bool isSupply = tx.typeId == 2;
    final bool isDispense = tx.typeId == 5;
    final bool isAeration = tx.typeId == 3;

    final Color badgeColor = isDispense
        ? const Color(0xFFB91C1C)
        : (isAeration ? const Color(0xFFD97706) : const Color(0xFF15803D));

    final Color badgeBg = isDispense
        ? const Color(0xFFFEE2E2)
        : (isAeration ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7));

    final String sign = isSupply ? '+' : '-';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF64748B), width: 1.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // الشريط اللوني الجانبي
              Container(width: 5, color: badgeColor),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // الصف العلوي: النوع والتاريخ
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tx.typeName ?? AppStrings.operation,
                              style: TextStyle(
                                fontSize: 12,
                                color: badgeColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                AppFormatters.formatDate(tx.transactionDate),
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // الصف الأوسط: تفاصيل الحساب والصنف والكمية
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                if (tx.fuelTypeName != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.local_gas_station, size: 13, color: AppColors.textSecondary),
                                        const SizedBox(width: 3),
                                        Text(
                                          tx.fuelTypeName!,
                                          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (tx.accountName != null)
                                  Flexible(
                                    child: Text(
                                      '${isSupply ? "المورد:" : "العميل:"} ${tx.accountName!}',
                                      style: AppTextStyles.bodySecondary.copyWith(fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // الكمية والمعادل
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$sign ${AppFormatters.formatQuantity(tx.enteredQuantity)} ${tx.unitName ?? ''}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: badgeColor,
                                ),
                              ),
                              Text(
                                '(${AppFormatters.formatQuantity(tx.baseQuantityLiters)} لتر)',
                                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // تنبيه المقاصة إن وجد
                      if (tx.referenceStationName != null && tx.referenceStationName != tx.stationName) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'بمقاصة خصم من: ${tx.referenceStationName!}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF1D4ED8)),
                          ),
                        ),
                      ],

                      // البيان
                      if (tx.notes != null && tx.notes!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.description_outlined, size: 14, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                tx.notes!,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // قائمة الخيارات
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary, size: 18),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFF64748B), width: 1.2),
                ),
                onSelected: (action) {
                  if (action == 'details') {
                    _showTransactionDetails(tx);
                  } else if (action == 'edit') {
                    OperationEntrySheet.show(
                      context: context,
                      editTransaction: tx,
                    ).then((_) {
                      if (widget.station.id != null && mounted) {
                        context.read<TransactionsController>().fetchStationTransactions(widget.station.id!);
                      }
                    });
                  } else if (action == 'delete') {
                    _deleteTransaction(tx);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'details',
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 18, color: AppColors.textSecondary),
                        SizedBox(width: 8),
                        Text(AppStrings.details, style: AppTextStyles.body),
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
                        Text(
                          AppStrings.delete,
                          style: TextStyle(color: Color(0xFFB91C1C), fontSize: 14),
                        ),
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
