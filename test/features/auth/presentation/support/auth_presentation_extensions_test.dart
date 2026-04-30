import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/core/validation/validation_mapping_result.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/support/auth_presentation_extensions.dart';

void main() {
  test('returns the first non-empty global error', () {
    const ValidationMappingResult result = ValidationMappingResult(
      fieldErrors: <String, String>{},
      globalErrors: <String>['  ', '', 'Primary error', 'Secondary error'],
    );

    expect(result.firstMeaningfulGlobalError, 'Primary error');
  });

  test('returns null when all global errors are empty', () {
    const ValidationMappingResult result = ValidationMappingResult(
      fieldErrors: <String, String>{},
      globalErrors: <String>['', '   '],
    );

    expect(result.firstMeaningfulGlobalError, isNull);
  });
}
