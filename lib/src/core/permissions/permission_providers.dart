import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/core/permissions/camera_permission_service.dart';
import 'package:global_airsoft_app/src/core/permissions/gallery_permission_service.dart';

final cameraPermissionServiceProvider = Provider<CameraPermissionService>(
  (ref) => CameraPermissionService(),
);

final galleryPermissionServiceProvider = Provider<GalleryPermissionService>(
  (ref) => GalleryPermissionService(),
);
