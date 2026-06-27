import 'dart:async';

import 'package:flutter/material.dart';
import 'package:global_airsoft_app/src/app/theme/app_colors.dart';
import 'package:global_airsoft_app/src/app/theme/app_dimensions.dart';
import 'package:global_airsoft_app/src/core/network/api_exception_diagnostics.dart';

enum AppSnackBarVariant { info, success, warning, error }

final class AppSnackBarPresenter {
  AppSnackBarPresenter._();

  static const Duration defaultDuration = Duration(seconds: 4);
  static const Duration errorDuration = Duration(seconds: 5);
  static const Duration _cupertinoTransitionDuration = Duration(
    milliseconds: 220,
  );
  static const EdgeInsets _androidInset = EdgeInsets.fromLTRB(16, 8, 16, 18);
  static const EdgeInsets _cupertinoInset = EdgeInsets.fromLTRB(12, 8, 12, 0);

  static _CupertinoNotificationHandle? _activeCupertinoNotification;
  static final List<_CupertinoNotificationRequest>
  _pendingCupertinoNotifications = <_CupertinoNotificationRequest>[];

  static bool showInfo(
    BuildContext context,
    String message, {
    Duration duration = defaultDuration,
    bool replaceCurrent = true,
  }) {
    return _show(
      context,
      message,
      variant: AppSnackBarVariant.info,
      duration: duration,
      replaceCurrent: replaceCurrent,
    );
  }

  static bool showSuccess(
    BuildContext context,
    String message, {
    Duration duration = defaultDuration,
    bool replaceCurrent = true,
  }) {
    return _show(
      context,
      message,
      variant: AppSnackBarVariant.success,
      duration: duration,
      replaceCurrent: replaceCurrent,
    );
  }

  static bool showWarning(
    BuildContext context,
    String message, {
    Duration duration = defaultDuration,
    bool replaceCurrent = true,
  }) {
    return _show(
      context,
      message,
      variant: AppSnackBarVariant.warning,
      duration: duration,
      replaceCurrent: replaceCurrent,
    );
  }

  static bool showError(
    BuildContext context,
    String message, {
    Duration duration = errorDuration,
    bool replaceCurrent = true,
    Object? source,
  }) {
    final apiException = ApiExceptionDiagnostics.extractApiException(source);
    if (apiException?.suppressesDuplicatePresentation ?? false) {
      return false;
    }

    return _show(
      context,
      ApiExceptionDiagnostics.formatMessageForDisplay(message, source: source),
      variant: AppSnackBarVariant.error,
      duration: duration,
      replaceCurrent: replaceCurrent,
    );
  }

  static bool _show(
    BuildContext context,
    String message, {
    required AppSnackBarVariant variant,
    required Duration duration,
    required bool replaceCurrent,
  }) {
    final String normalizedMessage = message.trim();
    if (normalizedMessage.isEmpty) {
      return false;
    }

    final ThemeData theme = Theme.of(context);
    final _NotificationPalette palette = _resolvePalette(
      theme.colorScheme,
      variant,
    );
    final _NotificationTextStyleSet textStyles = _resolveTextStyles(
      theme,
      palette,
    );

    if (_isCupertinoPlatform(theme.platform)) {
      return _showCupertinoNotification(
        context,
        message: normalizedMessage,
        duration: duration,
        replaceCurrent: replaceCurrent,
        palette: palette,
        textStyle: textStyles.cupertinoMessageStyle,
      );
    }

    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
      context,
    );
    if (messenger == null) {
      return false;
    }

    if (replaceCurrent) {
      messenger.hideCurrentMaterialBanner();
      messenger.hideCurrentSnackBar();
      _dismissActiveCupertinoNotification(clearQueue: true);
    }

