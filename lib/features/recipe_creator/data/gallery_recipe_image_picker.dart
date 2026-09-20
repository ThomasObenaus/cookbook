import 'package:cookbook/features/recipe_creator/data/recipe_image_picker.dart';
import 'package:image_picker/image_picker.dart';

typedef PickImage = Future<XFile?> Function({
  required ImageSource source,
  double? maxWidth,
  double? maxHeight,
  int? imageQuality,
});

class GalleryRecipeImagePicker implements RecipeImagePicker {
  GalleryRecipeImagePicker({PickImage? pickImage})
    : _pickImage = pickImage ?? _pickWithPlugin;

  static const _errorMessage =
      'The image could not be selected. Please try again.';

  final PickImage _pickImage;

  @override
  Future<String?> pickFromGallery() async {
    try {
      final image = await _pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      final path = image?.path.trim();
      if (path == null) {
        return null;
      }
      if (path.isEmpty) {
        throw const FormatException('The selected image path is empty.');
      }
      return path;
    } catch (error, stackTrace) {
      throw RecipeImagePickerException(
        message: _errorMessage,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<XFile?> _pickWithPlugin({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) {
    return ImagePicker().pickImage(
      source: source,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
  }
}
