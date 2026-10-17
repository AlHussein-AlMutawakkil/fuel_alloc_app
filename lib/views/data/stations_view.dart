import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_dialog.dart';
import '../../core/widgets/custom_modal_sheet.dart';
import '../../data/local/database_helper.dart';
import '../../models/station_model.dart';
import '../accounts/station_transactions_view.dart';

/// واجهة إدارة المحطات
class StationsView extends StatefulWidget {
  const StationsView({super.key});

  @override
  State<StationsView> createState() => _StationsViewState();
}

class _StationsViewState extends State<StationsView> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _stations = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    final nameController =
        TextEditingController(text: station?['name']?.toString() ?? '');
    final locationController =
        TextEditingController(text: station?['location']?.toString() ?? '');
    final phoneController =
        TextEditingController(text: station?['phone_number']?.toString() ?? '');
    final commissionController = TextEditingController(
      text: station != null
          ? station['default_commission_rate'].toString()
          : '2.0',
    );

    CustomModalSheet.show(
      context: context,
      title: station == null ? 'إضافة محطة' : 'تعديل محطة',
      contentBuilder: (ctx, setModalState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomModalSheet.buildTextField(
              label: 'اسم المحطة',
              controller: nameController,
            ),
            const SizedBox(height: 12),
            CustomModalSheet.buildTextField(
              label: 'الموقع / المدينة',
              controller: locationController,
            ),
            const SizedBox(height: 12),
            CustomModalSheet.buildTextField(
              label: 'رقم الهاتف',
              controller: phoneController,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            CustomModalSheet.buildTextField(
              label: 'نسبة عمولة التهوية (%)',
              controller: commissionController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        );
      },
      onSave: (ctx) async {
        final name = nameController.text.trim();
        if (name.isEmpty) return;

        final navigator = Navigator.of(ctx);
        final commRate =
            double.tryParse(commissionController.text.trim()) ?? 2.0;
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
        navigator.pop();
        _loadStations();
      },
    );
  }

  void _deleteStation(int id) async {
    final confirm = await CustomDialog.showConfirmation(
      context: context,
      title: 'تأكيد!',
      message: 'هل تريد حذف هذه المحطة؟',
      confirmText: 'حسناً',
      cancelText: 'إلغاء',
      isDanger: true,
    );
    if (confirm) {
      final db = await DatabaseHelper.instance.database;
      await db.update('stations', {'is_active': 0},
          where: 'id = ?', whereArgs: [id]);
      _loadStations();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredStations = _stations.where((s) {
      if (_searchQuery.isEmpty) return true;
      final name = (s['name'] ?? '').toString().toLowerCase();
      final loc = (s['location'] ?? '').toString().toLowerCase();
      final phone = (s['phone_number'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery) ||
          loc.contains(_searchQuery) ||
          phone.contains(_searchQuery);
    }).toList();

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
                  hintText: 'بحث في المحطات أو الموقع أو الهاتف...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
                  });
                },
              )
            : const Text('دليل محطات الوقود'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            tooltip: _isSearching ? 'إغلاق البحث' : 'بحث',
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'إضافة محطة',
            onPressed: () => _openAddEditDialog(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('قائمة المحطات المعتمدة',
                    style: AppTextStyles.heading2),
                Text(
                  'العدد: ${filteredStations.length}',
                  style: AppTextStyles.caption
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary))
                  : filteredStations.isEmpty
                      ? const Center(
                          child: Text('لا توجد محطات مسجلة بعد',
                              style: AppTextStyles.bodySecondary))
                      : ListView.separated(
                          itemCount: filteredStations.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final s = filteredStations[index];
                            return Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context)
                                      .push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              StationTransactionsView(
                                            station: StationModel.fromMap(s),
                                          ),
                                        ),
                                      )
                                      .then((_) => _loadStations());
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: AppColors.border, width: 1),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(s['name'].toString(),
                                                style: AppTextStyles.heading3),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                if (s['location'] != null &&
                                                    s['location']
                                                        .toString()
                                                        .isNotEmpty) ...[
                                                  const Icon(
                                                      Icons
                                                          .location_on_outlined,
                                                      size: 14,
                                                      color:
                                                          AppColors.textMuted),
                                                  const SizedBox(width: 4),
                                                  Text(s['location'].toString(),
                                                      style: AppTextStyles
                                                          .caption),
                                                  const SizedBox(width: 12),
                                                ],
                                                Text(
                                                  'عمولة التهوية: ${s['default_commission_rate']}%',
                                                  style: AppTextStyles.caption
                                                      .copyWith(
                                                          color: AppColors
                                                              .supplyGreen),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.arrow_forward_ios,
                                          size: 14, color: AppColors.textMuted),
                                      const SizedBox(width: 4),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert,
                                            color: AppColors.textSecondary,
                                            size: 20),
                                        color: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          side: const BorderSide(
                                              color: AppColors.border,
                                              width: 1),
                                        ),
                                        onSelected: (action) {
                                          if (action == 'transactions') {
                                            Navigator.of(context)
                                                .push(
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        StationTransactionsView(
                                                      station:
                                                          StationModel.fromMap(
                                                              s),
                                                    ),
                                                  ),
                                                )
                                                .then((_) => _loadStations());
                                          } else if (action == 'edit') {
                                            _openAddEditDialog(station: s);
                                          } else if (action == 'delete') {
                                            _deleteStation(s['id'] as int);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'transactions',
                                            child: Row(
                                              children: [
                                                Icon(
                                                    Icons.receipt_long_outlined,
                                                    size: 18,
                                                    color: AppColors.primary),
                                                SizedBox(width: 8),
                                                Text('كشف حساب المحطة',
                                                    style: AppTextStyles.body),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit_outlined,
                                                    size: 18,
                                                    color: AppColors
                                                        .textSecondary),
                                                SizedBox(width: 8),
                                                Text(AppStrings.edit,
                                                    style: AppTextStyles.body),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete_outline,
                                                    size: 18,
                                                    color:
                                                        AppColors.dispenseRed),
                                                SizedBox(width: 8),
                                                Text(AppStrings.delete,
                                                    style: TextStyle(
                                                        color: AppColors
                                                            .dispenseRed)),
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
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
