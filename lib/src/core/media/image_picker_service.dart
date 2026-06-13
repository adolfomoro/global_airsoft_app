import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ImagePickerResult {
  const ImagePickerResult({required this.file, required this.source});

  final File? file;
  final ImageSource source;

  bool get hasImage => file != null;
}

class ImagePickerService {
  ImagePickerService() : _picker = ImagePicker();

  final ImagePicker _picker;

  Future<ImagePickerResult> pickImage({
    required ImageSource source,
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
    bool requestFullMetadata = true,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        requestFullMetadata: requestFullMetadata,
      );

      final File? resolvedFile = await _resolvePickedFile(
        pickedFile: pickedFile,
      );

      if (resolvedFile == null) {
        return ImagePickerResult(file: null, source: source);
      }

      return ImagePickerResult(file: resolvedFile, source: source);
    } catch (_) {
      final File? recoveredFile = await _retrieveLostImageFile();
      return ImagePickerResult(file: recoveredFile, source: source);
    }
  }

  Future<ImagePickerResult> pickFromGallery({
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
    bool requestFullMetadata = false,
  }) async {
    return pickImage(
      source: ImageSource.gallery,
      imageQuality: imageQuality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      requestFullMetadata: requestFullMetadata,
    );
  }

  Future<File?> _resolvePickedFile({required XFile? pickedFile}) async {
    if (pickedFile != null) {
      return File(pickedFile.path);
    }

    return _retrieveLostImageFile();
  }

  Future<File?> _retrieveLostImageFile() async {
    try {
      final LostDataResponse response = await _picker.retrieveLostData();
      if (response.isEmpty) {
        return null;
      }

      final XFile? singleFile = response.file;
      if (singleFile != null) {
        return File(singleFile.path);
      }

      final List<XFile>? files = response.files;
      if (files == null || files.isEmpty) {
        return null;
      }

      return File(files.first.path);
    } catch (_) {
      return null;
    }
  }
}
