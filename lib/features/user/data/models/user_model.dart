import 'package:json_annotation/json_annotation.dart';
import 'package:pharmacy/core/helpers/special_access.dart';

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
  final int overTimeMinutes;
  final int shiftHours;
  final Role role;
  final String? photoUrl;
  final bool isActive;
  final bool hasRequestsPermission;
  final bool hasExtendedManagementAccess;
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
    required this.overTimeMinutes,
    required this.shiftHours,
    required this.role,
    this.photoUrl,
    required this.isActive,
    this.fcmToken,
    this.hasRequestsPermission = false,
    this.hasExtendedManagementAccess = false,
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

  String get overTimeDisplay {
    final hours = overTimeMinutes ~/ 60;
    final minutes = overTimeMinutes % 60;
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

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

  /// Staff/sub-manager with admin-like screens: branch hub, bank, all-branches reports, profit collection.
  bool get hasSpecialManagementAccess =>
      hasExtendedManagementAccess || hasLegacySpecialManagementAccess(uid);
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