import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';
@JsonSerializable()
class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String email;
  final String? printCode;
  final String branchId;
  final String branchName;
  final int vocationBalanceHours;
  final int overTimeHours;
  final int shiftHours;
  final Role role;
  final String? photoUrl;
  final bool isActive;

  UserModel( {
    required this.uid,
    required this.name,
    required this.phone,
    required this.email,
    this.printCode,
    required this.branchId,
    required this.branchName,
    required this.vocationBalanceHours,
    required this.overTimeHours,
    required this.shiftHours,
    required this.role,
    this.photoUrl,
    required this.isActive,
  });

  /// fromJson & toJson
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  String get vocationBalance{
    final hours = vocationBalanceHours;
    final days = hours ~/ shiftHours;
    final remainingHours = hours % shiftHours;
    return '${days}d ${remainingHours}h';
  }
}

@JsonEnum(alwaysCreate: true)
enum Role {
  @JsonValue('admin')
  admin,

  @JsonValue('manager')
  manager,


  @JsonValue('subManager')
  subManager,

  @JsonValue('staff')
  staff,
}
