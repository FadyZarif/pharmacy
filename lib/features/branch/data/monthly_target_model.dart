import 'package:json_annotation/json_annotation.dart';

part 'monthly_target_model.g.dart';

@JsonSerializable()
class MonthlyTargetModel {
  final String monthYear; // Format: "2025-11"
  final int monthlyTarget;

  const MonthlyTargetModel({
    required this.monthYear,
    required this.monthlyTarget,
  });

  factory MonthlyTargetModel.fromJson(Map<String, dynamic> json) =>
      _$MonthlyTargetModelFromJson(json);

  Map<String, dynamic> toJson() => _$MonthlyTargetModelToJson(this);
}

