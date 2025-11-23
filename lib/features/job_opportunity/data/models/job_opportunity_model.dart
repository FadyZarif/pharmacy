import 'package:json_annotation/json_annotation.dart';
import '../../../../core/helpers/server_timestamp_helper.dart';

part 'job_opportunity_model.g.dart';

@JsonSerializable(explicitToJson: true)
class JobOpportunityModel {
  final String id;
  final String fullName;
  final String whatsappPhone;
  final String qualification;
  final String graduationYear;
  final String address;
  final String addedByEmployeeId;
  final String addedByEmployeeName;
  final String branchId;
  final String branchName;
  @ServerTimestampOnNullConverter()
  final DateTime? createdAt;

  JobOpportunityModel({
    required this.id,
    required this.fullName,
    required this.whatsappPhone,
    required this.qualification,
    required this.graduationYear,
    required this.address,
    required this.addedByEmployeeId,
    required this.addedByEmployeeName,
    required this.branchId,
    required this.branchName,
    this.createdAt,
  });

  factory JobOpportunityModel.fromJson(Map<String, dynamic> json) =>
      _$JobOpportunityModelFromJson(json);

  Map<String, dynamic> toJson() => _$JobOpportunityModelToJson(this);

  JobOpportunityModel copyWith({
    String? id,
    String? fullName,
    String? whatsappPhone,
    String? qualification,
    String? graduationYear,
    String? address,
    String? addedByEmployeeId,
    String? addedByEmployeeName,
    String? branchId,
    String? branchName,
    DateTime? createdAt,
  }) {
    return JobOpportunityModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      whatsappPhone: whatsappPhone ?? this.whatsappPhone,
      qualification: qualification ?? this.qualification,
      graduationYear: graduationYear ?? this.graduationYear,
      address: address ?? this.address,
      addedByEmployeeId: addedByEmployeeId ?? this.addedByEmployeeId,
      addedByEmployeeName: addedByEmployeeName ?? this.addedByEmployeeName,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

