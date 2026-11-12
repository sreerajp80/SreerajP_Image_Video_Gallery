import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/pairing_payload.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/sync_role.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_purpose.dart';
import 'package:in_sreerajp_imgvidgal/providers/album_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/backup_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/settings_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/tag_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/vault_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/phone_move_data_service.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/sync_mark_dao.dart';
import 'package:in_sreerajp_imgvidgal/repositories/sync_mark_repository.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/device_identity_service.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/network_interface_service.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/qr_data_sync_service.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/received_media_service.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/sync_source_service.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/transfer_crypto_service.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/transfer_session_service.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Finds the device's own local network address.
final networkInterfaceServiceProvider = Provider<NetworkInterfaceService>((
  ref,
) {
  return NetworkInterfaceService();
});

/// Whether this device is on a local network it can transfer over.
///
/// Null means it is not, and the transfer screen says so instead of opening a
/// socket that could reach nobody.
final localNetworkAddressProvider = FutureProvider<LocalNetworkAddress?>((
  ref,
) async {
  return ref.watch(networkInterfaceServiceProvider).preferredAddress();
});

/// Session keys, wire ciphers, and the handshake proof.
final transferCryptoServiceProvider = Provider<TransferCryptoService>((ref) {
  return TransferCryptoService(channel: ref.watch(backupCryptoChannelProvider));
});

/// Puts arriving files into the gallery, and vault files into the vault.
final receivedMediaServiceProvider = Provider<ReceivedMediaService>((ref) {
  return ReceivedMediaService(
    mediaStore: ref.watch(mediaStoreChannelProvider),
    mediaRepository: ref.watch(mediaRepositoryProvider),
    mediaDao: ref.watch(mediaDaoProvider),
    tagRepository: ref.watch(tagRepositoryProvider),
    albumRepository: ref.watch(albumRepositoryProvider),
    vault: ref.watch(vaultTransferServiceProvider),
  );
});

/// Packs and reads the app data and settings of a phone move.
final phoneMoveDataServiceProvider = Provider<PhoneMoveDataService>((ref) {
  return PhoneMoveDataService(collector: ref.watch(backupCollectorProvider));
});

/// Phone move: whether the sender chose to include the private vault.
///
/// Turned on only after the vault was unlocked on this phone, and turned off
/// again whenever a send start screen opens or closes.
final phoneMoveIncludeVaultProvider = StateProvider<bool>((ref) => false);

/// This install's random id for Device Sync.
final deviceIdentityServiceProvider = Provider<DeviceIdentityService>((ref) {
  return DeviceIdentityService();
});

/// Data access over the "sent to that phone" marks.
final syncMarkDaoProvider = Provider<SyncMarkDao>((ref) => SyncMarkDao());

/// The only way the app reads or writes "sent to that phone" marks.
final syncMarkRepositoryProvider = Provider<SyncMarkRepository>((ref) {
  return SyncMarkRepository(dao: ref.watch(syncMarkDaoProvider));
});

/// Moves app data (not photos) between phones by QR codes.
final qrDataSyncServiceProvider = Provider<QrDataSyncService>((ref) {
  return QrDataSyncService(
    collector: ref.watch(backupCollectorProvider),
    crypto: ref.watch(backupCryptoChannelProvider),
    restore: ref.watch(restoreServiceProvider),
  );
});

/// Gathers the folders and albums the sender can pick from.
final syncSourceServiceProvider = Provider<SyncSourceService>((ref) {
  return SyncSourceService(
    albums: ref.watch(albumRepositoryProvider),
    marks: ref.watch(syncMarkRepositoryProvider),
  );
});

/// The send picker's folders and albums for one paired phone, by its id.
///
/// Read again after every send (the screen invalidates it), so the "sent X
/// of Y" numbers move as files go.
final syncSourcesProvider = FutureProvider.autoDispose
    .family<SyncSources, String>((ref, peerId) {
      final quickSend =
          ref.read(transferPurposeProvider) == TransferPurpose.quickSend;
      return ref
          .watch(syncSourceServiceProvider)
          .load(
            peerId: peerId,
            selection: quickSend
                ? ref.read(transferOutboxProvider)
                : const <MediaItem>[],
            selectionOnly: quickSend,
          );
    });

/// Drives one whole transfer.
///
/// Disposed with the provider scope, and the screen also stops it on the way
/// out and on backgrounding. Both, because "the listener lives only as long
/// as the transfer screen" has to survive the screen being torn down in ways
/// nobody planned for.
final transferSessionProvider = Provider<TransferSessionService>((ref) {
  final session = TransferSessionService(
    network: ref.watch(networkInterfaceServiceProvider),
    crypto: ref.watch(transferCryptoServiceProvider),
    received: ref.watch(receivedMediaServiceProvider),
    fileFor: (item) async {
      if (item.path.isEmpty) return null;
      final file = File(item.path);
      return await file.exists() ? file : null;
    },
    identity: ref.watch(deviceIdentityServiceProvider),
    marks: ref.watch(syncMarkRepositoryProvider),
    saveDigest: (id, sha256) =>
        ref.read(mediaDaoProvider).updateHashes(id, sha256: sha256),
    albumNamesFor: (item) async {
      final albums = ref.read(albumRepositoryProvider);
      final ids = (await albums.getAlbumIdsForMedia(item.id)).toSet();
      if (ids.isEmpty) return const <String>[];
      final all = await albums.getVirtualAlbums();
      return <String>[
        for (final album in all)
          if (ids.contains(album.id)) album.name,
      ];
    },
    buildAppData: () async {
      final version = await ref.read(appVersionProvider.future);
      return ref
          .read(phoneMoveDataServiceProvider)
          .build(appVersion: version, settings: ref.read(appSettingsProvider));
    },
    decodeAppData: (bytes) =>
        ref.read(phoneMoveDataServiceProvider).decode(bytes),
    vault: ref.watch(vaultTransferServiceProvider),
  );

  ref.onDispose(session.dispose);
  return session;
});

/// The transfer's state, as it changes.
///
/// Seeded with whatever the session already holds, so a rebuild mid-transfer
/// does not flash back to an idle screen.
final transferStateProvider = StreamProvider<TransferSessionState>((ref) {
  final session = ref.watch(transferSessionProvider);
  return session.states;
});

/// Media the user picked to send, carried from the selection to the screen.
///
/// Held here rather than passed as a route argument so a rebuild, a rotation,
/// or a return from the camera permission dialog does not lose the list.
final transferOutboxProvider = StateProvider<List<MediaItem>>(
  (ref) => const <MediaItem>[],
);

/// A pairing code that has been scanned and understood.
///
/// Null until the camera reads one, or the user types one that checks out.
final scannedPairingProvider = StateProvider<PairingPayload?>((ref) => null);

/// Which side of a transfer this device is taking.
final syncRoleProvider = StateProvider<SyncRole>((ref) => SyncRole.send);

/// Why the sending phone opened the transfer: a quick send of selected
/// photos, or a move to a new phone. Set by the screen that starts a send.
final transferPurposeProvider = StateProvider<TransferPurpose>(
  (ref) => TransferPurpose.quickSend,
);
