import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:global_airsoft_app/src/app/theme/app_colors.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/media/captured_image_mirror_service.dart';

class ProfilePhotoCameraCapturePage extends StatefulWidget {
  const ProfilePhotoCameraCapturePage({super.key});

  @override
  State<ProfilePhotoCameraCapturePage> createState() =>
      _ProfilePhotoCameraCapturePageState();
}

class _ProfilePhotoCameraCapturePageState
    extends State<ProfilePhotoCameraCapturePage>
    with WidgetsBindingObserver {
  final CapturedImageMirrorService _capturedImageMirrorService =
      const CapturedImageMirrorService();

  CameraController? _controller;
  List<CameraDescription> _cameras = const <CameraDescription>[];
  int _selectedCameraIndex = 0;
  bool _isInitializing = true;
  bool _isCapturing = false;
  String? _errorMessageKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeController();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameras.isEmpty) {
      return;
    }

    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _disposeController();
        break;
      case AppLifecycleState.resumed:
        if (_controller == null) {
          _initializeController(_selectedCameraIndex);
        }
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isInitializing = true;
      _errorMessageKey = null;
    });

    try {
      final List<CameraDescription> cameras = await availableCameras();
      if (!mounted) {
        return;
      }

      if (cameras.isEmpty) {
        setState(() {
          _errorMessageKey = AppLocaleKeys.profilePhotoNoCameraAvailable;
          _isInitializing = false;
        });
        return;
      }

      _cameras = cameras;
      _selectedCameraIndex = _preferredCameraIndex(cameras);
      await _initializeController(_selectedCameraIndex);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessageKey = AppLocaleKeys.profilePhotoCameraOpenFailed;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  int _preferredCameraIndex(List<CameraDescription> cameras) {
    final int frontCameraIndex = cameras.indexWhere(
      (CameraDescription camera) =>
          camera.lensDirection == CameraLensDirection.front,
    );

    return frontCameraIndex >= 0 ? frontCameraIndex : 0;
  }

  Future<void> _initializeController(int index) async {
    await _disposeController();

    final CameraController controller = CameraController(
      _cameras[index],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      await controller.setFlashMode(FlashMode.off);

      setState(() {
        _controller = controller;
        _selectedCameraIndex = index;
        _errorMessageKey = null;
      });
    } catch (_) {
      await controller.dispose();
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessageKey = AppLocaleKeys.profilePhotoCameraPreviewFailed;
      });
    }
  }

  Future<void> _disposeController() async {
    final CameraController? controller = _controller;
    _controller = null;

    if (controller != null) {
      await controller.dispose();
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isCapturing || _isInitializing) {
      return;
    }

    final int nextIndex = (_selectedCameraIndex + 1) % _cameras.length;
    setState(() {
      _isInitializing = true;
    });

    await _initializeController(nextIndex);

    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  Future<void> _capturePhoto() async {
    final CameraController? controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile capturedFile = await controller.takePicture();
      if (!mounted) {
        return;
      }

      final File capturedPhoto = File(capturedFile.path);
      final File mirroredPhoto = await _capturedImageMirrorService
          .mirrorCapturedPhotoIfNeeded(
            sourceFile: capturedPhoto,
            shouldMirror: _shouldMirrorCapturedPhoto(),
          );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(mirroredPhoto);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessageKey = AppLocaleKeys.profilePhotoCameraCaptureFailed;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Widget _buildLoadingState(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.white70,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.tr(
                _errorMessageKey ?? AppLocaleKeys.profilePhotoCameraUnavailable,
              ),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.white),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                _initializeCamera();
              },
              child: Text(l10n.tr(AppLocaleKeys.profilePhotoTryAgain)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    final CameraController? controller = _controller;
    if (_errorMessageKey != null) {
      return _buildErrorState(context);
    }

    if (_isInitializing ||
        controller == null ||
        !controller.value.isInitialized) {
      return _buildLoadingState(context);
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Widget preview = CameraPreview(controller);
        final bool shouldFadeEdges = _shouldFadePreviewEdges(
          constraints,
          controller.value.aspectRatio,
        );

        if (!shouldFadeEdges) {
          return Center(child: preview);
        }

        return Center(
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (Rect bounds) {
              return const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  AppColors.transparent,
                  AppColors.white,
                  AppColors.white,
                  AppColors.transparent,
                ],
                stops: <double>[0.0, 0.02, 0.98, 1.0],
              ).createShader(bounds);
            },
            child: preview,
          ),
        );
      },
    );
  }

  bool _shouldFadePreviewEdges(BoxConstraints constraints, double aspectRatio) {
    if (!constraints.hasBoundedWidth ||
        !constraints.hasBoundedHeight ||
        aspectRatio <= 0) {
      return true;
    }

    const double tolerance = 0.5;
    final double fittedHeight = constraints.maxWidth / aspectRatio;

    return fittedHeight + tolerance < constraints.maxHeight;
  }

  bool _shouldMirrorCapturedPhoto() {
    if (!Platform.isAndroid ||
        _selectedCameraIndex < 0 ||
        _selectedCameraIndex >= _cameras.length) {
      return false;
    }

    return _cameras[_selectedCameraIndex].lensDirection ==
        CameraLensDirection.front;
  }

  Widget _buildTopBar(BuildContext context) {
    final bool hasMultipleCameras = _cameras.length > 1;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(
          children: <Widget>[
            TextButton.icon(
              onPressed: _isCapturing
                  ? null
                  : () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
              label: Text(context.l10n.tr(AppLocaleKeys.profilePhotoCancel)),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.white,
                backgroundColor: AppColors.accentBlack.withValues(alpha: 0.18),
              ),
            ),
            const Spacer(),
            if (hasMultipleCameras)
              IconButton.filledTonal(
                onPressed: _isCapturing ? null : _switchCamera,
                icon: const Icon(Icons.cameraswitch_rounded),
                tooltip: context.l10n.tr(
                  AppLocaleKeys.profilePhotoSwitchCamera,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const SizedBox(width: 56),
            GestureDetector(
              onTap: _isCapturing ? null : _capturePhoto,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white,
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.5),
                    width: 6,
                  ),
                ),
                child: _isCapturing
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Icon(
                        Icons.camera_alt_rounded,
                        color: AppColors.black87,
                      ),
              ),
            ),
            const SizedBox(width: 56),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.accentBlack,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _buildPreview(context),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _buildTopBar(context),
              _buildBottomControls(context),
            ],
          ),
        ],
      ),
    );
  }
}
