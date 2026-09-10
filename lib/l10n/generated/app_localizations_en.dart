// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SreerajP Gallery';

  @override
  String get devBanner => 'DEV BUILD';

  @override
  String get settings => 'Settings';

  @override
  String get about => 'About';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System Default';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeAmoled => 'AMOLED True Black';

  @override
  String get currentFlavor => 'Current Flavor';

  @override
  String get version => 'Version';

  @override
  String get offlineStatus => '100% Offline (No Internet)';

  @override
  String get permissionRequired => 'Media access needed';

  @override
  String get permissionRequiredBody =>
      'Allow access to your photos and videos so the gallery can show them. Nothing ever leaves your device.';

  @override
  String get grantPermission => 'Allow access';

  @override
  String get openSettings => 'Open settings';

  @override
  String get permissionPartial =>
      'Only selected media is visible. Allow all media to see everything.';

  @override
  String get scanMedia => 'Scan device media';

  @override
  String get scanningMedia => 'Scanning media...';

  @override
  String scanProgress(int scanned, int total) {
    return '$scanned of $total scanned';
  }

  @override
  String scanComplete(int count) {
    return 'Scan complete: $count items indexed';
  }

  @override
  String get scanFailed => 'Media scan failed';

  @override
  String indexedItems(int count) {
    return 'Indexed items: $count';
  }

  @override
  String get noMediaFound => 'No photos or videos found';

  @override
  String get mediaUnavailable => 'Preview unavailable';

  @override
  String get timelineToday => 'Today';

  @override
  String get timelineYesterday => 'Yesterday';

  @override
  String get timelineTitle => 'Timeline';

  @override
  String get noMediaInTimeline => 'Your gallery is empty';

  @override
  String get pullToScan => 'Pull down to scan for new photos and videos.';

  @override
  String get flashbackTitle => 'On This Day';

  @override
  String get flashbackOneYearAgo => '1 year ago';

  @override
  String flashbackYearsAgo(int years) {
    return '$years years ago';
  }

  @override
  String gridColumns(int count) {
    return '$count per row';
  }

  @override
  String get badgeGif => 'GIF';

  @override
  String get badgeRaw => 'RAW';

  @override
  String get badgeHd => 'HD';

  @override
  String badgeVideoDuration(String duration) {
    return 'Video, $duration';
  }

  @override
  String mediaTileLabel(String name, String date) {
    return '$name, $date';
  }

  @override
  String get scrollToDate => 'Scroll to date';

  @override
  String get viewerClose => 'Close';

  @override
  String get viewerRotateLeft => 'Rotate left';

  @override
  String get viewerRotateRight => 'Rotate right';

  @override
  String get viewerAddFavorite => 'Add to favorites';

  @override
  String get viewerRemoveFavorite => 'Remove from favorites';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get frameForward => 'Next frame';

  @override
  String get frameBackward => 'Previous frame';

  @override
  String get skipForward => 'Skip forward 10 seconds';

  @override
  String get skipBackward => 'Skip back 10 seconds';

  @override
  String get loopPlayback => 'Repeat';

  @override
  String get playbackSpeed => 'Playback speed';

  @override
  String get videoCannotPlay => 'This video cannot be played.';

  @override
  String get videoFormatUnsupported =>
      'This device cannot play this video format.';

  @override
  String get detailsTitle => 'Details';

  @override
  String get detailsFileName => 'File name';

  @override
  String get detailsFormat => 'Format';

  @override
  String get detailsSize => 'Size';

  @override
  String get detailsDimensions => 'Dimensions';

  @override
  String get detailsDuration => 'Duration';

  @override
  String get detailsDateTaken => 'Date taken';

  @override
  String get detailsDateModified => 'Last modified';

  @override
  String get detailsFolder => 'Folder';

  @override
  String get detailsCameraSection => 'Camera and metadata';

  @override
  String get detailsNoMetadata => 'No camera metadata was found in this file.';

  @override
  String get detailsCamera => 'Camera';

  @override
  String get detailsLens => 'Lens';

  @override
  String get detailsAperture => 'Aperture';

  @override
  String get detailsShutter => 'Shutter';

  @override
  String get detailsIso => 'ISO';

  @override
  String get detailsFocalLength => 'Focal length';

  @override
  String get detailsFlash => 'Flash';

  @override
  String get detailsWhiteBalance => 'White balance';

  @override
  String get detailsMeteringMode => 'Metering mode';

  @override
  String get detailsColorSpace => 'Color space';

  @override
  String get detailsSoftware => 'Software';

  @override
  String get detailsLocation => 'Location';

  @override
  String get detailsAltitude => 'Altitude';

  @override
  String get editorTitle => 'Edit';

  @override
  String get editorOpen => 'Edit';

  @override
  String get editorSave => 'Save copy';

  @override
  String get editorSaving => 'Saving a copy...';

  @override
  String editorSaved(String fileName) {
    return 'Saved a copy: $fileName';
  }

  @override
  String get editorSaveFailed => 'The copy could not be saved';

  @override
  String get editorOriginalKept => 'Your original photo was not changed';

  @override
  String get editorCannotOpen => 'This photo cannot be edited';

  @override
  String get editorTooLarge => 'This photo is too large to edit on this device';

  @override
  String get editorLoading => 'Preparing the photo...';

  @override
  String get editorPreviewFailed => 'The preview could not be drawn';

  @override
  String get editorUndo => 'Undo';

  @override
  String get editorRedo => 'Redo';

  @override
  String get editorResetAll => 'Reset all';

  @override
  String get editorDiscardTitle => 'Discard changes?';

  @override
  String get editorDiscardMessage =>
      'Your edits have not been saved. Leaving now will lose them.';

  @override
  String get editorDiscard => 'Discard';

  @override
  String get editorKeepEditing => 'Keep editing';

  @override
  String get editorToolCrop => 'Crop';

  @override
  String get editorToolTune => 'Tune';

  @override
  String get editorToolMasks => 'Masks';

  @override
  String get editorToolFilters => 'Filters';

  @override
  String get editorToolMarkup => 'Markup';

  @override
  String get editorToolRedact => 'Hide';

  @override
  String get editorToolWatermark => 'Watermark';

  @override
  String get cropAspectFree => 'Free';

  @override
  String get cropAspectOriginal => 'Original';

  @override
  String get cropAspectSquare => 'Square';

  @override
  String get cropAspect4x3 => '4:3';

  @override
  String get cropAspect3x4 => '3:4';

  @override
  String get cropAspect16x9 => '16:9';

  @override
  String get cropAspect9x16 => '9:16';

  @override
  String get cropAspect3x2 => '3:2';

  @override
  String get cropAspect2x3 => '2:3';

  @override
  String get cropRotateLeft => 'Rotate left';

  @override
  String get cropRotateRight => 'Rotate right';

  @override
  String get cropFlipHorizontal => 'Mirror sideways';

  @override
  String get cropFlipVertical => 'Mirror upside down';

  @override
  String get cropStraighten => 'Straighten';

  @override
  String get cropPerspectiveVertical => 'Vertical tilt';

  @override
  String get cropPerspectiveHorizontal => 'Horizontal tilt';

  @override
  String get cropReset => 'Reset crop';

  @override
  String get toneExposure => 'Exposure';

  @override
  String get toneContrast => 'Contrast';

  @override
  String get toneHighlights => 'Highlights';

  @override
  String get toneShadows => 'Shadows';

  @override
  String get toneTemperature => 'Warmth';

  @override
  String get toneTint => 'Tint';

  @override
  String get toneVibrance => 'Vibrance';

  @override
  String get toneSaturation => 'Saturation';

  @override
  String get toneReset => 'Reset tune';

  @override
  String get toneCurves => 'Curves';

  @override
  String get curveChannelRgb => 'All';

  @override
  String get curveChannelRed => 'Red';

  @override
  String get curveChannelGreen => 'Green';

  @override
  String get curveChannelBlue => 'Blue';

  @override
  String get curveReset => 'Reset curve';

  @override
  String get curveHint => 'Drag a point to shape the curve';

  @override
  String get curveAddHint => 'Tap to add a point, long-press to remove';

  @override
  String get maskShapeLinear => 'Linear';

  @override
  String get maskShapeRadial => 'Radial';

  @override
  String get maskFeather => 'Feather';

  @override
  String get maskInvert => 'Invert';

  @override
  String get maskBlur => 'Blur';

  @override
  String get maskAddLinear => 'Add linear gradient';

  @override
  String get maskAddRadial => 'Add radial mask';

  @override
  String get maskRemove => 'Remove mask';

  @override
  String get maskEmpty => 'Tap + to add a mask';

  @override
  String get hslTitle => 'HSL Color Tuner';

  @override
  String get hslHue => 'Hue';

  @override
  String get hslSaturation => 'Saturation';

  @override
  String get hslLuminance => 'Luminance';

  @override
  String get hslReset => 'Reset HSL';

  @override
  String get hslRangeRed => 'Red';

  @override
  String get hslRangeOrange => 'Orange';

  @override
  String get hslRangeYellow => 'Yellow';

  @override
  String get hslRangeGreen => 'Green';

  @override
  String get hslRangeCyan => 'Cyan';

  @override
  String get hslRangeBlue => 'Blue';

  @override
  String get hslRangePurple => 'Purple';

  @override
  String get hslRangeMagenta => 'Magenta';

  @override
  String get filterNone => 'Original';

  @override
  String get filterMono => 'Mono';

  @override
  String get filterSepia => 'Sepia';

  @override
  String get filterVintage => 'Vintage';

  @override
  String get filterVivid => 'Vivid';

  @override
  String get filterCool => 'Cool';

  @override
  String get filterWarm => 'Warm';

  @override
  String get filterFade => 'Fade';

  @override
  String get filterIntensity => 'Strength';

  @override
  String get markupFreehand => 'Draw';

  @override
  String get markupRectangle => 'Rectangle';

  @override
  String get markupEllipse => 'Circle';

  @override
  String get markupLine => 'Line';

  @override
  String get markupArrow => 'Arrow';

  @override
  String get markupText => 'Text';

  @override
  String get markupColor => 'Colour';

  @override
  String get markupThickness => 'Thickness';

  @override
  String get markupFilled => 'Fill shape';

  @override
  String get markupUndoLayer => 'Remove last';

  @override
  String get markupTextTitle => 'Add text';

  @override
  String get markupTextHint => 'Type your text';

  @override
  String get markupTextAdd => 'Add';

  @override
  String get markupHint => 'Drag on the photo to draw';

  @override
  String get redactBlur => 'Blur';

  @override
  String get redactPixelate => 'Pixelate';

  @override
  String get redactBlackout => 'Blackout';

  @override
  String get redactStrength => 'Strength';

  @override
  String get redactHint => 'Drag over anything you want hidden';

  @override
  String get redactRemoveLast => 'Remove last';

  @override
  String redactCount(int count) {
    return '$count areas hidden';
  }

  @override
  String get watermarkNone => 'None';

  @override
  String get watermarkText => 'Text';

  @override
  String get watermarkTimestamp => 'Date and time';

  @override
  String get watermarkLogo => 'Logo';

  @override
  String get watermarkTextHint => 'Watermark text';

  @override
  String get watermarkPosition => 'Position';

  @override
  String get watermarkOpacity => 'Opacity';

  @override
  String get watermarkSize => 'Size';

  @override
  String get watermarkMargin => 'Edge gap';

  @override
  String get watermarkPickLogo => 'Choose a logo file';

  @override
  String get watermarkNoLogo => 'No logo chosen yet';

  @override
  String get watermarkClearLogo => 'Remove logo';

  @override
  String get positionTopLeft => 'Top left';

  @override
  String get positionTopCenter => 'Top centre';

  @override
  String get positionTopRight => 'Top right';

  @override
  String get positionCenterLeft => 'Middle left';

  @override
  String get positionCenter => 'Centre';

  @override
  String get positionCenterRight => 'Middle right';

  @override
  String get positionBottomLeft => 'Bottom left';

  @override
  String get positionBottomCenter => 'Bottom centre';

  @override
  String get positionBottomRight => 'Bottom right';

  @override
  String get convertOpen => 'Convert';

  @override
  String get convertTitle => 'Convert and resize';

  @override
  String get convertCannotOpen => 'This file cannot be converted';

  @override
  String get convertTooLarge => 'This file is too large to convert';

  @override
  String get convertUnreadable => 'This picture could not be read';

  @override
  String get convertFormatLabel => 'Format';

  @override
  String get convertQualityLabel => 'Quality';

  @override
  String get convertResizeLabel => 'Size';

  @override
  String get convertResizeNone => 'Original';

  @override
  String get convertResizeLongestSide => 'Longest side';

  @override
  String get convertResizePercent => 'Percent';

  @override
  String get convertResizeExact => 'Width and height';

  @override
  String get convertKeepAspect => 'Keep the shape';

  @override
  String get convertWidth => 'Width';

  @override
  String get convertHeight => 'Height';

  @override
  String get convertLongestSideLabel => 'Longest side in pixels';

  @override
  String get convertPercentLabel => 'Percent of the original';

  @override
  String get convertStripMetadata => 'Remove camera details';

  @override
  String get convertStripMetadataHint =>
      'Location and camera settings are left out of the copy';

  @override
  String get convertOriginalSize => 'Original';

  @override
  String get convertNewSize => 'New copy';

  @override
  String get convertEstimating => 'Working out the size';

  @override
  String get convertNoEstimate => 'The size cannot be worked out for this file';

  @override
  String get convertLargerWarning => 'The copy is larger than the original';

  @override
  String get convertSave => 'Save a copy';

  @override
  String get convertSaving => 'Saving';

  @override
  String get convertFailed => 'The copy could not be saved';

  @override
  String get convertOriginalKept => 'Your original file is not changed';

  @override
  String get pdfOpen => 'Export as PDF';

  @override
  String get pdfExportTitle => 'Export as PDF';

  @override
  String get pdfChoosePhotos => 'Choose photos';

  @override
  String get pdfNoSelection => 'Choose at least one photo';

  @override
  String get pdfNoPhotos => 'There are no photos to choose from';

  @override
  String get pdfPageSizeLabel => 'Page size';

  @override
  String get pdfPageA4 => 'A4';

  @override
  String get pdfPageLetter => 'Letter';

  @override
  String get pdfPageFitImage => 'Fit the photo';

  @override
  String get pdfOrientationLabel => 'Direction';

  @override
  String get pdfOrientationPortrait => 'Upright';

  @override
  String get pdfOrientationLandscape => 'Sideways';

  @override
  String get pdfOrientationAuto => 'Follow the photo';

  @override
  String get pdfFitLabel => 'Placement';

  @override
  String get pdfFitContain => 'Fit the whole photo';

  @override
  String get pdfFitFill => 'Fill the page';

  @override
  String get pdfMarginLabel => 'Border';

  @override
  String get pdfMarginNone => 'None';

  @override
  String get pdfMarginSmall => 'Small';

  @override
  String get pdfMarginMedium => 'Medium';

  @override
  String get pdfMarginLarge => 'Large';

  @override
  String get pdfQualityLabel => 'Photo quality';

  @override
  String get pdfExportAction => 'Create the PDF';

  @override
  String get pdfExporting => 'Creating the PDF';

  @override
  String get pdfFailed => 'The PDF could not be created';

  @override
  String get videoToolsOpen => 'Video tools';

  @override
  String get videoToolsTitle => 'Video tools';

  @override
  String get videoToolsUnavailable => 'This clip could not be read';

  @override
  String get videoTabFrame => 'Frame';

  @override
  String get videoTabGif => 'GIF';

  @override
  String get videoTabTrim => 'Trim';

  @override
  String get framePositionLabel => 'Position in the clip';

  @override
  String get frameFormatLabel => 'Save as';

  @override
  String get frameSaveAction => 'Save this frame';

  @override
  String get frameUnavailable => 'No frame could be read here';

  @override
  String get gifFrameRateLabel => 'Frames per second';

  @override
  String get gifSizeLabel => 'Size';

  @override
  String get gifLoopLabel => 'Play on a loop';

  @override
  String get gifCapped => 'The GIF is shortened to keep the file small';

  @override
  String get gifExportAction => 'Create the GIF';

  @override
  String get gifExporting => 'Creating the GIF';

  @override
  String get trimStartLabel => 'Start';

  @override
  String get trimEndLabel => 'End';

  @override
  String get trimLengthLabel => 'Length';

  @override
  String get trimAction => 'Save the trimmed clip';

  @override
  String get trimLosslessNote =>
      'Nothing is re-encoded, so no quality is lost. The cut may begin a moment earlier, at the nearest key frame.';

  @override
  String get trimTooShort => 'The chosen part is too short';

  @override
  String get videoWorking => 'Working';

  @override
  String get videoJobFailed => 'That could not be finished';

  @override
  String convertPixelSize(int width, int height) {
    return '$width by $height pixels';
  }

  @override
  String convertSmallerBy(int percent) {
    return '$percent percent smaller';
  }

  @override
  String convertSavedAs(String name) {
    return 'Saved as $name';
  }

  @override
  String pdfSelectedCount(int count) {
    return '$count chosen';
  }

  @override
  String pdfMaxPagesReached(int count) {
    return 'Only $count photos fit in one PDF';
  }

  @override
  String pdfExportedAs(String name, int pages) {
    return 'Saved $name with $pages pages';
  }

  @override
  String pdfSkippedCount(int count) {
    return '$count photos could not be read and were left out';
  }

  @override
  String gifFrameCount(int count) {
    return '$count frames';
  }

  @override
  String videoJobSavedAs(String name) {
    return 'Saved as $name';
  }

  @override
  String get searchTitle => 'Search';

  @override
  String get searchOpen => 'Search';

  @override
  String get searchHint => 'Search names, tags, notes, places';

  @override
  String get searchClear => 'Clear';

  @override
  String get searchFilters => 'Filters';

  @override
  String get searchStartTitle => 'Search your library';

  @override
  String get searchStartBody =>
      'Look through names, tags, notes, camera and place. Start a word with tag:, type:, place:, camera:, before: or after: to narrow the search.';

  @override
  String get searchNoResultsTitle => 'Nothing matched';

  @override
  String get searchNoResultsBody => 'Try fewer words, or check the filters.';

  @override
  String get searchFailed => 'The search could not run';

  @override
  String get searchRecentTitle => 'Recent searches';

  @override
  String get searchRecentClear => 'Clear all';

  @override
  String get searchRecentRemove => 'Forget this search';

  @override
  String searchResultCount(int count) {
    return '$count results';
  }

  @override
  String get searchMatchedInName => 'Matched the file name';

  @override
  String get searchMatchedInTags => 'Matched a tag';

  @override
  String get searchMatchedInNotes => 'Matched a note';

  @override
  String get searchMatchedInPlace => 'Matched a place';

  @override
  String get searchMatchedInDetails => 'Matched the photo details';

  @override
  String get filterTitle => 'Filters';

  @override
  String get filterMediaType => 'Kind';

  @override
  String get filterTypeImage => 'Photos';

  @override
  String get filterTypeVideo => 'Videos';

  @override
  String get filterTypeGif => 'GIFs';

  @override
  String get filterTypeRaw => 'RAW';

  @override
  String get filterTypeSvg => 'SVG';

  @override
  String get filterFavoritesOnly => 'Favourites only';

  @override
  String get filterHasLocation => 'Has a place';

  @override
  String get filterDateRange => 'Date range';

  @override
  String get filterDateAny => 'Any date';

  @override
  String get filterDateChoose => 'Choose dates';

  @override
  String get filterDateClear => 'Clear dates';

  @override
  String get filterTags => 'Tags';

  @override
  String get filterTagModeAll => 'Has all';

  @override
  String get filterTagModeAny => 'Has any';

  @override
  String get filterNoTags => 'No tags yet';

  @override
  String get filterReset => 'Reset';

  @override
  String get filterApply => 'Apply';

  @override
  String get tagsTitle => 'Tags';

  @override
  String get tagsOpen => 'Tags';

  @override
  String get tagsEmptyTitle => 'No tags yet';

  @override
  String get tagsEmptyBody => 'Make a tag to group photos your own way.';

  @override
  String get tagNew => 'New tag';

  @override
  String get tagEditTitle => 'Edit tag';

  @override
  String get tagNameLabel => 'Tag name';

  @override
  String get tagColorLabel => 'Colour';

  @override
  String get tagSave => 'Save';

  @override
  String get tagCancel => 'Cancel';

  @override
  String get tagDelete => 'Delete';

  @override
  String get tagDeleteTitle => 'Delete this tag?';

  @override
  String get tagDeleteBody =>
      'The tag comes off every photo that has it. No photo is deleted.';

  @override
  String tagItemCount(int count) {
    return '$count items';
  }

  @override
  String get tagShowMedia => 'Show photos';

  @override
  String get tagErrorEmpty => 'A tag needs a name';

  @override
  String get tagErrorTooLong => 'That name is too long';

  @override
  String get tagErrorDuplicate => 'That tag already exists';

  @override
  String get tagErrorFailed => 'The tag could not be saved';

  @override
  String get tagSheetTitle => 'Tags on this item';

  @override
  String get tagSheetNewHint => 'Add a new tag';

  @override
  String get tagSheetAdd => 'Add';

  @override
  String get tagSheetDone => 'Done';

  @override
  String get tagSheetOpen => 'Tags';

  @override
  String get cleanerTitle => 'Duplicate cleaner';

  @override
  String get cleanerOpen => 'Duplicate cleaner';

  @override
  String get cleanerStart => 'Find duplicates';

  @override
  String get cleanerStop => 'Stop';

  @override
  String get cleanerRescan => 'Scan again';

  @override
  String get cleanerIdleTitle => 'Find duplicate photos';

  @override
  String get cleanerIdleBody =>
      'Each file is read once and what was found is remembered, so scanning again later is quick.';

  @override
  String cleanerScanning(int processed, int total) {
    return 'Checked $processed of $total';
  }

  @override
  String get cleanerGrouping => 'Grouping the copies';

  @override
  String get cleanerCancelled => 'Scan stopped';

  @override
  String get cleanerFailed => 'The scan could not finish';

  @override
  String get cleanerNoneTitle => 'No duplicates found';

  @override
  String get cleanerNoneBody =>
      'Nothing in your library looks like a copy of anything else.';

  @override
  String cleanerGroupsFound(int count) {
    return '$count groups of copies';
  }

  @override
  String cleanerReclaimable(String size) {
    return 'About $size could be freed';
  }

  @override
  String cleanerFailures(int count) {
    return '$count files could not be read and were skipped';
  }

  @override
  String get cleanerKindExact => 'Identical files';

  @override
  String get cleanerKindSimilar => 'Looks the same';

  @override
  String cleanerMemberCount(int count) {
    return '$count copies';
  }

  @override
  String get cleanerCompare => 'Compare';

  @override
  String get compareTitle => 'Compare copies';

  @override
  String get compareGroupGone => 'This group has already been dealt with';

  @override
  String get compareKeepThis => 'Keep this one';

  @override
  String get compareBestBadge => 'Suggested';

  @override
  String compareKeepAndTrash(int count) {
    return 'Keep 1, move $count to trash';
  }

  @override
  String get compareTrashNotice =>
      'Nothing is erased. The other copies move to the trash and can be brought back.';

  @override
  String compareConfirmTitle(int count) {
    return 'Move $count copies to the trash?';
  }

  @override
  String get compareConfirmBody =>
      'Only the copy you kept stays in the gallery. The files stay on the device and can be brought back.';

  @override
  String get compareConfirm => 'Move to trash';

  @override
  String get compareCancel => 'Cancel';

  @override
  String compareMoved(int count) {
    return '$count copies moved to the trash';
  }

  @override
  String get compareFailed => 'The copies could not be moved';

  @override
  String get compareFieldSize => 'Size';

  @override
  String get compareFieldPixels => 'Pixels';

  @override
  String get compareFieldDate => 'Date';

  @override
  String get compareFieldCamera => 'Camera';

  @override
  String get compareUnknown => 'Unknown';

  @override
  String get albumsTitle => 'Albums';

  @override
  String get albumsOpen => 'Albums';

  @override
  String get albumsSectionMine => 'My albums';

  @override
  String get albumsSectionSmart => 'Smart albums';

  @override
  String get albumsSectionFolders => 'Device folders';

  @override
  String get albumsEmptyTitle => 'No albums yet';

  @override
  String get albumsEmptyBody =>
      'Make an album to group photos and videos your own way. The files stay where they are.';

  @override
  String get albumsFoldersEmpty => 'No folders found';

  @override
  String get albumsLoadFailed => 'Albums could not be loaded';

  @override
  String albumItemCount(int count) {
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
  String get smartAlbumFavorites => 'Favourites';

  @override
  String get smartAlbumVideos => 'Videos';

  @override
  String get smartAlbumGifs => 'Animated & GIFs';

  @override
  String get smartAlbumRaw => 'RAW captures';

  @override
  String get smartAlbumPanoramas => 'Panoramas';

  @override
  String get smartAlbumRecent => 'Recently added';

  @override
  String get smartAlbumTrash => 'Trash';

  @override
  String get albumNew => 'New album';

  @override
  String get albumCreateTitle => 'New album';

  @override
  String get albumRenameTitle => 'Rename album';

  @override
  String get albumNameLabel => 'Album name';

  @override
  String get albumNameHint => 'Holiday 2026';

  @override
  String get albumSave => 'Save';

  @override
  String get albumCancel => 'Cancel';

  @override
  String get albumRename => 'Rename';

  @override
  String get albumDelete => 'Delete album';

  @override
  String get albumChooseCover => 'Choose cover';

  @override
  String get albumReorder => 'Change order';

  @override
  String get albumAddMedia => 'Add photos';

  @override
  String get albumRemoveMedia => 'Remove from album';

  @override
  String get albumPin => 'Pin to top';

  @override
  String get albumUnpin => 'Unpin';

  @override
  String get albumErrorEmpty => 'An album needs a name';

  @override
  String get albumErrorTooLong => 'That name is too long';

  @override
  String get albumErrorDuplicate => 'An album with that name already exists';

  @override
  String get albumErrorFailed => 'That change could not be saved';

  @override
  String albumDeleteConfirmTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get albumDeleteConfirmBody =>
      'Only the album goes. Every photo and video stays on the device exactly where it is.';

  @override
  String get albumDeleteConfirm => 'Delete album';

  @override
  String get albumDeleted => 'Album deleted';

  @override
  String get albumRemovedFromAlbum => 'Removed from the album';

  @override
  String get albumCoverSet => 'Cover updated';

  @override
  String get albumOrderSaved => 'New order saved';

  @override
  String get albumEmptyTitle => 'This album is empty';

  @override
  String get albumEmptyBody =>
      'Add photos and videos from the gallery. They are not moved or copied.';

  @override
  String get albumGone => 'This album is no longer there';

  @override
  String get albumReorderTitle => 'Change order';

  @override
  String get albumReorderHint =>
      'Drag an item to move it. The new order is saved when you tap Save.';

  @override
  String get albumReorderSave => 'Save order';

  @override
  String get albumCoverTitle => 'Choose a cover';

  @override
  String get albumCoverClear => 'Use the newest item';

  @override
  String get albumPickerTitle => 'Add to album';

  @override
  String get albumPickerEmpty => 'You have no albums yet';

  @override
  String get albumPickerCreate => 'New album';

  @override
  String get albumPickerDone => 'Done';

  @override
  String get albumPickerSaved => 'Albums updated';

  @override
  String get folderEmptyTitle => 'This folder is empty';

  @override
  String get smartAlbumEmptyTitle => 'Nothing here yet';

  @override
  String get smartAlbumUnknown => 'That album does not exist';

  @override
  String get filterHasTags => 'Tagged only';

  @override
  String get filterFileSize => 'File size';

  @override
  String get filterSizeAny => 'Any size';

  @override
  String get filterSizeSmall => 'Under 1 MB';

  @override
  String get filterSizeMedium => '1 to 10 MB';

  @override
  String get filterSizeLarge => 'Over 10 MB';

  @override
  String get filterSortBy => 'Sort by';

  @override
  String get filterSortDateTaken => 'Date taken';

  @override
  String get filterSortDateAdded => 'Date added';

  @override
  String get filterSortName => 'Name';

  @override
  String get filterSortSize => 'Size';

  @override
  String get filterSortNewestFirst => 'Newest first';

  @override
  String get filterSortOldestFirst => 'Oldest first';

  @override
  String get vaultTitle => 'Private Vault';

  @override
  String get vaultMenuLabel => 'Private Vault';

  @override
  String get vaultMoveToVault => 'Move to vault';

  @override
  String get vaultSetUpTitle => 'Create your vault';

  @override
  String get vaultSetUpBody =>
      'Items you move here are encrypted with a key held by this device and hidden from the gallery.';

  @override
  String get vaultNoRecoveryWarning =>
      'There is no way to recover a forgotten PIN. Without it nobody can open the vault, not even this app.';

  @override
  String get vaultChoosePin => 'Choose a PIN';

  @override
  String get vaultConfirmPin => 'Enter the PIN again';

  @override
  String get vaultEnterPin => 'Enter your PIN';

  @override
  String get vaultCreate => 'Create vault';

  @override
  String get vaultUnlock => 'Unlock';

  @override
  String get vaultUseBiometrics => 'Use fingerprint';

  @override
  String get vaultUnlockReason => 'Unlock your private vault';

  @override
  String get vaultLockNow => 'Lock now';

  @override
  String get vaultPinMismatch => 'The two PINs are not the same';

  @override
  String get vaultWrongPin => 'That PIN is not right';

  @override
  String vaultAttemptsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tries left',
      one: '1 try left',
    );
    return '$_temp0';
  }

  @override
  String vaultLockedOut(int seconds) {
    return 'Too many tries. Wait $seconds seconds.';
  }

  @override
  String vaultPinTooShort(int count) {
    return 'A PIN needs at least $count digits';
  }

  @override
  String vaultPinTooLong(int count) {
    return 'A PIN can have at most $count digits';
  }

  @override
  String get vaultPinNotDigits => 'A PIN can only have digits';

  @override
  String get vaultPinAllSame => 'Do not use the same digit all the way through';

  @override
  String get vaultPinSequential => 'Do not use digits in a straight run';

  @override
  String get vaultBiometricFailed => 'Not recognised. Use your PIN.';

  @override
  String get vaultBiometricUnavailable =>
      'Fingerprint unlock is not available. Use your PIN.';

  @override
  String get vaultAuthError => 'The vault could not be opened';

  @override
  String get vaultKeystoreUnavailableTitle =>
      'This device cannot hold the vault key';

  @override
  String get vaultKeystoreUnavailableBody =>
      'The vault needs a hardware-backed key store, and this device does not have a working one. Nothing is encrypted without it, so the vault stays shut.';

  @override
  String get vaultEmptyTitle => 'The vault is empty';

  @override
  String get vaultEmptyBody =>
      'Add photos and videos here to encrypt them and take them out of the gallery.';

  @override
  String vaultItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'No items',
    );
    return '$_temp0';
  }

  @override
  String vaultSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get vaultAddItems => 'Add items';

  @override
  String get vaultRestore => 'Restore to gallery';

  @override
  String get vaultDeleteForever => 'Delete for good';

  @override
  String get vaultSettingsAction => 'Vault settings';

  @override
  String get vaultWorking => 'Working…';

  @override
  String get vaultCancel => 'Cancel';

  @override
  String get vaultSelectAll => 'Select all';

  @override
  String get vaultClearSelection => 'Clear selection';

  @override
  String get vaultImportTitle => 'Move to vault';

  @override
  String get vaultImportBody =>
      'The items are encrypted and taken out of the gallery. What happens to the originals is up to you.';

  @override
  String get vaultImportKeepOriginal => 'Keep the originals';

  @override
  String get vaultImportKeepOriginalBody =>
      'The originals stay where they are. Delete them yourself later if you want to.';

  @override
  String get vaultImportShredOriginal => 'Shred the originals';

  @override
  String get vaultImportShredOriginalBody =>
      'The original files are overwritten and deleted. This cannot be undone.';

  @override
  String vaultImportConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Move $count items',
      one: 'Move 1 item',
    );
    return '$_temp0';
  }

  @override
  String get vaultImportNothingSelected => 'Nothing is selected';

  @override
  String vaultShredConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Destroy $count originals?',
      one: 'Destroy 1 original?',
    );
    return '$_temp0';
  }

  @override
  String get vaultShredConfirmBody =>
      'The original files will be overwritten and deleted. There is no undo, and no way to get them back.';

  @override
  String get vaultShredConfirmAction => 'Shred them';

  @override
  String vaultImportDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items moved to the vault',
      one: '1 item moved to the vault',
    );
    return '$_temp0';
  }

  @override
  String vaultImportPartial(int moved, int failed) {
    return '$moved moved, $failed could not be read';
  }

  @override
  String get vaultImportFailed => 'Nothing could be moved to the vault';

  @override
  String vaultRestoreConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Restore $count items?',
      one: 'Restore 1 item?',
    );
    return '$_temp0';
  }

  @override
  String get vaultRestoreConfirmBody =>
      'The items are written back into your gallery folders and taken out of the vault.';

  @override
  String get vaultRestoreConfirmAction => 'Restore';

  @override
  String vaultRestoreDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items restored',
      one: '1 item restored',
    );
    return '$_temp0';
  }

  @override
  String get vaultRestoreFailed => 'Nothing could be restored';

  @override
  String vaultDeleteConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count items for good?',
      one: 'Delete 1 item for good?',
    );
    return '$_temp0';
  }

  @override
  String get vaultDeleteConfirmBody =>
      'The encrypted files are overwritten and deleted. There is no undo, and no copy anywhere else.';

  @override
  String vaultDeleteDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items deleted',
      one: '1 item deleted',
    );
    return '$_temp0';
  }

  @override
  String get vaultViewerFailed => 'This item could not be opened';

  @override
  String get vaultViewerTampered =>
      'This item failed its integrity check and was not opened';

  @override
  String get vaultSettingsTitle => 'Vault settings';

  @override
  String get vaultAutoLockHeading => 'Auto-lock';

  @override
  String get vaultAutoLockBody =>
      'The vault always locks when the app leaves the screen. This is how long it waits while you are not touching it.';

  @override
  String vaultAutoLockSeconds(int count) {
    return '$count seconds';
  }

  @override
  String vaultAutoLockMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String get vaultBiometricHeading => 'Unlock with fingerprint';

  @override
  String get vaultBiometricBody =>
      'A shortcut, not a replacement. Your PIN opens the vault whether this is on or off.';

  @override
  String get vaultShredHeading => 'Shred passes';

  @override
  String get vaultShredBody =>
      'How many times a file is overwritten before it is deleted. More passes take longer. On flash storage an overwrite is a strong measure, not a guarantee.';

  @override
  String vaultShredPassCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count passes',
      one: '1 pass',
    );
    return '$_temp0';
  }

  @override
  String get vaultShredDefaultHeading => 'Shred originals by default';

  @override
  String get vaultShredDefaultBody =>
      'Pre-selects the shred choice when you add items. It still asks you to confirm every time.';

  @override
  String get vaultChangePin => 'Change PIN';

  @override
  String get vaultCurrentPin => 'Current PIN';

  @override
  String get vaultNewPin => 'New PIN';

  @override
  String get vaultPinChanged => 'Your PIN has been changed';

  @override
  String get vaultSecureScreenHeading => 'Screenshots are blocked';

  @override
  String get vaultSecureScreenBody =>
      'While the vault is open, Android blocks screenshots and screen recording, and hides the vault in the app switcher.';

  @override
  String selectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '1 selected',
    );
    return '$_temp0';
  }

  @override
  String get selectionClear => 'Clear selection';

  @override
  String get selectionSelectAll => 'Select all';

  @override
  String get selectionFull => 'That is as many as one batch can hold';

  @override
  String get batchTitle => 'Batch actions';

  @override
  String get batchActionConvert => 'Convert';

  @override
  String get batchActionWatermark => 'Watermark';

  @override
  String get batchActionExportPdf => 'Make a PDF';

  @override
  String get batchActionAddTags => 'Add tags';

  @override
  String get batchActionRemoveTags => 'Remove tags';

  @override
  String get batchActionAddToAlbum => 'Add to album';

  @override
  String get batchActionFavourite => 'Add to favourites';

  @override
  String get batchActionUnfavourite => 'Remove from favourites';

  @override
  String get batchActionMoveToVault => 'Move to vault';

  @override
  String get batchActionTransfer => 'Send to a device';

  @override
  String get batchActionMoveToTrash => 'Move to trash';

  @override
  String get batchBlockedEmpty => 'Select something first';

  @override
  String get batchBlockedTooLarge => 'Too many items for one batch';

  @override
  String get batchBlockedUnsupported => 'Not available for these files';

  @override
  String get batchBlockedMixed => 'Videos cannot be included in this action';

  @override
  String batchWillSkip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files will be skipped',
      one: '1 file will be skipped',
    );
    return '$_temp0';
  }

  @override
  String get batchRunning => 'Working';

  @override
  String batchProgress(int done, int total) {
    return '$done of $total';
  }

  @override
  String get batchCancel => 'Cancel';

  @override
  String get batchCancelling => 'Stopping after this file';

  @override
  String get batchDone => 'Finished';

  @override
  String batchResultSucceeded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files done',
      one: '1 file done',
    );
    return '$_temp0';
  }

  @override
  String batchResultFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files could not be done',
      one: '1 file could not be done',
    );
    return '$_temp0';
  }

  @override
  String batchResultSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files skipped',
      one: '1 file skipped',
    );
    return '$_temp0';
  }

  @override
  String get batchConfirmTitle => 'Are you sure?';

  @override
  String batchConfirmVault(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos will be moved into the vault',
      one: '1 photo will be moved into the vault',
    );
    return '$_temp0';
  }

  @override
  String batchConfirmTrash(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items will be moved to the trash. Nothing is erased.',
      one: '1 item will be moved to the trash. Nothing is erased.',
    );
    return '$_temp0';
  }

  @override
  String batchConfirmNewFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new files will be saved beside the originals.',
      one: 'A new file will be saved beside the original.',
    );
    return '$_temp0';
  }

  @override
  String get batchConfirmContinue => 'Continue';

  @override
  String get batchPickTags => 'Choose tags';

  @override
  String get batchPickAlbum => 'Choose an album';

  @override
  String get backupTitle => 'Backup and restore';

  @override
  String get backupOpen => 'Backup and restore';

  @override
  String get backupCreateTitle => 'Create a backup';

  @override
  String get backupCreateBody =>
      'Saves your tags, albums, favourites and notes into one password-protected file. Photos and videos are not included: send those to another device with Transfer.';

  @override
  String get backupCreateAction => 'Create backup';

  @override
  String get backupRestoreTitle => 'Restore a backup';

  @override
  String get backupRestoreBody =>
      'Brings back tags, albums, favourites and notes for the photos that are on this device. Nothing on this device is deleted.';

  @override
  String get backupRestoreAction => 'Choose a backup file';

  @override
  String get backupPasswordTitle => 'Backup password';

  @override
  String get backupPasswordLabel => 'Password';

  @override
  String get backupPasswordConfirmLabel => 'Type it again';

  @override
  String get backupPasswordWarning =>
      'There is no way to recover this password. If you forget it, the backup cannot be opened.';

  @override
  String backupPasswordTooShort(int count) {
    return 'At least $count characters';
  }

  @override
  String get backupPasswordMismatch => 'The two do not match';

  @override
  String get backupStageCollecting => 'Reading your library';

  @override
  String get backupStagePacking => 'Packing';

  @override
  String get backupStageChoosing => 'Waiting for you to choose where to save';

  @override
  String get backupStageEncrypting => 'Encrypting';

  @override
  String get backupDone => 'Backup saved';

  @override
  String get backupCancelled => 'Backup cancelled';

  @override
  String get backupNothingToSave =>
      'There are no tags, albums, notes or favourites to back up yet';

  @override
  String get backupFailed => 'The backup could not be saved';

  @override
  String get restorePreviewTitle => 'What will be restored';

  @override
  String restoreFromBackupDate(String date) {
    return 'Backup from $date';
  }

  @override
  String restorePlanTags(int count) {
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
  String restorePlanAlbums(int count) {
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
  String restorePlanLinks(int count) {
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
  String restorePlanUpdates(int count) {
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
  String restorePlanUnmatched(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos in the backup are not on this device',
      one: '1 photo in the backup is not on this device',
    );
    return '$_temp0';
  }

  @override
  String get restorePlanNothing =>
      'This backup would change nothing on this device';

  @override
  String get restoreApply => 'Restore';

  @override
  String get restoreDone => 'Restore finished';

  @override
  String get restoreWrongPassword => 'Wrong password, or the file is damaged';

  @override
  String get restoreNotAnArchive => 'That is not a gallery backup file';

  @override
  String get restoreTooLarge => 'That file is too large to be a gallery backup';

  @override
  String get restoreTooNew =>
      'That backup was made by a newer version of the app';

  @override
  String get restoreFailed => 'The backup could not be restored';

  @override
  String get syncTitle => 'Transfer';

  @override
  String get syncOpen => 'Transfer to a device';

  @override
  String get syncIntro =>
      'Send photos straight to another phone on the same Wi-Fi. Nothing goes to the internet, and no account is needed.';

  @override
  String get syncPrivacyNote =>
      'Both phones must be on the same Wi-Fi. The connection is refused unless the other device is on your local network, and it is closed as soon as you leave this screen.';

  @override
  String get syncSend => 'Send';

  @override
  String get syncReceive => 'Receive';

  @override
  String get syncSendBody => 'Show a code on this phone, or scan the other one';

  @override
  String get syncReceiveBody => 'Show a code for the other phone to scan';

  @override
  String get syncShowCode => 'Show a code';

  @override
  String get syncScanCode => 'Scan a code';

  @override
  String get syncScanTitle => 'Scan the other phone';

  @override
  String get syncPairingHeading => 'Point the other phone at this code';

  @override
  String get syncManualCodeHeading => 'Or type this code';

  @override
  String get syncManualCodeLabel => 'Pairing code';

  @override
  String get syncManualCodeInvalid => 'That code is not valid';

  @override
  String get syncWaiting => 'Waiting for the other phone';

  @override
  String syncPairedWith(String name) {
    return 'Paired with $name';
  }

  @override
  String get syncTransferring => 'Transferring';

  @override
  String syncProgressFiles(int done, int total) {
    return '$done of $total files';
  }

  @override
  String get syncNothingSelected => 'Choose some photos to send first';

  @override
  String syncOfferHeading(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files offered',
      one: '1 file offered',
    );
    return '$_temp0';
  }

  @override
  String get syncDone => 'Transfer finished';

  @override
  String syncResultReceived(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files received',
      one: '1 file received',
    );
    return '$_temp0';
  }

  @override
  String syncResultSent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files sent',
      one: '1 file sent',
    );
    return '$_temp0';
  }

  @override
  String syncResultSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files were already there',
      one: '1 file was already there',
    );
    return '$_temp0';
  }

  @override
  String syncResultFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files did not arrive',
      one: '1 file did not arrive',
    );
    return '$_temp0';
  }

  @override
  String get syncSavedToAppFolder =>
      'On this version of Android the files were saved in the app\'s own folder rather than your gallery.';

  @override
  String get syncStop => 'Stop';

  @override
  String get syncErrorNoNetwork => 'This phone is not on a Wi-Fi network';

  @override
  String get syncErrorPairingTimeout => 'No device connected in time';

  @override
  String get syncErrorRefused => 'That device is not on your local network';

  @override
  String get syncErrorHandshake =>
      'The other device could not prove it showed that code';

  @override
  String get syncErrorProtocol =>
      'The other device is running a different version of the app';

  @override
  String get syncErrorConnection =>
      'The connection to the other device was lost';

  @override
  String get syncErrorIdle => 'The other device stopped responding';

  @override
  String get syncErrorCancelled => 'The transfer was stopped';

  @override
  String get syncErrorUnknown => 'The transfer could not be finished';

  @override
  String get syncCameraPermission =>
      'Camera access is needed to scan the code. You can type the code instead.';

  @override
  String get syncTypeCodeInstead => 'Type the code instead';

  @override
  String get viewerMoreActions => 'More';

  @override
  String get codeScanOpen => 'Scan codes';

  @override
  String get codeScanTitle => 'Codes in this picture';

  @override
  String get codeScanLooking => 'Looking for codes';

  @override
  String get codeScanNoCodes => 'No codes were found in this picture';

  @override
  String get codeScanFailed => 'This picture could not be scanned';

  @override
  String get codeScanRetry => 'Try again';

  @override
  String codeScanFoundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count codes found',
      one: '1 code found',
    );
    return '$_temp0';
  }

  @override
  String get codeScanKindUrl => 'Web address';

  @override
  String get codeScanKindWifi => 'Wi-Fi network';

  @override
  String get codeScanKindPhone => 'Phone number';

  @override
  String get codeScanKindEmail => 'Email address';

  @override
  String get codeScanKindSms => 'Text message';

  @override
  String get codeScanKindGeo => 'Map point';

  @override
  String get codeScanKindContact => 'Contact card';

  @override
  String get codeScanKindCalendar => 'Calendar entry';

  @override
  String get codeScanKindText => 'Text';

  @override
  String get codeScanActionCopy => 'Copy';

  @override
  String get codeScanActionOpen => 'Open';

  @override
  String get codeScanActionDial => 'Call';

  @override
  String get codeScanActionEmail => 'Write email';

  @override
  String get codeScanActionSms => 'Send message';

  @override
  String get codeScanActionMap => 'Show on map';

  @override
  String get codeScanActionCopyWifiPassword => 'Copy password';

  @override
  String get codeScanActionConnectWifi => 'Connect';

  @override
  String get codeScanActionSaveToNotes => 'Save to notes';

  @override
  String get codeScanBlockedScheme =>
      'The app does not open this kind of address';

  @override
  String get codeScanBlockedMalformed => 'This address could not be read';

  @override
  String get codeScanBlockedIncompleteWifi =>
      'This Wi-Fi code is missing the network name or the password';

  @override
  String get codeScanBlockedTooLong => 'This code is too long to use';

  @override
  String get codeScanCopied => 'Copied';

  @override
  String get codeScanPasswordCopied => 'Password copied';

  @override
  String get codeScanSavedToNotes => 'Saved to notes';

  @override
  String get codeScanOpenFailed => 'No app on this device can open it';

  @override
  String get codeScanWifiSuggested =>
      'The network was offered to Android. Pick it in the Wi-Fi settings.';

  @override
  String get codeScanWifiManual =>
      'Open the Wi-Fi settings and pick the network yourself.';

  @override
  String codeScanWifiSecurity(String security) {
    return 'Security: $security';
  }

  @override
  String get codeScanWifiHidden => 'Hidden network';

  @override
  String get codeScanWifiOpen => 'Open network';

  @override
  String get ocrOpen => 'Extract text';

  @override
  String get ocrTitle => 'Text in this picture';

  @override
  String get ocrReading => 'Reading the text';

  @override
  String get ocrSlowHint => 'A large photo can take a few seconds.';

  @override
  String get ocrLanguage => 'Language';

  @override
  String get ocrLanguageEnglish => 'English';

  @override
  String get ocrLanguageMalayalam => 'Malayalam';

  @override
  String get ocrLanguageBoth => 'English and Malayalam';

  @override
  String get ocrNoText => 'No text was found in this picture';

  @override
  String get ocrCopyAll => 'Copy all';

  @override
  String get ocrCopied => 'Text copied';

  @override
  String get ocrSaveToNotes => 'Save to notes';

  @override
  String get ocrSavedToNotes => 'Saved to notes';

  @override
  String get ocrReadAgain => 'Read again';

  @override
  String ocrWordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: '1 word',
    );
    return '$_temp0';
  }

  @override
  String get ocrFailedUnreadable => 'This picture could not be opened';

  @override
  String get ocrFailedTooLarge => 'This picture is too large to read';

  @override
  String get ocrFailedMissingData =>
      'The language files are missing from this build';

  @override
  String get ocrFailedTimeout => 'Reading took too long and was stopped';

  @override
  String get ocrFailedEngine => 'The text could not be read';

  @override
  String get notesOpen => 'Notes';

  @override
  String get notesTitle => 'Notes';

  @override
  String get notesWriteTab => 'Write';

  @override
  String get notesPreviewTab => 'Preview';

  @override
  String get notesHint =>
      'Write a note about this item. Markdown is supported.';

  @override
  String get notesEmpty => 'No note yet';

  @override
  String get notesSave => 'Save';

  @override
  String get notesSaved => 'Note saved';

  @override
  String get notesSaveFailed => 'The note could not be saved';

  @override
  String get notesDelete => 'Delete note';

  @override
  String get notesDeleteTitle => 'Delete this note?';

  @override
  String get notesDeleteBody =>
      'The note will be removed. The file is not changed.';

  @override
  String get notesDeleted => 'Note deleted';

  @override
  String get notesCancel => 'Cancel';

  @override
  String notesCharacterCount(int used, int total) {
    return '$used of $total characters';
  }

  @override
  String get notesTooLong => 'This note is too long to save';

  @override
  String get notesDiscardTitle => 'Leave without saving?';

  @override
  String get notesDiscardBody => 'Your changes to this note will be lost.';

  @override
  String get notesDiscardLeave => 'Leave';

  @override
  String get notesDiscardKeep => 'Keep writing';

  @override
  String get notesLinkBlocked => 'The app does not open this kind of link';

  @override
  String get notesDetailsLabel => 'Note';

  @override
  String get notesAddFromDetails => 'Add a note';

  @override
  String get pdfImagesOpen => 'Extract images from PDF';

  @override
  String get pdfImagesTitle => 'Images in a PDF';

  @override
  String get pdfImagesPick => 'Choose a PDF';

  @override
  String get pdfImagesChooseAnother => 'Choose another PDF';

  @override
  String get pdfImagesReading => 'Reading the PDF';

  @override
  String get pdfImagesEmptyTitle => 'No PDF chosen yet';

  @override
  String get pdfImagesEmptyBody =>
      'Pick a PDF and the app will list the pictures inside it. The PDF itself is never changed.';

  @override
  String get pdfImagesNone => 'This PDF holds no pictures';

  @override
  String pdfImagesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pictures found',
      one: '1 picture found',
    );
    return '$_temp0';
  }

  @override
  String pdfImagesSkippedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count could not be read',
      one: '1 could not be read',
    );
    return '$_temp0';
  }

  @override
  String get pdfImagesSave => 'Save selected';

  @override
  String get pdfImagesSaving => 'Saving';

  @override
  String pdfImagesSavedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pictures saved to the gallery',
      one: '1 picture saved to the gallery',
    );
    return '$_temp0';
  }

  @override
  String pdfImagesSaveFailedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count could not be saved',
      one: '1 could not be saved',
    );
    return '$_temp0';
  }

  @override
  String get pdfImagesSelectAll => 'Select all';

  @override
  String get pdfImagesClearSelection => 'Clear';

  @override
  String get pdfImagesNothingSelected => 'Tick at least one picture to save';

  @override
  String get pdfImagesTruncated =>
      'Only the first pictures were read, because this PDF holds a great many.';

  @override
  String get pdfImagesFallbackDirectory =>
      'Saved to the app folder, because the gallery could not be written to';

  @override
  String pdfImageSize(int width, int height) {
    return '$width by $height';
  }

  @override
  String get pdfRefusedNotPdf => 'This file is not a PDF';

  @override
  String get pdfRefusedEncrypted =>
      'This PDF is password protected, so it cannot be opened';

  @override
  String get pdfRefusedTooLarge => 'This PDF is too large to open';

  @override
  String get pdfRefusedUnreadable => 'This PDF could not be read';

  @override
  String get pdfSkipUnsupportedFilter =>
      'Compressed in a way the app cannot read';

  @override
  String get pdfSkipUnsupportedColor =>
      'Uses a colour space the app cannot read';

  @override
  String get pdfSkipUnsupportedDepth =>
      'Uses a colour depth the app cannot read';

  @override
  String get pdfSkipTooLarge => 'Too large to pull out';

  @override
  String get pdfSkipMalformed => 'The picture data is incomplete';

  @override
  String get pdfSkipDecodeFailed => 'The picture could not be decompressed';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsSafety => 'Safety';

  @override
  String get settingsPrivacy => 'Storage and privacy';

  @override
  String get settingsDeveloper => 'Developer';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageMalayalam => 'മലയാളം';

  @override
  String get languageSubtitle =>
      'The app changes language at once. No restart is needed.';

  @override
  String get gridDensity => 'Grid density';

  @override
  String get gridDensitySubtitle =>
      'How many photos fit across the timeline. Pinching the grid changes it too.';

  @override
  String gridDensityValue(int count) {
    return '$count per row';
  }

  @override
  String get showFlashbacks => 'Show memories';

  @override
  String get showFlashbacksSubtitle =>
      'A row of photos from this day in past years, at the top of the timeline.';

  @override
  String get confirmDestructive => 'Ask before deleting';

  @override
  String get confirmDestructiveSubtitle =>
      'Ask one more time before a delete or an overwrite. Some warnings always appear, whatever this is set to.';

  @override
  String get privacyNoServer => 'No remote server';

  @override
  String get privacyNoServerBody =>
      'Your photos, tags and notes stay on this phone. Nothing is uploaded, and there is no account. Internet access is used only by the transfer screen, to reach another phone on your own Wi-Fi.';

  @override
  String get aboutOpen => 'About this app';

  @override
  String get aboutOpenSubtitle => 'Version, author and licence';

  @override
  String aboutBuild(String build) {
    return 'Build $build';
  }

  @override
  String get aboutBuildDate => 'Build date';

  @override
  String get aboutMailFailed => 'No app on this phone can open that address.';

  @override
  String get aboutAppName => 'App';

  @override
  String get vaultSettingsOpenSubtitle => 'Lock timing, PIN and shredding';

  @override
  String get backupOpenSubtitle => 'Password-protected backup and restore';

  @override
  String get settingsResetTitle => 'Reset settings';

  @override
  String get settingsResetBody =>
      'Put every setting on this screen back to how it started. Your photos, tags, albums and vault are not touched.';

  @override
  String get settingsResetDone => 'Settings put back to the defaults.';

  @override
  String get settingsCancel => 'Cancel';

  @override
  String get settingsResetConfirm => 'Reset';

  @override
  String get settingsHelp => 'Help & Guides';

  @override
  String get settingsHelpSubtitle =>
      'Explore guides, pro-tips and offline guarantees for every feature';

  @override
  String get settingsAbout => 'About';

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
  String get settingsDefaultApp => 'Default Gallery App';

  @override
  String get settingsDefaultAppSubtitle =>
      'Set as default app for viewing photos and videos';

  @override
  String get defaultAppDialogTitle => 'Set as Default Gallery';

  @override
  String get defaultAppDialogBody =>
      'To make this your default gallery:\n\n1. Open any photo or video on your device (e.g. from Files, Downloads, or messages).\n2. Choose SreerajP Image Video Gallery and tap \'Always\'.\n\nYou can also configure defaults in Android Settings.';

  @override
  String get defaultAppOpenSettings => 'Open Android Settings';

  @override
  String get trashTitle => 'Trash';

  @override
  String get trashEmpty => 'Trash is empty';

  @override
  String get trashEmptySubtitle =>
      'Items you delete are kept here until you empty the trash.';

  @override
  String get trashEmptyAction => 'Empty trash';

  @override
  String get trashEmptyConfirmTitle => 'Empty trash?';

  @override
  String get trashEmptyConfirmBody =>
      'This will permanently delete all trashed items from your device storage. This action cannot be undone.';

  @override
  String get trashDeletePermanentlyAction => 'Delete permanently';

  @override
  String get trashDeletePermanentlyConfirmTitle => 'Delete permanently?';

  @override
  String get trashDeletePermanentlyConfirmBody =>
      'This item will be permanently deleted from your device storage. This action cannot be undone.';

  @override
  String get trashDeletedPermanentlySnackbar => 'Item permanently deleted';

  @override
  String get trashRestoreAction => 'Restore';

  @override
  String get trashRestoreAllAction => 'Restore all';

  @override
  String get trashRestoreAllConfirmBody =>
      'Every item in the trash will be moved back to your library.';

  @override
  String get trashRestoredSnackbar => 'Restored from trash';

  @override
  String get trashEmptiedSnackbar => 'Trash emptied';

  @override
  String trashItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items in trash',
      one: '1 item in trash',
    );
    return '$_temp0';
  }

  @override
  String get settingsAppearanceSubtitle => 'Theme, grid density, memories';

  @override
  String get settingsLanguageSubtitle => 'System, English, Malayalam';

  @override
  String get settingsSafetySubtitle =>
      'Confirmation before destructive actions';

  @override
  String get settingsDefaultAppCardSubtitle => 'Set as default gallery app';

  @override
  String get settingsPrivacySubtitle => 'Vault, backup, network policy';

  @override
  String get settingsHelpCardSubtitle =>
      'Guides and privacy guarantees for every feature';

  @override
  String get settingsAboutSubtitle => 'Version, author and licence';

  @override
  String get settingsDeveloperSubtitle => 'Media scanner tools';

  @override
  String get viewerTrashTooltip => 'Move to trash';

  @override
  String get viewerTrashConfirmTitle => 'Move to trash?';

  @override
  String get viewerTrashConfirmBody =>
      'This item will be moved to the trash. You can restore it anytime from the Trash album.';

  @override
  String get viewerTrashSuccess => 'Moved to trash';

  @override
  String get viewerTrashUndo => 'Undo';

  @override
  String get comparePhotosTitle => 'A/B Comparison';

  @override
  String get compareModeSplit => 'Split View';

  @override
  String get compareModeCurtain => 'Sliding Curtain';

  @override
  String get compareSplitHorizontal => 'Side by Side';

  @override
  String get compareSplitVertical => 'Top and Bottom';

  @override
  String get compareSyncLocked => 'Pan & Zoom Locked';

  @override
  String get compareSyncUnlocked => 'Independent Pan & Zoom';

  @override
  String get compareSwap => 'Swap Photos';

  @override
  String get compareResetZoom => 'Reset Zoom';

  @override
  String get compareDetails => 'Compare Details';

  @override
  String get comparePickPhoto => 'Choose Photo';

  @override
  String get comparePhotoA => 'Photo A';

  @override
  String get comparePhotoB => 'Photo B';

  @override
  String get compareWithPrevious => 'Compare with previous photo';

  @override
  String get compareWithNext => 'Compare with next photo';

  @override
  String get compareChooseFromGallery => 'Pick photo from gallery';

  @override
  String get compareAction => 'Compare';

  @override
  String get compareTooltip => 'Compare photos side-by-side';

  @override
  String get compareSelectSecondPhoto => 'Select a photo to compare with';

  @override
  String get compareDimensions => 'Dimensions';

  @override
  String get compareFileSize => 'File Size';

  @override
  String get compareDateTaken => 'Date Taken';

  @override
  String get compareCamera => 'Camera';

  @override
  String get compareExposure => 'Exposure';

  @override
  String get compareIso => 'ISO';

  @override
  String get compareAperture => 'Aperture';

  @override
  String get compareShutterSpeed => 'Shutter Speed';

  @override
  String get compareFocalLength => 'Focal Length';

  @override
  String get compareNoExif => 'No EXIF data available';

  @override
  String get tabTimeline => 'Timeline';

  @override
  String get tabFolders => 'Folders';

  @override
  String get tabAlbums => 'Albums';

  @override
  String get foldersTitle => 'Folders';

  @override
  String get foldersEmpty => 'No folders found';

  @override
  String get foldersEmptyBody =>
      'Pull down to scan for photos and videos on your device.';

  @override
  String folderItemCount(int count) {
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
  String get privacyScrubberTitle => 'Media Privacy & Scrubber';

  @override
  String get privacyScrubberSubtitle =>
      'Strip sensitive EXIF metadata and fuzz GPS coordinates before sharing';

  @override
  String get privacyScrubberMenu => 'Privacy & EXIF Scrubber';

  @override
  String get privacyCardTitle => 'Media Privacy & EXIF';

  @override
  String get privacyCardBody =>
      'Protect your privacy by stripping GPS location, camera serial numbers, and device identifiers before sharing.';

  @override
  String get privacyOpenScrubber => 'Open Privacy Controls';

  @override
  String get privacyTabStripper => 'EXIF Stripper';

  @override
  String get privacyTabGeofence => 'GPS Geofence Shifter';

  @override
  String get privacyStripAndShareAction => 'One-Tap Strip & Share';

  @override
  String get privacySaveSanitizedAction => 'Save Sanitized Copy to Gallery';

  @override
  String get privacyGranularTitle => 'Selective Metadata Scrubbing';

  @override
  String get privacyStripAll => 'Strip All';

  @override
  String get privacyCustom => 'Custom';

  @override
  String get privacyOptionGps => 'Strip GPS Coordinates & Altitude';

  @override
  String get privacyOptionSerials => 'Strip Camera & Lens Serial Numbers';

  @override
  String get privacyOptionTimestamps => 'Strip Capture & Digitization Dates';

  @override
  String get privacyOptionAuthor => 'Strip Author & Software Info';

  @override
  String get privacyErrorReadingFile =>
      'Unable to read image data for privacy processing';

  @override
  String get privacyShareTitle => 'Share Sanitized Media';

  @override
  String get privacyShareFailed => 'Sharing could not be initiated';

  @override
  String get privacyProcessError => 'An error occurred while sanitizing media';

  @override
  String get privacySavedToGallery => 'Sanitized copy saved to gallery';

  @override
  String get privacySaveFailed => 'Failed to save sanitized image';

  @override
  String get privacyNoLocation =>
      'No embedded GPS location found in this photo';

  @override
  String get geofenceOffsetDistance => 'Shift Distance Offset';

  @override
  String get geofenceReroll => 'Reroll random shift';

  @override
  String get geofenceRandomPreset => 'Random (2–5 km)';

  @override
  String geofenceShiftSummary(String summary) {
    return 'Shifted $summary';
  }

  @override
  String geofenceFuzzedCoordinates(String lat, String lon) {
    return 'Shifted to $lat, $lon';
  }

  @override
  String get geofenceExplanation =>
      'Adds an offset within 2–5 km to preserve general regional travel context while hiding exact residential street coordinates.';

  @override
  String get geofenceShareTitle => 'Share Geofuzzed Photo';

  @override
  String get geofenceShareAction => 'Fuzz Location & Share';

  @override
  String get geofenceSaveAction => 'Save Geofuzzed Copy to Gallery';

  @override
  String get geofenceSavedToGallery => 'Geofuzzed copy saved to gallery';

  @override
  String get geofenceNoCoordinates => 'No Location Found';

  @override
  String get geofenceNoCoordinatesBody =>
      'This media item does not have embedded GPS coordinates to shift.';

  @override
  String get privacyAuditSensitiveDetected => 'Sensitive Metadata Detected';

  @override
  String get privacyAuditClean => 'No Sensitive Metadata Detected';

  @override
  String privacyAuditSensitiveDetails(String gps, String camera) {
    return 'Contains $gps $camera';
  }

  @override
  String get privacyAuditGps => 'GPS Coordinates';

  @override
  String get privacyAuditCamera => 'Device Identifiers';

  @override
  String get privacyAuditCleanDetails =>
      'This file does not contain embedded location or camera serial identifiers.';

  @override
  String get forensicInspectorTitle => 'Forensic Lens & Sensor Inspector';

  @override
  String get forensicInspectorSubtitle =>
      'Deep technical optical and hardware forensic insights';

  @override
  String get forensicInspectorButton => 'Inspect Lens & Sensor Forensics';

  @override
  String get forensicInspectorQuickHint =>
      'Sensor crop factor, 35mm equivalent, shutter actuation, exposure bias';

  @override
  String get forensicNoData =>
      'No forensic lens or sensor metadata found in this item.';

  @override
  String get forensicSectionSensorOptics => 'Sensor & Optical Characteristics';

  @override
  String get forensicSectionMechanicsColor =>
      'Mechanical Actuations & Color Space';

  @override
  String get forensicSectionHardwareIdentity =>
      'Hardware & Lens Serial Identity';

  @override
  String get forensicSensorFormat => 'Sensor Format';

  @override
  String get forensicCropFactor => 'Crop Factor';

  @override
  String get forensicFocal35mm => '35mm Equivalent';

  @override
  String get forensicPhysicalFocalLength => 'Physical Focal Length';

  @override
  String get forensicHyperfocalDistance => 'Hyperfocal Distance';

  @override
  String get forensicExposureBias => 'Exposure Bias (EV)';

  @override
  String get forensicShutterActuations => 'Shutter Releases';

  @override
  String get forensicShutterNotReported => 'Electronic shutter / Not reported';

  @override
  String get forensicColorProfile => 'Color Space / Profile';

  @override
  String get forensicExposureProgram => 'Exposure Program';

  @override
  String get forensicMeteringMode => 'Metering Mode';

  @override
  String get forensicSensingMethod => 'Sensing Method';

  @override
  String get forensicSceneCaptureType => 'Scene Capture Type';

  @override
  String get forensicFlashStatus => 'Flash & Strobe Status';

  @override
  String get forensicCameraSerial => 'Camera Serial Number';

  @override
  String get forensicLensModel => 'Lens Model';

  @override
  String get forensicLensSpecification => 'Lens Specification';

  @override
  String get forensicLensSerial => 'Lens Serial Number';

  @override
  String get forensicSerialNotEmbedded => 'Not embedded in headers';
}
