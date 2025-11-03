// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  uid: json['uid'] as String,
  name: json['name'] as String,
  phone: json['phone'] as String,
  email: json['email'] as String,
  printCode: json['printCode'] as String?,
  branchId: json['branchId'] as String,
  branchName: json['branchName'] as String,
  vocationBalanceHours: (json['vocationBalanceHours'] as num).toInt(),
  overTimeHours: (json['overTimeHours'] as num).toInt(),
  shiftHours: (json['shiftHours'] as num).toInt(),
  role: $enumDecode(_$RoleEnumMap, json['role']),
  photoUrl: json['photoUrl'] as String?,
  isActive: json['isActive'] as bool,
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'uid': instance.uid,
  'name': instance.name,
  'phone': instance.phone,
  'email': instance.email,
  'printCode': instance.printCode,
  'branchId': instance.branchId,
  'branchName': instance.branchName,
  'vocationBalanceHours': instance.vocationBalanceHours,
  'overTimeHours': instance.overTimeHours,
  'shiftHours': instance.shiftHours,
  'role': _$RoleEnumMap[instance.role]!,
  'photoUrl': instance.photoUrl,
  'isActive': instance.isActive,
};

const _$RoleEnumMap = {
  Role.admin: 'admin',
  Role.manager: 'manager',
  Role.subManager: 'subManager',
  Role.staff: 'staff',
};
