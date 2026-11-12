import 'package:flutter/foundation.dart';

/// Whether Android itself will ask before the app deletes a photo, and the
/// state of the optional "Manage media" special access (Android 12+).
///
/// The app shows its own "Delete permanently?" dialog only when Android will
/// not, so after the delete choice sheet the user is asked exactly once.
@immutable
class DeleteConfirmInfo {
  /// True when Android always shows its own prompt before a delete or an
  /// overwrite (Android 11+, "Manage media" off). Android 10 is false: it
  /// deletes the app's own files with no prompt.
  final bool systemConfirmsDelete;

  /// True on Android 12+, where "Manage media" exists.
  final bool manageMediaSupported;

  /// True when the user has turned "Manage media" on for this app.
  final bool manageMediaGranted;

  const DeleteConfirmInfo({
    required this.systemConfirmsDelete,
    required this.manageMediaSupported,
    required this.manageMediaGranted,
  });

  /// Used when the answer is unknown. Says Android will not ask, so the app
  /// asks itself: the worst case is one extra dialog, never none.
  static const DeleteConfirmInfo fallback = DeleteConfirmInfo(
    systemConfirmsDelete: false,
    manageMediaSupported: false,
    manageMediaGranted: false,
  );

  /// Reads the map sent by the platform channel. Anything missing or of the
  /// wrong type falls back to the safe value.
  factory DeleteConfirmInfo.fromPlatform(Object? raw) {
    if (raw is! Map) return fallback;
    bool read(String key) => raw[key] == true;
    return DeleteConfirmInfo(
      systemConfirmsDelete: read('systemConfirmsDelete'),
      manageMediaSupported: read('manageMediaSupported'),
      manageMediaGranted: read('manageMediaGranted'),
    );
  }

  /// Whether the app must show its own confirmation before a permanent
  /// delete, because Android will not.
  bool get appMustConfirm => !systemConfirmsDelete;

  DeleteConfirmInfo copyWith({
    bool? systemConfirmsDelete,
    bool? manageMediaSupported,
    bool? manageMediaGranted,
  }) {
    return DeleteConfirmInfo(
      systemConfirmsDelete: systemConfirmsDelete ?? this.systemConfirmsDelete,
      manageMediaSupported: manageMediaSupported ?? this.manageMediaSupported,
      manageMediaGranted: manageMediaGranted ?? this.manageMediaGranted,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DeleteConfirmInfo &&
      other.systemConfirmsDelete == systemConfirmsDelete &&
      other.manageMediaSupported == manageMediaSupported &&
      other.manageMediaGranted == manageMediaGranted;

  @override
  int get hashCode => Object.hash(
    systemConfirmsDelete,
    manageMediaSupported,
    manageMediaGranted,
  );
}
