import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

enum AppImageZoomViewerShape { rectangle, circle }

class AppImageZoomViewer extends StatelessWidget {
  const AppImageZoomViewer.network({required String imageUrl, Key? key})
    : this.shapedNetwork(
        imageUrl: imageUrl,
        imageShape: AppImageZoomViewerShape.rectangle,
        key: key,
      );

  const AppImageZoomViewer.imageProvider({
    required ImageProvider imageProvider,
    Key? key,
  }) : this.shapedImageProvider(
         imageProvider: imageProvider,
         imageShape: AppImageZoomViewerShape.rectangle,
         key: key,
       );

  const AppImageZoomViewer.shapedNetwork({
    required String imageUrl,
    required AppImageZoomViewerShape imageShape,
    super.key,
  }) : _imageUrl = imageUrl,
       _imageProvider = null,
       _imageShape = imageShape;

  const AppImageZoomViewer.shapedImageProvider({
    required ImageProvider imageProvider,
    required AppImageZoomViewerShape imageShape,
    super.key,
  }) : _imageUrl = null,
       _imageProvider = imageProvider,
       _imageShape = imageShape;

  static Future<T?> showNetwork<T extends Object?>(
    BuildContext context, {
    required String imageUrl,
    AppImageZoomViewerShape imageShape = AppImageZoomViewerShape.rectangle,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      transitionBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) => child,
      pageBuilder:
          (
            BuildContext dialogContext,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            return AppImageZoomViewer.shapedNetwork(
              imageUrl: imageUrl,
              imageShape: imageShape,
            );
          },
    );
  }

  static Future<T?> showImageProvider<T extends Object?>(
    BuildContext context, {
    required ImageProvider imageProvider,
    AppImageZoomViewerShape imageShape = AppImageZoomViewerShape.rectangle,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      transitionBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) => child,
      pageBuilder:
          (
            BuildContext dialogContext,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            return AppImageZoomViewer.shapedImageProvider(
              imageProvider: imageProvider,
              imageShape: imageShape,
            );
          },
    );
  }

  final String? _imageUrl;
  final ImageProvider? _imageProvider;
  final AppImageZoomViewerShape _imageShape;

  @override
  Widget build(BuildContext context) {
    return _AppImageZoomViewerBody(
      imageUrl: _imageUrl,
      imageProvider: _imageProvider,
      imageShape: _imageShape,
    );
  }
}

class _AppImageZoomViewerBody extends StatefulWidget {
  const _AppImageZoomViewerBody({
    required this.imageUrl,
    required this.imageProvider,
    required this.imageShape,
  });

  final String? imageUrl;
  final ImageProvider? imageProvider;
  final AppImageZoomViewerShape imageShape;

  @override
  State<_AppImageZoomViewerBody> createState() =>
      _AppImageZoomViewerBodyState();
}

