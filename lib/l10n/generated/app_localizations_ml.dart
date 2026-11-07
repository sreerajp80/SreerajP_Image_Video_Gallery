// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malayalam (`ml`).
class AppLocalizationsMl extends AppLocalizations {
  AppLocalizationsMl([String locale = 'ml']) : super(locale);

  @override
  String get titleApp => 'ശ്രീരാജ് പി ഗാലറി';

  @override
  String get labelDevBanner => 'ഡെവ് ബിൽഡ്';

  @override
  String get titleSettings => 'ക്രമീകരണങ്ങൾ';

  @override
  String get titleAbout => 'വിവരണം';

  @override
  String get labelTheme => 'തീം';

  @override
  String get actionThemeSystem => 'സിസ്റ്റം ഡിഫോൾട്ട്';

  @override
  String get actionThemeLight => 'ലൈറ്റ്';

  @override
  String get actionThemeDark => 'ഡാർക്ക്';

  @override
  String get actionThemeAmoled => 'അമോലെഡ് ബ്ലാക്ക്';

  @override
  String get titleVersion => 'പതിപ്പ്';

  @override
  String get labelPermissionRequired => 'മീഡിയ അനുമതി ആവശ്യമാണ്';

  @override
  String get bodyPermissionRequired =>
      'ഗാലറിക്ക് നിങ്ങളുടെ ഫോട്ടോകളും വീഡിയോകളും കാണിക്കാൻ അനുമതി നൽകുക. ഒന്നും ഉപകരണത്തിന് പുറത്തേക്ക് പോകില്ല.';

  @override
  String get labelGrantPermission => 'അനുമതി നൽകുക';

  @override
  String get labelOpenSettings => 'ക്രമീകരണങ്ങൾ തുറക്കുക';

  @override
  String get bodyPermissionPartial =>
      'തിരഞ്ഞെടുത്ത മീഡിയ മാത്രമേ കാണാനാകൂ. എല്ലാം കാണാൻ പൂർണ അനുമതി നൽകുക.';

  @override
  String get labelScanMedia => 'ഉപകരണത്തിലെ മീഡിയ സ്കാൻ ചെയ്യുക';

  @override
  String get bodyScanningMedia => 'മീഡിയ സ്കാൻ ചെയ്യുന്നു...';

  @override
  String bodyScanProgress(int scanned, int total) {
    return '$total ൽ $scanned സ്കാൻ ചെയ്തു';
  }

  @override
  String bodyScanComplete(int count) {
    return 'സ്കാൻ പൂർത്തിയായി: $count ഇനങ്ങൾ ചേർത്തു';
  }

  @override
  String get errorScanFailed => 'മീഡിയ സ്കാൻ പരാജയപ്പെട്ടു';

  @override
  String bodyIndexedItems(int count) {
    return 'ചേർത്ത ഇനങ്ങൾ: $count';
  }

  @override
  String get bodyNoMediaFound => 'ഫോട്ടോകളോ വീഡിയോകളോ കണ്ടെത്തിയില്ല';

  @override
  String get labelMediaUnavailable => 'പ്രിവ്യൂ ലഭ്യമല്ല';

  @override
  String get labelTimelineToday => 'ഇന്ന്';

  @override
  String get labelTimelineYesterday => 'ഇന്നലെ';

  @override
  String get titleTimeline => 'ടൈംലൈൻ';

  @override
  String get bodyNoMediaInTimeline => 'നിങ്ങളുടെ ഗാലറി ശൂന്യമാണ്';

  @override
  String get bodyPullToScan =>
      'പുതിയ ഫോട്ടോകളും വീഡിയോകളും തിരയാൻ താഴേക്ക് വലിക്കുക.';

  @override
  String get titleFlashback => 'ഈ ദിവസം';

  @override
  String get tooltipExpandFlashback => 'ഓർമ്മകൾ കാണിക്കുക';

  @override
  String get tooltipCollapseFlashback => 'ഓർമ്മകൾ മറയ്ക്കുക';

  @override
  String get labelFlashbackOneYearAgo => '1 വർഷം മുമ്പ്';

  @override
  String bodyFlashbackYearsAgo(int years) {
    return '$years വർഷം മുമ്പ്';
  }

  @override
  String bodyGridColumns(int count) {
    return 'ഒരു വരിയിൽ $count';
  }

  @override
  String get labelBadgeGif => 'GIF';

  @override
  String get labelBadgeRaw => 'RAW';

  @override
  String get labelBadgeHd => 'HD';

  @override
  String labelBadgeVideoDuration(String duration) {
    return 'വീഡിയോ, $duration';
  }

  @override
  String get labelScrollToDate => 'തീയതിയിലേക്ക് പോകുക';

  @override
  String get tooltipViewerClose => 'അടയ്ക്കുക';

  @override
  String get labelViewerRotateLeft => 'ഇടത്തേക്ക് തിരിക്കുക';

  @override
  String get labelViewerRotateRight => 'വലത്തേക്ക് തിരിക്കുക';

  @override
  String get labelViewerAddFavorite => 'പ്രിയപ്പെട്ടതിലേക്ക് ചേർക്കുക';

  @override
  String get bodyViewerRemoveFavorite => 'പ്രിയപ്പെട്ടതിൽ നിന്ന് നീക്കുക';

  @override
  String get actionPlay => 'പ്ലേ ചെയ്യുക';

  @override
  String get actionPause => 'നിർത്തുക';

  @override
  String get tooltipFrameForward => 'അടുത്ത ഫ്രെയിം';

  @override
  String get tooltipFrameBackward => 'മുൻ ഫ്രെയിം';

  @override
  String get tooltipSkipForward => '10 സെക്കൻഡ് മുന്നോട്ട്';

  @override
  String get tooltipSkipBackward => '10 സെക്കൻഡ് പിന്നോട്ട്';

  @override
  String get tooltipLoopPlayback => 'ആവർത്തിക്കുക';

  @override
  String get tooltipPlaybackSpeed => 'പ്ലേബാക്ക് വേഗത';

  @override
  String get bodyVideoCannotPlay => 'ഈ വീഡിയോ പ്ലേ ചെയ്യാൻ കഴിയില്ല.';

  @override
  String get bodyVideoFormatUnsupported =>
      'ഈ ഉപകരണത്തിന് ഈ വീഡിയോ ഫോർമാറ്റ് പ്ലേ ചെയ്യാൻ കഴിയില്ല.';

  @override
  String get tooltipDetailsTitle => 'വിശദാംശങ്ങൾ';

  @override
  String get labelDetailsFileName => 'ഫയലിന്റെ പേര്';

  @override
  String get labelDetailsFormat => 'ഫോർമാറ്റ്';

  @override
  String get labelDetailsSize => 'വലുപ്പം';

  @override
  String get labelDetailsDimensions => 'അളവുകൾ';

  @override
  String get labelDetailsDuration => 'ദൈർഘ്യം';

  @override
  String get labelDetailsDateTaken => 'എടുത്ത തീയതി';

  @override
  String get labelDetailsDateModified => 'അവസാനം മാറ്റിയത്';

  @override
  String get labelDetailsFolder => 'ഫോൾഡർ';

  @override
  String get labelDetailsCameraSection => 'ക്യാമറയും മെറ്റാഡാറ്റയും';

  @override
  String get bodyDetailsNoMetadata =>
      'ഈ ഫയലിൽ ക്യാമറ മെറ്റാഡാറ്റ കണ്ടെത്തിയില്ല.';

  @override
  String get labelDetailsCamera => 'ക്യാമറ';

  @override
  String get labelDetailsLens => 'ലെൻസ്';

  @override
  String get labelDetailsAperture => 'അപ്പേർച്ചർ';

  @override
  String get labelDetailsShutter => 'ഷട്ടർ';

  @override
  String get labelDetailsIso => 'ഐഎസ്ഒ';

  @override
  String get labelDetailsFocalLength => 'ഫോക്കൽ ദൈർഘ്യം';

  @override
  String get labelDetailsFlash => 'ഫ്ലാഷ്';

  @override
  String get labelDetailsWhiteBalance => 'വൈറ്റ് ബാലൻസ്';

  @override
  String get labelDetailsMeteringMode => 'മീറ്ററിംഗ് മോഡ്';

  @override
  String get labelDetailsColorSpace => 'കളർ സ്പേസ്';

  @override
  String get labelDetailsSoftware => 'സോഫ്റ്റ്‌വെയർ';

  @override
  String get labelDetailsLocation => 'സ്ഥലം';

  @override
  String get labelDetailsAltitude => 'ഉയരം';

  @override
  String get titleEditor => 'മാറ്റം വരുത്തുക';

  @override
  String get titleEditorOpen => 'മാറ്റം വരുത്തുക';

  @override
  String get labelEditorSave => 'പകർപ്പ് സേവ് ചെയ്യുക';

  @override
  String get bodyEditorSaving => 'പകർപ്പ് സേവ് ചെയ്യുന്നു...';

  @override
  String bodyEditorSaved(String fileName) {
    return 'പകർപ്പ് സേവ് ചെയ്തു: $fileName';
  }

  @override
  String get errorEditorSaveFailed => 'പകർപ്പ് സേവ് ചെയ്യാൻ കഴിഞ്ഞില്ല';

  @override
  String get bodyEditorOriginalKept => 'നിങ്ങളുടെ യഥാർഥ ചിത്രത്തിന് മാറ്റമില്ല';

  @override
  String get bodyEditorCannotOpen => 'ഈ ചിത്രത്തിൽ മാറ്റം വരുത്താൻ കഴിയില്ല';

  @override
  String get bodyEditorTooLarge =>
      'ഈ ചിത്രം ഈ ഉപകരണത്തിൽ എഡിറ്റ് ചെയ്യാൻ വളരെ വലുതാണ്';

  @override
  String get errorEditorPreviewFailed => 'പ്രിവ്യൂ വരയ്ക്കാൻ കഴിഞ്ഞില്ല';

  @override
  String get tooltipEditorUndo => 'പഴയപടിയാക്കുക';

  @override
  String get tooltipEditorRedo => 'വീണ്ടും ചെയ്യുക';

  @override
  String get tooltipEditorResetAll => 'എല്ലാം പഴയപടിയാക്കുക';

  @override
  String get titleEditorDiscard => 'മാറ്റങ്ങൾ ഉപേക്ഷിക്കണോ?';

  @override
  String get bodyEditorDiscardMessage =>
      'നിങ്ങളുടെ മാറ്റങ്ങൾ സേവ് ചെയ്തിട്ടില്ല. ഇപ്പോൾ പോയാൽ അവ നഷ്ടമാകും.';

  @override
  String get actionEditorDiscard => 'ഉപേക്ഷിക്കുക';

  @override
  String get actionEditorKeepEditing => 'തുടർന്ന് എഡിറ്റ് ചെയ്യുക';

  @override
  String get labelEditorToolCrop => 'ക്രോപ്പ്';

  @override
  String get labelEditorToolTune => 'വെളിച്ചം';

  @override
  String get labelEditorToolMasks => 'മാസ്കുകൾ';

  @override
  String get labelEditorToolFilters => 'ഫിൽട്ടറുകൾ';

  @override
  String get labelEditorToolMarkup => 'വരയ്ക്കുക';

  @override
  String get labelEditorToolRedact => 'മറയ്ക്കുക';

  @override
  String get labelEditorToolWatermark => 'വാട്ടർമാർക്ക്';

  @override
  String get labelCropAspectFree => 'സ്വതന്ത്രം';

  @override
  String get labelCropAspectOriginal => 'യഥാർഥം';

  @override
  String get labelCropAspectSquare => 'സമചതുരം';

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
  String get tooltipCropRotateLeft => 'ഇടത്തോട്ട് തിരിക്കുക';

  @override
  String get tooltipCropRotateRight => 'വലത്തോട്ട് തിരിക്കുക';

  @override
  String get tooltipCropFlipHorizontal => 'വശങ്ങൾ മാറ്റുക';

  @override
  String get tooltipCropFlipVertical => 'മുകളും താഴെയും മാറ്റുക';

  @override
  String get labelCropStraighten => 'നേരെയാക്കുക';

  @override
  String get labelCropPerspectiveVertical => 'കുത്തനെയുള്ള ചരിവ്';

  @override
  String get labelCropPerspectiveHorizontal => 'വിലങ്ങനെയുള്ള ചരിവ്';

  @override
  String get actionCropReset => 'ക്രോപ്പ് പഴയപടിയാക്കുക';

  @override
  String get labelToneExposure => 'വെളിച്ചം';

  @override
  String get labelToneContrast => 'വൈരുധ്യം';

  @override
  String get labelToneHighlights => 'തെളിഞ്ഞ ഭാഗങ്ങൾ';

  @override
  String get labelToneShadows => 'ഇരുണ്ട ഭാഗങ്ങൾ';

  @override
  String get labelToneTemperature => 'ചൂട്';

  @override
  String get labelToneTint => 'നിറച്ചായ്‌വ്';

  @override
  String get labelToneVibrance => 'നിറത്തിളക്കം';

  @override
  String get labelToneSaturation => 'നിറസാന്ദ്രത';

  @override
  String get actionToneReset => 'വെളിച്ചം പഴയപടിയാക്കുക';

  @override
  String get labelToneCurves => 'കർവുകൾ';

  @override
  String get labelCurveChannelRgb => 'എല്ലാം';

  @override
  String get labelCurveChannelRed => 'ചുവപ്പ്';

  @override
  String get labelCurveChannelGreen => 'പച്ച';

  @override
  String get labelCurveChannelBlue => 'നീല';

  @override
  String get actionCurveReset => 'കർവ് പഴയപടിയാക്കുക';

  @override
  String get helpCurveAddHint =>
      'പോയിന്റ് ചേർക്കാൻ തൊടുക, മാറ്റാൻ അമർത്തിപ്പിടിക്കുക';

  @override
  String get labelMaskShapeLinear => 'ലീനിയർ';

  @override
  String get labelMaskShapeRadial => 'റേഡിയൽ';

  @override
  String get labelMaskFeather => 'ഫെദർ';

  @override
  String get labelMaskInvert => 'വിപരീതം';

  @override
  String get labelMaskBlur => 'മങ്ങൽ';

  @override
  String get tooltipMaskAddLinear => 'ലീനിയർ ഗ്രേഡിയന്റ് ചേർക്കുക';

  @override
  String get tooltipMaskAddRadial => 'റേഡിയൽ മാസ്ക് ചേർക്കുക';

  @override
  String get emptyMask => 'മാസ്ക് ചേർക്കാൻ + തൊടുക';

  @override
  String get titleHsl => 'എച്ച്.എസ്.എൽ കളർ ട്യൂണർ';

  @override
  String get labelHslHue => 'നിറം';

  @override
  String get labelHslSaturation => 'സാന്ദ്രത';

  @override
  String get labelHslLuminance => 'തെളിച്ചം';

  @override
  String get actionHslReset => 'എച്ച്.എസ്.എൽ പഴയപടിയാക്കുക';

  @override
  String get labelHslRangeRed => 'ചുവപ്പ്';

  @override
  String get labelHslRangeOrange => 'ഓറഞ്ച്';

  @override
  String get labelHslRangeYellow => 'മഞ്ഞ';

  @override
  String get labelHslRangeGreen => 'പച്ച';

  @override
  String get labelHslRangeCyan => 'സയൻ';

  @override
  String get labelHslRangeBlue => 'നീല';

  @override
  String get labelHslRangePurple => 'പർപ്പിൾ';

  @override
  String get labelHslRangeMagenta => 'മജന്ത';

  @override
  String get labelFilterNone => 'യഥാർഥം';

  @override
  String get labelFilterMono => 'കറുപ്പും വെളുപ്പും';

  @override
  String get labelFilterSepia => 'സെപിയ';

  @override
  String get labelFilterVintage => 'പഴമ';

  @override
  String get labelFilterVivid => 'തിളക്കം';

  @override
  String get labelFilterCool => 'തണുപ്പ്';

  @override
  String get labelFilterWarm => 'ചൂട്';

  @override
  String get labelFilterFade => 'മങ്ങൽ';

  @override
  String get labelFilterIntensity => 'കരുത്ത്';

  @override
  String get labelMarkupFreehand => 'വരയ്ക്കുക';

  @override
  String get labelMarkupRectangle => 'ദീർഘചതുരം';

  @override
  String get labelMarkupEllipse => 'വൃത്തം';

  @override
  String get labelMarkupLine => 'വര';

  @override
  String get labelMarkupArrow => 'അമ്പ്';

  @override
  String get labelMarkupText => 'എഴുത്ത്';

  @override
  String get labelMarkupColor => 'നിറം';

  @override
  String get labelMarkupThickness => 'കനം';

  @override
  String get titleMarkupFilled => 'ഉള്ളിൽ നിറയ്ക്കുക';

  @override
  String get actionMarkupUndoLayer => 'അവസാനത്തേത് നീക്കുക';

  @override
  String get titleMarkupText => 'എഴുത്ത് ചേർക്കുക';

  @override
  String get helpMarkupTextHint => 'നിങ്ങളുടെ എഴുത്ത് ടൈപ്പ് ചെയ്യുക';

  @override
  String get actionMarkupTextAdd => 'ചേർക്കുക';

  @override
  String get helpMarkupHint => 'വരയ്ക്കാൻ ചിത്രത്തിൽ വലിക്കുക';

  @override
  String get labelRedactBlur => 'മങ്ങിക്കുക';

  @override
  String get labelRedactPixelate => 'കട്ടകളാക്കുക';

  @override
  String get labelRedactBlackout => 'കറുപ്പിക്കുക';

  @override
  String get labelRedactStrength => 'കരുത്ത്';

  @override
  String get helpRedactHint => 'മറയ്ക്കേണ്ട ഭാഗത്തിന് മുകളിൽ വലിക്കുക';

  @override
  String get actionRedactRemoveLast => 'അവസാനത്തേത് നീക്കുക';

  @override
  String bodyRedactCount(int count) {
    return '$count ഭാഗങ്ങൾ മറച്ചു';
  }

  @override
  String get labelWatermarkNone => 'ഒന്നുമില്ല';

  @override
  String get labelWatermarkText => 'എഴുത്ത്';

  @override
  String get labelWatermarkTimestamp => 'തീയതിയും സമയവും';

  @override
  String get labelWatermarkLogo => 'ലോഗോ';

  @override
  String get helpWatermarkTextHint => 'വാട്ടർമാർക്ക് എഴുത്ത്';

  @override
  String get labelWatermarkPosition => 'സ്ഥാനം';

  @override
  String get labelWatermarkOpacity => 'സുതാര്യത';

  @override
  String get labelWatermarkSize => 'വലുപ്പം';

  @override
  String get labelWatermarkMargin => 'അരികിൽ നിന്നുള്ള അകലം';

  @override
  String get actionWatermarkPickLogo => 'ഒരു ലോഗോ ഫയൽ തിരഞ്ഞെടുക്കുക';

  @override
  String get bodyWatermarkNoLogo => 'ലോഗോ തിരഞ്ഞെടുത്തിട്ടില്ല';

  @override
  String get labelPositionTopLeft => 'മുകളിൽ ഇടത്';

  @override
  String get labelPositionTopCenter => 'മുകളിൽ നടുവിൽ';

  @override
  String get labelPositionTopRight => 'മുകളിൽ വലത്';

  @override
  String get labelPositionCenterLeft => 'നടുവിൽ ഇടത്';

  @override
  String get labelPositionCenter => 'നടുവിൽ';

  @override
  String get labelPositionCenterRight => 'നടുവിൽ വലത്';

  @override
  String get labelPositionBottomLeft => 'താഴെ ഇടത്';

  @override
  String get labelPositionBottomCenter => 'താഴെ നടുവിൽ';

  @override
  String get labelPositionBottomRight => 'താഴെ വലത്';

  @override
  String get titleConvertOpen => 'മാറ്റുക';

  @override
  String get titleConvert => 'മാറ്റവും വലുപ്പവും';

  @override
  String get bodyConvertCannotOpen => 'ഈ ഫയൽ മാറ്റാൻ കഴിയില്ല';

  @override
  String get bodyConvertTooLarge => 'ഈ ഫയൽ മാറ്റാൻ പറ്റാത്തത്ര വലുതാണ്';

  @override
  String get bodyConvertUnreadable => 'ഈ ചിത്രം വായിക്കാൻ കഴിഞ്ഞില്ല';

  @override
  String get labelConvertFormat => 'ഫോർമാറ്റ്';

  @override
  String get labelConvertQuality => 'ഗുണനിലവാരം';

  @override
  String get labelConvertResize => 'വലുപ്പം';

  @override
  String get labelConvertResizeNone => 'യഥാർത്ഥം';

  @override
  String get labelConvertResizeLongestSide => 'നീളമുള്ള വശം';

  @override
  String get labelConvertResizePercent => 'ശതമാനം';

  @override
  String get labelConvertResizeExact => 'വീതിയും ഉയരവും';

  @override
  String get titleConvertKeepAspect => 'രൂപം നിലനിർത്തുക';

  @override
  String get labelConvertWidth => 'വീതി';

  @override
  String get labelConvertHeight => 'ഉയരം';

  @override
  String get labelConvertLongestSide => 'നീളമുള്ള വശം പിക്സലിൽ';

  @override
  String get labelConvertPercent => 'യഥാർത്ഥത്തിന്റെ ശതമാനം';

  @override
  String get titleConvertStripMetadata => 'ക്യാമറ വിവരങ്ങൾ നീക്കുക';

  @override
  String get helpConvertStripMetadataHint =>
      'സ്ഥലവും ക്യാമറ ക്രമീകരണവും പകർപ്പിൽ ഉൾപ്പെടുത്തില്ല';

  @override
  String get labelConvertOriginalSize => 'യഥാർത്ഥം';

  @override
  String get labelConvertNewSize => 'പുതിയ പകർപ്പ്';

  @override
  String get bodyConvertEstimating => 'വലുപ്പം കണക്കാക്കുന്നു';

