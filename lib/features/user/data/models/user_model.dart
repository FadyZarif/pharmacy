import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';
@JsonSerializable(explicitToJson: true)
class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String email;
  final String? printCode;
  final List<Branch> branches;
  @JsonKey(includeFromJson: false, includeToJson: false)
  Branch currentBranch = Branch(id: '', name: '');
  final int vocationBalanceMinutes;
  final int overTimeHours;
  final int shiftHours;
  final Role role;
  final String? photoUrl;
  final bool isActive;
  final bool hasRequestsPermission;
  final String? fcmToken;

  UserModel( {
    required this.uid,
    required this.name,
    required this.phone,
    required this.email,
    this.printCode,
    required this.branches,
    required this.vocationBalanceMinutes,
    required this.overTimeHours,
    required this.shiftHours,
    required this.role,
    this.photoUrl,
    required this.isActive,
    this.fcmToken,
    this.hasRequestsPermission = false,
  });

  /// fromJson & toJson
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final user = _$UserModelFromJson(json);
    if(user.role == Role.staff || user.role == Role.subManager){
      user.currentBranch = user.branches.first;
    }

    return user;
  }

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  String get vocationBalance{
    final totalMinutes = vocationBalanceMinutes;
    final shiftMinutes = shiftHours * 60;
    final days = totalMinutes ~/ shiftMinutes;
    final remainingMinutes = totalMinutes % shiftMinutes;
    final hours = remainingMinutes ~/ 60;
    final minutes = remainingMinutes % 60;
    return '${days}d ${hours}h ${minutes}m';
  }

  bool get isManagement{
    return role == Role.admin || role == Role.manager;
  }

  bool get isAdmin{
    return role == Role.admin;
  }

  bool get isStaff{
    return role == Role.staff ;
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

@JsonSerializable()
class Branch {
  final String id;
    final String name;


  Branch({
    required this.id,
    required this.name,
  });
  /// fromJson & toJson
  factory Branch.fromJson(Map<String, dynamic> json) => _$BranchFromJson(json);
  Map<String, dynamic> toJson() => _$BranchToJson(this);

}