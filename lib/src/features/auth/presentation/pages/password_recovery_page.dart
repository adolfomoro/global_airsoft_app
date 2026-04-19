import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/routing/app_route_paths.dart';
import 'package:global_airsoft_app/src/app/widgets/app_adaptive_app_bar.dart';
import 'package:global_airsoft_app/src/app/widgets/app_button.dart';
import 'package:global_airsoft_app/src/app/widgets/app_text_field.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/validation/backend_validation_error_mapper.dart';
import 'package:global_airsoft_app/src/core/validation/validation.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_service.dart';
import 'package:global_airsoft_app/src/features/auth/data/exceptions/authentication_exception.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/request_password_recovery_input_dto.dart';
import 'package:global_airsoft_app/src/features/auth/domain/validation/email_validation.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/providers/auth_providers.dart';

class PasswordRecoveryPage extends ConsumerStatefulWidget {
  const PasswordRecoveryPage({super.key});

  @override
  ConsumerState<PasswordRecoveryPage> createState() =>
      _PasswordRecoveryPageState();
}

class _PasswordRecoveryPageState extends ConsumerState<PasswordRecoveryPage> {
  static const BackendValidationErrorMapper _validationErrorMapper =
      BackendValidationErrorMapper();
  static final ValidationRuleSet _emailValidationRules = EmailValidation.rules;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  String? _emailError;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleEmailChanged(String _) {
    if (_emailError == null) {
      return;
    }

    setState(() {
      _emailError = null;
    });
  }

  String _resolveValidationMessage(ValidationFailure failure) {
    final String selectedKey = switch (failure.messageKey) {
      AppLocaleKeys.validationMinLength => _pluralizedValidationKey(
        baseKey: AppLocaleKeys.validationMinLength,
        value: failure.arguments['min'],
      ),
      AppLocaleKeys.validationMaxLength => _pluralizedValidationKey(
        baseKey: AppLocaleKeys.validationMaxLength,
        value: failure.arguments['max'],
      ),
      _ => failure.messageKey,
    };

    return context.l10n.trArgs(selectedKey, args: failure.arguments);
  }

  String _pluralizedValidationKey({
    required String baseKey,
    required Object? value,
  }) {
    final int? numericValue;
    if (value is int) {
      numericValue = value;
    } else if (value is num) {
      numericValue = value.toInt();
    } else if (value is String) {
      numericValue = int.tryParse(value);
    } else {
      numericValue = null;
    }

    return AppLocaleKeys.withPluralSuffix(
      baseKey: baseKey,
      isSingular: numericValue == 1,
    );
  }

  Future<void> _handleRequestRecovery() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _emailError = null;
    });

    final FormState? formState = _formKey.currentState;
    if (!(formState?.validate() ?? false)) {
      return;
    }

    final String normalizedEmail = _emailController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      final AuthService authService = ref.read(authServiceProvider);
      await authService.requestPasswordRecovery(normalizedEmail);

      if (!mounted) {
        return;
      }

      await Navigator.of(context).pushReplacementNamed(
        AppRoutePaths.passwordRecoverySuccess,
        arguments: normalizedEmail,
      );
    } on AuthenticationException catch (error) {
      if (!mounted) {
        return;
      }

      final ValidationMappingResult mappedErrors = _validationErrorMapper.map(
        exception: error.failure,
        targetFields: const <String>{
          RequestPasswordRecoveryInputDto.emailField,
        },
        memberAliases: const <String, String>{
          'email': RequestPasswordRecoveryInputDto.emailField,
        },
      );

      setState(() {
        _emailError = mappedErrors
            .fieldErrors[RequestPasswordRecoveryInputDto.emailField];
      });

      final String fallbackMessage = context.l10n.tr(
        AppLocaleKeys.authPasswordRecoveryFailed,
      );
      final String message = error.message ?? fallbackMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (error, stackTrace) {
      AppLogger.instance.error(
        'Unexpected password recovery failure.',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.tr(AppLocaleKeys.authPasswordRecoveryFailed),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAdaptiveAppBar(
        title: Text(context.l10n.tr(AppLocaleKeys.authPasswordRecoveryTitle)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: 20),
                  Text(
                    context.l10n.tr(AppLocaleKeys.authPasswordRecoveryHeading),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.tr(AppLocaleKeys.authPasswordRecoverySubtitle),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  AppTextField(
                    labelText: context.l10n.tr(AppLocaleKeys.authEmailLabel),
                    controller: _emailController,
                    errorText: _emailError,
                    onChanged: _handleEmailChanged,
                    isRequired: _emailValidationRules.hasRequiredRule,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    prefixIcon: const Icon(Icons.mail_outline_rounded),
                    validator: _emailValidationRules.asValidator(
                      _resolveValidationMessage,
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: context.l10n.tr(
                      AppLocaleKeys.authPasswordRecoverySendAction,
                    ),
                    onPressed: _isLoading ? null : _handleRequestRecovery,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
