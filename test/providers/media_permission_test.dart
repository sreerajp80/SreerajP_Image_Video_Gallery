import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:in_sreerajp_imgvidgal/repositories/media_repository.dart';
import 'package:in_sreerajp_imgvidgal/services/media/media_permission_service.dart';
import 'package:in_sreerajp_imgvidgal/services/media/media_scanner_service.dart';
import 'package:in_sreerajp_imgvidgal/services/media/media_store_channel.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';

import '../services/media/fake_media_store_channel.dart';

class _TrackingFakeMediaStoreChannel extends FakeMediaStoreChannel {
  int requestPermissionsCount = 0;
  int checkPermissionsCount = 0;

  _TrackingFakeMediaStoreChannel({super.permissionStatus});

  @override
  Future<MediaPermissionStatus> checkPermissions() async {
    checkPermissionsCount++;
    return permissionStatus;
  }

  @override
  Future<MediaPermissionStatus> requestPermissions() async {
    requestPermissionsCount++;
    return permissionStatus;
  }
}

class _FakeMediaDao extends Fake implements MediaDao {}

void main() {
  group('MediaPermissionService', () {
    test('check returns current status from channel', () async {
      final channel = _TrackingFakeMediaStoreChannel(
        permissionStatus: MediaPermissionStatus.denied,
      );
      final service = MediaPermissionService(channel: channel);

      final status = await service.check();
      expect(status, MediaPermissionStatus.denied);
      expect(channel.checkPermissionsCount, 1);
    });

    test('request invokes channel requestPermissions', () async {
      final channel = _TrackingFakeMediaStoreChannel(
        permissionStatus: MediaPermissionStatus.granted,
      );
      final service = MediaPermissionService(channel: channel);

      final status = await service.request();
      expect(status, MediaPermissionStatus.granted);
      expect(channel.requestPermissionsCount, 1);
    });

    test('ensureGranted asks for permission if denied', () async {
      final channel = _TrackingFakeMediaStoreChannel(
        permissionStatus: MediaPermissionStatus.denied,
      );
      final service = MediaPermissionService(channel: channel);

      final status = await service.ensureGranted();
      expect(status, MediaPermissionStatus.denied);
      expect(channel.checkPermissionsCount, 1);
      expect(channel.requestPermissionsCount, 1);
    });

    test('ensureGranted returns immediately if permanentlyDenied', () async {
      final channel = _TrackingFakeMediaStoreChannel(
        permissionStatus: MediaPermissionStatus.permanentlyDenied,
      );
      final service = MediaPermissionService(channel: channel);

      final status = await service.ensureGranted();
      expect(status, MediaPermissionStatus.permanentlyDenied);
      expect(channel.checkPermissionsCount, 1);
      expect(channel.requestPermissionsCount, 0);
    });

    test('ensureGranted returns immediately if already granted', () async {
      final channel = _TrackingFakeMediaStoreChannel(
        permissionStatus: MediaPermissionStatus.granted,
      );
      final service = MediaPermissionService(channel: channel);

      final status = await service.ensureGranted();
      expect(status, MediaPermissionStatus.granted);
      expect(channel.checkPermissionsCount, 1);
      expect(channel.requestPermissionsCount, 0);
    });

    test('openSettings invokes openAppSettings on channel', () async {
      final channel = _TrackingFakeMediaStoreChannel();
      final service = MediaPermissionService(channel: channel);

      await service.openSettings();
      expect(channel.settingsOpenedCount, 1);
    });
  });

  group('MediaScanController', () {
    test(
      'scan notifies onPermissionChecked and returns empty scan when denied',
      () async {
        final channel = _TrackingFakeMediaStoreChannel(
          permissionStatus: MediaPermissionStatus.denied,
        );
        final permissionService = MediaPermissionService(channel: channel);
        final dao = _FakeMediaDao();
        final scanner = MediaScannerService(channel: channel, mediaDao: dao);
        final repository = MediaRepository(
          mediaDao: dao,
          scanner: scanner,
          channel: channel,
        );

        var permissionCheckedCalled = false;
        final controller = MediaScanController(
          repository: repository,
          permissionService: permissionService,
          onPermissionChecked: () {
            permissionCheckedCalled = true;
          },
        );

        await controller.scan();

        expect(permissionCheckedCalled, isTrue);
        expect(controller.state.value?.indexed, 0);
        expect(
          controller.state.value?.permissionStatus,
          MediaPermissionStatus.denied,
        );
      },
    );
  });
}
