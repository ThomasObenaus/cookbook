enum RecipeCreatorStage {
  recipe('Recipe'),
  ingredients('Ingredients'),
  preparation('Preparation'),
  review('Review');

  const RecipeCreatorStage(this.title);

  final String title;

  int get stepNumber => index + 1;
}
