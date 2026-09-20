enum RecipeImageKind { asset, file }

class RecipeImage {
  factory RecipeImage.asset(String path) {
    return RecipeImage._(kind: RecipeImageKind.asset, path: _validPath(path));
  }

  factory RecipeImage.file(String path) {
    return RecipeImage._(kind: RecipeImageKind.file, path: _validPath(path));
  }

  factory RecipeImage.fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      throw const FormatException('Recipe.image must be a JSON object.');
    }

    final kind = json['kind'];
    final path = json['path'];
    if (kind is! String) {
      throw const FormatException('Recipe.image.kind must be a string.');
    }
    if (path is! String) {
      throw const FormatException('Recipe.image.path must be a string.');
    }

    return switch (kind) {
      'asset' => RecipeImage.asset(path),
      'file' => RecipeImage.file(path),
      _ => throw FormatException('Unsupported recipe image kind: $kind.'),
    };
  }

  const RecipeImage._({required this.kind, required this.path});

  final RecipeImageKind kind;
  final String path;

  Map<String, Object?> toJson() => <String, Object?>{
    'kind': kind.name,
    'path': path,
  };
}

String _validPath(String value) {
  final path = value.trim();
  if (path.isEmpty) {
    throw const FormatException('Recipe.image.path must not be empty.');
  }
  return path;
}
