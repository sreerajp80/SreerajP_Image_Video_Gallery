/// Constants defining database tables, columns, indexes, and schema definitions.
class DatabaseConstants {
  const DatabaseConstants._();

  /// SQLite database filename.
  static const String databaseName = 'gallery_database.db';

  /// Current SQLite database schema version.
  static const int schemaVersion = 3;

  // Table Names
  static const String tableMedia = 'media_items';
  static const String tableAlbums = 'albums';
  static const String tableAlbumMedia = 'album_media_entries';
  static const String tableTags = 'tags';
  static const String tableMediaTags = 'media_tag_entries';
  static const String tableVault = 'vault_items';
  static const String tableMediaSearchFts = 'media_search_fts';

  // Common Columns
  static const String colId = 'id';
  static const String colName = 'name';

  // Media Columns
  static const String colMediaPath = 'path';
  static const String colMediaUri = 'uri';
  static const String colMediaDisplayName = 'display_name';
  static const String colMediaType = 'media_type';
  static const String colMediaMimeType = 'mime_type';
  static const String colMediaSizeBytes = 'size_bytes';
  static const String colMediaDateAdded = 'date_added';
  static const String colMediaDateModified = 'date_modified';
  static const String colMediaDateTaken = 'date_taken';
  static const String colMediaDurationMs = 'duration_ms';
  static const String colMediaWidth = 'width';
  static const String colMediaHeight = 'height';
  static const String colMediaOrientation = 'orientation';
  static const String colMediaIsFavorite = 'is_favorite';
  static const String colMediaIsVaulted = 'is_vaulted';
  static const String colMediaIsTrash = 'is_trash';
  static const String colMediaExifJson = 'exif_json';
  static const String colMediaUserNotes = 'user_notes';
  static const String colMediaSha256Hash = 'sha256_hash';
  static const String colMediaPHash = 'p_hash';
  static const String colMediaLatitude = 'latitude';
  static const String colMediaLongitude = 'longitude';
  static const String colMediaAddress = 'address';

  // Album Columns
  static const String colAlbumType = 'album_type';
  static const String colAlbumRelativeFolderPath = 'relative_folder_path';
  static const String colAlbumCoverMediaId = 'cover_media_id';
  static const String colAlbumCoverPath = 'cover_path';
  static const String colAlbumItemCount = 'item_count';
  static const String colAlbumDateCreated = 'date_created';
  static const String colAlbumDateModified = 'date_modified';
  static const String colAlbumIsPinned = 'is_pinned';
  static const String colAlbumSortOrder = 'sort_order';

  // Album Media Junction Columns
  static const String colAlbumMediaAlbumId = 'album_id';
  static const String colAlbumMediaMediaId = 'media_id';
  static const String colAlbumMediaPosition = 'position';
  static const String colAlbumMediaDateAdded = 'date_added';

  // Tag Columns
  static const String colTagColorValue = 'color_value';
  static const String colTagDescription = 'description';
  static const String colTagItemCount = 'item_count';
  static const String colTagDateCreated = 'date_created';

  // Media Tag Junction Columns
  static const String colMediaTagMediaId = 'media_id';
  static const String colMediaTagTagId = 'tag_id';
  static const String colMediaTagDateTagged = 'date_tagged';

  // Vault Columns
  static const String colVaultOriginalPath = 'original_path';
  static const String colVaultOriginalFilename = 'original_filename';
  static const String colVaultEncryptedFilename = 'encrypted_filename';
  static const String colVaultEncryptedThumbnailFilename =
      'encrypted_thumbnail_filename';
  static const String colVaultMediaType = 'media_type';
  static const String colVaultMimeType = 'mime_type';
  static const String colVaultSizeBytes = 'size_bytes';
  static const String colVaultIv = 'iv';

  /// Initialisation vector of the encrypted preview.
  ///
  /// Its own, separate from [colVaultIv]. Each file is encrypted with a fresh
  /// IV, so the payload's cannot decrypt the preview beside it.
  static const String colVaultThumbnailIv = 'thumbnail_iv';
  static const String colVaultAuthTag = 'auth_tag';
  static const String colVaultDateVaulted = 'date_vaulted';
  static const String colVaultDateTaken = 'date_taken';
  static const String colVaultWidth = 'width';
  static const String colVaultHeight = 'height';
  static const String colVaultDurationMs = 'duration_ms';
  static const String colVaultTagsJson = 'tags_json';
  static const String colVaultNotes = 'notes';

  // FTS Search Virtual Table Columns
  static const String colFtsMediaId = 'media_id';
  static const String colFtsDisplayName = 'display_name';
  static const String colFtsUserNotes = 'user_notes';
  static const String colFtsTagsContent = 'tags_content';
  static const String colFtsExifSearchText = 'exif_search_text';
  static const String colFtsAddress = 'address';
}
