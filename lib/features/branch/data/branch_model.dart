import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'branch_model.g.dart';
@JsonSerializable()
class BranchModel extends Equatable{
  final String id;
  final String name;
  final List<String> devices;
  final String? photoUrl;

  const BranchModel({
    required this.id,
    required this.name,
    required this.devices,
    this.photoUrl,
  });

  @override
  // TODO: implement props
  List<Object> get props => [id,name,devices];

  /// fromJson & toJson
  factory BranchModel.fromJson(Map<String, dynamic> json) =>
      _$BranchModelFromJson(json);

  Map<String, dynamic> toJson() => _$BranchModelToJson(this);




}

