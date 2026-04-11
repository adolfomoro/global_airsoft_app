final class ValidationFailure {
  const ValidationFailure({
    required this.messageKey,
    this.arguments = const <String, Object?>{},
  });

  final String messageKey;
  final Map<String, Object?> arguments;
}
