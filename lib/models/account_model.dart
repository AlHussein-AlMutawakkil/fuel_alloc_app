enum AccountType {
  supplier, // مورد (الجهة العليا)
  beneficiary, // مستفيد (عميل)
}

/// نموذج الحساب الموحد
class AccountModel {
  final int? id;
  final String name;
  final AccountType accountType;
  final String? phoneNumber;
  final bool isActive;
  final bool isArchived;
  final String? createdAt;

  AccountModel({
    this.id,
    required this.name,
    required this.accountType,
    this.phoneNumber,
    this.isActive = true,
    this.isArchived = false,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'account_type':
          accountType == AccountType.supplier ? 'SUPPLIER' : 'BENEFICIARY',
      'phone_number': phoneNumber,
      'is_active': isActive ? 1 : 0,
      'is_archived': isArchived ? 1 : 0,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
  }

  factory AccountModel.fromMap(Map<String, dynamic> map) {
    return AccountModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      accountType: map['account_type'] == 'SUPPLIER'
          ? AccountType.supplier
          : AccountType.beneficiary,
      phoneNumber: map['phone_number'] as String?,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      isArchived: (map['is_archived'] as int? ?? 0) == 1,
      createdAt: map['created_at'] as String?,
    );
  }

  AccountModel copyWith({
    int? id,
    String? name,
    AccountType? accountType,
    String? phoneNumber,
    bool? isActive,
    bool? isArchived,
    String? createdAt,
  }) {
    return AccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      accountType: accountType ?? this.accountType,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isActive: isActive ?? this.isActive,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
