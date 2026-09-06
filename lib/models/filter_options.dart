import 'package:flutter/foundation.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';

/// Tag matching logic when multiple tags are selected.
enum TagFilterMode { andMode, orMode }

/// Fields by which gallery items can be sorted.
enum MediaSortField {
  dateTaken,
  dateAdded,
  dateModified,
  displayName,
  size,
  duration,
}

/// Sort order direction.
enum SortDirection { ascending, descending }

/// Immutable filter criteria model for querying gallery media items.
@immutable
class FilterOptions {
  /// Allowed media categories (empty means all types).
  final Set<MediaType> mediaTypes;

  /// IDs or names of tags to filter by.
  final Set<String> tagIds;

  /// Tag matching logic (AND vs OR).
  final TagFilterMode tagFilterMode;

  /// Filter for favorited items only if true.
  final bool? isFavoriteOnly;

  /// Start of capture date range.
  final DateTime? startDate;

  /// End of capture date range.
  final DateTime? endDate;

  /// Filter by specific folder directory paths.
  final Set<String> folderPaths;

  /// Selected sorting field.
  final MediaSortField sortBy;

  /// Sorting direction.
  final SortDirection sortDirection;

  /// Search keyword or FTS query string.
  final String? searchQuery;

  /// Filter items that contain GPS coordinates.
  final bool? hasGpsOnly;

  /// Filter items located in the trash bin.
  final bool isTrash;

  /// Smallest allowed file size in bytes, inclusive.
  final int? minSizeBytes;

  /// Largest allowed file size in bytes, inclusive.
  final int? maxSizeBytes;

  /// Filter items that carry at least one tag.
  final bool? hasTagsOnly;

  const FilterOptions({
    this.mediaTypes = const <MediaType>{},
    this.tagIds = const <String>{},
    this.tagFilterMode = TagFilterMode.andMode,
    this.isFavoriteOnly,
    this.startDate,
    this.endDate,
    this.folderPaths = const <String>{},
    this.sortBy = MediaSortField.dateTaken,
    this.sortDirection = SortDirection.descending,
    this.searchQuery,
    this.hasGpsOnly,
    this.isTrash = false,
    this.minSizeBytes,
    this.maxSizeBytes,
    this.hasTagsOnly,
  });

  /// Returns true if any active filters are applied beyond default sort.
  bool get hasActiveFilters =>
      mediaTypes.isNotEmpty ||
      tagIds.isNotEmpty ||
      isFavoriteOnly == true ||
      startDate != null ||
      endDate != null ||
      folderPaths.isNotEmpty ||
      (searchQuery != null && searchQuery!.trim().isNotEmpty) ||
      hasGpsOnly == true ||
      isTrash ||
      minSizeBytes != null ||
      maxSizeBytes != null ||
      hasTagsOnly == true;

  /// Creates a copy of [FilterOptions] with updated properties.
  ///
  /// The `clear...` flags exist because passing null to a `copyWith` means
  /// "leave this alone", so there would otherwise be no way to switch an
  /// optional filter back off. The filter sheet needs exactly that: turning
  /// "favourites only" or a date range off again has to be possible.
  FilterOptions copyWith({
    Set<MediaType>? mediaTypes,
    Set<String>? tagIds,
    TagFilterMode? tagFilterMode,
    bool? isFavoriteOnly,
    DateTime? startDate,
    DateTime? endDate,
    Set<String>? folderPaths,
    MediaSortField? sortBy,
    SortDirection? sortDirection,
    String? searchQuery,
    bool? hasGpsOnly,
    bool? isTrash,
    int? minSizeBytes,
    int? maxSizeBytes,
    bool? hasTagsOnly,
    bool clearFavorite = false,
    bool clearDates = false,
    bool clearGps = false,
    bool clearSearchQuery = false,
    bool clearSizeRange = false,
    bool clearHasTags = false,
  }) {
    return FilterOptions(
      mediaTypes: mediaTypes ?? this.mediaTypes,
      tagIds: tagIds ?? this.tagIds,
      tagFilterMode: tagFilterMode ?? this.tagFilterMode,
      isFavoriteOnly: clearFavorite
          ? null
          : (isFavoriteOnly ?? this.isFavoriteOnly),
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      folderPaths: folderPaths ?? this.folderPaths,
      sortBy: sortBy ?? this.sortBy,
      sortDirection: sortDirection ?? this.sortDirection,
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      hasGpsOnly: clearGps ? null : (hasGpsOnly ?? this.hasGpsOnly),
      isTrash: isTrash ?? this.isTrash,
      minSizeBytes: clearSizeRange ? null : (minSizeBytes ?? this.minSizeBytes),
      maxSizeBytes: clearSizeRange ? null : (maxSizeBytes ?? this.maxSizeBytes),
      hasTagsOnly: clearHasTags ? null : (hasTagsOnly ?? this.hasTagsOnly),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilterOptions &&
          runtimeType == other.runtimeType &&
          setEquals(mediaTypes, other.mediaTypes) &&
          setEquals(tagIds, other.tagIds) &&
          tagFilterMode == other.tagFilterMode &&
          isFavoriteOnly == other.isFavoriteOnly &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          setEquals(folderPaths, other.folderPaths) &&
          sortBy == other.sortBy &&
          sortDirection == other.sortDirection &&
          searchQuery == other.searchQuery &&
          hasGpsOnly == other.hasGpsOnly &&
          isTrash == other.isTrash &&
          minSizeBytes == other.minSizeBytes &&
          maxSizeBytes == other.maxSizeBytes &&
          hasTagsOnly == other.hasTagsOnly;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(mediaTypes),
    Object.hashAll(tagIds),
    tagFilterMode,
    isFavoriteOnly,
    startDate,
    endDate,
    Object.hashAll(folderPaths),
    sortBy,
    sortDirection,
    searchQuery,
    hasGpsOnly,
    isTrash,
    minSizeBytes,
    maxSizeBytes,
    hasTagsOnly,
  );
}
