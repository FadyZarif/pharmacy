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
      uploadedAt: const ServerTimestampOnNullConverter().fromJson(
        json['uploadedAt'],
      ),
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
      'uploadedAt': const ServerTimestampOnNullConverter().toJson(
        instance.uploadedAt,
      ),
      'uploadedBy': instance.uploadedBy,
      'employeeCount': instance.employeeCount,
      'notes': instance.notes,
    };
