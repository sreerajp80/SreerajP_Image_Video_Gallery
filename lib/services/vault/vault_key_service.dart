import 'package:in_sreerajp_imgvidgal/services/vault/vault_channel.dart';

/// Looks after the Android Keystore master key.
///
/// There is not much to it, and that is on purpose: the whole point of the
/// keystore is that the key is created, held, and used on the far side of the
/// channel. This class asks whether that worked and caches the answer, so the
/// gate screen can say plainly that the vault cannot be opened on this device
/// rather than failing later with a cipher error the user cannot act on.
class VaultKeyService {
  final VaultChannel _channel;

  /// Cached answer, so a screen rebuild does not walk the keystore again.
  bool? _ready;

  VaultKeyService({required VaultChannel channel}) : _channel = channel;

  /// Whether this device can hold the vault's master key.
  ///
  /// False means there is no usable hardware-backed keystore. The vault stays
  /// shut in that case: encrypting with a software key the app made up itself
  /// would look like a vault while giving almost none of its protection.
  Future<bool> isReady() async {
    final cached = _ready;
    if (cached != null) return cached;
    final ready = await _channel.isKeystoreReady();
    _ready = ready;
    return ready;
  }

  /// Creates the master key if this is the first time the vault is used.
  Future<void> ensureKey() => _channel.ensureMasterKey();

  /// Forgets the cached answer, so the next [isReady] asks Android again.
  void invalidate() => _ready = null;
}
