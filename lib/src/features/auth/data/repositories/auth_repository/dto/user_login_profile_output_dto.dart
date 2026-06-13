final class UserLoginProfileOutputDto {
  const UserLoginProfileOutputDto({required this.id, required this.username});

  final String id;
  final String username;

  factory UserLoginProfileOutputDto.fromJson(Map<String, dynamic> json) {
    return UserLoginProfileOutputDto(
      id: (json['id'] as String?) ?? '',
      username: (json['username'] as String?) ?? '',
    );
  }

  Map<String, String> toJson() {
    return <String, String>{'id': id, 'username': username};
  }
}
