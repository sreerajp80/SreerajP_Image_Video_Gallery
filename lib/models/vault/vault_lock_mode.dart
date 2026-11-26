/// How the vault is opened.
///
/// Stored on its own, not inside the vault settings JSON, and read with one
/// fixed rule: a stored PIN with no mode means [vaultPin]. A vault made before
/// this choice existed may never have saved settings at all, and reading the
/// new default for it would quietly move it off its PIN.
enum VaultLockMode {
  /// Android's own prompt: a fingerprint, or the phone's PIN, pattern or
  /// password. The default for a new vault.
  phoneLock,

  /// The app's own 4 to 8 digit PIN. A fingerprint may be a shortcut, but
  /// the phone's PIN never opens the vault in this mode.
  vaultPin;

  /// The value written to storage.
  String get storageName => name;

  /// The mode for a stored value, or null when it is not one.
  static VaultLockMode? fromStorageName(String? value) {
    for (final mode in VaultLockMode.values) {
      if (mode.storageName == value) return mode;
    }
    return null;
  }
}
