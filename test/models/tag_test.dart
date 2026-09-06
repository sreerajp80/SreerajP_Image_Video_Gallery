import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/tag.dart';

void main() {
  group('Tag Domain Model', () {
    final now = DateTime(2026, 8, 29, 9, 0, 0);
    final testTag = Tag(
      id: 'tag_001',
      name: 'Mountains',
      colorValue: 0xFF4CAF50,
      description: 'Photos taken during hill hikes',
      itemCount: 15,
      dateCreated: now,
    );

    test('supports value equality', () {
      final duplicate = Tag(
        id: 'tag_001',
        name: 'Mountains',
        colorValue: 0xFF4CAF50,
        description: 'Photos taken during hill hikes',
        itemCount: 15,
        dateCreated: now,
      );

      expect(testTag, equals(duplicate));
    });

    test('copyWith updates properties properly', () {
      final modified = testTag.copyWith(name: 'Highlands', itemCount: 20);
      expect(modified.name, 'Highlands');
      expect(modified.itemCount, 20);
      expect(modified.colorValue, 0xFF4CAF50);
    });

    test('serialization roundtrip via toMap and fromMap', () {
      final map = testTag.toMap();
      final fromMap = Tag.fromMap(map);

      expect(fromMap.id, testTag.id);
      expect(fromMap.name, testTag.name);
      expect(fromMap.colorValue, testTag.colorValue);
      expect(fromMap.description, testTag.description);
      expect(fromMap.itemCount, testTag.itemCount);
    });
  });
}
