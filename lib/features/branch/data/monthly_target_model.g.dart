// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monthly_target_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MonthlyTargetModel _$MonthlyTargetModelFromJson(Map<String, dynamic> json) =>
    MonthlyTargetModel(
      monthYear: json['monthYear'] as String,
      monthlyTarget: (json['monthlyTarget'] as num).toInt(),
    );

Map<String, dynamic> _$MonthlyTargetModelToJson(MonthlyTargetModel instance) =>
    <String, dynamic>{
      'monthYear': instance.monthYear,
      'monthlyTarget': instance.monthlyTarget,
    };
