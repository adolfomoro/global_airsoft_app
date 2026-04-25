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
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      if (pickedFile == null) {
        return ImagePickerResult(file: null, source: source);
      }

      final File file = File(pickedFile.path);
      return ImagePickerResult(file: file, source: source);
    } catch (e) {
      return ImagePickerResult(file: null, source: source);
    }
  }

  Future<ImagePickerResult> pickFromGallery({
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
  }) async {
    return pickImage(
      source: ImageSource.gallery,
      imageQuality: imageQuality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
  }
}
