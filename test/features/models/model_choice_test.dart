import 'package:flutter_test/flutter_test.dart';
import 'package:offgrid_ai/core/database/app_database.dart';
import 'package:offgrid_ai/features/models/model_providers.dart';

InstalledModel model(
  int id,
  String name, {
  int size = 1,
  bool active = false,
  bool vision = false,
}) => InstalledModel(
  id: id,
  displayName: name,
  fileName: '$name.gguf',
  sizeBytes: size,
  isActive: active,
  installedAt: DateTime(2026),
  projectorFileName: vision ? 'mmproj.gguf' : null,
);

void main() {
  group('textModelOf', () {
    test('is the active model when it is text-only', () {
      final big = model(1, 'big', size: 3);
      final small = model(2, 'small', active: true);
      expect(textModelOf([big, small]), small);
    });

    test('an active vision model hands text to the largest text model', () {
      final vision = model(1, 'vision', size: 9, active: true, vision: true);
      final big = model(2, 'big', size: 3);
      final small = model(3, 'small');
      expect(textModelOf([vision, small, big]), big);
    });

    test('a lone vision model answers text too', () {
      final vision = model(1, 'vision', active: true, vision: true);
      expect(textModelOf([vision]), vision);
      expect(textModelOf([]), isNull);
    });
  });

  group('visionModelOf', () {
    test('is the active model when it can see', () {
      final a = model(1, 'a', size: 9, vision: true);
      final b = model(2, 'b', active: true, vision: true);
      expect(visionModelOf([a, b]), b);
    });

    test('otherwise the largest vision model, or none', () {
      final text = model(1, 'text', active: true);
      final a = model(2, 'a', size: 2, vision: true);
      final b = model(3, 'b', size: 5, vision: true);
      expect(visionModelOf([text, a, b]), b);
      expect(visionModelOf([text]), isNull);
    });
  });
}
