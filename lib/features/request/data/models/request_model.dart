
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:pharmacy/core/helpers/server_timestamp_helper.dart';

part 'request_model.g.dart';
/// الأنواع الرئيسية للطلبات
enum RequestType { annualLeave, sickLeave, extraHours, coverageShift, attend, permission }

/// حالة الطلب
enum RequestStatus { pending, approved, rejected, }

/// الموديل الأساسي
@JsonSerializable(explicitToJson: true)
class RequestModel {
  final String employeeId;
  final String employeeName;
  final String employeePhone;
  final String employeeBranchId;
  final String employeeBranchName;
  final String? employeePhoto;

  final String id;
  final RequestType type;
  final RequestStatus status;
  final String? notes;
  @ServerTimestampOnNullConverter()
  final DateTime? createdAt;
  @ServerNullableTimestampConverter()
  final DateTime? updatedAt;

  /// تفاصيل الطلب (بتختلف حسب النوع)
  final Map<String, dynamic> details;

  RequestModel({
    required this.employeeId,
    required this.employeeName,
    required this.employeePhone,
    required this.employeeBranchId,
    required this.employeeBranchName,
    this.employeePhoto,
    required this.id,
    required this.type,
    required this.status,
    this.notes,
    this.createdAt,
    this.updatedAt,
    required this.details,
  });

  factory RequestModel.fromJson(Map<String, dynamic> json) =>
      _$RequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$RequestModelToJson(this);

  RequestModel copyWith({
    String? employeeId,
    String? employeeName,
    String? employeePhone,
    String? employeeBranchId,
    String? employeeBranchName,
    String? employeePhoto,
    String? id,
    RequestType? type,
    RequestStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? details,
  }) {
    return RequestModel(
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      employeePhone: employeePhone ?? this.employeePhone,
      employeeBranchId: employeeBranchId ?? this.employeeBranchId,
      employeeBranchName: employeeBranchName ?? this.employeeBranchName,
      employeePhoto: employeePhoto ?? this.employeePhoto,
      id: id ?? this.id,
      type: type ?? this.type,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      details: details ?? this.details,
    );
  }

  Color get statusColor {
    switch (status) {
      case RequestStatus.pending:
        return  Colors.orange;
      case RequestStatus.approved:
        return Colors.green;
      case RequestStatus.rejected:
        return Colors.red;
    }
  }
  String get typeLabel {
    switch (type) {
      case RequestType.annualLeave:
        return 'Annual Leave';
      case RequestType.sickLeave:
        return 'Sick Leave';
      case RequestType.extraHours:
        return 'Extra Hours';
      case RequestType.coverageShift:
        return 'Coverage Shift';
      case RequestType.attend:
        return 'Attendance';
      case RequestType.permission:
        return 'Early Leave Permission';
    }
  }
  IconData get typeIcon {
    switch (type) {
      case RequestType.annualLeave:
        return Icons.beach_access;
      case RequestType.sickLeave:
        return Icons.local_hospital;
      case RequestType.extraHours:
        return Icons.access_time;
      case RequestType.coverageShift:
        return Icons.swap_horiz;
      case RequestType.attend:
        return Icons.check_circle;
      case RequestType.permission:
        return Icons.exit_to_app;
    }
  }
}

@JsonSerializable()
class AnnualLeaveDetails {
  @ServerTimestampConverter()
  final DateTime startDate;
  @ServerTimestampConverter()
  final DateTime endDate;
  AnnualLeaveDetails({
    required this.startDate,
    required this.endDate,
  });

  factory AnnualLeaveDetails.fromJson(Map<String, dynamic> json) =>
      _$AnnualLeaveDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$AnnualLeaveDetailsToJson(this);

  int get totalDays {
    return endDate.difference(startDate).inDays + 1;
  }
}

@JsonSerializable()
class SickLeaveDetails {
  @ServerTimestampConverter()
  final DateTime startDate;
  @ServerTimestampConverter()
  final DateTime endDate;
  String prescription;


  SickLeaveDetails({
    required this.startDate,
    required this.endDate,
    required this.prescription,
  });

  factory SickLeaveDetails.fromJson(Map<String, dynamic> json) =>
      _$SickLeaveDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$SickLeaveDetailsToJson(this);
}

@JsonSerializable()
class ExtraHoursDetails {
  @ServerTimestampConverter()
  final DateTime date;
  final int hours;

  ExtraHoursDetails({
    required this.date,
    required this.hours,
  });

  factory ExtraHoursDetails.fromJson(Map<String, dynamic> json) =>
      _$ExtraHoursDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$ExtraHoursDetailsToJson(this);
}

@JsonSerializable(explicitToJson: true)
class CoverageShiftDetails {
  final String peerEmployeeId;
  final String peerEmployeeName;
  final String peerBranchId;
  final String peerBranchName;
  @ServerTimestampConverter()
  final DateTime date;



  CoverageShiftDetails({
    required this.peerEmployeeId,
    required this.peerEmployeeName,
    required this.peerBranchId,
    required this.peerBranchName,
    required this.date,
  });

  factory CoverageShiftDetails.fromJson(Map<String, dynamic> json) =>
      _$CoverageShiftDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$CoverageShiftDetailsToJson(this);
}

@JsonSerializable()
class AttendDetails {
  @ServerTimestampConverter()
  final DateTime date;

  AttendDetails({
    required this.date,
  });

  factory AttendDetails.fromJson(Map<String, dynamic> json) =>
      _$AttendDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$AttendDetailsToJson(this);
}

@JsonSerializable()
class PermissionDetails {
  @ServerTimestampConverter()
  final DateTime date;
  final int hours;

  PermissionDetails({
    required this.date,
    required this.hours,
  });

  factory PermissionDetails.fromJson(Map<String, dynamic> json) =>
      _$PermissionDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$PermissionDetailsToJson(this);
}