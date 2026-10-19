enum AccountType {
  supplier, // مورد (الجهة العليا)
  beneficiary, // مستفيد (عميل)
  station, // محطة (نقطة توزيع وتوريد وقود)
}

/// نموذج الحساب الموحد (يشمل العملاء، الموردين، والمحطات)
class AccountModel {
  final int? id;
  final String name;
  final AccountType accountType;
  final String? phoneNumber;
  final String? location; // خاص بالمحطات
  final double defaultCommissionRate; // نسبة عمولة التهوية الافتراضية للمحطة (2.0%)
  final bool isActive;
  final bool isArchived;
  final String? createdAt;
  final String? deletedAt;
  final int operationsCount;
  final double currentBalance;

  AccountModel({
    this.id,
    required this.name,
    required this.accountType,
    this.phoneNumber,
    this.location,
    this.defaultCommissionRate = 2.0,
    this.isActive = true,
    this.isArchived = false,
    this.createdAt,
    this.deletedAt,
    this.operationsCount = 0,
    this.currentBalance = 0.0,
  });

  Map<String, dynamic> toMap() {
    String typeStr;
    switch (accountType) {
      case AccountType.supplier:
        typeStr = 'SUPPLIER';
        break;
      case AccountType.station:
        typeStr = 'STATION';
        break;
      case AccountType.beneficiary:
      default:
        typeStr = 'BENEFICIARY';
        break;
    }

    return {
      if (id != null) 'id': id,
      'name': name,
      'account_type': typeStr,
      'phone_number': phoneNumber,
      'location': location,
      'default_commission_rate': defaultCommissionRate,
      'is_active': isActive ? 1 : 0,
      'is_archived': isArchived ? 1 : 0,
      if (deletedAt != null) 'deleted_at': deletedAt,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
  }

  factory AccountModel.fromMap(Map<String, dynamic> map) {
    final typeStr = map['account_type'] as String?;
    AccountType type;
    if (typeStr == 'SUPPLIER') {
      type = AccountType.supplier;
    } else if (typeStr == 'STATION') {
      type = AccountType.station;
    } else {
      type = AccountType.beneficiary;
    }

    return AccountModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      accountType: type,
      phoneNumber: map['phone_number'] as String?,
      location: map['location'] as String?,
      defaultCommissionRate:
          (map['default_commission_rate'] as num?)?.toDouble() ?? 2.0,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      isArchived: (map['is_archived'] as int? ?? 0) == 1,
      createdAt: map['created_at'] as String?,
      deletedAt: map['deleted_at'] as String?,
      operationsCount: (map['operations_count'] as num?)?.toInt() ?? 0,
      currentBalance: (map['balance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  AccountModel copyWith({
    int? id,
    String? name,
    AccountType? accountType,
    String? phoneNumber,
    String? location,
    double? defaultCommissionRate,
    bool? isActive,
    bool? isArchived,
    String? createdAt,
    String? deletedAt,
    int? operationsCount,
    double? currentBalance,
  }) {
    return AccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      accountType: accountType ?? this.accountType,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      location: location ?? this.location,
      defaultCommissionRate:
          defaultCommissionRate ?? this.defaultCommissionRate,
      isActive: isActive ?? this.isActive,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      operationsCount: operationsCount ?? this.operationsCount,
      currentBalance: currentBalance ?? this.currentBalance,
    );
  }
}
