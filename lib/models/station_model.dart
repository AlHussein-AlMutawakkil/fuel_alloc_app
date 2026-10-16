/// نموذج المحطة (محطة الوقود / نقطة الصرف والتوريد)
class StationModel {
  final int? id;
  final String name;
  final String? location;
  final String? phoneNumber;
  final double defaultCommissionRate;
  final bool isActive;
  final String? createdAt;
  final double currentBalance;

  StationModel({
    this.id,
    required this.name,
    this.location,
    this.phoneNumber,
    this.defaultCommissionRate = 2.0,
    this.isActive = true,
    this.createdAt,
    this.currentBalance = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'location': location,
      'phone_number': phoneNumber,
      'default_commission_rate': defaultCommissionRate,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
  }

  factory StationModel.fromMap(Map<String, dynamic> map) {
    return StationModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      location: map['location'] as String?,
      phoneNumber: map['phone_number'] as String?,
      defaultCommissionRate:
          (map['default_commission_rate'] as num?)?.toDouble() ?? 2.0,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: map['created_at'] as String?,
      currentBalance: (map['balance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  StationModel copyWith({
    int? id,
    String? name,
    String? location,
    String? phoneNumber,
    double? defaultCommissionRate,
    bool? isActive,
    String? createdAt,
    double? currentBalance,
  }) {
    return StationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      defaultCommissionRate:
          defaultCommissionRate ?? this.defaultCommissionRate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      currentBalance: currentBalance ?? this.currentBalance,
    );
  }
}
