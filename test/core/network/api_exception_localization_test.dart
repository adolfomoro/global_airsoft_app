import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/core/network/app_dio_service.dart';
import 'package:global_airsoft_app/src/core/localization/app_localization_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('builds localized generic Dio messages for pt-BR', () async {
    final AppLocalizationService localizationService = AppLocalizationService(
      locale: const Locale('pt', 'BR'),
    );

    final localizedMessages = await buildLocalizedApiExceptionMessages(
      localizationService,
    );

    expect(
      localizedMessages.connectionErrorMessage,
      'Ocorreu um erro. Tente novamente mais tarde.',
    );
    expect(
      localizedMessages.requestCancelledMessage,
      'Ocorreu um erro. Tente novamente mais tarde.',
    );
    expect(
      localizedMessages.badResponseFallbackMessage,
      'Ocorreu um erro. Tente novamente mais tarde.',
    );
    expect(
      localizedMessages.validationErrorMessage,
      'Revise as informacoes preenchidas.',
    );
  });
}
