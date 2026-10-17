import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/custom_dialog.dart';
import '../../core/widgets/custom_modal_sheet.dart';
import '../../core/widgets/empty_state_widget.dart';
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
      title: item == null ? AppStrings.addFuelType : AppStrings.editFuelType,
      contentBuilder: (ctx, setModalState) {
        return CustomModalSheet.buildTextField(
          label: AppStrings.fuelTypeNameLabel,
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
      title: AppStrings.confirmExclamation,
      message: AppStrings.confirmDeleteFuelTypeMsg,
      confirmText: AppStrings.ok,
      cancelText: AppStrings.cancel,
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
      backgroundColor: AppColors.scaffoldBackground,
      appBar: OneUiAppBar(
        title: AppStrings.fuelTypesDirectory,
        actions: [
          IconButton(
            icon: const Icon(AppIcons.addRounded),
            tooltip: AppStrings.addFuelType,
            onPressed: () => _openAddEditDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const AppLoadingIndicator()
          : ListView(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.spaceL,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space2XL,
                    vertical: AppDimensions.spaceS,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        AppStrings.registeredFuelTypes,
                        style: TextStyle(
                          fontSize: AppTypography.sizeBodySecondary,
                          fontWeight: AppTypography.weightSemiBold,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      Text(
                        '${AppStrings.countPrefix}${_fuelTypes.length}',
                        style: const TextStyle(
                          fontSize: AppTypography.sizeCaption,
                          fontWeight: AppTypography.weightMedium,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_fuelTypes.isEmpty)
                  const OneUiCard(
                    children: [
                      EmptyStateWidget(
                        icon: AppIcons.gasStationOutlined,
                        title: AppStrings.noFuelTypesRecordedYet,
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
                          decoration: const BoxDecoration(
                            color: AppColors.chipBackground,
                            borderRadius: AppDimensions.borderRadiusL,
                          ),
                          child: const Icon(
                            AppIcons.gasStationRounded,
                            color: AppColors.primary,
                            size: AppDimensions.iconMedium,
                          ),
                        ),
                        title: f['name'].toString(),
                        onTap: () => _openAddEditDialog(item: f),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(
                            AppIcons.moreVert,
                            color: AppColors.textMuted,
                            size: AppDimensions.iconMedium,
                          ),
                          color: AppColors.surface,
                          elevation: 3,
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppDimensions.borderRadiusXL,
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
                                  Icon(
                                    AppIcons.edit,
                                    size: AppDimensions.iconRegular,
                                    color: AppColors.textSecondary,
                                  ),
                                  SizedBox(width: AppDimensions.spaceM),
                                  Text(
                                    AppStrings.edit,
                                    style: TextStyle(
                                      fontSize: AppTypography.sizeBody,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    AppIcons.delete,
                                    size: AppDimensions.iconRegular,
                                    color: AppColors.dispenseRed,
                                  ),
                                  SizedBox(width: AppDimensions.spaceM),
                                  Text(
                                    AppStrings.delete,
                                    style: TextStyle(
                                      color: AppColors.dispenseRed,
                                      fontSize: AppTypography.sizeBody,
                                    ),
                                  ),
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
