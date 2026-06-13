import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class GalleryPermissionService {
  Permission get _galleryPermission {
    if (Platform.isIOS) {
      return Permission.photos;
    }
    return Permission.photos;
  }

  Future<Permission> _getAndroidGalleryPermission() async {
    if (Platform.isAndroid) {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.sdkInt >= 33
          ? Permission.photos
          : Permission.storage;
    }
    return Permission.photos;
  }

  Future<bool> isGranted() async {
    final Permission permission = Platform.isAndroid
        ? await _getAndroidGalleryPermission()
        : _galleryPermission;
    final PermissionStatus status = await permission.status;

    if (status.isLimited) {
      return true;
    }

    return status.isGranted;
  }

  Future<bool> isPermanentlyDenied() async {
    final Permission permission = Platform.isAndroid
        ? await _getAndroidGalleryPermission()
        : _galleryPermission;
    final PermissionStatus status = await permission.status;
    return status.isPermanentlyDenied;
  }

  Future<bool> request() async {
    final Permission permission = Platform.isAndroid
        ? await _getAndroidGalleryPermission()
        : _galleryPermission;
    final PermissionStatus status = await permission.request();

    if (status.isLimited) {
      return true;
    }

    return status.isGranted;
  }

  Future<bool> openSettings() async {
    return await openAppSettings();
  }

  Future<PermissionStatus> checkStatus() async {
    final Permission permission = Platform.isAndroid
        ? await _getAndroidGalleryPermission()
        : _galleryPermission;
    return await permission.status;
  }
}
