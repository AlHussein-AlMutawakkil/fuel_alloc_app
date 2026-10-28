import 'transaction_model.dart';

/// نموذج بند كشف الحساب مع الرصيد الجاري التراكمي
class StatementItemModel {
  final TransactionModel transaction;
  final double runningBalance;
  final double inflow; // وارد / اعتماد إيجابي
  final double outflow; // منصرف / خصم
  final String? operationLabel;

  const StatementItemModel({
    required this.transaction,
    required this.runningBalance,
    this.inflow = 0.0,
    this.outflow = 0.0,
    this.operationLabel,
  });

  int? get id => transaction.id;
  String? get transactionNumber => transaction.transactionNumber;
  String get transactionDate => transaction.transactionDate;
  int get typeId => transaction.typeId;
  String? get typeName => operationLabel ?? transaction.typeName;
  String? get fuelTypeName => transaction.fuelTypeName;
  int? get fuelTypeId => transaction.fuelTypeId;
  String? get unitName => transaction.unitName;
  double get enteredQuantity => transaction.enteredQuantity;
  double get baseQuantityLiters => transaction.baseQuantityLiters;
  String? get stationName => transaction.stationName;
  String? get referenceStationName => transaction.referenceStationName;
  String? get recipientName => transaction.recipientName;
  String? get referenceNumber => transaction.referenceNumber;
  String? get notes => transaction.notes;

  bool get isPositive => inflow > 0;
  bool get isNegative => outflow > 0;
}

