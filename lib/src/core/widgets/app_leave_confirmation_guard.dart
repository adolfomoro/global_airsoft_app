import 'dart:async';

import 'package:flutter/material.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/widgets/app_confirmation_dialog.dart';

enum AppLeaveConfirmationBehavior { whenChanged, always }

final class AppLeaveConfirmationController {
  _PendingLeaveBypassRequest? _pendingBypassRequest;

  Future<bool> dismiss<T extends Object?>(BuildContext context, [T? result]) {
    _pendingBypassRequest = _PendingLeaveBypassRequest(result: result);
    return Navigator.of(context).maybePop<T>(result);
  }

  _PendingLeaveBypassRequest? _takePendingBypassRequest() {
    final _PendingLeaveBypassRequest? request = _pendingBypassRequest;
    _pendingBypassRequest = null;
    return request;
  }
}

final class AppLeaveConfirmationGuard extends StatefulWidget {
  const AppLeaveConfirmationGuard({
    required this.child,
    required this.hasUnsavedChanges,
    super.key,
    this.controller,
    this.behavior = AppLeaveConfirmationBehavior.whenChanged,
    this.enabled = true,
    this.title,
    this.message,
    this.confirmLabel,
    this.cancelLabel,
  });

  final Widget child;
  final bool hasUnsavedChanges;
  final AppLeaveConfirmationController? controller;
  final AppLeaveConfirmationBehavior behavior;
  final bool enabled;
  final String? title;
  final String? message;
  final String? confirmLabel;
  final String? cancelLabel;

  @override
  State<AppLeaveConfirmationGuard> createState() =>
      _AppLeaveConfirmationGuardState();
}

final class _AppLeaveConfirmationGuardState
    extends State<AppLeaveConfirmationGuard> {
  bool _allowNextPop = false;
  bool _isHandlingPop = false;

  AppLeaveConfirmationController get _controller =>
      widget.controller ?? _fallbackController;
  final AppLeaveConfirmationController _fallbackController =
      AppLeaveConfirmationController();

  bool get _shouldConfirmExit {
    if (!widget.enabled) {
      return false;
    }

    return switch (widget.behavior) {
      AppLeaveConfirmationBehavior.whenChanged => widget.hasUnsavedChanges,
      AppLeaveConfirmationBehavior.always => true,
    };
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowNextPop || !_shouldConfirmExit,
      onPopInvokedWithResult: _handlePopInvoked,
      child: widget.child,
    );
  }

  void _handlePopInvoked(bool didPop, Object? result) {
    if (didPop || _isHandlingPop) {
      return;
    }

    unawaited(_handlePendingPop());
  }

  Future<void> _handlePendingPop() async {
    _isHandlingPop = true;

    try {
      final _PendingLeaveBypassRequest? bypassRequest = _controller
          ._takePendingBypassRequest();
      if (bypassRequest != null || !_shouldConfirmExit) {
        await _popWithBypass(result: bypassRequest?.result);
        return;
      }

      final bool shouldLeave = await AppConfirmationDialog.show(
        context: context,
        title:
            widget.title ??
            context.l10n.tr(AppLocaleKeys.commonDiscardChangesTitle),
        message:
            widget.message ??
            context.l10n.tr(AppLocaleKeys.commonDiscardChangesMessage),
        confirmLabel:
            widget.confirmLabel ??
            context.l10n.tr(AppLocaleKeys.commonDiscardChangesAction),
        cancelLabel:
            widget.cancelLabel ??
            context.l10n.tr(AppLocaleKeys.commonKeepEditing),
        isDestructive: true,
      );

      if (!shouldLeave || !mounted) {
        return;
      }

      await _popWithBypass();
    } finally {
      _isHandlingPop = false;
    }
  }

  Future<void> _popWithBypass({Object? result}) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _allowNextPop = true;
    });

    Navigator.of(context).pop(result);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _allowNextPop = false;
      });
    });
  }
}

final class _PendingLeaveBypassRequest {
  const _PendingLeaveBypassRequest({this.result});

  final Object? result;
}
