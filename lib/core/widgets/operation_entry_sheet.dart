import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/accounts_controller.dart';
import '../../controllers/transactions_controller.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../models/account_model.dart';
import '../../models/transaction_model.dart';

/// واجهة تسجيل وتعديل القيود والعمليات (مكون مشترك وذكي لكافة شاشات التطبيق)
/// مطابقة بنسبة 100% للتصميم المعتمد والملاحظات الصوتية الدقيقة
class OperationEntrySheet extends StatefulWidget {
  final AccountModel? initialAccount;
  final TransactionModel? editTransaction;
  final int initialTabIndex; // 0: اعتماد, 1: فعلي, 2: نسبة
  final int initialDirection; // 0: توريد, 1: صرف

  const OperationEntrySheet({
    super.key,
    this.initialAccount,
    this.editTransaction,
    this.initialTabIndex = 0,
    this.initialDirection = 0,
  });

  /// فتح نافذة تسجيل القيد بتنسيق نافذة منبثقة مطابقة للصورة المعتمدة
  static Future<bool?> show({
    required BuildContext context,
    AccountModel? account,
    TransactionModel? editTransaction,
    int initialTabIndex = 0,
    int initialDirection = 0,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) => OperationEntrySheet(
        initialAccount: account,
        editTransaction: editTransaction,
        initialTabIndex: initialTabIndex,
        initialDirection: initialDirection,
      ),
    );
  }

  @override
  State<OperationEntrySheet> createState() => _OperationEntrySheetState();
}

class _OperationEntrySheetState extends State<OperationEntrySheet> {
  // لون حدود الحقول الواضح والواثق (بدون بهتان)
  static const Color _fieldBorderColor = Color(0xFF64748B);

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
  final TextEditingController _referenceNumberController = TextEditingController();

  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.editTransaction != null;

    if (_isEdit) {
      final tx = widget.editTransaction!;
      // تحديد التبويب والاتجاه بناءً على نوع القيد
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
      _showReferenceStation = tx.referenceStationId != null && tx.referenceStationId != tx.stationId;

      _selectedFuelTypeId = tx.fuelTypeId;
      _selectedUnitId = tx.unitId;
      _quantityController.text = tx.enteredQuantity.toString();
      _dateController.text = tx.transactionDate.replaceAll('-', '/');
      _statementController.text = tx.notes ?? '';
      // ملاحظة المستخدم: رقم المرجع هو الرقم اليدوي فقط
      _referenceNumberController.text = tx.referenceNumber ?? '';
    } else {
      _selectedTab = widget.initialTabIndex;
      _selectedDirection = widget.initialDirection;

      final now = DateTime.now();
      _dateController.text =
          '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}';
    }

    _selectedAccount = widget.initialAccount;

    // تحميل وتعيين القيم المرجعية الافتراضية
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final txController = context.read<TransactionsController>();
      final accController = context.read<AccountsController>();

      if (accController.accounts.isEmpty) {
        await accController.fetchAccounts();
      }

      // مطابقة الحساب إذا تم التمرير في التعديل
      if (_selectedAccount == null && widget.editTransaction?.accountId != null) {
        final matches = accController.accounts.where(
          (a) => a.id == widget.editTransaction!.accountId,
        );
        if (matches.isNotEmpty) {
          _selectedAccount = matches.first;
        }
      }

      // إذا لم يكن هناك حساب محدد، اختيار أول حساب مناسب لنوع الحركة تلقائياً
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

      // جلب الأرصدة الحالية للحساب والمحطة
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

  /// تصفية الحسابات بذكاء حسب نوع العملية (توريد للموردين / صرف للعملاء)
  List<AccountModel> _getFilteredAccounts(List<AccountModel> accounts) {
    if (_selectedTab == 2) {
      // تبويب النسبة: يظهر الجميع
      return accounts;
    }
    if (_selectedDirection == 0) {
      // توريد: الموردين فقط
      return accounts.where((a) => a.accountType == AccountType.supplier).toList();
    } else {
      // صرف: العملاء والمستفيدين فقط
      return accounts.where((a) => a.accountType == AccountType.beneficiary).toList();
    }
  }

