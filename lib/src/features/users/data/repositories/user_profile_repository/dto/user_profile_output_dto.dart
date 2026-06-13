class UserProfileOutputDto {
  const UserProfileOutputDto({
    required this.id,
    required this.userName,
    this.fullName,
    this.bio,
  });

  factory UserProfileOutputDto.fromJson(Map<String, dynamic> json) {
    return UserProfileOutputDto(
      id: (json['id'] as String?)?.trim() ?? '',
      userName: (json['userName'] as String?)?.trim() ?? '',
      fullName: (json['fullName'] as String?)?.trim(),
      bio: (json['bio'] as String?)?.trim(),
    );
  }

  final String id;
  final String userName;
  final String? fullName;
  final String? bio;
}
