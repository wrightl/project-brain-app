// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth0_roles.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Auth0Role _$Auth0RoleFromJson(Map<String, dynamic> json) => Auth0Role(
      id: json['id'] as String,
      name: $enumDecode(_$RoleEnumMap, json['name']),
      description: json['description'] as String,
    );

Map<String, dynamic> _$Auth0RoleToJson(Auth0Role instance) => <String, dynamic>{
      'id': instance.id,
      'name': _$RoleEnumMap[instance.name]!,
      'description': instance.description,
    };

const _$RoleEnumMap = {
  Role.employee: 'employee',
  Role.admin: 'admin',
  Role.customer: 'customer',
};
