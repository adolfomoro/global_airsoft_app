import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class ProfilePhotoCameraCapturePage extends StatefulWidget {
  const ProfilePhotoCameraCapturePage({super.key});

  @override
  State<ProfilePhotoCameraCapturePage> createState() =>
      _ProfilePhotoCameraCapturePageState();
}

class _ProfilePhotoCameraCapturePageState
    extends State<ProfilePhotoCameraCapturePage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = const <CameraDescription>[];
  int _selectedCameraIndex = 0;
  bool _isInitializing = true;
  bool _isCapturing = false;
  String? _errorMessage;

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
      _errorMessage = null;
    });

    try {
      final List<CameraDescription> cameras = await availableCameras();
      if (!mounted) {
        return;
      }

      if (cameras.isEmpty) {
        setState(() {
          _errorMessage = 'No camera available on this device.';
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
        _errorMessage = 'Unable to open the camera.';
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
        _errorMessage = null;
      });
    } catch (_) {
      await controller.dispose();
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Unable to start the camera preview.';
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

      Navigator.of(context).pop(File(capturedFile.path));
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Unable to capture the photo.';
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.white70,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Camera unavailable.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                _initializeCamera();
              },
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    final CameraController? controller = _controller;
    if (_errorMessage != null) {
      return _buildErrorState(context);
    }

    if (_isInitializing ||
        controller == null ||
        !controller.value.isInitialized) {
      return _buildLoadingState(context);
    }

    return Center(
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Colors.transparent,
              Colors.white,
              Colors.white,
              Colors.transparent,
            ],
            stops: <double>[0.0, 0.02, 0.98, 1.0],
          ).createShader(bounds);
        },
        child: CameraPreview(controller),
      ),
    );
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
              label: const Text('Cancel'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.black.withValues(alpha: 0.18),
              ),
            ),
            const Spacer(),
            if (hasMultipleCameras)
              IconButton.filledTonal(
                onPressed: _isCapturing ? null : _switchCamera,
                icon: const Icon(Icons.cameraswitch_rounded),
                tooltip: 'Switch camera',
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
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
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
                        color: Colors.black87,
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
      backgroundColor: Colors.black,
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
