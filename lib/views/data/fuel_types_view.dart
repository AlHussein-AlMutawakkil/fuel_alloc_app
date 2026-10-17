import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/custom_dialog.dart';
import '../../core/widgets/custom_modal_sheet.dart';
import '../../core/widgets/one_ui_card.dart';
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
    final nameController =
        TextEditingController(text: item?['name']?.toString() ?? '');

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
      await db.update('fuel_types', {'is_active': 0},
          where: 'id = ?', whereArgs: [id]);
      _loadFuelTypes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f8f8),
      appBar: OneUiAppBar(
        title: 'دليل أصناف الوقود',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'إضافة صنف',
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
                        'الأصناف المسجلة',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        'العدد: ${_fuelTypes.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_fuelTypes.isEmpty)
                  const OneUiCard(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: 36.0, horizontal: 20.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.local_gas_station_outlined,
                                size: 40,
                                color: Color(0xFF94A3B8),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'لا توجد أصناف مسجلة بعد',
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
                    children: _fuelTypes.map((f) {
                      return OneUiTile(
                        leading: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.local_gas_station_rounded,
                            color: Color(0xFF102A43),
                            size: 20,
                          ),
                        ),
                        title: f['name'].toString(),
                        onTap: () => _openAddEditDialog(item: f),
                        trailing: PopupMenuButton<String>(
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
                                  Icon(Icons.edit_outlined,
                                      size: 18, color: Color(0xFF475569)),
                                  SizedBox(width: 8),
                                  Text(AppStrings.edit,
                                      style: TextStyle(fontSize: 14)),
                                ],
                              ),
                            ),
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
                      );
                    }).toList(),
                  ),
              ],
            ),
    );
  }
}
