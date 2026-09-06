class AppConstants {
  AppConstants._();

  // Database
  static const String databaseName = 'gallery_database.db';
  static const int databaseVersion = 2;

  // Language & Preferences
  /// Language codes the app ships translations for.
  ///
  /// Anything outside this set is ignored when settings are read, so a
  /// hand-edited file cannot ask for a language that has no strings.
  static const Set<String> supportedLocaleCodes = <String>{'en', 'ml'};

  /// File the user's preferences are kept in, inside the app support
  /// directory.
  ///
  /// A plain JSON file, not secure storage: none of these values is a secret.
  static const String appSettingsFileName = 'app_settings.json';

  // Grid Defaults
  static const int minGridColumns = 1;
  static const int maxGridColumns = 5;
  static const int defaultGridColumns = 3;

  // Cache & Performance
  static const int defaultThumbnailSize = 256;
  static const int maxMemoryCacheItems = 500;

  // Vault Security
  static const int vaultAutoLockTimeoutSeconds = 60;
  static const String vaultStorageDirectoryName = '.secure_vault';

  // Media Scanning
  /// Number of MediaStore rows fetched per platform channel page.
  static const int scanBatchSize = 200;

  /// Method channel name used for all Android MediaStore calls.
  static const String mediaStoreChannelName =
      'in.sreerajp.imgvidgal/mediastore';

  // Thumbnail Cache Tiers (memory entries, pixel size, disk byte budget)
  /// Devices with less than this much RAM use the low memory tier.
  static const int lowMemoryThresholdBytes = 4 * 1024 * 1024 * 1024;

  /// Devices with at least this much RAM use the high memory tier.
  static const int highMemoryThresholdBytes = 6 * 1024 * 1024 * 1024;

  static const int lowTierThumbnailSize = 256;
  static const int mediumTierThumbnailSize = 384;
  static const int highTierThumbnailSize = 512;

  static const int lowTierMemoryCacheItems = 100;
  static const int mediumTierMemoryCacheItems = 300;
  static const int highTierMemoryCacheItems = 500;

  static const int lowTierMemoryCacheBytes = 24 * 1024 * 1024;
  static const int mediumTierMemoryCacheBytes = 64 * 1024 * 1024;
  static const int highTierMemoryCacheBytes = 128 * 1024 * 1024;

  static const int lowTierDiskCacheBytes = 128 * 1024 * 1024;
  static const int mediumTierDiskCacheBytes = 256 * 1024 * 1024;
  static const int highTierDiskCacheBytes = 512 * 1024 * 1024;

  /// Folder inside the app cache directory holding generated thumbnails.
  static const String thumbnailCacheDirectoryName = 'thumbnails';

  /// JPEG quality used when re-encoding fallback thumbnails.
  static const int thumbnailJpegQuality = 82;

  // Fullscreen Viewer & Video Player
  /// Method channel name used for screen brightness, volume, and keep-awake.
  static const String playbackChannelName = 'in.sreerajp.imgvidgal/playback';

  /// Smallest zoom level of the image viewer (fit to screen).
  static const double viewerMinScale = 1.0;

  /// Largest zoom level of the image viewer.
  static const double viewerMaxScale = 8.0;

  /// Zoom level a double tap jumps to.
  static const double viewerDoubleTapScale = 2.5;

  /// Downward drag distance, in logical pixels, that closes the viewer.
  static const double viewerDismissDistance = 140;

  /// Time the viewer waits before hiding its buttons during playback.
  static const int viewerChromeHideDelayMs = 3500;

  /// Playback speeds offered by the video player, slowest first.
  static const List<double> playbackSpeeds = <double>[
    0.25,
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    1.75,
    2.0,
  ];

  /// Speed a clip starts at.
  static const double defaultPlaybackSpeed = 1.0;

  /// One frame of a 30 fps clip, used by the frame step buttons.
  static const int frameStepMs = 33;

  /// Full-screen drag distance that moves the seek bar across the whole clip.
  static const double videoSeekDragReferencePx = 300;

  /// Longest seek a single horizontal drag may produce, in milliseconds.
  static const int videoSeekDragMaxMs = 120 * 1000;

  /// Vertical drag distance that moves brightness or volume from 0 to 1.
  static const double videoLevelDragReferencePx = 220;

  /// Largest original file the viewer decodes at full resolution (bytes).
  ///
  /// Anything bigger stays on its high-resolution thumbnail so a huge photo
  /// cannot exhaust memory.
  static const int viewerFullImageMaxBytes = 48 * 1024 * 1024;

  /// Largest file the EXIF reader will load into memory (bytes).
  static const int exifReadMaxBytes = 32 * 1024 * 1024;

  // Image Editor
  /// Largest original the editor will open (bytes).
  ///
  /// Editing decodes the whole photo, so a file bigger than this is refused
  /// with a message rather than risking an out-of-memory crash.
  static const int editorMaxSourceBytes = 40 * 1024 * 1024;

  /// Longest side, in pixels, of the live preview the sliders drive.
  ///
  /// Small enough to re-render while a finger is moving, large enough that
  /// the result still looks like the final image.
  static const int editorPreviewMaxSide = 1080;

  /// Smallest side, in pixels, that a preview is allowed to shrink to.
  static const int editorPreviewMinSide = 240;

  /// How long the editor waits after the last slider move before rendering.
  static const int editorPreviewDebounceMs = 120;

  /// Number of steps the undo history keeps.
  static const int editorUndoDepth = 40;

  /// Furthest the straighten slider tilts in either direction, in degrees.
  static const double editorStraightenMaxDegrees = 45;

  /// Furthest a perspective corner can be pulled in, as a fraction.
  static const double editorPerspectiveMaxInset = 0.35;

  /// Smallest crop box allowed, as a fraction of the image.
  static const double editorMinCropFraction = 0.05;

  /// JPEG quality used when the editor saves a copy, 0 to 100.
  static const int editorJpegQuality = 92;

  /// Suffix pattern for saved copies, so the original name is kept intact.
  static const String editorOutputSuffix = '_edit';

  /// Largest version number the save service will try before giving up.
  static const int editorMaxVersionAttempts = 999;

  /// Largest Gaussian blur radius a redaction may use, in pixels.
  static const int editorMaxBlurRadius = 40;

  /// Largest pixelation block a redaction may use, in pixels.
  static const int editorMaxPixelateBlock = 60;

  // Phase 7 — Conversion, Compression, PDF Export & Video Tools
  /// Method channel name used for the native WEBP encoder.
  static const String imageToolsChannelName =
      'in.sreerajp.imgvidgal/imagetools';

  /// Method channel name used for video frames, clip info, and trimming.
  static const String videoToolsChannelName =
      'in.sreerajp.imgvidgal/videotools';

  /// Largest original the converter will open (bytes).
  ///
  /// Converting decodes the whole photo, so a bigger file is refused with a
  /// message rather than risking an out-of-memory crash.
  static const int convertMaxSourceBytes = 64 * 1024 * 1024;

  /// Default quality used when converting to a lossy format, 0 to 100.
  static const int convertDefaultQuality = 85;

  static const int convertMinQuality = 10;
  static const int convertMaxQuality = 100;

  /// Smallest longest-side a resize may target, in pixels.
  static const int convertMinLongestSide = 32;

  /// Largest longest-side a resize may target, in pixels.
  static const int convertMaxLongestSide = 12000;

  /// Smallest and largest percent a percent resize may use.
  static const int convertMinPercent = 5;
  static const int convertMaxPercent = 400;

  /// How long the converter waits after the last slider move before it
  /// re-encodes for the size preview.
  static const int convertEstimateDebounceMs = 350;

  /// Longest side of the picture shown behind the converter controls.
  static const int convertPreviewMaxSide = 720;

  /// Name suffix used for a converted copy.
  static const String convertOutputSuffix = '_conv';

  /// Name suffix used for a grabbed still frame.
  static const String frameOutputSuffix = '_frame';

  /// Name suffix used for an exported GIF.
  static const String gifOutputSuffix = '_gif';

  /// Name suffix used for a trimmed clip.
  static const String trimOutputSuffix = '_trim';

  /// Name suffix used for an exported PDF document.
  static const String pdfOutputSuffix = '_album';

  /// Largest version number a save will try before giving up.
  static const int convertMaxVersionAttempts = 999;

  // PDF export
  /// A4 page size in PDF points (1/72 inch).
  static const double pdfA4WidthPoints = 595.28;
  static const double pdfA4HeightPoints = 841.89;

  /// US Letter page size in PDF points.
  static const double pdfLetterWidthPoints = 612;
  static const double pdfLetterHeightPoints = 792;

  /// Page margin choices offered, in PDF points.
  static const double pdfNoMarginPoints = 0;
  static const double pdfSmallMarginPoints = 18;
  static const double pdfMediumMarginPoints = 36;
  static const double pdfLargeMarginPoints = 72;

  /// Default margin used by the PDF export screen.
  static const double pdfDefaultMarginPoints = pdfSmallMarginPoints;

  /// Longest side each photo is shrunk to before it goes into the PDF.
  ///
  /// Keeps a twenty-photo document to a sensible file size while still
  /// looking sharp on screen and in print.
  static const int pdfImageMaxSide = 2000;

  /// JPEG quality used for the photos embedded in a PDF.
  static const int pdfImageQuality = 82;

  /// Largest number of photos one exported PDF may hold.
  static const int pdfMaxPages = 200;

  // Video tools
  /// Frame rates offered by the GIF exporter, slowest first.
  static const List<int> gifFrameRates = <int>[5, 8, 10, 12, 15, 20];

  /// Frame rate a GIF export starts at.
  static const int gifDefaultFrameRate = 10;

  /// Longest-side choices offered by the GIF exporter, in pixels.
  static const List<int> gifSizeChoices = <int>[240, 320, 480, 640];

  /// Longest side a GIF export starts at.
  static const int gifDefaultMaxSide = 320;

  /// Largest number of frames one GIF may hold.
  ///
  /// Each frame is pulled from the clip and kept in memory, so the cap is
  /// what stops a long selection from exhausting the device.
  static const int gifMaxFrames = 150;

  /// Longest slice of a clip a GIF export may cover, in milliseconds.
  static const int gifMaxDurationMs = 30 * 1000;

  /// Longest side of a frame pulled for the frame-grab preview.
  static const int framePreviewMaxSide = 1080;

  /// Shortest trim a user may keep, in milliseconds.
  static const int trimMinDurationMs = 500;

  // Phase 8 — Search, Multi-Tag Filtering & Duplicate Detection
  /// Method channel name used for content hashing and grayscale decoding.
  static const String hashToolsChannelName = 'in.sreerajp.imgvidgal/hashtools';

  /// How long the search screen waits after the last keystroke before it
  /// runs the query.
  static const int searchDebounceMs = 300;

  /// Largest number of results one search page returns.
  static const int searchPageSize = 200;

  /// Shortest text that starts a search, so a single letter does not scan
  /// the whole library on every keystroke.
  static const int searchMinQueryLength = 2;

  /// Largest number of recent searches kept.
  static const int searchHistoryMaxEntries = 12;

  /// File the recent searches are kept in, inside the app support directory.
  static const String searchHistoryFileName = 'search_history.json';

  /// Longest a tag name may be, in characters.
  static const int tagNameMaxLength = 40;

  /// Colour a tag falls back to when the palette cannot be consulted.
  static const int tagDefaultColorValue = 0xFF2196F3;

  // Duplicate detection
  /// Side of the square grayscale grid the perceptual hashes are built from.
  ///
  /// 32 is the standard pHash input: the DCT runs on 32x32 and only the
  /// top-left 8x8 block is kept.
  static const int perceptualHashGridSize = 32;

  /// Side of the DCT block kept from the 32x32 transform.
  static const int perceptualHashBlockSize = 8;

  /// Largest pHash Hamming distance still counted as the same picture.
  ///
  /// Out of 64 bits. Ten is the usual "visually the same" line; higher finds
  /// more bursts but starts pairing unrelated photos.
  static const int duplicatePHashThreshold = 10;

  /// Largest dHash Hamming distance allowed alongside the pHash match.
  ///
  /// The looser second opinion. Both hashes must agree before two photos are
  /// called similar, which removes most of the false pairs either hash makes
  /// on its own.
  static const int duplicateDHashThreshold = 16;

  /// Number of bit bands the pHash is split into for bucketing.
  ///
  /// Only photos sharing at least one 16-bit band are compared in full, which
  /// keeps the scan from being quadratic in the library size.
  static const int duplicateHashBandCount = 4;

  /// Number of media rows the duplicate scan hashes per page.
  static const int duplicateScanPageSize = 100;

  /// Largest file the duplicate scan will hash.
  ///
  /// Bigger files are still grouped by any hash already stored, they are just
  /// not read again.
  static const int duplicateMaxHashableBytes = 512 * 1024 * 1024;

  /// Block size the native digest reads with, in bytes.
  static const int duplicateHashBlockBytes = 64 * 1024;

  // Phase 10 — Secure Private Vault
  /// Method channel name used for the vault key, cipher, shredder, and
  /// the secure window flag.
  static const String vaultChannelName = 'in.sreerajp.imgvidgal/vault';

  /// Alias the AES-256 master key is stored under inside the Android Keystore.
  ///
  /// The key itself never crosses the channel; only this name does.
  static const String vaultKeystoreAlias = 'imgvidgal_vault_master_key';

  /// Length of the AES-GCM initialisation vector, in bytes.
  ///
  /// Ninety-six bits is the size GCM is defined for, and the only size that
  /// lets the counter be built without an extra hashing step.
  static const int vaultIvLengthBytes = 12;

  /// Length of the AES-GCM authentication tag, in bits.
  static const int vaultAuthTagLengthBits = 128;

  /// Number of PBKDF2 rounds used to turn a PIN into key bytes.
  ///
  /// High enough that guessing a four digit PIN off-device is slow, low
  /// enough that an unlock on an old phone still feels immediate.
  static const int vaultPinIterations = 120000;

  /// Length of the random salt stored beside the PIN hash, in bytes.
  static const int vaultPinSaltBytes = 16;

  /// Length of the derived PIN hash, in bytes.
  static const int vaultPinHashBytes = 32;

  /// Shortest and longest PIN the vault accepts, in digits.
  static const int vaultPinMinLength = 4;
  static const int vaultPinMaxLength = 8;

  /// Wrong PINs allowed before the pad refuses to take another one.
  static const int vaultMaxFailedAttempts = 5;

  /// How long the pad stays shut after too many wrong PINs, in seconds.
  static const int vaultLockoutSeconds = 30;

  /// Inactivity timeouts the settings screen offers, in seconds.
  static const List<int> vaultAutoLockChoicesSeconds = <int>[30, 60, 300];

  /// Overwrite passes a shred makes before the file is unlinked.
  static const int vaultDefaultShredPasses = 2;
  static const int vaultMinShredPasses = 1;
  static const int vaultMaxShredPasses = 5;

  /// Block size the shredder writes with, in bytes.
  static const int vaultShredBlockBytes = 64 * 1024;

  /// Longest side of the encrypted preview kept beside each vault payload.
  static const int vaultThumbnailSize = 320;

  /// Quality used when re-encoding a vault preview.
  static const int vaultThumbnailQuality = 80;

  /// Largest original the vault will take in, in bytes.
  static const int vaultMaxImportBytes = 2 * 1024 * 1024 * 1024;

  /// Largest payload that may be decrypted straight into memory, in bytes.
  ///
  /// Photos and previews go through memory so nothing decrypted ever reaches
  /// disk. Anything bigger than this is a video, and has to be decrypted to a
  /// working file the player can open.
  static const int vaultMaxDecryptToMemoryBytes = 64 * 1024 * 1024;

  /// Number of random bytes behind an on-disk vault file name.
  static const int vaultPayloadNameBytes = 16;

  /// Extension of an encrypted media payload.
  static const String vaultPayloadExtension = '.enc';

  /// Extension of an encrypted preview.
  static const String vaultThumbnailExtension = '.thm';

  /// Extension of a decrypted working file the video player reads.
  ///
  /// Files carrying it are shredded when the player closes, when the vault
  /// locks, and swept on every vault open in case a crash left one behind.
  static const String vaultWorkingExtension = '.dec';

  /// Marker file that keeps other apps' media scanners out of the vault.
  static const String vaultNoMediaFileName = '.nomedia';

  /// Name suffix used for a file restored out of the vault.
  static const String vaultExportSuffix = '_vault';

  // Phase 11 — Batch Operations, Backup/Restore & Local P2P Wi-Fi Sync

  /// Largest number of items one selection may hold.
  ///
  /// A batch runs one file at a time and keeps its ids in memory, so the cap
  /// is what stops "select all" on a fifty-thousand photo library from
  /// becoming an operation nobody can cancel out of.
  static const int batchMaxSelectionSize = 500;

  /// How often a running batch reports progress, in items.
  ///
  /// Every item, so a slow conversion still moves the bar.
  static const int batchProgressInterval = 1;

  /// Method channel name used for backup key derivation and archive ciphers.
  static const String backupChannelName = 'in.sreerajp.imgvidgal/backup';

  /// Method channel name used for the Storage Access Framework file picker.
  static const String documentsChannelName = 'in.sreerajp.imgvidgal/documents';

  /// File extension of an encrypted backup archive, without the dot.
  static const String backupFileExtension = 'gallerybak';

  /// MIME type an archive is created with.
  ///
  /// Deliberately generic: Android has no type for this format, and claiming
  /// one it knows would let another app offer to open a file it cannot read.
  static const String backupMimeType = 'application/octet-stream';

  /// Four bytes every archive starts with, so a wrong file is refused fast.
  static const String backupMagic = 'GBAK';

  /// Container version. Bumped only when the header layout changes.
  static const int backupFormatVersion = 1;

  /// Number of PBKDF2 rounds used to turn the backup password into a key.
  ///
  /// Higher than the vault's PIN count because an archive leaves the device
  /// and can be attacked at leisure, and because it is derived once per
  /// backup rather than on every unlock.
  static const int backupKdfIterations = 210000;

  /// Length of the random salt written into each archive header, in bytes.
  static const int backupSaltBytes = 16;

  /// Shortest backup password accepted, in characters.
  static const int backupPasswordMinLength = 8;

  /// Name the backup file is offered under, before the date is appended.
  static const String backupFileNamePrefix = 'gallery_backup';

  /// Staging file the archive is built in, inside the app support directory.
  static const String backupStagingFileName = 'backup_staging.gz';

  /// Staging file a restore decrypts into, inside the app support directory.
  static const String restoreStagingFileName = 'restore_staging.gz';

  /// Largest archive the restore screen will open, in bytes.
  ///
  /// A metadata-only backup of a very large library is a few tens of
  /// megabytes; anything past this is not one of ours.
  static const int backupMaxArchiveBytes = 256 * 1024 * 1024;

  // Local peer-to-peer transfer
  /// Version of the wire protocol. A peer announcing anything else is refused.
  static const int syncProtocolVersion = 1;

  /// Port range the listener picks from.
  ///
  /// Zero means "let the operating system choose a free ephemeral port",
  /// which is what the pairing code then carries to the other device.
  static const int syncEphemeralPort = 0;

  /// Length of the random secret the pairing code carries, in bytes.
  ///
  /// Nine bytes is 72 bits of randomness, written as 24 characters a person
  /// can read aloud. It is short because it has to be typeable, and short is
  /// safe here: it is good for one transfer, it is guessable only during the
  /// three-minute pairing window, and a wrong guess ends the session rather
  /// than allowing another try on the same secret.
  static const int syncPairingSecretBytes = 9;

  /// Length of the AES key the transfer actually uses, in bytes.
  ///
  /// Derived from the pairing secret rather than carried, so the QR code and
  /// the typed code produce exactly the same key and neither path is weaker
  /// than the other at the point where it matters.
  static const int syncSessionKeyBytes = 32;

  /// Length of the per-frame initialisation vector, in bytes.
  static const int syncIvLengthBytes = 12;

  /// Longest a listener waits for a peer before it gives up, in seconds.
  static const int syncPairingTimeoutSeconds = 180;

  /// Longest a connected socket may sit idle before it is closed, in seconds.
  static const int syncIdleTimeoutSeconds = 60;

  /// How long a connect attempt waits before failing, in seconds.
  static const int syncConnectTimeoutSeconds = 10;

  /// Bytes of file payload carried by one frame.
  ///
  /// Large enough that a video does not become a million frames, small enough
  /// that progress moves visibly and a cancel is acted on quickly.
  static const int syncChunkBytes = 256 * 1024;

  /// Largest frame the reader will accept, in bytes.
  ///
  /// A peer claiming more than this is refused rather than trusted with an
  /// allocation, which is the whole reason the cap exists.
  static const int syncMaxFrameBytes = 2 * 1024 * 1024;

  /// Largest single file one transfer will accept, in bytes.
  static const int syncMaxFileBytes = 4 * 1024 * 1024 * 1024;

  /// Largest number of files one transfer may offer.
  static const int syncMaxManifestEntries = 2000;

  /// Number of characters in one group of the typed pairing code.
  static const int syncManualCodeGroupLength = 4;

  /// Number of groups in the typed pairing code.
  static const int syncManualCodeGroupCount = 6;

  /// Folder incoming files are written into, under the shared Pictures tree.
  static const String syncReceiveDirectoryName = 'Gallery Transfers';

  /// Name suffix used when an incoming file clashes with one already there.
  static const String syncReceiveSuffix = '_recv';

  // In-Image Scanner, OCR, Notes & PDF Tools (Phase 12)
  /// Method channel used to hand a scanned code to another app.
  ///
  /// The app builds every intent itself rather than taking a launcher
  /// package, so the list of schemes it will ever open lives in one place.
  static const String intentChannelName = 'in.sreerajp.imgvidgal/intents';

  /// URI schemes a scanned code may be opened with.
  ///
  /// Anything else is shown as plain text and never launched. A code is
  /// untrusted input: it came off a poster, a screenshot, or a stranger.
  static const Set<String> scanLaunchableSchemes = <String>{
    'http',
    'https',
    'tel',
    'mailto',
    'sms',
    'geo',
  };

  /// Longest raw code payload the scanner will keep, in characters.
  static const int scanMaxPayloadLength = 4096;

  /// Longest a single in-image scan may run before it is given up on.
  static const int scanTimeoutSeconds = 20;

  /// Folder the traineddata language files are shipped in.
  static const String ocrTessDataAssetDir = 'assets/tessdata';

  /// Folder the language files are copied to on first use.
  ///
  /// Tesseract wants a real directory called `tessdata`, so the assets are
  /// unpacked once into app-private storage and read from there after that.
  static const String ocrWorkingDirectoryName = 'tessdata';

  /// Language files shipped with the app.
  static const List<String> ocrBundledTraineddata = <String>[
    'eng.traineddata',
    'mal.traineddata',
  ];

  /// Longest one OCR pass may run before it is given up on.
  ///
  /// Tesseract on a large photo is slow, and a stuck pass must not leave the
  /// screen spinning forever.
  static const int ocrTimeoutSeconds = 120;

  /// Largest image OCR will accept, in bytes.
  static const int ocrMaxImageBytes = 32 * 1024 * 1024;

  /// Longest note the editor will store, in characters.
  static const int notesMaxLength = 20000;

  /// Largest PDF the image extractor will open, in bytes.
  static const int pdfExtractMaxFileBytes = 256 * 1024 * 1024;

  /// Largest number of images one PDF may yield.
  static const int pdfExtractMaxImages = 500;

  /// Largest single embedded image, in pixels.
  ///
  /// A hostile file can claim any width and height it likes, so the claim is
  /// checked before a single byte is allocated for it.
  static const int pdfExtractMaxPixels = 80 * 1000 * 1000;

  /// Largest decoded size of one embedded image stream, in bytes.
  static const int pdfExtractMaxImageBytes = 128 * 1024 * 1024;

  /// Name suffix given to a picture pulled out of a PDF.
  static const String pdfExtractSuffix = '_pdfimg';

  /// Folder extracted pictures are written into, under shared Pictures.
  static const String pdfExtractDirectoryName = 'Gallery Extracted';
}
