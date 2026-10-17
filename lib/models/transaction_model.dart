/// نموذج القيد والعملية المحاسبية الموحدة
class TransactionModel {
  final int? id;
  final String? transactionNumber;
  final String transactionDate;
  final int typeId;
  final String? typeName;
  final String? typeCode;
  final int? accountId;
  final String? accountName;
  final int? stationId;
  final String? stationName;
  final int? referenceStationId;
  final String? referenceStationName;
  final int? fuelTypeId;
  final String? fuelTypeName;
  final int unitId;
  final String? unitName;
  final double? unitFactor;
  final double enteredQuantity;
  final double baseQuantityLiters;
  final String? referenceNumber;
  final int? parentTransactionId;
  final String? notes;
  final String? createdAt;

  TransactionModel({
    this.id,
    this.transactionNumber,
    required this.transactionDate,
    required this.typeId,
    this.typeName,
    this.typeCode,
    this.accountId,
    this.accountName,
    this.stationId,
    this.stationName,
    this.referenceStationId,
    this.referenceStationName,
    this.fuelTypeId,
    this.fuelTypeName,
    required this.unitId,
    this.unitName,
    this.unitFactor,
    required this.enteredQuantity,
    required this.baseQuantityLiters,
    this.referenceNumber,
    this.parentTransactionId,
    this.notes,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'transaction_number': transactionNumber,
      'transaction_date': transactionDate,
      'type_id': typeId,
      'account_id': accountId,
      'station_id': stationId,
      'reference_station_id': referenceStationId,
      'fuel_type_id': fuelTypeId,
      'unit_id': unitId,
      'entered_quantity': enteredQuantity,
      'base_quantity_liters': baseQuantityLiters,
      'reference_number': referenceNumber,
      'parent_transaction_id': parentTransactionId,
      'notes': notes,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      transactionNumber: map['transaction_number'] as String?,
      transactionDate: map['transaction_date'] as String,
      typeId: map['type_id'] as int,
      typeName: map['type_name'] as String?,
      typeCode: map['type_code'] as String?,
      accountId: map['account_id'] as int?,
      accountName: map['account_name'] as String?,
      stationId: map['station_id'] as int?,
      stationName: map['station_name'] as String?,
      referenceStationId: map['reference_station_id'] as int?,
      referenceStationName: map['reference_station_name'] as String?,
      fuelTypeId: map['fuel_type_id'] as int?,
      fuelTypeName: map['fuel_type_name'] as String?,
      unitId: map['unit_id'] as int,
      unitName: map['unit_name'] as String?,
      unitFactor: (map['unit_factor'] as num?)?.toDouble(),
      enteredQuantity: (map['entered_quantity'] as num).toDouble(),
      baseQuantityLiters: (map['base_quantity_liters'] as num).toDouble(),
      referenceNumber: map['reference_number'] as String?,
      parentTransactionId: map['parent_transaction_id'] as int?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }

  bool get isSupply =>
      typeCode == 'SUPPLY_QUOTA' ||
      typeCode == 'SUPPLY_ACTUAL' ||
      typeId == 1 ||
      typeId == 2;

  bool get isDispense =>
      typeCode == 'DISPENSE_QUOTA' ||
      typeCode == 'DISPENSE_ACTUAL' ||
      typeId == 4 ||
      typeId == 5;

  bool get isQuota =>
      typeCode == 'SUPPLY_QUOTA' ||
      typeCode == 'DISPENSE_QUOTA' ||
      typeId == 1 ||
      typeId == 4;

  bool get isActual =>
      typeCode == 'SUPPLY_ACTUAL' ||
      typeCode == 'DISPENSE_ACTUAL' ||
      typeId == 2 ||
      typeId == 5;

  bool get isAeration => typeCode == 'AERATION_COMMISSION' || typeId == 3;
}
