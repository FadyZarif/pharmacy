// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'month_salary_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MonthSalaryModel _$MonthSalaryModelFromJson(Map<String, dynamic> json) =>
    MonthSalaryModel(
      monthKey: json['monthKey'] as String,
      monthName: json['monthName'] as String,
      year: (json['year'] as num).toInt(),
      month: (json['month'] as num).toInt(),
      uploadedAt: json['uploadedAt'] == null
          ? null
          : DateTime.parse(json['uploadedAt'] as String),
      uploadedBy: json['uploadedBy'] as String?,
      employeeCount: (json['employeeCount'] as num?)?.toInt(),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$MonthSalaryModelToJson(MonthSalaryModel instance) =>
    <String, dynamic>{
      'monthKey': instance.monthKey,
      'monthName': instance.monthName,
      'year': instance.year,
      'month': instance.month,
      'uploadedAt': instance.uploadedAt?.toIso8601String(),
      'uploadedBy': instance.uploadedBy,
      'employeeCount': instance.employeeCount,
      'notes': instance.notes,
    };
