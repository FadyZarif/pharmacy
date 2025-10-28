// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repair_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RepairModel _$RepairModelFromJson(Map<String, dynamic> json) => RepairModel(
  id: json['id'] as String,
  deviceName: json['deviceName'] as String,
  notes: json['notes'] as String,
  employeeName: json['employeeName'] as String,
  employeeId: json['employeeId'] as String,
  branchId: json['branchId'] as String,
  branchName: json['branchName'] as String,
  createdAt: const ServerTimestampOnNullConverter().fromJson(json['createdAt']),
);

Map<String, dynamic> _$RepairModelToJson(RepairModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'deviceName': instance.deviceName,
      'notes': instance.notes,
      'employeeName': instance.employeeName,
      'employeeId': instance.employeeId,
      'branchId': instance.branchId,
      'branchName': instance.branchName,
      'createdAt': const ServerTimestampOnNullConverter().toJson(
        instance.createdAt,
      ),
    };
