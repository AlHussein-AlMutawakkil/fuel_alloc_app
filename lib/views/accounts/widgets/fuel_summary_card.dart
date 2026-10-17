import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/formatters.dart';

/// عنصر إحصائي في الصندوق الرمادي السفلي للكارد
class FuelCardMetric {
  final double value;
  final String label;
  final Color? valueColor;

  const FuelCardMetric({
    required this.value,
    required this.label,
    this.valueColor,
  });
}

/// بيانات بطاقة الصنف
class FuelCardData {
  final String title;
  final String fuelName;
  final double balance;
  final String? secondaryTag;
  final List<FuelCardMetric> metrics;

  const FuelCardData({
    required this.title,
    required this.fuelName,
    required this.balance,
    required this.metrics,
    this.secondaryTag,
  });
}

/// بطاقة ملخص الوقود الموحدة الأنيقة
class FuelSummaryCard extends StatelessWidget {
  final FuelCardData data;

  const FuelSummaryCard({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppDimensions.fuelCardMaxWidth,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceXXS,
          ),
          padding: AppDimensions.paddingCard,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppDimensions.borderRadius3XL,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowSubtle,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. الصف العلوي: العنوان + شارة الصنف البيضاوية
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      data.title,
                      style: const TextStyle(
                        fontSize: AppTypography.sizeH2,
                        fontWeight: AppTypography.weightBold,
                        color: AppColors.textDarkSlate,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceM),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spaceL - 2,
                      vertical: AppDimensions.spaceXXS + 0.5,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.charcoal,
                      borderRadius: AppDimensions.borderRadius2XL,
                    ),
                    child: Text(
                      data.fuelName,
                      style: const TextStyle(
                        fontSize: AppTypography.sizeSmall + 0.5,
                        fontWeight: AppTypography.weightBold,
                        color: AppColors.textWhite,
                      ),
                    ),
                  ),
                ],
              ),

              // خط فاصل خفيف وناعم تحت الصف العلوي
              const Padding(
                padding: EdgeInsets.symmetric(
                  vertical: AppDimensions.spaceXS,
                ),
                child: Divider(
                  height: AppDimensions.dividerHeight,
                  thickness: AppDimensions.borderWidthHairline,
                  color: AppColors.borderSubtle,
                ),
              ),

              // 2. الجزء الأوسط: الرقم مع أيقونة ✦ + شارة إضافية اختيارية
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        AppIcons.star,
                        size: AppDimensions.space2XL - 5,
                        color: AppColors.textDarkSlate,
                      ),
                      const SizedBox(width: AppDimensions.spaceXS + 1),
                      Text(
                        AppFormatters.formatQuantity(data.balance),
                        style: const TextStyle(
                          fontSize: AppTypography.sizeH2 + 1,
                          fontWeight: AppTypography.weightBold,
                          color: AppColors.textDarkSlate,
                        ),
                      ),
                    ],
                  ),
                  if (data.secondaryTag != null &&
                      data.secondaryTag!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spaceS + 1,
                        vertical: AppDimensions.spaceXXS - 0.5,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: AppDimensions.borderRadiusXS,
                      ),
                      child: Text(
                        data.secondaryTag!,
                        style: const TextStyle(
                          fontSize: AppTypography.sizeMicro + 0.5,
                          fontWeight: AppTypography.weightBold,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceXS + 1),

              // 3. الجزء السفلي: المربع الرمادي الفاتح لعناصر العمليات
              Center(
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: AppDimensions.fuelCardMetricsMaxWidth,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.spaceS - 1,
                    horizontal: AppDimensions.spaceM,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.highlightBackground,
                    borderRadius: AppDimensions.borderRadiusL,
                  ),
                  child: Row(
                    children: data.metrics.map((metric) {
                      return Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppFormatters.formatQuantity(metric.value),
                              style: TextStyle(
                                fontSize: data.metrics.length > 2
                                    ? AppTypography.sizeBodySecondary + 0.5
                                    : AppTypography.sizeBody + 1,
                                fontWeight: AppTypography.weightBold,
                                color: metric.valueColor ??
                                    AppColors.textDarkSlate,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              metric.label,
                              style: TextStyle(
                                fontSize: data.metrics.length > 2
                                    ? AppTypography.sizeMicro
                                    : AppTypography.sizeMicro + 0.5,
                                color: AppColors.textMuted,
                                fontWeight: AppTypography.weightMedium,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// شريحة ملخص الوقود التفاعلية المتكاملة
class FuelSummarySlider extends StatefulWidget {
  final List<Map<String, dynamic>> fuelTypes;
  final int? selectedFuelId;
  final ValueChanged<int>? onFuelChanged;
  final FuelCardData Function(int fuelId, String fuelName) cardBuilder;

  const FuelSummarySlider({
    super.key,
    required this.fuelTypes,
    this.selectedFuelId,
    this.onFuelChanged,
    required this.cardBuilder,
  });

  @override
  State<FuelSummarySlider> createState() => _FuelSummarySliderState();
}

class _FuelSummarySliderState extends State<FuelSummarySlider> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    final fuels = _effectiveFuelTypes;
    if (widget.selectedFuelId != null) {
      final index = fuels.indexWhere((f) => f['id'] == widget.selectedFuelId);
      if (index != -1) {
        _currentPage = index;
      }
    }
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _effectiveFuelTypes {
    if (widget.fuelTypes.isNotEmpty) {
      return widget.fuelTypes;
    }
    return [
      {'id': 1, 'name': AppStrings.fuelPetrol},
      {'id': 2, 'name': AppStrings.fuelDiesel},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final fuels = _effectiveFuelTypes;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 146,
          child: PageView.builder(
            controller: _pageController,
            itemCount: fuels.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
              if (index < fuels.length && widget.onFuelChanged != null) {
                final fuelId = fuels[index]['id'] as int;
                widget.onFuelChanged!(fuelId);
              }
            },
            itemBuilder: (context, index) {
              final ft = fuels[index];
              final fuelId = ft['id'] as int;
              final fuelName = ft['name'] as String;
              final cardData = widget.cardBuilder(fuelId, fuelName);
              return FuelSummaryCard(data: cardData);
            },
          ),
        ),
        const SizedBox(height: AppDimensions.spaceS),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(fuels.length, (i) {
            final isSelected = i == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceXS,
              ),
              width: isSelected ? AppDimensions.spaceXL : AppDimensions.spaceS,
              height: 5,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.border,
                borderRadius: AppDimensions.borderRadiusXS,
              ),
            );
          }),
        ),
      ],
    );
  }
}
