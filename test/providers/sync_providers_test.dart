import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/sync_role.dart';
import 'package:in_sreerajp_imgvidgal/providers/sync_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/network_interface_service.dart';

void main() {
  test('the transfer screen starts empty, as a sender, unpaired', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(transferOutboxProvider), isEmpty);
    expect(container.read(scannedPairingProvider), isNull);
    expect(container.read(syncRoleProvider), SyncRole.send);
  });

  test('the outbox holds what the user picked', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final item = MediaItem(
      id: 's1',
      path: '/storage/DCIM/Camera/S1.jpg',
      displayName: 'S1.jpg',
      mediaType: MediaType.image,
      mimeType: 'image/jpeg',
      size: 1000,
      dateAdded: DateTime(2026, 9),
      dateModified: DateTime(2026, 9),
    );

    container.read(transferOutboxProvider.notifier).state = <MediaItem>[item];

    expect(container.read(transferOutboxProvider).single.id, 's1');
  });

  test('no Wi-Fi interface means no local address', () async {
    final container = ProviderContainer(
      overrides: <Override>[
        networkInterfaceServiceProvider.overrideWithValue(
          NetworkInterfaceService(lister: () async => <NetworkInterface>[]),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(await container.read(localNetworkAddressProvider.future), isNull);
  });
}
