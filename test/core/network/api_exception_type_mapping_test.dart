import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/core/network/abp_error_response.dart';
import 'package:global_airsoft_app/src/core/network/api_exception.dart';

void main() {
  test(
    'maps 400 responses without validation errors to UserFriendlyApiException',
    () {
      final ApiException exception = const ApiException(
        message: 'Business rule violation.',
        statusCode: 400,
      ).toTypedException();

      expect(exception, isA<UserFriendlyApiException>());
    },
  );

  test(
    'keeps 400 responses with validation errors as ValidationApiException',
    () {
      final ApiException exception = const ApiException(
        message: 'Validation failed.',
        statusCode: 400,
        validationErrors: <AbpValidationError>[
          AbpValidationError(
            message: 'Field is required.',
            members: <String>['field'],
          ),
        ],
      ).toTypedException();

      expect(exception, isA<ValidationApiException>());
    },
  );
}