class _AppImageZoomViewerBodyState extends State<_AppImageZoomViewerBody>
    with SingleTickerProviderStateMixin {
  static const Duration _resetDuration = Duration(milliseconds: 180);
  static const Duration _imageRevealDuration = Duration(milliseconds: 160);
  static const double _blurSigma = 30;
  static const double _imageViewportFactor = 0.78;
  static const double _minRevealScale = 0.96;
  static const double _maxScale = 3.8;

  AnimationController? _resetController;
  double _zoomScale = 1;
  double _gestureBaseScale = 1;
  double _imageAspectRatio = 1;
  bool _imageReady = false;
  bool _imageLoadFailed = false;
  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;

  @override
  void initState() {
    super.initState();
    _resolveImageAspectRatio();
  }

  @override
  void didUpdateWidget(covariant _AppImageZoomViewerBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.imageProvider != widget.imageProvider) {
      _imageReady = false;
      _imageLoadFailed = false;
      _zoomScale = 1;
      _gestureBaseScale = 1;
      _imageAspectRatio = 1;
      _resolveImageAspectRatio();
    }
  }

  ImageProvider? _resolveImageProvider() {
    if (widget.imageProvider != null) {
      return widget.imageProvider;
    }

    final String? imageUrl = widget.imageUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      return null;
    }

    return NetworkImage(imageUrl);
  }

  void _resolveImageAspectRatio() {
    _clearImageStreamListener();

    final ImageProvider? imageProvider = _resolveImageProvider();
    if (imageProvider == null) {
      return;
    }

    final ImageStream stream = imageProvider.resolve(
      const ImageConfiguration(),
    );

    final ImageStreamListener listener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        final double width = info.image.width.toDouble();
        final double height = info.image.height.toDouble();
        if (!mounted || width <= 0 || height <= 0) {
          return;
        }

        setState(() {
          _imageAspectRatio = width / height;
          _imageReady = true;
          _imageLoadFailed = false;
        });
      },
      onError: (Object error, StackTrace? stackTrace) {
        if (!mounted) {
          return;
        }

        setState(() {
          _imageLoadFailed = true;
        });
      },
    );

    _imageStream = stream;
    _imageStreamListener = listener;
    stream.addListener(listener);
  }

  void _clearImageStreamListener() {
    final ImageStream? imageStream = _imageStream;
    final ImageStreamListener? imageStreamListener = _imageStreamListener;
    if (imageStream != null && imageStreamListener != null) {
      imageStream.removeListener(imageStreamListener);
    }

    _imageStream = null;
    _imageStreamListener = null;
  }

  void _close() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  void _cancelResetAnimation() {
    _resetController?.stop();
    _resetController?.dispose();
    _resetController = null;
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _cancelResetAnimation();
    _gestureBaseScale = _zoomScale;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    final double nextScale = (_gestureBaseScale * details.scale).clamp(
      1,
      _maxScale,
    );
    if (nextScale == _zoomScale) {
      return;
    }

    setState(() {
      _zoomScale = nextScale;
    });
  }

  void _resetScale() {
    if (_zoomScale <= 1) {
      return;
    }

    _cancelResetAnimation();

    final AnimationController controller = AnimationController(
      vsync: this,
      duration: _resetDuration,
    );
    final Animation<double> resetAnimation = Tween<double>(
      begin: _zoomScale,
      end: 1,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic));

    resetAnimation.addListener(() {
      if (!mounted) {
        return;
      }

      setState(() {
        _zoomScale = resetAnimation.value;
      });
    });

    _resetController = controller;

    controller.forward().whenComplete(() {
      if (!mounted || _resetController != controller) {
        return;
      }

      setState(() {
        _zoomScale = 1;
      });
      _cancelResetAnimation();
    });
  }

  Widget _buildImage(BuildContext context, BoxConstraints constraints) {
    final double maxWidth = constraints.maxWidth * _imageViewportFactor;
    final double maxHeight = constraints.maxHeight * _imageViewportFactor;
    final bool isCircular = widget.imageShape == AppImageZoomViewerShape.circle;

    late double imageWidth;
    late double imageHeight;

    if (isCircular) {
      final double diameter = math.min(maxWidth, maxHeight);
      imageWidth = diameter;
      imageHeight = diameter;
    } else {
      imageWidth = maxWidth;
      imageHeight = imageWidth / _imageAspectRatio;
      if (imageHeight > maxHeight) {
        imageHeight = maxHeight;
        imageWidth = imageHeight * _imageAspectRatio;
      }
    }

    final Widget imageWidget;
    if (widget.imageProvider != null) {
      final ImageProvider imageProvider = widget.imageProvider!;
      imageWidget = Image(
        image: imageProvider,
        fit: isCircular ? BoxFit.cover : BoxFit.fill,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) {
              return const SizedBox.shrink();
            },
      );
    } else {
      imageWidget = Image.network(
        widget.imageUrl!,
        fit: isCircular ? BoxFit.cover : BoxFit.fill,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) {
              return const SizedBox.shrink();
            },
      );
    }

    if (_imageLoadFailed) {
      return const SizedBox.shrink();
    }

    if (!_imageReady) {
      return Center(
        child: SizedBox(width: imageWidth, height: imageHeight),
      );
    }

    return Center(
      child: SizedBox(
        width: imageWidth,
        height: imageHeight,
        child: TweenAnimationBuilder<double>(
          key: const ValueKey<String>('image-reveal'),
          tween: Tween<double>(begin: 0, end: 1),
          duration: _imageRevealDuration,
          curve: Curves.easeOutCubic,
          builder: (BuildContext context, double progress, Widget? child) {
            final double revealScale =
                _minRevealScale + ((1 - _minRevealScale) * progress);

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: _handleScaleStart,
              onScaleUpdate: _handleScaleUpdate,
              onScaleEnd: (_) => _resetScale(),
              child: Opacity(
                opacity: progress,
                child: Transform.scale(
                  scale: _zoomScale * revealScale,
                  alignment: Alignment.center,
                  child: _wrapImageForShape(child ?? const SizedBox.shrink()),
                ),
              ),
            );
          },
          child: imageWidget,
        ),
      ),
    );
  }

  Widget _wrapImageForShape(Widget child) {
    if (widget.imageShape == AppImageZoomViewerShape.circle) {
      return ClipOval(child: SizedBox.expand(child: child));
    }

    return child;
  }

  @override
  void dispose() {
    _clearImageStreamListener();
    _cancelResetAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Material(
        type: MaterialType.transparency,
        child: SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _close,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(
                        sigmaX: _blurSigma,
                        sigmaY: _blurSigma,
                      ),
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: 0.22),
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    return _buildImage(context, constraints);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
