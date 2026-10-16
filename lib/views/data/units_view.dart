import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/custom_dialog.dart';
import '../../core/widgets/custom_modal_sheet.dart';
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
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
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
