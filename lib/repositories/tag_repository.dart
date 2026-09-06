import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';
import 'package:in_sreerajp_imgvidgal/models/tag.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/tag_dao.dart';
import 'package:in_sreerajp_imgvidgal/services/tags/tag_color_palette.dart';
import 'package:in_sreerajp_imgvidgal/services/tags/tag_name_rules.dart';

/// Thrown when a tag name breaks one of the rules.
///
/// Carries the reason so the UI can show the right message rather than
/// guessing from the text.
class TagValidationException implements Exception {
  final TagNameError reason;
  final String message;

  const TagValidationException(this.reason, this.message);

  @override
  String toString() => 'TagValidationException: $message';
}

/// The only way the app changes tags.
///
/// Two things live here that would otherwise be scattered. First, the name
/// rules are applied before anything is written, so no path can slip a
/// duplicate or an empty tag past them. Second, every change rewrites the tag
/// words the full-text index holds for the affected photos. That second job is
/// easy to forget in a caller, and forgetting it leaves the search index
/// quietly disagreeing with the database, so it belongs in one place.
class TagRepository {
  final TagDao _tagDao;
  final MediaDao _mediaDao;

  TagRepository({TagDao? tagDao, MediaDao? mediaDao})
    : _tagDao = tagDao ?? TagDao(),
      _mediaDao = mediaDao ?? MediaDao();

  /// Every tag, by name.
  Future<List<Tag>> getAllTags() => _tagDao.getAllTags();

  /// The tags on one media item.
  Future<List<Tag>> getTagsForMedia(String mediaId) =>
      _tagDao.getTagsForMedia(mediaId);

  /// Makes a new tag and returns it.
  ///
  /// [colorValue] is optional; without one the tag takes the palette colour
  /// its name maps to, so tags look distinct without the user having to
  /// choose. Throws [TagValidationException] when the name is not allowed.
  Future<Tag> createTag(String name, {int? colorValue, DateTime? now}) async {
    final existing = await _tagDao.getAllTags();
    final check = TagNameRules.check(
      name,
      existingNames: existing.map((t) => t.name),
    );
    _throwIfInvalid(check);

    final created = Tag(
      id: _newId(check.normalized),
      name: check.normalized,
      colorValue: TagColorPalette.resolve(colorValue, check.normalized),
      dateCreated: now ?? DateTime.now(),
    );
    await _tagDao.insertTag(created);
    return created;
  }

  /// Finds a tag by name, or makes it when it is not there yet.
  ///
  /// What the "new tag" row in the tag sheet needs: the user types a name and
  /// gets a tag, whether or not one already existed.
  Future<Tag> findOrCreateTag(String name, {int? colorValue}) async {
    final normalized = TagNameRules.normalize(name);
    final existing = await _tagDao.getTagByName(normalized);
    if (existing != null) return existing;
    return createTag(normalized, colorValue: colorValue);
  }

  /// Renames a tag and refreshes the search index of every photo carrying it.
  ///
  /// Throws [TagValidationException] when the new name is empty, too long, or
  /// already taken by a different tag.
  Future<Tag> renameTag(String tagId, String name) async {
    final tag = await _requireTag(tagId);
    final existing = await _tagDao.getAllTags();
    final check = TagNameRules.check(
      name,
      existingNames: existing.map((t) => t.name),
      ignoreName: tag.name,
    );
    _throwIfInvalid(check);

    await _tagDao.renameTag(tagId, check.normalized);
    await _reindexMediaOfTag(tagId);
    return tag.copyWith(name: check.normalized);
  }

  /// Changes the colour of a tag.
  ///
  /// Colour is not in the search index, so nothing is reindexed.
  Future<Tag> setTagColor(String tagId, int colorValue) async {
    final tag = await _requireTag(tagId);
    final updated = tag.copyWith(
      colorValue: TagColorPalette.resolve(colorValue, tag.name),
    );
    await _tagDao.updateTag(updated);
    return updated;
  }

  /// Deletes a tag and takes it off every photo.
  ///
  /// The junction rows go with it through the foreign key cascade, but the
  /// search index does not know about cascades, so the affected photos are
  /// collected first and reindexed afterwards.
  Future<void> deleteTag(String tagId) async {
    final mediaIds = await _tagDao.getMediaIdsForTag(tagId);
    await _tagDao.deleteTag(tagId);
    for (final mediaId in mediaIds) {
      await _reindexMedia(mediaId);
    }
  }

  /// Puts a tag on a photo.
  Future<void> addTagToMedia(String mediaId, String tagId) async {
    await _tagDao.addTagToMedia(mediaId, tagId);
    await _reindexMedia(mediaId);
  }

  /// Takes a tag off a photo.
  Future<void> removeTagFromMedia(String mediaId, String tagId) async {
    await _tagDao.removeTagFromMedia(mediaId, tagId);
    await _reindexMedia(mediaId);
  }

  /// Replaces the whole tag set of one photo at once.
  Future<void> setTagsForMedia(String mediaId, Set<String> tagIds) async {
    await _tagDao.setTagsForMedia(mediaId, tagIds);
    await _reindexMedia(mediaId);
  }

  /// Rewrites the tag words the search index holds for one photo.
  Future<void> _reindexMedia(String mediaId) async {
    final tags = await _tagDao.getTagsForMedia(mediaId);
    await _mediaDao.syncFtsTags(mediaId, tags.map((t) => t.name).toList());
  }

  /// Rewrites the search index for every photo carrying one tag.
  Future<void> _reindexMediaOfTag(String tagId) async {
    for (final mediaId in await _tagDao.getMediaIdsForTag(tagId)) {
      await _reindexMedia(mediaId);
    }
  }

  Future<Tag> _requireTag(String tagId) async {
    final tag = await _tagDao.getTagById(tagId);
    if (tag == null) {
      throw StorageException('Tag $tagId no longer exists');
    }
    return tag;
  }

  void _throwIfInvalid(TagNameCheck check) {
    final error = check.error;
    if (error == null) return;
    throw TagValidationException(error, switch (error) {
      TagNameError.empty => 'A tag needs a name',
      TagNameError.tooLong =>
        'A tag name may be at most ${TagNameRules.maxLength} characters',
      TagNameError.duplicate => 'A tag called "${check.normalized}" exists',
    });
  }

  /// A unique id for a new tag.
  ///
  /// The tag table takes a text primary key, and the app has no UUID package,
  /// so the id is the timestamp plus the name's own hash. Both parts are
  /// needed: the timestamp keeps two tags made in the same session apart, and
  /// the name keeps two made in the same millisecond apart.
  String _newId(String normalizedName) {
    final stamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final suffix = normalizedName
        .toLowerCase()
        .hashCode
        .toUnsigned(32)
        .toRadixString(36);
    return 'tag_${stamp}_$suffix';
  }
}
