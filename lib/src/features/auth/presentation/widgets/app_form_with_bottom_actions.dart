import 'package:flutter/material.dart';
import 'package:global_airsoft_app/src/app/theme/app_dimensions.dart';
import 'package:global_airsoft_app/src/core/widgets/form/app_form_padding.dart';

final class AppFormBottomAction {
  const AppFormBottomAction({required this.child, this.showWhenKeyboardOpen});

  final Widget child;
  final bool? showWhenKeyboardOpen;
}

final class AppFormWithBottomActions extends StatefulWidget {
  const AppFormWithBottomActions({
    required this.body,
    required this.bottomActions,
    super.key,
    this.scrollController,
    this.bottomActionsRevealKeyboardCloseProgress = 0.6,
    this.bodyPadding = const EdgeInsets.symmetric(
      horizontal: AppDimensions.spacing2xl,
    ),
    this.bottomActionsPadding = const EdgeInsets.fromLTRB(
      AppDimensions.spacing2xl,
      AppDimensions.spacingLg,
      AppDimensions.spacing2xl,
      AppDimensions.spacingLg,
    ),
    this.bodyBottomSpacing = AppDimensions.spacingXl,
  }) : assert(
         bottomActionsRevealKeyboardCloseProgress >= 0 &&
             bottomActionsRevealKeyboardCloseProgress <= 1,
         'bottomActionsRevealKeyboardCloseProgress must be between 0 and 1.',
       );

  final Widget body;
  final List<AppFormBottomAction> bottomActions;
  final ScrollController? scrollController;
  final double bottomActionsRevealKeyboardCloseProgress;
  final EdgeInsetsGeometry bodyPadding;
  final EdgeInsetsGeometry bottomActionsPadding;
  final double bodyBottomSpacing;

  @override
  State<AppFormWithBottomActions> createState() =>
      _AppFormWithBottomActionsState();
}

final class _AppFormWithBottomActionsState
    extends State<AppFormWithBottomActions>
    with WidgetsBindingObserver {
  static const double _insetTolerance = 0.5;

  double _currentBottomInset = 0;
  double _peakBottomInset = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncKeyboardInsets(updateState: false);
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _syncKeyboardInsets();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> visibleBottomActions = _resolveVisibleBottomActions(
      isKeyboardOpen: _shouldHideKeyboardOnlyActions,
    );

    return SafeArea(
      child: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
              child: AppFormPadding(
                padding: widget.bodyPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    widget.body,
                    SizedBox(height: widget.bodyBottomSpacing),
                  ],
                ),
              ),
            ),
          ),
          if (visibleBottomActions.isNotEmpty)
            AppFormPadding(
              padding: widget.bottomActionsPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: visibleBottomActions,
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _resolveVisibleBottomActions({required bool isKeyboardOpen}) {
    final Iterable<AppFormBottomAction> visibleActions = isKeyboardOpen
        ? widget.bottomActions.where(
            (AppFormBottomAction action) => action.showWhenKeyboardOpen == true,
          )
        : widget.bottomActions;

    return visibleActions
        .map((AppFormBottomAction action) => action.child)
        .toList(growable: false);
  }

  bool get _shouldHideKeyboardOnlyActions {
    if (_currentBottomInset <= _insetTolerance) {
      return false;
    }

    return _keyboardCloseProgress <
        widget.bottomActionsRevealKeyboardCloseProgress;
  }

  double get _keyboardCloseProgress {
    if (_peakBottomInset <= _insetTolerance) {
      return 1;
    }

    final double closeProgress =
        (_peakBottomInset - _currentBottomInset) / _peakBottomInset;
    return closeProgress.clamp(0.0, 1.0);
  }

  void _syncKeyboardInsets({bool updateState = true}) {
    final double nextBottomInset = MediaQueryData.fromView(
      View.of(context),
    ).viewInsets.bottom;
    final double normalizedBottomInset = nextBottomInset <= _insetTolerance
        ? 0
        : nextBottomInset;
    final double nextPeakBottomInset = normalizedBottomInset == 0
        ? 0
        : normalizedBottomInset > _peakBottomInset
        ? normalizedBottomInset
        : _peakBottomInset;

    final bool didInsetChange =
        (normalizedBottomInset - _currentBottomInset).abs() > _insetTolerance;
    final bool didPeakChange =
        (nextPeakBottomInset - _peakBottomInset).abs() > _insetTolerance;

    if (!didInsetChange && !didPeakChange) {
      return;
    }

    if (!updateState || !mounted) {
      _currentBottomInset = normalizedBottomInset;
      _peakBottomInset = nextPeakBottomInset;
      return;
    }

    setState(() {
      _currentBottomInset = normalizedBottomInset;
      _peakBottomInset = nextPeakBottomInset;
    });
  }
}


