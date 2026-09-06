import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/pairing_payload.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/sync_role.dart';
import 'package:in_sreerajp_imgvidgal/providers/backup_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/tag_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/network_interface_service.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/received_media_service.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/transfer_crypto_service.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/transfer_session_service.dart';

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

/// Puts arriving files into the gallery.
final receivedMediaServiceProvider = Provider<ReceivedMediaService>((ref) {
  return ReceivedMediaService(
    mediaStore: ref.watch(mediaStoreChannelProvider),
    mediaRepository: ref.watch(mediaRepositoryProvider),
    mediaDao: ref.watch(mediaDaoProvider),
    tagRepository: ref.watch(tagRepositoryProvider),
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
