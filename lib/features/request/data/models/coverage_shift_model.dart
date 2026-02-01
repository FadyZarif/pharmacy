import 'package:json_annotation/json_annotation.dart';

import '../../../../core/helpers/server_timestamp_helper.dart';

part 'coverage_shift_model.g.dart';

/// Model for storing approved coverage shifts
/// This is used to temporarily swap branches for employees
@JsonSerializable()
class CoverageShiftModel {
  final String id;
  final String requestId;
  @ServerTimestampConverter()
  final DateTime date;

  // Employee 1 (requester)
  final String employee1Id;
  final String employee1OriginalBranchId;
  final String employee1OriginalBranchName;
  final String employee1TempBranchId;
  final String employee1TempBranchName;

  // Employee 2 (peer)
  final String employee2Id;
  final String employee2OriginalBranchId;
  final String employee2OriginalBranchName;
  final String employee2TempBranchId;
  final String employee2TempBranchName;

  CoverageShiftModel({
    required this.id,
    required this.requestId,
    required this.date,
    required this.employee1Id,
    required this.employee1OriginalBranchId,
    required this.employee1OriginalBranchName,
    required this.employee1TempBranchId,
    required this.employee1TempBranchName,
    required this.employee2Id,
    required this.employee2OriginalBranchId,
    required this.employee2OriginalBranchName,
    required this.employee2TempBranchId,
    required this.employee2TempBranchName,
  });

  factory CoverageShiftModel.fromJson(Map<String, dynamic> json) =>
      _$CoverageShiftModelFromJson(json);

  Map<String, dynamic> toJson() => _$CoverageShiftModelToJson(this);
}

