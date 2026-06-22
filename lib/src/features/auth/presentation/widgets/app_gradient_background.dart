import 'package:flutter/material.dart';
import 'package:global_airsoft_app/src/app/theme/app_colors.dart';

final class AppGradientBackground extends StatefulWidget {
  const AppGradientBackground({
    super.key,
    required this.child,
    this.colors,
    this.begin = Alignment.topCenter,
    this.end = Alignment.bottomCenter,
    this.stops,
    this.animateOnFirstBuild = false,
    this.animationId,
    this.fadeDuration = const Duration(milliseconds: 1200),
    this.initialDarkOverlayOpacity = 0.9,
  });

  final Widget child;
  final List<Color>? colors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  final List<double>? stops;
  final bool animateOnFirstBuild;
  final String? animationId;
  final Duration fadeDuration;
  final double initialDarkOverlayOpacity;

  @override
  State<AppGradientBackground> createState() => _AppGradientBackgroundState();
}

final class _AppGradientBackgroundState extends State<AppGradientBackground>
    with SingleTickerProviderStateMixin {
  static final Set<String> _completedAnimations = <String>{};
  static const String _defaultAnimationId = '_app_gradient_background_default';

  late final AnimationController _animationController;
  late final Animation<double> _overlayOpacityAnimation;
  late final bool _shouldAnimate;

  @override
  void initState() {
    super.initState();

    final String animationId = widget.animationId ?? _defaultAnimationId;
    final bool animationAlreadyCompleted = _completedAnimations.contains(
      animationId,
    );
    _shouldAnimate =
        widget.animateOnFirstBuild &&
        !animationAlreadyCompleted &&
        widget.initialDarkOverlayOpacity > 0;

    _animationController = AnimationController(
      vsync: this,
      duration: widget.fadeDuration,
    );
    _overlayOpacityAnimation =
        Tween<double>(
          begin: widget.initialDarkOverlayOpacity.clamp(0.0, 1.0),
          end: 0,
        ).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    if (_shouldAnimate) {
      _completedAnimations.add(animationId);
      _animationController.forward();
    } else {
      _animationController.value = 1;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final List<Color> effectiveColors =
        widget.colors ??
        <Color>[
          colorScheme.primaryContainer.withValues(alpha: 0.20),
          colorScheme.surface,
          colorScheme.surface,
        ];

    final Size viewportSize = MediaQuery.sizeOf(context);

    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: <Widget>[
          IgnorePointer(
            child: OverflowBox(
              alignment: Alignment.topCenter,
              minWidth: viewportSize.width,
              maxWidth: viewportSize.width,
              minHeight: viewportSize.height,
              maxHeight: viewportSize.height,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: widget.begin,
                        end: widget.end,
                        colors: effectiveColors,
                        stops: widget.stops,
                      ),
                    ),
                    child: const SizedBox.expand(),
                  ),
                  if (_shouldAnimate)
                    AnimatedBuilder(
                      animation: _overlayOpacityAnimation,
                      builder: (BuildContext context, Widget? child) {
                        final double opacity = _overlayOpacityAnimation.value;
                        if (opacity <= 0) {
                          return const SizedBox.shrink();
                        }

                        return ColoredBox(
                          color: AppColors.accentBlack.withValues(
                            alpha: opacity,
                          ),
                          child: const SizedBox.expand(),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}
