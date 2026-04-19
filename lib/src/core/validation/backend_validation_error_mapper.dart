import 'package:global_airsoft_app/src/core/network/abp_error_response.dart';
import 'package:global_airsoft_app/src/core/network/api_exception.dart';
import 'package:global_airsoft_app/src/core/validation/validation_mapping_result.dart';

export 'package:global_airsoft_app/src/core/validation/validation_mapping_result.dart';

final class BackendValidationErrorMapper {
  const BackendValidationErrorMapper();

  static final RegExp _arrayIndexPattern = RegExp(r'\[\d+\]');

  ValidationMappingResult map({
    required ApiException exception,
    required Set<String> targetFields,
    Map<String, String> memberAliases = const <String, String>{},
  }) {
    final Map<String, String> fieldErrors = <String, String>{};
    final List<String> globalErrors = <String>[];

    final Set<String> normalizedTargetFields = targetFields
        .map(_normalizeFieldKey)
        .toSet();
    final Map<String, String> normalizedAliases = <String, String>{
      for (final MapEntry<String, String> entry in memberAliases.entries)
        _normalizeFieldKey(entry.key): _normalizeFieldKey(entry.value),
    };

    final bool isValidationException = exception is ValidationApiException;
    if (!isValidationException) {
      globalErrors.add(exception.message);
    }

    for (final AbpValidationError validationError
        in exception.validationErrors) {
      if (validationError.members.isEmpty) {
        globalErrors.add(validationError.message);
        continue;
      }

      bool mappedToAnyField = false;

      for (final String member in validationError.members) {
        final String normalizedMember = _normalizeMember(member);
        final String targetKey =
            normalizedAliases[normalizedMember] ?? normalizedMember;

        if (!normalizedTargetFields.contains(targetKey)) {
          continue;
        }

        fieldErrors.putIfAbsent(targetKey, () => validationError.message);
        mappedToAnyField = true;
      }

      if (!mappedToAnyField) {
        globalErrors.add(validationError.message);
      }
    }

    return ValidationMappingResult(
      fieldErrors: fieldErrors,
      globalErrors: globalErrors,
    );
  }

  String _normalizeMember(String member) {
    final String cleaned = member
        .trim()
        .replaceAll(_arrayIndexPattern, '')
        .replaceAll('/', '.')
        .replaceAll('\\', '.');

    if (cleaned.isEmpty) {
      return cleaned;
    }

    final List<String> parts = cleaned
        .split('.')
        .map((String part) => part.trim())
        .where((String part) => part.isNotEmpty)
        .toList(growable: false);

    if (parts.isEmpty) {
      return '';
    }

    return _normalizeFieldKey(parts.last);
  }

  String _normalizeFieldKey(String value) {
    return value.trim().toLowerCase();
  }
}
