import 'package:json_annotation/json_annotation.dart';

part 'login_request.g.dart';

@JsonSerializable()
class LoginRequest {
  @JsonKey(name: 'usernameOrEmail')
  final String usernameOrEmail;
  @JsonKey(name: 'password')
  final String password;
  @JsonKey(name: 'captchaToken')
  final String captchaToken;

  LoginRequest({
    required this.usernameOrEmail,
    required this.password,
    required this.captchaToken,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}
