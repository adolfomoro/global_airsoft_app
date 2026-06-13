import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/core/media/image_crop_service.dart';
import 'package:global_airsoft_app/src/core/media/image_picker_service.dart';
import 'package:global_airsoft_app/src/core/media/profile_photo_camera_capture_service.dart';

final imagePickerServiceProvider = Provider<ImagePickerService>(
  (ref) => ImagePickerService(),
);

final imageCropServiceProvider = Provider<ImageCropService>(
  (ref) => ImageCropService(),
);

final profilePhotoCameraCaptureServiceProvider =
    Provider<ProfilePhotoCameraCaptureService>(
      (ref) => const ProfilePhotoCameraCaptureService(),
    );
