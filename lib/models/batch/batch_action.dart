import 'package:in_sreerajp_imgvidgal/models/media_item.dart';

/// One thing a batch can do to a selection.
///
/// Each action names the media types it can work on. That list is the whole
/// reason the enum carries data rather than being a bare set of names: the
/// action bar has to grey out "Watermark" the moment a video is picked, and
/// deciding that in one place keeps the bar and the runner from disagreeing.
enum BatchAction {
  /// Convert or compress to another image format.
  convert(accepts: _stillImages, needsAllAccepted: true),

  /// Burn a watermark into a copy of each image.
  watermark(accepts: _stillImages, needsAllAccepted: true),

  /// Build one PDF document out of the selected images.
  ///
  /// The only action that does not accept every type: a mixed selection is
  /// allowed, and the videos in it are skipped rather than refused, because
  /// "make a PDF of these photos" is a reasonable thing to mean.
  exportPdf(accepts: _stillImages, needsAllAccepted: false),

  /// Add one or more tags to everything selected.
  addTags(accepts: _everything, needsAllAccepted: true),

  /// Take one or more tags off everything selected.
  removeTags(accepts: _everything, needsAllAccepted: true),

  /// Put everything selected into a virtual album.
  addToAlbum(accepts: _everything, needsAllAccepted: true),

  /// Mark everything selected as a favourite.
  favourite(accepts: _everything, needsAllAccepted: true),

  /// Take the favourite mark off everything selected.
  unfavourite(accepts: _everything, needsAllAccepted: true),

  /// Move everything selected into the encrypted private vault.
  moveToVault(accepts: _everything, needsAllAccepted: true),

  /// Offer everything selected to a paired device.
  transfer(accepts: _everything, needsAllAccepted: true),

  /// Move everything selected to the trash.
  ///
  /// Nothing is erased: the rows are flagged and the files stay on disk, so
  /// the action is undoable and hard rule 4 holds.
  moveToTrash(accepts: _everything, needsAllAccepted: true);

  /// Media types this action can work on.
  final Set<MediaType> accepts;

  /// Whether every selected item must be an accepted type.
  ///
  /// When false, the unaccepted items are skipped and the rest still run.
  final bool needsAllAccepted;

  const BatchAction({required this.accepts, required this.needsAllAccepted});

  /// Whether this action can do anything at all with [item].
  bool acceptsItem(MediaItem item) => accepts.contains(item.mediaType);

  /// Whether the action changes files on disk.
  ///
  /// The confirm step is stricter for these: they write new files, or in the
  /// vault's case move the original, and the user should be told which.
  bool get touchesFiles =>
      this == convert ||
      this == watermark ||
      this == exportPdf ||
      this == moveToVault;
}

/// Everything the gallery indexes.
const Set<MediaType> _everything = <MediaType>{
  MediaType.image,
  MediaType.video,
  MediaType.gif,
  MediaType.rawImage,
  MediaType.svg,
};

/// Pictures a decoder can open and re-encode.
///
/// SVG is left out because the render pipeline works on pixels, and a vector
/// file converted to pixels is a different thing from what the user selected.
const Set<MediaType> _stillImages = <MediaType>{
  MediaType.image,
  MediaType.gif,
  MediaType.rawImage,
};
