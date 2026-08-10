// GENERATED MANUALLY to match json_serializable output style.
// ignore_for_file: type=lint

part of 'authorized_experiences.dart';

AuthorizedExperiencesDto _$AuthorizedExperiencesDtoFromJson(
        Map<String, dynamic> json) =>
    AuthorizedExperiencesDto(
      accountType: json['accountType'] as String? ?? '',
      authorizedExperiences: (json['authorizedExperiences'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      canContinueAsUser: json['canContinueAsUser'] as bool? ?? false,
      canContinueAsBusinessOwner:
          json['canContinueAsBusinessOwner'] as bool? ?? false,
      canRegisterBusiness: json['canRegisterBusiness'] as bool? ?? false,
    );

Map<String, dynamic> _$AuthorizedExperiencesDtoToJson(
        AuthorizedExperiencesDto instance) =>
    <String, dynamic>{
      'accountType': instance.accountType,
      'authorizedExperiences': instance.authorizedExperiences,
      'canContinueAsUser': instance.canContinueAsUser,
      'canContinueAsBusinessOwner': instance.canContinueAsBusinessOwner,
      'canRegisterBusiness': instance.canRegisterBusiness,
    };

SelectExperienceResultDto _$SelectExperienceResultDtoFromJson(
        Map<String, dynamic> json) =>
    SelectExperienceResultDto(
      allowed: json['allowed'] as bool? ?? false,
      experience: json['experience'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      message: json['message'] as String?,
    );

Map<String, dynamic> _$SelectExperienceResultDtoToJson(
        SelectExperienceResultDto instance) =>
    <String, dynamic>{
      'allowed': instance.allowed,
      'experience': instance.experience,
      'destination': instance.destination,
      'message': instance.message,
    };
