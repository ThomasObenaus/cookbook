import 'package:cookbook/features/recipe_creator/data/gallery_recipe_image_picker.dart';
import 'package:cookbook/features/recipe_creator/data/recipe_image_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  test('selects one constrained gallery image', () async {
    ImageSource? actualSource;
    double? actualMaxWidth;
    double? actualMaxHeight;
    int? actualImageQuality;
    final picker = GalleryRecipeImagePicker(
      pickImage:
          ({
            required ImageSource source,
            double? maxWidth,
            double? maxHeight,
            int? imageQuality,
          }) async {
            actualSource = source;
            actualMaxWidth = maxWidth;
            actualMaxHeight = maxHeight;
            actualImageQuality = imageQuality;
            return XFile('/tmp/recipe.jpg');
          },
    );

    final path = await picker.pickFromGallery();

    expect(path, '/tmp/recipe.jpg');
    expect(actualSource, ImageSource.gallery);
    expect(actualMaxWidth, 1600);
    expect(actualMaxHeight, 1600);
    expect(actualImageQuality, 85);
  });

  test('returns null when gallery selection is cancelled', () async {
    final picker = GalleryRecipeImagePicker(
      pickImage: ({
        required ImageSource source,
        double? maxWidth,
        double? maxHeight,
        int? imageQuality,
      }) async => null,
    );

    expect(await picker.pickFromGallery(), isNull);
  });

  test('converts picker failures to a friendly exception', () async {
    final picker = GalleryRecipeImagePicker(
      pickImage: ({
        required ImageSource source,
        double? maxWidth,
        double? maxHeight,
        int? imageQuality,
      }) async => throw PlatformException(code: 'gallery-failed'),
    );

    await expectLater(
      picker.pickFromGallery(),
      throwsA(
        isA<RecipeImagePickerException>()
            .having(
              (error) => error.message,
              'message',
              'The image could not be selected. Please try again.',
            )
            .having((error) => error.cause, 'cause', isA<PlatformException>()),
      ),
    );
  });
}