    _showAndroidSnackBar(
      messenger,
      message: normalizedMessage,
      duration: duration,
      palette: palette,
      textStyle: textStyles.androidMessageStyle,
    );
    return true;
  }

  static bool _showCupertinoNotification(
    BuildContext context, {
    required String message,
    required Duration duration,
    required bool replaceCurrent,
    required _NotificationPalette palette,
    required TextStyle textStyle,
  }) {
    final OverlayState? overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      return false;
    }

    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
      context,
    );
    messenger?.hideCurrentSnackBar();
    messenger?.hideCurrentMaterialBanner();

    final _CupertinoNotificationRequest request = _CupertinoNotificationRequest(
      overlay: overlay,
      message: message,
      duration: duration,
      palette: palette,
      textStyle: textStyle,
    );

    if (replaceCurrent) {
      _pendingCupertinoNotifications
        ..clear()
        ..add(request);
      _dismissActiveCupertinoNotification();
      if (_activeCupertinoNotification == null) {
        _showNextCupertinoNotification();
      }
      return true;
    }

    if (_activeCupertinoNotification != null) {
      _pendingCupertinoNotifications.add(request);
      return true;
    }

    _presentCupertinoNotification(request);
    return true;
  }

  static void _showAndroidSnackBar(
    ScaffoldMessengerState messenger, {
    required String message,
    required Duration duration,
    required _NotificationPalette palette,
    required TextStyle textStyle,
  }) {
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.transparent,
        elevation: 0,
        margin: _androidInset,
        padding: EdgeInsets.zero,
        duration: duration,
        dismissDirection: DismissDirection.horizontal,
        clipBehavior: Clip.none,
        content: _AndroidNotificationCard(
          message: message,
          palette: palette,
          textStyle: textStyle,
        ),
      ),
    );
  }

  static void _presentCupertinoNotification(
    _CupertinoNotificationRequest request,
  ) {
    if (!request.overlay.mounted) {
      _showNextCupertinoNotification();
      return;
    }

    late final _CupertinoNotificationHandle handle;
    handle = _CupertinoNotificationHandle(
      overlay: request.overlay,
      duration: request.duration,
      onClosed: () {
        if (identical(_activeCupertinoNotification, handle)) {
          _activeCupertinoNotification = null;
        }
        _showNextCupertinoNotification();
      },
      builder: (bool isVisible, VoidCallback dismiss) {
        return _CupertinoNotificationOverlay(
          isVisible: isVisible,
          message: request.message,
          palette: request.palette,
          textStyle: request.textStyle,
          onDismiss: dismiss,
        );
      },
    );

    _activeCupertinoNotification = handle;
    handle.show();
  }

  static void _showNextCupertinoNotification() {
    while (_pendingCupertinoNotifications.isNotEmpty) {
      final _CupertinoNotificationRequest nextRequest =
          _pendingCupertinoNotifications.removeAt(0);
      if (!nextRequest.overlay.mounted) {
        continue;
      }

      _presentCupertinoNotification(nextRequest);
      return;
    }
  }

  static void _dismissActiveCupertinoNotification({bool clearQueue = false}) {
    if (clearQueue) {
      _pendingCupertinoNotifications.clear();
    }

    final _CupertinoNotificationHandle? active = _activeCupertinoNotification;
    if (active == null) {
      return;
    }

    active.dismiss();
  }

  static bool _isCupertinoPlatform(TargetPlatform platform) {
    return platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
  }

  static _NotificationTextStyleSet _resolveTextStyles(
    ThemeData theme,
    _NotificationPalette palette,
  ) {
    final TextStyle fallbackBaseStyle = TextStyle(
      color: palette.foregroundColor,
      fontSize: 15,
      fontWeight: FontWeight.w500,
      height: 1.3,
    );
    final TextStyle baseTextStyle =
        theme.snackBarTheme.contentTextStyle?.copyWith(
          color: palette.foregroundColor,
        ) ??
        theme.textTheme.bodyMedium?.copyWith(color: palette.foregroundColor) ??
        fallbackBaseStyle;

    return _NotificationTextStyleSet(
      androidMessageStyle: baseTextStyle.copyWith(
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      cupertinoMessageStyle: baseTextStyle.copyWith(
        fontWeight: FontWeight.w500,
        height: 1.28,
      ),
    );
  }

  static _NotificationPalette _resolvePalette(
    ColorScheme colorScheme,
    AppSnackBarVariant variant,
  ) {
    return switch (variant) {
      AppSnackBarVariant.info => _NotificationPalette(
        backgroundColor: colorScheme.secondaryContainer,
        foregroundColor: colorScheme.onSecondaryContainer,
        accentColor: AppColors.info,
        borderColor: AppColors.info.withValues(alpha: 0.28),
        iconData: Icons.info_outline_rounded,
      ),
      AppSnackBarVariant.success => _NotificationPalette(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        accentColor: AppColors.success,
        borderColor: AppColors.success.withValues(alpha: 0.24),
        iconData: Icons.check_circle_outline_rounded,
      ),
      AppSnackBarVariant.warning => _NotificationPalette(
        backgroundColor: colorScheme.tertiaryContainer,
        foregroundColor: colorScheme.onTertiaryContainer,
        accentColor: AppColors.warning,
        borderColor: AppColors.warning.withValues(alpha: 0.28),
        iconData: Icons.warning_amber_rounded,
      ),
      AppSnackBarVariant.error => _NotificationPalette(
        backgroundColor: colorScheme.errorContainer,
        foregroundColor: colorScheme.onErrorContainer,
        accentColor: colorScheme.error,
        borderColor: colorScheme.error.withValues(alpha: 0.30),
        iconData: Icons.error_outline_rounded,
      ),
    };
  }
}

