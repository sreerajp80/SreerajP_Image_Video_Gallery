// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get titleApp => 'SreerajP Gallery';

  @override
  String get labelDevBanner => 'DEV BUILD';

  @override
  String get titleSettings => 'Settings';

  @override
  String get titleAbout => 'About';

  @override
  String get labelTheme => 'Theme';

  @override
  String get actionThemeSystem => 'System Default';

  @override
  String get actionThemeLight => 'Light';

  @override
  String get actionThemeDark => 'Dark';

  @override
  String get actionThemeAmoled => 'AMOLED True Black';

  @override
  String get titleVersion => 'Version';

  @override
  String get labelPermissionRequired => 'Media access needed';

  @override
  String get bodyPermissionRequired =>
      'Allow access to your photos and videos so the gallery can show them. Nothing ever leaves your device.';

  @override
  String get labelGrantPermission => 'Allow access';

  @override
  String get labelOpenSettings => 'Open settings';

  @override
  String get bodyPermissionPartial =>
      'Only selected media is visible. Allow all media to see everything.';

  @override
  String get labelScanMedia => 'Scan device media';

  @override
  String get bodyScanningMedia => 'Scanning media...';

  @override
  String bodyScanProgress(int scanned, int total) {
    return '$scanned of $total scanned';
  }

  @override
  String bodyScanComplete(int count) {
    return 'Scan complete: $count items indexed';
  }

  @override
  String get errorScanFailed => 'Media scan failed';

  @override
  String bodyIndexedItems(int count) {
    return 'Indexed items: $count';
  }

  @override
  String get bodyNoMediaFound => 'No photos or videos found';

  @override
  String get labelMediaUnavailable => 'Preview unavailable';

  @override
  String get labelTimelineToday => 'Today';

  @override
  String get labelTimelineYesterday => 'Yesterday';

  @override
  String get titleTimeline => 'Timeline';

  @override
  String get bodyNoMediaInTimeline => 'Your gallery is empty';

  @override
  String get bodyPullToScan => 'Pull down to scan for new photos and videos.';

  @override
  String get titleFlashback => 'On This Day';

  @override
  String get tooltipExpandFlashback => 'Show memories';

  @override
  String get tooltipCollapseFlashback => 'Hide memories';

  @override
  String get labelFlashbackOneYearAgo => '1 year ago';

  @override
  String bodyFlashbackYearsAgo(int years) {
    return '$years years ago';
  }

  @override
  String bodyGridColumns(int count) {
    return '$count per row';
  }

  @override
  String get labelBadgeGif => 'GIF';

  @override
  String get labelBadgeRaw => 'RAW';

  @override
  String get labelBadgeHd => 'HD';

  @override
  String labelBadgeVideoDuration(String duration) {
    return 'Video, $duration';
  }

  @override
  String get labelScrollToDate => 'Scroll to date';

  @override
  String get tooltipViewerClose => 'Close';

  @override
  String get labelViewerRotateLeft => 'Rotate left';

  @override
  String get labelViewerRotateRight => 'Rotate right';

  @override
  String get labelViewerAddFavorite => 'Add to favorites';

  @override
  String get bodyViewerRemoveFavorite => 'Remove from favorites';

  @override
  String get actionPlay => 'Play';

  @override
  String get actionPause => 'Pause';

  @override
  String get tooltipFrameForward => 'Next frame';

  @override
  String get tooltipFrameBackward => 'Previous frame';

  @override
  String get tooltipSkipForward => 'Forward 10 seconds';

  @override
  String get tooltipSkipBackward => 'Back 10 seconds';

  @override
  String get tooltipLoopPlayback => 'Repeat';

  @override
  String get tooltipPlaybackSpeed => 'Playback speed';

  @override
  String get bodyVideoCannotPlay => 'This video cannot be played.';

  @override
  String get bodyVideoFormatUnsupported =>
      'This device cannot play this video format.';

  @override
  String get tooltipDetailsTitle => 'Details';

  @override
  String get labelDetailsFileName => 'File name';

  @override
  String get labelDetailsFormat => 'Format';

  @override
  String get labelDetailsSize => 'Size';

  @override
  String get labelDetailsDimensions => 'Dimensions';

  @override
  String get labelDetailsDuration => 'Duration';

  @override
  String get labelDetailsDateTaken => 'Date taken';

  @override
  String get labelDetailsDateModified => 'Last modified';

  @override
  String get labelDetailsFolder => 'Folder';

  @override
  String get labelDetailsCameraSection => 'Camera and metadata';

  @override
  String get bodyDetailsNoMetadata =>
      'No camera metadata was found in this file.';

  @override
  String get labelDetailsCamera => 'Camera';

  @override
  String get labelDetailsLens => 'Lens';

  @override
  String get labelDetailsAperture => 'Aperture';

  @override
  String get labelDetailsShutter => 'Shutter';

  @override
  String get labelDetailsIso => 'ISO';

  @override
  String get labelDetailsFocalLength => 'Focal length';

  @override
  String get labelDetailsFlash => 'Flash';

  @override
  String get labelDetailsWhiteBalance => 'White balance';

  @override
  String get labelDetailsMeteringMode => 'Metering mode';

  @override
  String get labelDetailsColorSpace => 'Color space';

  @override
  String get labelDetailsSoftware => 'Software';

  @override
  String get labelDetailsLocation => 'Location';

  @override
  String get labelDetailsAltitude => 'Altitude';

  @override
  String get titleEditor => 'Edit';

  @override
  String get titleEditorOpen => 'Edit';

  @override
  String get labelEditorSave => 'Save copy';

  @override
  String get bodyEditorSaving => 'Saving a copy...';

  @override
  String bodyEditorSaved(String fileName) {
    return 'Saved a copy: $fileName';
  }

  @override
  String get errorEditorSaveFailed => 'The copy could not be saved';

  @override
  String get bodyEditorOriginalKept => 'Your original photo was not changed';

  @override
  String get bodyEditorCannotOpen => 'This photo cannot be edited';

  @override
  String get bodyEditorTooLarge =>
      'This photo is too large to edit on this device';

  @override
  String get errorEditorPreviewFailed => 'The preview could not be drawn';

  @override
  String get tooltipEditorUndo => 'Undo';

  @override
  String get tooltipEditorRedo => 'Redo';

  @override
  String get tooltipEditorResetAll => 'Reset all';

  @override
  String get titleEditorDiscard => 'Discard changes?';

  @override
  String get bodyEditorDiscardMessage =>
      'Your edits have not been saved. Leaving now will lose them.';

  @override
  String get actionEditorDiscard => 'Discard';

  @override
  String get actionEditorKeepEditing => 'Keep editing';

  @override
  String get labelEditorToolCrop => 'Crop';

  @override
  String get labelEditorToolTune => 'Tune';

  @override
  String get labelEditorToolMasks => 'Masks';

  @override
  String get labelEditorToolFilters => 'Filters';

  @override
  String get labelEditorToolMarkup => 'Markup';

  @override
  String get labelEditorToolRedact => 'Hide';

  @override
  String get labelEditorToolWatermark => 'Watermark';

  @override
  String get labelCropAspectFree => 'Free';

  @override
  String get labelCropAspectOriginal => 'Original';

  @override
  String get labelCropAspectSquare => 'Square';

  @override
  String get labelCropAspect4x3 => '4:3';

  @override
  String get labelCropAspect3x4 => '3:4';

  @override
  String get labelCropAspect16x9 => '16:9';

  @override
  String get labelCropAspect9x16 => '9:16';

  @override
  String get labelCropAspect3x2 => '3:2';

  @override
  String get labelCropAspect2x3 => '2:3';

  @override
  String get tooltipCropRotateLeft => 'Rotate left';

  @override
  String get tooltipCropRotateRight => 'Rotate right';

  @override
  String get tooltipCropFlipHorizontal => 'Mirror sideways';

  @override
  String get tooltipCropFlipVertical => 'Mirror upside down';

  @override
  String get labelCropStraighten => 'Straighten';

  @override
  String get labelCropPerspectiveVertical => 'Vertical tilt';

  @override
  String get labelCropPerspectiveHorizontal => 'Horizontal tilt';

  @override
  String get actionCropReset => 'Reset crop';

  @override
  String get labelToneExposure => 'Exposure';

  @override
  String get labelToneContrast => 'Contrast';

  @override
  String get labelToneHighlights => 'Highlights';

  @override
  String get labelToneShadows => 'Shadows';

  @override
  String get labelToneTemperature => 'Warmth';

  @override
  String get labelToneTint => 'Tint';

  @override
  String get labelToneVibrance => 'Vibrance';

  @override
  String get labelToneSaturation => 'Saturation';

  @override
  String get actionToneReset => 'Reset tune';

  @override
  String get labelToneCurves => 'Curves';

  @override
  String get labelCurveChannelRgb => 'All';

  @override
  String get labelCurveChannelRed => 'Red';

  @override
  String get labelCurveChannelGreen => 'Green';

  @override
  String get labelCurveChannelBlue => 'Blue';

  @override
  String get actionCurveReset => 'Reset curve';

  @override
  String get helpCurveAddHint => 'Tap to add a point, long-press to remove';

  @override
  String get labelMaskShapeLinear => 'Linear';

  @override
  String get labelMaskShapeRadial => 'Radial';

  @override
  String get labelMaskFeather => 'Feather';

  @override
  String get labelMaskInvert => 'Invert';

  @override
  String get labelMaskBlur => 'Blur';

  @override
  String get tooltipMaskAddLinear => 'Add linear gradient';

  @override
  String get tooltipMaskAddRadial => 'Add radial mask';

  @override
  String get emptyMask => 'Tap + to add a mask';

  @override
  String get titleHsl => 'HSL Color Tuner';

  @override
  String get labelHslHue => 'Hue';

  @override
  String get labelHslSaturation => 'Saturation';

  @override
  String get labelHslLuminance => 'Luminance';

  @override
  String get actionHslReset => 'Reset HSL';

  @override
  String get labelHslRangeRed => 'Red';

  @override
  String get labelHslRangeOrange => 'Orange';

  @override
  String get labelHslRangeYellow => 'Yellow';

  @override
  String get labelHslRangeGreen => 'Green';

  @override
  String get labelHslRangeCyan => 'Cyan';

  @override
  String get labelHslRangeBlue => 'Blue';

  @override
  String get labelHslRangePurple => 'Purple';

  @override
  String get labelHslRangeMagenta => 'Magenta';

  @override
  String get labelFilterNone => 'Original';

  @override
  String get labelFilterMono => 'Mono';

  @override
  String get labelFilterSepia => 'Sepia';

  @override
  String get labelFilterVintage => 'Vintage';

  @override
  String get labelFilterVivid => 'Vivid';

  @override
  String get labelFilterCool => 'Cool';

  @override
  String get labelFilterWarm => 'Warm';

  @override
  String get labelFilterFade => 'Fade';

  @override
  String get labelFilterIntensity => 'Strength';

  @override
  String get labelMarkupFreehand => 'Draw';

  @override
  String get labelMarkupRectangle => 'Rectangle';

  @override
  String get labelMarkupEllipse => 'Circle';

  @override
  String get labelMarkupLine => 'Line';

  @override
  String get labelMarkupArrow => 'Arrow';

  @override
  String get labelMarkupText => 'Text';

  @override
  String get labelMarkupColor => 'Colour';

  @override
  String get labelMarkupThickness => 'Thickness';

  @override
  String get titleMarkupFilled => 'Fill shape';

  @override
  String get actionMarkupUndoLayer => 'Remove last';

  @override
  String get titleMarkupText => 'Add text';

  @override
  String get helpMarkupTextHint => 'Type your text';

  @override
  String get actionMarkupTextAdd => 'Add';

  @override
  String get helpMarkupHint => 'Drag on the photo to draw';

  @override
  String get labelRedactBlur => 'Blur';

  @override
  String get labelRedactPixelate => 'Pixelate';

  @override
  String get labelRedactBlackout => 'Blackout';

  @override
  String get labelRedactStrength => 'Strength';

  @override
  String get helpRedactHint => 'Drag over anything you want hidden';

  @override
  String get actionRedactRemoveLast => 'Remove last';

  @override
  String bodyRedactCount(int count) {
    return '$count areas hidden';
  }

  @override
  String get labelWatermarkNone => 'None';

  @override
  String get labelWatermarkText => 'Text';

  @override
  String get labelWatermarkTimestamp => 'Date and time';

  @override
  String get labelWatermarkLogo => 'Logo';

  @override
  String get helpWatermarkTextHint => 'Watermark text';

  @override
  String get labelWatermarkPosition => 'Position';

  @override
  String get labelWatermarkOpacity => 'Opacity';

  @override
  String get labelWatermarkSize => 'Size';

  @override
  String get labelWatermarkMargin => 'Edge gap';

  @override
  String get actionWatermarkPickLogo => 'Choose a logo file';

  @override
  String get bodyWatermarkNoLogo => 'No logo chosen yet';

  @override
  String get labelPositionTopLeft => 'Top left';

  @override
  String get labelPositionTopCenter => 'Top centre';

  @override
  String get labelPositionTopRight => 'Top right';

  @override
  String get labelPositionCenterLeft => 'Middle left';

  @override
  String get labelPositionCenter => 'Centre';

  @override
  String get labelPositionCenterRight => 'Middle right';

  @override
  String get labelPositionBottomLeft => 'Bottom left';

  @override
  String get labelPositionBottomCenter => 'Bottom centre';

  @override
  String get labelPositionBottomRight => 'Bottom right';

  @override
  String get titleConvertOpen => 'Convert';

  @override
  String get titleConvert => 'Convert and resize';

  @override
  String get bodyConvertCannotOpen => 'This file cannot be converted';

  @override
  String get bodyConvertTooLarge => 'This file is too large to convert';

  @override
  String get bodyConvertUnreadable => 'This picture could not be read';

  @override
  String get labelConvertFormat => 'Format';

  @override
  String get labelConvertQuality => 'Quality';

  @override
  String get labelConvertResize => 'Size';

  @override
  String get labelConvertResizeNone => 'Original';

  @override
  String get labelConvertResizeLongestSide => 'Longest side';

  @override
  String get labelConvertResizePercent => 'Percent';

  @override
  String get labelConvertResizeExact => 'Width and height';

  @override
  String get titleConvertKeepAspect => 'Keep the shape';

  @override
  String get labelConvertWidth => 'Width';

  @override
  String get labelConvertHeight => 'Height';

  @override
  String get labelConvertLongestSide => 'Longest side (px)';

  @override
  String get labelConvertPercent => 'Percent of original';

  @override
  String get titleConvertStripMetadata => 'Remove camera info';

  @override
  String get helpConvertStripMetadataHint =>
      'Location and camera settings are left out of the copy';

  @override
  String get labelConvertOriginalSize => 'Original';

  @override
  String get labelConvertNewSize => 'New copy';

  @override
  String get bodyConvertEstimating => 'Working out the size';

  @override
  String get bodyConvertNoEstimate =>
      'The size cannot be worked out for this file';

  @override
  String get bodyConvertLargerWarning => 'The copy is larger than the original';

  @override
  String get labelConvertSave => 'Save a copy';

  @override
  String get labelConvertSaving => 'Saving';

  @override
  String get errorConvertFailed => 'The copy could not be saved';

  @override
  String get bodyConvertOriginalKept => 'Your original file is not changed';

  @override
  String get tooltipPdfOpen => 'Export as PDF';

  @override
  String get titlePdfExport => 'Export as PDF';

  @override
  String get labelPdfChoosePhotos => 'Choose photos';

  @override
  String get bodyPdfNoSelection => 'Choose at least one photo';

  @override
  String get bodyPdfNoPhotos => 'There are no photos to choose from';

  @override
  String get labelPdfPageSize => 'Page size';

  @override
  String get labelPdfPageA4 => 'A4';

  @override
  String get labelPdfPageLetter => 'Letter';

  @override
  String get labelPdfPageFitImage => 'Fit the photo';

  @override
  String get labelPdfOrientation => 'Direction';

  @override
  String get labelPdfOrientationPortrait => 'Upright';

  @override
  String get labelPdfOrientationLandscape => 'Sideways';

  @override
  String get labelPdfOrientationAuto => 'Follow the photo';

  @override
  String get labelPdfFit => 'Placement';

  @override
  String get labelPdfFitContain => 'Fit the whole photo';

  @override
  String get labelPdfFitFill => 'Fill the page';

  @override
  String get labelPdfMargin => 'Border';

  @override
  String get labelPdfMarginNone => 'None';

  @override
  String get labelPdfMarginSmall => 'Small';

  @override
  String get labelPdfMarginMedium => 'Medium';

  @override
  String get labelPdfMarginLarge => 'Large';

  @override
  String get labelPdfQuality => 'Photo quality';

  @override
  String get actionPdfExport => 'Create the PDF';

  @override
  String get labelPdfExporting => 'Creating the PDF';

  @override
  String get errorPdfFailed => 'The PDF could not be created';

  @override
  String get titleVideoToolsOpen => 'Video tools';

  @override
  String get titleVideoTools => 'Video tools';

  @override
  String get bodyVideoToolsUnavailable => 'This clip could not be read';

  @override
  String get tabVideoTabFrame => 'Frame';

  @override
  String get tabVideoTabGif => 'GIF';

  @override
  String get tabVideoTabTrim => 'Trim';

  @override
  String get labelFramePosition => 'Position in the clip';

  @override
  String get labelFrameFormat => 'Save as';

  @override
  String get actionFrameSave => 'Save this frame';

  @override
  String get bodyFrameUnavailable => 'No frame could be read here';

  @override
  String get labelGifFrameRate => 'Frames per second';

  @override
  String get labelGifSize => 'Size';

  @override
  String get titleGifLoopLabel => 'Play on a loop';

  @override
  String get bodyGifCapped => 'The GIF is shortened to keep the file small';

  @override
  String get actionGifExport => 'Create the GIF';

  @override
  String get labelGifExporting => 'Creating the GIF';

  @override
  String get labelTrimStart => 'Start';

  @override
  String get labelTrimEnd => 'End';

  @override
  String get labelTrimLength => 'Length';

  @override
  String get actionTrim => 'Save trimmed clip';

  @override
  String get bodyTrimLosslessNote =>
      'Nothing is re-encoded, so no quality is lost. The cut may begin a moment earlier, at the nearest key frame.';

  @override
  String get bodyTrimTooShort => 'The chosen part is too short';

  @override
  String get labelVideoWorking => 'Working';

  @override
  String get errorVideoJobFailed => 'That could not be finished';

  @override
  String bodyConvertPixelSize(int width, int height) {
    return '$width by $height pixels';
  }

  @override
  String bodyConvertSmallerBy(int percent) {
    return '$percent percent smaller';
  }

  @override
  String bodyConvertSavedAs(String name) {
    return 'Saved as $name';
  }

  @override
  String bodyPdfSelectedCount(int count) {
    return '$count chosen';
  }

  @override
  String bodyPdfMaxPagesReached(int count) {
    return 'Only $count photos fit in one PDF';
  }

  @override
  String bodyPdfExportedAs(String name, int pages) {
    return 'Saved $name with $pages pages';
  }

  @override
  String bodyPdfSkippedCount(int count) {
    return '$count photos could not be read and were left out';
  }

  @override
  String bodyGifFrameCount(int count) {
    return '$count frames';
  }

  @override
  String bodyVideoJobSavedAs(String name) {
    return 'Saved as $name';
  }

  @override
  String get titleSearch => 'Search';

  @override
  String get tooltipSearchOpen => 'Search';

  @override
  String get helpSearchHint => 'Search names, tags, notes, places';

  @override
  String get tooltipSearchClear => 'Clear';

  @override
  String get tooltipSearchFilters => 'Filters';

  @override
  String get titleSearchStart => 'Search your library';

  @override
  String get bodySearchStart =>
      'Look through names, tags, notes, camera and place. Start a word with tag:, type:, place:, camera:, before: or after: to narrow the search.';

  @override
  String get titleSearchNoResults => 'Nothing matched';

  @override
  String get bodySearchNoResults => 'Try fewer words, or check the filters.';

  @override
  String get errorSearchFailed => 'The search could not run';

  @override
  String get titleSearchRecent => 'Recent searches';

  @override
  String get actionSearchRecentClear => 'Clear all';

  @override
  String get tooltipSearchRecentRemove => 'Forget this search';

  @override
  String bodySearchResultCount(int count) {
    return '$count results';
  }

  @override
  String get bodySearchMatchedInName => 'Matched the file name';

  @override
  String get labelSearchMatchedInTags => 'Matched a tag';

  @override
  String get labelSearchMatchedInNotes => 'Matched a note';

  @override
  String get labelSearchMatchedInPlace => 'Matched a place';

  @override
  String get bodySearchMatchedInDetails => 'Matched the photo details';

  @override
  String get tooltipFilterTitle => 'Filters';

  @override
  String get labelFilterMediaType => 'Kind';

  @override
  String get labelFilterTypeImage => 'Photos';

  @override
  String get labelFilterTypeVideo => 'Videos';

  @override
  String get labelFilterTypeGif => 'GIFs';

  @override
  String get labelFilterTypeRaw => 'RAW';

  @override
  String get labelFilterTypeSvg => 'SVG';

  @override
  String get titleFilterFavoritesOnly => 'Favourites only';

  @override
  String get titleFilterHasLocation => 'Has a place';

  @override
  String get labelFilterDateRange => 'Date range';

  @override
  String get labelFilterDateAny => 'Any date';

  @override
  String get actionFilterDateChoose => 'Choose dates';

  @override
  String get actionFilterDateClear => 'Clear dates';

  @override
  String get labelFilterTags => 'Tags';

  @override
  String get actionFilterTagModeAll => 'Has all';

  @override
  String get actionFilterTagModeAny => 'Has any';

  @override
  String get labelFilterNoTags => 'No tags yet';

  @override
  String get actionFilterReset => 'Reset';

  @override
  String get actionFilterApply => 'Apply';

  @override
  String get titleTags => 'Tags';

  @override
  String get titleTagsOpen => 'Tags';

  @override
  String get titleTagsEmpty => 'No tags yet';

  @override
  String get bodyTagsEmpty => 'Make a tag to group photos your own way.';

  @override
  String get actionTagNew => 'New tag';

  @override
  String get tooltipTagEditTitle => 'Edit tag';

  @override
  String get labelTagName => 'Tag name';

  @override
  String get labelTagColor => 'Colour';

  @override
  String get actionTagSave => 'Save';

  @override
  String get actionTagCancel => 'Cancel';

  @override
  String get tooltipTagDelete => 'Delete';

  @override
  String get titleTagDelete => 'Delete this tag?';

  @override
  String get bodyTagDelete =>
      'The tag comes off every photo that has it. No photo is deleted.';

  @override
  String descTagItemCount(int count) {
    return '$count items';
  }

  @override
  String get emptyTagError => 'A tag needs a name';

  @override
  String get bodyTagErrorTooLong => 'That name is too long';

  @override
  String get bodyTagErrorDuplicate => 'That tag already exists';

  @override
  String get errorTagErrorFailed => 'The tag could not be saved';

  @override
  String get titleTagSheet => 'Tags on this item';

  @override
  String get helpTagSheetNewHint => 'Add a new tag';

  @override
  String get actionTagSheetAdd => 'Add';

  @override
  String get actionTagSheetDone => 'Done';

  @override
  String get titleTagSheetOpen => 'Tags';

  @override
  String get titleCleaner => 'Duplicate cleaner';

  @override
  String get titleCleanerOpen => 'Duplicate cleaner';

  @override
  String get labelCleanerStart => 'Find duplicates';

  @override
  String get actionCleanerStop => 'Stop';

  @override
  String get labelCleanerRescan => 'Scan again';

  @override
  String get titleCleanerIdle => 'Find duplicates';

  @override
  String get bodyCleanerIdle =>
      'Each file is read once and what was found is remembered, so scanning again later is quick.';

  @override
  String bodyCleanerScanning(int processed, int total) {
    return 'Checked $processed of $total';
  }

  @override
  String get labelCleanerGrouping => 'Grouping the copies';

  @override
  String get labelCleanerCancelled => 'Scan stopped';

  @override
  String get errorCleanerFailed => 'The scan could not finish';

  @override
  String get titleCleanerNone => 'No duplicates found';

  @override
  String get bodyCleanerNone =>
      'Nothing in your library looks like a copy of anything else.';

  @override
  String bodyCleanerGroupsFound(int count) {
    return '$count groups of copies';
  }

  @override
  String bodyCleanerReclaimable(String size) {
    return 'About $size could be freed';
  }

  @override
  String bodyCleanerFailures(int count) {
    return '$count files could not be read and were skipped';
  }

  @override
  String get labelCleanerKindExact => 'Identical files';

  @override
  String get labelCleanerKindSimilar => 'Looks the same';

  @override
  String bodyCleanerMemberCount(int count) {
    return '$count copies';
  }

  @override
  String get actionCleanerCompare => 'Compare';

  @override
  String get titleCompare => 'Compare copies';

  @override
  String get bodyCompareGroupGone => 'This group has already been dealt with';

  @override
  String get actionCompareKeepThis => 'Keep this one';

  @override
  String get labelCompareBestBadge => 'Suggested';

  @override
  String bodyCompareKeepAndTrash(int count) {
    return 'Keep 1, move $count to trash';
  }

  @override
  String get bodyCompareTrashNotice =>
      'Nothing is erased. The other copies move to the trash and can be brought back.';

  @override
  String titleCompareConfirm(int count) {
    return 'Move $count copies to the trash?';
  }

  @override
  String get bodyCompareConfirm =>
      'Only the copy you kept stays in the gallery. The files stay on the device and can be brought back.';

  @override
  String get actionCompareConfirm => 'Move to trash';

  @override
  String get actionCompareCancel => 'Cancel';

  @override
  String bodyCompareMoved(int count) {
    return '$count copies moved to the trash';
  }

  @override
  String get errorCompareFailed => 'The copies could not be moved';

  @override
  String get labelCompareFieldSize => 'Size';

  @override
  String get labelCompareFieldPixels => 'Pixels';

  @override
  String get labelCompareFieldDate => 'Date';

  @override
  String get labelCompareFieldCamera => 'Camera';

  @override
  String get labelCompareUnknown => 'Unknown';

  @override
  String get titleAlbums => 'Albums';

  @override
  String get labelAlbumsSectionMine => 'My albums';

  @override
  String get labelAlbumsSectionSmart => 'Smart albums';

  @override
  String get labelAlbumsSectionFolders => 'Device folders';

  @override
  String get titleAlbumsEmpty => 'No albums yet';

  @override
  String get bodyAlbumsEmpty =>
      'Make an album to group photos and videos your own way. The files stay where they are.';

  @override
  String get emptyAlbumsFolders => 'No folders found';

  @override
  String get errorAlbumsLoadFailed => 'Albums could not be loaded';

  @override
  String descAlbumItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'Empty',
    );
    return '$_temp0';
  }

  @override
  String get labelSmartAlbumFavorites => 'Favourites';

  @override
  String get labelSmartAlbumVideos => 'Videos';

  @override
  String get labelSmartAlbumGifs => 'Animated & GIFs';

  @override
  String get labelSmartAlbumRaw => 'RAW captures';

  @override
  String get labelSmartAlbumPanoramas => 'Panoramas';

  @override
  String get labelSmartAlbumRecent => 'Recently added';

  @override
  String get labelSmartAlbumTrash => 'Trash';

  @override
  String get actionAlbumNew => 'New album';

  @override
  String get titleAlbumCreate => 'New album';

  @override
  String get titleAlbumRenameTitle => 'Rename album';

  @override
  String get labelAlbumName => 'Album name';

  @override
  String get helpAlbumNameHint => 'Holiday 2026';

  @override
  String get labelAlbumSave => 'Save';

  @override
  String get actionAlbumCancel => 'Cancel';

  @override
  String get titleAlbumRename => 'Rename';

  @override
  String get titleAlbumDelete => 'Delete album';

  @override
  String get titleAlbumChooseCover => 'Choose cover';

  @override
  String get titleAlbumReorder => 'Change order';

  @override
  String get titleAlbumRemoveMedia => 'Remove from album';

  @override
  String get titleAlbumPin => 'Pin to top';

  @override
  String get emptyAlbumError => 'An album needs a name';

  @override
  String get bodyAlbumErrorTooLong => 'That name is too long';

  @override
  String get bodyAlbumErrorDuplicate =>
      'An album with that name already exists';

  @override
  String get errorAlbumErrorFailed => 'That change could not be saved';

  @override
  String titleAlbumDeleteConfirm(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get bodyAlbumDeleteConfirm =>
      'Only the album goes. Every photo and video stays on the device exactly where it is.';

  @override
  String get actionAlbumDeleteConfirm => 'Delete album';

  @override
  String get bodyAlbumDeleted => 'Album deleted';

  @override
  String get bodyAlbumRemovedFromAlbum => 'Removed from the album';

  @override
  String get bodyAlbumCoverSet => 'Cover updated';

  @override
  String get bodyAlbumOrderSaved => 'New order saved';

  @override
  String get titleAlbumEmpty => 'This album is empty';

  @override
  String get bodyAlbumEmpty =>
      'Add photos and videos from the gallery. They are not moved or copied.';

  @override
  String get bodyAlbumGone => 'This album is no longer there';

  @override
  String get titleAlbumReorderTitle => 'Change order';

  @override
  String get helpAlbumReorderHint =>
      'Drag an item to move it. The new order is saved when you tap Save.';

  @override
  String get actionAlbumReorderSave => 'Save order';

  @override
  String get titleAlbumCover => 'Choose a cover';

  @override
  String get actionAlbumCoverClear => 'Use the newest item';

  @override
  String get titleAlbumPicker => 'Add to album';

  @override
  String get emptyAlbumPicker => 'You have no albums yet';

  @override
  String get actionAlbumPickerCreate => 'New album';

  @override
  String get actionAlbumPickerDone => 'Done';

  @override
  String get bodyAlbumPickerSaved => 'Albums updated';

  @override
  String get titleFolderEmpty => 'This folder is empty';

  @override
  String get titleSmartAlbumEmpty => 'Nothing here yet';

  @override
  String get bodySmartAlbumUnknown => 'That album does not exist';

  @override
  String get titleFilterHasTags => 'Tagged only';

  @override
  String get labelFilterFileSize => 'File size';

  @override
  String get labelFilterSizeAny => 'Any size';

  @override
  String get labelFilterSizeSmall => 'Under 1 MB';

  @override
  String get bodyFilterSizeMedium => '1 to 10 MB';

  @override
  String get labelFilterSizeLarge => 'Over 10 MB';

  @override
  String get labelFilterSortBy => 'Sort by';

  @override
  String get labelFilterSortDateTaken => 'Date taken';

  @override
  String get labelFilterSortDateAdded => 'Date added';

  @override
  String get labelFilterSortName => 'Name';

  @override
  String get labelFilterSortSize => 'Size';

  @override
  String get actionFilterSortNewestFirst => 'Newest first';

  @override
  String get actionFilterSortOldestFirst => 'Oldest first';

  @override
  String get titleVault => 'Private Vault';

  @override
  String get titleVaultMenuLabel => 'Private Vault';

  @override
  String get titleVaultMoveToVault => 'Move to vault';

  @override
  String get titleVaultSetUp => 'Create your vault';

  @override
  String get bodyVaultSetUp =>
      'Items you move here are encrypted with a key held by this device and hidden from the gallery.';

  @override
  String get bodyVaultNoRecoveryWarning =>
      'There is no way to recover a forgotten PIN. Without it nobody can open the vault, not even this app.';

  @override
  String get labelVaultChoosePin => 'Choose a PIN';

  @override
  String get bodyVaultConfirmPin => 'Enter the PIN again';

  @override
  String get labelVaultEnterPin => 'Enter your PIN';

  @override
  String get labelVaultCreate => 'Create vault';

  @override
  String get labelVaultUnlock => 'Unlock';

  @override
  String get labelVaultUseBiometrics => 'Use fingerprint';

  @override
  String get bodyVaultUnlockReason => 'Unlock your private vault';

  @override
  String get tooltipVaultLockNow => 'Lock now';

  @override
  String get bodyVaultPinMismatch => 'The two PINs are not the same';

  @override
  String get bodyVaultWrongPin => 'That PIN is not right';

  @override
  String bodyVaultAttemptsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tries left',
      one: '1 try left',
    );
    return '$_temp0';
  }

  @override
  String bodyVaultLockedOut(int seconds) {
    return 'Too many tries. Wait $seconds seconds.';
  }

  @override
  String bodyVaultPinTooShort(int count) {
    return 'A PIN needs at least $count digits';
  }

  @override
  String bodyVaultPinTooLong(int count) {
    return 'A PIN can have at most $count digits';
  }

  @override
  String get bodyVaultPinNotDigits => 'A PIN can only have digits';

  @override
  String get bodyVaultPinAllSame =>
      'Do not use the same digit all the way through';

  @override
  String get bodyVaultPinSequential => 'Do not use digits in a straight run';

  @override
  String get errorVaultBiometricFailed => 'Not recognised. Use your PIN.';

  @override
  String get bodyVaultBiometricUnavailable =>
      'Fingerprint unlock is not available. Use your PIN.';

  @override
  String get errorVaultAuth => 'The vault could not be opened';

  @override
  String get titleVaultKeystoreUnavailable => 'No safe key storage';

  @override
  String get bodyVaultKeystoreUnavailable =>
      'The vault needs a hardware-backed key store, and this device does not have a working one. Nothing is encrypted without it, so the vault stays shut.';

  @override
  String get titleVaultEmpty => 'The vault is empty';

  @override
  String get bodyVaultEmpty =>
      'Add photos and videos here to encrypt them and take them out of the gallery.';

  @override
  String bodyVaultSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get labelVaultAddItems => 'Add items';

  @override
  String get tooltipVaultRestore => 'Restore to gallery';

  @override
  String get tooltipVaultDeleteForever => 'Delete for good';

  @override
  String get tooltipVaultSettingsAction => 'Vault settings';

  @override
  String get actionVaultCancel => 'Cancel';

  @override
  String get tooltipVaultClearSelection => 'Clear selection';

  @override
  String get titleVaultImport => 'Move to vault';

  @override
  String get bodyVaultImport =>
      'The items are encrypted and taken out of the gallery. What happens to the originals is up to you.';

  @override
  String get titleVaultImportKeepOriginal => 'Keep the originals';

  @override
  String get bodyVaultImportKeepOriginal =>
      'The originals stay where they are. Delete them yourself later if you want to.';

  @override
  String get titleVaultImportShredOriginal => 'Shred the originals';

  @override
  String get bodyVaultImportShredOriginal =>
      'The original files are overwritten and deleted. This cannot be undone.';

  @override
  String bodyVaultImportConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Move $count items',
      one: 'Move 1 item',
    );
    return '$_temp0';
  }

  @override
  String get labelVaultImportNothingSelected => 'Nothing is selected';

  @override
  String bodyVaultShredConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Destroy $count originals?',
      one: 'Destroy 1 original?',
    );
    return '$_temp0';
  }

  @override
  String get bodyVaultShredConfirm =>
      'The original files will be overwritten and deleted. There is no undo, and no way to get them back.';

  @override
  String get actionVaultShredConfirm => 'Shred them';

  @override
  String bodyVaultImportDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items moved to the vault',
      one: '1 item moved to the vault',
    );
    return '$_temp0';
  }

  @override
  String bodyVaultImportPartial(int moved, int failed) {
    return '$moved moved, $failed could not be read';
  }

  @override
  String get errorVaultImportFailed => 'Nothing could be moved to the vault';

  @override
  String bodyVaultRestoreConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Restore $count items?',
      one: 'Restore 1 item?',
    );
    return '$_temp0';
  }

  @override
  String get bodyVaultRestoreConfirm =>
      'The items are written back into your gallery folders and taken out of the vault.';

  @override
  String get actionVaultRestoreConfirm => 'Restore';

  @override
  String bodyVaultDeleteConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count items for good?',
      one: 'Delete 1 item for good?',
    );
    return '$_temp0';
  }

  @override
  String get bodyVaultDeleteConfirm =>
      'The encrypted files are overwritten and deleted. There is no undo, and no copy anywhere else.';

  @override
  String get errorVaultViewerFailed => 'This item could not be opened';

  @override
  String get bodyVaultViewerTampered =>
      'This item failed its integrity check and was not opened';

  @override
  String get titleVaultSettings => 'Vault settings';

  @override
  String get titleVaultAutoLockHeading => 'Auto-lock';

  @override
  String get bodyVaultAutoLock =>
      'The vault always locks when the app leaves the screen. This is how long it waits while you are not touching it.';

  @override
  String bodyVaultAutoLockSeconds(int count) {
    return '$count seconds';
  }

  @override
  String bodyVaultAutoLockMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String get titleVaultBiometricHeading => 'Fingerprint unlock';

  @override
  String get bodyVaultBiometric =>
      'A shortcut, not a replacement. Your PIN opens the vault whether this is on or off.';

  @override
  String get titleVaultShredHeading => 'Shred passes';

  @override
  String get bodyVaultShred =>
      'How many times a file is overwritten before it is deleted. More passes take longer. On flash storage an overwrite is a strong measure, not a guarantee.';

  @override
  String bodyVaultShredPassCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count passes',
      one: '1 pass',
    );
    return '$_temp0';
  }

  @override
  String get titleVaultShredDefaultHeading => 'Shred by default';

  @override
  String get bodyVaultShredDefault =>
      'Pre-selects the shred choice when you add items. It still asks you to confirm every time.';

  @override
  String get titleVaultChangePin => 'Change PIN';

  @override
  String get labelVaultCurrentPin => 'Current PIN';

  @override
  String get labelVaultNewPin => 'New PIN';

  @override
  String get bodyVaultPinChanged => 'Your PIN has been changed';

  @override
  String get titleVaultSecureScreenHeading => 'Screenshots blocked';

  @override
  String get bodyVaultSecureScreen =>
      'While the vault is open, Android blocks screenshots and screen recording, and hides the vault in the app switcher.';

  @override
  String bodySelectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '1 selected',
    );
    return '$_temp0';
  }

  @override
  String get tooltipSelectionClear => 'Clear selection';

  @override
  String get tooltipSelectionSelectAll => 'Select all';

  @override
  String get bodySelectionFull => 'That is as many as one batch can hold';

  @override
  String get labelBatchActionConvert => 'Convert';

  @override
  String get labelBatchActionMore => 'More';

  @override
  String get labelBatchActionWatermark => 'Watermark';

  @override
  String get labelBatchActionExportPdf => 'Make a PDF';

  @override
  String get labelBatchActionAddTags => 'Add tags';

  @override
  String get labelBatchActionRemoveTags => 'Remove tags';

  @override
  String get labelBatchActionAddToAlbum => 'Add to album';

  @override
  String get labelBatchActionFavourite => 'Add to favourites';

  @override
  String get bodyBatchActionUnfavourite => 'Remove from favourites';

  @override
  String get labelBatchActionMoveToVault => 'Move to vault';

  @override
  String get bodyBatchActionTransfer => 'Send to a device';

  @override
  String get titleBatchActionMoveToTrash => 'Move to trash';

  @override
  String get emptyBatchBlocked => 'Select something first';

  @override
  String get bodyBatchBlockedTooLarge => 'Too many items for one batch';

  @override
  String get bodyBatchBlockedUnsupported => 'Not available for these files';

  @override
  String get bodyBatchBlockedMixed =>
      'Videos cannot be included in this action';

  @override
  String get titleBatchRunning => 'Working';

  @override
  String bodyBatchProgress(int done, int total) {
    return '$done of $total';
  }

  @override
  String get labelBatchCancel => 'Cancel';

  @override
  String get bodyBatchCancelling => 'Stopping after this file';

  @override
  String get labelBatchDone => 'Finished';

  @override
  String bodyBatchResultSucceeded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files done',
      one: '1 file done',
    );
    return '$_temp0';
  }

  @override
  String errorBatchResultFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files could not be done',
      one: '1 file could not be done',
    );
    return '$_temp0';
  }

  @override
  String bodyBatchResultSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files skipped',
      one: '1 file skipped',
    );
    return '$_temp0';
  }

  @override
  String get titleBatchConfirm => 'Are you sure?';

  @override
  String bodyBatchConfirmVault(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos will be moved into the vault',
      one: '1 photo will be moved into the vault',
    );
    return '$_temp0';
  }

  @override
  String bodyBatchConfirmTrash(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items will be moved to the trash. Nothing is erased.',
      one: '1 item will be moved to the trash. Nothing is erased.',
    );
    return '$_temp0';
  }

  @override
  String bodyBatchConfirmNewFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new files will be saved beside the originals.',
      one: 'A new file will be saved beside the original.',
    );
    return '$_temp0';
  }

  @override
  String get actionBatchConfirmContinue => 'Continue';

  @override
  String get labelBatchPickTags => 'Choose tags';

  @override
  String get labelBatchPickAlbum => 'Choose an album';

  @override
  String get titleBackup => 'Backup and restore';

  @override
  String get titleBackupOpen => 'Backup and restore';

  @override
  String get titleBackupCreate => 'Create a backup';

  @override
  String get bodyBackupCreate =>
      'Saves your tags, albums, favourites and notes into one password-protected file. Photos and videos are not included: send those to another device with Transfer.';

  @override
  String get actionBackupCreate => 'Create backup';

  @override
  String get titleBackupRestore => 'Restore a backup';

  @override
  String get bodyBackupRestore =>
      'Brings back tags, albums, favourites and notes for the photos that are on this device. Nothing on this device is deleted.';

  @override
  String get actionBackupRestore => 'Choose a backup file';

  @override
  String get titleBackupPassword => 'Backup password';

  @override
  String get labelBackupPassword => 'Password';

  @override
  String get labelBackupPasswordConfirm => 'Type it again';

  @override
  String get bodyBackupPasswordWarning =>
      'There is no way to recover this password. If you forget it, the backup cannot be opened.';

  @override
  String bodyBackupPasswordTooShort(int count) {
    return 'At least $count characters';
  }

  @override
  String get bodyBackupPasswordMismatch => 'The two do not match';

  @override
  String get labelBackupStageCollecting => 'Reading your library';

  @override
  String get labelBackupStagePacking => 'Packing';

  @override
  String get bodyBackupStageChoosing =>
      'Waiting for you to choose where to save';

  @override
  String get labelBackupStageEncrypting => 'Encrypting';

  @override
  String get labelBackupDone => 'Backup saved';

  @override
  String get labelBackupCancelled => 'Backup cancelled';

  @override
  String get bodyBackupNothingToSave =>
      'There are no tags, albums, notes or favourites to back up yet';

  @override
  String get errorBackupFailed => 'The backup could not be saved';

  @override
  String get titleRestorePreview => 'To be restored';

  @override
  String bodyRestoreFromBackupDate(String date) {
    return 'Backup from $date';
  }

  @override
  String bodyRestorePlanTags(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new tags',
      one: '1 new tag',
      zero: 'No new tags',
    );
    return '$_temp0';
  }

  @override
  String bodyRestorePlanAlbums(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new albums',
      one: '1 new album',
      zero: 'No new albums',
    );
    return '$_temp0';
  }

  @override
  String bodyRestorePlanLinks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tags and album places to add',
      one: '1 tag or album place to add',
      zero: 'No tags or album places to add',
    );
    return '$_temp0';
  }

  @override
  String bodyRestorePlanUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos to update',
      one: '1 photo to update',
      zero: 'No photos to update',
    );
    return '$_temp0';
  }

  @override
  String bodyRestorePlanUnmatched(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos in the backup are not on this device',
      one: '1 photo in the backup is not on this device',
    );
    return '$_temp0';
  }

  @override
  String get bodyRestorePlanNothing =>
      'This backup would change nothing on this device';

  @override
  String get labelRestoreApply => 'Restore';

  @override
  String get labelRestoreDone => 'Restore finished';

  @override
  String get bodyRestoreWrongPassword =>
      'Wrong password, or the file is damaged';

  @override
  String get bodyRestoreNotAnArchive => 'That is not a gallery backup file';

  @override
  String get bodyRestoreTooLarge =>
      'That file is too large to be a gallery backup';

  @override
  String get bodyRestoreTooNew =>
      'That backup was made by a newer version of the app';

  @override
  String get errorRestoreFailed => 'The backup could not be restored';

  @override
  String get titleSync => 'Transfer';

  @override
  String get titleSyncOpen => 'Transfer to a device';

  @override
  String get bodySyncIntro =>
      'Send photos straight to another phone on the same Wi-Fi. Nothing goes to the internet, and no account is needed.';

  @override
  String get bodySyncPrivacyNote =>
      'Both phones must be on the same Wi-Fi. The connection is refused unless the other device is on your local network, and it is closed as soon as you leave this screen.';

  @override
  String get labelSyncSend => 'Send';

  @override
  String get labelSyncReceive => 'Receive';

  @override
  String get bodySyncSend => 'Show a code on this phone, or scan the other one';

  @override
  String get bodySyncReceive => 'Show a code for the other phone to scan';

  @override
  String get actionSyncScanCode => 'Scan a code';

  @override
  String get titleSyncScan => 'Scan the other phone';

  @override
  String get titleSyncPairingHeading => 'Scan on other phone';

  @override
  String get titleSyncManualCodeHeading => 'Or type this code';

  @override
  String get labelSyncManualCode => 'Pairing code';

  @override
  String get bodySyncManualCodeInvalid => 'That code is not valid';

  @override
  String get bodySyncWaiting => 'Waiting for the other phone';

  @override
  String bodySyncPairedWith(String name) {
    return 'Paired with $name';
  }

  @override
  String get labelSyncTransferring => 'Transferring';

  @override
  String bodySyncProgressFiles(int done, int total) {
    return '$done of $total files';
  }

  @override
  String get bodySyncNothingSelected => 'Choose some photos to send first';

  @override
  String bodySyncOfferHeading(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files offered',
      one: '1 file offered',
    );
    return '$_temp0';
  }

  @override
  String get labelSyncDone => 'Transfer finished';

  @override
  String bodySyncResultReceived(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files received',
      one: '1 file received',
    );
    return '$_temp0';
  }

  @override
  String bodySyncResultSent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files sent',
      one: '1 file sent',
    );
    return '$_temp0';
  }

  @override
  String bodySyncResultSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files were already there',
      one: '1 file was already there',
    );
    return '$_temp0';
  }

  @override
  String errorSyncResultFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files did not arrive',
      one: '1 file did not arrive',
    );
    return '$_temp0';
  }

  @override
  String get bodySyncSavedToAppFolder =>
      'On this version of Android the files were saved in the app\'s own folder rather than your gallery.';

  @override
  String get actionSyncStop => 'Stop';

  @override
  String get bodySyncErrorNoNetwork => 'This phone is not on a Wi-Fi network';

  @override
  String get bodySyncErrorPairingTimeout => 'No device connected in time';

  @override
  String get bodySyncErrorRefused => 'That device is not on your local network';

  @override
  String get bodySyncErrorHandshake =>
      'The other device could not prove it showed that code';

  @override
  String get bodySyncErrorProtocol =>
      'The other device is running a different version of the app';

  @override
  String get bodySyncErrorConnection =>
      'The connection to the other device was lost';

  @override
  String get bodySyncErrorIdle => 'The other device stopped responding';

  @override
  String get bodySyncErrorCancelled => 'The transfer was stopped';

  @override
  String get bodySyncErrorUnknown => 'The transfer could not be finished';

  @override
  String get bodySyncCameraPermission =>
      'Camera access is needed to scan the code. You can type the code instead.';

  @override
  String get actionSyncTypeCodeInstead => 'Type the code';

  @override
  String get tooltipViewerMoreActions => 'More';

  @override
  String get titleCodeScanOpen => 'Scan codes';

  @override
  String get titleCodeScan => 'Codes in picture';

  @override
  String get labelCodeScanLooking => 'Looking for codes';

  @override
  String get bodyCodeScanNoCodes => 'No codes were found in this picture';

  @override
  String get errorCodeScanFailed => 'This picture could not be scanned';

  @override
  String get tooltipCodeScanRetry => 'Try again';

  @override
  String bodyCodeScanFoundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count codes found',
      one: '1 code found',
    );
    return '$_temp0';
  }

  @override
  String get labelCodeScanKindUrl => 'Web address';

  @override
  String get labelCodeScanKindWifi => 'Wi-Fi network';

  @override
  String get labelCodeScanKindPhone => 'Phone number';

  @override
  String get labelCodeScanKindEmail => 'Email address';

  @override
  String get labelCodeScanKindSms => 'Text message';

  @override
  String get labelCodeScanKindGeo => 'Map point';

  @override
  String get labelCodeScanKindContact => 'Contact card';

  @override
  String get labelCodeScanKindCalendar => 'Calendar entry';

  @override
  String get labelCodeScanKindText => 'Text';

  @override
  String get labelCodeScanActionCopy => 'Copy';

  @override
  String get labelCodeScanActionOpen => 'Open';

  @override
  String get labelCodeScanActionDial => 'Call';

  @override
  String get labelCodeScanActionEmail => 'Write email';

  @override
  String get labelCodeScanActionSms => 'Send message';

  @override
  String get labelCodeScanActionMap => 'Show on map';

  @override
  String get labelCodeScanActionCopyWifiPassword => 'Copy password';

  @override
  String get labelCodeScanActionConnectWifi => 'Connect';

  @override
  String get labelCodeScanActionSaveToNotes => 'Save to notes';

  @override
  String get bodyCodeScanBlockedScheme =>
      'The app does not open this kind of address';

  @override
  String get bodyCodeScanBlockedMalformed => 'This address could not be read';

  @override
  String get bodyCodeScanBlockedIncompleteWifi =>
      'This Wi-Fi code is missing the network name or the password';

  @override
  String get bodyCodeScanBlockedTooLong => 'This code is too long to use';

  @override
  String get labelCodeScanCopied => 'Copied';

  @override
  String get labelCodeScanPasswordCopied => 'Password copied';

  @override
  String get labelCodeScanSavedToNotes => 'Saved to notes';

  @override
  String get errorCodeScanOpenFailed => 'No app on this device can open it';

  @override
  String get bodyCodeScanWifiSuggested =>
      'The network was offered to Android. Pick it in the Wi-Fi settings.';

  @override
  String get bodyCodeScanWifiManual =>
      'Open the Wi-Fi settings and pick the network yourself.';

  @override
  String bodyCodeScanWifiSecurity(String security) {
    return 'Security: $security';
  }

  @override
  String get labelCodeScanWifiHidden => 'Hidden network';

  @override
  String get labelCodeScanWifiOpen => 'Open network';

  @override
  String get titleOcrOpen => 'Extract text';

  @override
  String get titleOcr => 'Text in this picture';

  @override
  String get labelOcrReading => 'Reading the text';

  @override
  String get helpOcrSlowHint => 'A large photo can take a few seconds.';

  @override
  String get labelOcrLanguage => 'Language';

  @override
  String get labelOcrLanguageEnglish => 'English';

  @override
  String get labelOcrLanguageMalayalam => 'Malayalam';

  @override
  String get bodyOcrLanguageBoth => 'English and Malayalam';

  @override
  String get bodyOcrNoText => 'No text was found in this picture';

  @override
  String get actionOcrCopyAll => 'Copy all';

  @override
  String get labelOcrCopied => 'Text copied';

  @override
  String get labelOcrSaveToNotes => 'Save to notes';

  @override
  String get labelOcrSavedToNotes => 'Saved to notes';

  @override
  String get actionOcrReadAgain => 'Read again';

  @override
  String bodyOcrWordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: '1 word',
    );
    return '$_temp0';
  }

  @override
  String get bodyOcrFailedUnreadable => 'This picture could not be opened';

  @override
  String get bodyOcrFailedTooLarge => 'This picture is too large to read';

  @override
  String get bodyOcrFailedMissingData =>
      'The language files are missing from this build';

  @override
  String get bodyOcrFailedTimeout => 'Reading took too long and was stopped';

  @override
  String get bodyOcrFailedEngine => 'The text could not be read';

  @override
  String get titleNotesOpen => 'Notes';

  @override
  String get titleNotes => 'Notes';

  @override
  String get tabNotesWrite => 'Write';

  @override
  String get tabNotesPreview => 'Preview';

  @override
  String get helpNotesHint =>
      'Write a note about this item. Markdown is supported.';

  @override
  String get emptyNotes => 'No note yet';

  @override
  String get tooltipNotesSave => 'Save';

  @override
  String get labelNotesSaved => 'Note saved';

  @override
  String get errorNotesSaveFailed => 'The note could not be saved';

  @override
  String get tooltipNotesDelete => 'Delete note';

  @override
  String get titleNotesDelete => 'Delete this note?';

  @override
  String get bodyNotesDelete =>
      'The note will be removed. The file is not changed.';

  @override
  String get labelNotesDeleted => 'Note deleted';

  @override
  String get actionNotesCancel => 'Cancel';

  @override
  String bodyNotesCharacterCount(int used, int total) {
    return '$used of $total characters';
  }

  @override
  String get bodyNotesTooLong => 'This note is too long to save';

  @override
  String get titleNotesDiscard => 'Leave unsaved?';

  @override
  String get bodyNotesDiscard => 'Your changes to this note will be lost.';

  @override
  String get actionNotesDiscardLeave => 'Leave';

  @override
  String get actionNotesDiscardKeep => 'Keep writing';

  @override
  String get bodyNotesLinkBlocked => 'The app does not open this kind of link';

  @override
  String get titleNotesDetailsLabel => 'Note';

  @override
  String get labelNotesAddFromDetails => 'Add a note';

  @override
  String get titlePdfImagesOpen => 'Images from PDF';

  @override
  String get titlePdfImages => 'Images in a PDF';

  @override
  String get actionPdfImagesPick => 'Choose a PDF';

  @override
  String get tooltipPdfImagesChooseAnother => 'Choose another PDF';

  @override
  String get labelPdfImagesReading => 'Reading the PDF';

  @override
  String get titlePdfImagesEmpty => 'No PDF chosen yet';

  @override
  String get bodyPdfImagesEmpty =>
      'Pick a PDF and the app will list the pictures inside it. The PDF itself is never changed.';

  @override
  String get bodyPdfImagesNone => 'This PDF holds no pictures';

  @override
  String bodyPdfImagesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pictures found',
      one: '1 picture found',
    );
    return '$_temp0';
  }

  @override
  String bodyPdfImagesSkippedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count could not be read',
      one: '1 could not be read',
    );
    return '$_temp0';
  }

  @override
  String get labelPdfImagesSave => 'Save selected';

  @override
  String get labelPdfImagesSaving => 'Saving';

  @override
  String bodyPdfImagesSavedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pictures saved to the gallery',
      one: '1 picture saved to the gallery',
    );
    return '$_temp0';
  }

  @override
  String bodyPdfImagesSaveFailedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count could not be saved',
      one: '1 could not be saved',
    );
    return '$_temp0';
  }

  @override
  String get actionPdfImagesSelectAll => 'Select all';

  @override
  String get labelPdfImagesClearSelection => 'Clear';

  @override
  String get bodyPdfImagesNothingSelected =>
      'Tick at least one picture to save';

  @override
  String get bodyPdfImagesTruncated =>
      'Only the first pictures were read, because this PDF holds a great many.';

  @override
  String get bodyPdfImagesFallbackDirectory =>
      'Saved to the app folder, because the gallery could not be written to';

  @override
  String bodyPdfImageSize(int width, int height) {
    return '$width by $height';
  }

  @override
  String get bodyPdfRefusedNotPdf => 'This file is not a PDF';

  @override
  String get bodyPdfRefusedEncrypted =>
      'This PDF is password protected, so it cannot be opened';

  @override
  String get bodyPdfRefusedTooLarge => 'This PDF is too large to open';

  @override
  String get bodyPdfRefusedUnreadable => 'This PDF could not be read';

  @override
  String get bodyPdfSkipUnsupportedFilter =>
      'Compressed in a way the app cannot read';

  @override
  String get bodyPdfSkipUnsupportedColor =>
      'Uses a colour space the app cannot read';

  @override
  String get bodyPdfSkipUnsupportedDepth =>
      'Uses a colour depth the app cannot read';

  @override
  String get bodyPdfSkipTooLarge => 'Too large to pull out';

  @override
  String get bodyPdfSkipMalformed => 'The picture data is incomplete';

  @override
  String get errorPdfSkipDecodeFailed =>
      'The picture could not be decompressed';

  @override
  String get titleSettingsAppearance => 'Appearance';

  @override
  String get titleSettingsLanguage => 'Language';

  @override
  String get titleSettingsSafety => 'Safety';

  @override
  String get titleSettingsPrivacy => 'Privacy';

  @override
  String get titleSettingsDeveloper => 'Developer';

  @override
  String get titleLanguageSystem => 'System default';

  @override
  String get titleLanguageEnglish => 'English';

  @override
  String get titleLanguageMalayalam => 'മലയാളം';

  @override
  String get descLanguageSubtitle =>
      'The app changes language at once. No restart is needed.';

  @override
  String get labelGridDensity => 'Grid density';

  @override
  String get descGridDensitySubtitle =>
      'How many photos fit across the timeline. Pinching the grid changes it too.';

  @override
  String labelGridDensityValue(int count) {
    return '$count per row';
  }

  @override
  String get titleShowFlashbacks => 'Show memories';

  @override
  String get descShowFlashbacksSubtitle =>
      'A row of photos from this day in past years, at the top of the timeline.';

  @override
  String get titleConfirmDestructive => 'Ask before deleting';

  @override
  String get descConfirmDestructiveSubtitle =>
      'Ask one more time before a delete or an overwrite. Some warnings always appear, whatever this is set to.';

  @override
  String get titlePrivacyNoServer => 'No remote server';

  @override
  String get bodyPrivacyNoServer =>
      'Your photos, tags and notes stay on this phone. Nothing is uploaded, and there is no account. Internet access is used only by the transfer screen, to reach another phone on your own Wi-Fi.';

  @override
  String bodyAboutBuild(String build) {
    return 'Build $build';
  }

  @override
  String get titleAboutBuildDate => 'Build date';

  @override
  String get errorAboutMailFailed =>
      'No app on this phone can open that address.';

  @override
  String get descVaultSettingsOpenSubtitle => 'Lock timing, PIN and shredding';

  @override
  String get descBackupOpenSubtitle => 'Password-protected backup and restore';

  @override
  String get titleSettingsReset => 'Reset settings';

  @override
  String get bodySettingsReset =>
      'Put every setting on this screen back to how it started. Your photos, tags, albums and vault are not touched.';

  @override
  String get bodySettingsResetDone => 'Settings put back to the defaults.';

  @override
  String get actionSettingsCancel => 'Cancel';

  @override
  String get actionSettingsResetConfirm => 'Reset';

  @override
  String get helpSettings => 'Help & Guides';

  @override
  String get descSettingsHelpSubtitle =>
      'Explore guides, pro-tips and offline guarantees for every feature';

  @override
  String get labelSettingsAbout => 'About';

  @override
  String get helpOverview => 'Overview';

  @override
  String get helpHowToUse => 'How to use';

  @override
  String get helpTips => 'Tips & shortcuts';

  @override
  String get helpPrivacy => 'Privacy & offline guarantee';

  @override
  String get helpBadgeOffline => '100% Offline';

  @override
  String get helpBadgeEncrypted => 'Hardware Encrypted';

  @override
  String get helpBadgeLocal => 'Local Wi-Fi Only';

  @override
  String get helpBadgeSafe => 'Non-Destructive';

  @override
  String get helpTopicTimelineTitle => 'Timeline & Memories';

  @override
  String get helpTopicTimelineSummary =>
      'Browse photos by date, pinch to change grid size, and view flashbacks.';

  @override
  String get helpTopicTimelineOverview =>
      'The timeline organizes all your indexed photos and videos in reverse chronological order with date headers. It includes an \'On This Day\' flashback carousel showing photos from today in past years.';

  @override
  String get helpTopicTimelineSteps =>
      '• Pinch in or out to dynamically switch between 1 and 5 columns.\n• Drag the floating date scrubber on the right to jump quickly through months and years.\n• Tap any photo or video to open it in high resolution.';

  @override
  String get helpTopicTimelineTips =>
      '• Long-press any photo to enter multi-selection mode for batch actions.\n• You can toggle flashback memories on or off in Settings.';

  @override
  String get helpTopicTimelinePrivacy =>
      'All timeline grouping and date indexing happen strictly on device using local SQLite. No remote server is ever contacted.';

  @override
  String get helpTopicViewerTitle => 'Fullscreen Viewer & Video Player';

  @override
  String get helpTopicViewerSummary =>
      'High-resolution viewer with gestures, EXIF details, and hardware video playback.';

  @override
  String get helpTopicViewerOverview =>
      'View photos and videos with smooth hardware acceleration. Swipe through your timeline seamlessly with responsive gesture controls.';

  @override
  String get helpTopicViewerSteps =>
      '• Double-tap or pinch to zoom into fine details.\n• Swipe down to dismiss and return to the timeline.\n• Swipe up to view the EXIF metadata drawer (camera, exposure, resolution, location).\n• While watching video: swipe up/down on left for brightness, on right for volume, or swipe horizontally to seek.';

  @override
  String get helpTopicViewerTips =>
      '• Use the video controls to adjust playback speed (0.25x to 2.0x), step frame-by-frame, or repeat video in a loop.\n• Tap the overflow menu for quick access to editing, converting, scanning, and notes.';

  @override
  String get helpTopicViewerPrivacy =>
      'EXIF metadata is parsed and cached locally in SQLite. Video decoding is hardware-accelerated without any network streaming components.';

  @override
  String get helpTopicEditorTitle => 'Photo Editor & Markup';

  @override
  String get helpTopicEditorSummary =>
      'Crop, rotate, adjust colors, apply filters, doodle markup, and redact private areas.';

  @override
  String get helpTopicEditorOverview =>
      'A full-featured non-destructive photo editor with transformations, color adjustments, artistic filters, freehand markup, privacy redaction, and watermarking.';

  @override
  String get helpTopicEditorSteps =>
      '• Open any photo and tap the Edit icon in the toolbar.\n• Transform: Crop with standard aspect ratios, rotate quarter turns, flip, or straighten.\n• Adjust: Fine-tune exposure, contrast, highlights, shadows, warmth, and RGB curves.\n• Markup & Redact: Draw shapes, add text, or redact sensitive areas using Gaussian blur, pixelation, or blackout.\n• Tap Save to export.';

  @override
  String get helpTopicEditorTips =>
      '• Privacy redactions permanently replace underlying pixels in the exported image.\n• Full undo and redo history is available throughout the editing session.';

  @override
  String get helpTopicEditorPrivacy =>
      'All image operations are performed completely offline on a background isolate. Edits are saved as a new version beside the original, never overwriting your original photo without consent.';

  @override
  String get helpTopicConverterTitle => 'Format Converter & Compression';

  @override
  String get helpTopicConverterSummary =>
      'Convert formats (JPEG, PNG, WEBP, BMP), compress file sizes, and trim videos.';

  @override
  String get helpTopicConverterOverview =>
      'Convert photos between popular image formats, compress file sizes with real-time size estimation, extract still frames from video, convert video clips to GIF, and trim videos losslessly.';

  @override
  String get helpTopicConverterSteps =>
      '• Select Convert from the viewer overflow menu.\n• Choose target format (JPEG, PNG, WEBP, BMP) and adjust the quality slider.\n• Set resize mode (percentage, longest side, or custom dimensions) if desired.\n• Tap Convert to generate the optimized file.';

  @override
  String get helpTopicConverterTips =>
      '• In Video Tools: Use lossless trimming to cut sections without re-encoding or quality loss.\n• Create animated GIFs from video clips with custom framerate and loop settings.';

  @override
  String get helpTopicConverterPrivacy =>
      'All image and video conversions take place entirely on-device with zero network transmission. Results are saved as new files.';

  @override
  String get helpTopicPdfTitle => 'PDF Export & Image Extraction';

  @override
  String get helpTopicPdfSummary =>
      'Export multi-image PDF documents and extract embedded pictures from PDFs offline.';

  @override
  String get helpTopicPdfOverview =>
      'Create professional PDF documents from selected photos with custom layouts, or extract high-quality images embedded inside PDF documents.';

  @override
  String get helpTopicPdfSteps =>
      '• PDF Export: Select photos, choose page size (A4, Letter), orientation, margins, and tap Export.\n• PDF Image Extract: Open the tool from the timeline menu, pick a PDF file, review detected pictures, and tap Save to extract them to your gallery.';

  @override
  String get helpTopicPdfTips =>
      '• Reorder photos before PDF export to control page sequence.\n• The PDF extractor walks file objects directly, working even if the PDF\'s cross-reference table is damaged.';

  @override
  String get helpTopicPdfPrivacy =>
      'PDF generation and extraction are executed 100% offline using an app-private sandbox. No PDF data is ever uploaded to any cloud service.';

  @override
  String get helpTopicSearchTitle => 'Search & Tags';

  @override
  String get helpTopicSearchSummary =>
      'Instant SQLite FTS5 search with query filters and 12-color tag management.';

  @override
  String get helpTopicSearchOverview =>
      'Locate photos and videos instantly using full-text search across titles, notes, camera models, and tags, with prefix operators and multi-criteria filters.';

  @override
  String get helpTopicSearchSteps =>
      '• Tap the Search icon on the timeline.\n• Type any search keywords, or use prefixes: \'tag:nature\', \'type:video\', \'camera:sony\', \'place:kochi\', \'before:2024-01-01\'.\n• Tap the Filter icon to combine date range, media type, favorites, and size filters.\n• To manage tags, visit the Tags screen from the timeline menu.';

  @override
  String get helpTopicSearchTips =>
      '• Create custom tags with 12 distinct Material colors.\n• Tags update the search index immediately, making photos findable in milliseconds.';

  @override
  String get helpTopicSearchPrivacy =>
      'Search indexes are stored locally in SQLite with FTS5. Your search queries and history remain strictly on your device.';

  @override
  String get helpTopicAlbumsTitle => 'Albums & Smart Albums';

  @override
  String get helpTopicAlbumsSummary =>
      'Organize into virtual albums, browse device folders, and view smart auto-albums.';

  @override
  String get helpTopicAlbumsOverview =>
      'Manage your collection with user-created virtual albums, physical device folder browsing, and smart auto-albums that organize media automatically.';

  @override
  String get helpTopicAlbumsSteps =>
      '• Tap Albums on the timeline app bar.\n• Virtual Albums: Tap \'+\' to create an album, add media, reorder items, or set a custom cover photo.\n• Smart Albums: Automatically gathers Favorites, Videos, GIFs, RAW photos, Panoramas, and Recently Added.\n• Device Folders: Browse physical folders on your storage (Camera, Screenshots, WhatsApp, Downloads).';

  @override
  String get helpTopicAlbumsTips =>
      '• Pin favorite albums to keep them at the top of the list.\n• Virtual albums do not duplicate media files on disk, saving storage space.';

  @override
  String get helpTopicAlbumsPrivacy =>
      'Album memberships and metadata are stored in the local database. Device folder scanning adheres to Android scoped storage.';

  @override
  String get helpTopicCleanerTitle => 'Duplicate Cleaner';

  @override
  String get helpTopicCleanerSummary =>
      'Detect exact and visually similar duplicates with side-by-side comparison.';

  @override
  String get helpTopicCleanerOverview =>
      'Free up storage by identifying exact duplicate files (via SHA-256 hash) and visually similar photos (via perceptual pHash and dHash).';

  @override
  String get helpTopicCleanerSteps =>
      '• Open Duplicate Cleaner from the timeline menu.\n• Tap Scan to analyze your library.\n• Review duplicate groups and tap any group for side-by-side comparison.\n• Use \'Keep Best Photo\' to automatically pick the highest resolution, sharpest image and move others to trash.';

  @override
  String get helpTopicCleanerTips =>
      '• Perceptual hashing finds photos taken in rapid succession or with minor edits.\n• No file is ever deleted without your confirmation.';

  @override
  String get helpTopicCleanerPrivacy =>
      'Hashing runs completely locally. Downsampled 32x32 previews are used for DCT computation and cleared immediately.';

  @override
  String get helpTopicVaultTitle => 'Secure Private Vault';

  @override
  String get helpTopicVaultSummary =>
      'Hardware-backed AES-256-GCM encryption, biometric & PIN authentication, and shredding.';

  @override
  String get helpTopicVaultOverview =>
      'Protect sensitive photos and videos in an encrypted vault. Payloads are encrypted with a 256-bit key protected by the Android Keystore, with biometric unlock and screenshot prevention.';

  @override
  String get helpTopicVaultSteps =>
      '• Tap the Vault icon on the timeline to unlock or configure your vault.\n• Set a master PIN (and enable Biometrics for convenient access).\n• Import media from the timeline or viewer. Choose whether to securely shred the original file.\n• View encrypted photos and videos safely inside the vault.';

  @override
  String get helpTopicVaultTips =>
      '• Screenshot protection (FLAG_SECURE) is active while inside the vault.\n• The vault locks automatically when the app is switched to the background or after an idle timeout.';

  @override
  String get helpTopicVaultPrivacy =>
      'Decrypted data is held in memory only. Keys never leave the Android Keystore hardware module, and no plaintext files are left on disk.';

  @override
  String get helpTopicSyncTitle => 'Local Wi-Fi Transfer';

  @override
  String get helpTopicSyncSummary =>
      'Direct peer-to-peer transfer between devices on the same Wi-Fi with zero internet.';

  @override
  String get helpTopicSyncOverview =>
      'Transfer photos and videos directly between two phones on the same local Wi-Fi router. Connections are end-to-end encrypted with an authenticated handshake.';

  @override
  String get helpTopicSyncSteps =>
      '• On receiving device: Open Transfer > Receive to show the QR pairing code.\n• On sending device: Open Transfer > Send and scan the code (or enter the 6-character code).\n• Select photos or albums to transfer and start the transfer.\n• Received files are verified by SHA-256 digest and published directly to your gallery.';

  @override
  String get helpTopicSyncTips =>
      '• No internet access or router configuration is needed; devices connect directly over local IP addresses.\n• The transfer socket binds only while the transfer screen is open and shuts down immediately when you leave.';

  @override
  String get helpTopicSyncPrivacy =>
      'Connections to external or public IP addresses are strictly blocked by LocalAddressRules. Zero tracking, zero telemetry, zero cloud intermediary.';

  @override
  String get helpTopicBackupTitle => 'Backup & Restore';

  @override
  String get helpTopicBackupSummary =>
      'Create password-protected encrypted .gbak archives and restore safely.';

  @override
  String get helpTopicBackupOverview =>
      'Safeguard your tags, album structures, media notes, and user metadata in an encrypted GBAK backup archive protected by AES-256-GCM.';

  @override
  String get helpTopicBackupSteps =>
      '• Tap Backup from the timeline menu.\n• Create Backup: Enter a strong password and save the backup file via Android\'s document picker.\n• Restore: Select a previously exported .gbak file, enter your password, inspect the preview summary, and apply.';

  @override
  String get helpTopicBackupTips =>
      '• The restore process is non-destructive: it fills gaps and merges tags and albums without overwriting existing data.\n• Keep a safe record of your backup password; without it, the encrypted archive cannot be recovered.';

  @override
  String get helpTopicBackupPrivacy =>
      'Backup files are encrypted using PBKDF2-derived keys and AES-256-GCM. Backups are stored wherever you choose on your device or SD card.';

  @override
  String get helpTopicScannerTitle => 'QR Scanner & OCR';

  @override
  String get helpTopicScannerSummary =>
      'Scan QR/barcodes from photos with safe schemes, and extract text with offline OCR.';

  @override
  String get helpTopicScannerOverview =>
      'Analyze existing photos to scan QR codes and barcodes, or run offline Tesseract optical character recognition to extract English and Malayalam text.';

  @override
  String get helpTopicScannerSteps =>
      '• Open a photo in the viewer and select \'Scan code\' or \'Extract text\' from the menu.\n• Scanned codes: View detected URL, Wi-Fi credentials, or text. Safe URL schemes (http, https, tel, mailto, sms, geo) can be opened with confirmation.\n• Extracted text: View recognized text, copy it to clipboard, or append it directly to the media item\'s notes.';

  @override
  String get helpTopicScannerTips =>
      '• Optical character recognition uses bundled offline language models (English and Malayalam); no internet connection is required.\n• Wi-Fi codes allow copying network credentials securely or suggesting network connection without silent joining.';

  @override
  String get helpTopicScannerPrivacy =>
      'All barcode decoding and OCR processing are executed locally on your device. Untrusted QR payloads are validated before launching external apps.';

  @override
  String get titleSettingsDefaultApp => 'Default Gallery App';

  @override
  String get descSettingsDefaultAppSubtitle =>
      'Set as default app for viewing photos and videos';

  @override
  String get titleDefaultAppDialog => 'Set Default Gallery';

  @override
  String get bodyDefaultAppDialog =>
      'To make this your default gallery:\n\n1. Open any photo or video on your device (e.g. from Files, Downloads, or messages).\n2. Choose SreerajP Image Video Gallery and tap \'Always\'.\n\nIf another app already opens your photos, first clear its default: Android Settings → Apps → that app → Open by default.';

  @override
  String get titleTrash => 'Trash';

  @override
  String get emptyTrash => 'Trash is empty';

  @override
  String get descTrashEmptySubtitle =>
      'Items you delete are kept here until you empty the trash.';

  @override
  String get tooltipTrashEmptyAction => 'Empty trash';

  @override
  String get titleTrashEmptyConfirm => 'Empty trash?';

  @override
  String get bodyTrashEmptyConfirm =>
      'This will permanently delete all trashed items from your device storage. This action cannot be undone.';

  @override
  String get titleTrashDeletePermanentlyAction => 'Delete permanently';

  @override
  String get titleTrashDeletePermanentlyConfirm => 'Delete permanently?';

  @override
  String get bodyTrashDeletePermanentlyConfirm =>
      'This item will be permanently deleted from your device storage. This action cannot be undone.';

  @override
  String get bodyTrashDeletedPermanentlySnackbar => 'Item permanently deleted';

  @override
  String get actionTrashRestore => 'Restore';

  @override
  String get tooltipTrashRestoreAllAction => 'Restore all';

  @override
  String get bodyTrashRestoreAllConfirm =>
      'Every item in the trash will be moved back to your library.';

  @override
  String get bodyTrashRestoredSnackbar => 'Restored from trash';

  @override
  String get bodyTrashEmptiedSnackbar => 'Trash emptied';

  @override
  String bodyTrashItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items in trash',
      one: '1 item in trash',
    );
    return '$_temp0';
  }

  @override
  String get descSettingsAppearanceSubtitle => 'Theme, grid density, memories';

  @override
  String get descSettingsLanguageSubtitle =>
      'System, English, Malayalam, Sanskrit';

  @override
  String get descSettingsSafetySubtitle =>
      'Confirmation before destructive actions';

  @override
  String get descSettingsDefaultAppCardSubtitle => 'Set as default gallery app';

  @override
  String get descSettingsPrivacySubtitle => 'Hide content and vault';

  @override
  String get descSettingsHelpCardSubtitle =>
      'Guides and privacy guarantees for every feature';

  @override
  String get descSettingsAboutSubtitle => 'Version, author and licence';

  @override
  String get descSettingsDeveloperSubtitle => 'Media scanner tools';

  @override
  String get titleViewerTrashConfirm => 'Move to trash?';

  @override
  String get bodyViewerTrashConfirm =>
      'This item will be moved to the trash. You can restore it anytime from the Trash album.';

  @override
  String get bodyViewerTrashSuccess => 'Moved to trash';

  @override
  String get actionViewerTrashUndo => 'Undo';

  @override
  String get titleComparePhotos => 'A/B Comparison';

  @override
  String get labelCompareModeSplit => 'Split View';

  @override
  String get labelCompareModeCurtain => 'Sliding Curtain';

  @override
  String get labelCompareSplitHorizontal => 'Side by Side';

  @override
  String get labelCompareSplitVertical => 'Top and Bottom';

  @override
  String get bodyCompareSyncLocked => 'Pan & Zoom Locked';

  @override
  String get bodyCompareSyncUnlocked => 'Independent Pan & Zoom';

  @override
  String get tooltipCompareSwap => 'Swap Photos';

  @override
  String get tooltipCompareResetZoom => 'Reset Zoom';

  @override
  String get tooltipCompareDetails => 'Compare Details';

  @override
  String get labelComparePhotoA => 'Photo A';

  @override
  String get labelComparePhotoB => 'Photo B';

  @override
  String get titleCompareWithPrevious => 'Compare previous';

  @override
  String get titleCompareWithNext => 'Compare next';

  @override
  String get titleCompareChooseFromGallery => 'Pick from gallery';

  @override
  String get tooltipCompare => 'Compare photos';

  @override
  String get bodyCompareSelectSecondPhoto => 'Select a photo to compare with';

  @override
  String get labelCompareDimensions => 'Dimensions';

  @override
  String get labelCompareFileSize => 'File Size';

  @override
  String get labelCompareDateTaken => 'Date Taken';

  @override
  String get labelCompareCamera => 'Camera';

  @override
  String get labelCompareIso => 'ISO';

  @override
  String get labelCompareAperture => 'Aperture';

  @override
  String get labelCompareShutterSpeed => 'Shutter Speed';

  @override
  String get labelCompareFocalLength => 'Focal Length';

  @override
  String get tabTimeline => 'Timeline';

  @override
  String get tabFolders => 'Folders';

  @override
  String get tabAlbums => 'Albums';

  @override
  String get titleFolders => 'Folders';

  @override
  String get emptyFolders => 'No folders found';

  @override
  String get bodyFoldersEmpty =>
      'Pull down to scan for photos and videos on your device.';

  @override
  String get tooltipPrivacyScrubberTitle => 'Privacy Scrubber';

  @override
  String get descPrivacyScrubberSubtitle =>
      'Strip sensitive EXIF metadata and fuzz GPS coordinates before sharing';

  @override
  String get titlePrivacyScrubberMenu => 'Privacy Scrubber';

  @override
  String get titlePrivacyCard => 'Media Privacy & EXIF';

  @override
  String get bodyPrivacyCard =>
      'Protect your privacy by stripping GPS location, camera serial numbers, and device identifiers before sharing.';

  @override
  String get bodyPrivacyOpenScrubber => 'Open Privacy Controls';

  @override
  String get labelPrivacyTabStripper => 'EXIF Stripper';

  @override
  String get labelPrivacyTabGeofence => 'GPS Geofence Shifter';

  @override
  String get actionPrivacyStripAndShare => 'Strip & Share';

  @override
  String get actionPrivacySaveSanitized => 'Save Clean Copy';

  @override
  String get titlePrivacyGranular => 'Choose What to Strip';

  @override
  String get labelPrivacyStripAll => 'Strip All';

  @override
  String get labelPrivacyCustom => 'Custom';

  @override
  String get titlePrivacyOptionGps => 'GPS Location';

  @override
  String get titlePrivacyOptionSerials => 'Serial Numbers';

  @override
  String get titlePrivacyOptionTimestamps => 'Capture Dates';

  @override
  String get titlePrivacyOptionAuthor => 'Author & Software';

  @override
  String get bodyPrivacyErrorReadingFile =>
      'Unable to read image data for privacy processing';

  @override
  String get titlePrivacyShare => 'Share Clean Copy';

  @override
  String get errorPrivacyShareFailed => 'Sharing could not be initiated';

  @override
  String get errorPrivacyProcess => 'An error occurred while sanitizing media';

  @override
  String get bodyPrivacySavedToGallery => 'Sanitized copy saved to gallery';

  @override
  String get errorPrivacySaveFailed => 'Failed to save sanitized image';

  @override
  String get bodyPrivacyNoLocation =>
      'No embedded GPS location found in this photo';

  @override
  String get bodyGeofenceOffsetDistance => 'Shift Distance Offset';

  @override
  String get tooltipGeofenceReroll => 'Reroll random shift';

  @override
  String get labelGeofenceRandomPreset => 'Random (2–5 km)';

  @override
  String bodyGeofenceShiftSummary(String summary) {
    return 'Shifted $summary';
  }

  @override
  String bodyGeofenceFuzzedCoordinates(String lat, String lon) {
    return 'Shifted to $lat, $lon';
  }

  @override
  String get descGeofenceExplanation =>
      'Adds an offset within 2–5 km to preserve general regional travel context while hiding exact residential street coordinates.';

  @override
  String get titleGeofenceShare => 'Share Fuzzed Photo';

  @override
  String get actionGeofenceShare => 'Fuzz & Share';

  @override
  String get actionGeofenceSave => 'Save Fuzzed Copy';

  @override
  String get bodyGeofenceSavedToGallery => 'Geofuzzed copy saved to gallery';

  @override
  String get labelGeofenceNoCoordinates => 'No Location Found';

  @override
  String get bodyGeofenceNoCoordinates =>
      'This media item does not have embedded GPS coordinates to shift.';

  @override
  String get bodyPrivacyAuditSensitiveDetected => 'Sensitive Metadata Detected';

  @override
  String get bodyPrivacyAuditClean => 'No Sensitive Metadata Detected';

  @override
  String bodyPrivacyAuditSensitiveDetails(String gps, String camera) {
    return 'Contains $gps $camera';
  }

  @override
  String get labelPrivacyAuditGps => 'GPS Coordinates';

  @override
  String get labelPrivacyAuditCamera => 'Device Identifiers';

  @override
  String get bodyPrivacyAuditCleanDetails =>
      'This file does not contain embedded location or camera serial identifiers.';

  @override
  String get titleForensicInspector => 'Lens & Sensor Data';

  @override
  String get descForensicInspectorSubtitle =>
      'Deep technical optical and hardware forensic insights';

  @override
  String get actionForensicInspector => 'Inspect Lens Data';

  @override
  String get helpForensicInspectorQuickHint =>
      'Sensor crop factor, 35mm equivalent, shutter actuation, exposure bias';

  @override
  String get bodyForensicNoData =>
      'No forensic lens or sensor metadata found in this item.';

  @override
  String get bodyForensicSectionSensorOptics =>
      'Sensor & Optical Characteristics';

  @override
  String get bodyForensicSectionMechanicsColor =>
      'Mechanical Actuations & Color Space';

  @override
  String get bodyForensicSectionHardwareIdentity =>
      'Hardware & Lens Serial Identity';

  @override
  String get labelForensicSensorFormat => 'Sensor Format';

  @override
  String get labelForensicCropFactor => 'Crop Factor';

  @override
  String get labelForensicFocal35mm => '35mm Equivalent';

  @override
  String get labelForensicPhysicalFocalLength => 'Real Focal Length';

  @override
  String get labelForensicHyperfocalDistance => 'Hyperfocal Distance';

  @override
  String get labelForensicExposureBias => 'Exposure Bias (EV)';

  @override
  String get labelForensicShutterActuations => 'Shutter Releases';

  @override
  String get bodyForensicShutterNotReported =>
      'Electronic shutter / Not reported';

  @override
  String get labelForensicColorProfile => 'Color Profile';

  @override
  String get labelForensicExposureProgram => 'Exposure Program';

  @override
  String get labelForensicMeteringMode => 'Metering Mode';

  @override
  String get labelForensicSensingMethod => 'Sensing Method';

  @override
  String get labelForensicSceneCaptureType => 'Scene Capture Type';

  @override
  String get labelForensicFlashStatus => 'Flash Status';

  @override
  String get labelForensicCameraSerial => 'Camera Serial Number';

  @override
  String get labelForensicLensModel => 'Lens Model';

  @override
  String get labelForensicLensSpecification => 'Lens Specification';

  @override
  String get labelForensicLensSerial => 'Lens Serial Number';

  @override
  String get bodyForensicSerialNotEmbedded => 'Not embedded in headers';

  @override
  String get tooltipShowPassword => 'Show password';

  @override
  String get tooltipHidePassword => 'Hide password';

  @override
  String labelDistanceKm(String distance) {
    return '$distance km';
  }

  @override
  String labelCompareBadge(String photo, String name) {
    return '$photo: $name';
  }

  @override
  String get aboutDetailAuthor => 'Author';

  @override
  String get aboutDetailLicense => 'License';

  @override
  String get aboutDetailIdeUsed => 'IDE used';

  @override
  String get aboutDetailAiUsed => 'AI used';

  @override
  String get aboutDetailStorageModel => 'Storage model';

  @override
  String get aboutDetailNetworkPolicy => 'Network policy';

  @override
  String get aboutDetailSecurity => 'Security';

  @override
  String get aboutDetailLanguages => 'Languages';

  @override
  String madeWithLove(String heart) {
    return 'Made with $heart from India';
  }

  @override
  String get madeWithLoveA11y => 'Made with love from India';

  @override
  String get titleLanguageSanskrit => 'संस्कृतम्';

  @override
  String bodyUnitBytes(String value) {
    return '$value B';
  }

  @override
  String bodyUnitKilobytes(String value) {
    return '$value KB';
  }

  @override
  String bodyUnitMegabytes(String value) {
    return '$value MB';
  }

  @override
  String bodyUnitGigabytes(String value) {
    return '$value GB';
  }

  @override
  String bodyUnitTerabytes(String value) {
    return '$value TB';
  }

  @override
  String bodyUnitMillimetres(String value) {
    return '$value mm';
  }

  @override
  String bodyUnitMetres(String value) {
    return '$value m';
  }

  @override
  String bodyUnitIsoValue(String value) {
    return 'ISO $value';
  }

  @override
  String bodyUnitCropFactor(String value) {
    return '${value}x';
  }

  @override
  String bodyForensicShutterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count releases',
      one: '1 release',
    );
    return '$_temp0';
  }

  @override
  String bodyTransferBytesProgress(String done, String total) {
    return '$done of $total';
  }

  @override
  String bodyPdfImageFormatAndSize(String format, String size) {
    return '$format · $size';
  }

  @override
  String get labelColorRed => 'Red';

  @override
  String get labelColorPink => 'Pink';

  @override
  String get labelColorPurple => 'Purple';

  @override
  String get labelColorDeepPurple => 'Deep purple';

  @override
  String get labelColorIndigo => 'Indigo';

  @override
  String get labelColorBlue => 'Blue';

  @override
  String get labelColorTeal => 'Teal';

  @override
  String get labelColorGreen => 'Green';

  @override
  String get labelColorLightGreen => 'Light green';

  @override
  String get labelColorAmber => 'Amber';

  @override
  String get labelColorDeepOrange => 'Deep orange';

  @override
  String get labelColorBrown => 'Brown';

  @override
  String get labelColorYellow => 'Yellow';

  @override
  String get labelColorWhite => 'White';

  @override
  String get labelColorBlack => 'Black';

  @override
  String get labelA11yCropArea => 'Crop area';

  @override
  String bodyA11yCropAreaValue(int left, int top, int width, int height) {
    return 'Left $left%, top $top%, width $width%, height $height%';
  }

  @override
  String get helpA11yCropAreaHint =>
      'Drag the corners, or use the actions to move or resize';

  @override
  String get labelA11yMoveLeft => 'Move left';

  @override
  String get labelA11yMoveRight => 'Move right';

  @override
  String get labelA11yMoveUp => 'Move up';

  @override
  String get labelA11yMoveDown => 'Move down';

  @override
  String get labelA11yMakeSmaller => 'Make smaller';

  @override
  String get labelA11yMakeLarger => 'Make larger';

  @override
  String get labelA11yCurveArea => 'Tone curve';

  @override
  String bodyA11yCurveValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count points',
      one: '1 point',
    );
    return '$_temp0';
  }

  @override
  String get labelA11yMarkupArea => 'Drawing area';

  @override
  String bodyA11yMarkupValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count marks',
      one: '1 mark',
      zero: 'Nothing drawn',
    );
    return '$_temp0';
  }

  @override
  String get helpA11yDrawingNeedsTouchHint =>
      'Drawing needs touch. Use the panel below to change or remove marks.';

  @override
  String get labelA11yRedactionArea => 'Hide area';

  @override
  String bodyA11yRedactionValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count areas hidden',
      one: '1 area hidden',
      zero: 'Nothing hidden',
    );
    return '$_temp0';
  }

  @override
  String get labelA11yMaskArea => 'Mask position';

  @override
  String bodyA11yMaskValue(String shape, int x, int y) {
    return '$shape, centre at $x% across, $y% down';
  }

  @override
  String get helpA11yMaskHint =>
      'Drag the handles, or use the actions to move the mask';

  @override
  String get labelA11yCompareDivider => 'Comparison divider';

  @override
  String bodyA11yPercentValue(int percent) {
    return '$percent%';
  }

  @override
  String get errorOpenWithRefused =>
      'This file can\'t be opened here. Open it from the gallery instead.';

  @override
  String get errorOpenWithFailed =>
      'The file couldn\'t be opened. It may have been moved or deleted.';

  @override
  String get bodyCleanerFailed =>
      'Something went wrong while comparing photos. Try again.';

  @override
  String get aboutDetailEmail => 'Email';

  @override
  String get aboutDetailPrivacyPolicy => 'Privacy policy';

  @override
  String get titleSettingsProtectScreens => 'Hide content';

  @override
  String get descSettingsProtectScreens =>
      'Block screenshots and screen recording, and show a blank card in recent apps, on every screen. The vault is always protected.';

  @override
  String get titleSettingsPermissions => 'Permissions';

  @override
  String get descSettingsPermissionsSubtitle => 'What the app can use, and why';

  @override
  String get labelPermissionsExplicit => 'You allow these';

  @override
  String get labelPermissionsImplicit => 'Granted at install';

  @override
  String get labelPermissionsRemoved => 'Removed on purpose';

  @override
  String get descPermissionsExplicit =>
      'Android asks you before the app can use these. You can change them at any time in Android settings.';

  @override
  String get descPermissionsImplicit =>
      'Android gives these when the app is installed, without asking. None of them gives access to your photos or files.';

  @override
  String get descPermissionsRemoved =>
      'Some libraries the app is built with ask for these. The app removes them, so it never holds them.';

  @override
  String get descPermissionsManage =>
      'To change what you allow, open this app\'s page in Android settings.';

  @override
  String get labelPermPhotosVideos => 'Photos and videos';

  @override
  String get labelPermCamera => 'Camera';

  @override
  String get labelPermBiometric => 'Fingerprint unlock';

  @override
  String get labelPermNetwork => 'Local network';

  @override
  String get labelPermWifiState => 'Wi-Fi details';

  @override
  String get labelPermNetworkState => 'Network state';

  @override
  String get labelPermChangeWifi => 'Wi-Fi suggestions';

  @override
  String get labelPermReceiverPrivate => 'App-private messages';

  @override
  String get labelPermWakeLock => 'Keep phone awake';

  @override
  String get labelPermRecordAudio => 'Record sound';

  @override
  String get labelPermWriteStorage => 'Write to storage';

  @override
  String get descPermPhotosVideos =>
      'Shows the photos and videos on this phone. On Android 14 and up you can allow only the ones you pick.';

  @override
  String get descPermCamera =>
      'Scans the pairing QR code on the transfer screen only. The app never takes a photo.';

  @override
  String get descPermBiometric =>
      'Unlocks the vault with your fingerprint. Your PIN always works too.';

  @override
  String get descPermNetwork =>
      'Used only by the transfer screen, to reach another phone on your own Wi-Fi. The app never goes on the internet.';

  @override
  String get descPermWifiState =>
      'Reads this phone\'s own Wi-Fi address to make the pairing code.';

  @override
  String get descPermNetworkState =>
      'Part of the local transfer set. The app does not use it to go online.';

  @override
  String get descPermChangeWifi =>
      'Offers a Wi-Fi code you scanned to Android. You still choose the network yourself.';

  @override
  String get descPermReceiverPrivate =>
      'Added by an Android library. It keeps the app\'s own internal messages private and gives no access to anything.';

  @override
  String get descPermWakeLock =>
      'The video player asks for it for streaming. The app plays only files on this phone.';

  @override
  String get descPermRecordAudio =>
      'The camera library asks for it. The QR scanner never records sound.';

  @override
  String get descPermWriteStorage =>
      'Android 9 and older only. Lets you delete photos for good, or securely. Asked together with photos access.';

  @override
  String get labelPermAllowed => 'Allowed';

  @override
  String get labelPermSelectedOnly => 'Selected only';

  @override
  String get labelPermNotAllowed => 'Not allowed';

  @override
  String labelPermAndroidFrom(String version) {
    return 'Android $version+';
  }

  @override
  String labelPermAndroidUpTo(String version) {
    return 'Up to Android $version';
  }

  @override
  String get titleVaultFolderMissing => 'Folder not found';

  @override
  String bodyVaultFolderMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count items can\'t go back to their old folder, because that folder no longer exists. Choose a folder for them, or skip them and they stay in the vault.',
      one:
          '1 item can\'t go back to its old folder, because that folder no longer exists. Choose a folder for it, or skip it and it stays in the vault.',
    );
    return '$_temp0';
  }

  @override
  String get actionVaultChooseFolder => 'Choose folder';

  @override
  String get actionVaultSkip => 'Skip';

  @override
  String bodyVaultRestoreSkipped(int done, int skipped) {
    return '$done restored, $skipped stayed in the vault';
  }

  @override
  String bodyVaultRestoreSkippedFailed(int done, int skipped, int failed) {
    return '$done restored, $skipped stayed in the vault, $failed failed';
  }

  @override
  String get titleBatchActionDelete => 'Delete';

  @override
  String titleDeleteChoice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count items?',
      one: 'Delete 1 item?',
    );
    return '$_temp0';
  }

  @override
  String bodyDeleteChoiceTrash(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You can restore them from the trash.',
      one: 'You can restore it from the trash.',
    );
    return '$_temp0';
  }

  @override
  String get bodyDeleteChoicePermanent =>
      'Removed from the device. This cannot be undone.';

  @override
  String get bodyDeleteChoicePermanentSecure =>
      'Written over, then removed from the device. This cannot be undone.';

  @override
  String bodyDeletePermanentlyConfirmCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count items will be deleted from your device for good. This cannot be undone.',
      one:
          '1 item will be deleted from your device for good. This cannot be undone.',
    );
    return '$_temp0';
  }

  @override
  String get bodyDeleteNothingDeleted => 'Nothing was deleted.';

  @override
  String bodyDeletedPermanentlyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items deleted for good.',
      one: '1 item deleted for good.',
    );
    return '$_temp0';
  }

  @override
  String bodySecureDeletedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items securely deleted.',
      one: '1 item securely deleted.',
    );
    return '$_temp0';
  }

  @override
  String bodySecureDeleteNotOverwritten(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count of them could not be written over first.',
      one: '1 of them could not be written over first.',
    );
    return '$_temp0';
  }

  @override
  String bodyDeleteFailedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items could not be deleted.',
      one: '1 item could not be deleted.',
    );
    return '$_temp0';
  }

  @override
  String get titleSecureDelete => 'Secure delete';

  @override
  String get descSecureDeleteSubtitle =>
      'Writes over each file before deleting it, so undelete tools cannot bring it back. Used for permanent deletes and for the trash. Android asks you to allow it first. On flash storage this stops undelete tools, not a lab.';

  @override
  String get bodySecureDeleteVaultNote =>
      'Deleting from the vault is always secure, whatever this switch says.';

  @override
  String bodyBatchTrashSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items moved to trash',
      one: '1 item moved to trash',
    );
    return '$_temp0';
  }
}
