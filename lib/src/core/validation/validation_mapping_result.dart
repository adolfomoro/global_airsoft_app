final class ValidationMappingResult {
  const ValidationMappingResult({
    required this.fieldErrors,
    required this.globalErrors,
  });

  final Map<String, String> fieldErrors;
  final List<String> globalErrors;

  bool get hasFieldErrors => fieldErrors.isNotEmpty;
}