extension AppSnackBarBuildContextX on BuildContext {
  bool showInfoSnackBar(
    String message, {
    Duration duration = AppSnackBarPresenter.defaultDuration,
    bool replaceCurrent = true,
  }) {
    return AppSnackBarPresenter.showInfo(
      this,
      message,
      duration: duration,
      replaceCurrent: replaceCurrent,
    );
  }

  bool showSuccessSnackBar(
    String message, {
    Duration duration = AppSnackBarPresenter.defaultDuration,
    bool replaceCurrent = true,
  }) {
    return AppSnackBarPresenter.showSuccess(
      this,
      message,
      duration: duration,
      replaceCurrent: replaceCurrent,
    );
  }

  bool showWarningSnackBar(
    String message, {
    Duration duration = AppSnackBarPresenter.defaultDuration,
    bool replaceCurrent = true,
  }) {
    return AppSnackBarPresenter.showWarning(
      this,
      message,
      duration: duration,
      replaceCurrent: replaceCurrent,
    );
  }

  bool showErrorSnackBar(
    String message, {
    Duration duration = AppSnackBarPresenter.errorDuration,
    bool replaceCurrent = true,
    Object? source,
  }) {
    return AppSnackBarPresenter.showError(
      this,
      message,
      duration: duration,
      replaceCurrent: replaceCurrent,
      source: source,
    );
  }
}

final class _NotificationPalette {
  const _NotificationPalette({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.accentColor,
    required this.borderColor,
    required this.iconData,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final Color accentColor;
  final Color borderColor;
  final IconData iconData;
}

final class _NotificationTextStyleSet {
  const _NotificationTextStyleSet({
    required this.androidMessageStyle,
    required this.cupertinoMessageStyle,
  });

  final TextStyle androidMessageStyle;
  final TextStyle cupertinoMessageStyle;
}

final class _CupertinoNotificationRequest {
  const _CupertinoNotificationRequest({
    required this.overlay,
    required this.message,
    required this.duration,
    required this.palette,
    required this.textStyle,
  });

  final OverlayState overlay;
  final String message;
  final Duration duration;
  final _NotificationPalette palette;
  final TextStyle textStyle;
}

final class _CupertinoNotificationHandle {
  _CupertinoNotificationHandle({
    required OverlayState overlay,
    required Duration duration,
    required this.onClosed,
    required this.builder,
  }) : _overlay = overlay,
       _duration = duration;

  final OverlayState _overlay;
  final Duration _duration;
  final VoidCallback onClosed;
  final Widget Function(bool isVisible, VoidCallback dismiss) builder;
  final ValueNotifier<bool> _isVisible = ValueNotifier<bool>(false);

  OverlayEntry? _entry;
  Timer? _dismissTimer;
  Timer? _removeTimer;
  bool _isClosed = false;

  void show() {
    if (_isClosed) {
      return;
    }

    _entry = OverlayEntry(
      builder: (BuildContext context) {
        return ValueListenableBuilder<bool>(
          valueListenable: _isVisible,
          builder: (BuildContext context, bool isVisible, Widget? child) {
            return builder(isVisible, dismiss);
          },
        );
      },
    );

    _overlay.insert(_entry!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isClosed) {
        return;
      }

      _isVisible.value = true;
      _dismissTimer = Timer(_duration, dismiss);
    });
  }

  void dismiss() {
    if (_isClosed) {
      return;
    }

    _dismissTimer?.cancel();
    _removeTimer?.cancel();
    _isVisible.value = false;
    _removeTimer = Timer(
      AppSnackBarPresenter._cupertinoTransitionDuration,
      _remove,
    );
  }

  void _remove() {
    if (_isClosed) {
      return;
    }

    _isClosed = true;
    _dismissTimer?.cancel();
    _removeTimer?.cancel();
    _entry?.remove();
    _entry = null;
    _isVisible.dispose();
    onClosed();
  }
}

final class _AndroidNotificationCard extends StatelessWidget {
  const _AndroidNotificationCard({
    required this.message,
    required this.palette,
    required this.textStyle,
  });

