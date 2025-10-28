// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RequestModel _$RequestModelFromJson(Map<String, dynamic> json) => RequestModel(
  employeeId: json['employeeId'] as String,
  employeeName: json['employeeName'] as String,
  employeePhone: json['employeePhone'] as String,
  employeeBranchId: json['employeeBranchId'] as String,
  employeeBranchName: json['employeeBranchName'] as String,
  employeePhoto: json['employeePhoto'] as String?,
  id: json['id'] as String,
  type: $enumDecode(_$RequestTypeEnumMap, json['type']),
  status: $enumDecode(_$RequestStatusEnumMap, json['status']),
  notes: json['notes'] as String?,
  createdAt: const ServerTimestampOnNullConverter().fromJson(json['createdAt']),
  updatedAt: const ServerNullableTimestampConverter().fromJson(
    json['updatedAt'],
  ),
  details: json['details'] as Map<String, dynamic>,
);

Map<String, dynamic> _$RequestModelToJson(RequestModel instance) =>
    <String, dynamic>{
      'employeeId': instance.employeeId,
      'employeeName': instance.employeeName,
      'employeePhone': instance.employeePhone,
      'employeeBranchId': instance.employeeBranchId,
      'employeeBranchName': instance.employeeBranchName,
      'employeePhoto': instance.employeePhoto,
      'id': instance.id,
      'type': _$RequestTypeEnumMap[instance.type]!,
      'status': _$RequestStatusEnumMap[instance.status]!,
      'notes': instance.notes,
      'createdAt': const ServerTimestampOnNullConverter().toJson(
        instance.createdAt,
      ),
      'updatedAt': const ServerNullableTimestampConverter().toJson(
        instance.updatedAt,
      ),
      'details': instance.details,
    };

const _$RequestTypeEnumMap = {
  RequestType.annualLeave: 'annualLeave',
  RequestType.sickLeave: 'sickLeave',
  RequestType.extraHours: 'extraHours',
  RequestType.coverageShift: 'coverageShift',
  RequestType.attend: 'attend',
  RequestType.permission: 'permission',
};

const _$RequestStatusEnumMap = {
  RequestStatus.pending: 'pending',
  RequestStatus.approved: 'approved',
  RequestStatus.rejected: 'rejected',
};

AnnualLeaveDetails _$AnnualLeaveDetailsFromJson(Map<String, dynamic> json) =>
    AnnualLeaveDetails(
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
    );

Map<String, dynamic> _$AnnualLeaveDetailsToJson(AnnualLeaveDetails instance) =>
    <String, dynamic>{
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
    };

SickLeaveDetails _$SickLeaveDetailsFromJson(Map<String, dynamic> json) =>
    SickLeaveDetails(
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      prescription: json['prescription'] as String,
    );

Map<String, dynamic> _$SickLeaveDetailsToJson(SickLeaveDetails instance) =>
    <String, dynamic>{
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'prescription': instance.prescription,
    };

ExtraHoursDetails _$ExtraHoursDetailsFromJson(Map<String, dynamic> json) =>
    ExtraHoursDetails(
      date: DateTime.parse(json['date'] as String),
      hours: (json['hours'] as num).toInt(),
    );

Map<String, dynamic> _$ExtraHoursDetailsToJson(ExtraHoursDetails instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'hours': instance.hours,
    };

CoverageShiftDetails _$CoverageShiftDetailsFromJson(
  Map<String, dynamic> json,
) => CoverageShiftDetails(
  peerEmployeeId: json['peerEmployeeId'] as String,
  peerEmployeeName: json['peerEmployeeName'] as String,
  peerBranchId: json['peerBranchId'] as String,
  peerBranchName: json['peerBranchName'] as String,
  date: DateTime.parse(json['date'] as String),
);

Map<String, dynamic> _$CoverageShiftDetailsToJson(
  CoverageShiftDetails instance,
) => <String, dynamic>{
  'peerEmployeeId': instance.peerEmployeeId,
  'peerEmployeeName': instance.peerEmployeeName,
  'peerBranchId': instance.peerBranchId,
  'peerBranchName': instance.peerBranchName,
  'date': instance.date.toIso8601String(),
};

AttendDetails _$AttendDetailsFromJson(Map<String, dynamic> json) =>
    AttendDetails(date: DateTime.parse(json['date'] as String));

Map<String, dynamic> _$AttendDetailsToJson(AttendDetails instance) =>
    <String, dynamic>{'date': instance.date.toIso8601String()};

PermissionDetails _$PermissionDetailsFromJson(Map<String, dynamic> json) =>
    PermissionDetails(
      date: DateTime.parse(json['date'] as String),
      hours: (json['hours'] as num).toInt(),
    );

Map<String, dynamic> _$PermissionDetailsToJson(PermissionDetails instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'hours': instance.hours,
    };
