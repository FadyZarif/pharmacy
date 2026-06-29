import 'package:cloud_firestore/cloud_firestore.dart';

import 'marketing_coding_metric_model.dart';
import 'marketing_metric_model.dart';

class MarketingDailyEntry {
  final String id;
  final String employeeId;
  final String employeeName;
  final String branchId;
  final String branchName;
  final String dateKey;
  final String monthKey;
  final MarketingCodingMetric newCoding;
  final MarketingMetric followers;
  final MarketingMetric reviews;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MarketingDailyEntry({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.branchId,
    required this.branchName,
    required this.dateKey,
    required this.monthKey,
    required this.newCoding,
    required this.followers,
    required this.reviews,
    this.createdAt,
    this.updatedAt,
  });

  static String buildDocId(String employeeId, String dateKey) =>
      '${employeeId}_$dateKey';

  static String dateKeyFrom(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static String monthKeyFrom(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  bool get canEdit {
    if (createdAt == null) return true;
    return DateTime.now().difference(createdAt!) < const Duration(hours: 24);
  }

  int get totalCount =>
      newCoding.count + followers.count + reviews.count;

  factory MarketingDailyEntry.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdTs = data['createdAt'];
    final updatedTs = data['updatedAt'];
    return MarketingDailyEntry(
      id: doc.id,
      employeeId: (data['employeeId'] as String?) ?? '',
      employeeName: (data['employeeName'] as String?) ?? '',
      branchId: (data['branchId'] as String?) ?? '',
      branchName: (data['branchName'] as String?) ?? '',
      dateKey: (data['dateKey'] as String?) ?? '',
      monthKey: (data['monthKey'] as String?) ?? '',
      newCoding: MarketingCodingMetric.fromMap(
        data['newCoding'] as Map<String, dynamic>?,
      ),
      followers: MarketingMetric.fromMap(
        data['followers'] as Map<String, dynamic>?,
      ),
      reviews: MarketingMetric.fromMap(
        data['reviews'] as Map<String, dynamic>?,
      ),
      createdAt: createdTs is Timestamp ? createdTs.toDate() : null,
      updatedAt: updatedTs is Timestamp ? updatedTs.toDate() : null,
    );
  }

  Map<String, dynamic> toMap({bool isCreate = false}) {
    final map = <String, dynamic>{
      'employeeId': employeeId,
      'employeeName': employeeName,
      'branchId': branchId,
      'branchName': branchName,
      'dateKey': dateKey,
      'monthKey': monthKey,
      'newCoding': newCoding.toMap(),
      'followers': followers.toMap(),
      'reviews': reviews.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (isCreate) {
      map['createdAt'] = FieldValue.serverTimestamp();
    }
    return map;
  }
}
