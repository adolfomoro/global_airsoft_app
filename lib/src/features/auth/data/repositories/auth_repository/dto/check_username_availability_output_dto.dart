final class CheckUsernameAvailabilityOutputDto {
  const CheckUsernameAvailabilityOutputDto({
    required this.userName,
    required this.isAvailable,
    required this.suggestions,
  });

  final String userName;
  final bool isAvailable;
  final List<String> suggestions;

  factory CheckUsernameAvailabilityOutputDto.fromJson(
    Map<String, dynamic> json,
  ) {
    final Object? rawSuggestions = json['suggestions'] ?? json['Suggestions'];

    return CheckUsernameAvailabilityOutputDto(
      userName:
          (json['userName'] as String?) ?? (json['UserName'] as String?) ?? '',
      isAvailable:
          (json['isAvailable'] as bool?) ??
          (json['IsAvailable'] as bool?) ??
          false,
      suggestions: rawSuggestions is List
          ? rawSuggestions
                .whereType<String>()
                .where((String suggestion) => suggestion.trim().isNotEmpty)
                .toList(growable: false)
          : const <String>[],
    );
  }
}
