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
import '../../models/account_model.dart';
import '../../models/transaction_model.dart';

/// واجهة كشف حساب وعمليات الحساب (توريد / صرف)
class AccountTransactionsView extends StatefulWidget {
  final AccountModel account;

  const AccountTransactionsView({
    super.key,
    required this.account,
  });

  @override
  State<AccountTransactionsView> createState() =>
      _AccountTransactionsViewState();
}

class _AccountTransactionsViewState extends State<AccountTransactionsView> {
  final TextEditingController _searchController = TextEditingController();
  final PageController _fuelPageController = PageController();
  bool _isSearching = false;
  int _selectedFuelPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.account.id != null) {
        context
            .read<TransactionsController>()
            .fetchAccountTransactions(widget.account.id!);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fuelPageController.dispose();
    super.dispose();
  }

  /// فتح نافذة تسجيل القيد والعملية المطابقة للصورة 100%
  void _openAddTransactionDialog() async {
    final isSupplier = widget.account.accountType == AccountType.supplier;
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
      account: widget.account,
      initialTabIndex: 0,
      initialDirection:
          isSupplier ? 0 : 1, // المورد افتراضياً توريد، العميل افتراضياً صرف
      initialFuelTypeId: currentFuelId,
    );
    if (widget.account.id != null && mounted) {
      context.read<TransactionsController>().fetchAccountTransactions(
            widget.account.id!,
            defaultFuelTypeId: currentFuelId,
          );
    }
  }

  /// حذف عملية مع نافذة تأكيد مطابقة تماماً للصورة 1
  void _deleteTransaction(TransactionModel tx) async {
    final confirm = await CustomDialog.showConfirmation(
      context: context,
      title: 'تأكيد!',
      message: 'هل تريد حذف هذا القيد؟',
      confirmText: 'حسناً',
      cancelText: 'إلغاء',
      isDanger: true,
    );

    if (confirm && tx.id != null && widget.account.id != null && mounted) {
      final success =
          await context.read<TransactionsController>().deleteTransaction(
                tx.id!,
                widget.account.id!,
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

  /// عرض تفاصيل العملية
  void _showTransactionDetails(TransactionModel tx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(AppStrings.operationDetails,
                style: AppTextStyles.heading2),
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
            _buildDetailRow(AppStrings.labelOperationType,
                tx.typeName ?? AppStrings.operation),
            _buildDetailRow(AppStrings.labelDate,
                AppFormatters.formatDate(tx.transactionDate)),
            if (tx.stationName != null)
              _buildDetailRow(AppStrings.labelStation, tx.stationName!),
            if (tx.referenceStationName != null &&
                tx.referenceStationName != tx.stationName)
              _buildDetailRow(
                  AppStrings.labelReferenceStation, tx.referenceStationName!),
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
              style:
                  AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
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
    final isSupplier = widget.account.accountType == AccountType.supplier;

    return Consumer<TransactionsController>(
      builder: (context, controller, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8F8F8),
          appBar: AppBar(
            title: _isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      hintText: AppStrings.searchTransactionHint,
                      hintStyle:
                          TextStyle(color: Colors.white.withOpacity(0.7)),
                      border: InputBorder.none,
                    ),
                    onChanged: (val) => controller.setSearchQuery(val),
                  )
                : Text(
                    '${AppStrings.accountOperations}: ${widget.account.name}',
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
                  if (widget.account.id != null) {
                    controller.fetchAccountTransactions(widget.account.id!);
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
                // 1. بطاقة ملخص الحساب والأرصدة (تتغير حسب الصنف بالسحب)
                _buildSummaryCard(controller, isSupplier),
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
                      label: AppStrings.quotaFilter,
                      isSelected: controller.selectedFilter == 'QUOTA',
                      onTap: () => controller.setFilter('QUOTA'),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: AppStrings.actualFilter,
                      isSelected: controller.selectedFilter == 'ACTUAL',
                      onTap: () => controller.setFilter('ACTUAL'),
                    ),
                    const Spacer(),
                    Text(
                      '${AppStrings.totalOperations}: ${controller.transactions.length}',
                      style: AppTextStyles.caption
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 4. قائمة العمليات
                Expanded(
                  child: controller.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary),
                        )
                      : controller.transactions.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    size: 56,
                                    color: AppColors.textMuted.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    AppStrings.noTransactionsFound,
                                    style: AppTextStyles.bodySecondary,
                                  ),
                                  const SizedBox(height: 12),
                                  CustomButton(
                                    text: AppStrings.recordFirstOperation,
                                    icon: Icons.add,
                                    variant: ButtonVariant.secondary,
                                    onPressed: () =>
                                        _openAddTransactionDialog(),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: controller.transactions.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final tx = controller.transactions[index];
                                return _buildTransactionCard(tx);
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

  /// بطاقة إحصائيات رصيد الحساب الموحدة (مطابقة تماماً لتصميم الصورة)
  Widget _buildSummaryCard(TransactionsController controller, bool isSupplier) {
    final fuelTypes = controller.fuelTypes.isNotEmpty
        ? controller.fuelTypes
        : [
            {'id': 1, 'name': 'بترول'},
            {'id': 2, 'name': 'ديزل'},
          ];

    return Column(
      children: [
        SizedBox(
          height: 208,
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

              final quota = controller.getQuotaLitersForFuel(fuelId);
              final actual = controller.getActualLitersForFuel(fuelId);
              final balance = controller.getBalanceLitersForFuel(fuelId);

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // الصف العلوي: اسم الحساب (يمين في RTL) + شارة الصنف البيضاوية السوداء (يسار في RTL)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // اسم الحساب (بدل Free)
                        Expanded(
                          child: Text(
                            widget.account.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // شارة الصنف البيضاوية السوداء (بدل ترقية): بترول / ديزل مباشرة بدون كلمة الصنف
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            fuelName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // خط فاصل ناعم وخفيف تحت الصف العلوي
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(
                        height: 1,
                        thickness: 0.8,
                        color: Color(0xFFF1F5F9),
                      ),
                    ),

                    // الجزء الأوسط: الرصيد المتبقي مع أيقونة النجمة ✦ (بدل 40 الأرصدة ✦)
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 18,
                          color: Color(0xFF1E293B),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppFormatters.formatQuantity(balance),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'الرصيد المتبقي',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // الجزء السفلي: المربع الرمادي الفاتح (بدل الاشتراك والمكافأة)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F5F7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          // اليمين (بدل الاشتراك): إجمالي الاعتماد / التوريد
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  AppFormatters.formatQuantity(quota),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isSupplier
                                      ? 'إجمالي التوريد'
                                      : 'إجمالي الاعتماد',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // اليسار (بدل مكافأة): إجمالي الفعلي / الصرف
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  AppFormatters.formatQuantity(actual),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isSupplier
                                      ? 'إجمالي الصرف'
                                      : 'إجمالي الفعلي',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w500,
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
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1,
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

  /// بناء بطاقة العملية الفردية (بدون رقم العملية كما طُلب)
  Widget _buildTransactionCard(TransactionModel tx) {
    // صرف اعتماد وتوريد اعتماد وتوريد فعلي تكون باللون الأخضر (+)
    // صرف فعلي فقط يكون باللون الأحمر (-)
    // عمولة التهوية تكون باللون البرتقالي التحذيري (-)
    final bool isPositive = tx.typeId == 1 || tx.typeId == 2 || tx.typeId == 4;
    final bool isActualDispense = tx.typeId == 5;
    final bool isAeration = tx.typeId == 3;

    final Color badgeColor = isActualDispense
        ? AppColors.dispenseRed
        : (isAeration ? AppColors.warning : AppColors.supplyGreen);

    final Color badgeBg = isActualDispense
        ? AppColors.dispenseLight
        : (isAeration ? const Color(0xFFFEF3C7) : AppColors.supplyLight);

    final String sign = isPositive ? '+' : '-';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // شريط ملون جانبي يوضح طبيعة العملية
              Container(width: 5, color: badgeColor),

              // المحتوى الداخلي للبطاقة
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // الصف العلوي: نوع العملية والتاريخ (بدون رقم العملية)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tx.typeName ?? AppStrings.operation,
                              style: AppTextStyles.caption.copyWith(
                                color: badgeColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined,
                                  size: 13, color: AppColors.textMuted),
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

                      // الصف الأوسط: المحطة ونوع الوقود والكمية
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // بيانات المحطة والصنف
                          Expanded(
                            child: Row(
                              children: [
                                // نوع الوقود
                                if (tx.fuelTypeName != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.local_gas_station,
                                            size: 13,
                                            color: AppColors.textSecondary),
                                        const SizedBox(width: 3),
                                        Text(
                                          tx.fuelTypeName!,
                                          style: AppTextStyles.caption.copyWith(
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],

                                // اسم المحطة المنفذة (ومرجع الخصم إن اختلف)
                                if (tx.stationName != null)
                                  Flexible(
                                    child: Text(
                                      tx.referenceStationName != null &&
                                              tx.referenceStationName !=
                                                  tx.stationName
                                          ? '${tx.stationName!} (مرجع: ${tx.referenceStationName!})'
                                          : tx.stationName!,
                                      style: AppTextStyles.bodySecondary,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // الكمية الأساسية والمعادل باللتر
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
                                '(${AppFormatters.formatQuantity(tx.baseQuantityLiters)} ${AppStrings.unitLiter})',
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // صف البيان إن وجد
                      if (tx.notes != null && tx.notes!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.description_outlined,
                                size: 14, color: AppColors.textMuted),
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

              // زر القائمة الجانبية للعملية
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert,
                    color: AppColors.textSecondary, size: 18),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppColors.border, width: 1),
                ),
                onSelected: (action) {
                  if (action == 'details') {
                    _showTransactionDetails(tx);
                  } else if (action == 'edit') {
                    OperationEntrySheet.show(
                      context: context,
                      account: widget.account,
                      editTransaction: tx,
                    );
                  } else if (action == 'delete') {
                    _deleteTransaction(tx);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'details',
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 18, color: AppColors.textSecondary),
                        SizedBox(width: 8),
                        Text(AppStrings.details, style: AppTextStyles.body),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined,
                            size: 18, color: AppColors.textSecondary),
                        SizedBox(width: 8),
                        Text(AppStrings.edit, style: AppTextStyles.body),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            size: 18, color: AppColors.dispenseRed),
                        SizedBox(width: 8),
                        Text(
                          AppStrings.delete,
                          style: TextStyle(
                              color: AppColors.dispenseRed, fontSize: 14),
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
