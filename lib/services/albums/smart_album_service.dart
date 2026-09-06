import 'package:in_sreerajp_imgvidgal/models/album.dart';
import 'package:in_sreerajp_imgvidgal/models/filter_options.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/smart_album.dart';

/// Turns the six built-in smart albums into queries.
///
/// Everything here is pure: it takes a rule and gives back a filter, or takes
/// an item and says whether the rule covers it. Nothing is stored, so a smart
/// album cannot fall out of step with the library the way a cached list would.
class SmartAlbumService {
  const SmartAlbumService._();

  /// How much wider than tall (or taller than wide) a photo must be to count
  /// as a panorama.
  static const double panoramaMinAspectRatio = 2.5;

  /// How many pixels the longest side must have as well.
  ///
  /// The ratio alone would catch a thin crop of a small photo; the pixel floor
  /// alone would catch any large photo. A panorama needs both.
  static const int panoramaMinLongestSide = 2000;

  /// How far back "recently added" reaches.
  static const Duration recentWindow = Duration(days: 30);

  /// Route key for each smart album.
  ///
  /// Deliberately separate from the enum name so the enum may be renamed later
  /// without breaking a route a user has already navigated to.
  static const Map<AlbumType, String> _keys = <AlbumType, String>{
    AlbumType.smartFavorites: 'favorites',
    AlbumType.smartVideos: 'videos',
    AlbumType.smartGifs: 'gifs',
    AlbumType.smartRaw: 'raw',
    AlbumType.smartPanoramas: 'panoramas',
    AlbumType.smartRecentlyAdded: 'recent',
    AlbumType.smartTrash: 'trash',
  };

  /// The seven smart albums, in the order the albums screen shows them.
  ///
  /// Trash sits at the end so it does not distract from the creative albums.
  static List<SmartAlbum> all() {
    return <SmartAlbum>[
      forType(AlbumType.smartFavorites),
      forType(AlbumType.smartVideos),
      forType(AlbumType.smartGifs),
      forType(AlbumType.smartRaw),
      forType(AlbumType.smartPanoramas),
      forType(AlbumType.smartRecentlyAdded),
      forType(AlbumType.smartTrash),
    ];
  }

  /// The route key for one smart album type, or null when the type is not one.
  static String? keyFor(AlbumType type) => _keys[type];

  /// The smart album a route key names, or null when the key is unknown.
  ///
  /// Returning null rather than throwing keeps a stale or hand-typed link from
  /// crashing the app; the screen shows a "not found" state instead.
  static SmartAlbum? fromKey(String key) {
    for (final entry in _keys.entries) {
      if (entry.value == key) return forType(entry.key);
    }
    return null;
  }

  /// Builds one smart album's rule.
  static SmartAlbum forType(AlbumType type) {
    return switch (type) {
      AlbumType.smartFavorites => const SmartAlbum(
        albumType: AlbumType.smartFavorites,
        key: 'favorites',
        filter: FilterOptions(isFavoriteOnly: true),
      ),
      AlbumType.smartVideos => const SmartAlbum(
        albumType: AlbumType.smartVideos,
        key: 'videos',
        filter: FilterOptions(mediaTypes: <MediaType>{MediaType.video}),
      ),
      AlbumType.smartGifs => const SmartAlbum(
        albumType: AlbumType.smartGifs,
        key: 'gifs',
        filter: FilterOptions(mediaTypes: <MediaType>{MediaType.gif}),
      ),
      AlbumType.smartRaw => const SmartAlbum(
        albumType: AlbumType.smartRaw,
        key: 'raw',
        filter: FilterOptions(mediaTypes: <MediaType>{MediaType.rawImage}),
      ),
      // Shape is not a column, so the database returns every still image and
      // the ratio test runs afterwards.
      AlbumType.smartPanoramas => const SmartAlbum(
        albumType: AlbumType.smartPanoramas,
        key: 'panoramas',
        filter: FilterOptions(
          mediaTypes: <MediaType>{MediaType.image, MediaType.rawImage},
        ),
        needsPostFilter: true,
      ),
      // The window moves with the clock, so the cut-off is applied against
      // "now" at read time rather than baked into a const filter.
      AlbumType.smartRecentlyAdded => const SmartAlbum(
        albumType: AlbumType.smartRecentlyAdded,
        key: 'recent',
        filter: FilterOptions(sortBy: MediaSortField.dateAdded),
        needsPostFilter: true,
      ),
      AlbumType.smartTrash => const SmartAlbum(
        albumType: AlbumType.smartTrash,
        key: 'trash',
        filter: FilterOptions(isTrash: true),
      ),
      _ => throw ArgumentError.value(type, 'type', 'Not a smart album type'),
    };
  }

  /// Whether an item belongs in a smart album, for the rules that need a
  /// second pass after the database query.
  ///
  /// Rules the database has already applied in full return true here, so a
  /// caller can run this over every result without special-casing.
  static bool matches(SmartAlbum album, MediaItem item, {DateTime? now}) {
    return switch (album.albumType) {
      AlbumType.smartPanoramas => isPanorama(item),
      AlbumType.smartRecentlyAdded => isRecentlyAdded(item, now: now),
      _ => true,
    };
  }

  /// Whether a photo is wide (or tall) enough to be a panorama.
  ///
  /// An item with no recorded dimensions is never a panorama: guessing from a
  /// missing value would put ordinary photos in the album.
  static bool isPanorama(MediaItem item) {
    final width = item.width;
    final height = item.height;
    if (width == null || height == null) return false;
    if (width <= 0 || height <= 0) return false;

    final longest = width > height ? width : height;
    final shortest = width > height ? height : width;
    if (longest < panoramaMinLongestSide) return false;

    return longest / shortest >= panoramaMinAspectRatio;
  }

  /// Whether an item was added inside the recent window.
  static bool isRecentlyAdded(MediaItem item, {DateTime? now}) {
    final cutoff = (now ?? DateTime.now()).subtract(recentWindow);
    return !item.dateAdded.isBefore(cutoff);
  }
}