  @override
  String get bodyConvertNoEstimate => 'ഈ ഫയലിന്റെ വലുപ്പം കണക്കാക്കാൻ കഴിയില്ല';

  @override
  String get bodyConvertLargerWarning => 'പകർപ്പ് യഥാർത്ഥത്തേക്കാൾ വലുതാണ്';

  @override
  String get labelConvertSave => 'ഒരു പകർപ്പ് സൂക്ഷിക്കുക';

  @override
  String get labelConvertSaving => 'സൂക്ഷിക്കുന്നു';

  @override
  String get errorConvertFailed => 'പകർപ്പ് സൂക്ഷിക്കാൻ കഴിഞ്ഞില്ല';

  @override
  String get bodyConvertOriginalKept => 'നിങ്ങളുടെ യഥാർത്ഥ ഫയൽ മാറുന്നില്ല';

  @override
  String get tooltipPdfOpen => 'PDF ആയി കയറ്റുമതി ചെയ്യുക';

  @override
  String get titlePdfExport => 'PDF ആയി കയറ്റുമതി ചെയ്യുക';

  @override
  String get labelPdfChoosePhotos => 'ചിത്രങ്ങൾ തിരഞ്ഞെടുക്കുക';

  @override
  String get bodyPdfNoSelection => 'കുറഞ്ഞത് ഒരു ചിത്രമെങ്കിലും തിരഞ്ഞെടുക്കുക';

  @override
  String get bodyPdfNoPhotos => 'തിരഞ്ഞെടുക്കാൻ ചിത്രങ്ങളൊന്നുമില്ല';

  @override
  String get labelPdfPageSize => 'പേജ് വലുപ്പം';

  @override
  String get labelPdfPageA4 => 'A4';

  @override
  String get labelPdfPageLetter => 'ലെറ്റർ';

  @override
  String get labelPdfPageFitImage => 'ചിത്രത്തിന് അനുസരിച്ച്';

  @override
  String get labelPdfOrientation => 'ദിശ';

  @override
  String get labelPdfOrientationPortrait => 'നെടുകെ';

  @override
  String get labelPdfOrientationLandscape => 'കുറുകെ';

  @override
  String get labelPdfOrientationAuto => 'ചിത്രം അനുസരിച്ച്';

  @override
  String get labelPdfFit => 'സ്ഥാനം';

  @override
  String get labelPdfFitContain => 'മുഴുവൻ ചിത്രവും';

  @override
  String get labelPdfFitFill => 'പേജ് നിറയ്ക്കുക';

  @override
  String get labelPdfMargin => 'അതിര്';

  @override
  String get labelPdfMarginNone => 'ഒന്നുമില്ല';

  @override
  String get labelPdfMarginSmall => 'ചെറുത്';

  @override
  String get labelPdfMarginMedium => 'ഇടത്തരം';

  @override
  String get labelPdfMarginLarge => 'വലുത്';

  @override
  String get labelPdfQuality => 'ചിത്ര ഗുണനിലവാരം';

  @override
  String get actionPdfExport => 'PDF ഉണ്ടാക്കുക';

  @override
  String get labelPdfExporting => 'PDF ഉണ്ടാക്കുന്നു';

  @override
  String get errorPdfFailed => 'PDF ഉണ്ടാക്കാൻ കഴിഞ്ഞില്ല';

  @override
  String get titleVideoToolsOpen => 'വീഡിയോ ഉപകരണങ്ങൾ';

  @override
  String get titleVideoTools => 'വീഡിയോ ഉപകരണങ്ങൾ';

  @override
  String get bodyVideoToolsUnavailable => 'ഈ ക്ലിപ്പ് വായിക്കാൻ കഴിഞ്ഞില്ല';

  @override
  String get tabVideoTabFrame => 'ഫ്രെയിം';

  @override
  String get tabVideoTabGif => 'GIF';

  @override
  String get tabVideoTabTrim => 'മുറിക്കുക';

  @override
  String get labelFramePosition => 'ക്ലിപ്പിലെ സ്ഥാനം';

  @override
  String get labelFrameFormat => 'ഇങ്ങനെ സൂക്ഷിക്കുക';

  @override
  String get actionFrameSave => 'ഈ ഫ്രെയിം സൂക്ഷിക്കുക';

  @override
  String get bodyFrameUnavailable => 'ഇവിടെ ഫ്രെയിം വായിക്കാൻ കഴിഞ്ഞില്ല';

  @override
  String get labelGifFrameRate => 'സെക്കൻഡിൽ ഫ്രെയിമുകൾ';

  @override
  String get labelGifSize => 'വലുപ്പം';

  @override
  String get titleGifLoopLabel => 'ആവർത്തിച്ച് കാണിക്കുക';

  @override
  String get bodyGifCapped => 'ഫയൽ ചെറുതാക്കാൻ GIF കുറയ്ക്കുന്നു';

  @override
  String get actionGifExport => 'GIF ഉണ്ടാക്കുക';

  @override
  String get labelGifExporting => 'GIF ഉണ്ടാക്കുന്നു';

  @override
  String get labelTrimStart => 'തുടക്കം';

  @override
  String get labelTrimEnd => 'അവസാനം';

  @override
  String get labelTrimLength => 'ദൈർഘ്യം';

  @override
  String get actionTrim => 'മുറിച്ച ക്ലിപ്പ് സൂക്ഷിക്കുക';

  @override
  String get bodyTrimLosslessNote =>
      'വീണ്ടും എൻകോഡ് ചെയ്യുന്നില്ല, അതിനാൽ ഗുണനിലവാരം നഷ്ടപ്പെടുന്നില്ല.';

  @override
  String get bodyTrimTooShort => 'തിരഞ്ഞെടുത്ത ഭാഗം വളരെ ചെറുതാണ്';

  @override
  String get labelVideoWorking => 'പ്രവർത്തിക്കുന്നു';

  @override
  String get errorVideoJobFailed => 'ഇത് പൂർത്തിയാക്കാൻ കഴിഞ്ഞില്ല';

  @override
  String bodyConvertPixelSize(int width, int height) {
    return '$width x $height പിക്സൽ';
  }

  @override
  String bodyConvertSmallerBy(int percent) {
    return '$percent ശതമാനം ചെറുത്';
  }

  @override
  String bodyConvertSavedAs(String name) {
    return '$name ആയി സൂക്ഷിച്ചു';
  }

  @override
  String bodyPdfSelectedCount(int count) {
    return '$count തിരഞ്ഞെടുത്തു';
  }

  @override
  String bodyPdfMaxPagesReached(int count) {
    return 'ഒരു PDF-ൽ $count ചിത്രങ്ങൾ മാത്രമേ ഉൾകൊള്ളൂ';
  }

  @override
  String bodyPdfExportedAs(String name, int pages) {
    return '$pages പേജുകളുള്ള $name സൂക്ഷിച്ചു';
  }

  @override
  String bodyPdfSkippedCount(int count) {
    return '$count ചിത്രങ്ങൾ വായിക്കാൻ കഴിയാതതിനാൽ ഒഴിവാക്കി';
  }

  @override
  String bodyGifFrameCount(int count) {
    return '$count ഫ്രെയിമുകൾ';
  }

  @override
  String bodyVideoJobSavedAs(String name) {
    return '$name ആയി സൂക്ഷിച്ചു';
  }

  @override
  String get titleSearch => 'തിരയുക';

  @override
  String get tooltipSearchOpen => 'തിരയുക';

  @override
  String get helpSearchHint => 'പേരുകൾ, ടാഗുകൾ, കുറിപ്പുകൾ, സ്ഥലങ്ങൾ തിരയുക';

  @override
  String get tooltipSearchClear => 'മായ്ക്കുക';

  @override
  String get tooltipSearchFilters => 'അരിപ്പകൾ';

  @override
  String get titleSearchStart => 'നിങ്ങളുടെ ശേഖരം തിരയുക';

  @override
  String get bodySearchStart =>
      'പേരുകൾ, ടാഗുകൾ, കുറിപ്പുകൾ, ക്യാമറ, സ്ഥലം എന്നിവയിൽ തിരയാം. കൂടുതൽ കൃത്യമാക്കാൻ ഒരു വാക്ക് tag:, type:, place:, camera:, before:, after: എന്നിവയിൽ ഒന്നുകൊണ്ട് തുടങ്ങുക.';

  @override
  String get titleSearchNoResults => 'ഒന്നും കണ്ടെത്തിയില്ല';

  @override
  String get bodySearchNoResults =>
      'കുറച്ച് വാക്കുകൾ ഉപയോഗിക്കുക, അല്ലെങ്കിൽ അരിപ്പകൾ പരിശോധിക്കുക.';

  @override
  String get errorSearchFailed => 'തിരയൽ നടത്താൻ കഴിഞ്ഞില്ല';

  @override
  String get titleSearchRecent => 'അടുത്തിടെ തിരഞ്ഞവ';

  @override
  String get actionSearchRecentClear => 'എല്ലാം മായ്ക്കുക';

  @override
  String get tooltipSearchRecentRemove => 'ഈ തിരയൽ മറക്കുക';

  @override
  String bodySearchResultCount(int count) {
    return '$count ഫലങ്ങൾ';
  }

  @override
  String get bodySearchMatchedInName => 'ഫയൽ പേരുമായി ചേർന്നു';

  @override
  String get labelSearchMatchedInTags => 'ഒരു ടാഗുമായി ചേർന്നു';

  @override
  String get labelSearchMatchedInNotes => 'ഒരു കുറിപ്പുമായി ചേർന്നു';

  @override
  String get labelSearchMatchedInPlace => 'ഒരു സ്ഥലവുമായി ചേർന്നു';

  @override
  String get bodySearchMatchedInDetails => 'ചിത്ര വിവരങ്ങളുമായി ചേർന്നു';

  @override
  String get tooltipFilterTitle => 'അരിപ്പകൾ';

  @override
  String get labelFilterMediaType => 'തരം';

  @override
  String get labelFilterTypeImage => 'ചിത്രങ്ങൾ';

  @override
  String get labelFilterTypeVideo => 'വീഡിയോകൾ';

  @override
  String get labelFilterTypeGif => 'GIF-കൾ';

  @override
  String get labelFilterTypeRaw => 'RAW';

  @override
  String get labelFilterTypeSvg => 'SVG';

  @override
  String get titleFilterFavoritesOnly => 'പ്രിയപ്പെട്ടവ മാത്രം';

  @override
  String get titleFilterHasLocation => 'സ്ഥലമുള്ളവ';

  @override
  String get labelFilterDateRange => 'തീയതി പരിധി';

  @override
  String get labelFilterDateAny => 'ഏത് തീയതിയും';

  @override
  String get actionFilterDateChoose => 'തീയതികൾ തിരഞ്ഞെടുക്കുക';

  @override
  String get actionFilterDateClear => 'തീയതികൾ മായ്ക്കുക';

  @override
  String get labelFilterTags => 'ടാഗുകൾ';

  @override
  String get actionFilterTagModeAll => 'എല്ലാം ഉള്ളവ';

  @override
  String get actionFilterTagModeAny => 'ഏതെങ്കിലും ഉള്ളവ';

  @override
  String get labelFilterNoTags => 'ടാഗുകൾ ഒന്നുമില്ല';

  @override
  String get actionFilterReset => 'പുനഃസജ്ജമാക്കുക';

  @override
  String get actionFilterApply => 'ബാധകമാക്കുക';

  @override
  String get titleTags => 'ടാഗുകൾ';

  @override
  String get titleTagsOpen => 'ടാഗുകൾ';

  @override
  String get titleTagsEmpty => 'ടാഗുകൾ ഒന്നുമില്ല';

  @override
  String get bodyTagsEmpty =>
      'നിങ്ങളുടെ ഇഷ്ടപ്രകാരം ചിത്രങ്ങൾ കൂട്ടിയിടാൻ ഒരു ടാഗ് ഉണ്ടാക്കുക.';

  @override
  String get actionTagNew => 'പുതിയ ടാഗ്';

  @override
  String get tooltipTagEditTitle => 'ടാഗ് തിരുത്തുക';

  @override
  String get labelTagName => 'ടാഗിന്റെ പേര്';

  @override
  String get labelTagColor => 'നിറം';

  @override
  String get actionTagSave => 'സൂക്ഷിക്കുക';

  @override
  String get actionTagCancel => 'റദ്ദാക്കുക';

  @override
  String get tooltipTagDelete => 'ഇല്ലാതാക്കുക';

  @override
  String get titleTagDelete => 'ഈ ടാഗ് ഇല്ലാതാക്കണോ?';

  @override
  String get bodyTagDelete =>
      'ഈ ടാഗ് ഉള്ള എല്ലാ ചിത്രങ്ങളിൽ നിന്നും അത് നീക്കും. ഒരു ചിത്രവും ഇല്ലാതാകില്ല.';

  @override
  String descTagItemCount(int count) {
    return '$count ഇനങ്ങൾ';
  }

  @override
  String get emptyTagError => 'ടാഗിന് ഒരു പേര് വേണം';

  @override
  String get bodyTagErrorTooLong => 'ആ പേര് വളരെ നീളമുള്ളതാണ്';

  @override
  String get bodyTagErrorDuplicate => 'ആ ടാഗ് ഇതിനകം ഉണ്ട്';

  @override
  String get errorTagErrorFailed => 'ടാഗ് സൂക്ഷിക്കാൻ കഴിഞ്ഞില്ല';

  @override
  String get titleTagSheet => 'ഈ ഇനത്തിലെ ടാഗുകൾ';

  @override
  String get helpTagSheetNewHint => 'ഒരു പുതിയ ടാഗ് ചേർക്കുക';

  @override
  String get actionTagSheetAdd => 'ചേർക്കുക';

  @override
  String get actionTagSheetDone => 'കഴിഞ്ഞു';

  @override
  String get titleTagSheetOpen => 'ടാഗുകൾ';

  @override
  String get titleCleaner => 'ഇരട്ട ഫയൽ വൃത്തിയാക്കൽ';

  @override
  String get titleCleanerOpen => 'ഇരട്ട ഫയൽ വൃത്തിയാക്കൽ';

  @override
  String get labelCleanerStart => 'ഇരട്ടകൾ കണ്ടെത്തുക';

  @override
  String get actionCleanerStop => 'നിർത്തുക';

  @override
  String get labelCleanerRescan => 'വീണ്ടും പരിശോധിക്കുക';

  @override
  String get titleCleanerIdle => 'ഇരട്ട ചിത്രങ്ങൾ കണ്ടെത്തുക';

  @override
  String get bodyCleanerIdle =>
      'ഓരോ ഫയലും ഒരു തവണ വായിച്ച് ഫലം ഓർത്തുവയ്ക്കും, അതിനാൽ അടുത്ത തവണ പരിശോധന വേഗത്തിലാകും.';

  @override
  String bodyCleanerScanning(int processed, int total) {
    return '$total-ൽ $processed പരിശോധിച്ചു';
  }

  @override
  String get labelCleanerGrouping => 'പകർപ്പുകൾ കൂട്ടിയിടുന്നു';

  @override
  String get labelCleanerCancelled => 'പരിശോധന നിർത്തി';

  @override
  String get errorCleanerFailed => 'പരിശോധന പൂർത്തിയാക്കാൻ കഴിഞ്ഞില്ല';

  @override
  String get titleCleanerNone => 'ഇരട്ടകൾ ഒന്നും കണ്ടെത്തിയില്ല';

  @override
  String get bodyCleanerNone =>
      'നിങ്ങളുടെ ശേഖരത്തിൽ ഒന്നും മറ്റൊന്നിന്റെ പകർപ്പായി തോന്നുന്നില്ല.';

  @override
  String bodyCleanerGroupsFound(int count) {
    return 'പകർപ്പുകളുടെ $count കൂട്ടങ്ങൾ';
  }

  @override
  String bodyCleanerReclaimable(String size) {
    return 'ഏകദേശം $size ഒഴിവാക്കാം';
  }

  @override
  String bodyCleanerFailures(int count) {
    return '$count ഫയലുകൾ വായിക്കാൻ കഴിയാതെ ഒഴിവാക്കി';
  }

  @override
  String get labelCleanerKindExact => 'ഒരേ ഫയലുകൾ';

  @override
  String get labelCleanerKindSimilar => 'കാഴ്ചയിൽ ഒരുപോലെ';

  @override
  String bodyCleanerMemberCount(int count) {
    return '$count പകർപ്പുകൾ';
  }

  @override
  String get actionCleanerCompare => 'താരതമ്യം';

  @override
  String get titleCompare => 'പകർപ്പുകൾ താരതമ്യം ചെയ്യുക';

  @override
  String get bodyCompareGroupGone => 'ഈ കൂട്ടം ഇതിനകം കൈകാര്യം ചെയ്തു';

  @override
  String get actionCompareKeepThis => 'ഇത് സൂക്ഷിക്കുക';

  @override
  String get labelCompareBestBadge => 'നിർദ്ദേശിച്ചത്';

  @override
  String bodyCompareKeepAndTrash(int count) {
    return '1 സൂക്ഷിക്കുക, $count എണ്ണം ചവറ്റുകുട്ടയിലേക്ക്';
  }

  @override
  String get bodyCompareTrashNotice =>
      'ഒന്നും മായ്ക്കുന്നില്ല. മറ്റ് പകർപ്പുകൾ ചവറ്റുകുട്ടയിലേക്ക് പോകും, തിരികെ എടുക്കാം.';

  @override
  String titleCompareConfirm(int count) {
    return '$count പകർപ്പുകൾ ചവറ്റുകുട്ടയിലേക്ക് മാറ്റണോ?';
  }

  @override
  String get bodyCompareConfirm =>
      'നിങ്ങൾ സൂക്ഷിച്ച പകർപ്പ് മാത്രം ഗാലറിയിൽ തുടരും. ഫയലുകൾ ഉപകരണത്തിൽ തന്നെ ഇരിക്കും, തിരികെ എടുക്കാം.';

  @override
  String get actionCompareConfirm => 'ചവറ്റുകുട്ടയിലേക്ക് മാറ്റുക';

  @override
  String get actionCompareCancel => 'റദ്ദാക്കുക';

  @override
  String bodyCompareMoved(int count) {
    return '$count പകർപ്പുകൾ ചവറ്റുകുട്ടയിലേക്ക് മാറ്റി';
  }

  @override
  String get errorCompareFailed => 'പകർപ്പുകൾ മാറ്റാൻ കഴിഞ്ഞില്ല';

  @override
  String get labelCompareFieldSize => 'വലുപ്പം';

  @override
  String get labelCompareFieldPixels => 'പിക്സലുകൾ';

  @override
  String get labelCompareFieldDate => 'തീയതി';

  @override
  String get labelCompareFieldCamera => 'ക്യാമറ';

  @override
  String get labelCompareUnknown => 'അറിയില്ല';

  @override
  String get titleAlbums => 'ആൽബങ്ങൾ';

  @override
  String get labelAlbumsSectionMine => 'എന്റെ ആൽബങ്ങൾ';

  @override
  String get labelAlbumsSectionSmart => 'സ്മാർട്ട് ആൽബങ്ങൾ';

  @override
  String get labelAlbumsSectionFolders => 'ഉപകരണ ഫോൾഡറുകൾ';

  @override
  String get titleAlbumsEmpty => 'ഇതുവരെ ആൽബങ്ങളില്ല';

  @override
  String get bodyAlbumsEmpty =>
      'ഫോട്ടോകളും വീഡിയോകളും നിങ്ങളുടെ രീതിയിൽ ഒരുമിച്ചു ചേർക്കാൻ ഒരു ആൽബം ഉണ്ടാക്കുക. ഫയലുകൾ ഇപ്പോഴുള്ള സ്ഥലത്തുതന്നെ നിൽക്കും.';

  @override
  String get emptyAlbumsFolders => 'ഫോൾഡറുകളൊന്നും കണ്ടെത്തിയില്ല';

  @override
  String get errorAlbumsLoadFailed => 'ആൽബങ്ങൾ എടുക്കാൻ കഴിഞ്ഞില്ല';

