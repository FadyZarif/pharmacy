// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'salary_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SalaryModel _$SalaryModelFromJson(Map<String, dynamic> json) => SalaryModel(
  employeeUid: json['employeeUid'] as String,
  pharmacyCode: json['pharmacyCode'] as String,
  pharmacyName: json['pharmacyName'] as String,
  acc: json['acc'] as String,
  nameEnglish: json['nameEnglish'] as String,
  nameArabic: json['nameArabic'] as String,
  hourlyRate: json['hourlyRate'] as String,
  hoursWorked: json['hoursWorked'] as String,
  basicSalary: json['basicSalary'] as String,
  incentive: json['incentive'] as String,
  additional: json['additional'] as String,
  quarterlySalesIncentive: json['quarterlySalesIncentive'] as String,
  workBonus: json['workBonus'] as String,
  administrativeBonus: json['administrativeBonus'] as String,
  transportAllowance: json['transportAllowance'] as String,
  employerShare: json['employerShare'] as String,
  eideya: json['eideya'] as String,
  hourlyDeduction: json['hourlyDeduction'] as String,
  penalties: json['penalties'] as String,
  pharmacyCodeDeduction: json['pharmacyCodeDeduction'] as String,
  visaDeduction: json['visaDeduction'] as String,
  advanceDeduction: json['advanceDeduction'] as String,
  quarterlyShiftDeficitDeduction:
      json['quarterlyShiftDeficitDeduction'] as String,
  insuranceDeduction: json['insuranceDeduction'] as String,
  netSalary: json['netSalary'] as String,
  remainingAdvance: json['remainingAdvance'] as String,
  notes: json['notes'] as String?,
  uploadedAt: const ServerNullableTimestampConverter().fromJson(
    json['uploadedAt'],
  ),
  uploadedBy: json['uploadedBy'] as String?,
);

Map<String, dynamic> _$SalaryModelToJson(SalaryModel instance) =>
    <String, dynamic>{
      'employeeUid': instance.employeeUid,
      'pharmacyCode': instance.pharmacyCode,
      'pharmacyName': instance.pharmacyName,
      'acc': instance.acc,
      'nameEnglish': instance.nameEnglish,
      'nameArabic': instance.nameArabic,
      'hourlyRate': instance.hourlyRate,
      'hoursWorked': instance.hoursWorked,
      'basicSalary': instance.basicSalary,
      'incentive': instance.incentive,
      'additional': instance.additional,
      'quarterlySalesIncentive': instance.quarterlySalesIncentive,
      'workBonus': instance.workBonus,
      'administrativeBonus': instance.administrativeBonus,
      'transportAllowance': instance.transportAllowance,
      'employerShare': instance.employerShare,
      'eideya': instance.eideya,
      'hourlyDeduction': instance.hourlyDeduction,
      'penalties': instance.penalties,
      'pharmacyCodeDeduction': instance.pharmacyCodeDeduction,
      'visaDeduction': instance.visaDeduction,
      'advanceDeduction': instance.advanceDeduction,
      'quarterlyShiftDeficitDeduction': instance.quarterlyShiftDeficitDeduction,
      'insuranceDeduction': instance.insuranceDeduction,
      'netSalary': instance.netSalary,
      'remainingAdvance': instance.remainingAdvance,
      'notes': instance.notes,
      'uploadedAt': const ServerNullableTimestampConverter().toJson(
        instance.uploadedAt,
      ),
      'uploadedBy': instance.uploadedBy,
    };
