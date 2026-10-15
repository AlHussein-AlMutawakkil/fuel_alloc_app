import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../data/local/database_helper.dart';

/// واجهة إدارة المحطات
class StationsView extends StatefulWidget {
  const StationsView({super.key});

  @override
  State<StationsView> createState() => _StationsViewState();
}

class _StationsViewState extends State<StationsView> {
  List<Map<String, dynamic>> _stations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    final db = await DatabaseHelper.instance.database;
    final data = await db.query(
      'stations',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    setState(() {
      _stations = data;
      _isLoading = false;
    });
  }

  void _openAddEditDialog({Map<String, dynamic>? station}) {
    final nameController = TextEditingController(text: station?['name']?.toString() ?? '');
    final locationController = TextEditingController(text: station?['location']?.toString() ?? '');
    final phoneController = TextEditingController(text: station?['phone_number']?.toString() ?? '');
    final commissionController = TextEditingController(
      text: station != null
          ? station['default_commission_rate'].toString()
          : '2.0',
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        title: Text(
          station == null ? 'إضافة محطة جديدة' : 'تعديل بيانات المحطة',
          style: AppTextStyles.heading2,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                label: 'اسم المحطة',
                controller: nameController,
                hint: 'مثال: محطة تعز المركزية...',
              ),
              const SizedBox(height: 10),
              CustomTextField(
                label: 'الموقع / المدينة',
                controller: locationController,
                hint: 'مثال: تعز - الحوبان...',
              ),
              const SizedBox(height: 10),
              CustomTextField(
                label: 'رقم الهاتف',
                controller: phoneController,
                keyboardType: TextInputType.phone,
                hint: 'هاتف المسؤول في المحطة...',
              ),
              const SizedBox(height: 10),
              CustomTextField(
                label: 'نسبة عمولة التهوية (%)',
                controller: commissionController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                hint: 'النسبة المئوية (افتراضياً 2%)',
              ),
            ],
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: AppStrings.cancel,
                  variant: ButtonVariant.secondary,
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomButton(
                  text: AppStrings.save,
                  variant: ButtonVariant.primary,
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    final navigator = Navigator.of(dialogCtx);
                    final commRate = double.tryParse(commissionController.text.trim()) ?? 2.0;
                    final db = await DatabaseHelper.instance.database;

                    if (station == null) {
                      await db.insert('stations', {
                        'name': name,
                        'location': locationController.text.trim(),
                        'phone_number': phoneController.text.trim(),
                        'default_commission_rate': commRate,
                        'is_active': 1,
                        'created_at': DateTime.now().toIso8601String(),
                      });
                    } else {
                      await db.update(
                        'stations',
                        {
                          'name': name,
                          'location': locationController.text.trim(),
                          'phone_number': phoneController.text.trim(),
                          'default_commission_rate': commRate,
                        },
                        where: 'id = ?',
                        whereArgs: [station['id']],
                      );
                    }
                    if (mounted) {
                      navigator.pop();
                      _loadStations();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _deleteStation(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('stations', {'is_active': 0}, where: 'id = ?', whereArgs: [id]);
    _loadStations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('دليل محطات الوقود'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('قائمة المحطات المعتمدة', style: AppTextStyles.heading2),
                CustomButton(
                  text: 'إضافة محطة',
                  icon: Icons.add,
                  onPressed: () => _openAddEditDialog(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _stations.isEmpty
                      ? const Center(child: Text('لا توجد محطات مسجلة بعد', style: AppTextStyles.bodySecondary))
                      : ListView.separated(
                          itemCount: _stations.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final s = _stations[index];
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
                                        Text(s['name'].toString(), style: AppTextStyles.heading3),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            if (s['location'] != null && s['location'].toString().isNotEmpty) ...[
                                              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                                              const SizedBox(width: 4),
                                              Text(s['location'].toString(), style: AppTextStyles.caption),
                                              const SizedBox(width: 12),
                                            ],
                                            Text(
                                              'عمولة التهوية: ${s['default_commission_rate']}%',
                                              style: AppTextStyles.caption.copyWith(color: AppColors.supplyGreen),
                                            ),
                                          ],
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
                                        _openAddEditDialog(station: s);
                                      } else if (action == 'delete') {
                                        _deleteStation(s['id'] as int);
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
