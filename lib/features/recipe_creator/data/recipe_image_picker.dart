abstract interface class RecipeImagePicker {
  Future<String?> pickFromGallery();
}

class RecipeImagePickerException implements Exception {
  const RecipeImagePickerException({
    required this.message,
    required this.cause,
    required this.stackTrace,
  });

  final String message;
  final Object cause;
  final StackTrace stackTrace;

  @override
  String toString() => message;
}
