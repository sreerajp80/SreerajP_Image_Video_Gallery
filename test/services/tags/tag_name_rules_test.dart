import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/services/tags/tag_name_rules.dart';

void main() {
  group('TagNameRules.normalize', () {
    test('trims the ends', () {
      expect(TagNameRules.normalize('  beach  '), 'beach');
    });

    test('collapses runs of inner whitespace', () {
      // Otherwise "beach  holiday" and "beach holiday" would be two tags that
      // look identical in the list.
      expect(TagNameRules.normalize('beach   holiday'), 'beach holiday');
      expect(TagNameRules.normalize('beach\tholiday'), 'beach holiday');
    });

    test('leaves a normal name alone', () {
      expect(TagNameRules.normalize('Family 2026'), 'Family 2026');
    });
  });

  group('TagNameRules.isSameName', () {
    test('ignores case', () {
      expect(TagNameRules.isSameName('Beach', 'beach'), isTrue);
    });

    test('ignores surrounding and repeated spaces', () {
      expect(TagNameRules.isSameName(' beach  day ', 'Beach Day'), isTrue);
    });

    test('different names are different', () {
      expect(TagNameRules.isSameName('beach', 'beaches'), isFalse);
    });
  });

  group('TagNameRules.check', () {
    test('accepts a good name and returns it cleaned up', () {
      final check = TagNameRules.check('  Beach   Day ');

      expect(check.isValid, isTrue);
      expect(check.normalized, 'Beach Day');
    });

    test('refuses a blank name', () {
      expect(TagNameRules.check('').error, TagNameError.empty);
      expect(TagNameRules.check('    ').error, TagNameError.empty);
    });

    test('refuses a name over the length cap', () {
      final tooLong = 'a' * (TagNameRules.maxLength + 1);

      expect(TagNameRules.check(tooLong).error, TagNameError.tooLong);
      expect(TagNameRules.check('a' * TagNameRules.maxLength).isValid, isTrue);
    });

    test('refuses a name already in use, whatever its case', () {
      final check = TagNameRules.check(
        'beach',
        existingNames: <String>['Holiday', 'Beach'],
      );

      expect(check.error, TagNameError.duplicate);
    });

    test('a rename may keep its own name', () {
      // Fixing only the letter case of a tag must not be refused as a clash
      // with itself.
      final check = TagNameRules.check(
        'Beach',
        existingNames: <String>['beach', 'Holiday'],
        ignoreName: 'beach',
      );

      expect(check.isValid, isTrue);
      expect(check.normalized, 'Beach');
    });

    test('a rename onto another existing tag is still refused', () {
      final check = TagNameRules.check(
        'Holiday',
        existingNames: <String>['beach', 'Holiday'],
        ignoreName: 'beach',
      );

      expect(check.error, TagNameError.duplicate);
    });
  });
}
