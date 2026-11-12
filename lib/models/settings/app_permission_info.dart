/// How the app comes to hold (or not hold) an Android permission.
enum AppPermissionKind {
  /// A runtime permission: Android asks the user, who may say no.
  explicit,

  /// A normal permission: Android grants it at install, with no prompt.
  implicit,

  /// A special access: Android never prompts for it. It stays off until the
  /// user turns it on in Android settings.
  special,

  /// A permission a library asks for that the app removes from its manifest.
  removed,
}

/// Which friendly row a permission entry belongs to on the Permissions screen.
///
/// The screen maps each id to its localized name and reason.
enum AppPermissionId {
  photosVideos,
  camera,
  biometric,
  network,
  wifiState,
  networkState,
  changeWifi,
  receiverPrivate,
  wakeLock,
  recordAudio,
  writeStorage,
  manageMedia,
}

/// One Android permission name, with the Android versions it applies to.
class AndroidPermissionName {
  /// The name after `android.permission.` (or the full name if it has no
  /// such prefix), as written in the manifest.
  final String name;

  /// Lowest Android API level this name is used on, or null for all.
  final int? minApi;

  /// Highest Android API level this name is used on, or null for all.
  final int? maxApi;

  const AndroidPermissionName(this.name, {this.minApi, this.maxApi});
}

/// One row on the Permissions screen: a friendly group of Android permission
/// names that serve the same purpose.
class AppPermissionInfo {
  final AppPermissionId id;
  final AppPermissionKind kind;
  final List<AndroidPermissionName> androidNames;

  const AppPermissionInfo({
    required this.id,
    required this.kind,
    required this.androidNames,
  });

  AppPermissionInfo copyWith({
    AppPermissionId? id,
    AppPermissionKind? kind,
    List<AndroidPermissionName>? androidNames,
  }) {
    return AppPermissionInfo(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      androidNames: androidNames ?? this.androidNames,
    );
  }
}
