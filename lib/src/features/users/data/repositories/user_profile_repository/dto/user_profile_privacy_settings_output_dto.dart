final class UserProfilePrivacySettingsOutputDto {
  const UserProfilePrivacySettingsOutputDto({required this.fullNameVisible});

  factory UserProfilePrivacySettingsOutputDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return UserProfilePrivacySettingsOutputDto(
      fullNameVisible: json['fullNameVisible'] == true,
    );
  }

  final bool fullNameVisible;
}
