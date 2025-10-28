
import 'package:json_annotation/json_annotation.dart';

import '../../../../core/helpers/server_timestamp_helper.dart';

part 'repair_model.g.dart';

@JsonSerializable()
class RepairModel {
  final String id;
  final String deviceName;
  final String notes;
  final String employeeName;
  final String employeeId;
  final String branchId;
  final String branchName;
  @ServerTimestampOnNullConverter()
  final DateTime? createdAt;

  RepairModel({required this.id, required this.deviceName, required this.notes,required this.employeeName,required this.employeeId,required this.branchId,required this.branchName, required this.createdAt});

  /// fromJson & toJson
  factory RepairModel.fromJson(Map<String, dynamic> json) =>
      _$RepairModelFromJson(json);

  Map<String, dynamic> toJson() => _$RepairModelToJson(this);


}