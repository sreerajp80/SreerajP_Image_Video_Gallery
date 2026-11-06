/// Where an edited copy was written.
class SaveOutcome {
  /// Full path of the new file.
  final String path;

  /// Size of the new file in bytes.
  final int sizeBytes;

  const SaveOutcome({required this.path, required this.sizeBytes});
}
