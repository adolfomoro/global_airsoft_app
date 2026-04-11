class AuthProfile {
  const AuthProfile({required this.userId, required this.username});

  final String userId;
  final String username;

  Map<String, dynamic> toJson() => {'userId': userId, 'username': username};

  factory AuthProfile.fromJson(Map<String, dynamic> json) => AuthProfile(
    userId: json['userId'] as String? ?? '',
    username: json['username'] as String? ?? '',
  );
}
