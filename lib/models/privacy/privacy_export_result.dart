/// How a privacy export ended. The screen turns this into a message.
enum PrivacyExportResult {
  /// The copy was shared or saved.
  done,

  /// The original could not be read (gone, too large, or no access).
  unreadable,

  /// The share sheet could not be opened.
  shareFailed,

  /// Something else went wrong while cleaning or saving the copy.
  failed,
}
