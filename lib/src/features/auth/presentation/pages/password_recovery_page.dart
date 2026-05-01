import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/routing/app_route_paths.dart';
import 'package:global_airsoft_app/src/app/theme/app_dimensions.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/localization/app_validation_localizations.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/validation/backend_validation_error_mapper.dart';
import 'package:global_airsoft_app/src/core/validation/validation.dart';
import 'package:global_airsoft_app/src/core/widgets/app_bar/app_adaptive_app_bar.dart';
import 'package:global_airsoft_app/src/core/widgets/app_bar/app_page_header.dart';
import 'package:global_airsoft_app/src/core/widgets/app_snack_bar_presenter.dart';
import 'package:global_airsoft_app/src/core/widgets/form/app_button.dart';
import 'package:global_airsoft_app/src/core/widgets/form/app_text_field.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_service.dart';
import 'package:global_airsoft_app/src/features/auth/data/exceptions/authentication_exception.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/request_password_recovery_input_dto.dart';
import 'package:global_airsoft_app/src/features/auth/domain/validation/email_validation.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/support/auth_form_submission_mixin.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/support/auth_presentation_extensions.dart';

class PasswordRecoveryPage extends ConsumerStatefulWidget {
  const PasswordRecoveryPage({super.key});

  @override
  ConsumerState<PasswordRecoveryPage> createState() =>
      _PasswordRecoveryPageState();
}

class _PasswordRecoveryPageState extends ConsumerState<PasswordRecoveryPage>
    with AuthFormSubmissionMixin<PasswordRecoveryPage> {
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

  Future<void> _submitPasswordRecovery() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _emailError = null;
    });

    if (!validateSubmittedForm(_formKey)) {
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
      context.showErrorSnackBar(message, source: error.failure);
    } catch (error, stackTrace) {
      AppLogger.instance.error(
        'Unexpected password recovery failure.',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) {
        return;
      }

      context.showLocalizedErrorSnackBar(
        AppLocaleKeys.authPasswordRecoveryFailed,
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
            autovalidateMode: formAutovalidateMode,
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacing2xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: AppDimensions.spacingXl),
                  AppPageHeader(
                    title: context.l10n.tr(
                      AppLocaleKeys.authPasswordRecoveryHeading,
                    ),
                    subtitle: context.l10n.tr(
                      AppLocaleKeys.authPasswordRecoverySubtitle,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacing2xl),
                  AppTextField(
                    labelText: context.l10n.tr(AppLocaleKeys.authEmailLabel),
                    controller: _emailController,
                    errorText: _emailError,
                    onChanged: _handleEmailChanged,
                    onFieldSubmitted: (_) {
                      if (_isLoading) {
                        return;
                      }

                      unawaited(_submitPasswordRecovery());
                    },
                    isRequired: _emailValidationRules.hasRequiredRule,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    prefixIcon: const Icon(Icons.mail_outline_rounded),
                    validator: _emailValidationRules.asValidator(
                      context.resolveValidationMessage,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacing2xl),
                  AppButton(
                    label: context.l10n.tr(
                      AppLocaleKeys.authPasswordRecoverySendAction,
                    ),
                    onPressed: _isLoading ? null : _submitPasswordRecovery,
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
