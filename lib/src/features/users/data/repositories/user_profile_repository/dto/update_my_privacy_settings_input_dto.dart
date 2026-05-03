final class UpdateMyPrivacySettingsInputDto {
  const UpdateMyPrivacySettingsInputDto({required this.fullNameVisible});

  final bool fullNameVisible;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'fullNameVisible': fullNameVisible};
  }
}