  @override
  String descAlbumItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഇനങ്ങൾ',
      one: '1 ഇനം',
      zero: 'ശൂന്യം',
    );
    return '$_temp0';
  }

  @override
  String get labelSmartAlbumFavorites => 'പ്രിയപ്പെട്ടവ';

  @override
  String get labelSmartAlbumVideos => 'വീഡിയോകൾ';

  @override
  String get labelSmartAlbumGifs => 'ആനിമേറ്റഡും GIF-ഉം';

  @override
  String get labelSmartAlbumRaw => 'RAW ചിത്രങ്ങൾ';

  @override
  String get labelSmartAlbumPanoramas => 'പനോരമകൾ';

  @override
  String get labelSmartAlbumRecent => 'അടുത്തിടെ ചേർത്തവ';

  @override
  String get labelSmartAlbumTrash => 'ചവറ്റുകുട്ട';

  @override
  String get actionAlbumNew => 'പുതിയ ആൽബം';

  @override
  String get titleAlbumCreate => 'പുതിയ ആൽബം';

  @override
  String get titleAlbumRenameTitle => 'ആൽബത്തിന്റെ പേര് മാറ്റുക';

  @override
  String get labelAlbumName => 'ആൽബത്തിന്റെ പേര്';

  @override
  String get helpAlbumNameHint => 'അവധിക്കാലം 2026';

  @override
  String get labelAlbumSave => 'സൂക്ഷിക്കുക';

  @override
  String get actionAlbumCancel => 'റദ്ദാക്കുക';

  @override
  String get titleAlbumRename => 'പേര് മാറ്റുക';

  @override
  String get titleAlbumDelete => 'ആൽബം ഇല്ലാതാക്കുക';

  @override
  String get titleAlbumChooseCover => 'കവർ തിരഞ്ഞെടുക്കുക';

  @override
  String get titleAlbumReorder => 'ക്രമം മാറ്റുക';

  @override
  String get titleAlbumRemoveMedia => 'ആൽബത്തിൽ നിന്ന് നീക്കുക';

  @override
  String get titleAlbumPin => 'മുകളിൽ പിൻ ചെയ്യുക';

  @override
  String get emptyAlbumError => 'ആൽബത്തിന് ഒരു പേര് വേണം';

  @override
  String get bodyAlbumErrorTooLong => 'ആ പേര് വളരെ നീളമുള്ളതാണ്';

  @override
  String get bodyAlbumErrorDuplicate => 'ആ പേരിൽ ഒരു ആൽബം ഇതിനകം ഉണ്ട്';

  @override
  String get errorAlbumErrorFailed => 'ആ മാറ്റം സൂക്ഷിക്കാൻ കഴിഞ്ഞില്ല';

  @override
  String titleAlbumDeleteConfirm(String name) {
    return '\"$name\" ഇല്ലാതാക്കണോ?';
  }

  @override
  String get bodyAlbumDeleteConfirm =>
      'ആൽബം മാത്രമേ പോകൂ. എല്ലാ ഫോട്ടോകളും വീഡിയോകളും ഉപകരണത്തിൽ ഇപ്പോഴുള്ള സ്ഥലത്തുതന്നെ നിൽക്കും.';

  @override
  String get actionAlbumDeleteConfirm => 'ആൽബം ഇല്ലാതാക്കുക';

  @override
  String get bodyAlbumDeleted => 'ആൽബം ഇല്ലാതാക്കി';

  @override
  String get bodyAlbumRemovedFromAlbum => 'ആൽബത്തിൽ നിന്ന് നീക്കി';

  @override
  String get bodyAlbumCoverSet => 'കവർ പുതുക്കി';

  @override
  String get bodyAlbumOrderSaved => 'പുതിയ ക്രമം സൂക്ഷിച്ചു';

  @override
  String get titleAlbumEmpty => 'ഈ ആൽബം ശൂന്യമാണ്';

  @override
  String get bodyAlbumEmpty =>
      'ഗാലറിയിൽ നിന്ന് ഫോട്ടോകളും വീഡിയോകളും ചേർക്കുക. അവ നീക്കുകയോ പകർത്തുകയോ ചെയ്യില്ല.';

  @override
  String get bodyAlbumGone => 'ഈ ആൽബം ഇപ്പോൾ ഇല്ല';

  @override
  String get titleAlbumReorderTitle => 'ക്രമം മാറ്റുക';

  @override
  String get helpAlbumReorderHint =>
      'ഒരു ഇനം നീക്കാൻ അത് വലിച്ചിടുക. സൂക്ഷിക്കുക അമർത്തുമ്പോൾ പുതിയ ക്രമം സൂക്ഷിക്കും.';

  @override
  String get actionAlbumReorderSave => 'ക്രമം സൂക്ഷിക്കുക';

  @override
  String get titleAlbumCover => 'ഒരു കവർ തിരഞ്ഞെടുക്കുക';

  @override
  String get actionAlbumCoverClear => 'ഏറ്റവും പുതിയ ഇനം ഉപയോഗിക്കുക';

  @override
  String get titleAlbumPicker => 'ആൽബത്തിൽ ചേർക്കുക';

  @override
  String get emptyAlbumPicker => 'നിങ്ങൾക്ക് ഇതുവരെ ആൽബങ്ങളില്ല';

  @override
  String get actionAlbumPickerCreate => 'പുതിയ ആൽബം';

  @override
  String get actionAlbumPickerDone => 'പൂർത്തിയായി';

  @override
  String get bodyAlbumPickerSaved => 'ആൽബങ്ങൾ പുതുക്കി';

  @override
  String get titleFolderEmpty => 'ഈ ഫോൾഡർ ശൂന്യമാണ്';

  @override
  String get titleSmartAlbumEmpty => 'ഇവിടെ ഇതുവരെ ഒന്നുമില്ല';

  @override
  String get bodySmartAlbumUnknown => 'ആ ആൽബം നിലവിലില്ല';

  @override
  String get titleFilterHasTags => 'ടാഗ് ഉള്ളവ മാത്രം';

  @override
  String get labelFilterFileSize => 'ഫയൽ വലുപ്പം';

  @override
  String get labelFilterSizeAny => 'ഏത് വലുപ്പവും';

  @override
  String get labelFilterSizeSmall => '1 MB-യിൽ കുറവ്';

  @override
  String get bodyFilterSizeMedium => '1 മുതൽ 10 MB വരെ';

  @override
  String get labelFilterSizeLarge => '10 MB-യിൽ കൂടുതൽ';

  @override
  String get labelFilterSortBy => 'ക്രമീകരിക്കുക';

  @override
  String get labelFilterSortDateTaken => 'എടുത്ത തീയതി';

  @override
  String get labelFilterSortDateAdded => 'ചേർത്ത തീയതി';

  @override
  String get labelFilterSortName => 'പേര്';

  @override
  String get labelFilterSortSize => 'വലുപ്പം';

  @override
  String get actionFilterSortNewestFirst => 'പുതിയത് ആദ്യം';

  @override
  String get actionFilterSortOldestFirst => 'പഴയത് ആദ്യം';

  @override
  String get titleVault => 'സ്വകാര്യ വോള്‍ട്ട്';

  @override
  String get titleVaultMenuLabel => 'സ്വകാര്യ വോള്‍ട്ട്';

  @override
  String get titleVaultMoveToVault => 'വോള്‍ട്ടിലേക്ക് മാറ്റുക';

  @override
  String get titleVaultSetUp => 'നിങ്ങളുടെ വോള്‍ട്ട് ഉണ്ടാക്കുക';

  @override
  String get bodyVaultSetUp =>
      'ഇവിടേക്ക് മാറ്റുന്ന ഇനങ്ങള്‍ ഈ ഉപകരണം സൂക്ഷിക്കുന്ന ഒരു കീ ഉപയോഗിച്ച് എന്‍ക്രിപ്റ്റ് ചെയ്യപ്പെടുകയും ഗാലറിയില്‍ നിന്ന് മറയ്ക്കപ്പെടുകയും ചെയ്യും.';

  @override
  String get bodyVaultNoRecoveryWarning =>
      'മറന്നുപോയ പിന്‍ വീണ്ടെടുക്കാന്‍ വഴിയില്ല. അതില്ലാതെ ഈ ആപ്പിനു പോലും വോള്‍ട്ട് തുറക്കാനാവില്ല.';

  @override
  String get labelVaultChoosePin => 'ഒരു പിന്‍ തിരഞ്ഞെടുക്കുക';

  @override
  String get bodyVaultConfirmPin => 'പിന്‍ വീണ്ടും നല്‍കുക';

  @override
  String get labelVaultEnterPin => 'നിങ്ങളുടെ പിന്‍ നല്‍കുക';

  @override
  String get labelVaultCreate => 'വോള്‍ട്ട് ഉണ്ടാക്കുക';

  @override
  String get labelVaultUnlock => 'തുറക്കുക';

  @override
  String get labelVaultUseBiometrics => 'വിരലടയാളം ഉപയോഗിക്കുക';

  @override
  String get bodyVaultUnlockReason => 'സ്വകാര്യ വോള്‍ട്ട് തുറക്കുക';

  @override
  String get tooltipVaultLockNow => 'ഇപ്പോള്‍ പൂട്ടുക';

  @override
  String get bodyVaultPinMismatch => 'രണ്ട് പിന്നുകളും ഒന്നല്ല';

  @override
  String get bodyVaultWrongPin => 'പിന്‍ ശരിയല്ല';

  @override
  String bodyVaultAttemptsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ശ്രമങ്ങള്‍ ബാക്കി',
      one: '1 ശ്രമം ബാക്കി',
    );
    return '$_temp0';
  }

  @override
  String bodyVaultLockedOut(int seconds) {
    return 'ഒട്ടേറെ ശ്രമങ്ങള്‍. $seconds സെക്കന്‍റ് കാത്തിരിക്കുക.';
  }

  @override
  String bodyVaultPinTooShort(int count) {
    return 'പിന്നിന് കുറഞ്ഞത് $count അക്കങ്ങള്‍ വേണം';
  }

  @override
  String bodyVaultPinTooLong(int count) {
    return 'പിന്നിന് പരമാവധി $count അക്കങ്ങള്‍ മാത്രമേ പാടുള്ളൂ';
  }

  @override
  String get bodyVaultPinNotDigits => 'പിന്നില്‍ അക്കങ്ങള്‍ മാത്രമേ ആകാവൂ';

  @override
  String get bodyVaultPinAllSame => 'ഒരേ അക്കം ആവര്‍ത്തിക്കരുത്';

  @override
  String get bodyVaultPinSequential =>
      'തുടര്‍ച്ചയായി വരുന്ന അക്കങ്ങള്‍ ഉപയോഗിക്കരുത്';

  @override
  String get errorVaultBiometricFailed =>
      'തിരിച്ചറിഞ്ഞില്ല. നിങ്ങളുടെ പിന്‍ ഉപയോഗിക്കുക.';

  @override
  String get bodyVaultBiometricUnavailable =>
      'വിരലടയാളം ലഭ്യമല്ല. നിങ്ങളുടെ പിന്‍ ഉപയോഗിക്കുക.';

  @override
  String get errorVaultAuth => 'വോള്‍ട്ട് തുറക്കാനായില്ല';

  @override
  String get titleVaultKeystoreUnavailable =>
      'ഈ ഉപകരണത്തിന് വോള്‍ട്ട് കീ സൂക്ഷിക്കാനാവില്ല';

  @override
  String get bodyVaultKeystoreUnavailable =>
      'വോള്‍ട്ടിന് ഹാര്‍ഡ്‌വെയര്‍ കീ സ്റ്റോര്‍ വേണം, ഈ ഉപകരണത്തില്‍ അത് പ്രവര്‍ത്തനക്ഷമമല്ല. അതില്ലാതെ ഒന്നും എന്‍ക്രിപ്റ്റ് ചെയ്യാനാവില്ല, അതിനാല്‍ വോള്‍ട്ട് അടഞ്ഞു കിടക്കും.';

  @override
  String get titleVaultEmpty => 'വോള്‍ട്ട് കാലിയാണ്';

  @override
  String get bodyVaultEmpty =>
      'ചിത്രങ്ങളും വീഡിയോകളും ഇവിടെ ചേര്‍ത്താല്‍ അവ എന്‍ക്രിപ്റ്റ് ചെയ്യുകയും ഗാലറിയില്‍ നിന്ന് മാറ്റുകയും ചെയ്യും.';

  @override
  String bodyVaultSelectedCount(int count) {
    return '$count തിരഞ്ഞെടുത്തു';
  }

  @override
  String get labelVaultAddItems => 'ഇനങ്ങള്‍ ചേര്‍ക്കുക';

  @override
  String get tooltipVaultRestore => 'ഗാലറിയിലേക്ക് തിരികെ കൊണ്ടുവരിക';

  @override
  String get tooltipVaultDeleteForever => 'പൂര്‍ണ്ണമായി ഇല്ലാതാക്കുക';

  @override
  String get tooltipVaultSettingsAction => 'വോള്‍ട്ട് ക്രമീകരണങ്ങള്‍';

  @override
  String get actionVaultCancel => 'റദ്ദാക്കുക';

  @override
  String get tooltipVaultClearSelection => 'തിരഞ്ഞെടുപ്പ് മായ്ക്കുക';

  @override
  String get titleVaultImport => 'വോള്‍ട്ടിലേക്ക് മാറ്റുക';

  @override
  String get bodyVaultImport =>
      'ഇനങ്ങള്‍ എന്‍ക്രിപ്റ്റ് ചെയ്യപ്പെടുകയും ഗാലറിയില്‍ നിന്ന് മാറ്റുകയും ചെയ്യും. മൂല ഫയലുകള്‍ എന്തു ചെയ്യണം എന്നത് നിങ്ങള്‍ തീരുമാനിക്കുക.';

  @override
  String get titleVaultImportKeepOriginal => 'മൂല ഫയലുകള്‍ സൂക്ഷിക്കുക';

  @override
  String get bodyVaultImportKeepOriginal =>
      'മൂല ഫയലുകള്‍ അവിടെത്തന്നെ തുടരും. വേണമെങ്കില്‍ പിന്നീട് സ്വയം ഇല്ലാതാക്കാം.';

  @override
  String get titleVaultImportShredOriginal => 'മൂല ഫയലുകള്‍ നശിപ്പിക്കുക';

  @override
  String get bodyVaultImportShredOriginal =>
      'മൂല ഫയലുകള്‍ മേലെഴുതി ഇല്ലാതാക്കും. ഇത് തിരികെ എടുക്കാനാവില്ല.';

  @override
  String bodyVaultImportConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഇനങ്ങള്‍ മാറ്റുക',
      one: '1 ഇനം മാറ്റുക',
    );
    return '$_temp0';
  }

  @override
  String get labelVaultImportNothingSelected => 'ഒന്നും തിരഞ്ഞെടുത്തിട്ടില്ല';

  @override
  String bodyVaultShredConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count മൂല ഫയലുകള്‍ നശിപ്പിക്കണോ?',
      one: '1 മൂല ഫയല്‍ നശിപ്പിക്കണോ?',
    );
    return '$_temp0';
  }

  @override
  String get bodyVaultShredConfirm =>
      'മൂല ഫയലുകള്‍ മേലെഴുതി ഇല്ലാതാക്കും. ഇത് തിരികെ എടുക്കാനാവില്ല.';

  @override
  String get actionVaultShredConfirm => 'നശിപ്പിക്കുക';

  @override
  String bodyVaultImportDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഇനങ്ങള്‍ വോള്‍ട്ടിലേക്ക് മാറ്റി',
      one: '1 ഇനം വോള്‍ട്ടിലേക്ക് മാറ്റി',
    );
    return '$_temp0';
  }

  @override
  String bodyVaultImportPartial(int moved, int failed) {
    return '$moved മാറ്റി, $failed വായിക്കാനായില്ല';
  }

  @override
  String get errorVaultImportFailed => 'ഒന്നും വോള്‍ട്ടിലേക്ക് മാറ്റാനായില്ല';

  @override
  String bodyVaultRestoreConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഇനങ്ങള്‍ തിരികെ കൊണ്ടുവരണോ?',
      one: '1 ഇനം തിരികെ കൊണ്ടുവരണോ?',
    );
    return '$_temp0';
  }

  @override
  String get bodyVaultRestoreConfirm =>
      'ഇനങ്ങള്‍ നിങ്ങളുടെ ഗാലറി ഫോള്‍ഡറുകളിലേക്ക് തിരികെ എഴുതുകയും വോള്‍ട്ടില്‍ നിന്ന് മാറ്റുകയും ചെയ്യും.';

  @override
  String get actionVaultRestoreConfirm => 'തിരികെ കൊണ്ടുവരിക';

  @override
  String bodyVaultDeleteConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഇനങ്ങള്‍ പൂര്‍ണ്ണമായി ഇല്ലാതാക്കണോ?',
      one: '1 ഇനം പൂര്‍ണ്ണമായി ഇല്ലാതാക്കണോ?',
    );
    return '$_temp0';
  }

  @override
  String get bodyVaultDeleteConfirm =>
      'എന്‍ക്രിപ്റ്റ് ചെയ്ത ഫയലുകള്‍ മേലെഴുതി ഇല്ലാതാക്കും. തിരികെ എടുക്കാനാവില്ല, മറ്റൊരിടത്തും പകര്‍പ്പുമില്ല.';

  @override
  String get errorVaultViewerFailed => 'ഈ ഇനം തുറക്കാനായില്ല';

  @override
  String get bodyVaultViewerTampered =>
      'ഈ ഇനത്തിന്‍റെ സമഗ്രതാ പരിശോധന പരാജയപ്പെട്ടു, അത് തുറന്നില്ല';

  @override
  String get titleVaultSettings => 'വോള്‍ട്ട് ക്രമീകരണങ്ങള്‍';

  @override
  String get titleVaultAutoLockHeading => 'സ്വയം പൂട്ടല്‍';

  @override
  String get bodyVaultAutoLock =>
      'ആപ്പ് സ്ക്രീനില്‍ നിന്ന് മാറുമ്പോള്‍ വോള്‍ട്ട് എപ്പോഴും പൂടും. നിങ്ങള്‍ തൊടാതിരിക്കുമ്പോള്‍ എത്ര നേരം കാത്തിരിക്കണം എന്നതാണ് ഇത്.';

  @override
  String bodyVaultAutoLockSeconds(int count) {
    return '$count സെക്കന്‍റ്';
  }

  @override
  String bodyVaultAutoLockMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count മിനിറ്റ്',
      one: '1 മിനിറ്റ്',
    );
    return '$_temp0';
  }

  @override
  String get titleVaultBiometricHeading => 'വിരലടയാളം കൊണ്ട് തുറക്കുക';

  @override
  String get bodyVaultBiometric =>
      'ഇതൊരു കുറുക്കുവഴി മാത്രമാണ്. ഇത് ഓണ്‍ ആയാലും ഓഫ് ആയാലും നിങ്ങളുടെ പിന്‍ വോള്‍ട്ട് തുറക്കും.';

  @override
  String get titleVaultShredHeading => 'നശിപ്പിക്കലിന്‍റെ തവണകള്‍';

  @override
  String get bodyVaultShred =>
      'ഒരു ഫയല്‍ ഇല്ലാതാക്കുന്നതിനു മുമ്പ് എത്ര തവണ മേലെഴുതണം. കൂടുതല്‍ തവണകള്‍ കൂടുതല്‍ സമയമെടുക്കും. ഫ്ലാഷ് സ്റ്റോറേജില്‍ ഇത് ശക്തമായ ഒരു നടപടിയാണ്, ഉറപ്പല്ല.';

  @override
  String bodyVaultShredPassCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count തവണ',
      one: '1 തവണ',
    );
    return '$_temp0';
  }

  @override
  String get titleVaultShredDefaultHeading =>
      'സ്ഥിരമായി മൂല ഫയലുകള്‍ നശിപ്പിക്കുക';

  @override
  String get bodyVaultShredDefault =>
      'ഇനങ്ങള്‍ ചേര്‍ക്കുമ്പോള്‍ നശിപ്പിക്കല്‍ മുന്‍കൂട്ടി തിരഞ്ഞെടുക്കും. ഓരോ തവണയും സ്ഥിരീകരിക്കാന്‍ ചോദിക്കും.';

  @override
  String get titleVaultChangePin => 'പിന്‍ മാറ്റുക';

  @override
  String get labelVaultCurrentPin => 'ഇപ്പോഴത്തെ പിന്‍';

  @override
  String get labelVaultNewPin => 'പുതിയ പിന്‍';

  @override
  String get bodyVaultPinChanged => 'നിങ്ങളുടെ പിന്‍ മാറ്റി';

  @override
  String get titleVaultSecureScreenHeading =>
      'സ്ക്രീന്‍ഷോട്ടുകള്‍ തടഞ്ഞിരിക്കുന്നു';

  @override
  String get bodyVaultSecureScreen =>
      'വോള്‍ട്ട് തുറന്നിരിക്കേ, ആന്‍ഡ്രോയ്ഡ് സ്ക്രീന്‍ഷോട്ടും സ്ക്രീന്‍ റെക്കോര്‍ഡിങ്ങും തടയുകയും ആപ്പ് സ്വിച്ചറില്‍ വോള്‍ട്ട് മറയ്ക്കുകയും ചെയ്യും.';

  @override
  String bodySelectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count തിരഞ്ഞെടുത്തു',
      one: '1 തിരഞ്ഞെടുത്തു',
    );
    return '$_temp0';
  }

  @override
  String get tooltipSelectionClear => 'തിരഞ്ഞെടുപ്പ് മായ്ക്കുക';

  @override
  String get tooltipSelectionSelectAll => 'എല്ലാം തിരഞ്ഞെടുക്കുക';

  @override
  String get bodySelectionFull =>
      'ഒരു ബാച്ചിന് ഉൾക്കൊള്ളാവുന്ന പരമാവധി ഇത്രയാണ്';

  @override
  String get labelBatchActionConvert => 'രൂപാന്തരപ്പെടുത്തുക';

  @override
  String get labelBatchActionMore => 'കൂടുതൽ';

  @override
  String get labelBatchActionWatermark => 'വാട്ടർമാർക്ക്';

  @override
  String get labelBatchActionExportPdf => 'പി.ഡി.എഫ് ഉണ്ടാക്കുക';

  @override
  String get labelBatchActionAddTags => 'ടാഗുകൾ ചേർക്കുക';

  @override
  String get labelBatchActionRemoveTags => 'ടാഗുകൾ നീക്കുക';

  @override
  String get labelBatchActionAddToAlbum => 'ആൽബത്തിലാക്കുക';

  @override
  String get labelBatchActionFavourite => 'പ്രിയപ്പെട്ടതാക്കുക';

  @override
  String get bodyBatchActionUnfavourite => 'പ്രിയപ്പെട്ടതല്ലാതാക്കുക';

  @override
  String get labelBatchActionMoveToVault => 'വോൾട്ടിലേക്ക് മാറ്റുക';

  @override
  String get bodyBatchActionTransfer => 'ഉപകരണത്തിലേക്ക് അയക്കുക';

  @override
  String get titleBatchActionMoveToTrash => 'കളയുക';

  @override
  String get emptyBatchBlocked => 'ആദ്യം എന്തെങ്കിലും തിരഞ്ഞെടുക്കുക';

  @override
  String get bodyBatchBlockedTooLarge => 'ഒരു ബാച്ചിന് വളരെയധികം ഇനങ്ങൾ';

  @override
  String get bodyBatchBlockedUnsupported => 'ഈ ഫയലുകൾക്ക് ലഭ്യമല്ല';

  @override
  String get bodyBatchBlockedMixed =>
      'ഈ പ്രവൃത്തിയിൽ വീഡിയോകൾ ഉൾപ്പെടുത്താനാവില്ല';

  @override
  String get titleBatchRunning => 'പ്രവർത്തിക്കുന്നു';

  @override
  String bodyBatchProgress(int done, int total) {
    return '$total ൽ $done';
  }

  @override
  String get labelBatchCancel => 'റദ്ദാക്കുക';

  @override
  String get bodyBatchCancelling => 'ഈ ഫയലിനു ശേഷം നിർത്തുന്നു';

  @override
  String get labelBatchDone => 'പൂർത്തിയായി';

  @override
  String bodyBatchResultSucceeded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഫയലുകൾ പൂർത്തിയായി',
      one: '1 ഫയൽ പൂർത്തിയായി',
    );
    return '$_temp0';
  }

  @override
  String errorBatchResultFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഫയലുകൾ ചെയ്യാനായില്ല',
      one: '1 ഫയൽ ചെയ്യാനായില്ല',
    );
    return '$_temp0';
  }

  @override
  String bodyBatchResultSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഫയലുകൾ ഒഴിവാക്കി',
      one: '1 ഫയൽ ഒഴിവാക്കി',
    );
    return '$_temp0';
  }

  @override
  String get titleBatchConfirm => 'ഉറപ്പാണോ?';

  @override
  String bodyBatchConfirmVault(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഫോട്ടോകൾ വോൾട്ടിലേക്ക് മാറ്റും',
      one: '1 ഫോട്ടോ വോൾട്ടിലേക്ക് മാറ്റും',
    );
    return '$_temp0';
  }

  @override
  String bodyBatchConfirmTrash(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഇനങ്ങൾ ചവറ്റുകുട്ടയിലേക്ക് മാറ്റും. ഒന്നും മായ്ക്കില്ല.',
      one: '1 ഇനം ചവറ്റുകുട്ടയിലേക്ക് മാറ്റും. ഒന്നും മായ്ക്കില്ല.',
    );
    return '$_temp0';
  }

  @override
  String bodyBatchConfirmNewFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ഒറിജിനലുകൾക്കൊപ്പം $count പുതിയ ഫയലുകൾ സേവ് ചെയ്യും.',
      one: 'ഒറിജിനലിനൊപ്പം ഒരു പുതിയ ഫയൽ സേവ് ചെയ്യും.',
    );
    return '$_temp0';
  }

  @override
  String get actionBatchConfirmContinue => 'തുടരുക';

  @override
  String get labelBatchPickTags => 'ടാഗുകൾ തിരഞ്ഞെടുക്കുക';

  @override
  String get labelBatchPickAlbum => 'ഒരു ആൽബം തിരഞ്ഞെടുക്കുക';

  @override
  String get titleBackup => 'ബാക്കപ്പും പുനഃസ്ഥാപനവും';

  @override
  String get titleBackupOpen => 'ബാക്കപ്പും പുനഃസ്ഥാപനവും';

  @override
  String get titleBackupCreate => 'ഒരു ബാക്കപ്പ് ഉണ്ടാക്കുക';

  @override
  String get bodyBackupCreate =>
      'നിങ്ങളുടെ ടാഗുകൾ, ആൽബങ്ങൾ, പ്രിയപ്പെട്ടവ, കുറിപ്പുകൾ എന്നിവ പാസ്‌വേഡ് കൊണ്ട് സംരക്ഷിച്ച ഒരു ഫയലിൽ സേവ് ചെയ്യുന്നു. ഫോട്ടോകളും വീഡിയോകളും ഇതിൽ ഇല്ല: അവ ട്രാൻസ്ഫർ ഉപയോഗിച്ച് മറ്റൊരു ഉപകരണത്തിലേക്ക് അയയ്ക്കുക.';

  @override
  String get actionBackupCreate => 'ബാക്കപ്പ് ഉണ്ടാക്കുക';

  @override
  String get titleBackupRestore => 'ഒരു ബാക്കപ്പ് പുനഃസ്ഥാപിക്കുക';

  @override
  String get bodyBackupRestore =>
      'ഈ ഉപകരണത്തിലുള്ള ഫോട്ടോകൾക്കായി ടാഗുകൾ, ആൽബങ്ങൾ, പ്രിയപ്പെട്ടവ, കുറിപ്പുകൾ എന്നിവ തിരികെ കൊണ്ടുവരുന്നു. ഈ ഉപകരണത്തിൽ നിന്ന് ഒന്നും ഇല്ലാതാക്കുന്നില്ല.';

  @override
  String get actionBackupRestore => 'ഒരു ബാക്കപ്പ് ഫയൽ തിരഞ്ഞെടുക്കുക';

  @override
  String get titleBackupPassword => 'ബാക്കപ്പ് പാസ്‌വേഡ്';

  @override
  String get labelBackupPassword => 'പാസ്‌വേഡ്';

  @override
  String get labelBackupPasswordConfirm => 'വീണ്ടും ടൈപ്പ് ചെയ്യുക';

  @override
  String get bodyBackupPasswordWarning =>
      'ഈ പാസ്‌വേഡ് വീണ്ടെടുക്കാൻ ഒരു വഴിയുമില്ല. മറന്നാൽ ബാക്കപ്പ് തുറക്കാനാവില്ല.';

  @override
  String bodyBackupPasswordTooShort(int count) {
    return 'കുറഞ്ഞത് $count അക്ഷരങ്ങൾ';
  }

  @override
  String get bodyBackupPasswordMismatch => 'രണ്ടും തമ്മിൽ പൊരുത്തപ്പെടുന്നില്ല';

  @override
  String get labelBackupStageCollecting => 'നിങ്ങളുടെ ലൈബ്രറി വായിക്കുന്നു';

  @override
  String get labelBackupStagePacking => 'പായ്ക്ക് ചെയ്യുന്നു';

  @override
  String get bodyBackupStageChoosing =>
      'എവിടെ സേവ് ചെയ്യണമെന്ന് തിരഞ്ഞെടുക്കാൻ കാത്തിരിക്കുന്നു';

  @override
  String get labelBackupStageEncrypting => 'എൻക്രിപ്റ്റ് ചെയ്യുന്നു';

  @override
  String get labelBackupDone => 'ബാക്കപ്പ് സേവ് ചെയ്തു';

  @override
  String get labelBackupCancelled => 'ബാക്കപ്പ് റദ്ദാക്കി';

  @override
  String get bodyBackupNothingToSave =>
      'ബാക്കപ്പ് ചെയ്യാൻ ടാഗുകളോ ആൽബങ്ങളോ കുറിപ്പുകളോ പ്രിയപ്പെട്ടവയോ ഇതുവരെ ഇല്ല';

  @override
  String get errorBackupFailed => 'ബാക്കപ്പ് സേവ് ചെയ്യാനായില്ല';

  @override
  String get titleRestorePreview => 'എന്ത് പുനഃസ്ഥാപിക്കും';

  @override
  String bodyRestoreFromBackupDate(String date) {
    return '$date ലെ ബാക്കപ്പ്';
  }

  @override
  String bodyRestorePlanTags(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count പുതിയ ടാഗുകൾ',
      one: '1 പുതിയ ടാഗ്',
      zero: 'പുതിയ ടാഗുകളില്ല',
    );
    return '$_temp0';
  }

  @override
  String bodyRestorePlanAlbums(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count പുതിയ ആൽബങ്ങൾ',
      one: '1 പുതിയ ആൽബം',
      zero: 'പുതിയ ആൽബങ്ങളില്ല',
    );
    return '$_temp0';
  }

  @override
  String bodyRestorePlanLinks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ചേർക്കാൻ $count ടാഗുകളും ആൽബം സ്ഥാനങ്ങളും',
      one: 'ചേർക്കാൻ 1 ടാഗ് അല്ലെങ്കിൽ ആൽബം സ്ഥാനം',
      zero: 'ചേർക്കാൻ ടാഗുകളോ ആൽബം സ്ഥാനങ്ങളോ ഇല്ല',
    );
    return '$_temp0';
  }

  @override
  String bodyRestorePlanUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'പുതുക്കാൻ $count ഫോട്ടോകൾ',
      one: 'പുതുക്കാൻ 1 ഫോട്ടോ',
      zero: 'പുതുക്കാൻ ഫോട്ടോകളില്ല',
    );
    return '$_temp0';
  }

  @override
  String bodyRestorePlanUnmatched(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ബാക്കപ്പിലെ $count ഫോട്ടോകൾ ഈ ഉപകരണത്തിൽ ഇല്ല',
      one: 'ബാക്കപ്പിലെ 1 ഫോട്ടോ ഈ ഉപകരണത്തിൽ ഇല്ല',
    );
    return '$_temp0';
  }

  @override
  String get bodyRestorePlanNothing =>
      'ഈ ബാക്കപ്പ് ഈ ഉപകരണത്തിൽ ഒന്നും മാറ്റില്ല';

  @override
  String get labelRestoreApply => 'പുനഃസ്ഥാപിക്കുക';

  @override
  String get labelRestoreDone => 'പുനഃസ്ഥാപനം പൂർത്തിയായി';

  @override
  String get bodyRestoreWrongPassword =>
      'തെറ്റായ പാസ്‌വേഡ്, അല്ലെങ്കിൽ ഫയൽ കേടായിരിക്കുന്നു';

  @override
  String get bodyRestoreNotAnArchive => 'അത് ഒരു ഗാലറി ബാക്കപ്പ് ഫയൽ അല്ല';

  @override
  String get bodyRestoreTooLarge =>
      'ഒരു ഗാലറി ബാക്കപ്പ് ആകാൻ ആ ഫയൽ വളരെ വലുതാണ്';

  @override
  String get bodyRestoreTooNew =>
      'ആ ബാക്കപ്പ് ആപ്പിന്റെ പുതിയ പതിപ്പ് ഉണ്ടാക്കിയതാണ്';

  @override
  String get errorRestoreFailed => 'ബാക്കപ്പ് പുനഃസ്ഥാപിക്കാനായില്ല';

  @override
  String get titleSync => 'ട്രാൻസ്ഫർ';

  @override
  String get titleSyncOpen => 'ഒരു ഉപകരണത്തിലേക്ക് ട്രാൻസ്ഫർ';

  @override
  String get bodySyncIntro =>
      'അതേ വൈ-ഫൈയിലുള്ള മറ്റൊരു ഫോണിലേക്ക് നേരിട്ട് ഫോട്ടോകൾ അയയ്ക്കുക. ഒന്നും ഇന്റർനെറ്റിലേക്ക് പോകുന്നില്ല, അക്കൗണ്ട് വേണ്ട.';

  @override
  String get bodySyncPrivacyNote =>
      'രണ്ട് ഫോണുകളും ഒരേ വൈ-ഫൈയിൽ ആയിരിക്കണം. മറ്റേ ഉപകരണം നിങ്ങളുടെ ലോക്കൽ നെറ്റ്‌വർക്കിൽ അല്ലെങ്കിൽ കണക്ഷൻ നിരസിക്കും, ഈ സ്ക്രീൻ വിട്ടാലുടൻ അത് അടയ്ക്കും.';

  @override
  String get labelSyncSend => 'അയയ്ക്കുക';

  @override
  String get labelSyncReceive => 'സ്വീകരിക്കുക';

  @override
  String get bodySyncSend =>
      'ഈ ഫോണിൽ ഒരു കോഡ് കാണിക്കുക, അല്ലെങ്കിൽ മറ്റേത് സ്കാൻ ചെയ്യുക';

  @override
  String get bodySyncReceive => 'മറ്റേ ഫോൺ സ്കാൻ ചെയ്യാൻ ഒരു കോഡ് കാണിക്കുക';

  @override
  String get actionSyncScanCode => 'ഒരു കോഡ് സ്കാൻ ചെയ്യുക';

  @override
  String get titleSyncScan => 'മറ്റേ ഫോൺ സ്കാൻ ചെയ്യുക';

  @override
  String get titleSyncPairingHeading => 'മറ്റേ ഫോൺ ഈ കോഡിലേക്ക് ചൂണ്ടുക';

  @override
  String get titleSyncManualCodeHeading => 'അല്ലെങ്കിൽ ഈ കോഡ് ടൈപ്പ് ചെയ്യുക';

  @override
  String get labelSyncManualCode => 'ജോടിയാക്കൽ കോഡ്';

  @override
  String get bodySyncManualCodeInvalid => 'ആ കോഡ് സാധുവല്ല';

  @override
  String get bodySyncWaiting => 'മറ്റേ ഫോണിനായി കാത്തിരിക്കുന്നു';

  @override
  String bodySyncPairedWith(String name) {
    return '$name മായി ജോടിയാക്കി';
  }

  @override
  String get labelSyncTransferring => 'ട്രാൻസ്ഫർ ചെയ്യുന്നു';

  @override
  String bodySyncProgressFiles(int done, int total) {
    return '$total ഫയലുകളിൽ $done';
  }

  @override
  String get bodySyncNothingSelected =>
      'ആദ്യം അയയ്ക്കാൻ കുറച്ച് ഫോട്ടോകൾ തിരഞ്ഞെടുക്കുക';

  @override
  String bodySyncOfferHeading(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഫയലുകൾ വാഗ്ദാനം ചെയ്തു',
      one: '1 ഫയൽ വാഗ്ദാനം ചെയ്തു',
    );
    return '$_temp0';
  }

  @override
  String get labelSyncDone => 'ട്രാൻസ്ഫർ പൂർത്തിയായി';

  @override
  String bodySyncResultReceived(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഫയലുകൾ ലഭിച്ചു',
      one: '1 ഫയൽ ലഭിച്ചു',
    );
    return '$_temp0';
  }

  @override
  String bodySyncResultSent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഫയലുകൾ അയച്ചു',
      one: '1 ഫയൽ അയച്ചു',
    );
    return '$_temp0';
  }

  @override
  String bodySyncResultSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഫയലുകൾ നേരത്തെ ഉണ്ടായിരുന്നു',
      one: '1 ഫയൽ നേരത്തെ ഉണ്ടായിരുന്നു',
    );
    return '$_temp0';
  }

  @override
  String errorSyncResultFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഫയലുകൾ എത്തിയില്ല',
      one: '1 ഫയൽ എത്തിയില്ല',
    );
    return '$_temp0';
  }

  @override
  String get bodySyncSavedToAppFolder =>
      'ആൻഡ്രോയ്ഡിന്റെ ഈ പതിപ്പിൽ ഫയലുകൾ നിങ്ങളുടെ ഗാലറിക്ക് പകരം ആപ്പിന്റെ സ്വന്തം ഫോൾഡറിൽ സേവ് ചെയ്തു.';

  @override
  String get actionSyncStop => 'നിർത്തുക';

  @override
  String get bodySyncErrorNoNetwork => 'ഈ ഫോൺ ഒരു വൈ-ഫൈ നെറ്റ്‌വർക്കിൽ അല്ല';

  @override
  String get bodySyncErrorPairingTimeout =>
      'സമയത്ത് ഒരു ഉപകരണവും കണക്റ്റ് ചെയ്തില്ല';

  @override
  String get bodySyncErrorRefused =>
      'ആ ഉപകരണം നിങ്ങളുടെ ലോക്കൽ നെറ്റ്‌വർക്കിൽ അല്ല';

  @override
  String get bodySyncErrorHandshake =>
      'ആ കോഡ് കാണിച്ചതെന്ന് മറ്റേ ഉപകരണത്തിന് തെളിയിക്കാനായില്ല';

  @override
  String get bodySyncErrorProtocol =>
      'മറ്റേ ഉപകരണം ആപ്പിന്റെ മറ്റൊരു പതിപ്പാണ് പ്രവർത്തിപ്പിക്കുന്നത്';

  @override
  String get bodySyncErrorConnection =>
      'മറ്റേ ഉപകരണവുമായുള്ള കണക്ഷൻ നഷ്ടപ്പെട്ടു';

  @override
  String get bodySyncErrorIdle => 'മറ്റേ ഉപകരണം പ്രതികരിക്കുന്നത് നിർത്തി';

  @override
  String get bodySyncErrorCancelled => 'ട്രാൻസ്ഫർ നിർത്തി';

  @override
  String get bodySyncErrorUnknown => 'ട്രാൻസ്ഫർ പൂർത്തിയാക്കാനായില്ല';

  @override
  String get bodySyncCameraPermission =>
      'കോഡ് സ്കാൻ ചെയ്യാൻ ക്യാമറ ആക്‌സസ് വേണം. പകരം കോഡ് ടൈപ്പ് ചെയ്യാം.';

  @override
  String get actionSyncTypeCodeInstead => 'പകരം കോഡ് ടൈപ്പ് ചെയ്യുക';

  @override
  String get tooltipViewerMoreActions => 'കൂടുതൽ';

  @override
  String get titleCodeScanOpen => 'കോഡുകൾ സ്കാൻ ചെയ്യുക';

  @override
  String get titleCodeScan => 'ഈ ചിത്രത്തിലെ കോഡുകൾ';

  @override
  String get labelCodeScanLooking => 'കോഡുകൾ തിരയുന്നു';

  @override
  String get bodyCodeScanNoCodes => 'ഈ ചിത്രത്തിൽ കോഡുകളൊന്നും കണ്ടെത്തിയില്ല';

  @override
  String get errorCodeScanFailed => 'ഈ ചിത്രം സ്കാൻ ചെയ്യാൻ കഴിഞ്ഞില്ല';

  @override
  String get tooltipCodeScanRetry => 'വീണ്ടും ശ്രമിക്കുക';

  @override
  String bodyCodeScanFoundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count കോഡുകൾ കണ്ടെത്തി',
      one: '1 കോഡ് കണ്ടെത്തി',
    );
    return '$_temp0';
  }

  @override
  String get labelCodeScanKindUrl => 'വെബ് വിലാസം';

  @override
  String get labelCodeScanKindWifi => 'വൈ-ഫൈ നെറ്റ്‌വർക്ക്';

  @override
  String get labelCodeScanKindPhone => 'ഫോൺ നമ്പർ';

  @override
  String get labelCodeScanKindEmail => 'ഇമെയിൽ വിലാസം';

  @override
  String get labelCodeScanKindSms => 'സന്ദേശം';

  @override
  String get labelCodeScanKindGeo => 'ഭൂപട സ്ഥാനം';

  @override
  String get labelCodeScanKindContact => 'കോൺടാക്ട് കാർഡ്';

  @override
  String get labelCodeScanKindCalendar => 'കലണ്ടർ ഇനം';

  @override
  String get labelCodeScanKindText => 'ടെക്സ്റ്റ്';

  @override
  String get labelCodeScanActionCopy => 'പകർത്തുക';

  @override
  String get labelCodeScanActionOpen => 'തുറക്കുക';

  @override
  String get labelCodeScanActionDial => 'വിളിക്കുക';

  @override
  String get labelCodeScanActionEmail => 'ഇമെയിൽ എഴുതുക';

  @override
  String get labelCodeScanActionSms => 'സന്ദേശം അയയ്ക്കുക';

  @override
  String get labelCodeScanActionMap => 'ഭൂപടത്തിൽ കാണിക്കുക';

  @override
  String get labelCodeScanActionCopyWifiPassword => 'പാസ്‌വേഡ് പകർത്തുക';

  @override
  String get labelCodeScanActionConnectWifi => 'കണക്റ്റ് ചെയ്യുക';

  @override
  String get labelCodeScanActionSaveToNotes => 'കുറിപ്പുകളിൽ സൂക്ഷിക്കുക';

  @override
  String get bodyCodeScanBlockedScheme => 'ഈ തരം വിലാസം ആപ്പ് തുറക്കില്ല';

  @override
  String get bodyCodeScanBlockedMalformed => 'ഈ വിലാസം വായിക്കാൻ കഴിഞ്ഞില്ല';

  @override
  String get bodyCodeScanBlockedIncompleteWifi =>
      'ഈ വൈ-ഫൈ കോഡിൽ നെറ്റ്‌വർക്ക് പേരോ പാസ്‌വേഡോ ഇല്ല';

  @override
  String get bodyCodeScanBlockedTooLong =>
      'ഈ കോഡ് ഉപയോഗിക്കാൻ കഴിയാത്തത്ര നീളമുള്ളതാണ്';

  @override
  String get labelCodeScanCopied => 'പകർത്തി';

  @override
  String get labelCodeScanPasswordCopied => 'പാസ്‌വേഡ് പകർത്തി';

  @override
  String get labelCodeScanSavedToNotes => 'കുറിപ്പുകളിൽ സൂക്ഷിച്ചു';

  @override
  String get errorCodeScanOpenFailed =>
      'ഇത് തുറക്കാൻ കഴിയുന്ന ആപ്പ് ഈ ഉപകരണത്തിൽ ഇല്ല';

  @override
  String get bodyCodeScanWifiSuggested =>
      'നെറ്റ്‌വർക്ക് Android-ന് നൽകി. വൈ-ഫൈ ക്രമീകരണങ്ങളിൽ അത് തിരഞ്ഞെടുക്കുക.';

  @override
  String get bodyCodeScanWifiManual =>
      'വൈ-ഫൈ ക്രമീകരണങ്ങൾ തുറന്ന് നെറ്റ്‌വർക്ക് സ്വയം തിരഞ്ഞെടുക്കുക.';

  @override
  String bodyCodeScanWifiSecurity(String security) {
    return 'സുരക്ഷ: $security';
  }

  @override
  String get labelCodeScanWifiHidden => 'മറഞ്ഞിരിക്കുന്ന നെറ്റ്‌വർക്ക്';

  @override
  String get labelCodeScanWifiOpen => 'തുറന്ന നെറ്റ്‌വർക്ക്';

  @override
  String get titleOcrOpen => 'ടെക്സ്റ്റ് എടുക്കുക';

  @override
  String get titleOcr => 'ഈ ചിത്രത്തിലെ ടെക്സ്റ്റ്';

  @override
  String get labelOcrReading => 'ടെക്സ്റ്റ് വായിക്കുന്നു';

  @override
  String get helpOcrSlowHint =>
      'വലിയ ഫോട്ടോയ്ക്ക് കുറച്ച് സെക്കൻഡ് എടുത്തേക്കാം.';

  @override
  String get labelOcrLanguage => 'ഭാഷ';

  @override
  String get labelOcrLanguageEnglish => 'ഇംഗ്ലീഷ്';

  @override
  String get labelOcrLanguageMalayalam => 'മലയാളം';

  @override
  String get bodyOcrLanguageBoth => 'ഇംഗ്ലീഷും മലയാളവും';

  @override
  String get bodyOcrNoText => 'ഈ ചിത്രത്തിൽ ടെക്സ്റ്റ് ഒന്നും കണ്ടെത്തിയില്ല';

  @override
  String get actionOcrCopyAll => 'എല്ലാം പകർത്തുക';

  @override
  String get labelOcrCopied => 'ടെക്സ്റ്റ് പകർത്തി';

  @override
  String get labelOcrSaveToNotes => 'കുറിപ്പുകളിൽ സൂക്ഷിക്കുക';

  @override
  String get labelOcrSavedToNotes => 'കുറിപ്പുകളിൽ സൂക്ഷിച്ചു';

  @override
  String get actionOcrReadAgain => 'വീണ്ടും വായിക്കുക';

  @override
  String bodyOcrWordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count വാക്കുകൾ',
      one: '1 വാക്ക്',
    );
    return '$_temp0';
  }

  @override
  String get bodyOcrFailedUnreadable => 'ഈ ചിത്രം തുറക്കാൻ കഴിഞ്ഞില്ല';

  @override
  String get bodyOcrFailedTooLarge => 'ഈ ചിത്രം വായിക്കാൻ കഴിയാത്തത്ര വലുതാണ്';

  @override
  String get bodyOcrFailedMissingData => 'ഈ ബിൽഡിൽ ഭാഷാ ഫയലുകൾ ഇല്ല';

  @override
  String get bodyOcrFailedTimeout => 'വായന വളരെ നീണ്ടുപോയതിനാൽ നിർത്തി';

  @override
  String get bodyOcrFailedEngine => 'ടെക്സ്റ്റ് വായിക്കാൻ കഴിഞ്ഞില്ല';

  @override
  String get titleNotesOpen => 'കുറിപ്പുകൾ';

  @override
  String get titleNotes => 'കുറിപ്പുകൾ';

  @override
  String get tabNotesWrite => 'എഴുതുക';

  @override
  String get tabNotesPreview => 'പ്രിവ്യൂ';

  @override
  String get helpNotesHint =>
      'ഈ ഇനത്തെക്കുറിച്ച് ഒരു കുറിപ്പ് എഴുതുക. മാർക്ക്ഡൗൺ ഉപയോഗിക്കാം.';

  @override
  String get emptyNotes => 'ഇതുവരെ കുറിപ്പില്ല';

  @override
  String get tooltipNotesSave => 'സൂക്ഷിക്കുക';

  @override
  String get labelNotesSaved => 'കുറിപ്പ് സൂക്ഷിച്ചു';

  @override
  String get errorNotesSaveFailed => 'കുറിപ്പ് സൂക്ഷിക്കാൻ കഴിഞ്ഞില്ല';

  @override
  String get tooltipNotesDelete => 'കുറിപ്പ് ഇല്ലാതാക്കുക';

  @override
  String get titleNotesDelete => 'ഈ കുറിപ്പ് ഇല്ലാതാക്കണോ?';

  @override
  String get bodyNotesDelete => 'കുറിപ്പ് നീക്കം ചെയ്യും. ഫയലിന് മാറ്റമില്ല.';

  @override
  String get labelNotesDeleted => 'കുറിപ്പ് ഇല്ലാതാക്കി';

  @override
  String get actionNotesCancel => 'റദ്ദാക്കുക';

  @override
  String bodyNotesCharacterCount(int used, int total) {
    return '$total അക്ഷരങ്ങളിൽ $used';
  }

  @override
  String get bodyNotesTooLong =>
      'ഈ കുറിപ്പ് സൂക്ഷിക്കാൻ കഴിയാത്തത്ര നീളമുള്ളതാണ്';

  @override
  String get titleNotesDiscard => 'സൂക്ഷിക്കാതെ പോകണോ?';

  @override
  String get bodyNotesDiscard => 'ഈ കുറിപ്പിലെ മാറ്റങ്ങൾ നഷ്ടപ്പെടും.';

  @override
  String get actionNotesDiscardLeave => 'പോകുക';

  @override
  String get actionNotesDiscardKeep => 'എഴുത്ത് തുടരുക';

  @override
  String get bodyNotesLinkBlocked => 'ഈ തരം ലിങ്ക് ആപ്പ് തുറക്കില്ല';

  @override
  String get titleNotesDetailsLabel => 'കുറിപ്പ്';

  @override
  String get labelNotesAddFromDetails => 'ഒരു കുറിപ്പ് ചേർക്കുക';

  @override
  String get titlePdfImagesOpen => 'PDF-ൽ നിന്ന് ചിത്രങ്ങൾ എടുക്കുക';

  @override
  String get titlePdfImages => 'PDF-ലെ ചിത്രങ്ങൾ';

  @override
  String get actionPdfImagesPick => 'ഒരു PDF തിരഞ്ഞെടുക്കുക';

  @override
  String get tooltipPdfImagesChooseAnother => 'മറ്റൊരു PDF തിരഞ്ഞെടുക്കുക';

  @override
  String get labelPdfImagesReading => 'PDF വായിക്കുന്നു';

  @override
  String get titlePdfImagesEmpty => 'ഇതുവരെ PDF തിരഞ്ഞെടുത്തിട്ടില്ല';

  @override
  String get bodyPdfImagesEmpty =>
      'ഒരു PDF തിരഞ്ഞെടുക്കുക, അതിനുള്ളിലെ ചിത്രങ്ങൾ ആപ്പ് കാണിക്കും. PDF-ന് ഒരു മാറ്റവും വരുത്തില്ല.';

  @override
  String get bodyPdfImagesNone => 'ഈ PDF-ൽ ചിത്രങ്ങളൊന്നുമില്ല';

  @override
  String bodyPdfImagesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ചിത്രങ്ങൾ കണ്ടെത്തി',
      one: '1 ചിത്രം കണ്ടെത്തി',
    );
    return '$_temp0';
  }

  @override
  String bodyPdfImagesSkippedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count എണ്ണം വായിക്കാൻ കഴിഞ്ഞില്ല',
      one: '1 എണ്ണം വായിക്കാൻ കഴിഞ്ഞില്ല',
    );
    return '$_temp0';
  }

  @override
  String get labelPdfImagesSave => 'തിരഞ്ഞെടുത്തവ സൂക്ഷിക്കുക';

  @override
  String get labelPdfImagesSaving => 'സൂക്ഷിക്കുന്നു';

  @override
  String bodyPdfImagesSavedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ചിത്രങ്ങൾ ഗാലറിയിൽ സൂക്ഷിച്ചു',
      one: '1 ചിത്രം ഗാലറിയിൽ സൂക്ഷിച്ചു',
    );
    return '$_temp0';
  }

  @override
  String bodyPdfImagesSaveFailedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count എണ്ണം സൂക്ഷിക്കാൻ കഴിഞ്ഞില്ല',
      one: '1 എണ്ണം സൂക്ഷിക്കാൻ കഴിഞ്ഞില്ല',
    );
    return '$_temp0';
  }

  @override
  String get actionPdfImagesSelectAll => 'എല്ലാം തിരഞ്ഞെടുക്കുക';

  @override
  String get labelPdfImagesClearSelection => 'മായ്ക്കുക';

  @override
  String get bodyPdfImagesNothingSelected =>
      'സൂക്ഷിക്കാൻ ഒരു ചിത്രമെങ്കിലും തിരഞ്ഞെടുക്കുക';

  @override
  String get bodyPdfImagesTruncated =>
      'ഈ PDF-ൽ വളരെയധികം ചിത്രങ്ങൾ ഉള്ളതിനാൽ ആദ്യത്തേവ മാത്രമേ വായിച്ചുള്ളൂ.';

  @override
  String get bodyPdfImagesFallbackDirectory =>
      'ഗാലറിയിൽ എഴുതാൻ കഴിയാത്തതിനാൽ ആപ്പ് ഫോൾഡറിൽ സൂക്ഷിച്ചു';

  @override
  String bodyPdfImageSize(int width, int height) {
    return '$width x $height';
  }

  @override
  String get bodyPdfRefusedNotPdf => 'ഈ ഫയൽ ഒരു PDF അല്ല';

  @override
  String get bodyPdfRefusedEncrypted =>
      'ഈ PDF പാസ്‌വേഡ് ഉപയോഗിച്ച് സംരക്ഷിച്ചതാണ്, അതിനാൽ തുറക്കാൻ കഴിയില്ല';

  @override
  String get bodyPdfRefusedTooLarge => 'ഈ PDF തുറക്കാൻ കഴിയാത്തത്ര വലുതാണ്';

  @override
  String get bodyPdfRefusedUnreadable => 'ഈ PDF വായിക്കാൻ കഴിഞ്ഞില്ല';

  @override
  String get bodyPdfSkipUnsupportedFilter =>
      'ആപ്പിന് വായിക്കാൻ കഴിയാത്ത രീതിയിൽ കംപ്രസ് ചെയ്തത്';

  @override
  String get bodyPdfSkipUnsupportedColor =>
      'ആപ്പിന് വായിക്കാൻ കഴിയാത്ത കളർ സ്പേസ് ഉപയോഗിക്കുന്നു';

  @override
  String get bodyPdfSkipUnsupportedDepth =>
      'ആപ്പിന് വായിക്കാൻ കഴിയാത്ത കളർ ഡെപ്ത് ഉപയോഗിക്കുന്നു';

  @override
  String get bodyPdfSkipTooLarge => 'എടുക്കാൻ കഴിയാത്തത്ര വലുത്';

  @override
  String get bodyPdfSkipMalformed => 'ചിത്ര ഡാറ്റ അപൂർണ്ണമാണ്';

  @override
  String get errorPdfSkipDecodeFailed => 'ചിത്രം ഡീകംപ്രസ് ചെയ്യാൻ കഴിഞ്ഞില്ല';

  @override
  String get titleSettingsAppearance => 'രൂപം';

  @override
  String get titleSettingsLanguage => 'ഭാഷ';

  @override
  String get titleSettingsSafety => 'സുരക്ഷ';

  @override
  String get titleSettingsPrivacy => 'സ്വകാര്യത';

  @override
  String get titleSettingsDeveloper => 'ഡെവലപ്പർ';

  @override
  String get titleLanguageSystem => 'സിസ്റ്റം സ്വതവേ';

  @override
  String get titleLanguageEnglish => 'English';

  @override
  String get titleLanguageMalayalam => 'മലയാളം';

  @override
  String get descLanguageSubtitle =>
      'ആപ്പ് ഉടൻ ഭാഷ മാറ്റും. വീണ്ടും തുറക്കേണ്ടതില്ല.';

  @override
  String get labelGridDensity => 'ഗ്രിഡ് സാന്ദ്രത';

  @override
  String get descGridDensitySubtitle =>
      'ടൈംലൈനിൽ ഒരു വരിയിൽ എത്ര ചിത്രങ്ങൾ വരണം. ഗ്രിഡിൽ നുള്ളിയും ഇത് മാറ്റാം.';

  @override
  String labelGridDensityValue(int count) {
    return 'ഒരു വരിയിൽ $count';
  }

  @override
  String get titleShowFlashbacks => 'ഓർമ്മകൾ കാണിക്കുക';

  @override
  String get descShowFlashbacksSubtitle =>
      'കഴിഞ്ഞ വർഷങ്ങളിൽ ഇന്നത്തെ ദിവസം എടുത്ത ചിത്രങ്ങൾ, ടൈംലൈനിന്റെ മുകളിൽ.';

  @override
  String get titleConfirmDestructive => 'മായ്ക്കുന്നതിനു മുമ്പ് ചോദിക്കുക';

  @override
  String get descConfirmDestructiveSubtitle =>
      'മായ്ക്കുന്നതിനോ മാറ്റിയെഴുതുന്നതിനോ മുമ്പ് ഒരിക്കൽ കൂടി ചോദിക്കും. ചില മുന്നറിയിപ്പുകൾ ഇത് ഓഫാക്കിയാലും എപ്പോഴും കാണിക്കും.';

  @override
  String get titlePrivacyNoServer => 'വിദൂര സെർവർ ഇല്ല';

  @override
  String get bodyPrivacyNoServer =>
      'നിങ്ങളുടെ ചിത്രങ്ങളും ടാഗുകളും കുറിപ്പുകളും ഈ ഫോണിൽ തന്നെ തുടരും. ഒന്നും അപ്‌ലോഡ് ചെയ്യുന്നില്ല, അക്കൗണ്ട് ഇല്ല. നിങ്ങളുടെ സ്വന്തം വൈ-ഫൈയിലെ മറ്റൊരു ഫോണിലേക്ക് എത്താൻ ട്രാൻസ്ഫർ സ്ക്രീൻ മാത്രമാണ് ഇന്റർനെറ്റ് ഉപയോഗിക്കുന്നത്.';

  @override
  String bodyAboutBuild(String build) {
    return 'ബിൽഡ് $build';
  }

  @override
  String get titleAboutBuildDate => 'ബിൽഡ് തീയതി';

  @override
  String get errorAboutMailFailed =>
      'ആ വിലാസം തുറക്കാൻ ഈ ഫോണിൽ ആപ്പ് ഒന്നുമില്ല.';

  @override
  String get descVaultSettingsOpenSubtitle => 'ലോക്ക് സമയം, പിൻ, ഷ്രെഡ്ഡിങ്';

  @override
  String get descBackupOpenSubtitle =>
      'പാസ്‌വേഡ് സംരക്ഷിത ബാക്കപ്പും പുനഃസ്ഥാപനവും';

  @override
  String get titleSettingsReset => 'ക്രമീകരണങ്ങൾ പഴയപോലാക്കുക';

  @override
  String get bodySettingsReset =>
      'ഈ സ്ക്രീനിലെ എല്ലാ ക്രമീകരണങ്ങളും തുടക്കത്തിലേക്ക് മാറ്റും. ചിത്രങ്ങൾ, ടാഗുകൾ, ആൽബങ്ങൾ, വോൾട്ട് എന്നിവയ്ക്ക് മാറ്റമില്ല.';

  @override
  String get bodySettingsResetDone => 'ക്രമീകരണങ്ങൾ തുടക്കത്തിലേക്ക് മാറ്റി.';

  @override
  String get actionSettingsCancel => 'റദ്ദാക്കുക';

  @override
  String get actionSettingsResetConfirm => 'പഴയപോലാക്കുക';

  @override
  String get helpSettings => 'സഹായവും വഴികാട്ടിയും';

  @override
  String get descSettingsHelpSubtitle =>
      'ഓരോ സവിശേഷതയെക്കുറിച്ചുമുള്ള വഴികാട്ടികളും നുറുങ്ങുകളും ഓഫ്‌ലൈൻ ഉറപ്പുകളും പരിശോധിക്കുക';

  @override
  String get labelSettingsAbout => 'വിവരണം';

  @override
  String get helpOverview => 'അവലോകനം';

  @override
  String get helpHowToUse => 'എങ്ങനെ ഉപയോഗിക്കാം';

  @override
  String get helpTips => 'നുറുങ്ങുകളും കുറുക്കുവഴികളും';

  @override
  String get helpPrivacy => 'സ്വകാര്യതയും ഓഫ്‌ലൈൻ ഉറപ്പും';

  @override
  String get helpBadgeOffline => '100% ഓഫ്‌ലൈൻ';

  @override
  String get helpBadgeEncrypted => 'ഹാർഡ്‌വെയർ എൻക്രിപ്റ്റ് ചെയ്തത്';

  @override
  String get helpBadgeLocal => 'ലോക്കൽ വൈ-ഫൈ മാത്രം';

  @override
  String get helpBadgeSafe => 'സുരക്ഷിതം (ഒറിജിനൽ നിലനിർത്തുന്നു)';

  @override
  String get helpTopicTimelineTitle => 'ടൈംലൈനും ഓർമ്മകളും';

  @override
  String get helpTopicTimelineSummary =>
      'തീയതി അടിസ്ഥാനത്തിൽ ചിത്രങ്ങൾ കാണുക, ഗ്രിഡ് വലിപ്പം മാറ്റുക, പഴയ ഓർമ്മകൾ ആസ്വദിക്കുക.';

  @override
  String get helpTopicTimelineOverview =>
      'നിങ്ങളുടെ എല്ലാ ചിത്രങ്ങളും വീഡിയോകളും തീയതി തലക്കെട്ടുകളോടെ കാലഗണനാക്രമത്തിൽ ടൈംലൈൻ കാണിക്കുന്നു. കഴിഞ്ഞ വർഷങ്ങളിലെ ഇന്നത്തെ ദിവസത്തെ ചിത്രങ്ങൾ കാണിക്കുന്ന \'ഈ ദിവസം\' ഓർമ്മപ്പട്ടികയും ഇതിലുണ്ട്.';

  @override
  String get helpTopicTimelineSteps =>
      '• 1 മുതൽ 5 കോളങ്ങൾ വരെ വലിപ്പം മാറ്റാൻ പിഞ്ച് ചെയ്യുക.\n• മാസങ്ങളിലൂടെയും വർഷങ്ങളിലൂടെയും വേഗത്തിൽ നീങ്ങാൻ വലതുവശത്തെ ഫ്ലോട്ടിംഗ് സ്ക്രബ്ബർ വലിക്കുക.\n• പൂർണ്ണ വ്യക്തതയിൽ കാണാൻ ഏതെങ്കിലും ചിത്രത്തിലോ വീഡിയോയിലോ ടാപ്പ് ചെയ്യുക.';

  @override
  String get helpTopicTimelineTips =>
      '• ഒന്നിലധികം ചിത്രങ്ങൾ ഒരുമിച്ച് തിരഞ്ഞെടുക്കാൻ ഏതെങ്കിലും ഫോട്ടോയിൽ അമർത്തിപ്പിടിക്കുക.\n• ഓർമ്മപ്പട്ടിക വേണമെങ്കിൽ ക്രമീകരണങ്ങളിൽ ഓഫ് ചെയ്യാം.';

  @override
  String get helpTopicTimelinePrivacy =>
      'ടൈംലൈൻ വർഗ്ഗീകരണവും തീയതി പരിശോധനയും ഉപകരണത്തിലെ ലോക്കൽ SQLite ഉപയോഗിച്ച് മാത്രമാണ് നടക്കുന്നത്. ഒരു റിമോട്ട് സെർവറുമായും ബന്ധപ്പെടുന്നില്ല.';

  @override
  String get helpTopicViewerTitle => 'ഫുൾസ്ക്രീൻ വ്യൂവറും വീഡിയോ പ്ലെയറും';

  @override
  String get helpTopicViewerSummary =>
      'ആംഗ്യനിയന്ത്രണങ്ങൾ, EXIF വിവരങ്ങൾ, ഹാർഡ്‌വെയർ വീഡിയോ പ്ലേബാക്ക് എന്നിവയുള്ള ഹൈ-റെസല്യൂഷൻ വ്യൂവർ.';

  @override
  String get helpTopicViewerOverview =>
      'സുഗമമായ ഹാർഡ്‌വെയർ ആക്സിലറേഷനോടെ ഫോട്ടോകളും വീഡിയോകളും കാണുക. ആംഗ്യങ്ങൾ ഉപയോഗിച്ച് എളുപ്പത്തിൽ നിയന്ത്രിക്കുക.';

  @override
  String get helpTopicViewerSteps =>
      '• വിശദാംശങ്ങൾ സൂം ചെയ്യാൻ ഡബിൾ-ടാപ്പ് അല്ലെങ്കിൽ പിഞ്ച് ചെയ്യുക.\n• തിരികെ ടൈംലൈനിലേക്ക് പോകാൻ താഴേക്ക് സ്വൈപ്പ് ചെയ്യുക.\n• ക്യാമറ, എക്സ്പോഷർ, ലൊക്കേഷൻ തുടങ്ങിയ EXIF വിവരങ്ങൾ കാണാൻ മുകളിലേക്ക് സ്വൈപ്പ് ചെയ്യുക.\n• വീഡിയോ കാണുമ്പോൾ: തെളിച്ചം കൂട്ടാൻ/കുറയ്ക്കാൻ ഇടത് വശത്തും, ശബ്ദം മാറ്റാൻ വലത് വശത്തും സ്വൈപ്പ് ചെയ്യുക.';

  @override
  String get helpTopicViewerTips =>
      '• പ്ലേബാക്ക് വേഗത (0.25x മുതൽ 2.0x വരെ) മാറ്റാനും, ഫ്രെയിം ബൈ ഫ്രെയിം നീക്കാനും വീഡിയോ നിയന്ത്രണങ്ങൾ ഉപയോഗിക്കുക.\n• എഡിറ്റിംഗ്, ഫോർമാറ്റ് മാറ്റം, സ്കാനിംഗ് എന്നിവയ്ക്കായി മെനു ഉപയോഗിക്കുക.';

  @override
  String get helpTopicViewerPrivacy =>
      'EXIF വിവരങ്ങൾ പ്രാദേശികമായി SQLite-ൽ മാത്രമേ സൂക്ഷിക്കുന്നുള്ളൂ. വീഡിയോ പ്ലേബാക്കിൽ നെറ്റ്‌വർക്ക് ഘടകങ്ങൾ ഒന്നുമില്ല.';

  @override
  String get helpTopicEditorTitle => 'ഫോട്ടോ എഡിറ്ററും മാർക്കപ്പും';

  @override
  String get helpTopicEditorSummary =>
      'ക്രോപ്പ് ചെയ്യുക, തിരിക്കുക, നിറങ്ങൾ ക്രമീകരിക്കുക, ഫിൽട്ടറുകൾ പ്രയോഗിക്കുക, സ്വകാര്യ വിവരങ്ങൾ മായ്ക്കുക.';

  @override
  String get helpTopicEditorOverview =>
      'ഒറിജിനൽ ചിത്രത്തിന് കോട്ടം തട്ടാത്ത സമ്പൂർണ്ണ ഫോട്ടോ എഡിറ്റർ. കളർ അഡ്ജസ്റ്റ്മെന്റുകൾ, ഫിൽട്ടറുകൾ, ഡ്രോയിംഗ്, പ്രൈവസി റിഡാക്ഷൻ, വാട്ടർമാർക്ക് എന്നിവ ഉൾപ്പെടുന്നു.';

  @override
  String get helpTopicEditorSteps =>
      '• ഫോട്ടോ തുറന്ന് ടൂൾബാറിലെ എഡിറ്റ് ഐക്കൺ ടാപ്പ് ചെയ്യുക.\n• ട്രാൻസ്ഫോർം: അനുയോജ്യമായ അനുപാതത്തിൽ ക്രോപ്പ് ചെയ്യുക, തിരിക്കുക അല്ലെങ്കിൽ നേരെയുള്ളതാക്കുക.\n• അഡ്ജസ്റ്റ്: തെളിച്ചം, കോൺട്രാസ്റ്റ്, ഷാഡോകൾ, RGB കർവുകൾ എന്നിവ ക്രമീകരിക്കുക.\n• മാർക്കപ്പും റിഡാക്ഷനും: രൂപങ്ങൾ വരയ്ക്കുക, വാചകം ചേർക്കുക, അല്ലെങ്കിൽ ബ്ലർ / പിക്സലേഷൻ ഉപയോഗിച്ച് സ്വകാര്യ ഭാഗങ്ങൾ മറയ്ക്കുക.\n• സേവ് ചെയ്യാൻ ടാപ്പ് ചെയ്യുക.';

  @override
  String get helpTopicEditorTips =>
      '• സ്വകാര്യത റിഡാക്ഷൻ വഴി മാറ്റുന്ന ഭാഗങ്ങൾ ശാശ്വതമായി പുതിയ പിക്സലുകളായി മാറുന്നു.\n• വരുത്തിയ മാറ്റങ്ങൾ പഴയപടിയാക്കാൻ Undo / Redo ലഭ്യമാണ്.';

  @override
  String get helpTopicEditorPrivacy =>
      'എല്ലാ എഡിറ്റിംഗും ഉപകരണത്തിൽ മാത്രം ഓഫ്‌ലൈനായി നടക്കുന്നു. മാറ്റങ്ങൾ പുതിയ ഫയലായി സൂക്ഷിക്കുന്നു, ഒറിജിനൽ മാറ്റമില്ലാതെ തുടരും.';

  @override
  String get helpTopicConverterTitle => 'ഫോർമാറ്റ് മാറ്റലും കംപ്രഷനും';

  @override
  String get helpTopicConverterSummary =>
      'ഫോർമാറ്റുകൾ മാറ്റുക (JPEG, PNG, WEBP, BMP), വലിപ്പം കുറയ്ക്കുക, വീഡിയോ ട്രിം ചെയ്യുക.';

  @override
  String get helpTopicConverterOverview =>
      'ഫോട്ടോകളുടെ ഫോർമാറ്റ് മാറ്റുക, ഗുണനിലവാരം കുറയ്ക്കാതെ ഫയൽ വലിപ്പം കുറയ്ക്കുക, വീഡിയോയിൽ നിന്ന് നിശ്ചല ഫ്രെയിമുകൾ വേർതിരിക്കുക, വീഡിയോ GIF ആക്കുക, ട്രിം ചെയ്യുക.';

  @override
  String get helpTopicConverterSteps =>
      '• വ്യൂവർ മെനുവിൽ നിന്ന് കൺവേർട്ട് തിരഞ്ഞെടുക്കുക.\n• ആവശ്യമുള്ള ഫോർമാറ്റും ഗുണനിലവാരവും തിരഞ്ഞെടുക്കുക.\n• വലിപ്പം മാറ്റണമെങ്കിൽ റീസൈസ് മോഡ് നിശ്ചയിക്കുക.\n• ഫയൽ സൃഷ്ടിക്കാൻ കൺവേർട്ട് ടാപ്പ് ചെയ്യുക.';

  @override
  String get helpTopicConverterTips =>
      '• വീഡിയോ ടൂൾസ്: ഗുണനിലവാരം ഒട്ടും നഷ്ടപ്പെടാതെ അതിവേഗം വീഡിയോ ട്രിം ചെയ്യാം.\n• ഇഷ്ടമുള്ള ഫ്രെയിം റേറ്റിൽ വീഡിയോകൾ ആനിമേറ്റഡ് GIF ആക്കി മാറ്റാം.';

  @override
  String get helpTopicConverterPrivacy =>
      'എല്ലാ പരിവർത്തനങ്ങളും പൂർണ്ണമായും ഉപകരണത്തിൽ തന്നെ നടക്കുന്നു. പുതിയ ഫയലുകളായാണ് സേവ് ചെയ്യപ്പെടുന്നത്.';

  @override
  String get helpTopicPdfTitle =>
      'പി.ഡി.എഫ് കയറ്റുമതിയും ചിത്രങ്ങൾ വേർതിരിക്കലും';

  @override
  String get helpTopicPdfSummary =>
      'ചിത്രങ്ങൾ ചേർത്ത് പി.ഡി.എഫ് നിർമ്മിക്കുക, പി.ഡി.എഫുകളിൽ നിന്ന് ചിത്രങ്ങൾ വേർതിരിച്ചെടുക്കുക.';

  @override
  String get helpTopicPdfOverview =>
      'തിരഞ്ഞെടുത്ത ഫോട്ടോകളിൽ നിന്ന് മികച്ച പി.ഡി.എഫ് രേഖകൾ ഉണ്ടാക്കുക, അല്ലെങ്കിൽ ഏതൊരു പി.ഡി.എഫിലെയും ചിത്രങ്ങൾ ഓഫ്‌ലൈനായി വേർതിരിച്ചെടുക്കുക.';

  @override
  String get helpTopicPdfSteps =>
      '• പി.ഡി.എഫ് നിർമ്മാണം: ഫോട്ടോകൾ തിരഞ്ഞെടുക്കുക, പേജ് വലിപ്പം (A4, Letter) മാർജിൻ എന്നിവ നിശ്ചയിച്ച് എക്സ്പോർട്ട് ചെയ്യുക.\n• ചിത്രങ്ങൾ വേർതിരിക്കൽ: ടൂളിൽ നിന്ന് ഒരു പി.ഡി.എഫ് തിരഞ്ഞെടുക്കുക, കണ്ടെത്തിയ ചിത്രങ്ങൾ പരിശോധിച്ച് ഗാലറിയിലേക്ക് സേവ് ചെയ്യുക.';

  @override
  String get helpTopicPdfTips =>
      '• പേജുകളുടെ ക്രമം മാറ്റാൻ കയറ്റുമതിക്ക് മുൻപ് ഫോട്ടോകൾ പുനഃക്രമീകരിക്കാം.\n• പി.ഡി.എഫിന്റെ ക്രോസ്-റഫറൻസ് കേടായതാണെങ്കിലും ചിത്രങ്ങൾ കണ്ടെത്താൻ ടൂളിന് സാധിക്കും.';

  @override
  String get helpTopicPdfPrivacy =>
      'പി.ഡി.എഫ് പ്രക്രിയകൾ പൂർണ്ണമായും ഓഫ്‌ലൈനായി ആപ്പ് സാൻഡ്‌ബോക്സിൽ നടക്കുന്നു. ഒരു വിവരവും ക്ലൗഡിലേക്ക് അയക്കില്ല.';

  @override
  String get helpTopicSearchTitle => 'തിരച്ചിലും ടാഗുകളും';

  @override
  String get helpTopicSearchSummary =>
      'ഫിൽട്ടറുകളോടെയുള്ള അതിവേഗ FTS5 തിരച്ചിലും 12 നിറങ്ങളിലുള്ള ടാഗുകളും.';

  @override
  String get helpTopicSearchOverview =>
      'ഫോട്ടോകളുടെ തലക്കെട്ടുകൾ, കുറിപ്പുകൾ, ക്യാമറ മോഡലുകൾ, ടാഗുകൾ എന്നിവയിലൂടെ അതിവേഗം തിരയുക.';

  @override
  String get helpTopicSearchSteps =>
      '• ടൈംലൈനിലെ തിരച്ചിൽ ഐക്കൺ ടാപ്പ് ചെയ്യുക.\n• വാക്കുകൾ ടൈപ്പ് ചെയ്യുക, അല്ലെങ്കിൽ പ്രിഫിക്സ് ഉപയോഗിക്കുക: \'tag:nature\', \'type:video\', \'camera:sony\', \'place:kochi\', \'before:2024-01-01\'.\n• തീയതി, തരം, വലിപ്പം എന്നിവ സംയോജിപ്പിച്ച് ഫിൽട്ടർ ചെയ്യുക.\n• ടാഗുകൾ നിയന്ത്രിക്കാൻ ടാഗ്സ് സ്ക്രീൻ സന്ദർശിക്കുക.';

  @override
  String get helpTopicSearchTips =>
      '• 12 ആകർഷകമായ നിറങ്ങളിൽ സ്വന്തമായി ടാഗുകൾ ഉണ്ടാക്കുക.\n• ടാഗുകൾ ചേർത്താലുടൻ തിരച്ചിൽ ഫലങ്ങളിൽ ദൃശ്യമാകും.';

  @override
  String get helpTopicSearchPrivacy =>
      'തിരച്ചിൽ സൂചികകളും ചരിത്രവും പൂർണ്ണമായും നിങ്ങളുടെ ഫോണിലെ SQLite-ൽ സുരക്ഷിതമായി സൂക്ഷിക്കുന്നു.';

  @override
  String get helpTopicAlbumsTitle => 'ആൽബങ്ങളും സ്മാർട്ട് ആൽബങ്ങളും';

  @override
  String get helpTopicAlbumsSummary =>
      'വെർച്വൽ ആൽബങ്ങൾ ഉണ്ടാക്കുക, ഉപകരണ ഫോൾഡറുകൾ കാണുക, സ്മാർട്ട് ആൽബങ്ങൾ പരിശോധിക്കുക.';

  @override
  String get helpTopicAlbumsOverview =>
      'സ്വന്തം ആൽബങ്ങൾ, ഉപകരണത്തിലെ ഫയൽ ഫോൾഡറുകൾ, തനിയെ തരംതിരിക്കുന്ന സ്മാർട്ട് ആൽബങ്ങൾ എന്നിവയിലൂടെ മീഡിയ സംഘടിപ്പിക്കുക.';

  @override
  String get helpTopicAlbumsSteps =>
      '• ടൈംലൈൻ ബാറിലെ ആൽബംസ് ടാപ്പ് ചെയ്യുക.\n• വെർച്വൽ ആൽബങ്ങൾ: പുതിയ ആൽബം ഉണ്ടാക്കാൻ \'+\' അമർത്തുക, ക്രമം മാറ്റുക, കവർ ഫോട്ടോ നിശ്ചയിക്കുക.\n• സ്മാർട്ട് ആൽബങ്ങൾ: പ്രിയപ്പെട്ടവ, വീഡിയോകള്‍, GIF, റോ ഫോട്ടോകൾ, പനോരമകൾ എന്നിവ തനിയെ തരംതിരിക്കുന്നു.\n• ഫോൾഡറുകൾ: ക്യാമറ, സ്ക്രീൻഷോട്ട്, വാട്ട്‌സ്ആപ്പ് തുടങ്ങിയ ഫോൾഡറുകൾ കാണുക.';

  @override
  String get helpTopicAlbumsTips =>
      '• പ്രധാനപ്പെട്ട ആൽബങ്ങൾ മുകളിൽ കാണാൻ പിൻ ചെയ്യുക.\n• വെർച്വൽ ആൽബങ്ങൾ ഫയലുകളുടെ ഇരട്ടിപ്പുകൾ ഉണ്ടാക്കുന്നില്ല, അതിനാൽ സ്റ്റോറേജ് നഷ്ടപ്പെടില്ല.';

  @override
  String get helpTopicAlbumsPrivacy =>
      'ആൽബം വിവരങ്ങൾ പ്രാദേശിക ഡാറ്റാബേസിൽ സൂക്ഷിക്കുന്നു. ആൻഡ്രോയിഡ് സ്കോപ്പ്ഡ് സ്റ്റോറേജ് ചട്ടങ്ങൾ പാലിക്കുന്നു.';

  @override
  String get helpTopicCleanerTitle => 'ഡ്യൂപ്ലിക്കേറ്റ് ക്ലീനർ';

  @override
  String get helpTopicCleanerSummary =>
      'ഒരേപോലെയുള്ളതും സമാനവുമായ ചിത്രങ്ങൾ കണ്ടെത്തി വശങ്ങളിലായി താരതമ്യം ചെയ്യുക.';

  @override
  String get helpTopicCleanerOverview =>
      'പൂർണ്ണമായും ഒരേപോലെയുള്ള ഫയലുകളും (SHA-256 വഴി) കാഴ്ചയിൽ സാമ്യമുള്ള ഫോട്ടോകളും (pHash വഴി) കണ്ടെത്തി സ്റ്റോറേജ് ലാഭിക്കുക.';

  @override
  String get helpTopicCleanerSteps =>
      '• ടൈംലൈൻ മെനുവിൽ നിന്ന് ഡ്യൂപ്ലിക്കേറ്റ് ക്ലീനർ തുറക്കുക.\n• സ്കാൻ ആരംഭിക്കാൻ സ്കാൻ ടാപ്പ് ചെയ്യുക.\n• കണ്ടെത്തിയ ഗ്രൂപ്പുകൾ പരിശോധിച്ച് താരതമ്യം ചെയ്യുക.\n• ഏറ്റവും മികച്ച ഫോട്ടോ നിലനിർത്തി ബാക്കിയുള്ളവ മാറ്റാൻ \'മികച്ച ഫോട്ടോ നിലനിർത്തുക\' ഉപയോഗിക്കുക.';

  @override
  String get helpTopicCleanerTips =>
      '• തുടർച്ചയായി എടുത്ത ബർസ്റ്റ് ഫോട്ടോകളും ചെറുതായി എഡിറ്റ് ചെയ്തവയും കണ്ടെത്താൻ സാധിക്കും.\n• നിങ്ങളുടെ അനുമതിയില്ലാതെ ഒരു ഫയലും നീക്കം ചെയ്യില്ല.';

  @override
  String get helpTopicCleanerPrivacy =>
      'ഹാഷിംഗ് പ്രക്രിയ പൂർണ്ണമായും ഉപകരണത്തിൽ തന്നെ നടക്കുന്നു. പ്രിവ്യൂകൾ അപ്പോൾ തന്നെ മായ്ച്ചുകളയുന്നു.';

  @override
  String get helpTopicVaultTitle => 'സുരക്ഷിത പ്രൈവറ്റ് വോൾട്ട്';

  @override
  String get helpTopicVaultSummary =>
      'ഹാർഡ്‌വെയർ അധിഷ്ഠിത AES-256-GCM എൻക്രിപ്ഷൻ, ബയോമെട്രിക് & പിൻ ലോഗിൻ, സുരക്ഷിത ഷ്രെഡ്ഡിങ്.';

  @override
  String get helpTopicVaultOverview =>
      'രഹസ്യ ചിത്രങ്ങളും വീഡിയോകളും എൻക്രിപ്റ്റ് ചെയ്ത വോൾട്ടിൽ സൂക്ഷിക്കുക. ആൻഡ്രോയിഡ് കീസ്റ്റോർ സുരക്ഷ, ബയോമെട്രിക് അൺലോക്ക്, സ്ക്രീൻഷോട്ട് നിരോധനം എന്നിവ നൽകുന്നു.';

  @override
  String get helpTopicVaultSteps =>
      '• വോൾട്ട് തുറക്കാൻ ടൈംലൈനിലെ വോൾട്ട് ഐക്കൺ ടാപ്പ് ചെയ്യുക.\n• ഒരു മാസ്റ്റർ പിൻ നൽകുക (ബയോമെട്രിക്സും പ്രവർത്തനക്ഷമമാക്കാം).\n• ചിത്രങ്ങൾ വോൾട്ടിലേക്ക് ഇംപോർട്ട് ചെയ്യുക. ഒറിജിനൽ ഫയൽ സുരക്ഷിതമായി മായ്ക്കണമോ എന്ന് തിരഞ്ഞെടുക്കാം.\n• വോൾട്ടിനുള്ളിൽ സുരക്ഷിതമായി കാണുക.';

  @override
  String get helpTopicVaultTips =>
      '• വോൾട്ടിനുള്ളിൽ ആയിരിക്കുമ്പോൾ സ്ക്രീൻഷോട്ടുകൾ തടയപ്പെടുന്നു (FLAG_SECURE).\n• ആപ്പ് മാറുമ്പോഴോ നിശ്ചിത സമയം കഴിയുമ്പോഴോ വോൾട്ട് തനിയെ ലോക്കാകുന്നു.';

  @override
  String get helpTopicVaultPrivacy =>
      'ഡീക്രിപ്റ്റ് ചെയ്ത വിവരങ്ങൾ മെമ്മറിയിൽ മാത്രമേ നിൽക്കൂ. കീകൾ ആൻഡ്രോയിഡ് കീസ്റ്റോർ ഹാർഡ്‌വെയറിൽ സുരക്ഷിതമാണ്.';

  @override
  String get helpTopicSyncTitle => 'ലോക്കൽ വൈ-ഫൈ കൈമാറ്റം';

  @override
  String get helpTopicSyncSummary =>
      'ഇന്റർനെറ്റ് ഇല്ലാതെ ഒരേ വൈ-ഫൈയിലുള്ള ഉപകരണങ്ങൾ തമ്മിൽ നേരിട്ടുള്ള ഫയൽ കൈമാറ്റം.';

  @override
  String get helpTopicSyncOverview =>
      'ഒരേ വൈ-ഫൈ റൂട്ടറിലുള്ള രണ്ട് ഫോണുകൾ തമ്മിൽ ചിത്രങ്ങളും വീഡിയോകളും നേരിട്ട് കൈമാറുക. എൻഡ്-ടു-എൻഡ് എൻക്രിപ്ഷനിലൂടെ സുരക്ഷിതം.';

  @override
  String get helpTopicSyncSteps =>
      '• സ്വീകരിക്കുന്ന ഫോണിൽ: ട്രാൻസ്ഫർ > റിസീവ് തുറന്ന് QR കോഡ് കാണിക്കുക.\n• അയക്കുന്ന ഫോണിൽ: ട്രാൻസ്ഫർ > സെൻഡ് തുറന്ന് കോഡ് സ്കാൻ ചെയ്യുക (അല്ലെങ്കിൽ 6 അക്ഷര കോഡ് നൽകുക).\n• ഫോട്ടോകൾ തിരഞ്ഞെടുത്ത് അയക്കുക.\n• ലഭിക്കുന്ന ഫയലുകൾ SHA-256 വഴി പരിശോധിച്ച് ഗാലറിയിൽ ചേർക്കുന്നു.';

  @override
  String get helpTopicSyncTips =>
      '• ഇന്റർനെറ്റ് കണക്ഷൻ ആവശ്യമില്ല; ലോക്കൽ ഐപി വഴി നേരിട്ട് ബന്ധിപ്പിക്കുന്നു.\n• സ്ക്രീൻ തുറന്നിരിക്കുമ്പോൾ മാത്രമേ സോക്കറ്റ് പ്രവർത്തിക്കൂ, സ്ക്രീൻ വിടുമ്പോൾ ഉടൻ بندാകും.';

  @override
  String get helpTopicSyncPrivacy =>
      'പുറത്തുനിന്നുള്ള ഇന്റർനെറ്റ് വിലാസങ്ങളിലേക്കുള്ള കണക്ഷനുകൾ LocalAddressRules വഴി തടയുന്നു. ട്രാക്കിംഗോ ക്ലൗഡോ ഇല്ല.';

  @override
  String get helpTopicBackupTitle => 'ബാക്കപ്പും പുനഃസ്ഥാപനവും';

  @override
  String get helpTopicBackupSummary =>
      'പാസ്‌വേഡ് സംരക്ഷിത .gbak ഫയലുകൾ നിർമ്മിക്കുകയും സുരക്ഷിതമായി പുനഃസ്ഥാപിക്കുകയും ചെയ്യുക.';

  @override
  String get helpTopicBackupOverview =>
      'നിങ്ങളുടെ ടാഗുകൾ, ആൽബങ്ങൾ, കുറിപ്പുകൾ, വിവരങ്ങൾ എന്നിവ AES-256-GCM എൻക്രിപ്റ്റ് ചെയ്ത ബാക്കപ്പിൽ സുരക്ഷിതമാക്കുക.';

  @override
  String get helpTopicBackupSteps =>
      '• മെനുവിൽ നിന്ന് ബാക്കപ്പ് ടാപ്പ് ചെയ്യുക.\n• ബാക്കപ്പ് ഉണ്ടാക്കാൻ: ശക്തമായ ഒരു പാസ്‌വേഡ് നൽകി ഫയൽ ഉപകരണത്തിലേക്ക് സേവ് ചെയ്യുക.\n• പുനഃസ്ഥാപിക്കാൻ: മുൻപ് സേവ് ചെയ്ത .gbak ഫയൽ തിരഞ്ഞെടുക്കുക, പാസ്‌വേഡ് നൽകി പ്രിവ്യൂ കണ്ട് നടപ്പിലാക്കുക.';

  @override
  String get helpTopicBackupTips =>
      '• പഴയ വിവരങ്ങൾ മായ്ക്കാതെ പുതിയവ ചേർക്കുന്ന സുരക്ഷിത രീതിയാണ് പുനഃസ്ഥാപനത്തിനുള്ളത്.\n• പാസ്‌വേഡ് മറന്നുപോകാതെ സൂക്ഷിക്കുക; പാസ്‌വേഡ് ഇല്ലാതെ ബാക്കപ്പ് തുറക്കാനാവില്ല.';

  @override
  String get helpTopicBackupPrivacy =>
      'ബാക്കപ്പ് ഫയലുകൾ PBKDF2, AES-256-GCM സാങ്കേതികവിദ്യകളാൽ എൻക്രിപ്റ്റ് ചെയ്താണ് സൂക്ഷിക്കുന്നത്.';

  @override
  String get helpTopicScannerTitle => 'QR സ്കാനറും OCR ഉം';

  @override
  String get helpTopicScannerSummary =>
      'ഫോട്ടോകളിൽ നിന്ന് QR/ബാർകോഡ് സ്കാൻ ചെയ്യുക, ഓഫ്‌ലൈൻ OCR വഴി വാചകം വേർതിരിക്കുക.';

  @override
  String get helpTopicScannerOverview =>
      'ഫോട്ടോകളിലുള്ള QR കോഡുകളും ബാർകോഡുകളും വായിക്കുക, അല്ലെങ്കിൽ ഇംഗ്ലീഷ്, മലയാളം അക്ഷരങ്ങൾ ഓഫ്‌ലൈൻ Tesseract OCR വഴി തിരിച്ചറിയുക.';

  @override
  String get helpTopicScannerSteps =>
      '• ഫോട്ടോ തുറന്ന് മെനുവിൽ നിന്ന് \'സ്കാൻ കോഡ്\' അല്ലെങ്കിൽ \'വാചകം വേർതിരിക്കുക\' തിരഞ്ഞെടുക്കുക.\n• സ്കാൻ കോഡ്: ലിങ്ക്, വൈ-ഫൈ വിവരങ്ങൾ എന്നിവ പരിശോധിച്ച് തുറക്കാം.\n• വാചകം: കണ്ടെത്തിയ വാചകം പകർത്തിയെടുക്കുകയോ ഫോട്ടോയുടെ കുറിപ്പുകളിലേക്ക് ചേർക്കുകയോ ചെയ്യാം.';

  @override
  String get helpTopicScannerTips =>
      '• ഇംഗ്ലീഷും മലയാളവും തിരിച്ചറിയാൻ ആപ്പിൽ തന്നെ മോഡലുകൾ ഉൾപ്പെടുത്തിയിട്ടുണ്ട്; ഇന്റർനെറ്റ് ആവശ്യമില്ല.\n• വൈ-ഫൈ കോഡുകൾ വഴി സുരക്ഷിതമായി പാസ്‌വേഡ് പകർത്താം.';

  @override
  String get helpTopicScannerPrivacy =>
      'എല്ലാ കോഡ് റീഡിംഗും OCR ഉം നിങ്ങളുടെ ഉപകരണത്തിൽ മാത്രമാണ് നടക്കുന്നത്.';

  @override
  String get titleSettingsDefaultApp => 'ഡിഫോൾട്ട് ഗാലറി ആപ്പ്';

  @override
  String get descSettingsDefaultAppSubtitle =>
      'ഫോട്ടോകളും വീഡിയോകളും കാണുന്നതിനുള്ള പ്രധാന ആപ്പായി സജ്ജീകരിക്കുക';

  @override
  String get titleDefaultAppDialog => 'ഡിഫോൾട്ട് ഗാലറിയാക്കുക';

  @override
  String get bodyDefaultAppDialog =>
      'ഈ ആപ്പ് ഡിഫോൾട്ട് ആക്കുന്നതിന്:\n\n1. ഫോണിലെ ഏതെങ്കിലും ഫോട്ടോയോ വീഡിയോയോ തുറക്കുക (ഉദാഹരണത്തിന് Files അല്ലെങ്കിൽ Downloads-ൽ നിന്ന്).\n2. SreerajP ഗാലറി തിരഞ്ഞെടുത്ത് \'Always\' നൽകുക.\n\nമറ്റൊരു ആപ്പ് ഇപ്പോൾ ഫോട്ടോകൾ തുറക്കുന്നുണ്ടെങ്കിൽ, ആദ്യം അതിന്റെ ഡിഫോൾട്ട് മാറ്റുക: ആൻഡ്രോയിഡ് സെറ്റിംഗ്സ് → Apps → ആ ആപ്പ് → Open by default.';

  @override
  String get titleTrash => 'ചവറ്റുകുട്ട';

  @override
  String get emptyTrash => 'ചവറ്റുകുട്ട ശൂന്യമാണ്';

  @override
  String get descTrashEmptySubtitle =>
      'നിങ്ങൾ ഇല്ലാതാക്കുന്ന ഇനങ്ങൾ ചവറ്റുകുട്ട ശൂന്യമാക്കുന്നതുവരെ ഇവിടെ സൂക്ഷിക്കും.';

  @override
  String get tooltipTrashEmptyAction => 'ചവറ്റുകുട്ട ശൂന്യമാക്കുക';

  @override
  String get titleTrashEmptyConfirm => 'ചവറ്റുകുട്ട ശൂന്യമാക്കണോ?';

  @override
  String get bodyTrashEmptyConfirm =>
      'ഇത് നിങ്ങളുടെ ഫോൺ സംഭരണത്തിൽ നിന്ന് എല്ലാ ഇനങ്ങളും ശാശ്വതമായി ഇല്ലാതാക്കും. ഈ പ്രവർത്തനം പഴയപടിയാക്കാൻ കഴിയില്ല.';

  @override
  String get titleTrashDeletePermanentlyAction => 'ശാശ്വതമായി ഇല്ലാതാക്കുക';

  @override
  String get titleTrashDeletePermanentlyConfirm => 'ശാശ്വതമായി ഇല്ലാതാക്കണോ?';

  @override
  String get bodyTrashDeletePermanentlyConfirm =>
      'ഈ ഇനം നിങ്ങളുടെ ഫോൺ സംഭരണത്തിൽ നിന്ന് ശാശ്വതമായി ഇല്ലാതാക്കും. ഈ പ്രവർത്തനം പഴയപടിയാക്കാൻ കഴിയില്ല.';

  @override
  String get bodyTrashDeletedPermanentlySnackbar =>
      'ഇനം ശാശ്വതമായി ഇല്ലാതാക്കി';

  @override
  String get actionTrashRestore => 'പുനഃസ്ഥാപിക്കുക';

  @override
  String get tooltipTrashRestoreAllAction => 'എല്ലാം പുനഃസ്ഥാപിക്കുക';

  @override
  String get bodyTrashRestoreAllConfirm =>
      'ചവറ്റുകുട്ടയിലെ എല്ലാ ഇനങ്ങളും നിങ്ങളുടെ ലൈബ്രറിയിലേക്ക് മടക്കും.';

  @override
  String get bodyTrashRestoredSnackbar =>
      'ചവറ്റുകുട്ടയിൽ നിന്ന് പുനഃസ്ഥാപിച്ചു';

  @override
  String get bodyTrashEmptiedSnackbar => 'ചവറ്റുകുട്ട ശൂന്യമാക്കി';

  @override
  String bodyTrashItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഇനങ്ങൾ ചവറ്റുകുട്ടയിൽ',
      one: '1 ഇനം ചവറ്റുകുട്ടയിൽ',
    );
    return '$_temp0';
  }

  @override
  String get descSettingsAppearanceSubtitle => 'തീം, ഗ്രിഡ് സാന്ദ്രത, ഓർമ്മകൾ';

  @override
  String get descSettingsLanguageSubtitle =>
      'സിസ്റ്റം, ഇംഗ്ലീഷ്, മലയാളം, സംസ്കൃതം';

  @override
  String get descSettingsSafetySubtitle =>
      'ഇല്ലാതാക്കുന്നതിന് മുമ്പ് സ്ഥിരീകരണം';

  @override
  String get descSettingsDefaultAppCardSubtitle =>
      'ഡിഫോൾട്ട് ഗാലറി ആപ്പ് ആയി സജ്ജമാക്കുക';

  @override
  String get descSettingsPrivacySubtitle => 'ഉള്ളടക്കം മറയ്ക്കലും വോൾട്ടും';

  @override
  String get descSettingsHelpCardSubtitle =>
      'എല്ലാ ഫീച്ചറുകൾക്കുമുള്ള ഗൈഡുകളും സ്വകാര്യത ഉറപ്പുകളും';

  @override
  String get descSettingsAboutSubtitle => 'പതിപ്പ്, രചയിതാവ്, ലൈസൻസ്';

  @override
  String get descSettingsDeveloperSubtitle => 'മീഡിയ സ്കാനർ ടൂളുകൾ';

  @override
  String get titleViewerTrashConfirm => 'ട്രാഷിലേക്ക് മാറ്റണോ?';

  @override
  String get bodyViewerTrashConfirm =>
      'ഈ ഇനം ട്രാഷിലേക്ക് മാറ്റപ്പെടും. ട്രാഷ് ആൽബത്തിൽ നിന്ന് ഇത് എപ്പോൾ വേണമെങ്കിലും പുനഃസ്ഥാപിക്കാം.';

  @override
  String get bodyViewerTrashSuccess => 'ട്രാഷിലേക്ക് മാറ്റി';

  @override
  String get actionViewerTrashUndo => 'പഴയപടിയാക്കുക';

  @override
  String get titleComparePhotos => 'A/B ഫോട്ടോ താരതമ്യം';

  @override
  String get labelCompareModeSplit => 'സ്പ്ലിറ്റ് കാഴ്ച';

  @override
  String get labelCompareModeCurtain => 'സ്ലൈഡിംഗ് കർട്ടൻ';

  @override
  String get labelCompareSplitHorizontal => 'വശങ്ങളിലായി';

  @override
  String get labelCompareSplitVertical => 'മുകളിലും താഴെയുമായി';

  @override
  String get bodyCompareSyncLocked => 'പാനും സൂമും ലോക്ക് ചെയ്‌തു';

  @override
  String get bodyCompareSyncUnlocked => 'വ്യത്യസ്ത പാനും സൂമും';

  @override
  String get tooltipCompareSwap => 'ഫോട്ടോകൾ പരസ്പരം മാറ്റുക';

  @override
  String get tooltipCompareResetZoom => 'സൂം പുനഃക്രമീകരിക്കുക';

  @override
  String get tooltipCompareDetails => 'വിശദാംശങ്ങൾ താരതമ്യം ചെയ്യുക';

  @override
  String get labelComparePhotoA => 'ഫോട്ടോ A';

  @override
  String get labelComparePhotoB => 'ഫോട്ടോ B';

  @override
  String get titleCompareWithPrevious =>
      'മുമ്പത്തെ ഫോട്ടോയുമായി താരതമ്യം ചെയ്യുക';

  @override
  String get titleCompareWithNext => 'അടുത്ത ഫോട്ടോയുമായി താരതമ്യം ചെയ്യുക';

  @override
  String get titleCompareChooseFromGallery => 'ഗാലറിയിൽ നിന്ന് തിരഞ്ഞെടുക്കുക';

  @override
  String get tooltipCompare => 'ഫോട്ടോകൾ പരസ്പരം താരതമ്യം ചെയ്യുക';

  @override
  String get bodyCompareSelectSecondPhoto =>
      'താരതമ്യം ചെയ്യാൻ ഫോട്ടോ തിരഞ്ഞെടുക്കുക';

  @override
  String get labelCompareDimensions => 'അളവുകൾ';

  @override
  String get labelCompareFileSize => 'ഫയൽ വലുപ്പം';

  @override
  String get labelCompareDateTaken => 'എടുത്ത തീയതി';

  @override
  String get labelCompareCamera => 'ക്യാമറ';

  @override
  String get labelCompareIso => 'ISO';

  @override
  String get labelCompareAperture => 'അപ്പർച്ചർ';

  @override
  String get labelCompareShutterSpeed => 'ഷട്ടർ സ്പീഡ്';

  @override
  String get labelCompareFocalLength => 'ഫോക്കൽ ലെങ്ത്';

  @override
  String get tabTimeline => 'ടൈംലൈൻ';

  @override
  String get tabFolders => 'ഫോൾഡറുകൾ';

  @override
  String get tabAlbums => 'ആൽബങ്ങൾ';

  @override
  String get titleFolders => 'ഫോൾഡറുകൾ';

  @override
  String get emptyFolders => 'ഫോൾഡറുകളൊന്നും കണ്ടെത്തിയില്ല';

  @override
  String get bodyFoldersEmpty =>
      'ഉപകരണത്തിലെ ചിത്രങ്ങളും വീഡിയോകളും തിരയാൻ താഴേക്ക് വലിക്കുക.';

  @override
  String get tooltipPrivacyScrubberTitle => 'മീഡിയ സ്വകാര്യതയും സ്ക്രബ്ബറും';

  @override
  String get descPrivacyScrubberSubtitle =>
      'പങ്കുവെക്കുന്നതിന് മുമ്പ് സെൻസിറ്റീവ് EXIF മെറ്റാഡാറ്റ നീക്കം ചെയ്യുകയും GPS സ്ഥാനം മാറ്റുകയും ചെയ്യുക';

  @override
  String get titlePrivacyScrubberMenu => 'സ്വകാര്യതയും EXIF സ്ക്രബ്ബറും';

  @override
  String get titlePrivacyCard => 'മീഡിയ സ്വകാര്യതയും EXIF വിവരങ്ങളും';

  @override
  String get bodyPrivacyCard =>
      'ഫോട്ടോ പങ്കിടുന്നതിന് മുമ്പ് കൃത്യമായ GPS ലൊക്കേഷൻ, ക്യാമറ സീരിയൽ നമ്പറുകൾ എന്നിവ നീക്കം ചെയ്ത് സ്വകാര്യത സംരക്ഷിക്കുക.';

  @override
  String get bodyPrivacyOpenScrubber => 'സ്വകാര്യതാ ക്രമീകരണങ്ങൾ തുറക്കുക';

  @override
  String get labelPrivacyTabStripper => 'EXIF നീക്കം ചെയ്യൽ';

  @override
  String get labelPrivacyTabGeofence => 'GPS ജിയോഫെൻസ് ഷിഫ്റ്റർ';

  @override
  String get actionPrivacyStripAndShare =>
      'ഒറ്റ ടാപ്പിൽ നീക്കം ചെയ്ത് പങ്കിടുക';

  @override
  String get actionPrivacySaveSanitized =>
      'നീക്കം ചെയ്ത കോപ്പി ഗാലറിയിൽ സൂക്ഷിക്കുക';

  @override
  String get titlePrivacyGranular => 'തിരഞ്ഞെടുത്ത മെറ്റാഡാറ്റ നീക്കം ചെയ്യൽ';

  @override
  String get labelPrivacyStripAll => 'എല്ലാം നീക്കം ചെയ്യുക';

  @override
  String get labelPrivacyCustom => 'ഇഷ്‌ടാനുസൃതം';

  @override
  String get titlePrivacyOptionGps => 'GPS ലൊക്കേഷനും ഉയരവും നീക്കം ചെയ്യുക';

  @override
  String get titlePrivacyOptionSerials => 'സീരിയൽ നമ്പർ നീക്കുക';

  @override
  String get titlePrivacyOptionTimestamps => 'തീയതി-സമയം നീക്കുക';

  @override
  String get titlePrivacyOptionAuthor => 'നിർമ്മാണവിവരം നീക്കുക';

  @override
  String get bodyPrivacyErrorReadingFile => 'ഫയൽ വായിക്കാൻ സാധിച്ചില്ല';

  @override
  String get titlePrivacyShare => 'സുരക്ഷിതമായി മീഡിയ പങ്കിടുക';

  @override
  String get errorPrivacyShareFailed => 'പങ്കിടാൻ സാധിച്ചില്ല';

  @override
  String get errorPrivacyProcess =>
      'മെറ്റാഡാറ്റ നീക്കം ചെയ്യുന്നതിൽ പിശക് സംഭവിച്ചു';

  @override
  String get bodyPrivacySavedToGallery =>
      'സുരക്ഷിതമായ കോപ്പി ഗാലറിയിൽ സേവ് ചെയ്തു';

  @override
  String get errorPrivacySaveFailed => 'സേവ് ചെയ്യാൻ സാധിച്ചില്ല';

  @override
  String get bodyPrivacyNoLocation => 'ഈ ഫോട്ടോയിൽ GPS വിവരങ്ങൾ കണ്ടെത്തിയില്ല';

  @override
  String get bodyGeofenceOffsetDistance => 'ഷിഫ്റ്റ് ചെയ്യേണ്ട ദൂരം';

  @override
  String get tooltipGeofenceReroll => 'പുതിയ റാൻഡം ലൊക്കേഷൻ കണ്ടെത്തുക';

  @override
  String get labelGeofenceRandomPreset => 'റാൻഡം (2–5 കി.മീ)';

  @override
  String bodyGeofenceShiftSummary(String summary) {
    return '$summary ലേക്ക് മാറ്റി';
  }

  @override
  String bodyGeofenceFuzzedCoordinates(String lat, String lon) {
    return '$lat, $lon ലേക്ക് മാറ്റി';
  }

  @override
  String get descGeofenceExplanation =>
      'കൃത്യമായ വീടിന്റെയോ താമസസ്ഥലത്തിന്റെയോ വിലാസം മറച്ചുവെച്ച് നഗരത്തിന്റെ പൊതുവായ ലൊക്കേഷൻ മാത്രം നിലനിർത്തുന്നു.';

  @override
  String get titleGeofenceShare => 'ലൊക്കേഷൻ മാറ്റിയ ഫോട്ടോ പങ്കിടുക';

  @override
  String get actionGeofenceShare => 'ലൊക്കേഷൻ മാറ്റി പങ്കിടുക';

  @override
  String get actionGeofenceSave => 'ഗാലറിയിലേക്ക് സേവ് ചെയ്യുക';

  @override
  String get bodyGeofenceSavedToGallery =>
      'ലൊക്കേഷൻ മാറ്റിയ ഫോട്ടോ ഗാലറിയിൽ സേവ് ചെയ്തു';

  @override
  String get labelGeofenceNoCoordinates => 'ലൊക്കേഷൻ കണ്ടെത്തിയില്ല';

  @override
  String get bodyGeofenceNoCoordinates =>
      'ഈ ഫോട്ടോയിൽ മാറ്റാൻ തക്ക GPS വിവരങ്ങൾ അടങ്ങിയിട്ടില്ല.';

  @override
  String get bodyPrivacyAuditSensitiveDetected => 'സ്വകാര്യ വിവരങ്ങൾ കണ്ടെത്തി';

  @override
  String get bodyPrivacyAuditClean => 'സെൻസിറ്റീവ് വിവരങ്ങൾ ഒന്നുമില്ല';

  @override
  String bodyPrivacyAuditSensitiveDetails(String gps, String camera) {
    return 'അടങ്ങിയിരിക്കുന്നത്: $gps $camera';
  }

  @override
  String get labelPrivacyAuditGps => 'GPS ലൊക്കേഷൻ';

  @override
  String get labelPrivacyAuditCamera => 'ഡിവൈസ് വിവരങ്ങൾ';

  @override
  String get bodyPrivacyAuditCleanDetails =>
      'ഈ ഫയലിൽ ലൊക്കേഷനോ സീരിയൽ നമ്പറോ അടങ്ങിയിട്ടില്ല.';

  @override
  String get titleForensicInspector => 'ഫോറൻസിക് ലെൻസ് & സെൻസർ ഇൻസ്പെക്ടർ';

  @override
  String get descForensicInspectorSubtitle =>
      'വിശദമായ ഒപ്റ്റിക്കൽ, ഹാർഡ്‌വെയർ സാങ്കേതിക വിവരങ്ങൾ';

  @override
  String get actionForensicInspector => 'ലെൻസ്-സെൻസർ പരിശോധന';

  @override
  String get helpForensicInspectorQuickHint =>
      'സെൻസർ ക്രോപ്പ് ഫാക്ടർ, 35mm തുല്യത, ഷട്ടർ കൗണ്ട്, എക്സ്പോഷർ ബയസ്';

  @override
  String get bodyForensicNoData => 'ഫോറൻസിക് മെറ്റാഡാറ്റ ലഭ്യമല്ല.';

  @override
  String get bodyForensicSectionSensorOptics => 'സെൻസർ & ഒപ്റ്റിക്കൽ സവിശേഷതകൾ';

  @override
  String get bodyForensicSectionMechanicsColor =>
      'മെക്കാനിക്കൽ റിലീസുകളും കളർ സ്പേസും';

  @override
  String get bodyForensicSectionHardwareIdentity =>
      'ഹാർഡ്‌വെയർ & ലെൻസ് തിരിച്ചറിയൽ';

  @override
  String get labelForensicSensorFormat => 'സെൻസർ ഫോർമാറ്റ്';

  @override
  String get labelForensicCropFactor => 'ക്രോപ്പ് ഫാക്ടർ';

  @override
  String get labelForensicFocal35mm => '35mm തുല്യത';

  @override
  String get labelForensicPhysicalFocalLength => 'യഥാർത്ഥ ഫോക്കൽ ലെങ്ത്';

  @override
  String get labelForensicHyperfocalDistance => 'ഹൈപ്പർഫോക്കൽ ദൂരം';

  @override
  String get labelForensicExposureBias => 'എക്സ്പോഷർ കോമ്പൻസേഷൻ (EV)';

  @override
  String get labelForensicShutterActuations => 'ഷട്ടർ ആക്ച്വേഷനുകൾ';

  @override
  String get bodyForensicShutterNotReported => 'ഇലക്ട്രോണിക് ഷട്ടർ / ലഭ്യമല്ല';

  @override
  String get labelForensicColorProfile => 'കളർ സ്പേസ് പ്രൊഫൈൽ';

  @override
  String get labelForensicExposureProgram => 'എക്സ്പോഷർ പ്രോഗ്രാം';

  @override
  String get labelForensicMeteringMode => 'മീറ്ററിംഗ് മോഡ്';

  @override
  String get labelForensicSensingMethod => 'സെൻസിംഗ് രീതി';

  @override
  String get labelForensicSceneCaptureType => 'സീൻ ക്യാപ്‌ചർ തരം';

  @override
  String get labelForensicFlashStatus => 'ഫ്ലാഷ് നില';

  @override
  String get labelForensicCameraSerial => 'ക്യാമറ സീരിയൽ നമ്പർ';

  @override
  String get labelForensicLensModel => 'ലെൻസ് മോഡൽ';

  @override
  String get labelForensicLensSpecification => 'ലെൻസ് സ്പെസിഫിക്കേഷൻ';

  @override
  String get labelForensicLensSerial => 'ലെൻസ് സീരിയൽ നമ്പർ';

  @override
  String get bodyForensicSerialNotEmbedded => 'രേഖപ്പെടുത്തിയിട്ടില്ല';

  @override
  String get tooltipShowPassword => 'പാസ്‌വേഡ് കാണിക്കുക';

  @override
  String get tooltipHidePassword => 'പാസ്‌വേഡ് മറയ്ക്കുക';

  @override
  String labelDistanceKm(String distance) {
    return '$distance കി.മീ.';
  }

  @override
  String labelCompareBadge(String photo, String name) {
    return '$photo: $name';
  }

  @override
  String get aboutDetailAuthor => 'രചയിതാവ്';

  @override
  String get aboutDetailLicense => 'ലൈസൻസ്';

  @override
  String get aboutDetailIdeUsed => 'ഉപയോഗിച്ച IDE';

  @override
  String get aboutDetailAiUsed => 'ഉപയോഗിച്ച AI';

  @override
  String get aboutDetailStorageModel => 'സംഭരണ രീതി';

  @override
  String get aboutDetailNetworkPolicy => 'നെറ്റ്‌വർക്ക് നയം';

  @override
  String get aboutDetailSecurity => 'സുരക്ഷ';

  @override
  String get aboutDetailLanguages => 'ഭാഷകൾ';

  @override
  String madeWithLove(String heart) {
    return 'സ്നേഹത്തോടെ $heart ഇന്ത്യയിൽ നിന്ന്';
  }

  @override
  String get madeWithLoveA11y => 'സ്നേഹത്തോടെ ഇന്ത്യയിൽ നിന്ന്';

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
      other: '$count തവണ',
      one: '1 തവണ',
    );
    return '$_temp0';
  }

  @override
  String bodyTransferBytesProgress(String done, String total) {
    return '$total-ൽ $done';
  }

  @override
  String bodyPdfImageFormatAndSize(String format, String size) {
    return '$format · $size';
  }

  @override
  String get labelColorRed => 'ചുവപ്പ്';

  @override
  String get labelColorPink => 'പിങ്ക്';

  @override
  String get labelColorPurple => 'പർപ്പിൾ';

  @override
  String get labelColorDeepPurple => 'കടും പർപ്പിൾ';

  @override
  String get labelColorIndigo => 'ഇൻഡിഗോ';

  @override
  String get labelColorBlue => 'നീല';

  @override
  String get labelColorTeal => 'പച്ചനീല';

  @override
  String get labelColorGreen => 'പച്ച';

  @override
  String get labelColorLightGreen => 'ഇളം പച്ച';

  @override
  String get labelColorAmber => 'ആമ്പർ';

  @override
  String get labelColorDeepOrange => 'കടും ഓറഞ്ച്';

  @override
  String get labelColorBrown => 'തവിട്ട്';

  @override
  String get labelColorYellow => 'മഞ്ഞ';

  @override
  String get labelColorWhite => 'വെള്ള';

  @override
  String get labelColorBlack => 'കറുപ്പ്';

  @override
  String get labelA11yCropArea => 'ക്രോപ്പ് ഭാഗം';

  @override
  String bodyA11yCropAreaValue(int left, int top, int width, int height) {
    return 'ഇടത് $left%, മുകളിൽ $top%, വീതി $width%, ഉയരം $height%';
  }

  @override
  String get helpA11yCropAreaHint =>
      'മൂലകൾ വലിക്കുക, അല്ലെങ്കിൽ നീക്കാനും വലുപ്പം മാറ്റാനും പ്രവർത്തനങ്ങൾ ഉപയോഗിക്കുക';

  @override
  String get labelA11yMoveLeft => 'ഇടത്തോട്ട് നീക്കുക';

  @override
  String get labelA11yMoveRight => 'വലത്തോട്ട് നീക്കുക';

  @override
  String get labelA11yMoveUp => 'മുകളിലേക്ക് നീക്കുക';

  @override
  String get labelA11yMoveDown => 'താഴേക്ക് നീക്കുക';

  @override
  String get labelA11yMakeSmaller => 'ചെറുതാക്കുക';

  @override
  String get labelA11yMakeLarger => 'വലുതാക്കുക';

  @override
  String get labelA11yCurveArea => 'ടോൺ കർവ്';

  @override
  String bodyA11yCurveValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count പോയിന്റുകൾ',
      one: '1 പോയിന്റ്',
    );
    return '$_temp0';
  }

  @override
  String get labelA11yMarkupArea => 'വരയ്ക്കാനുള്ള ഭാഗം';

  @override
  String bodyA11yMarkupValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count അടയാളങ്ങൾ',
      one: '1 അടയാളം',
      zero: 'ഒന്നും വരച്ചിട്ടില്ല',
    );
    return '$_temp0';
  }

  @override
  String get helpA11yDrawingNeedsTouchHint =>
      'വരയ്ക്കാൻ സ്പർശനം വേണം. അടയാളങ്ങൾ മാറ്റാനോ നീക്കാനോ താഴെയുള്ള പാനൽ ഉപയോഗിക്കുക.';

  @override
  String get labelA11yRedactionArea => 'മറയ്ക്കാനുള്ള ഭാഗം';

  @override
  String bodyA11yRedactionValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഭാഗങ്ങൾ മറച്ചു',
      one: '1 ഭാഗം മറച്ചു',
      zero: 'ഒന്നും മറച്ചിട്ടില്ല',
    );
    return '$_temp0';
  }

  @override
  String get labelA11yMaskArea => 'മാസ്കിന്റെ സ്ഥാനം';

  @override
  String bodyA11yMaskValue(String shape, int x, int y) {
    return '$shape, മധ്യം $x% കുറുകെ, $y% താഴെ';
  }

  @override
  String get helpA11yMaskHint =>
      'ഹാൻഡിലുകൾ വലിക്കുക, അല്ലെങ്കിൽ മാസ്ക് നീക്കാൻ പ്രവർത്തനങ്ങൾ ഉപയോഗിക്കുക';

  @override
  String get labelA11yCompareDivider => 'താരതമ്യ വിഭജനരേഖ';

  @override
  String bodyA11yPercentValue(int percent) {
    return '$percent%';
  }

  @override
  String get errorOpenWithRefused =>
      'ഈ ഫയൽ ഇവിടെ തുറക്കാനാവില്ല. പകരം ഗാലറിയിൽ നിന്ന് തുറക്കുക.';

  @override
  String get errorOpenWithFailed =>
      'ഫയൽ തുറക്കാനായില്ല. അത് നീക്കുകയോ മായ്ക്കുകയോ ചെയ്തിരിക്കാം.';

  @override
  String get bodyCleanerFailed =>
      'ഫോട്ടോകൾ താരതമ്യം ചെയ്യുമ്പോൾ എന്തോ പിശക് സംഭവിച്ചു. വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get aboutDetailEmail => 'ഇമെയിൽ';

  @override
  String get aboutDetailPrivacyPolicy => 'സ്വകാര്യതാ നയം';

  @override
  String get titleSettingsProtectScreens => 'ഉള്ളടക്കം മറയ്ക്കുക';

  @override
  String get descSettingsProtectScreens =>
      'എല്ലാ സ്ക്രീനിലും സ്ക്രീൻഷോട്ടുകളും സ്ക്രീൻ റെക്കോർഡിങ്ങും തടയുകയും സമീപകാല ആപ്പുകളിൽ ശൂന്യമായ കാർഡ് കാണിക്കുകയും ചെയ്യും. വോൾട്ട് എപ്പോഴും സംരക്ഷിതമാണ്.';

  @override
  String get titleSettingsPermissions => 'അനുമതികൾ';

  @override
  String get descSettingsPermissionsSubtitle =>
      'ആപ്പിന് എന്തെല്ലാം ഉപയോഗിക്കാം, എന്തിന്';

  @override
  String get labelPermissionsExplicit => 'നിങ്ങൾ അനുവദിക്കുന്നവ';

  @override
  String get labelPermissionsImplicit => 'സ്വയം ലഭിക്കുന്നവ';

  @override
  String get labelPermissionsRemoved => 'മനഃപൂർവം ഒഴിവാക്കിയവ';

  @override
  String get descPermissionsExplicit =>
      'ഇവ ഉപയോഗിക്കുന്നതിന് മുമ്പ് ആൻഡ്രോയിഡ് നിങ്ങളോട് ചോദിക്കും. ആൻഡ്രോയിഡ് ക്രമീകരണങ്ങളിൽ എപ്പോൾ വേണമെങ്കിലും ഇവ മാറ്റാം.';

  @override
  String get descPermissionsImplicit =>
      'ആപ്പ് ഇൻസ്റ്റാൾ ചെയ്യുമ്പോൾ ആൻഡ്രോയിഡ് ചോദിക്കാതെ ഇവ നൽകുന്നു. ഇവയൊന്നും നിങ്ങളുടെ ചിത്രങ്ങളിലേക്കോ ഫയലുകളിലേക്കോ പ്രവേശനം നൽകുന്നില്ല.';

  @override
  String get descPermissionsRemoved =>
      'ആപ്പ് നിർമ്മിക്കാൻ ഉപയോഗിച്ച ചില ലൈബ്രറികൾ ഇവ ആവശ്യപ്പെടുന്നു. ആപ്പ് ഇവ നീക്കം ചെയ്യുന്നതിനാൽ ഇവ ഒരിക്കലും ആപ്പിന് ലഭിക്കില്ല.';

  @override
  String get descPermissionsManage =>
      'നിങ്ങൾ അനുവദിച്ചവ മാറ്റാൻ, ആൻഡ്രോയിഡ് ക്രമീകരണങ്ങളിൽ ഈ ആപ്പിന്റെ താൾ തുറക്കുക.';

  @override
  String get labelPermPhotosVideos => 'ഫോട്ടോകളും വീഡിയോകളും';

  @override
  String get labelPermCamera => 'ക്യാമറ';

  @override
  String get labelPermBiometric => 'വിരലടയാളം';

  @override
  String get labelPermNetwork => 'പ്രാദേശിക നെറ്റ്‌വർക്ക്';

  @override
  String get labelPermWifiState => 'വൈ-ഫൈ വിവരങ്ങൾ';

  @override
  String get labelPermNetworkState => 'നെറ്റ്‌വർക്ക് നില';

  @override
  String get labelPermChangeWifi => 'വൈ-ഫൈ നിർദ്ദേശങ്ങൾ';

  @override
  String get labelPermReceiverPrivate => 'ആപ്പിനുള്ളിലെ സന്ദേശങ്ങൾ';

  @override
  String get labelPermWakeLock => 'ഫോൺ ഉണർത്തി നിർത്തൽ';

  @override
  String get labelPermRecordAudio => 'ശബ്ദം റെക്കോർഡിങ്';

  @override
  String get labelPermWriteStorage => 'സംഭരണത്തിൽ എഴുതൽ';

  @override
  String get descPermPhotosVideos =>
      'ഈ ഫോണിലെ ഫോട്ടോകളും വീഡിയോകളും കാണിക്കാൻ. ആൻഡ്രോയിഡ് 14 മുതൽ നിങ്ങൾ തിരഞ്ഞെടുക്കുന്നവ മാത്രം അനുവദിക്കാം.';

  @override
  String get descPermCamera =>
      'ട്രാൻസ്ഫർ സ്ക്രീനിൽ ജോടിയാക്കൽ QR കോഡ് സ്കാൻ ചെയ്യാൻ മാത്രം. ആപ്പ് ഒരിക്കലും ഫോട്ടോ എടുക്കുന്നില്ല.';

  @override
  String get descPermBiometric =>
      'വിരലടയാളം കൊണ്ട് വോൾട്ട് തുറക്കാൻ. നിങ്ങളുടെ പിൻ എപ്പോഴും പ്രവർത്തിക്കും.';

  @override
  String get descPermNetwork =>
      'നിങ്ങളുടെ സ്വന്തം വൈ-ഫൈയിലെ മറ്റൊരു ഫോണിലേക്ക് എത്താൻ ട്രാൻസ്ഫർ സ്ക്രീൻ മാത്രം ഉപയോഗിക്കുന്നു. ആപ്പ് ഒരിക്കലും ഇന്റർനെറ്റിൽ പോകുന്നില്ല.';

  @override
  String get descPermWifiState =>
      'ജോടിയാക്കൽ കോഡ് ഉണ്ടാക്കാൻ ഈ ഫോണിന്റെ സ്വന്തം വൈ-ഫൈ വിലാസം വായിക്കുന്നു.';

  @override
  String get descPermNetworkState =>
      'പ്രാദേശിക ട്രാൻസ്ഫറിനുള്ള കൂട്ടത്തിന്റെ ഭാഗം. ഓൺലൈനിൽ പോകാൻ ആപ്പ് ഇത് ഉപയോഗിക്കുന്നില്ല.';

  @override
  String get descPermChangeWifi =>
      'നിങ്ങൾ സ്കാൻ ചെയ്ത വൈ-ഫൈ കോഡ് ആൻഡ്രോയിഡിന് നിർദ്ദേശിക്കുന്നു. നെറ്റ്‌വർക്ക് നിങ്ങൾ തന്നെ തിരഞ്ഞെടുക്കണം.';

  @override
  String get descPermReceiverPrivate =>
      'ഒരു ആൻഡ്രോയിഡ് ലൈബ്രറി ചേർക്കുന്നത്. ആപ്പിന്റെ ആന്തരിക സന്ദേശങ്ങൾ സ്വകാര്യമായി സൂക്ഷിക്കുന്നു, മറ്റൊന്നിലേക്കും പ്രവേശനം നൽകുന്നില്ല.';

  @override
  String get descPermWakeLock =>
      'സ്ട്രീമിങ്ങിനായി വീഡിയോ പ്ലെയർ ഇത് ആവശ്യപ്പെടുന്നു. ആപ്പ് ഈ ഫോണിലെ ഫയലുകൾ മാത്രം പ്ലേ ചെയ്യുന്നു.';

  @override
  String get descPermRecordAudio =>
      'ക്യാമറ ലൈബ്രറി ഇത് ആവശ്യപ്പെടുന്നു. QR സ്കാനർ ഒരിക്കലും ശബ്ദം റെക്കോർഡ് ചെയ്യുന്നില്ല.';

  @override
  String get descPermWriteStorage =>
      'Android 9-ഉം അതിനു മുമ്പുള്ളവയിലും മാത്രം. ഫോട്ടോകൾ ശാശ്വതമായോ സുരക്ഷിതമായോ ഇല്ലാതാക്കാൻ അനുവദിക്കുന്നു. ഫോട്ടോ അനുമതിയോടൊപ്പം ചോദിക്കും.';

  @override
  String get labelPermAllowed => 'അനുവദിച്ചു';

  @override
  String get labelPermSelectedOnly => 'തിരഞ്ഞെടുത്തവ മാത്രം';

  @override
  String get labelPermNotAllowed => 'അനുവദിച്ചിട്ടില്ല';

  @override
  String labelPermAndroidFrom(String version) {
    return 'ആൻഡ്രോയിഡ് $version മുതൽ';
  }

  @override
  String labelPermAndroidUpTo(String version) {
    return 'ആൻഡ്രോയിഡ് $version വരെ';
  }

  @override
  String get titleVaultFolderMissing => 'ഫോൾഡർ കണ്ടില്ല';

  @override
  String bodyVaultFolderMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count ഇനങ്ങളുടെ പഴയ ഫോൾഡർ ഇപ്പോൾ ഇല്ല. അവയ്ക്കായി ഒരു ഫോൾഡർ തിരഞ്ഞെടുക്കുക, അല്ലെങ്കിൽ ഒഴിവാക്കുക; അവ വോൾട്ടിൽ തന്നെ ഇരിക്കും.',
      one:
          '1 ഇനത്തിന്റെ പഴയ ഫോൾഡർ ഇപ്പോൾ ഇല്ല. അതിനായി ഒരു ഫോൾഡർ തിരഞ്ഞെടുക്കുക, അല്ലെങ്കിൽ ഒഴിവാക്കുക; അത് വോൾട്ടിൽ തന്നെ ഇരിക്കും.',
    );
    return '$_temp0';
  }

  @override
  String get actionVaultChooseFolder => 'ഫോൾഡർ തിരഞ്ഞെടുക്കുക';

  @override
  String get actionVaultSkip => 'ഒഴിവാക്കുക';

  @override
  String bodyVaultRestoreSkipped(int done, int skipped) {
    return '$done തിരികെ കൊണ്ടുവന്നു, $skipped വോൾട്ടിൽ തന്നെ';
  }

  @override
  String bodyVaultRestoreSkippedFailed(int done, int skipped, int failed) {
    return '$done തിരികെ കൊണ്ടുവന്നു, $skipped വോൾട്ടിൽ തന്നെ, $failed പരാജയപ്പെട്ടു';
  }

  @override
  String get titleBatchActionDelete => 'ഇല്ലാതാക്കുക';

  @override
  String titleDeleteChoice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഇനങ്ങൾ ഇല്ലാതാക്കണോ?',
      one: '1 ഇനം ഇല്ലാതാക്കണോ?',
    );
    return '$_temp0';
  }

  @override
  String bodyDeleteChoiceTrash(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ചവറ്റുകുട്ടയിൽ നിന്ന് തിരികെ എടുക്കാം.',
      one: 'ചവറ്റുകുട്ടയിൽ നിന്ന് തിരികെ എടുക്കാം.',
    );
    return '$_temp0';
  }

  @override
  String get bodyDeleteChoicePermanent =>
      'ഫോണിൽ നിന്ന് നീക്കം ചെയ്യും. ഇത് പഴയപടിയാക്കാൻ കഴിയില്ല.';

  @override
  String get bodyDeleteChoicePermanentSecure =>
      'ആദ്യം മേലെഴുതി, പിന്നെ ഫോണിൽ നിന്ന് നീക്കം ചെയ്യും. ഇത് പഴയപടിയാക്കാൻ കഴിയില്ല.';

  @override
  String bodyDeletePermanentlyConfirmCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count ഇനങ്ങൾ ഫോണിൽ നിന്ന് ശാശ്വതമായി ഇല്ലാതാക്കും. ഇത് പഴയപടിയാക്കാൻ കഴിയില്ല.',
      one:
          '1 ഇനം ഫോണിൽ നിന്ന് ശാശ്വതമായി ഇല്ലാതാക്കും. ഇത് പഴയപടിയാക്കാൻ കഴിയില്ല.',
    );
    return '$_temp0';
  }

  @override
  String get bodyDeleteNothingDeleted => 'ഒന്നും ഇല്ലാതാക്കിയില്ല.';

  @override
  String bodyDeletedPermanentlyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഇനങ്ങൾ ശാശ്വതമായി ഇല്ലാതാക്കി.',
      one: '1 ഇനം ശാശ്വതമായി ഇല്ലാതാക്കി.',
    );
    return '$_temp0';
  }

  @override
  String bodySecureDeletedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഇനങ്ങൾ സുരക്ഷിതമായി ഇല്ലാതാക്കി.',
      one: '1 ഇനം സുരക്ഷിതമായി ഇല്ലാതാക്കി.',
    );
    return '$_temp0';
  }

  @override
  String bodySecureDeleteNotOverwritten(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'അതിൽ $count എണ്ണം ആദ്യം മേലെഴുതാൻ കഴിഞ്ഞില്ല.',
      one: 'അതിൽ 1 എണ്ണം ആദ്യം മേലെഴുതാൻ കഴിഞ്ഞില്ല.',
    );
    return '$_temp0';
  }

  @override
  String bodyDeleteFailedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഇനങ്ങൾ ഇല്ലാതാക്കാൻ കഴിഞ്ഞില്ല.',
      one: '1 ഇനം ഇല്ലാതാക്കാൻ കഴിഞ്ഞില്ല.',
    );
    return '$_temp0';
  }

  @override
  String get titleSecureDelete => 'സുരക്ഷിതമായി ഇല്ലാതാക്കൽ';

  @override
  String get descSecureDeleteSubtitle =>
      'ഇല്ലാതാക്കുന്നതിനു മുമ്പ് ഓരോ ഫയലും മേലെഴുതും, അതിനാൽ വീണ്ടെടുക്കൽ ടൂളുകൾക്ക് അത് തിരികെ കൊണ്ടുവരാൻ കഴിയില്ല. ശാശ്വതമായി ഇല്ലാതാക്കുമ്പോഴും ചവറ്റുകുട്ടയിൽ നിന്ന് ഇല്ലാതാക്കുമ്പോഴും ഇത് ബാധകം. ആദ്യം Android അനുമതി ചോദിക്കും. ഫ്ലാഷ് സ്റ്റോറേജിൽ ഇത് വീണ്ടെടുക്കൽ ടൂളുകളെ തടയും, ലാബിനെ അല്ല.';

  @override
  String get bodySecureDeleteVaultNote =>
      'ഈ സ്വിച്ച് എന്തായാലും, വോൾട്ടിൽ നിന്ന് ഇല്ലാതാക്കുന്നത് എപ്പോഴും സുരക്ഷിതമാണ്.';

  @override
  String bodyBatchTrashSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഇനങ്ങൾ ചവറ്റുകുട്ടയിലേക്ക് മാറ്റി',
      one: '1 ഇനം ചവറ്റുകുട്ടയിലേക്ക് മാറ്റി',
    );
    return '$_temp0';
  }
}
