final class UserProfileOutputDto {
  const UserProfileOutputDto({
    required this.id,
    required this.userName,
    required this.fullName,
    required this.bio,
  });

  final String id;
  final String userName;
  final String? fullName;
  final String? bio;

  factory UserProfileOutputDto.fromJson(Map<String, dynamic> json) {
    return UserProfileOutputDto(
      id: (json['id'] as String?) ?? '',
      userName:
          (json['userName'] as String?) ?? (json['username'] as String?) ?? '',
      fullName: json['fullName'] as String?,
      bio: json['bio'] as String?,
    );
  }
}
