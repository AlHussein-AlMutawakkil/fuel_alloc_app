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
      title: station == null ? AppStrings.addStation : AppStrings.editStation,
      contentBuilder: (ctx, setModalState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomModalSheet.buildTextField(
              label: AppStrings.stationNameLabel,
              controller: nameController,
            ),
            const SizedBox(height: AppDimensions.spaceL),
            CustomModalSheet.buildTextField(
              label: AppStrings.locationCityLabel,
              controller: locationController,
            ),
            const SizedBox(height: AppDimensions.spaceL),
            CustomModalSheet.buildTextField(
              label: AppStrings.phoneNumber,
              controller: phoneController,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppDimensions.spaceL),
            CustomModalSheet.buildTextField(
              label: AppStrings.commissionRatePercentLabel,
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
      title: AppStrings.confirmExclamation,
      message: AppStrings.confirmDeleteStationMsg,
      confirmText: AppStrings.ok,
      cancelText: AppStrings.cancel,
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
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: AppTypography.sizeBody + 1,
                ),
                cursorColor: AppColors.textWhite,
                decoration: InputDecoration(
                  hintText: AppStrings.searchStationsHint,
                  hintStyle: TextStyle(
                    color: AppColors.textWhite.withOpacity(0.7),
                  ),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
                  });
                },
              )
            : const Text(AppStrings.stationsDirectory),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? AppIcons.close : AppIcons.search),
            tooltip: _isSearching ? AppStrings.closeSearch : AppStrings.search,
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
            icon: const Icon(AppIcons.add),
            tooltip: AppStrings.addStation,
            onPressed: () => _openAddEditDialog(),
          ),
        ],
      ),
      body: Padding(
        padding: AppDimensions.paddingScreen,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  AppStrings.approvedStationsList,
                  style: AppTypography.heading2,
                ),
                Text(
                  '${AppStrings.countPrefix}${filteredStations.length}',
                  style: AppTypography.captionBold,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceL),
            Expanded(
              child: _isLoading
                  ? const AppLoadingIndicator()
                  : filteredStations.isEmpty
                      ? const EmptyStateWidget(
                          icon: AppIcons.gasStationOutlined,
                          title: AppStrings.noStationsRecordedYet,
                        )
                      : ListView.separated(
                          itemCount: filteredStations.length,
                          separatorBuilder: (_, __) => const SizedBox(
                            height: AppDimensions.spaceM,
                          ),
                          itemBuilder: (context, index) {
                            final s = filteredStations[index];
                            return Material(
                              color: AppColors.surface,
                              borderRadius: AppDimensions.borderRadiusM,
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
                                borderRadius: AppDimensions.borderRadiusM,
                                child: Container(
                                  padding: AppDimensions.paddingInput,
                                  decoration: BoxDecoration(
                                    borderRadius: AppDimensions.borderRadiusM,
                                    border: Border.all(
                                      color: AppColors.border,
                                      width: AppDimensions.borderWidthThin,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              s['name'].toString(),
                                              style: AppTypography.heading3,
                                            ),
                                            const SizedBox(
                                              height: AppDimensions.spaceXS,
                                            ),
                                            Row(
                                              children: [
                                                if (s['location'] != null &&
                                                    s['location']
                                                        .toString()
                                                        .isNotEmpty) ...[
                                                  const Icon(
                                                    AppIcons.location,
                                                    size:
                                                        AppDimensions.iconMini,
                                                    color: AppColors.textMuted,
                                                  ),
                                                  const SizedBox(
                                                    width:
                                                        AppDimensions.spaceXS,
                                                  ),
                                                  Text(
                                                    s['location'].toString(),
                                                    style:
                                                        AppTypography.caption,
                                                  ),
                                                  const SizedBox(
                                                    width: AppDimensions.spaceL,
                                                  ),
                                                ],
                                                Text(
                                                  '${AppStrings.commissionRateLabel}${s['default_commission_rate']}%',
                                                  style: AppTypography.caption
                                                      .copyWith(
                                                    color:
                                                        AppColors.supplyGreen,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        AppIcons.chevronRight,
                                        size: AppDimensions.iconMini,
                                        color: AppColors.textMuted,
                                      ),
                                      const SizedBox(
                                        width: AppDimensions.spaceXS,
                                      ),
                                      PopupMenuButton<String>(
                                        icon: const Icon(
                                          AppIcons.moreVert,
                                          color: AppColors.textSecondary,
                                          size: AppDimensions.iconMedium,
                                        ),
                                        color: AppColors.surface,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius:
                                              AppDimensions.borderRadiusM,
                                          side: BorderSide(
                                            color: AppColors.border,
                                            width:
                                                AppDimensions.borderWidthThin,
                                          ),
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
                                                  AppIcons.tabQuota,
                                                  size:
                                                      AppDimensions.iconRegular,
                                                  color: AppColors.primary,
                                                ),
                                                SizedBox(
                                                  width: AppDimensions.spaceM,
                                                ),
                                                Text(
                                                  AppStrings
                                                      .stationStatementTitle,
                                                  style: AppTypography.body,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  AppIcons.edit,
                                                  size:
                                                      AppDimensions.iconRegular,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                                SizedBox(
                                                  width: AppDimensions.spaceM,
                                                ),
                                                Text(
                                                  AppStrings.edit,
                                                  style: AppTypography.body,
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
                                                  size:
                                                      AppDimensions.iconRegular,
                                                  color: AppColors.dispenseRed,
                                                ),
                                                SizedBox(
                                                  width: AppDimensions.spaceM,
                                                ),
                                                Text(
                                                  AppStrings.delete,
                                                  style: TextStyle(
                                                    color:
                                                        AppColors.dispenseRed,
                                                  ),
                                                ),
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
