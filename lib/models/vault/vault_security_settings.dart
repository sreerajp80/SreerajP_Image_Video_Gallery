import 'package:flutter/foundation.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';

/// Immutable vault security preferences.
///
/// Stored as JSON in secure storage rather than in `SharedPreferences`,
/// because the shape of someone's vault settings is itself a hint about what
/// they keep in it.
@immutable
class VaultSecuritySettings {
  /// Idle seconds before the vault shuts itself.
  final int autoLockSeconds;

  /// Whether a fingerprint or face may open the vault.
  ///
  /// The PIN always works whatever this says; this only controls the shortcut.
  final bool biometricEnabled;

  /// Overwrite passes a shred makes.
  final int shredPasses;

  /// Whether the import sheet starts with "shred the original" chosen.
  ///
  /// Even when this is on, the shred still needs its own confirmation.
  final bool shredOnImportByDefault;

  const VaultSecuritySettings({
    this.autoLockSeconds = AppConstants.vaultAutoLockTimeoutSeconds,
    this.biometricEnabled = true,
    this.shredPasses = AppConstants.vaultDefaultShredPasses,
    this.shredOnImportByDefault = false,
  });

  /// What a brand new vault starts with.
  static const VaultSecuritySettings defaults = VaultSecuritySettings();

  /// Creates a copy with updated properties.
  VaultSecuritySettings copyWith({
    int? autoLockSeconds,
    bool? biometricEnabled,
    int? shredPasses,
    bool? shredOnImportByDefault,
  }) {
    return VaultSecuritySettings(
      autoLockSeconds: autoLockSeconds ?? this.autoLockSeconds,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      shredPasses: shredPasses ?? this.shredPasses,
      shredOnImportByDefault:
          shredOnImportByDefault ?? this.shredOnImportByDefault,
    );
  }

  /// Converts to a JSON-ready map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'auto_lock_seconds': autoLockSeconds,
      'biometric_enabled': biometricEnabled,
      'shred_passes': shredPasses,
      'shred_on_import': shredOnImportByDefault,
    };
  }

  /// Reads settings back, falling back to the defaults field by field.
  ///
  /// Values are clamped to what the app actually offers, so a hand-edited or
  /// corrupted store can never produce a vault that never locks or a shred
  /// that runs a thousand passes.
  factory VaultSecuritySettings.fromJson(Map<String, dynamic> json) {
    final rawTimeout = json['auto_lock_seconds'];
    final timeout = rawTimeout is int ? rawTimeout : null;
    return VaultSecuritySettings(
      autoLockSeconds:
          timeout != null &&
              AppConstants.vaultAutoLockChoicesSeconds.contains(timeout)
          ? timeout
          : AppConstants.vaultAutoLockTimeoutSeconds,
      biometricEnabled: json['biometric_enabled'] is bool
          ? json['biometric_enabled'] as bool
          : true,
      shredPasses: json['shred_passes'] is int
          ? (json['shred_passes'] as int).clamp(
              AppConstants.vaultMinShredPasses,
              AppConstants.vaultMaxShredPasses,
            )
          : AppConstants.vaultDefaultShredPasses,
      shredOnImportByDefault: json['shred_on_import'] is bool
          ? json['shred_on_import'] as bool
          : false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VaultSecuritySettings &&
          runtimeType == other.runtimeType &&
          autoLockSeconds == other.autoLockSeconds &&
          biometricEnabled == other.biometricEnabled &&
          shredPasses == other.shredPasses &&
          shredOnImportByDefault == other.shredOnImportByDefault;

  @override
  int get hashCode => Object.hash(
    autoLockSeconds,
    biometricEnabled,
    shredPasses,
    shredOnImportByDefault,
  );
}
