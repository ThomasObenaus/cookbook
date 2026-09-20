import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('registered recipe assets load from the root bundle', () async {
    final source = await rootBundle.loadString('assets/data/recipes.json');
    final decoded = jsonDecode(source) as List<Object?>;

    expect(decoded, hasLength(8));
    for (final value in decoded) {
      final recipe = value! as Map<String, Object?>;
      expect(recipe['image'], <String, Object?>{
        'kind': 'asset',
        'path': 'assets/images/recipe_placeholder.png',
      });
    }

    final imageData = await rootBundle.load(
      'assets/images/recipe_placeholder.png',
    );
    final codec = await ui.instantiateImageCodec(
      imageData.buffer.asUint8List(
        imageData.offsetInBytes,
        imageData.lengthInBytes,
      ),
    );
    final frame = await codec.getNextFrame();

    expect(frame.image.width, 1200);
    expect(frame.image.height, 900);

    frame.image.dispose();
    codec.dispose();
  });
}
