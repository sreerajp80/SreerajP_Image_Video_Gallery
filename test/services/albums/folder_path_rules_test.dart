import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/services/albums/folder_path_rules.dart';

void main() {
  group('parentDirectory', () {
    test('takes the directory of a normal Android path', () {
      expect(
        FolderPathRules.parentDirectory('/storage/emulated/0/DCIM/a.jpg'),
        '/storage/emulated/0/DCIM',
      );
    });

    test('handles a Windows-style path', () {
      expect(FolderPathRules.parentDirectory(r'C:\Photos\a.jpg'), r'C:\Photos');
    });

    test('keeps the root separator for a file at the root', () {
      expect(FolderPathRules.parentDirectory('/a.jpg'), '/');
    });

    test('returns empty when there is no separator', () {
      expect(FolderPathRules.parentDirectory('a.jpg'), '');
    });

    test('ignores a trailing separator', () {
      expect(FolderPathRules.parentDirectory('/DCIM/Camera/'), '/DCIM');
    });
  });

  group('displayName', () {
    test('takes the last segment', () {
      expect(FolderPathRules.displayName('/DCIM/Camera'), 'Camera');
    });

    test('ignores a trailing separator', () {
      expect(FolderPathRules.displayName('/DCIM/Camera/'), 'Camera');
    });

    test('falls back to the whole value when there is no segment', () {
      expect(FolderPathRules.displayName('Camera'), 'Camera');
      expect(FolderPathRules.displayName('/'), '/');
    });
  });

  group('escapeLike', () {
    test('escapes a percent sign', () {
      expect(FolderPathRules.escapeLike('100%'), '100!%');
    });

    test('escapes an underscore', () {
      expect(FolderPathRules.escapeLike('a_b'), 'a!_b');
    });

    test('escapes the escape character itself, and does so first', () {
      expect(FolderPathRules.escapeLike('a!b'), 'a!!b');
      expect(FolderPathRules.escapeLike('!%'), '!!!%');
    });

    test('leaves an ordinary name untouched', () {
      expect(FolderPathRules.escapeLike('/DCIM/Camera'), '/DCIM/Camera');
    });
  });

  group('childLikePattern', () {
    test('appends a separator and a wildcard', () {
      expect(
        FolderPathRules.childLikePattern('/DCIM/Camera'),
        '/DCIM/Camera/%',
      );
    });

    test('does not double the separator at the root', () {
      expect(FolderPathRules.childLikePattern('/'), '/%');
    });

    test('ignores a trailing separator on the directory', () {
      expect(
        FolderPathRules.childLikePattern('/DCIM/Camera/'),
        '/DCIM/Camera/%',
      );
    });

    test('escapes wildcards inside the folder name', () {
      expect(FolderPathRules.childLikePattern('/DCIM/100%'), '/DCIM/100!%/%');
    });

    test('cannot match a sibling folder with a longer name', () {
      // "/DCIM/Camera%" would have matched "/DCIM/CameraRoll/a.jpg"; the
      // separator in the pattern is what stops it.
      expect(
        FolderPathRules.childLikePattern('/DCIM/Camera'),
        isNot(contains('Camera%')),
      );
    });
  });

  group('childPrefixLength', () {
    test('counts the directory plus its separator', () {
      expect(FolderPathRules.childPrefixLength('/DCIM/Camera'), 13);
    });

    test('counts one character at the root', () {
      expect(FolderPathRules.childPrefixLength('/'), 1);
    });

    test('lines up with where the file name starts', () {
      const directory = '/DCIM/Camera';
      const path = '/DCIM/Camera/a.jpg';
      final length = FolderPathRules.childPrefixLength(directory);
      expect(path.substring(length), 'a.jpg');
    });
  });

  group('isDirectlyInside', () {
    test('accepts a file in the folder', () {
      expect(
        FolderPathRules.isDirectlyInside('/DCIM/Camera/a.jpg', '/DCIM/Camera'),
        isTrue,
      );
    });

    test('refuses a file in a sub-folder', () {
      expect(
        FolderPathRules.isDirectlyInside(
          '/DCIM/Camera/2026/a.jpg',
          '/DCIM/Camera',
        ),
        isFalse,
      );
    });

    test('refuses a sibling folder with a longer name', () {
      expect(
        FolderPathRules.isDirectlyInside(
          '/DCIM/CameraRoll/a.jpg',
          '/DCIM/Camera',
        ),
        isFalse,
      );
    });

    test('ignores a trailing separator on the directory', () {
      expect(
        FolderPathRules.isDirectlyInside('/DCIM/Camera/a.jpg', '/DCIM/Camera/'),
        isTrue,
      );
    });
  });
}
