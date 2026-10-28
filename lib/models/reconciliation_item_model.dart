/// حالات رصيد المطابقة
enum ReconciliationStatus {
  available, // متوفر
  warning, // وشيك على النفاد (أقل من 20% أو كمية محددة)
  depleted, // منتهي أو رصيد صفر
}

/// نموذج بند تقرير المطابقة والمراقبة
class ReconciliationItemModel {
  final int accountId;
  final String accountName;
  final String accountType; // SUPPLIER, STATION, BENEFICIARY
  final String? phoneNumber;
  final String? location;
  final int fuelTypeId;
  final String fuelTypeName;
  final double quota; // توريد اعتماد أو صرف اعتماد
  final double actual; // توريد فعلي أو صرف فعلي
  final double aeration; // عمولة تهوية (للمحطات)
  final double transfersIn; // تحويل وارد
  final double transfersOut; // تحويل صادر
  final double balance; // الرصيد المتبقي أو المخزون الفعلي
  final double ratio; // نسبة الإنجاز / الصرف (0.0 إلى 1.0)
  final double commissionRate; // نسبة عمولة المحطة

  const ReconciliationItemModel({
    required this.accountId,
    required this.accountName,
    required this.accountType,
    this.phoneNumber,
    this.location,
    required this.fuelTypeId,
    required this.fuelTypeName,
    this.quota = 0.0,
    this.actual = 0.0,
    this.aeration = 0.0,
    this.transfersIn = 0.0,
    this.transfersOut = 0.0,
    required this.balance,
    required this.ratio,
    this.commissionRate = 2.0,
  });

  /// حساب حالة الرصيد تلقائياً بناءً على المتبقي والنسبة
  ReconciliationStatus get status {
    if (balance <= 0.001) {
      return ReconciliationStatus.depleted;
    }
    if (quota > 0 && (balance / quota) < 0.20) {
      return ReconciliationStatus.warning;
    }
    if (accountType == 'STATION' && balance < 500) {
      return ReconciliationStatus.warning;
    }
    return ReconciliationStatus.available;
  }

  double get percent => (ratio * 100.0).clamp(0.0, 100.0);
}

