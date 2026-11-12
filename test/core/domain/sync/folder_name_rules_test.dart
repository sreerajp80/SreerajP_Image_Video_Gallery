import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/core/domain/sync/folder_name_rules.dart';

void main() {
  group('a folder name from another phone is never trusted', () {
    test('an ordinary name is kept', () {
      expect(FolderNameRules.safeFolderName('Camera'), 'Camera');
      expect(
        FolderNameRules.safeFolderName('WhatsApp Images'),
        'WhatsApp Images',
      );
    });

    test('Malayalam and Devanagari names are kept as they are', () {
      expect(FolderNameRules.safeFolderName('ചിത്രങ്ങൾ'), 'ചിത്രങ്ങൾ');
      expect(FolderNameRules.safeFolderName('चित्राणि'), 'चित्राणि');
    });

    test('a path keeps only its last part', () {
      expect(FolderNameRules.safeFolderName('DCIM/Camera'), 'Camera');
      expect(FolderNameRules.safeFolderName(r'a\b\Trip'), 'Trip');
    });

    test('parent references and hidden names are refused', () {
      expect(FolderNameRules.safeFolderName('..'), isNull);
      expect(FolderNameRules.safeFolderName('../../Android/data'), 'data');
      expect(FolderNameRules.safeFolderName('.secret'), 'secret');
    });

    test('control and refused characters are removed', () {
      expect(FolderNameRules.safeFolderName('A\u0000B:C*?'), 'ABC');
    });

    test('empty and missing names give null', () {
      expect(FolderNameRules.safeFolderName(null), isNull);
      expect(FolderNameRules.safeFolderName(''), isNull);
      expect(FolderNameRules.safeFolderName('///'), isNull);
    });

    test('a very long name is cut', () {
      final name = FolderNameRules.safeFolderName('x' * 300)!;
      expect(name.length, FolderNameRules.maxLength);
    });
  });

  group('receiveDirectoryFor', () {
    test('puts a named folder inside the receive folder', () {
      expect(
        FolderNameRules.receiveDirectoryFor('Camera'),
        '${AppConstants.syncReceiveDirectoryName}/Camera',
      );
    });

    test('uses the receive folder alone when there is no usable name', () {
      expect(
        FolderNameRules.receiveDirectoryFor('..'),
        AppConstants.syncReceiveDirectoryName,
      );
      expect(
        FolderNameRules.receiveDirectoryFor(null),
        AppConstants.syncReceiveDirectoryName,
      );
    });
  });
}
