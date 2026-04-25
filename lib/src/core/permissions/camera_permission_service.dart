import 'package:permission_handler/permission_handler.dart';

class CameraPermissionService {
  Future<bool> isGranted() async {
    final PermissionStatus status = await Permission.camera.status;
    return status.isGranted;
  }

  Future<bool> isPermanentlyDenied() async {
    final PermissionStatus status = await Permission.camera.status;
    return status.isPermanentlyDenied;
  }

  Future<bool> request() async {
    final PermissionStatus status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> openSettings() async {
    return await openAppSettings();
  }

  Future<PermissionStatus> checkStatus() async {
    return await Permission.camera.status;
  }
}
