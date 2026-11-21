import 'package:in_sreerajp_imgvidgal/models/media_item.dart';

/// Whether [item] can be handed to Android's wallpaper screen.
///
/// Only an ordinary photo or GIF qualifies. RAW and SVG files are left out:
/// Android's wallpaper screen cannot decode them. Videos have no still to set,
/// and an item in the trash may not be readable by another app.
///
/// The address must be a MediaStore one (`content://media/...`). That is the
/// only kind the Kotlin side accepts as well, so the app can never hand out
/// one of its own private files (vault, cache) this way.
bool canSetAsWallpaper(MediaItem item) {
  if (item.mediaType != MediaType.image && item.mediaType != MediaType.gif) {
    return false;
  }
  if (item.isTrash || item.isVaulted) return false;

  final uri = Uri.tryParse(item.uri ?? '');
  return uri != null && uri.scheme == 'content' && uri.host == 'media';
}
