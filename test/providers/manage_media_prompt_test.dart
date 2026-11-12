import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/media/delete_confirm_info.dart';
import 'package:in_sreerajp_imgvidgal/models/media/media_permission_status.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';

import '../services/media/fake_media_store_channel.dart';

void main() {
  const off = DeleteConfirmInfo(
    systemConfirmsDelete: true,
    manageMediaSupported: true,
    manageMediaGranted: false,
  );

  group('shouldPromptManageMedia', () {
    bool check({
      DeleteConfirmInfo info = off,
      MediaPermissionStatus status = MediaPermissionStatus.granted,
      bool alreadyShown = false,
    }) => shouldPromptManageMedia(
      info: info,
      status: status,
      alreadyShown: alreadyShown,
    );

    test('asks on Android 12+ while off, with full access', () {
      expect(check(), isTrue);
    });

    test('each condition alone stops it', () {
      expect(check(alreadyShown: true), isFalse);
      expect(check(info: off.copyWith(manageMediaSupported: false)), isFalse);
      expect(check(info: off.copyWith(manageMediaGranted: true)), isFalse);
      expect(check(status: MediaPermissionStatus.partial), isFalse);
      expect(check(status: MediaPermissionStatus.denied), isFalse);
      expect(check(status: MediaPermissionStatus.permanentlyDenied), isFalse);
    });
  });

  group('ManageMediaPromptController', () {
    ProviderContainer containerWith(DeleteConfirmInfo info) {
      final channel = FakeMediaStoreChannel()..deleteInfo = info;
      final container = ProviderContainer(
        overrides: [mediaStoreChannelProvider.overrideWithValue(channel)],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('asks only once per app start', () async {
      final container = containerWith(off);
      final notifier = container.read(manageMediaPromptProvider.notifier);

      expect(await notifier.takePrompt(MediaPermissionStatus.granted), isTrue);
      expect(await notifier.takePrompt(MediaPermissionStatus.granted), isFalse);
    });

    test('does not ask, and stays ready, when it is already on', () async {
      final container = containerWith(off.copyWith(manageMediaGranted: true));
      final notifier = container.read(manageMediaPromptProvider.notifier);

      expect(await notifier.takePrompt(MediaPermissionStatus.granted), isFalse);
      expect(container.read(manageMediaPromptProvider), isFalse);
    });

    test('a fresh start asks again', () async {
      final first = containerWith(off);
      expect(
        await first
            .read(manageMediaPromptProvider.notifier)
            .takePrompt(MediaPermissionStatus.granted),
        isTrue,
      );
      final second = containerWith(off);
      expect(
        await second
            .read(manageMediaPromptProvider.notifier)
            .takePrompt(MediaPermissionStatus.granted),
        isTrue,
      );
    });
  });
}
