import 'dart:io';

import 'package:flutter/material.dart';
import 'package:global_airsoft_app/src/core/widgets/profile_photo_camera_capture_page.dart';

final class ProfilePhotoCameraCaptureService {
  const ProfilePhotoCameraCaptureService();

  Future<File?> capture(NavigatorState navigator) {
    return navigator.push<File?>(
      MaterialPageRoute<File?>(
        fullscreenDialog: true,
        builder: (BuildContext context) =>
            const ProfilePhotoCameraCapturePage(),
      ),
    );
  }
}
