// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coverage_shift_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CoverageShiftModel _$CoverageShiftModelFromJson(
  Map<String, dynamic> json,
) => CoverageShiftModel(
  id: json['id'] as String,
  requestId: json['requestId'] as String,
  date: const ServerTimestampConverter().fromJson(json['date'] as Object),
  employee1Id: json['employee1Id'] as String,
  employee1OriginalBranchId: json['employee1OriginalBranchId'] as String,
  employee1OriginalBranchName: json['employee1OriginalBranchName'] as String,
  employee1TempBranchId: json['employee1TempBranchId'] as String,
  employee1TempBranchName: json['employee1TempBranchName'] as String,
  employee2Id: json['employee2Id'] as String,
  employee2OriginalBranchId: json['employee2OriginalBranchId'] as String,
  employee2OriginalBranchName: json['employee2OriginalBranchName'] as String,
  employee2TempBranchId: json['employee2TempBranchId'] as String,
  employee2TempBranchName: json['employee2TempBranchName'] as String,
);

Map<String, dynamic> _$CoverageShiftModelToJson(CoverageShiftModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'requestId': instance.requestId,
      'date': const ServerTimestampConverter().toJson(instance.date),
      'employee1Id': instance.employee1Id,
      'employee1OriginalBranchId': instance.employee1OriginalBranchId,
      'employee1OriginalBranchName': instance.employee1OriginalBranchName,
      'employee1TempBranchId': instance.employee1TempBranchId,
      'employee1TempBranchName': instance.employee1TempBranchName,
      'employee2Id': instance.employee2Id,
      'employee2OriginalBranchId': instance.employee2OriginalBranchId,
      'employee2OriginalBranchName': instance.employee2OriginalBranchName,
      'employee2TempBranchId': instance.employee2TempBranchId,
      'employee2TempBranchName': instance.employee2TempBranchName,
    };
