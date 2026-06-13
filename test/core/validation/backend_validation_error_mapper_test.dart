import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/core/network/abp_error_response.dart';
import 'package:global_airsoft_app/src/core/network/api_exception.dart';
import 'package:global_airsoft_app/src/core/validation/backend_validation_error_mapper.dart';

void main() {
  const BackendValidationErrorMapper mapper = BackendValidationErrorMapper();

  test('maps aliases without considering case', () {
    final ValidationApiException exception = ValidationApiException(
      message: 'Validation failed',
      validationErrors: const <AbpValidationError>[
        AbpValidationError(
          message: 'Email is invalid',
          members: <String>['EMAIL'],
        ),
      ],
    );

    final ValidationMappingResult result = mapper.map(
      exception: exception,
      targetFields: const <String>{'EmailField'},
      memberAliases: const <String, String>{'EMAIL': 'EMAILFIELD'},
    );

    expect(result.fieldErrors, containsPair('EmailField', 'Email is invalid'));
    expect(result.globalErrors, isEmpty);
  });

  test('adds global error when some members are not mapped', () {
    final ValidationApiException exception = ValidationApiException(
      message: 'Validation failed',
      validationErrors: const <AbpValidationError>[
        AbpValidationError(
          message: 'Email combo is invalid',
          members: <String>['EMAIL', 'UNKNOWN_FIELD'],
        ),
      ],
    );

    final ValidationMappingResult result = mapper.map(
      exception: exception,
      targetFields: const <String>{'EmailField'},
      memberAliases: const <String, String>{'EMAIL': 'EMAILFIELD'},
    );

    expect(
      result.fieldErrors,
      containsPair('EmailField', 'Email combo is invalid'),
    );
    expect(result.globalErrors, contains('Email combo is invalid'));
  });
}
