import 'package:in_sreerajp_imgvidgal/services/vault/vault_channel.dart';

/// Turns Android's `FLAG_SECURE` on and off.
///
/// With the flag set, Android refuses screenshots and screen recording for the
/// app window, and shows a blank card in the recent-apps switcher instead of a
/// picture of whatever was on screen. That last part matters as much as the
/// first: without it, backgrounding the vault leaves a thumbnail of a private
/// photo sitting in the switcher for anyone to see.
///
/// Requests are counted rather than set, on both sides of the channel. A vault
/// viewer opening on top of the vault grid asks for the flag too, and when the
/// viewer closes the grid is still on screen and still needs it.
///
/// Deliberately scoped to the vault screens. Setting it for the whole app
/// would stop the user screenshotting an ordinary holiday photo, which is not
/// what anybody asked for.
abstract class SecureWindowService {
  /// Asks for the secure flag. Every call must be matched by a [release].
  Future<void> acquire();

  /// Gives up one request for the secure flag.
  Future<void> release();
}

/// The real service, over the vault channel.
class PlatformSecureWindowService implements SecureWindowService {
  final VaultChannel _channel;

  PlatformSecureWindowService({required VaultChannel channel})
    : _channel = channel;

  @override
  Future<void> acquire() => _channel.setSecureFlag(true);

  @override
  Future<void> release() => _channel.setSecureFlag(false);
}
