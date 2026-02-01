// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'branch_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BranchModel _$BranchModelFromJson(Map<String, dynamic> json) => BranchModel(
  id: json['id'] as String,
  name: json['name'] as String,
  devices: (json['devices'] as List<dynamic>).map((e) => e as String).toList(),
  photoUrl: json['photoUrl'] as String?,
);

Map<String, dynamic> _$BranchModelToJson(BranchModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'devices': instance.devices,
      'photoUrl': instance.photoUrl,
    };
