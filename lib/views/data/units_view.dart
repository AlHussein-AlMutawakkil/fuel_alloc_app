import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/custom_dialog.dart';
import '../../core/widgets/one_ui_card.dart';
import '../../data/local/database_helper.dart';

/// واجهة إدارة الوحدات (الوحدات ومعاملات التحويل للتر)
class UnitsView extends StatefulWidget {
  const UnitsView({super.key});

  @override
  State<UnitsView> createState() => _UnitsViewState();
}

class _UnitsViewState extends State<UnitsView> {
  List<Map<String, dynamic>> _units = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    final db = await DatabaseHelper.instance.database;
    final data = await db.query('units', orderBy: 'conversion_factor ASC');
    setState(() {
      _units = data;
      _isLoading = false;
    });
  }

  void _openAddEditDialog({Map<String, dynamic>? unit}) {
    final nameController =
        TextEditingController(text: unit?['name']?.toString() ?? '');
    final factorController = TextEditingController(
      text: unit != null ? unit['conversion_factor'].toString() : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setModalState) {
            return Center(
              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
                      bottom: MediaQuery.of(dialogCtx).viewInsets.bottom,
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. رأس النافذة المنبثقة: العنوان وزر الإغلاق
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  unit == null ? 'إضافة وحدة' : 'تعديل وحدة',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Color(0xFF64748B),
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                onPressed: () => Navigator.of(dialogCtx).pop(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // 2. حقل اسم الوحدة مع حدود ناعمة وبدون أي نصوص إضافية
                          _buildMinimalInputField(
                            label: 'اسم الوحدة',
                            controller: nameController,
                          ),
                          const SizedBox(height: 14),

                          // 3. حقل معامل التحويل مع حدود ناعمة وبدون أي نصوص إضافية
                          _buildMinimalInputField(
                            label: 'معامل التحويل إلى لتر',
                            controller: factorController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 4. زري الإلغاء والتأكيد المتطابقين مع الصورة
                          Row(
                            children: [
                              // زر الإلغاء (يظهر يميناً في RTL)
                              Expanded(
                                child: InkWell(
                                  onTap: () => Navigator.of(dialogCtx).pop(),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFf8f8f8),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      'إلغاء',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // زر التأكيد (يظهر يساراً في RTL)
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final name = nameController.text.trim();
                                    final factor = double.tryParse(
                                            factorController.text.trim()) ??
                                        1.0;
                                    if (name.isEmpty) return;

                                    final navigator = Navigator.of(dialogCtx);
                                    final db =
                                        await DatabaseHelper.instance.database;
                                    if (unit == null) {
                                      await db.insert('units', {
                                        'name': name,
                                        'conversion_factor': factor,
                                        'is_base_unit': 0,
                                      });
                                    } else {
                                      await db.update(
                                        'units',
                                        {
                                          'name': name,
                                          'conversion_factor': factor
                                        },
                                        where: 'id = ?',
                                        whereArgs: [unit['id']],
                                      );
                                    }
                                    navigator.pop();
                                    _loadUnits();
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E1E1E),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      'تأكيد',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
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
          },
        );
      },
    );
  }

  Widget _buildMinimalInputField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFf8f8f8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1.0,
            ),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0F172A),
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  void _deleteUnit(int id) async {
    final confirm = await CustomDialog.showConfirmation(
      context: context,
      title: 'تأكيد!',
      message: 'هل تريد حذف هذه الوحدة؟',
      confirmText: 'حسناً',
      cancelText: 'إلغاء',
      isDanger: true,
    );
    if (confirm) {
      final db = await DatabaseHelper.instance.database;
      await db.delete('units', where: 'id = ?', whereArgs: [id]);
      _loadUnits();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f8f8),
      appBar: OneUiAppBar(
        title: 'دليل الوحدات',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'إضافة وحدة',
            onPressed: () => _openAddEditDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 6.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'قائمة الوحدات المعتمدة',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        'العدد: ${_units.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_units.isEmpty)
                  const OneUiCard(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: 36.0, horizontal: 20.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.straighten_outlined,
                                size: 40,
                                color: Color(0xFF94A3B8),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'لا توجد وحدات مسجلة بعد',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  OneUiCard(
                    children: _units.map((u) {
                      final isBase = (u['is_base_unit'] as int? ?? 0) == 1;
                      return OneUiTile(
                        leading: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isBase
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.straighten_rounded,
                            color: isBase
                                ? const Color(0xFF15803D)
                                : const Color(0xFF102A43),
                            size: 20,
                          ),
                        ),
                        title: u['name'].toString(),
                        subtitle: 'المعادل: ${u['conversion_factor']} لتر',
                        onTap: () => _openAddEditDialog(unit: u),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isBase)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'أساسية',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                              ),
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert,
                                color: Color(0xFF94A3B8),
                                size: 20,
                              ),
                              color: Colors.white,
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              onSelected: (action) {
                                if (action == 'edit') {
                                  _openAddEditDialog(unit: u);
                                } else if (action == 'delete' && !isBase) {
                                  _deleteUnit(u['id'] as int);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined,
                                          size: 18, color: Color(0xFF475569)),
                                      SizedBox(width: 8),
                                      Text(AppStrings.edit,
                                          style: TextStyle(fontSize: 14)),
                                    ],
                                  ),
                                ),
                                if (!isBase)
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline,
                                            size: 18, color: Color(0xFFB91C1C)),
                                        SizedBox(width: 8),
                                        Text(AppStrings.delete,
                                            style: TextStyle(
                                                color: Color(0xFFB91C1C),
                                                fontSize: 14)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
    );
  }
}
