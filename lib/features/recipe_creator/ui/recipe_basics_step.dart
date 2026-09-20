import 'package:cookbook/features/recipe_catalog/models/recipe_image.dart';
import 'package:cookbook/features/recipe_catalog/ui/recipe_image_view.dart';
import 'package:flutter/material.dart';

class RecipeBasicsStep extends StatelessWidget {
  const RecipeBasicsStep({
    required this.titleController,
    required this.titleFocusNode,
    required this.imageFocusNode,
    required this.selectedImagePath,
    required this.titleError,
    required this.imageError,
    required this.isPickingImage,
    required this.enabled,
    required this.onTitleChanged,
    required this.onChooseImage,
    super.key,
  });

  final TextEditingController titleController;
  final FocusNode titleFocusNode;
  final FocusNode imageFocusNode;
  final String? selectedImagePath;
  final String? titleError;
  final String? imageError;
  final bool isPickingImage;
  final bool enabled;
  final ValueChanged<String> onTitleChanged;
  final VoidCallback onChooseImage;

  @override
  Widget build(BuildContext context) {
    final hasImage = selectedImagePath != null;
    final imageLabel = hasImage ? 'Change recipe image' : 'Choose recipe image';
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('Main image', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Semantics(
          button: true,
          enabled: enabled,
          label: imageLabel,
          child: Material(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: const ValueKey<String>('recipe-image-control'),
              focusNode: imageFocusNode,
              canRequestFocus: enabled,
              onTap: enabled ? onChooseImage : null,
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    ExcludeSemantics(
                      child: hasImage
                          ? RecipeImageView(
                              image: RecipeImage.file(selectedImagePath!),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  Icons.photo_library_outlined,
                                  size: 56,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Choose recipe image',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                    ),
                    if (isPickingImage)
                      ColoredBox(
                        color: colorScheme.scrim.withValues(alpha: 0.38),
                        child: const Center(
                          child: CircularProgressIndicator(
                            key: ValueKey<String>('recipe-image-progress'),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (imageError != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            imageError!,
            key: const ValueKey<String>('recipe-image-error'),
            style: TextStyle(color: colorScheme.error),
          ),
        ],
        const SizedBox(height: 24),
        TextFormField(
          key: const ValueKey<String>('recipe-title-field'),
          controller: titleController,
          focusNode: titleFocusNode,
          enabled: enabled,
          onChanged: onTitleChanged,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: 'Recipe title',
            errorText: titleError,
          ),
        ),
      ],
    );
  }
}
