import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_dialog.dart';
import '../../core/widgets/custom_modal_sheet.dart';
import '../../core/widgets/custom_text_field.dart';
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
    final nameController = TextEditingController(text: unit?['name']?.toString() ?? '');
    final factorController = TextEditingController(
      text: unit != null ? unit['conversion_factor'].toString() : '',
    );

    CustomModalSheet.show(
      context: context,
      title: unit == null ? 'إضافة وحدة' : 'تعديل وحدة',
      contentBuilder: (ctx, setModalState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomModalSheet.buildTextField(
              label: 'اسم الوحدة',
              controller: nameController,
            ),
            const SizedBox(height: 12),
            CustomModalSheet.buildTextField(
              label: 'معامل التحويل إلى لتر',
              controller: factorController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        );
      },
      onSave: (ctx) async {
        final name = nameController.text.trim();
        final factor = double.tryParse(factorController.text.trim()) ?? 1.0;
        if (name.isEmpty) return;

        final navigator = Navigator.of(ctx);
        final db = await DatabaseHelper.instance.database;
        if (unit == null) {
          await db.insert('units', {
            'name': name,
            'conversion_factor': factor,
            'is_base_unit': 0,
          });
        } else {
          await db.update(
            'units',
            {'name': name, 'conversion_factor': factor},
            where: 'id = ?',
            whereArgs: [unit['id']],
          );
        }
        navigator.pop();
        _loadUnits();
      },
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('دليل الوحدات والتحويلات'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('قائمة الوحدات المعتمدة', style: AppTextStyles.heading2),
                CustomButton(
                  text: 'إضافة وحدة',
                  icon: Icons.add,
                  onPressed: () => _openAddEditDialog(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : ListView.separated(
                      itemCount: _units.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final u = _units[index];
                        final isBase = (u['is_base_unit'] as int? ?? 0) == 1;

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border, width: 1),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(u['name'].toString(), style: AppTextStyles.heading3),
                                        if (isBase) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text('الوحدة الأساسية', style: AppTextStyles.caption),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'المعادل: ${u['conversion_factor']} لتر',
                                      style: AppTextStyles.bodySecondary,
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: const BorderSide(color: AppColors.border, width: 1),
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
                                        Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                                        SizedBox(width: 8),
                                        Text(AppStrings.edit, style: AppTextStyles.body),
                                      ],
                                    ),
                                  ),
                                  if (!isBase)
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline, size: 18, color: AppColors.dispenseRed),
                                          SizedBox(width: 8),
                                          Text(AppStrings.delete, style: TextStyle(color: AppColors.dispenseRed)),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
