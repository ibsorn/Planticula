import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

/// Result of picking a single image, including bytes and original file name.
class PickedImageResult {
  final Uint8List bytes;
  final String name;

  const PickedImageResult({required this.bytes, required this.name});
}

/// Shared image-picker configuration and logic.
///
/// Eliminates duplicated ImagePicker code across blocs.
class ImagePickerHelper {
  final ImagePicker _picker;

  static const double defaultMaxWidth = 1920;
  static const double defaultMaxHeight = 1920;
  static const int defaultImageQuality = 85;

  ImagePickerHelper({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  /// Pick a single image from [source] (gallery or camera).
  ///
  /// Returns the image bytes or null if cancelled.
  Future<Uint8List?> pickSingleImage({
    required ImageSource source,
    double maxWidth = defaultMaxWidth,
    double maxHeight = defaultMaxHeight,
    int imageQuality = defaultImageQuality,
  }) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );

    if (pickedFile == null) return null;
    return pickedFile.readAsBytes();
  }

  /// Pick a single image from [source], returning both bytes and file name.
  ///
  /// Returns null if cancelled.
  Future<PickedImageResult?> pickSingleImageWithName({
    required ImageSource source,
    double maxWidth = defaultMaxWidth,
    double maxHeight = defaultMaxHeight,
    int imageQuality = defaultImageQuality,
  }) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );

    if (pickedFile == null) return null;
    final bytes = await pickedFile.readAsBytes();
    return PickedImageResult(bytes: bytes, name: pickedFile.name);
  }

  /// Pick multiple images from gallery.
  ///
  /// Returns a list of image bytes or an empty list if cancelled.
  Future<List<Uint8List>> pickMultipleImages({
    double maxWidth = defaultMaxWidth,
    double maxHeight = defaultMaxHeight,
    int imageQuality = defaultImageQuality,
  }) async {
    final pickedFiles = await _picker.pickMultiImage(
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );

    if (pickedFiles.isEmpty) return [];
    return Future.wait(pickedFiles.map((f) => f.readAsBytes()));
  }
}
