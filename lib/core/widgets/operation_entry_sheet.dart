import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/accounts_controller.dart';
import '../../controllers/transactions_controller.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../models/account_model.dart';
import '../../models/transaction_model.dart';

/// واجهة تسجيل وتعديل القيود والعمليات (مكون مشترك لكافة شاشات التطبيق)
/// مطابقة بنسبة 100% للتصميم المعتمد في صورة تسجيل القيد
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

  /// فتح نافذة تسجيل القيد بتنسيق نافذة منبثقة مطابقة للصورة المعتمدة بنسبة 100%
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
  // التبويب العلوي: 0: اعتماد, 1: فعلي, 2: نسبة
  late int _selectedTab;

  // اتجاه الحركة: 0: توريد (له), 1: صرف (عليه)
  late int _selectedDirection;

  // الحساب المختار
  AccountModel? _selectedAccount;

  // المحطة المنفذة
  int? _selectedStationId;

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
      // تحديد التبويب والاتجاه بناءً على typeId
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
      _selectedFuelTypeId = tx.fuelTypeId;
      _selectedUnitId = tx.unitId;
      _quantityController.text = tx.enteredQuantity.toString();
      _dateController.text = tx.transactionDate.replaceAll('-', '/');
      _statementController.text = tx.notes ?? '';
      _referenceNumberController.text = tx.transactionNumber ?? '';
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

      // إذا لم يكن الحساب محدداً مسبقاً، محاولة تعيينه من القائمة
      if (_selectedAccount == null && widget.editTransaction?.accountId != null) {
        final matches = accController.accounts.where(
          (a) => a.id == widget.editTransaction!.accountId,
        );
        if (matches.isNotEmpty) {
          setState(() {
            _selectedAccount = matches.first;
          });
        }
      }

      if (_selectedFuelTypeId == null && txController.fuelTypes.isNotEmpty) {
        setState(() {
          _selectedFuelTypeId = txController.fuelTypes.first['id'] as int?;
        });
      }
      if (_selectedUnitId == null && txController.units.isNotEmpty) {
        setState(() {
          _selectedUnitId = txController.units.first['id'] as int?;
        });
      }
      if (_selectedStationId == null && txController.stations.isNotEmpty) {
        setState(() {
          _selectedStationId = txController.stations.first['id'] as int?;
        });
      }
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

  // عنوان النافذة العلوي المطابق للصورة
  String _getTitle() {
    if (_isEdit) {
      return 'تعديل قيد';
    }
    if (_selectedTab == 2) {
      return 'تسجيل قيد (نسبة)';
    }
    return _selectedDirection == 0 ? 'تسجيل قيد (له)' : 'تسجيل قيد (عليه)';
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
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
                      // زر إغلاق X على اليسار (Child 0 في RTL يظهر يميناً، لذا نضع مساحة فارغة يميناً وX يساراً)
                      const SizedBox(width: 32),
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
                        icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 2. التبويبات الثلاثة العلوية (مطابقة للصورة 100%: اعتماد / فعلي / نسبة)
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
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

                  // 3. زرا الاتجاه (↓ توريد / ↑ صرف) - تظهران في الاعتماد والفعلي
                  if (_selectedTab != 2) ...[
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                      ),
                      child: Row(
                        children: [
                          // زر توريد (يمين في RTL) - أخضر مطابق لـ "له (دائن)" في الصورة
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedDirection = 0;
                                });
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _selectedDirection == 0
                                      ? const Color(0xFF15803D)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
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
                          // زر صرف (يسار في RTL) - أحمر مطابق لـ "عليه (مدين)" في الصورة
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedDirection = 1;
                                });
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _selectedDirection == 1
                                      ? const Color(0xFFB91C1C)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
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

                  // 4. حقل الحساب (أيقونة شخص يميناً وسهم منسدل يساراً مطابق للصورة)
                  _buildFieldLabel('الحساب'),
                  InkWell(
                    onTap: () => _openAccountPicker(accController.accounts),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
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
                          const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B), size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 5. صف: الكمية (يميناً بدل المبلغ) و الصنف (يساراً بدل العملة)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // الكمية على اليمين (flex: 6) مطابقة لحقل المبلغ في الصورة
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('الكمية'),
                            Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                              ),
                              child: Row(
                                children: [
                                  // إدخال الرقم
                                  Expanded(
                                    child: TextField(
                                      controller: _quantityController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                                  // الوحدة بدل اختصار العملة داخل الحقل
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
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          right: BorderSide(color: Color(0xFFCBD5E1), width: 1),
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

                      // الصنف على اليسار (flex: 4) مطابق لحقل العملة في الصورة
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('الصنف'),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
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
                                          fontSize: 14,
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

                  // عرض المعادل باللتر إذا اختيرت وحدة أخرى
                  if (_selectedUnitId != 1 && calculatedLiters > 0) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        'المعادل: ${AppFormatters.formatQuantity(calculatedLiters)} لتر',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // 6. حقل المحطة (يظهر ومفعل في الفعلي فقط)
                  if (_selectedTab == 1) ...[
                    _buildFieldLabel('المحطة'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          isExpanded: true,
                          value: _selectedStationId,
                          hint: const Text('اختر المحطة', style: TextStyle(color: Color(0xFF94A3B8))),
                          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B), size: 18),
                          items: txController.stations.map((st) {
                            return DropdownMenuItem<int?>(
                              value: st['id'] as int,
                              child: Row(
                                children: [
                                  const Icon(Icons.local_gas_station_outlined, size: 16, color: Color(0xFF64748B)),
                                  const SizedBox(width: 6),
                                  Text(st['name'] as String, style: const TextStyle(fontSize: 14)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedStationId = val;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 7. حقل التاريخ (أيقونة التقويم وسهم منسدل مطابق للصورة)
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
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF64748B)),
                              const SizedBox(width: 8),
                              Text(
                                _dateController.text,
                                style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                              ),
                            ],
                          ),
                          const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 8. حقل البيان (بدون نصوص أمثلة، نظيف ومطابق للصورة)
                  _buildFieldLabel('البيان'),
                  Container(
                    height: 75,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                    ),
                    child: TextField(
                      controller: _statementController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 9. حقل رقم المرجع (مع أيقونة # مطابقة تماماً للصورة)
                  _buildFieldLabel('رقم المرجع'),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: Icon(Icons.tag, color: Color(0xFF64748B), size: 20),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _referenceNumberController,
                            style: const TextStyle(fontSize: 14),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 10. شريط الأزرار السفلي (حفظ الأخضر يميناً وإلغاء الأبيض يساراً في RTL)
                  Row(
                    children: [
                      // زر حفظ الأخضر الموحد على اليمين
                      Expanded(
                        flex: 5,
                        child: InkWell(
                          onTap: _saveOperation,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              color: const Color(0xFF15803D),
                              borderRadius: BorderRadius.circular(8),
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
                      const SizedBox(width: 10),

                      // زر إلغاء الأبيض على اليسار
                      Expanded(
                        flex: 3,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
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

  // نافذة اختيار الحساب بأسلوب منسدل سريع
  void _openAccountPicker(List<AccountModel> accounts) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                      const Text(
                        'اختر الحساب',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                      hintText: 'بحث عن حساب...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
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
                            child: Text('لا توجد نتائج', style: TextStyle(color: Color(0xFF94A3B8))),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, idx) {
                              final acc = filtered[idx];
                              return ListTile(
                                leading: const Icon(Icons.person_outline, color: Color(0xFF64748B)),
                                title: Text(acc.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                  acc.accountType == AccountType.supplier ? 'مورد' : 'عميل مستفيد',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                                onTap: () {
                                  setState(() {
                                    _selectedAccount = acc;
                                  });
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

    // حساب المعادل
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

    final tx = TransactionModel(
      id: widget.editTransaction?.id,
      transactionNumber: _referenceNumberController.text.trim().isEmpty
          ? null
          : _referenceNumberController.text.trim(),
      transactionDate: _dateController.text.trim().replaceAll('/', '-'),
      typeId: typeId,
      accountId: _selectedAccount?.id,
      stationId: isActual ? _selectedStationId : null,
      referenceStationId: isActual ? _selectedStationId : null,
      fuelTypeId: _selectedFuelTypeId,
      unitId: _selectedUnitId!,
      enteredQuantity: qty,
      baseQuantityLiters: baseLiters,
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
        });
      },
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF102A43) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
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
      padding: const EdgeInsets.only(bottom: 5.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF334155),
        ),
      ),
    );
  }
}
