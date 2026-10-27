/// نموذج إحصائي دقيق لحركة الوقود بحسب الصنف (يمنع خلط الأصناف)
class FuelTypeMetrics {
  final int fuelTypeId;
  final String fuelTypeName;

  // 1. ميزان الموردين
  final double supplierSupplyQuota; // توريد اعتماد (type 1)
  final double supplierSupplyActual; // توريد فعلي من الموردين إلى المحطات (type 2)

  // 2. ميزان المحطات
  final double stationSupplyActual; // وارد فعلي للمحطات (type 2)
  final double stationDispenseActual; // منصرف فعلي من المحطات (type 5)
  final double stationAeration; // عمولة تهوية مخصومة (type 3)
  final double stationCurrentStock; // رصيد المحطات المتاح للصنف

  // 3. ميزان المستفيدين
  final double beneficiaryDispenseQuota; // صرف اعتماد للمستفيدين (type 4)
  final double beneficiaryDispenseActual; // صرف فعلي للمستفيدين (type 5)

  FuelTypeMetrics({
    required this.fuelTypeId,
    required this.fuelTypeName,
    required this.supplierSupplyQuota,
    required this.supplierSupplyActual,
    required this.stationSupplyActual,
    required this.stationDispenseActual,
    required this.stationAeration,
    required this.stationCurrentStock,
    required this.beneficiaryDispenseQuota,
    required this.beneficiaryDispenseActual,
  });

  // ميزان الموردين: المتبقي من اعتماد التوريد
  double get supplierRemainingQuota =>
      supplierSupplyQuota - supplierSupplyActual;

  // ميزان الموردين: نسبة التوريد الفعلي من الاعتماد
  double get supplierSupplyRatio => supplierSupplyQuota > 0
      ? (supplierSupplyActual / supplierSupplyQuota).clamp(0.0, 1.0)
      : 0.0;
  double get supplierSupplyPercent => supplierSupplyRatio * 100.0;

  // ميزان المحطات: نسبة المنصرف الفعلي من الوارد الفعلي
  double get stationDispenseRatio => stationSupplyActual > 0
      ? (stationDispenseActual / stationSupplyActual).clamp(0.0, 1.0)
      : 0.0;
  double get stationDispensePercent => stationDispenseRatio * 100.0;

  // ميزان المستفيدين: المتبقي من اعتمادات الصرف
  double get beneficiaryRemainingQuota =>
      beneficiaryDispenseQuota - beneficiaryDispenseActual;

  // ميزان المستفيدين: نسبة التنفيذ الفعلي
  double get beneficiaryDispenseRatio => beneficiaryDispenseQuota > 0
      ? (beneficiaryDispenseActual / beneficiaryDispenseQuota).clamp(0.0, 1.0)
      : 0.0;
  double get beneficiaryDispensePercent => beneficiaryDispenseRatio * 100.0;
}

