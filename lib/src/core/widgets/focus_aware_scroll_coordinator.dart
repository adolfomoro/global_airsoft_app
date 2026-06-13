import 'dart:async';

import 'package:flutter/material.dart';

final class FocusAwareScrollCoordinator {
  FocusAwareScrollCoordinator({
    required FocusNode focusNode,
    required ScrollController scrollController,
    required GlobalKey focusedFieldKey,
    required GlobalKey revealTargetKey,
    this.minGapFromAppBar = 20,
    this.bottomPadding = 12,
    this.desiredRevealRatio = 0.9,
    this.focusAdjustDelay = const Duration(milliseconds: 40),
    this.metricsAdjustDelay = const Duration(milliseconds: 90),
    this.minAnimateDelta = 4,
  }) : _focusNode = focusNode,
       _scrollController = scrollController,
       _focusedFieldKey = focusedFieldKey,
       _revealTargetKey = revealTargetKey;

  final FocusNode _focusNode;
  final ScrollController _scrollController;
  final GlobalKey _focusedFieldKey;
  final GlobalKey _revealTargetKey;
  final double minGapFromAppBar;
  final double bottomPadding;
  final double desiredRevealRatio;
  final Duration focusAdjustDelay;
  final Duration metricsAdjustDelay;
  final double minAnimateDelta;

  Timer? _debounceTimer;

  void onFocusChanged(BuildContext context) {
    if (!_focusNode.hasFocus) {
      _debounceTimer?.cancel();
      return;
    }

    _scheduleAdjustment(context: context, delay: focusAdjustDelay);
  }

  void onMetricsChanged(BuildContext context) {
    if (!_focusNode.hasFocus) {
      return;
    }

    _scheduleAdjustment(context: context, delay: metricsAdjustDelay);
  }

  void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  void _scheduleAdjustment({
    required BuildContext context,
    required Duration delay,
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, () {
      if (!_focusNode.hasFocus) {
        return;
      }

      _adjustScroll(context);
    });
  }

  void _adjustScroll(BuildContext context) {
    if (!_scrollController.hasClients) {
      return;
    }

    final BuildContext? fieldContext = _focusedFieldKey.currentContext;
    if (fieldContext == null) {
      return;
    }

    final RenderObject? fieldRenderObject = fieldContext.findRenderObject();
    if (fieldRenderObject is! RenderBox || !fieldRenderObject.hasSize) {
      return;
    }

    final BuildContext? scrollContext =
        _scrollController.position.context.notificationContext;
    if (scrollContext == null) {
      return;
    }

    final RenderObject? scrollRenderObject = scrollContext.findRenderObject();
    if (scrollRenderObject is! RenderBox || !scrollRenderObject.hasSize) {
      return;
    }

    final ScrollPosition position = _scrollController.position;
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double appBarBottom = mediaQuery.padding.top + kToolbarHeight;
    final double minAllowedFieldTop = appBarBottom + minGapFromAppBar;

    final double fieldTop = fieldRenderObject.localToGlobal(Offset.zero).dy;
    final double viewportTop = scrollRenderObject.localToGlobal(Offset.zero).dy;
    final double viewportBottom = viewportTop + scrollRenderObject.size.height;
    final double visibleBottom = viewportBottom - bottomPadding;

    double requiredUpDeltaForReveal = 0;

    final BuildContext? revealContext = _revealTargetKey.currentContext;
    if (revealContext != null) {
      final RenderObject? revealRenderObject = revealContext.findRenderObject();
      if (revealRenderObject is RenderBox && revealRenderObject.hasSize) {
        final double revealTop = revealRenderObject
            .localToGlobal(Offset.zero)
            .dy;
        final double revealHeight = revealRenderObject.size.height;
        final double targetRevealTop =
            visibleBottom - (revealHeight * desiredRevealRatio);
        requiredUpDeltaForReveal = (revealTop - targetRevealTop).clamp(
          0,
          double.infinity,
        );
      }
    }

    final double requiredDownDeltaForField = (minAllowedFieldTop - fieldTop)
        .clamp(0, double.infinity);
    final double maxUpDeltaKeepingFieldVisible = (fieldTop - minAllowedFieldTop)
        .clamp(0, double.infinity);
    final double appliedUpDelta = requiredUpDeltaForReveal.clamp(
      0,
      maxUpDeltaKeepingFieldVisible,
    );

    double targetOffset =
        position.pixels - requiredDownDeltaForField + appliedUpDelta;

    targetOffset = targetOffset.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );

    if ((targetOffset - position.pixels).abs() < minAnimateDelta) {
      return;
    }

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }
}
