import 'package:in_sreerajp_imgvidgal/models/media_item.dart';

/// Decides which copy of a picture is worth keeping.
///
/// Pure and deliberately simple, because it is only ever a suggestion. The
/// cleaner pre-ticks whatever this picks and the user is free to change it,
/// so the aim is to be right most of the time and easy to explain, not to be
/// clever.
class BestPhotoService {
  const BestPhotoService();

  /// Orders [items] best first.
  ///
  /// The comparisons run in this order, each only used when the one before it
  /// ties:
  ///
  /// 1. **More pixels.** A bigger picture holds more of the original.
  /// 2. **Bigger file.** At the same size, the larger file was saved at the
  ///    higher quality.
  /// 3. **Has a real capture date.** A copy that kept its capture time still
  ///    has its metadata; one that lost it has probably been through a share
  ///    or a messaging app.
  /// 4. **Has EXIF.** Same reasoning, one step weaker.
  /// 5. **Marked favourite.** The user already said this one matters.
  /// 6. **Older file.** The last tie-break: the first copy made is most
  ///    likely the original, and the rest are its descendants.
  ///
  /// The order is stable, so the same group always ranks the same way.
  List<MediaItem> rank(List<MediaItem> items) {
    final ranked = <MediaItem>[...items];
    ranked.sort(compare);
    return ranked;
  }

  /// Picks the keeper, or null when [items] is empty.
  MediaItem? pickBest(List<MediaItem> items) {
    if (items.isEmpty) return null;
    return rank(items).first;
  }

  /// Compares two candidates. Negative means [a] is the better copy.
  int compare(MediaItem a, MediaItem b) {
    final pixels = _pixels(b).compareTo(_pixels(a));
    if (pixels != 0) return pixels;

    final size = b.size.compareTo(a.size);
    if (size != 0) return size;

    final captureDate = _flag(
      b.dateTaken != null,
    ).compareTo(_flag(a.dateTaken != null));
    if (captureDate != 0) return captureDate;

    final exif = _flag(b.exifData != null).compareTo(_flag(a.exifData != null));
    if (exif != 0) return exif;

    final favorite = _flag(b.isFavorite).compareTo(_flag(a.isFavorite));
    if (favorite != 0) return favorite;

    final age = _age(a).compareTo(_age(b));
    if (age != 0) return age;

    // Nothing separates them. Order by id so the answer never wobbles
    // between runs.
    return a.id.compareTo(b.id);
  }

  /// How many pixels the picture has, or 0 when the size is unknown.
  int _pixels(MediaItem item) {
    final width = item.width ?? 0;
    final height = item.height ?? 0;
    if (width <= 0 || height <= 0) return 0;
    return width * height;
  }

  /// The moment the file came into being, best guess first.
  DateTime _age(MediaItem item) => item.dateTaken ?? item.dateAdded;

  int _flag(bool value) => value ? 1 : 0;
}
