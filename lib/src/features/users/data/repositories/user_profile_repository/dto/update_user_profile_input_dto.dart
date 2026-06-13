final class UpdateUserProfileInputDto {
  const UpdateUserProfileInputDto({required this.fullName, required this.bio});

  static const String fullNameField = 'fullName';
  static const String bioField = 'bio';

  final String fullName;
  final String? bio;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{fullNameField: fullName, bioField: bio};
  }
}