  /// تحديث رصيد الحساب ورصيد المحطة بشكل لحظي بدون نصوص زائدة
  Future<void> _updateLiveBalances() async {
    final txController = context.read<TransactionsController>();

    if (_selectedAccount?.id != null) {
      final isSupplier = _selectedAccount!.accountType == AccountType.supplier;
      final bal = await txController.getAccountBalance(_selectedAccount!.id!, isSupplier);
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

  // حساب نوع العملية وفق التبويب والاتجاه
  int _calculateTypeId() {
    if (_selectedTab == 0) {
      // اعتماد
      return _selectedDirection == 0 ? 1 : 4; // 1: توريد اعتماد, 4: صرف اعتماد
    } else if (_selectedTab == 1) {
      // فعلي
      return _selectedDirection == 0 ? 2 : 5; // 2: توريد فعلي, 5: صرف فعلي
    } else {
      // نسبة (عمولة تهوية)
      return 3;
    }
  }

  // عنوان النافذة العلوي النظامي المعتمد
  String _getTitle() {
    return _isEdit ? 'تعديل قيد' : 'تسجيل قيد';
  }

  @override
  Widget build(BuildContext context) {
    final txController = context.watch<TransactionsController>();
    final accController = context.watch<AccountsController>();

    final fuelTypes = txController.fuelTypes.isNotEmpty
        ? txController.fuelTypes
        : [
            {'id': 1, 'name': 'بنزين'},
            {'id': 2, 'name': 'ديزل'},
          ];

    final units = txController.units.isNotEmpty
        ? txController.units
        : [
            {'id': 1, 'name': AppStrings.unitLiter, 'conversion_factor': 1.0},
            {'id': 2, 'name': AppStrings.unitDabba, 'conversion_factor': 20.0},
            {'id': 3, 'name': AppStrings.unitBarrel, 'conversion_factor': 200.0},
          ];

    _selectedFuelTypeId ??= fuelTypes.first['id'] as int?;
    _selectedUnitId ??= units.first['id'] as int?;

    // حساب المعادل باللتر
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

    // اسم الوحدة الحالية
    final currentUnitName = units.firstWhere(
      (e) => e['id'] == _selectedUnitId,
      orElse: () => {'name': AppStrings.unitLiter},
    )['name'] as String;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. الشريط العلوي: العنوان في المنتصف، وزر X على اليسار (في RTL الأول يمين والثاني يسار)
                  Row(
                    children: [
                      const SizedBox(width: 32), // موازنة المساحة
                      Expanded(
                        child: Text(
                          _getTitle(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF475569), size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 2. التبويبات الثلاثة العلوية (اعتماد / فعلي / نسبة) مع حواف واضحة (6px)
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _fieldBorderColor, width: 1.2),
                    ),
                    child: Row(
                      children: [
                        // تبويب 1 (يمين): اعتماد
                        Expanded(
                          child: _buildTopTabItem(
                            index: 0,
                            label: 'اعتماد',
                            icon: Icons.receipt_long_outlined,
                          ),
                        ),
                        // تبويب 2 (وسط): فعلي
                        Expanded(
                          child: _buildTopTabItem(
                            index: 1,
                            label: 'فعلي',
                            icon: Icons.swap_horiz,
                          ),
                        ),
                        // تبويب 3 (يسار): نسبة
                        Expanded(
                          child: _buildTopTabItem(
                            index: 2,
                            label: 'نسبة',
                            icon: Icons.percent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. زرا الاتجاه (↓ توريد / ↑ صرف) - أبعاد واضحة ومحددة
                  if (_selectedTab != 2) ...[
                    Container(
                      height: 42,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _fieldBorderColor, width: 1.2),
                      ),
                      child: Row(
                        children: [
                          // زر توريد (يمين في RTL) - أخضر غامق مطابق لـ "له (دائن)"
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedDirection = 0;
                                  // تصفية الحساب الذكي تلقائياً
                                  final validAccounts = _getFilteredAccounts(accController.accounts);
                                  if (_selectedAccount == null || !validAccounts.contains(_selectedAccount)) {
                                    _selectedAccount = validAccounts.isNotEmpty ? validAccounts.first : null;
                                  }
                                });
                                _updateLiveBalances();
                              },
                              borderRadius: BorderRadius.circular(5),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _selectedDirection == 0
                                      ? const Color(0xFF15803D)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.arrow_downward,
                                      size: 16,
                                      color: _selectedDirection == 0
                                          ? Colors.white
                                          : const Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'توريد',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: _selectedDirection == 0
                                            ? Colors.white
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // زر صرف (يسار في RTL) - أحمر مطابق لـ "عليه (مدين)"
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedDirection = 1;
                                  // تصفية الحساب الذكي تلقائياً
                                  final validAccounts = _getFilteredAccounts(accController.accounts);
                                  if (_selectedAccount == null || !validAccounts.contains(_selectedAccount)) {
                                    _selectedAccount = validAccounts.isNotEmpty ? validAccounts.first : null;
                                  }
                                });
                                _updateLiveBalances();
                              },
                              borderRadius: BorderRadius.circular(5),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _selectedDirection == 1
                                      ? const Color(0xFFB91C1C)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.arrow_upward,
                                      size: 16,
                                      color: _selectedDirection == 1
                                          ? Colors.white
                                          : const Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'صرف',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: _selectedDirection == 1
                                            ? Colors.white
                                            : const Color(0xFF64748B),
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
                    const SizedBox(height: 12),
                  ],

                  // 4. حقل الحساب مع الرصيد المباشر وحدود واضحة
                  _buildFieldLabel('الحساب'),
                  InkWell(
                    onTap: () => _openAccountPicker(_getFilteredAccounts(accController.accounts)),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _fieldBorderColor, width: 1.2),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: Color(0xFF64748B), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedAccount?.name ?? 'اختر الحساب',
                              style: TextStyle(
                                fontSize: 14,
                                color: _selectedAccount != null
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFF94A3B8),
                                fontWeight: _selectedAccount != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          // عرض رصيد الحساب المباشر بشكل أنيق ومختصر
                          if (_accountBalanceLiters != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: _fieldBorderColor, width: 1),
                              ),
                              child: Text(
                                '${AppFormatters.formatQuantity(_accountBalanceLiters!)} لتر',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _accountBalanceLiters! >= 0
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFFB91C1C),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B), size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 5. صف: الكمية (يميناً flex: 6) والصنف (يساراً flex: 4) بحدود واضحة
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // الكمية على اليمين
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('الكمية'),
                            Container(
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: _fieldBorderColor, width: 1.2),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _quantityController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.start,
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                                        hintText: '0.00',
                                        hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  // قائمة اختيار الوحدة داخل الحقل مع سهم
                                  PopupMenuButton<int>(
                                    initialValue: _selectedUnitId,
                                    onSelected: (val) {
                                      setState(() {
                                        _selectedUnitId = val;
                                      });
                                    },
                                    itemBuilder: (ctx) => units.map((u) {
                                      return PopupMenuItem<int>(
                                        value: u['id'] as int,
                                        child: Text(u['name'] as String),
                                      );
                                    }).toList(),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          right: BorderSide(color: _fieldBorderColor, width: 1.2),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            currentUnitName,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          const Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF64748B)),
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
                      const SizedBox(width: 8),

                      // الصنف على اليسار
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('الصنف'),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: _fieldBorderColor, width: 1.2),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  isExpanded: true,
                                  value: _selectedFuelTypeId,
                                  icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B), size: 18),
                                  items: fuelTypes.map((ft) {
                                    return DropdownMenuItem<int>(
                                      value: ft['id'] as int,
                                      child: Text(
                                        ft['name'] as String,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _selectedFuelTypeId = val;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // عرض المعادل باللتر إذا اختيرت وحدة غير اللتر
                  if (_selectedUnitId != 1 && calculatedLiters > 0) ...[
                    const SizedBox(height: 3),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        'المعادل: ${AppFormatters.formatQuantity(calculatedLiters)} لتر',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // 6. حقل المحطة مع زر التحويل (يظهر مرجع المحطة بجانبها في نفس الصف بدون نصوص زائدة)
                  if (_selectedTab == 1) ...[
                    if (!_showReferenceStation)
                      _buildFieldLabel('المحطة')
                    else
                      Row(
                        children: [
                          Expanded(flex: 5, child: _buildFieldLabel('المحطة')),
                          const SizedBox(width: 8),
                          Expanded(flex: 5, child: _buildFieldLabel('مرجع المحطة')),
                          const SizedBox(width: 52), // موازنة زر التحويل
                        ],
                      ),
                    Row(
                      children: [
                        // حقل اختيار المحطة
                        Expanded(
                          flex: 5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: _fieldBorderColor, width: 1.2),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int?>(
                                      isExpanded: true,
                                      value: _selectedStationId,
                                      hint: const Text('المحطة', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                                      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B), size: 18),
                                      items: txController.stations.map((st) {
                                        return DropdownMenuItem<int?>(
                                          value: st['id'] as int,
                                          child: Text(
                                            st['name'] as String,
                                            style: const TextStyle(fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedStationId = val;
                                        });
                                        _updateLiveBalances();
                                      },
                                    ),
                                  ),
                                ),
                                // عرض الرصيد المتبقي في المحطة إذا لم يكن حقل المرجع مفتوحاً
                                if (!_showReferenceStation && _stationBalanceLiters != null) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: _fieldBorderColor, width: 1),
                                    ),
                                    child: Text(
                                      '${AppFormatters.formatQuantity(_stationBalanceLiters!)} لتر',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        // حقل مرجع المحطة (يظهر بجانب المحطة في نفس الصف)
                        if (_showReferenceStation) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 5,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: _fieldBorderColor, width: 1.2),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int?>(
                                  isExpanded: true,
                                  value: _selectedReferenceStationId,
                                  hint: const Text('محطة المرجع', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                                  icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B), size: 18),
                                  items: txController.stations.map((st) {
                                    return DropdownMenuItem<int?>(
                                      value: st['id'] as int,
                                      child: Text(
                                        st['name'] as String,
                                        style: const TextStyle(fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedReferenceStationId = val;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(width: 8),

                        // زر التحويل (يظهر أو يخفي حقل مرجع المحطة بجانبها)
                        InkWell(
                          onTap: () {
                            setState(() {
                              _showReferenceStation = !_showReferenceStation;
                              if (!_showReferenceStation) {
                                _selectedReferenceStationId = null;
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            width: 44,
                            height: 46,
                            decoration: BoxDecoration(
                              color: _showReferenceStation ? const Color(0xFF102A43) : Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _showReferenceStation ? const Color(0xFF102A43) : _fieldBorderColor,
                                width: 1.2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              _showReferenceStation ? Icons.close : Icons.swap_horiz,
                              size: 20,
                              color: _showReferenceStation ? Colors.white : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 7. صف: التاريخ (يميناً flex: 6) ورقم المرجع (يساراً flex: 4) بحدود واضحة
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // التاريخ على اليمين
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('التاريخ'),
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
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                height: 46,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: _fieldBorderColor, width: 1.2),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF64748B)),
                                        const SizedBox(width: 6),
                                        Text(
                                          _dateController.text,
                                          style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                                        ),
                                      ],
                                    ),
                                    const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B), size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // رقم المرجع على اليسار
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('رقم المرجع'),
                            Container(
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: _fieldBorderColor, width: 1.2),
                              ),
                              child: Row(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Icon(Icons.tag, color: Color(0xFF64748B), size: 18),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _referenceNumberController,
                                      style: const TextStyle(fontSize: 13),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 2),
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
                  const SizedBox(height: 12),

                  // 8. حقل البيان بحدود واضحة وبدون نصوص زائدة
                  _buildFieldLabel('البيان'),
                  Container(
                    height: 65,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _fieldBorderColor, width: 1.2),
                    ),
                    child: TextField(
                      controller: _statementController,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 9. شريط الأزرار السفلي (حفظ الأخضر يميناً flex: 5 وإلغاء الأبيض يساراً flex: 3 في RTL)
                  Row(
                    children: [
                      // زر حفظ الأخضر المعتمد
                      Expanded(
                        flex: 5,
                        child: InkWell(
                          onTap: _saveOperation,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF15803D),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'حفظ',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // زر إلغاء الأبيض بحدود واضحة
                      Expanded(
                        flex: 3,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: _fieldBorderColor, width: 1.2),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'إلغاء',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF475569),
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

  // نافذة اختيار الحساب بأسلوب منسدل سريع وقائمة مصفاة
  void _openAccountPicker(List<AccountModel> accounts) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      builder: (ctx) {
        String filterText = '';
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final filtered = accounts.where((a) {
              return filterText.isEmpty ||
                  a.name.toLowerCase().contains(filterText.toLowerCase());
            }).toList();

            return Container(
              padding: const EdgeInsets.all(16),
              height: 380,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDirection == 0 ? 'اختر المورد' : 'اختر العميل المستفيد',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'بحث...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: _fieldBorderColor, width: 1.2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: _fieldBorderColor, width: 1.2),
                      ),
                    ),
                    onChanged: (val) {
                      setSheetState(() {
                        filterText = val.trim();
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text('لا توجد حسابات مسجلة لهذا النوع', style: TextStyle(color: Color(0xFF94A3B8))),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, idx) {
                              final acc = filtered[idx];
                              return ListTile(
                                leading: const Icon(Icons.person_outline, color: Color(0xFF64748B)),
                                title: Text(acc.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                subtitle: Text(
                                  acc.accountType == AccountType.supplier ? 'مورد (جهة عليا)' : 'عميل مستفيد',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                                onTap: () {
                                  setState(() {
                                    _selectedAccount = acc;
                                  });
                                  _updateLiveBalances();
                                  Navigator.of(ctx).pop();
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // حفظ أو تعديل القيد
  Future<void> _saveOperation() async {
    final qty = double.tryParse(_quantityController.text.trim());
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.invalidQuantity),
          backgroundColor: Color(0xFFB91C1C),
        ),
      );
      return;
    }

    if (_selectedUnitId == null) return;

    final navigator = Navigator.of(context);
    final txController = context.read<TransactionsController>();
    final typeId = _calculateTypeId();
    final isActual = _selectedTab == 1;

    // حساب المعادل باللتر
    final units = txController.units.isNotEmpty
        ? txController.units
        : [
            {'id': 1, 'name': AppStrings.unitLiter, 'conversion_factor': 1.0},
            {'id': 2, 'name': AppStrings.unitDabba, 'conversion_factor': 20.0},
            {'id': 3, 'name': AppStrings.unitBarrel, 'conversion_factor': 200.0},
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
      referenceStationId: isActual ? (_selectedReferenceStationId ?? _selectedStationId) : null,
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
          backgroundColor: Color(0xFF15803D),
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
          // تصفية الحساب الذكي
          final accController = context.read<AccountsController>();
          final validAccounts = _getFilteredAccounts(accController.accounts);
          if (_selectedAccount == null || !validAccounts.contains(_selectedAccount)) {
            _selectedAccount = validAccounts.isNotEmpty ? validAccounts.first : null;
          }
        });
        _updateLiveBalances();
      },
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF102A43) : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF334155),
        ),
      ),
    );
  }
}
