sealed class AppFailure {
  const AppFailure({required this.message});

  final String message;
}

final class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure({required super.message, this.cause});

  final Object? cause;
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure({required super.message});
}