  final String message;
  final _NotificationPalette palette;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = Color.alphaBlend(
      AppColors.accentBlack.withValues(alpha: 0.16),
      palette.backgroundColor,
    );

    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppDimensions.maxContentWidth,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: palette.borderColor),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: AppColors.shadowDark,
                  blurRadius: 22,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: palette.accentColor),
                        child: const SizedBox(width: 4),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 10, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        _NotificationIconBadge(
                          palette: palette,
                          fillOpacity: 0.16,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            message,
                            style: textStyle,
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _NotificationDismissButton(
                          icon: Icons.close_rounded,
                          iconColor: palette.foregroundColor.withValues(
                            alpha: 0.82,
                          ),
                          backgroundColor: palette.foregroundColor.withValues(
                            alpha: 0.08,
                          ),
                          onTap: () {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          },
                        ),
                      ],
                    ),
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

final class _CupertinoNotificationOverlay extends StatefulWidget {
  const _CupertinoNotificationOverlay({
    required this.isVisible,
    required this.message,
    required this.palette,
    required this.textStyle,
    required this.onDismiss,
  });

  final bool isVisible;
  final String message;
  final _NotificationPalette palette;
  final TextStyle textStyle;
  final VoidCallback onDismiss;

  @override
  State<_CupertinoNotificationOverlay> createState() =>
      _CupertinoNotificationOverlayState();
}

final class _CupertinoNotificationOverlayState
    extends State<_CupertinoNotificationOverlay> {
  static const double _dragDismissThreshold = 80.0;
  static const double _dragVelocityThreshold = 500.0;

  double _dragOffset = 0.0;
  late Offset _dragStartPosition;

  void _handleVerticalDragStart(DragStartDetails details) {
    _dragStartPosition = details.globalPosition;
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset = details.globalPosition.dy - _dragStartPosition.dy;
    });
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    final double velocity = details.velocity.pixelsPerSecond.dy;

    if (_dragOffset < -_dragDismissThreshold ||
        velocity < -_dragVelocityThreshold) {
      widget.onDismiss();
    } else {
      setState(() {
        _dragOffset = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = Color.alphaBlend(
      AppColors.white.withValues(alpha: 0.05),
      widget.palette.backgroundColor.withValues(alpha: 0.96),
    );

    return IgnorePointer(
      ignoring: !widget.isVisible,
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: AppSnackBarPresenter._cupertinoInset,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppDimensions.maxContentWidth,
                ),
                child: AnimatedSlide(
                  duration: AppSnackBarPresenter._cupertinoTransitionDuration,
                  curve: Curves.easeOutCubic,
                  offset: widget.isVisible
                      ? Offset(0, _dragOffset / 100)
                      : const Offset(0, -0.14),
                  child: AnimatedOpacity(
                    duration: AppSnackBarPresenter._cupertinoTransitionDuration,
                    curve: Curves.easeOutCubic,
                    opacity: widget.isVisible
                        ? (1 - (_dragOffset.abs() / 200)).clamp(0.0, 1.0)
                        : 0,
                    child: GestureDetector(
                      onVerticalDragStart: _handleVerticalDragStart,
                      onVerticalDragUpdate: _handleVerticalDragUpdate,
                      onVerticalDragEnd: _handleVerticalDragEnd,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: widget.palette.borderColor),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(
                              color: AppColors.shadowDark,
                              blurRadius: 24,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              _NotificationIconBadge(
                                palette: widget.palette,
                                fillOpacity: 0.14,
                                size: 32,
                                iconSize: 18,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.message,
                                  style: widget.textStyle,
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _NotificationDismissButton(
                                icon: Icons.close,
                                iconColor: widget.palette.foregroundColor
                                    .withValues(alpha: 0.76),
                                backgroundColor: widget.palette.foregroundColor
                                    .withValues(alpha: 0.06),
                                onTap: widget.onDismiss,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _NotificationIconBadge extends StatelessWidget {
  const _NotificationIconBadge({
    required this.palette,
    required this.fillOpacity,
    this.size = 28,
    this.iconSize = 18,
  });

  final _NotificationPalette palette;
  final double fillOpacity;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: size,
        height: size,
        child: Icon(
          palette.iconData,
          color: palette.accentColor,
          size: iconSize,
        ),
      );
  }
}

final class _NotificationDismissButton extends StatelessWidget {
  const _NotificationDismissButton({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        child: Ink(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
      ),
    );
  }
}
