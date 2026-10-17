import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
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

/// بطاقة ملخص الوقود الموحدة الأنيقة (تصميم مرن ومتناسق بدون تمدد مفرط أو أخطاء تجاوز)
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
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.025),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. الصف العلوي: العنوان (يمين في RTL) + شارة الصنف البيضاوية السوداء (يسار في RTL)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      data.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      data.fuelName,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              // خط فاصل خفيف وناعم تحت الصف العلوي
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Divider(
                  height: 1,
                  thickness: 0.5,
                  color: Color(0xFFF1F5F9),
                ),
              ),

              // 2. الجزء الأوسط: الرقم فقط مع أيقونة النجمة ✦ (يمين) + شارة إضافية اختيارية (يسار)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        size: 15,
                        color: Color(0xFF1E293B),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        AppFormatters.formatQuantity(data.balance),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  if (data.secondaryTag != null &&
                      data.secondaryTag!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        data.secondaryTag!,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 5),

              // 3. الجزء السفلي: المربع الرمادي الفاتح لعناصر العمليات (محدد العرض لتفادي التمدد المفرط)
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 380),
                  padding:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F5F7),
                    borderRadius: BorderRadius.circular(10),
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
                                fontSize: data.metrics.length > 2 ? 13.5 : 15,
                                fontWeight: FontWeight.bold,
                                color: metric.valueColor ??
                                    const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              metric.label,
                              style: TextStyle(
                                fontSize: data.metrics.length > 2 ? 10 : 10.5,
                                color: const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
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

/// شريحة ملخص الوقود التفاعلية المتكاملة (تجمع السلايدر، مؤشر النقاط، والتصميم المرن الموحد)
/// كل القياسات والأطوال تدار هنا تلقائياً دون الحاجة لتكرارها في كل صفحة
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
      final index =
          fuels.indexWhere((f) => f['id'] == widget.selectedFuelId);
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
      {'id': 1, 'name': 'بترول'},
      {'id': 2, 'name': 'ديزل'},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final fuels = _effectiveFuelTypes;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // سلايدر الكروت بقياس تلقائي مرن وموحد
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

        // مؤشر التنقل بين الأصناف (نقطتان فقط بدون أسهم)
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(fuels.length, (i) {
            final isSelected = i == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isSelected ? 16 : 6,
              height: 5,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}
