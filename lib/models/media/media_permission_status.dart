/// Permission state reported by the Android media permission flow.
enum MediaPermissionStatus {
  /// Full access to images and videos.
  granted,

  /// Android 14+ "selected photos" access — only some items are visible.
  partial,

  /// Denied, but the system will ask again.
  denied,

  /// Denied with "Don't ask again"; only app settings can change it.
  permanentlyDenied;

  /// Whether any media at all can be read.
  bool get canRead =>
      this == MediaPermissionStatus.granted ||
      this == MediaPermissionStatus.partial;

  /// Parses the string sent by the native channel, defaulting to [denied].
  static MediaPermissionStatus fromString(String? value) {
    return MediaPermissionStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => MediaPermissionStatus.denied,
    );
  }
}
