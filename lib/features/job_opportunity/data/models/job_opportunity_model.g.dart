// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_opportunity_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JobOpportunityModel _$JobOpportunityModelFromJson(Map<String, dynamic> json) =>
    JobOpportunityModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      whatsappPhone: json['whatsappPhone'] as String,
      qualification: json['qualification'] as String,
      graduationYear: json['graduationYear'] as String,
      address: json['address'] as String,
      addedByEmployeeId: json['addedByEmployeeId'] as String,
      addedByEmployeeName: json['addedByEmployeeName'] as String,
      branchId: json['branchId'] as String,
      branchName: json['branchName'] as String,
      createdAt: const ServerTimestampOnNullConverter().fromJson(
        json['createdAt'],
      ),
    );

Map<String, dynamic> _$JobOpportunityModelToJson(
  JobOpportunityModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'fullName': instance.fullName,
  'whatsappPhone': instance.whatsappPhone,
  'qualification': instance.qualification,
  'graduationYear': instance.graduationYear,
  'address': instance.address,
  'addedByEmployeeId': instance.addedByEmployeeId,
  'addedByEmployeeName': instance.addedByEmployeeName,
  'branchId': instance.branchId,
  'branchName': instance.branchName,
  'createdAt': const ServerTimestampOnNullConverter().toJson(
    instance.createdAt,
  ),
};
