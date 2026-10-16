import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_dialog.dart';
import '../../core/widgets/custom_modal_sheet.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../data/local/database_helper.dart';

/// واجهة إدارة الأصناف (المشتقات النفطية: بترول، ديزل...)
class FuelTypesView extends StatefulWidget {
  const FuelTypesView({super.key});

  @override
  State<FuelTypesView> createState() => _FuelTypesViewState();
}

class _FuelTypesViewState extends State<FuelTypesView> {
  List<Map<String, dynamic>> _fuelTypes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFuelTypes();
  }

  Future<void> _loadFuelTypes() async {
    final db = await DatabaseHelper.instance.database;
    final data = await db.query(
      'fuel_types',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'id ASC',
    );
    setState(() {
      _fuelTypes = data;
      _isLoading = false;
    });
  }

  void _openAddEditDialog({Map<String, dynamic>? item}) {
    final nameController = TextEditingController(text: item?['name']?.toString() ?? '');

    CustomModalSheet.show(
      context: context,
      title: item == null ? 'إضافة صنف' : 'تعديل صنف',
      contentBuilder: (ctx, setModalState) {
        return CustomModalSheet.buildTextField(
          label: 'اسم الصنف',
          controller: nameController,
        );
      },
      onSave: (ctx) async {
        final name = nameController.text.trim();
        if (name.isEmpty) return;

        final navigator = Navigator.of(ctx);
        final db = await DatabaseHelper.instance.database;
        if (item == null) {
          await db.insert('fuel_types', {'name': name, 'is_active': 1});
        } else {
          await db.update(
            'fuel_types',
            {'name': name},
            where: 'id = ?',
            whereArgs: [item['id']],
          );
        }
        navigator.pop();
        _loadFuelTypes();
      },
    );
  }

  void _deleteFuelType(int id) async {
    final confirm = await CustomDialog.showConfirmation(
      context: context,
      title: 'تأكيد!',
      message: 'هل تريد حذف هذا الصنف؟',
      confirmText: 'حسناً',
      cancelText: 'إلغاء',
      isDanger: true,
    );
    if (confirm) {
      final db = await DatabaseHelper.instance.database;
      await db.update('fuel_types', {'is_active': 0}, where: 'id = ?', whereArgs: [id]);
      _loadFuelTypes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('دليل أصناف الوقود'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الأصناف المسجلة', style: AppTextStyles.heading2),
                CustomButton(
                  text: 'إضافة صنف',
                  icon: Icons.add,
                  onPressed: () => _openAddEditDialog(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _fuelTypes.isEmpty
                      ? const Center(child: Text('لا توجد أصناف مسجلة بعد', style: AppTextStyles.bodySecondary))
                      : ListView.separated(
                          itemCount: _fuelTypes.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final f = _fuelTypes[index];
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border, width: 1),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.local_gas_station_outlined, color: AppColors.primary, size: 22),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(f['name'].toString(), style: AppTextStyles.heading3),
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
                                        _openAddEditDialog(item: f);
                                      } else if (action == 'delete') {
                                        _deleteFuelType(f['id'] as int);
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
