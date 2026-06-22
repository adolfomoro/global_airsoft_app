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
import 'package:global_airsoft_app/src/core/widgets/app_snack_bar_presenter.dart';
import 'package:global_airsoft_app/src/core/widgets/form/app_button.dart';
import 'package:global_airsoft_app/src/core/widgets/form/app_form_padding.dart';
import 'package:global_airsoft_app/src/core/widgets/form/app_text_field.dart';
import 'package:global_airsoft_app/src/features/auth/data/exceptions/authentication_exception.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/request_password_recovery_input_dto.dart';
import 'package:global_airsoft_app/src/features/auth/domain/validation/email_validation.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/providers/password_recovery_form_providers.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/support/auth_presentation_extensions.dart';

class PasswordRecoveryPage extends ConsumerWidget {
  const PasswordRecoveryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppAdaptiveAppBar(
        title: Text(context.l10n.tr(AppLocaleKeys.authPasswordRecoveryTitle)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: AppFormPadding(
            padding: AppFormPadding.standardScrollablePagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: AppDimensions.spacingXl),
                _EmailFieldConsumer(),
                const SizedBox(height: AppDimensions.spacingXl),
                _SubmitButtonConsumer(),
                const SizedBox(height: AppDimensions.spacingXl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// EMAIL FIELD CONSUMER
// ============================================================================

class _EmailFieldConsumer extends ConsumerStatefulWidget {
  const _EmailFieldConsumer();

  @override
  ConsumerState<_EmailFieldConsumer> createState() => _EmailFieldConsumerState();
}

class _EmailFieldConsumerState extends ConsumerState<_EmailFieldConsumer> {
  late final TextEditingController _controller;

  static final ValidationRuleSet _emailValidationRules = EmailValidation.rules;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emailValue = ref.watch(passwordRecoveryEmailValueProvider);
    final emailError = ref.watch(passwordRecoveryEmailErrorProvider);
    final isSubmitting = ref.watch(passwordRecoveryIsSubmittingProvider);

    if (_controller.text != emailValue) {
      _controller.text = emailValue;
    }

    return AppTextField(
      labelText: context.l10n.tr(AppLocaleKeys.authEmailLabel),
      controller: _controller,
      errorText: emailError,
      onChanged: (value) {
        ref.read(passwordRecoveryEmailFieldProvider.notifier).setValue(value);
      },
      onFieldSubmitted: (_) {
        if (!isSubmitting) {
          _PasswordRecoverySubmissionLogic.submit(context, ref);
        }
      },
      isRequired: _emailValidationRules.hasRequiredRule,
      validator: _emailValidationRules.asValidator(
        context.resolveValidationMessage,
      ),
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.send,
      autofillHints: const <String>[AutofillHints.email],
    );
  }
}

// ============================================================================
// SUBMIT BUTTON CONSUMER
// ============================================================================

class _SubmitButtonConsumer extends ConsumerWidget {
  const _SubmitButtonConsumer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSubmitting = ref.watch(passwordRecoveryIsSubmittingProvider);
    final isEnabled = ref.watch(passwordRecoverySubmitEnabledProvider);

    return AppButton(
      label: context.l10n.tr(AppLocaleKeys.authPasswordRecoverySendAction),
      onPressed: !isEnabled ? null : () => _PasswordRecoverySubmissionLogic.submit(context, ref),
      isLoading: isSubmitting,
    );
  }
}

// ============================================================================
// SUBMISSION LOGIC
// ============================================================================

abstract final class _PasswordRecoverySubmissionLogic {
  static const BackendValidationErrorMapper _validationErrorMapper =
      BackendValidationErrorMapper();

  static Future<void> submit(BuildContext context, WidgetRef ref) async {
    FocusScope.of(context).unfocus();

    ref.read(passwordRecoveryEmailFieldProvider.notifier).clearError();
    ref.read(passwordRecoveryFormStateProvider.notifier).setError(null);

    final emailValid =
        ref.read(passwordRecoveryEmailFieldProvider.notifier).validate();

    if (!emailValid) {
      return;
    }

    final emailValue = ref.read(passwordRecoveryEmailValueProvider);

    ref.read(passwordRecoveryFormStateProvider.notifier).setSubmitting(true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.requestPasswordRecovery(emailValue.trim());

      if (!context.mounted) {
        return;
      }

      await Navigator.of(context).pushReplacementNamed(
        AppRoutePaths.passwordRecoverySuccess,
        arguments: emailValue.trim(),
      );
    } on AuthenticationException catch (error) {
      if (context.mounted) {
        final mappedErrors = _validationErrorMapper.map(
          exception: error.failure,
          targetFields: const <String>{
            RequestPasswordRecoveryInputDto.emailField,
          },
          memberAliases: const <String, String>{
            'email': RequestPasswordRecoveryInputDto.emailField,
          },
        );

        final emailFieldError =
            mappedErrors.fieldErrors[RequestPasswordRecoveryInputDto.emailField];

        if (emailFieldError != null) {
          ref.read(passwordRecoveryEmailFieldProvider.notifier).setError(emailFieldError);
        }

        final fallbackMessage =
            context.l10n.tr(AppLocaleKeys.authPasswordRecoveryFailed);
        final message = error.message ?? fallbackMessage;
        context.showErrorSnackBar(message, source: error.failure);
      }
    } catch (error, stackTrace) {
      AppLogger.instance.error(
        'Unexpected password recovery failure.',
        error: error,
        stackTrace: stackTrace,
      );
      if (context.mounted) {
        context.showLocalizedErrorSnackBar(AppLocaleKeys.authPasswordRecoveryFailed);
      }
    } finally {
      if (context.mounted) {
        ref.read(passwordRecoveryFormStateProvider.notifier).setSubmitting(false);
      }
    }
  }
}
