import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/media/delete_confirm_info.dart';

void main() {
  group('DeleteConfirmInfo', () {
    test('reads the platform map', () {
      final info = DeleteConfirmInfo.fromPlatform(<Object?, Object?>{
        'systemConfirmsDelete': true,
        'manageMediaSupported': true,
        'manageMediaGranted': false,
      });
      expect(info.systemConfirmsDelete, isTrue);
      expect(info.manageMediaSupported, isTrue);
      expect(info.manageMediaGranted, isFalse);
      expect(info.appMustConfirm, isFalse);
    });

    test('a bad or missing answer falls back to the app asking', () {
      expect(DeleteConfirmInfo.fromPlatform(null), DeleteConfirmInfo.fallback);
      expect(DeleteConfirmInfo.fromPlatform('yes'), DeleteConfirmInfo.fallback);
      expect(
        DeleteConfirmInfo.fromPlatform(<Object?, Object?>{
          'systemConfirmsDelete': 'true',
        }).appMustConfirm,
        isTrue,
      );
      expect(DeleteConfirmInfo.fallback.appMustConfirm, isTrue);
    });

    test('with Manage media on, the app asks', () {
      final info = DeleteConfirmInfo.fallback.copyWith(
        manageMediaSupported: true,
        manageMediaGranted: true,
      );
      expect(info.appMustConfirm, isTrue);
    });
  });
}
