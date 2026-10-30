import 'package:flutter_test/flutter_test.dart';
import 'package:offgrid_ai/features/models/data/model_catalog.dart';

void main() {
  test(
    'catalog entries are distinct, verifiable and permissively licensed',
    () {
      final models = ModelCatalog.models;
      expect(models.length, greaterThanOrEqualTo(3));
      expect(models.map((m) => m.fileName).toSet().length, models.length);
      expect(models.map((m) => m.displayName).toSet().length, models.length);
      for (final m in models) {
        expect(m.sha256, matches(RegExp(r'^[0-9a-f]{64}$')));
        expect(m.sizeBytes, greaterThan(500 << 20));
        expect(m.url.host, 'huggingface.co');
        expect(m.license, 'Apache-2.0');
      }
      expect(ModelCatalog.recommended.fileName, contains('Q4_0'));
    },
  );

  test('an install from the single-model catalog still counts', () {
    final standard = ModelCatalog.models.firstWhere(
      (m) => m.fileName.contains('Q4_K_M'),
    );
    expect(
      ModelCatalog.isInstalled(
        standard,
        'Qwen3-4B-Instruct-2507-Q4_K_M.gguf',
        'Qwen3 4B Instruct',
      ),
      isTrue,
    );
    expect(
      ModelCatalog.isInstalled(ModelCatalog.recommended, 'x.gguf', 'Other'),
      isFalse,
    );
  });
}
