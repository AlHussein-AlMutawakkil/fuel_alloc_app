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
      title: unit == null ? AppStrings.addUnit : AppStrings.editUnit,
      contentBuilder: (ctx, setModalState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomModalSheet.buildTextField(
              label: AppStrings.unitNameLabel,
              controller: nameController,
            ),
            const SizedBox(height: AppDimensions.spaceL),
            CustomModalSheet.buildTextField(
              label: AppStrings.conversionFactorLabel,
              controller: factorController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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
      title: AppStrings.confirmExclamation,
      message: AppStrings.confirmDeleteUnitMsg,
      confirmText: AppStrings.ok,
      cancelText: AppStrings.cancel,
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
      appBar: OneUiAppBar(
        title: AppStrings.unitsDirectory,
        actions: [
          IconButton(
            icon: const Icon(AppIcons.addRounded),
            tooltip: AppStrings.addUnit,
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
                        AppStrings.approvedUnitsList,
                        style: TextStyle(
                          fontSize: AppTypography.sizeBodySecondary,
                          fontWeight: AppTypography.weightSemiBold,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      Text(
                        '${AppStrings.countPrefix}${_units.length}',
                        style: const TextStyle(
                          fontSize: AppTypography.sizeCaption,
                          fontWeight: AppTypography.weightMedium,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_units.isEmpty)
                  const OneUiCard(
                    children: [
                      EmptyStateWidget(
                        icon: AppIcons.unitOutlined,
                        title: AppStrings.noUnitsRecordedYet,
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
                                ? AppColors.supplyLight
                                : AppColors.chipBackground,
                            borderRadius: AppDimensions.borderRadiusL,
                          ),
                          child: Icon(
                            AppIcons.unitRounded,
                            color: isBase
                                ? AppColors.supplyGreen
                                : AppColors.primary,
                            size: AppDimensions.iconMedium,
                          ),
                        ),
                        title: u['name'].toString(),
                        subtitle:
                            '${AppStrings.equivalentPrefix} ${u['conversion_factor']} ${AppStrings.unitLiter}',
                        onTap: () => _openAddEditDialog(unit: u),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isBase)
                              Container(
                                margin: const EdgeInsets.only(
                                  left: AppDimensions.spaceS,
                                ),
                                padding: AppDimensions.paddingTag,
                                decoration: const BoxDecoration(
                                  color: AppColors.supplyLight,
                                  borderRadius: AppDimensions.borderRadiusS,
                                ),
                                child: const Text(
                                  AppStrings.baseUnitBadge,
                                  style: TextStyle(
                                    fontSize: AppTypography.sizeSmall,
                                    fontWeight: AppTypography.weightBold,
                                    color: AppColors.supplyGreen,
                                  ),
                                ),
                              ),
                            PopupMenuButton<String>(
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
                                if (!isBase)
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
