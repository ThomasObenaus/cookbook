import 'package:cookbook/features/recipe_catalog/models/recipe.dart';
import 'package:cookbook/features/recipe_catalog/models/recipe_image.dart';
import 'package:cookbook/features/recipe_catalog/ui/recipe_image_view.dart';
import 'package:cookbook/features/recipe_creator/data/mutable_recipe_repository.dart';
import 'package:cookbook/features/recipe_creator/data/recipe_image_picker.dart';
import 'package:cookbook/features/recipe_creator/models/new_recipe.dart';
import 'package:cookbook/features/recipe_creator/ui/ingredient_form_row.dart';
import 'package:flutter/material.dart';

class RecipeCreatorScreen extends StatefulWidget {
  const RecipeCreatorScreen({
    required this.repository,
    required this.imagePicker,
    super.key,
  });

  final MutableRecipeRepository repository;
  final RecipeImagePicker imagePicker;

  @override
  State<RecipeCreatorScreen> createState() => _RecipeCreatorScreenState();
}

class _RecipeCreatorScreenState extends State<RecipeCreatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _titleController = TextEditingController();
  final _stepsController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _stepsFocusNode = FocusNode();
  final List<IngredientFormControllers> _ingredients =
      <IngredientFormControllers>[];

  int _nextIngredientId = 0;
  String? _selectedImagePath;
  String? _imageError;
  String? _ingredientError;
  bool _isDirty = false;
  bool _isPickingImage = false;
  bool _isSaving = false;
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    _ingredients.add(_newIngredient());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _titleController.dispose();
    _stepsController.dispose();
    _titleFocusNode.dispose();
    _stepsFocusNode.dispose();
    for (final ingredient in _ingredients) {
      ingredient.dispose();
    }
    super.dispose();
  }

  IngredientFormControllers _newIngredient() {
    return IngredientFormControllers(_nextIngredientId++);
  }

  void _markDirty() {
    if (!_isDirty) {
      setState(() {
        _isDirty = true;
      });
    }
  }

  void _addIngredient() {
    if (_isSaving) {
      return;
    }
    setState(() {
      _ingredients.add(_newIngredient());
      _isDirty = true;
      _ingredientError = null;
    });
  }

  void _removeIngredient(IngredientFormControllers ingredient) {
    if (_isSaving || _ingredients.length == 1) {
      return;
    }
    setState(() {
      _ingredients.remove(ingredient);
      _isDirty = true;
      _ingredientError = null;
    });
    ingredient.dispose();
  }

  Future<void> _chooseImage() async {
    if (_isPickingImage || _isSaving) {
      return;
    }
    setState(() {
      _isPickingImage = true;
      _imageError = null;
    });
    try {
      final path = await widget.imagePicker.pickFromGallery();
      if (!mounted || path == null) {
        return;
      }
      setState(() {
        _selectedImagePath = path;
        _isDirty = true;
      });
    } on RecipeImagePickerException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (_isSaving || _isPickingImage) {
      return;
    }
    FocusScope.of(context).unfocus();

    final hasIngredient = _ingredients.any((ingredient) => !ingredient.isBlank);
    setState(() {
      _imageError = _selectedImagePath == null ? 'Choose a recipe image' : null;
      _ingredientError = hasIngredient ? null : 'Add at least one ingredient';
    });
    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid || _imageError != null || _ingredientError != null) {
      _focusFirstInvalidField();
      return;
    }

    late final NewRecipe newRecipe;
    try {
      newRecipe = NewRecipe.fromInput(
        name: _titleController.text,
        ingredients: _ingredients.map((ingredient) => ingredient.toDraft()),
        preparationSteps: _stepsController.text,
        sourceImagePath: _selectedImagePath!,
      );
    } on FormatException catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
      return;
    }

    setState(() {
      _isSaving = true;
    });
    try {
      final recipe = await widget.repository.createRecipe(newRecipe);
      if (!mounted) {
        return;
      }
      _pop(recipe);
    } on Exception catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _focusFirstInvalidField() {
    if (_titleController.text.trim().isEmpty) {
      _titleFocusNode.requestFocus();
      return;
    }
    if (_selectedImagePath == null) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
      return;
    }
    for (final ingredient in _ingredients) {
      if (!ingredient.isBlank && ingredient.name.text.trim().isEmpty) {
        ingredient.nameFocusNode.requestFocus();
        return;
      }
    }
    if (_ingredientError != null && _ingredients.isNotEmpty) {
      _ingredients.first.nameFocusNode.requestFocus();
      return;
    }
    if (_stepsController.text.trim().isEmpty) {
      _stepsFocusNode.requestFocus();
    }
  }

  Future<void> _handleBlockedPop() async {
    if (_isSaving) {
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard recipe?'),
        content: const Text('Your unsaved recipe will be lost.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (!mounted || discard != true) {
      return;
    }
    _pop(null);
  }

  void _pop(Recipe? recipe) {
    setState(() {
      _allowPop = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop(recipe);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Recipe>(
      canPop: !_isDirty || _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_allowPop) {
          _handleBlockedPop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create recipe'),
          actions: <Widget>[
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(
                    key: ValueKey<String>('recipe-save-progress'),
                    strokeWidth: 2.5,
                  ),
                ),
              )
            else
              IconButton(
                key: const ValueKey<String>('save-recipe'),
                onPressed: _isPickingImage ? null : _save,
                tooltip: 'Save recipe',
                icon: const Icon(Icons.save_outlined),
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            key: const ValueKey<String>('recipe-creator-scroll-view'),
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'Main image',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    AspectRatio(
                      aspectRatio: 4 / 3,
                      child: _selectedImagePath == null
                          ? DecoratedBox(
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Icon(Icons.image_outlined, size: 56),
                                  SizedBox(height: 8),
                                  Text('No image selected'),
                                ],
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: RecipeImageView(
                                image: RecipeImage.file(_selectedImagePath!),
                                semanticLabel: 'Selected recipe image',
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        key: const ValueKey<String>('choose-recipe-image'),
                        onPressed: _isPickingImage || _isSaving
                            ? null
                            : _chooseImage,
                        icon: _isPickingImage
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.photo_library_outlined),
                        label: Text(
                          _selectedImagePath == null
                              ? 'Choose image'
                              : 'Replace image',
                        ),
                      ),
                    ),
                    if (_imageError != null) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        _imageError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    TextFormField(
                      key: const ValueKey<String>('recipe-title-field'),
                      controller: _titleController,
                      focusNode: _titleFocusNode,
                      enabled: !_isSaving,
                      onChanged: (_) => _markDirty(),
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Recipe title',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter a recipe title'
                          : null,
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Ingredients',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          key: const ValueKey<String>('add-ingredient'),
                          onPressed: _isSaving ? null : _addIngredient,
                          tooltip: 'Add ingredient',
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                    if (_ingredientError != null)
                      Text(
                        _ingredientError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    for (
                      var index = 0;
                      index < _ingredients.length;
                      index++
                    ) ...<Widget>[
                      IngredientFormRow(
                        key: ValueKey<int>(_ingredients[index].id),
                        index: index,
                        controllers: _ingredients[index],
                        enabled: !_isSaving,
                        canRemove: _ingredients.length > 1,
                        onChanged: _markDirty,
                        onRemove: () => _removeIngredient(_ingredients[index]),
                      ),
                      if (index < _ingredients.length - 1) const Divider(),
                    ],
                    const SizedBox(height: 20),
                    TextFormField(
                      key: const ValueKey<String>('recipe-steps-field'),
                      controller: _stepsController,
                      focusNode: _stepsFocusNode,
                      enabled: !_isSaving,
                      onChanged: (_) => _markDirty(),
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      minLines: 5,
                      maxLines: 10,
                      decoration: const InputDecoration(
                        labelText: 'Preparation steps',
                        helperText: 'Enter one step per line',
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        final hasStep =
                            value
                                ?.split(RegExp(r'\r?\n'))
                                .any((step) => step.trim().isNotEmpty) ??
                            false;
                        return hasStep ? null : 'Enter at least one step';
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
