
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:pharmacy/core/helpers/server_timestamp_helper.dart';

part 'request_model.g.dart';
/// الأنواع الرئيسية للطلبات
enum RequestType { annualLeave, sickLeave, extraHours, coverageShift, attend, permission }

extension RequestTypeExtension on RequestType {
  String get enName {
    switch (this) {
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
        return 'Permission';
    }
  }
  String get arName {
    switch (this) {
      case RequestType.annualLeave:
        return 'إجازة اعتيادية';
      case RequestType.sickLeave:
        return 'إجازة مرضية';
      case RequestType.extraHours:
        return 'ساعات إضافية';
      case RequestType.coverageShift:
        return 'تبديل وردية';
      case RequestType.attend:
        return 'حضور';
      case RequestType.permission:
        return 'اذن';
    }
  }
  IconData get icon {
    switch (this) {
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

/// حالة الطلب
enum RequestStatus { pending, approved, rejected, }

extension RequestStatusExtension on RequestStatus {
  String get enName {
    switch (this) {
      case RequestStatus.pending:
        return 'Pending';
      case RequestStatus.approved:
        return 'Approved';
      case RequestStatus.rejected:
        return 'Rejected';
    }
  }
  String get arName {
    switch (this) {
      case RequestStatus.pending:
        return 'قيد الانتظار';
      case RequestStatus.approved:
        return 'تم الموافقة';
      case RequestStatus.rejected:
        return 'تم الرفض';
    }
  }
  Color get color {
    switch (this) {
      case RequestStatus.pending:
        return  Colors.orange;
      case RequestStatus.approved:
        return Colors.green;
      case RequestStatus.rejected:
        return Colors.red;
    }
  }

}

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

  /// معلومات من قام بالموافقة أو الرفض
  final String? processedByName;

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
    this.processedByName,
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
    String? processedByName,
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
      processedByName: processedByName ?? this.processedByName,
      details: details ?? this.details,
    );
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
  @Default(PermissionType.earlyLeave) final PermissionType type; // late arrival or early leave
  final int hours;
  final int minutes;

  PermissionDetails({
    required this.date,
    required this.type,
    required this.hours,
    required this.minutes,
  });

  factory PermissionDetails.fromJson(Map<String, dynamic> json) =>
      _$PermissionDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$PermissionDetailsToJson(this);

  // Get total minutes
  int get totalMinutes => (hours * 60) + minutes;
}

enum PermissionType {
  @JsonValue('lateArrival')
  lateArrival,

  @JsonValue('earlyLeave')
  earlyLeave,
}