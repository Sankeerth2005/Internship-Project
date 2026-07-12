// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
  token: json['token'] as String,
  user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{'token': instance.token, 'user': instance.user};

UserDto _$UserDtoFromJson(Map<String, dynamic> json) => UserDto(
  id: json['id'] as String,
  name: json['name'] as String,
  email: json['email'] as String,
  userType: json['userType'] as String,
);

Map<String, dynamic> _$UserDtoToJson(UserDto instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'userType': instance.userType,
};
