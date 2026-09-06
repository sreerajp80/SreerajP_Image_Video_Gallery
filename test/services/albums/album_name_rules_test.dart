import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/services/albums/album_name_rules.dart';

void main() {
  group('AlbumNameRules.normalize', () {
    test('trims the ends', () {
      expect(AlbumNameRules.normalize('  Holiday  '), 'Holiday');
    });

    test('collapses runs of whitespace to one space', () {
      expect(AlbumNameRules.normalize('Trip   2026'), 'Trip 2026');
      expect(AlbumNameRules.normalize('Trip\t\n2026'), 'Trip 2026');
    });

    test('leaves an already clean name alone', () {
      expect(AlbumNameRules.normalize('Trip 2026'), 'Trip 2026');
    });
  });

  group('AlbumNameRules.check', () {
    test('accepts a plain name', () {
      final check = AlbumNameRules.check('Holiday');
      expect(check.isValid, isTrue);
      expect(check.normalized, 'Holiday');
      expect(check.error, isNull);
    });

    test('refuses an empty name', () {
      expect(AlbumNameRules.check('').error, AlbumNameError.empty);
      expect(AlbumNameRules.check('   ').error, AlbumNameError.empty);
    });

    test('allows exactly the maximum length', () {
      final name = 'a' * AlbumNameRules.maxLength;
      expect(AlbumNameRules.check(name).isValid, isTrue);
    });

    test('refuses one character over the maximum length', () {
      final name = 'a' * (AlbumNameRules.maxLength + 1);
      expect(AlbumNameRules.check(name).error, AlbumNameError.tooLong);
    });

    test('refuses a name already in use, ignoring case', () {
      final check = AlbumNameRules.check(
        'holiday',
        existingNames: const <String>['Holiday'],
      );
      expect(check.error, AlbumNameError.duplicate);
    });

    test('refuses a name that clashes only after normalizing', () {
      final check = AlbumNameRules.check(
        'Trip   2026',
        existingNames: const <String>['Trip 2026'],
      );
      expect(check.error, AlbumNameError.duplicate);
    });

    test('lets an album keep its own name when renaming', () {
      final check = AlbumNameRules.check(
        'Holiday',
        existingNames: const <String>['Holiday', 'Work'],
        ignoreName: 'Holiday',
      );
      expect(check.isValid, isTrue);
    });

    test('still refuses another album name while renaming', () {
      final check = AlbumNameRules.check(
        'Work',
        existingNames: const <String>['Holiday', 'Work'],
        ignoreName: 'Holiday',
      );
      expect(check.error, AlbumNameError.duplicate);
    });
  });
}
