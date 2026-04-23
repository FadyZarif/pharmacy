import 'package:cloud_firestore/cloud_firestore.dart';

enum PurchaseSourceType { company, warehouse }

class BranchPurchaseModel {
  final String id;
  final String branchId;
  final String branchName;
  final String monthKey;
  final double amount;
  final PurchaseSourceType sourceType;
  final String supplierName;
  final String notes;
  final String invoiceUrl;
  final DateTime purchaseDate;
  final DateTime? createdAt;
  final String createdByUid;
  final String createdByName;
  final String createdByRole;

  BranchPurchaseModel({
    required this.id,
    required this.branchId,
    required this.branchName,
    required this.monthKey,
    required this.amount,
    required this.sourceType,
    required this.supplierName,
    required this.notes,
    required this.invoiceUrl,
    required this.purchaseDate,
    required this.createdAt,
    required this.createdByUid,
    required this.createdByName,
    required this.createdByRole,
  });

  static PurchaseSourceType _sourceFromString(String value) {
    if (value == 'warehouse') return PurchaseSourceType.warehouse;
    return PurchaseSourceType.company;
  }

  static String sourceToString(PurchaseSourceType source) {
    return source == PurchaseSourceType.warehouse ? 'warehouse' : 'company';
  }

  factory BranchPurchaseModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final purchaseTs = data['purchaseDate'];
    final createdTs = data['createdAt'];
    return BranchPurchaseModel(
      id: doc.id,
      branchId: (data['branchId'] as String?) ?? '',
      branchName: (data['branchName'] as String?) ?? '',
      monthKey: (data['monthKey'] as String?) ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      sourceType: _sourceFromString((data['sourceType'] as String?) ?? 'company'),
      supplierName: (data['supplierName'] as String?) ?? '',
      notes: (data['notes'] as String?) ?? '',
      invoiceUrl: (data['invoiceUrl'] as String?) ?? '',
      purchaseDate: purchaseTs is Timestamp ? purchaseTs.toDate() : DateTime.now(),
      createdAt: createdTs is Timestamp ? createdTs.toDate() : null,
      createdByUid: (data['createdByUid'] as String?) ?? '',
      createdByName: (data['createdByName'] as String?) ?? '',
      createdByRole: (data['createdByRole'] as String?) ?? '',
    );
  }
}
