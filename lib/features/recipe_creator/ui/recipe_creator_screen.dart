import 'package:cookbook/features/recipe_catalog/models/recipe.dart';
import 'package:cookbook/features/recipe_creator/data/mutable_recipe_repository.dart';
import 'package:cookbook/features/recipe_creator/data/recipe_image_picker.dart';
import 'package:cookbook/features/recipe_creator/models/new_recipe.dart';
import 'package:cookbook/features/recipe_creator/models/recipe_creator_stage.dart';
import 'package:cookbook/features/recipe_creator/ui/ingredient_wizard_step.dart';
import 'package:cookbook/features/recipe_creator/ui/preparation_wizard_step.dart';
import 'package:cookbook/features/recipe_creator/ui/recipe_basics_step.dart';
import 'package:cookbook/features/recipe_creator/ui/recipe_review_step.dart';
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
  final _scrollController = ScrollController();
  final _titleController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _imageFocusNode = FocusNode();
  final _ingredientControllers = IngredientEditorControllers();
  final _preparationController = TextEditingController();
  final _preparationFocusNode = FocusNode();

  RecipeCreatorStage _stage = RecipeCreatorStage.recipe;
  List<IngredientDraft> _ingredients = const <IngredientDraft>[];
  List<String> _steps = const <String>[];
  String? _selectedImagePath;
  String? _titleError;
  String? _imageError;
  String? _ingredientNameError;
  String? _preparationError;
  int? _editingIngredientIndex;
  int? _editingPreparationIndex;
  bool _ingredientEditorVisible = true;
  bool _preparationEditorVisible = true;
  bool _isDirty = false;
  bool _isPickingImage = false;
  bool _isSaving = false;
  bool _allowPop = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _titleController.dispose();
    _titleFocusNode.dispose();
    _imageFocusNode.dispose();
    _ingredientControllers.dispose();
    _preparationController.dispose();
    _preparationFocusNode.dispose();
    super.dispose();
  }

  void _setStage(RecipeCreatorStage stage) {
    if (_isSaving) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _stage = stage;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  void _titleChanged(String value) {
    setState(() {
      _isDirty = true;
      if (value.trim().isNotEmpty) {
        _titleError = null;
      }
    });
  }

  Future<void> _chooseImage() async {
    if (_isPickingImage || _isSaving) {
      return;
    }
    setState(() {
      _isPickingImage = true;
    });
    try {
      final path = await widget.imagePicker.pickFromGallery();
      if (!mounted || path == null) {
        return;
      }
      setState(() {
        _selectedImagePath = path;
        _imageError = null;
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

  void _continue() {
    if (_isSaving || _isPickingImage) {
      return;
    }
    FocusScope.of(context).unfocus();
    switch (_stage) {
      case RecipeCreatorStage.recipe:
        if (_validateRecipe()) {
          _setStage(RecipeCreatorStage.ingredients);
        }
      case RecipeCreatorStage.ingredients:
        if (_commitIngredient(forContinue: true)) {
          _setStage(RecipeCreatorStage.preparation);
        }
      case RecipeCreatorStage.preparation:
        if (_commitPreparationStep(forContinue: true)) {
          _setStage(RecipeCreatorStage.review);
        }
      case RecipeCreatorStage.review:
        _save();
    }
  }

  bool _validateRecipe() {
    final titleError = _titleController.text.trim().isEmpty
        ? 'Enter a recipe title'
        : null;
    final imageError = _selectedImagePath == null
        ? 'Choose a recipe image'
        : null;
    setState(() {
      _titleError = titleError;
      _imageError = imageError;
    });
    if (imageError != null) {
      _imageFocusNode.requestFocus();
      return false;
    }
    if (titleError != null) {
      _titleFocusNode.requestFocus();
      return false;
    }
    return true;
  }

  void _ingredientChanged() {
    setState(() {
      _isDirty = true;
      if (_ingredientControllers.name.text.trim().isNotEmpty) {
        _ingredientNameError = null;
      }
    });
  }

  bool _commitIngredient({required bool forContinue}) {
    if (!_ingredientEditorVisible) {
      if (_ingredients.isNotEmpty) {
        return true;
      }
      _showIngredientError('Add at least one ingredient');
      return false;
    }

    if (_ingredientControllers.isBlank) {
      if (forContinue && _ingredients.isNotEmpty) {
        if (_editingIngredientIndex != null) {
          _showIngredientError('Enter an ingredient name');
          return false;
        }
        setState(() {
          _ingredientEditorVisible = false;
          _editingIngredientIndex = null;
          _ingredientNameError = null;
          _ingredientControllers.clear();
        });
        return true;
      }
      _showIngredientError(
        forContinue
            ? 'Add at least one ingredient'
            : 'Enter an ingredient name',
      );
      return false;
    }
    if (_ingredientControllers.name.text.trim().isEmpty) {
      _showIngredientError('Enter an ingredient name');
      return false;
    }

    final draft = _ingredientControllers.toDraft();
    final nextIngredients = List<IngredientDraft>.of(_ingredients);
    final editingIndex = _editingIngredientIndex;
    if (editingIndex == null) {
      nextIngredients.add(draft);
    } else {
      nextIngredients[editingIndex] = draft;
    }
    setState(() {
      _ingredients = List<IngredientDraft>.unmodifiable(nextIngredients);
      _ingredientEditorVisible = false;
      _editingIngredientIndex = null;
      _ingredientNameError = null;
      _isDirty = true;
      _ingredientControllers.clear();
    });
    return true;
  }

  void _showIngredientError(String message) {
    setState(() {
      _ingredientNameError = message;
    });
    _ingredientControllers.nameFocusNode.requestFocus();
  }

  void _addIngredient() {
    if (_isSaving || _ingredientEditorVisible) {
      return;
    }
    setState(() {
      _ingredientControllers.clear();
      _editingIngredientIndex = null;
      _ingredientEditorVisible = true;
      _ingredientNameError = null;
    });
    _ingredientControllers.nameFocusNode.requestFocus();
  }

  void _editIngredient(int index) {
    if (_isSaving || _ingredientEditorVisible) {
      return;
    }
    setState(() {
      _ingredientControllers.load(_ingredients[index]);
      _editingIngredientIndex = index;
      _ingredientEditorVisible = true;
      _ingredientNameError = null;
    });
    _ingredientControllers.nameFocusNode.requestFocus();
  }

  void _removeIngredient(int index) {
    if (_isSaving) {
      return;
    }
    final nextIngredients = List<IngredientDraft>.of(_ingredients)
      ..removeAt(index);
    setState(() {
      _ingredients = List<IngredientDraft>.unmodifiable(nextIngredients);
      if (_editingIngredientIndex != null && index < _editingIngredientIndex!) {
        _editingIngredientIndex = _editingIngredientIndex! - 1;
      }
      if (_ingredients.isEmpty && !_ingredientEditorVisible) {
        _ingredientControllers.clear();
        _ingredientEditorVisible = true;
        _editingIngredientIndex = null;
      }
      _ingredientNameError = null;
      _isDirty = true;
    });
  }

  void _preparationChanged() {
    setState(() {
      _isDirty = true;
      if (_preparationController.text.trim().isNotEmpty) {
        _preparationError = null;
      }
    });
  }

  bool _commitPreparationStep({required bool forContinue}) {
    if (!_preparationEditorVisible) {
      if (_steps.isNotEmpty) {
        return true;
      }
      _showPreparationError('Add at least one preparation step');
      return false;
    }

    final instruction = _preparationController.text.trim();
    if (instruction.isEmpty) {
      if (forContinue && _steps.isNotEmpty) {
        if (_editingPreparationIndex != null) {
          _showPreparationError('Enter a preparation step');
          return false;
        }
        setState(() {
          _preparationEditorVisible = false;
          _editingPreparationIndex = null;
          _preparationError = null;
          _preparationController.clear();
        });
        return true;
      }
      _showPreparationError(
        forContinue
            ? 'Add at least one preparation step'
            : 'Enter a preparation step',
      );
      return false;
    }

    final nextSteps = List<String>.of(_steps);
    final editingIndex = _editingPreparationIndex;
    if (editingIndex == null) {
      nextSteps.add(instruction);
    } else {
      nextSteps[editingIndex] = instruction;
    }
    setState(() {
      _steps = List<String>.unmodifiable(nextSteps);
      _preparationEditorVisible = false;
      _editingPreparationIndex = null;
      _preparationError = null;
      _isDirty = true;
      _preparationController.clear();
    });
    return true;
  }

  void _showPreparationError(String message) {
    setState(() {
      _preparationError = message;
    });
    _preparationFocusNode.requestFocus();
  }

  void _addPreparationStep() {
    if (_isSaving || _preparationEditorVisible) {
      return;
    }
    setState(() {
      _preparationController.clear();
      _editingPreparationIndex = null;
      _preparationEditorVisible = true;
      _preparationError = null;
    });
    _preparationFocusNode.requestFocus();
  }

  void _editPreparationStep(int index) {
    if (_isSaving || _preparationEditorVisible) {
      return;
    }
    setState(() {
      _preparationController.text = _steps[index];
      _editingPreparationIndex = index;
      _preparationEditorVisible = true;
      _preparationError = null;
    });
    _preparationFocusNode.requestFocus();
  }

  void _removePreparationStep(int index) {
    if (_isSaving) {
      return;
    }
    final nextSteps = List<String>.of(_steps)..removeAt(index);
    setState(() {
      _steps = List<String>.unmodifiable(nextSteps);
      if (_editingPreparationIndex != null &&
          index < _editingPreparationIndex!) {
        _editingPreparationIndex = _editingPreparationIndex! - 1;
      }
      if (_steps.isEmpty && !_preparationEditorVisible) {
        _preparationController.clear();
        _preparationEditorVisible = true;
        _editingPreparationIndex = null;
      }
      _preparationError = null;
      _isDirty = true;
    });
  }

  Future<void> _save() async {
    if (_isSaving || _isPickingImage || _stage != RecipeCreatorStage.review) {
      return;
    }

    late final NewRecipe newRecipe;
    try {
      newRecipe = NewRecipe.fromInput(
        name: _titleController.text,
        ingredients: _ingredients,
        steps: _steps,
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

  Future<void> _handleBack() async {
    if (_isSaving) {
      return;
    }
    if (_stage.index > 0) {
      _setStage(RecipeCreatorStage.values[_stage.index - 1]);
      return;
    }
    if (!_isDirty) {
      _pop(null);
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

  Widget _stageBody() {
    return switch (_stage) {
      RecipeCreatorStage.recipe => RecipeBasicsStep(
        titleController: _titleController,
        titleFocusNode: _titleFocusNode,
        imageFocusNode: _imageFocusNode,
        selectedImagePath: _selectedImagePath,
        titleError: _titleError,
        imageError: _imageError,
        isPickingImage: _isPickingImage,
        enabled: !_isSaving && !_isPickingImage,
        onTitleChanged: _titleChanged,
        onChooseImage: _chooseImage,
      ),
      RecipeCreatorStage.ingredients => IngredientWizardStep(
        ingredients: _ingredients,
        controllers: _ingredientControllers,
        editorVisible: _ingredientEditorVisible,
        editingIndex: _editingIngredientIndex,
        nameError: _ingredientNameError,
        enabled: !_isSaving,
        onChanged: _ingredientChanged,
        onSave: () => _commitIngredient(forContinue: false),
        onAdd: _addIngredient,
        onEdit: _editIngredient,
        onRemove: _removeIngredient,
      ),
      RecipeCreatorStage.preparation => PreparationWizardStep(
        steps: _steps,
        controller: _preparationController,
        focusNode: _preparationFocusNode,
        editorVisible: _preparationEditorVisible,
        editingIndex: _editingPreparationIndex,
        stepError: _preparationError,
        enabled: !_isSaving,
        onChanged: _preparationChanged,
        onSave: () => _commitPreparationStep(forContinue: false),
        onAdd: _addPreparationStep,
        onEdit: _editPreparationStep,
        onRemove: _removePreparationStep,
      ),
      RecipeCreatorStage.review => RecipeReviewStep(
        title: _titleController.text,
        imagePath: _selectedImagePath!,
        ingredients: _ingredients,
        steps: _steps,
        enabled: !_isSaving,
        onEditRecipe: () => _setStage(RecipeCreatorStage.recipe),
        onEditIngredients: () => _setStage(RecipeCreatorStage.ingredients),
        onEditPreparation: () => _setStage(RecipeCreatorStage.preparation),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Recipe>(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_allowPop) {
          _handleBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Create recipe')),
        body: Column(
          children: <Widget>[
            Expanded(
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
                        Semantics(
                          container: true,
                          header: true,
                          label:
                              '${_stage.title}. Step ${_stage.stepNumber} of '
                              '${RecipeCreatorStage.values.length}',
                          child: ExcludeSemantics(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Step ${_stage.stepNumber} of '
                                  '${RecipeCreatorStage.values.length}',
                                  key: const ValueKey<String>(
                                    'creator-stage-progress',
                                  ),
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _stage.title,
                                  key: const ValueKey<String>(
                                    'creator-stage-title',
                                  ),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _stageBody(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _WizardActions(
              stage: _stage,
              isSaving: _isSaving,
              enabled: !_isSaving && !_isPickingImage,
              onBack: _handleBack,
              onContinue: _continue,
            ),
          ],
        ),
      ),
    );
  }
}

class _WizardActions extends StatelessWidget {
  const _WizardActions({
    required this.stage,
    required this.isSaving,
    required this.enabled,
    required this.onBack,
    required this.onContinue,
  });

  final RecipeCreatorStage stage;
  final bool isSaving;
  final bool enabled;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final isReview = stage == RecipeCreatorStage.review;
    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.all(12),
        child: OverflowBar(
          spacing: 12,
          overflowSpacing: 8,
          alignment: MainAxisAlignment.spaceBetween,
          overflowAlignment: OverflowBarAlignment.end,
          children: <Widget>[
            OutlinedButton.icon(
              key: const ValueKey<String>('wizard-back'),
              onPressed: enabled ? onBack : null,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            ),
            FilledButton.icon(
              key: ValueKey<String>(
                isReview ? 'save-recipe' : 'wizard-continue',
              ),
              onPressed: enabled ? onContinue : null,
              icon: isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        key: ValueKey<String>('recipe-save-progress'),
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(isReview ? Icons.save_outlined : Icons.arrow_forward),
              label: Text(
                isSaving
                    ? 'Saving'
                    : isReview
                    ? 'Save recipe'
                    : 'Continue',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
