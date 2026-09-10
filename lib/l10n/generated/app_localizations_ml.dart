// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malayalam (`ml`).
class AppLocalizationsMl extends AppLocalizations {
  AppLocalizationsMl([String locale = 'ml']) : super(locale);

  @override
  String get appTitle => 'ശ്രീരാജ് പി ഗാലറി';

  @override
  String get devBanner => 'ഡെവ് ബിൽഡ്';

  @override
  String get settings => 'ക്രമീകരണങ്ങൾ';

  @override
  String get about => 'വിവരണം';

  @override
  String get theme => 'തീം';

  @override
  String get themeSystem => 'സിസ്റ്റം ഡിഫോൾട്ട്';

  @override
  String get themeLight => 'ലൈറ്റ്';

  @override
  String get themeDark => 'ഡാർക്ക്';

  @override
  String get themeAmoled => 'അമോലെഡ് ബ്ലാക്ക്';

  @override
  String get currentFlavor => 'നിലവിലെ ഫ്ലേവർ';

  @override
  String get version => 'പതിപ്പ്';

  @override
  String get offlineStatus => '100% ഓഫ്‌ലൈൻ (ഇന്റർനെറ്റ് ആവശ്യമില്ല)';

  @override
  String get permissionRequired => 'മീഡിയ അനുമതി ആവശ്യമാണ്';

  @override
  String get permissionRequiredBody =>
      'ഗാലറിക്ക് നിങ്ങളുടെ ഫോട്ടോകളും വീഡിയോകളും കാണിക്കാൻ അനുമതി നൽകുക. ഒന്നും ഉപകരണത്തിന് പുറത്തേക്ക് പോകില്ല.';

  @override
  String get grantPermission => 'അനുമതി നൽകുക';

  @override
  String get openSettings => 'ക്രമീകരണങ്ങൾ തുറക്കുക';

  @override
  String get permissionPartial =>
      'തിരഞ്ഞെടുത്ത മീഡിയ മാത്രമേ കാണാനാകൂ. എല്ലാം കാണാൻ പൂർണ അനുമതി നൽകുക.';

  @override
  String get scanMedia => 'ഉപകരണത്തിലെ മീഡിയ സ്കാൻ ചെയ്യുക';

  @override
  String get scanningMedia => 'മീഡിയ സ്കാൻ ചെയ്യുന്നു...';

  @override
  String scanProgress(int scanned, int total) {
    return '$total ൽ $scanned സ്കാൻ ചെയ്തു';
  }

  @override
  String scanComplete(int count) {
    return 'സ്കാൻ പൂർത്തിയായി: $count ഇനങ്ങൾ ചേർത്തു';
  }

  @override
  String get scanFailed => 'മീഡിയ സ്കാൻ പരാജയപ്പെട്ടു';

  @override
  String indexedItems(int count) {
    return 'ചേർത്ത ഇനങ്ങൾ: $count';
  }

  @override
  String get noMediaFound => 'ഫോട്ടോകളോ വീഡിയോകളോ കണ്ടെത്തിയില്ല';

  @override
  String get mediaUnavailable => 'പ്രിവ്യൂ ലഭ്യമല്ല';

  @override
  String get timelineToday => 'ഇന്ന്';

  @override
  String get timelineYesterday => 'ഇന്നലെ';

  @override
  String get timelineTitle => 'ടൈംലൈൻ';

  @override
  String get noMediaInTimeline => 'നിങ്ങളുടെ ഗാലറി ശൂന്യമാണ്';

  @override
  String get pullToScan =>
      'പുതിയ ഫോട്ടോകളും വീഡിയോകളും തിരയാൻ താഴേക്ക് വലിക്കുക.';

  @override
  String get flashbackTitle => 'ഈ ദിവസം';

  @override
  String get flashbackOneYearAgo => '1 വർഷം മുമ്പ്';

  @override
  String flashbackYearsAgo(int years) {
    return '$years വർഷം മുമ്പ്';
  }

  @override
  String gridColumns(int count) {
    return 'ഒരു വരിയിൽ $count';
  }

  @override
  String get badgeGif => 'GIF';

  @override
  String get badgeRaw => 'RAW';

  @override
  String get badgeHd => 'HD';

  @override
  String badgeVideoDuration(String duration) {
    return 'വീഡിയോ, $duration';
  }

  @override
  String mediaTileLabel(String name, String date) {
    return '$name, $date';
  }

  @override
  String get scrollToDate => 'തീയതിയിലേക്ക് പോകുക';

  @override
  String get viewerClose => 'അടയ്ക്കുക';

  @override
  String get viewerRotateLeft => 'ഇടത്തേക്ക് തിരിക്കുക';

  @override
  String get viewerRotateRight => 'വലത്തേക്ക് തിരിക്കുക';

  @override
  String get viewerAddFavorite => 'പ്രിയപ്പെട്ടതിലേക്ക് ചേർക്കുക';

  @override
  String get viewerRemoveFavorite => 'പ്രിയപ്പെട്ടതിൽ നിന്ന് നീക്കുക';

  @override
  String get play => 'പ്ലേ ചെയ്യുക';

  @override
  String get pause => 'നിർത്തുക';

  @override
  String get frameForward => 'അടുത്ത ഫ്രെയിം';

  @override
  String get frameBackward => 'മുൻ ഫ്രെയിം';

  @override
  String get skipForward => '10 സെക്കൻഡ് മുന്നോട്ട്';

  @override
  String get skipBackward => '10 സെക്കൻഡ് പിന്നോട്ട്';

  @override
  String get loopPlayback => 'ആവർത്തിക്കുക';

  @override
  String get playbackSpeed => 'പ്ലേബാക്ക് വേഗത';

  @override
  String get videoCannotPlay => 'ഈ വീഡിയോ പ്ലേ ചെയ്യാൻ കഴിയില്ല.';

  @override
  String get videoFormatUnsupported =>
      'ഈ ഉപകരണത്തിന് ഈ വീഡിയോ ഫോർമാറ്റ് പ്ലേ ചെയ്യാൻ കഴിയില്ല.';

  @override
  String get detailsTitle => 'വിശദാംശങ്ങൾ';

  @override
  String get detailsFileName => 'ഫയലിന്റെ പേര്';

  @override
  String get detailsFormat => 'ഫോർമാറ്റ്';

  @override
  String get detailsSize => 'വലുപ്പം';

  @override
  String get detailsDimensions => 'അളവുകൾ';

  @override
  String get detailsDuration => 'ദൈർഘ്യം';

  @override
  String get detailsDateTaken => 'എടുത്ത തീയതി';

  @override
  String get detailsDateModified => 'അവസാനം മാറ്റിയത്';

  @override
  String get detailsFolder => 'ഫോൾഡർ';

  @override
  String get detailsCameraSection => 'ക്യാമറയും മെറ്റാഡാറ്റയും';

  @override
  String get detailsNoMetadata => 'ഈ ഫയലിൽ ക്യാമറ മെറ്റാഡാറ്റ കണ്ടെത്തിയില്ല.';

  @override
  String get detailsCamera => 'ക്യാമറ';

  @override
  String get detailsLens => 'ലെൻസ്';

  @override
  String get detailsAperture => 'അപ്പേർച്ചർ';

  @override
  String get detailsShutter => 'ഷട്ടർ';

  @override
  String get detailsIso => 'ഐഎസ്ഒ';

  @override
  String get detailsFocalLength => 'ഫോക്കൽ ദൈർഘ്യം';

  @override
  String get detailsFlash => 'ഫ്ലാഷ്';

  @override
  String get detailsWhiteBalance => 'വൈറ്റ് ബാലൻസ്';

  @override
  String get detailsMeteringMode => 'മീറ്ററിംഗ് മോഡ്';

  @override
  String get detailsColorSpace => 'കളർ സ്പേസ്';

  @override
  String get detailsSoftware => 'സോഫ്റ്റ്‌വെയർ';

  @override
  String get detailsLocation => 'സ്ഥലം';

  @override
  String get detailsAltitude => 'ഉയരം';

  @override
  String get editorTitle => 'മാറ്റം വരുത്തുക';

  @override
  String get editorOpen => 'മാറ്റം വരുത്തുക';

  @override
  String get editorSave => 'പകർപ്പ് സേവ് ചെയ്യുക';

  @override
  String get editorSaving => 'പകർപ്പ് സേവ് ചെയ്യുന്നു...';

  @override
  String editorSaved(String fileName) {
    return 'പകർപ്പ് സേവ് ചെയ്തു: $fileName';
  }

  @override
  String get editorSaveFailed => 'പകർപ്പ് സേവ് ചെയ്യാൻ കഴിഞ്ഞില്ല';

  @override
  String get editorOriginalKept => 'നിങ്ങളുടെ യഥാർഥ ചിത്രത്തിന് മാറ്റമില്ല';

  @override
  String get editorCannotOpen => 'ഈ ചിത്രത്തിൽ മാറ്റം വരുത്താൻ കഴിയില്ല';

  @override
  String get editorTooLarge =>
      'ഈ ചിത്രം ഈ ഉപകരണത്തിൽ എഡിറ്റ് ചെയ്യാൻ വളരെ വലുതാണ്';

  @override
  String get editorLoading => 'ചിത്രം തയ്യാറാക്കുന്നു...';

  @override
  String get editorPreviewFailed => 'പ്രിവ്യൂ വരയ്ക്കാൻ കഴിഞ്ഞില്ല';

  @override
  String get editorUndo => 'പഴയപടിയാക്കുക';

  @override
  String get editorRedo => 'വീണ്ടും ചെയ്യുക';

  @override
  String get editorResetAll => 'എല്ലാം പഴയപടിയാക്കുക';

  @override
  String get editorDiscardTitle => 'മാറ്റങ്ങൾ ഉപേക്ഷിക്കണോ?';

  @override
  String get editorDiscardMessage =>
      'നിങ്ങളുടെ മാറ്റങ്ങൾ സേവ് ചെയ്തിട്ടില്ല. ഇപ്പോൾ പോയാൽ അവ നഷ്ടമാകും.';

  @override
  String get editorDiscard => 'ഉപേക്ഷിക്കുക';

  @override
  String get editorKeepEditing => 'തുടർന്ന് എഡിറ്റ് ചെയ്യുക';

  @override
  String get editorToolCrop => 'ക്രോപ്പ്';

  @override
  String get editorToolTune => 'വെളിച്ചം';

  @override
  String get editorToolMasks => 'മാസ്കുകൾ';

  @override
  String get editorToolFilters => 'ഫിൽട്ടറുകൾ';

  @override
  String get editorToolMarkup => 'വരയ്ക്കുക';

  @override
  String get editorToolRedact => 'മറയ്ക്കുക';

  @override
  String get editorToolWatermark => 'വാട്ടർമാർക്ക്';

  @override
  String get cropAspectFree => 'സ്വതന്ത്രം';

  @override
  String get cropAspectOriginal => 'യഥാർഥം';

  @override
  String get cropAspectSquare => 'സമചതുരം';

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
  String get cropRotateLeft => 'ഇടത്തോട്ട് തിരിക്കുക';

  @override
  String get cropRotateRight => 'വലത്തോട്ട് തിരിക്കുക';

  @override
  String get cropFlipHorizontal => 'വശങ്ങൾ മാറ്റുക';

  @override
  String get cropFlipVertical => 'മുകളും താഴെയും മാറ്റുക';

  @override
  String get cropStraighten => 'നേരെയാക്കുക';

  @override
  String get cropPerspectiveVertical => 'കുത്തനെയുള്ള ചരിവ്';

  @override
  String get cropPerspectiveHorizontal => 'വിലങ്ങനെയുള്ള ചരിവ്';

  @override
  String get cropReset => 'ക്രോപ്പ് പഴയപടിയാക്കുക';

  @override
  String get toneExposure => 'വെളിച്ചം';

  @override
  String get toneContrast => 'വൈരുധ്യം';

  @override
  String get toneHighlights => 'തെളിഞ്ഞ ഭാഗങ്ങൾ';

  @override
  String get toneShadows => 'ഇരുണ്ട ഭാഗങ്ങൾ';

  @override
  String get toneTemperature => 'ചൂട്';

  @override
  String get toneTint => 'നിറച്ചായ്‌വ്';

  @override
  String get toneVibrance => 'നിറത്തിളക്കം';

  @override
  String get toneSaturation => 'നിറസാന്ദ്രത';

  @override
  String get toneReset => 'വെളിച്ചം പഴയപടിയാക്കുക';

  @override
  String get toneCurves => 'കർവുകൾ';

  @override
  String get curveChannelRgb => 'എല്ലാം';

  @override
  String get curveChannelRed => 'ചുവപ്പ്';

  @override
  String get curveChannelGreen => 'പച്ച';

  @override
  String get curveChannelBlue => 'നീല';

  @override
  String get curveReset => 'കർവ് പഴയപടിയാക്കുക';

  @override
  String get curveHint => 'കർവ് മാറ്റാൻ ഒരു പോയിന്റ് വലിക്കുക';

  @override
  String get curveAddHint =>
      'പോയിന്റ് ചേർക്കാൻ തൊടുക, മാറ്റാൻ അമർത്തിപ്പിടിക്കുക';

  @override
  String get maskShapeLinear => 'ലീനിയർ';

  @override
  String get maskShapeRadial => 'റേഡിയൽ';

  @override
  String get maskFeather => 'ഫെദർ';

  @override
  String get maskInvert => 'വിപരീതം';

  @override
  String get maskBlur => 'മങ്ങൽ';

  @override
  String get maskAddLinear => 'ലീനിയർ ഗ്രേഡിയന്റ് ചേർക്കുക';

  @override
  String get maskAddRadial => 'റേഡിയൽ മാസ്ക് ചേർക്കുക';

  @override
  String get maskRemove => 'മാസ്ക് നീക്കംചെയ്യുക';

  @override
  String get maskEmpty => 'മാസ്ക് ചേർക്കാൻ + തൊടുക';

  @override
  String get hslTitle => 'എച്ച്.എസ്.എൽ കളർ ട്യൂണർ';

  @override
  String get hslHue => 'നിറം';

  @override
  String get hslSaturation => 'സാന്ദ്രത';

  @override
  String get hslLuminance => 'തെളിച്ചം';

  @override
  String get hslReset => 'എച്ച്.എസ്.എൽ പഴയപടിയാക്കുക';

  @override
  String get hslRangeRed => 'ചുവപ്പ്';

  @override
  String get hslRangeOrange => 'ഓറഞ്ച്';

  @override
  String get hslRangeYellow => 'മഞ്ഞ';

  @override
  String get hslRangeGreen => 'പച്ച';

  @override
  String get hslRangeCyan => 'സയൻ';

  @override
  String get hslRangeBlue => 'നീല';

  @override
  String get hslRangePurple => 'പർപ്പിൾ';

  @override
  String get hslRangeMagenta => 'മജന്ത';

  @override
  String get filterNone => 'യഥാർഥം';

  @override
  String get filterMono => 'കറുപ്പും വെളുപ്പും';

  @override
  String get filterSepia => 'സെപിയ';

  @override
  String get filterVintage => 'പഴമ';

  @override
  String get filterVivid => 'തിളക്കം';

  @override
  String get filterCool => 'തണുപ്പ്';

  @override
  String get filterWarm => 'ചൂട്';

  @override
  String get filterFade => 'മങ്ങൽ';

  @override
  String get filterIntensity => 'കരുത്ത്';

  @override
  String get markupFreehand => 'വരയ്ക്കുക';

  @override
  String get markupRectangle => 'ദീർഘചതുരം';

  @override
  String get markupEllipse => 'വൃത്തം';

  @override
  String get markupLine => 'വര';

  @override
  String get markupArrow => 'അമ്പ്';

  @override
  String get markupText => 'എഴുത്ത്';

  @override
  String get markupColor => 'നിറം';

  @override
  String get markupThickness => 'കനം';

  @override
  String get markupFilled => 'ഉള്ളിൽ നിറയ്ക്കുക';

  @override
  String get markupUndoLayer => 'അവസാനത്തേത് നീക്കുക';

  @override
  String get markupTextTitle => 'എഴുത്ത് ചേർക്കുക';

  @override
  String get markupTextHint => 'നിങ്ങളുടെ എഴുത്ത് ടൈപ്പ് ചെയ്യുക';

  @override
  String get markupTextAdd => 'ചേർക്കുക';

  @override
  String get markupHint => 'വരയ്ക്കാൻ ചിത്രത്തിൽ വലിക്കുക';

  @override
  String get redactBlur => 'മങ്ങിക്കുക';

  @override
  String get redactPixelate => 'കട്ടകളാക്കുക';

  @override
  String get redactBlackout => 'കറുപ്പിക്കുക';

  @override
  String get redactStrength => 'കരുത്ത്';

  @override
  String get redactHint => 'മറയ്ക്കേണ്ട ഭാഗത്തിന് മുകളിൽ വലിക്കുക';

  @override
  String get redactRemoveLast => 'അവസാനത്തേത് നീക്കുക';

  @override
  String redactCount(int count) {
    return '$count ഭാഗങ്ങൾ മറച്ചു';
  }

  @override
  String get watermarkNone => 'ഒന്നുമില്ല';

  @override
  String get watermarkText => 'എഴുത്ത്';

  @override
  String get watermarkTimestamp => 'തീയതിയും സമയവും';

  @override
  String get watermarkLogo => 'ലോഗോ';

  @override
  String get watermarkTextHint => 'വാട്ടർമാർക്ക് എഴുത്ത്';

  @override
  String get watermarkPosition => 'സ്ഥാനം';

  @override
  String get watermarkOpacity => 'സുതാര്യത';

  @override
  String get watermarkSize => 'വലുപ്പം';

  @override
  String get watermarkMargin => 'അരികിൽ നിന്നുള്ള അകലം';

  @override
  String get watermarkPickLogo => 'ഒരു ലോഗോ ഫയൽ തിരഞ്ഞെടുക്കുക';

  @override
  String get watermarkNoLogo => 'ലോഗോ തിരഞ്ഞെടുത്തിട്ടില്ല';

  @override
  String get watermarkClearLogo => 'ലോഗോ നീക്കുക';

  @override
  String get positionTopLeft => 'മുകളിൽ ഇടത്';

  @override
  String get positionTopCenter => 'മുകളിൽ നടുവിൽ';

  @override
  String get positionTopRight => 'മുകളിൽ വലത്';

  @override
  String get positionCenterLeft => 'നടുവിൽ ഇടത്';

  @override
  String get positionCenter => 'നടുവിൽ';

  @override
  String get positionCenterRight => 'നടുവിൽ വലത്';

  @override
  String get positionBottomLeft => 'താഴെ ഇടത്';

  @override
  String get positionBottomCenter => 'താഴെ നടുവിൽ';

  @override
  String get positionBottomRight => 'താഴെ വലത്';

  @override
  String get convertOpen => 'മാറ്റുക';

  @override
  String get convertTitle => 'മാറ്റവും വലുപ്പവും';

  @override
  String get convertCannotOpen => 'ഈ ഫയൽ മാറ്റാൻ കഴിയില്ല';

  @override
  String get convertTooLarge => 'ഈ ഫയൽ മാറ്റാൻ പറ്റാത്തത്ര വലുതാണ്';

  @override
  String get convertUnreadable => 'ഈ ചിത്രം വായിക്കാൻ കഴിഞ്ഞില്ല';

  @override
  String get convertFormatLabel => 'ഫോർമാറ്റ്';

  @override
  String get convertQualityLabel => 'ഗുണനിലവാരം';

  @override
  String get convertResizeLabel => 'വലുപ്പം';

  @override
  String get convertResizeNone => 'യഥാർത്ഥം';

  @override
  String get convertResizeLongestSide => 'നീളമുള്ള വശം';

  @override
  String get convertResizePercent => 'ശതമാനം';

  @override
  String get convertResizeExact => 'വീതിയും ഉയരവും';

  @override
  String get convertKeepAspect => 'രൂപം നിലനിർത്തുക';

  @override
  String get convertWidth => 'വീതി';

  @override
  String get convertHeight => 'ഉയരം';

  @override
  String get convertLongestSideLabel => 'നീളമുള്ള വശം പിക്സലിൽ';

  @override
  String get convertPercentLabel => 'യഥാർത്ഥത്തിന്റെ ശതമാനം';

  @override
  String get convertStripMetadata => 'ക്യാമറ വിവരങ്ങൾ നീക്കുക';

  @override
  String get convertStripMetadataHint =>
      'സ്ഥലവും ക്യാമറ ക്രമീകരണവും പകർപ്പിൽ ഉൾപ്പെടുത്തില്ല';

  @override
  String get convertOriginalSize => 'യഥാർത്ഥം';

  @override
  String get convertNewSize => 'പുതിയ പകർപ്പ്';

  @override
  String get convertEstimating => 'വലുപ്പം കണക്കാക്കുന്നു';

  @override
  String get convertNoEstimate => 'ഈ ഫയലിന്റെ വലുപ്പം കണക്കാക്കാൻ കഴിയില്ല';

  @override
  String get convertLargerWarning => 'പകർപ്പ് യഥാർത്ഥത്തേക്കാൾ വലുതാണ്';

  @override
  String get convertSave => 'ഒരു പകർപ്പ് സൂക്ഷിക്കുക';

  @override
  String get convertSaving => 'സൂക്ഷിക്കുന്നു';

  @override
  String get convertFailed => 'പകർപ്പ് സൂക്ഷിക്കാൻ കഴിഞ്ഞില്ല';

  @override
  String get convertOriginalKept => 'നിങ്ങളുടെ യഥാർത്ഥ ഫയൽ മാറുന്നില്ല';

  @override
  String get pdfOpen => 'PDF ആയി കയറ്റുമതി ചെയ്യുക';

  @override
  String get pdfExportTitle => 'PDF ആയി കയറ്റുമതി ചെയ്യുക';

  @override
  String get pdfChoosePhotos => 'ചിത്രങ്ങൾ തിരഞ്ഞെടുക്കുക';

  @override
  String get pdfNoSelection => 'കുറഞ്ഞത് ഒരു ചിത്രമെങ്കിലും തിരഞ്ഞെടുക്കുക';

  @override
  String get pdfNoPhotos => 'തിരഞ്ഞെടുക്കാൻ ചിത്രങ്ങളൊന്നുമില്ല';

  @override
  String get pdfPageSizeLabel => 'പേജ് വലുപ്പം';

  @override
  String get pdfPageA4 => 'A4';

  @override
  String get pdfPageLetter => 'ലെറ്റർ';

  @override
  String get pdfPageFitImage => 'ചിത്രത്തിന് അനുസരിച്ച്';

  @override
  String get pdfOrientationLabel => 'ദിശ';

  @override
  String get pdfOrientationPortrait => 'നെടുകെ';

  @override
  String get pdfOrientationLandscape => 'കുറുകെ';

  @override
  String get pdfOrientationAuto => 'ചിത്രം അനുസരിച്ച്';

  @override
  String get pdfFitLabel => 'സ്ഥാനം';

  @override
  String get pdfFitContain => 'മുഴുവൻ ചിത്രവും';

  @override
  String get pdfFitFill => 'പേജ് നിറയ്ക്കുക';

  @override
  String get pdfMarginLabel => 'അതിര്';

  @override
  String get pdfMarginNone => 'ഒന്നുമില്ല';

  @override
  String get pdfMarginSmall => 'ചെറുത്';

  @override
  String get pdfMarginMedium => 'ഇടത്തരം';

  @override
  String get pdfMarginLarge => 'വലുത്';

  @override
  String get pdfQualityLabel => 'ചിത്ര ഗുണനിലവാരം';

  @override
  String get pdfExportAction => 'PDF ഉണ്ടാക്കുക';

  @override
  String get pdfExporting => 'PDF ഉണ്ടാക്കുന്നു';

  @override
  String get pdfFailed => 'PDF ഉണ്ടാക്കാൻ കഴിഞ്ഞില്ല';

  @override
  String get videoToolsOpen => 'വീഡിയോ ഉപകരണങ്ങൾ';

  @override
  String get videoToolsTitle => 'വീഡിയോ ഉപകരണങ്ങൾ';

  @override
  String get videoToolsUnavailable => 'ഈ ക്ലിപ്പ് വായിക്കാൻ കഴിഞ്ഞില്ല';

  @override
  String get videoTabFrame => 'ഫ്രെയിം';

  @override
  String get videoTabGif => 'GIF';

  @override
  String get videoTabTrim => 'മുറിക്കുക';

  @override
  String get framePositionLabel => 'ക്ലിപ്പിലെ സ്ഥാനം';

  @override
  String get frameFormatLabel => 'ഇങ്ങനെ സൂക്ഷിക്കുക';

  @override
  String get frameSaveAction => 'ഈ ഫ്രെയിം സൂക്ഷിക്കുക';

  @override
  String get frameUnavailable => 'ഇവിടെ ഫ്രെയിം വായിക്കാൻ കഴിഞ്ഞില്ല';

  @override
  String get gifFrameRateLabel => 'സെക്കൻഡിൽ ഫ്രെയിമുകൾ';

  @override
  String get gifSizeLabel => 'വലുപ്പം';

  @override
  String get gifLoopLabel => 'ആവർത്തിച്ച് കാണിക്കുക';

  @override
  String get gifCapped => 'ഫയൽ ചെറുതാക്കാൻ GIF കുറയ്ക്കുന്നു';

  @override
  String get gifExportAction => 'GIF ഉണ്ടാക്കുക';

  @override
  String get gifExporting => 'GIF ഉണ്ടാക്കുന്നു';

  @override
  String get trimStartLabel => 'തുടക്കം';

  @override
  String get trimEndLabel => 'അവസാനം';

  @override
  String get trimLengthLabel => 'ദൈർഘ്യം';

  @override
  String get trimAction => 'മുറിച്ച ക്ലിപ്പ് സൂക്ഷിക്കുക';

  @override
  String get trimLosslessNote =>
      'വീണ്ടും എൻകോഡ് ചെയ്യുന്നില്ല, അതിനാൽ ഗുണനിലവാരം നഷ്ടപ്പെടുന്നില്ല.';

  @override
  String get trimTooShort => 'തിരഞ്ഞെടുത്ത ഭാഗം വളരെ ചെറുതാണ്';

  @override
  String get videoWorking => 'പ്രവർത്തിക്കുന്നു';

  @override
  String get videoJobFailed => 'ഇത് പൂർത്തിയാക്കാൻ കഴിഞ്ഞില്ല';

  @override
  String convertPixelSize(int width, int height) {
    return '$width x $height പിക്സൽ';
  }

  @override
  String convertSmallerBy(int percent) {
    return '$percent ശതമാനം ചെറുത്';
  }

  @override
  String convertSavedAs(String name) {
    return '$name ആയി സൂക്ഷിച്ചു';
  }

  @override
  String pdfSelectedCount(int count) {
    return '$count തിരഞ്ഞെടുത്തു';
  }

  @override
  String pdfMaxPagesReached(int count) {
    return 'ഒരു PDF-ൽ $count ചിത്രങ്ങൾ മാത്രമേ ഉൾകൊള്ളൂ';
  }

  @override
  String pdfExportedAs(String name, int pages) {
    return '$pages പേജുകളുള്ള $name സൂക്ഷിച്ചു';
  }

  @override
  String pdfSkippedCount(int count) {
    return '$count ചിത്രങ്ങൾ വായിക്കാൻ കഴിയാതതിനാൽ ഒഴിവാക്കി';
  }

  @override
  String gifFrameCount(int count) {
    return '$count ഫ്രെയിമുകൾ';
  }

  @override
  String videoJobSavedAs(String name) {
    return '$name ആയി സൂക്ഷിച്ചു';
  }

  @override
  String get searchTitle => 'തിരയുക';

  @override
  String get searchOpen => 'തിരയുക';

  @override
  String get searchHint => 'പേരുകൾ, ടാഗുകൾ, കുറിപ്പുകൾ, സ്ഥലങ്ങൾ തിരയുക';

  @override
  String get searchClear => 'മായ്ക്കുക';

  @override
  String get searchFilters => 'അരിപ്പകൾ';

  @override
  String get searchStartTitle => 'നിങ്ങളുടെ ശേഖരം തിരയുക';

  @override
  String get searchStartBody =>
      'പേരുകൾ, ടാഗുകൾ, കുറിപ്പുകൾ, ക്യാമറ, സ്ഥലം എന്നിവയിൽ തിരയാം. കൂടുതൽ കൃത്യമാക്കാൻ ഒരു വാക്ക് tag:, type:, place:, camera:, before:, after: എന്നിവയിൽ ഒന്നുകൊണ്ട് തുടങ്ങുക.';

  @override
  String get searchNoResultsTitle => 'ഒന്നും കണ്ടെത്തിയില്ല';

  @override
  String get searchNoResultsBody =>
      'കുറച്ച് വാക്കുകൾ ഉപയോഗിക്കുക, അല്ലെങ്കിൽ അരിപ്പകൾ പരിശോധിക്കുക.';

  @override
  String get searchFailed => 'തിരയൽ നടത്താൻ കഴിഞ്ഞില്ല';

  @override
  String get searchRecentTitle => 'അടുത്തിടെ തിരഞ്ഞവ';

  @override
  String get searchRecentClear => 'എല്ലാം മായ്ക്കുക';

  @override
  String get searchRecentRemove => 'ഈ തിരയൽ മറക്കുക';

  @override
  String searchResultCount(int count) {
    return '$count ഫലങ്ങൾ';
  }

  @override
  String get searchMatchedInName => 'ഫയൽ പേരുമായി ചേർന്നു';

  @override
  String get searchMatchedInTags => 'ഒരു ടാഗുമായി ചേർന്നു';

  @override
  String get searchMatchedInNotes => 'ഒരു കുറിപ്പുമായി ചേർന്നു';

  @override
  String get searchMatchedInPlace => 'ഒരു സ്ഥലവുമായി ചേർന്നു';

  @override
  String get searchMatchedInDetails => 'ചിത്ര വിവരങ്ങളുമായി ചേർന്നു';

  @override
  String get filterTitle => 'അരിപ്പകൾ';

  @override
  String get filterMediaType => 'തരം';

  @override
  String get filterTypeImage => 'ചിത്രങ്ങൾ';

  @override
  String get filterTypeVideo => 'വീഡിയോകൾ';

  @override
  String get filterTypeGif => 'GIF-കൾ';

  @override
  String get filterTypeRaw => 'RAW';

  @override
  String get filterTypeSvg => 'SVG';

  @override
  String get filterFavoritesOnly => 'പ്രിയപ്പെട്ടവ മാത്രം';

  @override
  String get filterHasLocation => 'സ്ഥലമുള്ളവ';

  @override
  String get filterDateRange => 'തീയതി പരിധി';

  @override
  String get filterDateAny => 'ഏത് തീയതിയും';

  @override
  String get filterDateChoose => 'തീയതികൾ തിരഞ്ഞെടുക്കുക';

  @override
  String get filterDateClear => 'തീയതികൾ മായ്ക്കുക';

  @override
  String get filterTags => 'ടാഗുകൾ';

  @override
  String get filterTagModeAll => 'എല്ലാം ഉള്ളവ';

  @override
  String get filterTagModeAny => 'ഏതെങ്കിലും ഉള്ളവ';

  @override
  String get filterNoTags => 'ടാഗുകൾ ഒന്നുമില്ല';

  @override
  String get filterReset => 'പുനഃസജ്ജമാക്കുക';

  @override
  String get filterApply => 'ബാധകമാക്കുക';

  @override
  String get tagsTitle => 'ടാഗുകൾ';

  @override
  String get tagsOpen => 'ടാഗുകൾ';

  @override
  String get tagsEmptyTitle => 'ടാഗുകൾ ഒന്നുമില്ല';

  @override
  String get tagsEmptyBody =>
      'നിങ്ങളുടെ ഇഷ്ടപ്രകാരം ചിത്രങ്ങൾ കൂട്ടിയിടാൻ ഒരു ടാഗ് ഉണ്ടാക്കുക.';

  @override
  String get tagNew => 'പുതിയ ടാഗ്';

  @override
  String get tagEditTitle => 'ടാഗ് തിരുത്തുക';

  @override
  String get tagNameLabel => 'ടാഗിന്റെ പേര്';

  @override
  String get tagColorLabel => 'നിറം';

  @override
  String get tagSave => 'സൂക്ഷിക്കുക';

  @override
  String get tagCancel => 'റദ്ദാക്കുക';

  @override
  String get tagDelete => 'ഇല്ലാതാക്കുക';

  @override
  String get tagDeleteTitle => 'ഈ ടാഗ് ഇല്ലാതാക്കണോ?';

  @override
  String get tagDeleteBody =>
      'ഈ ടാഗ് ഉള്ള എല്ലാ ചിത്രങ്ങളിൽ നിന്നും അത് നീക്കും. ഒരു ചിത്രവും ഇല്ലാതാകില്ല.';

  @override
  String tagItemCount(int count) {
    return '$count ഇനങ്ങൾ';
  }

  @override
  String get tagShowMedia => 'ചിത്രങ്ങൾ കാണിക്കുക';

  @override
  String get tagErrorEmpty => 'ടാഗിന് ഒരു പേര് വേണം';

  @override
  String get tagErrorTooLong => 'ആ പേര് വളരെ നീളമുള്ളതാണ്';

  @override
  String get tagErrorDuplicate => 'ആ ടാഗ് ഇതിനകം ഉണ്ട്';

  @override
  String get tagErrorFailed => 'ടാഗ് സൂക്ഷിക്കാൻ കഴിഞ്ഞില്ല';

  @override
  String get tagSheetTitle => 'ഈ ഇനത്തിലെ ടാഗുകൾ';

  @override
  String get tagSheetNewHint => 'ഒരു പുതിയ ടാഗ് ചേർക്കുക';

  @override
  String get tagSheetAdd => 'ചേർക്കുക';

  @override
  String get tagSheetDone => 'കഴിഞ്ഞു';

  @override
  String get tagSheetOpen => 'ടാഗുകൾ';

  @override
  String get cleanerTitle => 'ഇരട്ട ഫയൽ വൃത്തിയാക്കൽ';

  @override
  String get cleanerOpen => 'ഇരട്ട ഫയൽ വൃത്തിയാക്കൽ';

  @override
  String get cleanerStart => 'ഇരട്ടകൾ കണ്ടെത്തുക';

  @override
  String get cleanerStop => 'നിർത്തുക';

  @override
  String get cleanerRescan => 'വീണ്ടും പരിശോധിക്കുക';

  @override
  String get cleanerIdleTitle => 'ഇരട്ട ചിത്രങ്ങൾ കണ്ടെത്തുക';

  @override
  String get cleanerIdleBody =>
      'ഓരോ ഫയലും ഒരു തവണ വായിച്ച് ഫലം ഓർത്തുവയ്ക്കും, അതിനാൽ അടുത്ത തവണ പരിശോധന വേഗത്തിലാകും.';

  @override
  String cleanerScanning(int processed, int total) {
    return '$total-ൽ $processed പരിശോധിച്ചു';
  }

  @override
  String get cleanerGrouping => 'പകർപ്പുകൾ കൂട്ടിയിടുന്നു';

  @override
  String get cleanerCancelled => 'പരിശോധന നിർത്തി';

  @override
  String get cleanerFailed => 'പരിശോധന പൂർത്തിയാക്കാൻ കഴിഞ്ഞില്ല';

  @override
  String get cleanerNoneTitle => 'ഇരട്ടകൾ ഒന്നും കണ്ടെത്തിയില്ല';

  @override
  String get cleanerNoneBody =>
      'നിങ്ങളുടെ ശേഖരത്തിൽ ഒന്നും മറ്റൊന്നിന്റെ പകർപ്പായി തോന്നുന്നില്ല.';

  @override
  String cleanerGroupsFound(int count) {
    return 'പകർപ്പുകളുടെ $count കൂട്ടങ്ങൾ';
  }

  @override
  String cleanerReclaimable(String size) {
    return 'ഏകദേശം $size ഒഴിവാക്കാം';
  }

  @override
  String cleanerFailures(int count) {
    return '$count ഫയലുകൾ വായിക്കാൻ കഴിയാതെ ഒഴിവാക്കി';
  }

  @override
  String get cleanerKindExact => 'ഒരേ ഫയലുകൾ';

  @override
  String get cleanerKindSimilar => 'കാഴ്ചയിൽ ഒരുപോലെ';

  @override
  String cleanerMemberCount(int count) {
    return '$count പകർപ്പുകൾ';
  }

  @override
  String get cleanerCompare => 'താരതമ്യം';

  @override
  String get compareTitle => 'പകർപ്പുകൾ താരതമ്യം ചെയ്യുക';

  @override
  String get compareGroupGone => 'ഈ കൂട്ടം ഇതിനകം കൈകാര്യം ചെയ്തു';

  @override
  String get compareKeepThis => 'ഇത് സൂക്ഷിക്കുക';

  @override
  String get compareBestBadge => 'നിർദ്ദേശിച്ചത്';

  @override
  String compareKeepAndTrash(int count) {
    return '1 സൂക്ഷിക്കുക, $count എണ്ണം ചവറ്റുകുട്ടയിലേക്ക്';
  }

  @override
  String get compareTrashNotice =>
      'ഒന്നും മായ്ക്കുന്നില്ല. മറ്റ് പകർപ്പുകൾ ചവറ്റുകുട്ടയിലേക്ക് പോകും, തിരികെ എടുക്കാം.';

  @override
  String compareConfirmTitle(int count) {
    return '$count പകർപ്പുകൾ ചവറ്റുകുട്ടയിലേക്ക് മാറ്റണോ?';
  }

  @override
  String get compareConfirmBody =>
      'നിങ്ങൾ സൂക്ഷിച്ച പകർപ്പ് മാത്രം ഗാലറിയിൽ തുടരും. ഫയലുകൾ ഉപകരണത്തിൽ തന്നെ ഇരിക്കും, തിരികെ എടുക്കാം.';

  @override
  String get compareConfirm => 'ചവറ്റുകുട്ടയിലേക്ക് മാറ്റുക';

  @override
  String get compareCancel => 'റദ്ദാക്കുക';

  @override
  String compareMoved(int count) {
    return '$count പകർപ്പുകൾ ചവറ്റുകുട്ടയിലേക്ക് മാറ്റി';
  }

  @override
  String get compareFailed => 'പകർപ്പുകൾ മാറ്റാൻ കഴിഞ്ഞില്ല';

  @override
  String get compareFieldSize => 'വലുപ്പം';

  @override
  String get compareFieldPixels => 'പിക്സലുകൾ';

  @override
  String get compareFieldDate => 'തീയതി';

  @override
  String get compareFieldCamera => 'ക്യാമറ';

  @override
  String get compareUnknown => 'അറിയില്ല';

  @override
  String get albumsTitle => 'ആൽബങ്ങൾ';

  @override
  String get albumsOpen => 'ആൽബങ്ങൾ';

  @override
  String get albumsSectionMine => 'എന്റെ ആൽബങ്ങൾ';

  @override
  String get albumsSectionSmart => 'സ്മാർട്ട് ആൽബങ്ങൾ';

  @override
  String get albumsSectionFolders => 'ഉപകരണ ഫോൾഡറുകൾ';

  @override
  String get albumsEmptyTitle => 'ഇതുവരെ ആൽബങ്ങളില്ല';

  @override
  String get albumsEmptyBody =>
      'ഫോട്ടോകളും വീഡിയോകളും നിങ്ങളുടെ രീതിയിൽ ഒരുമിച്ചു ചേർക്കാൻ ഒരു ആൽബം ഉണ്ടാക്കുക. ഫയലുകൾ ഇപ്പോഴുള്ള സ്ഥലത്തുതന്നെ നിൽക്കും.';

  @override
  String get albumsFoldersEmpty => 'ഫോൾഡറുകളൊന്നും കണ്ടെത്തിയില്ല';

  @override
  String get albumsLoadFailed => 'ആൽബങ്ങൾ എടുക്കാൻ കഴിഞ്ഞില്ല';

  @override
  String albumItemCount(int count) {
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
  String get smartAlbumFavorites => 'പ്രിയപ്പെട്ടവ';

  @override
  String get smartAlbumVideos => 'വീഡിയോകൾ';

  @override
  String get smartAlbumGifs => 'ആനിമേറ്റഡും GIF-ഉം';

  @override
  String get smartAlbumRaw => 'RAW ചിത്രങ്ങൾ';

  @override
  String get smartAlbumPanoramas => 'പനോരമകൾ';

  @override
  String get smartAlbumRecent => 'അടുത്തിടെ ചേർത്തവ';

  @override
  String get smartAlbumTrash => 'ചവറ്റുകുട്ട';

  @override
  String get albumNew => 'പുതിയ ആൽബം';

  @override
  String get albumCreateTitle => 'പുതിയ ആൽബം';

  @override
  String get albumRenameTitle => 'ആൽബത്തിന്റെ പേര് മാറ്റുക';

  @override
  String get albumNameLabel => 'ആൽബത്തിന്റെ പേര്';

  @override
  String get albumNameHint => 'അവധിക്കാലം 2026';

  @override
  String get albumSave => 'സൂക്ഷിക്കുക';

  @override
  String get albumCancel => 'റദ്ദാക്കുക';

  @override
  String get albumRename => 'പേര് മാറ്റുക';

  @override
  String get albumDelete => 'ആൽബം ഇല്ലാതാക്കുക';

  @override
  String get albumChooseCover => 'കവർ തിരഞ്ഞെടുക്കുക';

  @override
  String get albumReorder => 'ക്രമം മാറ്റുക';

  @override
  String get albumAddMedia => 'ഫോട്ടോകൾ ചേർക്കുക';

  @override
  String get albumRemoveMedia => 'ആൽബത്തിൽ നിന്ന് നീക്കുക';

  @override
  String get albumPin => 'മുകളിൽ പിൻ ചെയ്യുക';

  @override
  String get albumUnpin => 'പിൻ ഒഴിവാക്കുക';

  @override
  String get albumErrorEmpty => 'ആൽബത്തിന് ഒരു പേര് വേണം';

  @override
  String get albumErrorTooLong => 'ആ പേര് വളരെ നീളമുള്ളതാണ്';

  @override
  String get albumErrorDuplicate => 'ആ പേരിൽ ഒരു ആൽബം ഇതിനകം ഉണ്ട്';

  @override
  String get albumErrorFailed => 'ആ മാറ്റം സൂക്ഷിക്കാൻ കഴിഞ്ഞില്ല';

  @override
  String albumDeleteConfirmTitle(String name) {
    return '\"$name\" ഇല്ലാതാക്കണോ?';
  }

  @override
  String get albumDeleteConfirmBody =>
      'ആൽബം മാത്രമേ പോകൂ. എല്ലാ ഫോട്ടോകളും വീഡിയോകളും ഉപകരണത്തിൽ ഇപ്പോഴുള്ള സ്ഥലത്തുതന്നെ നിൽക്കും.';

  @override
  String get albumDeleteConfirm => 'ആൽബം ഇല്ലാതാക്കുക';

  @override
  String get albumDeleted => 'ആൽബം ഇല്ലാതാക്കി';

  @override
  String get albumRemovedFromAlbum => 'ആൽബത്തിൽ നിന്ന് നീക്കി';

  @override
  String get albumCoverSet => 'കവർ പുതുക്കി';

  @override
  String get albumOrderSaved => 'പുതിയ ക്രമം സൂക്ഷിച്ചു';

  @override
  String get albumEmptyTitle => 'ഈ ആൽബം ശൂന്യമാണ്';

  @override
  String get albumEmptyBody =>
      'ഗാലറിയിൽ നിന്ന് ഫോട്ടോകളും വീഡിയോകളും ചേർക്കുക. അവ നീക്കുകയോ പകർത്തുകയോ ചെയ്യില്ല.';

  @override
  String get albumGone => 'ഈ ആൽബം ഇപ്പോൾ ഇല്ല';

  @override
  String get albumReorderTitle => 'ക്രമം മാറ്റുക';

  @override
  String get albumReorderHint =>
      'ഒരു ഇനം നീക്കാൻ അത് വലിച്ചിടുക. സൂക്ഷിക്കുക അമർത്തുമ്പോൾ പുതിയ ക്രമം സൂക്ഷിക്കും.';

  @override
  String get albumReorderSave => 'ക്രമം സൂക്ഷിക്കുക';

  @override
  String get albumCoverTitle => 'ഒരു കവർ തിരഞ്ഞെടുക്കുക';

  @override
  String get albumCoverClear => 'ഏറ്റവും പുതിയ ഇനം ഉപയോഗിക്കുക';

  @override
  String get albumPickerTitle => 'ആൽബത്തിൽ ചേർക്കുക';

  @override
  String get albumPickerEmpty => 'നിങ്ങൾക്ക് ഇതുവരെ ആൽബങ്ങളില്ല';

  @override
  String get albumPickerCreate => 'പുതിയ ആൽബം';

  @override
  String get albumPickerDone => 'പൂർത്തിയായി';

  @override
  String get albumPickerSaved => 'ആൽബങ്ങൾ പുതുക്കി';

  @override
  String get folderEmptyTitle => 'ഈ ഫോൾഡർ ശൂന്യമാണ്';

  @override
  String get smartAlbumEmptyTitle => 'ഇവിടെ ഇതുവരെ ഒന്നുമില്ല';

  @override
  String get smartAlbumUnknown => 'ആ ആൽബം നിലവിലില്ല';

  @override
  String get filterHasTags => 'ടാഗ് ഉള്ളവ മാത്രം';

  @override
  String get filterFileSize => 'ഫയൽ വലുപ്പം';

  @override
  String get filterSizeAny => 'ഏത് വലുപ്പവും';

  @override
  String get filterSizeSmall => '1 MB-യിൽ കുറവ്';

  @override
  String get filterSizeMedium => '1 മുതൽ 10 MB വരെ';

  @override
  String get filterSizeLarge => '10 MB-യിൽ കൂടുതൽ';

  @override
  String get filterSortBy => 'ക്രമീകരിക്കുക';

  @override
  String get filterSortDateTaken => 'എടുത്ത തീയതി';

  @override
  String get filterSortDateAdded => 'ചേർത്ത തീയതി';

  @override
  String get filterSortName => 'പേര്';

  @override
  String get filterSortSize => 'വലുപ്പം';

  @override
  String get filterSortNewestFirst => 'പുതിയത് ആദ്യം';

  @override
  String get filterSortOldestFirst => 'പഴയത് ആദ്യം';

  @override
  String get vaultTitle => 'സ്വകാര്യ വോള്‍ട്ട്';

  @override
  String get vaultMenuLabel => 'സ്വകാര്യ വോള്‍ട്ട്';

  @override
  String get vaultMoveToVault => 'വോള്‍ട്ടിലേക്ക് മാറ്റുക';

  @override
  String get vaultSetUpTitle => 'നിങ്ങളുടെ വോള്‍ട്ട് ഉണ്ടാക്കുക';

  @override
  String get vaultSetUpBody =>
      'ഇവിടേക്ക് മാറ്റുന്ന ഇനങ്ങള്‍ ഈ ഉപകരണം സൂക്ഷിക്കുന്ന ഒരു കീ ഉപയോഗിച്ച് എന്‍ക്രിപ്റ്റ് ചെയ്യപ്പെടുകയും ഗാലറിയില്‍ നിന്ന് മറയ്ക്കപ്പെടുകയും ചെയ്യും.';

  @override
  String get vaultNoRecoveryWarning =>
      'മറന്നുപോയ പിന്‍ വീണ്ടെടുക്കാന്‍ വഴിയില്ല. അതില്ലാതെ ഈ ആപ്പിനു പോലും വോള്‍ട്ട് തുറക്കാനാവില്ല.';

  @override
  String get vaultChoosePin => 'ഒരു പിന്‍ തിരഞ്ഞെടുക്കുക';

  @override
  String get vaultConfirmPin => 'പിന്‍ വീണ്ടും നല്‍കുക';

  @override
  String get vaultEnterPin => 'നിങ്ങളുടെ പിന്‍ നല്‍കുക';

  @override
  String get vaultCreate => 'വോള്‍ട്ട് ഉണ്ടാക്കുക';

  @override
  String get vaultUnlock => 'തുറക്കുക';

  @override
  String get vaultUseBiometrics => 'വിരലടയാളം ഉപയോഗിക്കുക';

  @override
  String get vaultUnlockReason => 'സ്വകാര്യ വോള്‍ട്ട് തുറക്കുക';

  @override
  String get vaultLockNow => 'ഇപ്പോള്‍ പൂട്ടുക';

  @override
  String get vaultPinMismatch => 'രണ്ട് പിന്നുകളും ഒന്നല്ല';

  @override
  String get vaultWrongPin => 'പിന്‍ ശരിയല്ല';

  @override
  String vaultAttemptsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ശ്രമങ്ങള്‍ ബാക്കി',
      one: '1 ശ്രമം ബാക്കി',
    );
    return '$_temp0';
  }

  @override
  String vaultLockedOut(int seconds) {
    return 'ഒട്ടേറെ ശ്രമങ്ങള്‍. $seconds സെക്കന്‍റ് കാത്തിരിക്കുക.';
  }

  @override
  String vaultPinTooShort(int count) {
    return 'പിന്നിന് കുറഞ്ഞത് $count അക്കങ്ങള്‍ വേണം';
  }

  @override
  String vaultPinTooLong(int count) {
    return 'പിന്നിന് പരമാവധി $count അക്കങ്ങള്‍ മാത്രമേ പാടുള്ളൂ';
  }

  @override
  String get vaultPinNotDigits => 'പിന്നില്‍ അക്കങ്ങള്‍ മാത്രമേ ആകാവൂ';

  @override
  String get vaultPinAllSame => 'ഒരേ അക്കം ആവര്‍ത്തിക്കരുത്';

  @override
  String get vaultPinSequential =>
      'തുടര്‍ച്ചയായി വരുന്ന അക്കങ്ങള്‍ ഉപയോഗിക്കരുത്';

  @override
  String get vaultBiometricFailed =>
      'തിരിച്ചറിഞ്ഞില്ല. നിങ്ങളുടെ പിന്‍ ഉപയോഗിക്കുക.';

  @override
  String get vaultBiometricUnavailable =>
      'വിരലടയാളം ലഭ്യമല്ല. നിങ്ങളുടെ പിന്‍ ഉപയോഗിക്കുക.';

  @override
  String get vaultAuthError => 'വോള്‍ട്ട് തുറക്കാനായില്ല';

  @override
  String get vaultKeystoreUnavailableTitle =>
      'ഈ ഉപകരണത്തിന് വോള്‍ട്ട് കീ സൂക്ഷിക്കാനാവില്ല';

  @override
  String get vaultKeystoreUnavailableBody =>
      'വോള്‍ട്ടിന് ഹാര്‍ഡ്‌വെയര്‍ കീ സ്റ്റോര്‍ വേണം, ഈ ഉപകരണത്തില്‍ അത് പ്രവര്‍ത്തനക്ഷമമല്ല. അതില്ലാതെ ഒന്നും എന്‍ക്രിപ്റ്റ് ചെയ്യാനാവില്ല, അതിനാല്‍ വോള്‍ട്ട് അടഞ്ഞു കിടക്കും.';

  @override
  String get vaultEmptyTitle => 'വോള്‍ട്ട് കാലിയാണ്';

  @override
  String get vaultEmptyBody =>
      'ചിത്രങ്ങളും വീഡിയോകളും ഇവിടെ ചേര്‍ത്താല്‍ അവ എന്‍ക്രിപ്റ്റ് ചെയ്യുകയും ഗാലറിയില്‍ നിന്ന് മാറ്റുകയും ചെയ്യും.';

  @override
  String vaultItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഇനങ്ങള്‍',
      one: '1 ഇനം',
      zero: 'ഇനങ്ങള്‍ ഇല്ല',
    );
    return '$_temp0';
  }

  @override
  String vaultSelectedCount(int count) {
    return '$count തിരഞ്ഞെടുത്തു';
  }

  @override
  String get vaultAddItems => 'ഇനങ്ങള്‍ ചേര്‍ക്കുക';

  @override
  String get vaultRestore => 'ഗാലറിയിലേക്ക് തിരികെ കൊണ്ടുവരിക';

  @override
  String get vaultDeleteForever => 'പൂര്‍ണ്ണമായി ഇല്ലാതാക്കുക';

  @override
  String get vaultSettingsAction => 'വോള്‍ട്ട് ക്രമീകരണങ്ങള്‍';

  @override
  String get vaultWorking => 'പ്രവര്‍ത്തിക്കുന്നു…';

  @override
  String get vaultCancel => 'റദ്ദാക്കുക';

  @override
  String get vaultSelectAll => 'എല്ലാം തിരഞ്ഞെടുക്കുക';

  @override
  String get vaultClearSelection => 'തിരഞ്ഞെടുപ്പ് മായ്ക്കുക';

  @override
  String get vaultImportTitle => 'വോള്‍ട്ടിലേക്ക് മാറ്റുക';

  @override
  String get vaultImportBody =>
      'ഇനങ്ങള്‍ എന്‍ക്രിപ്റ്റ് ചെയ്യപ്പെടുകയും ഗാലറിയില്‍ നിന്ന് മാറ്റുകയും ചെയ്യും. മൂല ഫയലുകള്‍ എന്തു ചെയ്യണം എന്നത് നിങ്ങള്‍ തീരുമാനിക്കുക.';

  @override
  String get vaultImportKeepOriginal => 'മൂല ഫയലുകള്‍ സൂക്ഷിക്കുക';

  @override
  String get vaultImportKeepOriginalBody =>
      'മൂല ഫയലുകള്‍ അവിടെത്തന്നെ തുടരും. വേണമെങ്കില്‍ പിന്നീട് സ്വയം ഇല്ലാതാക്കാം.';

  @override
  String get vaultImportShredOriginal => 'മൂല ഫയലുകള്‍ നശിപ്പിക്കുക';

  @override
  String get vaultImportShredOriginalBody =>
      'മൂല ഫയലുകള്‍ മേലെഴുതി ഇല്ലാതാക്കും. ഇത് തിരികെ എടുക്കാനാവില്ല.';

  @override
  String vaultImportConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഇനങ്ങള്‍ മാറ്റുക',
      one: '1 ഇനം മാറ്റുക',
    );
    return '$_temp0';
  }

  @override
  String get vaultImportNothingSelected => 'ഒന്നും തിരഞ്ഞെടുത്തിട്ടില്ല';

  @override
  String vaultShredConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count മൂല ഫയലുകള്‍ നശിപ്പിക്കണോ?',
      one: '1 മൂല ഫയല്‍ നശിപ്പിക്കണോ?',
    );
    return '$_temp0';
  }

  @override
  String get vaultShredConfirmBody =>
      'മൂല ഫയലുകള്‍ മേലെഴുതി ഇല്ലാതാക്കും. ഇത് തിരികെ എടുക്കാനാവില്ല.';

  @override
  String get vaultShredConfirmAction => 'നശിപ്പിക്കുക';

  @override
  String vaultImportDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഇനങ്ങള്‍ വോള്‍ട്ടിലേക്ക് മാറ്റി',
      one: '1 ഇനം വോള്‍ട്ടിലേക്ക് മാറ്റി',
    );
    return '$_temp0';
  }

  @override
  String vaultImportPartial(int moved, int failed) {
    return '$moved മാറ്റി, $failed വായിക്കാനായില്ല';
  }

  @override
  String get vaultImportFailed => 'ഒന്നും വോള്‍ട്ടിലേക്ക് മാറ്റാനായില്ല';

  @override
  String vaultRestoreConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഇനങ്ങള്‍ തിരികെ കൊണ്ടുവരണോ?',
      one: '1 ഇനം തിരികെ കൊണ്ടുവരണോ?',
    );
    return '$_temp0';
  }

  @override
  String get vaultRestoreConfirmBody =>
      'ഇനങ്ങള്‍ നിങ്ങളുടെ ഗാലറി ഫോള്‍ഡറുകളിലേക്ക് തിരികെ എഴുതുകയും വോള്‍ട്ടില്‍ നിന്ന് മാറ്റുകയും ചെയ്യും.';

  @override
  String get vaultRestoreConfirmAction => 'തിരികെ കൊണ്ടുവരിക';

  @override
  String vaultRestoreDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഇനങ്ങള്‍ തിരികെ എത്തി',
      one: '1 ഇനം തിരികെ എത്തി',
    );
    return '$_temp0';
  }

  @override
  String get vaultRestoreFailed => 'ഒന്നും തിരികെ കൊണ്ടുവരാനായില്ല';

  @override
  String vaultDeleteConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഇനങ്ങള്‍ പൂര്‍ണ്ണമായി ഇല്ലാതാക്കണോ?',
      one: '1 ഇനം പൂര്‍ണ്ണമായി ഇല്ലാതാക്കണോ?',
    );
    return '$_temp0';
  }

  @override
  String get vaultDeleteConfirmBody =>
      'എന്‍ക്രിപ്റ്റ് ചെയ്ത ഫയലുകള്‍ മേലെഴുതി ഇല്ലാതാക്കും. തിരികെ എടുക്കാനാവില്ല, മറ്റൊരിടത്തും പകര്‍പ്പുമില്ല.';

  @override
  String vaultDeleteDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഇനങ്ങള്‍ ഇല്ലാതാക്കി',
      one: '1 ഇനം ഇല്ലാതാക്കി',
    );
    return '$_temp0';
  }

  @override
  String get vaultViewerFailed => 'ഈ ഇനം തുറക്കാനായില്ല';

  @override
  String get vaultViewerTampered =>
      'ഈ ഇനത്തിന്‍റെ സമഗ്രതാ പരിശോധന പരാജയപ്പെട്ടു, അത് തുറന്നില്ല';

  @override
  String get vaultSettingsTitle => 'വോള്‍ട്ട് ക്രമീകരണങ്ങള്‍';

  @override
  String get vaultAutoLockHeading => 'സ്വയം പൂട്ടല്‍';

  @override
  String get vaultAutoLockBody =>
      'ആപ്പ് സ്ക്രീനില്‍ നിന്ന് മാറുമ്പോള്‍ വോള്‍ട്ട് എപ്പോഴും പൂടും. നിങ്ങള്‍ തൊടാതിരിക്കുമ്പോള്‍ എത്ര നേരം കാത്തിരിക്കണം എന്നതാണ് ഇത്.';

  @override
  String vaultAutoLockSeconds(int count) {
    return '$count സെക്കന്‍റ്';
  }

  @override
  String vaultAutoLockMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count മിനിറ്റ്',
      one: '1 മിനിറ്റ്',
    );
    return '$_temp0';
  }

  @override
  String get vaultBiometricHeading => 'വിരലടയാളം കൊണ്ട് തുറക്കുക';

  @override
  String get vaultBiometricBody =>
      'ഇതൊരു കുറുക്കുവഴി മാത്രമാണ്. ഇത് ഓണ്‍ ആയാലും ഓഫ് ആയാലും നിങ്ങളുടെ പിന്‍ വോള്‍ട്ട് തുറക്കും.';

  @override
  String get vaultShredHeading => 'നശിപ്പിക്കലിന്‍റെ തവണകള്‍';

  @override
  String get vaultShredBody =>
      'ഒരു ഫയല്‍ ഇല്ലാതാക്കുന്നതിനു മുമ്പ് എത്ര തവണ മേലെഴുതണം. കൂടുതല്‍ തവണകള്‍ കൂടുതല്‍ സമയമെടുക്കും. ഫ്ലാഷ് സ്റ്റോറേജില്‍ ഇത് ശക്തമായ ഒരു നടപടിയാണ്, ഉറപ്പല്ല.';

  @override
  String vaultShredPassCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count തവണ',
      one: '1 തവണ',
    );
    return '$_temp0';
  }

  @override
  String get vaultShredDefaultHeading => 'സ്ഥിരമായി മൂല ഫയലുകള്‍ നശിപ്പിക്കുക';

  @override
  String get vaultShredDefaultBody =>
      'ഇനങ്ങള്‍ ചേര്‍ക്കുമ്പോള്‍ നശിപ്പിക്കല്‍ മുന്‍കൂട്ടി തിരഞ്ഞെടുക്കും. ഓരോ തവണയും സ്ഥിരീകരിക്കാന്‍ ചോദിക്കും.';

  @override
  String get vaultChangePin => 'പിന്‍ മാറ്റുക';

  @override
  String get vaultCurrentPin => 'ഇപ്പോഴത്തെ പിന്‍';

  @override
  String get vaultNewPin => 'പുതിയ പിന്‍';

  @override
  String get vaultPinChanged => 'നിങ്ങളുടെ പിന്‍ മാറ്റി';

  @override
  String get vaultSecureScreenHeading => 'സ്ക്രീന്‍ഷോട്ടുകള്‍ തടഞ്ഞിരിക്കുന്നു';

  @override
  String get vaultSecureScreenBody =>
      'വോള്‍ട്ട് തുറന്നിരിക്കേ, ആന്‍ഡ്രോയ്ഡ് സ്ക്രീന്‍ഷോട്ടും സ്ക്രീന്‍ റെക്കോര്‍ഡിങ്ങും തടയുകയും ആപ്പ് സ്വിച്ചറില്‍ വോള്‍ട്ട് മറയ്ക്കുകയും ചെയ്യും.';

  @override
  String selectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count തിരഞ്ഞെടുത്തു',
      one: '1 തിരഞ്ഞെടുത്തു',
    );
    return '$_temp0';
  }

  @override
  String get selectionClear => 'തിരഞ്ഞെടുപ്പ് മായ്ക്കുക';

  @override
  String get selectionSelectAll => 'എല്ലാം തിരഞ്ഞെടുക്കുക';

  @override
  String get selectionFull => 'ഒരു ബാച്ചിന് ഉൾക്കൊള്ളാവുന്ന പരമാവധി ഇത്രയാണ്';

  @override
  String get batchTitle => 'ബാച്ച് പ്രവൃത്തികൾ';

  @override
  String get batchActionConvert => 'രൂപാന്തരപ്പെടുത്തുക';

  @override
  String get batchActionWatermark => 'വാട്ടർമാർക്ക്';

  @override
  String get batchActionExportPdf => 'പി.ഡി.എഫ് ഉണ്ടാക്കുക';

  @override
  String get batchActionAddTags => 'ടാഗുകൾ ചേർക്കുക';

  @override
  String get batchActionRemoveTags => 'ടാഗുകൾ നീക്കുക';

  @override
  String get batchActionAddToAlbum => 'ആൽബത്തിൽ ചേർക്കുക';

  @override
  String get batchActionFavourite => 'പ്രിയപ്പെട്ടവയിൽ ചേർക്കുക';

  @override
  String get batchActionUnfavourite => 'പ്രിയപ്പെട്ടവയിൽ നിന്ന് നീക്കുക';

  @override
  String get batchActionMoveToVault => 'വോൾട്ടിലേക്ക് മാറ്റുക';

  @override
  String get batchActionTransfer => 'ഒരു ഉപകരണത്തിലേക്ക് അയയ്ക്കുക';

  @override
  String get batchActionMoveToTrash => 'ചവറ്റുകുട്ടയിലേക്ക് മാറ്റുക';

  @override
  String get batchBlockedEmpty => 'ആദ്യം എന്തെങ്കിലും തിരഞ്ഞെടുക്കുക';

  @override
  String get batchBlockedTooLarge => 'ഒരു ബാച്ചിന് വളരെയധികം ഇനങ്ങൾ';

  @override
  String get batchBlockedUnsupported => 'ഈ ഫയലുകൾക്ക് ലഭ്യമല്ല';

  @override
  String get batchBlockedMixed => 'ഈ പ്രവൃത്തിയിൽ വീഡിയോകൾ ഉൾപ്പെടുത്താനാവില്ല';

  @override
  String batchWillSkip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഫയലുകൾ ഒഴിവാക്കും',
      one: '1 ഫയൽ ഒഴിവാക്കും',
    );
    return '$_temp0';
  }

  @override
  String get batchRunning => 'പ്രവർത്തിക്കുന്നു';

  @override
  String batchProgress(int done, int total) {
    return '$total ൽ $done';
  }

  @override
  String get batchCancel => 'റദ്ദാക്കുക';

  @override
  String get batchCancelling => 'ഈ ഫയലിനു ശേഷം നിർത്തുന്നു';

  @override
  String get batchDone => 'പൂർത്തിയായി';

  @override
  String batchResultSucceeded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഫയലുകൾ പൂർത്തിയായി',
      one: '1 ഫയൽ പൂർത്തിയായി',
    );
    return '$_temp0';
  }

  @override
  String batchResultFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഫയലുകൾ ചെയ്യാനായില്ല',
      one: '1 ഫയൽ ചെയ്യാനായില്ല',
    );
    return '$_temp0';
  }

  @override
  String batchResultSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഫയലുകൾ ഒഴിവാക്കി',
      one: '1 ഫയൽ ഒഴിവാക്കി',
    );
    return '$_temp0';
  }

  @override
  String get batchConfirmTitle => 'ഉറപ്പാണോ?';

  @override
  String batchConfirmVault(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഫോട്ടോകൾ വോൾട്ടിലേക്ക് മാറ്റും',
      one: '1 ഫോട്ടോ വോൾട്ടിലേക്ക് മാറ്റും',
    );
    return '$_temp0';
  }

  @override
  String batchConfirmTrash(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഇനങ്ങൾ ചവറ്റുകുട്ടയിലേക്ക് മാറ്റും. ഒന്നും മായ്ക്കില്ല.',
      one: '1 ഇനം ചവറ്റുകുട്ടയിലേക്ക് മാറ്റും. ഒന്നും മായ്ക്കില്ല.',
    );
    return '$_temp0';
  }

  @override
  String batchConfirmNewFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ഒറിജിനലുകൾക്കൊപ്പം $count പുതിയ ഫയലുകൾ സേവ് ചെയ്യും.',
      one: 'ഒറിജിനലിനൊപ്പം ഒരു പുതിയ ഫയൽ സേവ് ചെയ്യും.',
    );
    return '$_temp0';
  }

  @override
  String get batchConfirmContinue => 'തുടരുക';

  @override
  String get batchPickTags => 'ടാഗുകൾ തിരഞ്ഞെടുക്കുക';

  @override
  String get batchPickAlbum => 'ഒരു ആൽബം തിരഞ്ഞെടുക്കുക';

  @override
  String get backupTitle => 'ബാക്കപ്പും പുനഃസ്ഥാപനവും';

  @override
  String get backupOpen => 'ബാക്കപ്പും പുനഃസ്ഥാപനവും';

  @override
  String get backupCreateTitle => 'ഒരു ബാക്കപ്പ് ഉണ്ടാക്കുക';

  @override
  String get backupCreateBody =>
      'നിങ്ങളുടെ ടാഗുകൾ, ആൽബങ്ങൾ, പ്രിയപ്പെട്ടവ, കുറിപ്പുകൾ എന്നിവ പാസ്‌വേഡ് കൊണ്ട് സംരക്ഷിച്ച ഒരു ഫയലിൽ സേവ് ചെയ്യുന്നു. ഫോട്ടോകളും വീഡിയോകളും ഇതിൽ ഇല്ല: അവ ട്രാൻസ്ഫർ ഉപയോഗിച്ച് മറ്റൊരു ഉപകരണത്തിലേക്ക് അയയ്ക്കുക.';

  @override
  String get backupCreateAction => 'ബാക്കപ്പ് ഉണ്ടാക്കുക';

  @override
  String get backupRestoreTitle => 'ഒരു ബാക്കപ്പ് പുനഃസ്ഥാപിക്കുക';

  @override
  String get backupRestoreBody =>
      'ഈ ഉപകരണത്തിലുള്ള ഫോട്ടോകൾക്കായി ടാഗുകൾ, ആൽബങ്ങൾ, പ്രിയപ്പെട്ടവ, കുറിപ്പുകൾ എന്നിവ തിരികെ കൊണ്ടുവരുന്നു. ഈ ഉപകരണത്തിൽ നിന്ന് ഒന്നും ഇല്ലാതാക്കുന്നില്ല.';

  @override
  String get backupRestoreAction => 'ഒരു ബാക്കപ്പ് ഫയൽ തിരഞ്ഞെടുക്കുക';

  @override
  String get backupPasswordTitle => 'ബാക്കപ്പ് പാസ്‌വേഡ്';

  @override
  String get backupPasswordLabel => 'പാസ്‌വേഡ്';

  @override
  String get backupPasswordConfirmLabel => 'വീണ്ടും ടൈപ്പ് ചെയ്യുക';

  @override
  String get backupPasswordWarning =>
      'ഈ പാസ്‌വേഡ് വീണ്ടെടുക്കാൻ ഒരു വഴിയുമില്ല. മറന്നാൽ ബാക്കപ്പ് തുറക്കാനാവില്ല.';

  @override
  String backupPasswordTooShort(int count) {
    return 'കുറഞ്ഞത് $count അക്ഷരങ്ങൾ';
  }

  @override
  String get backupPasswordMismatch => 'രണ്ടും തമ്മിൽ പൊരുത്തപ്പെടുന്നില്ല';

  @override
  String get backupStageCollecting => 'നിങ്ങളുടെ ലൈബ്രറി വായിക്കുന്നു';

  @override
  String get backupStagePacking => 'പായ്ക്ക് ചെയ്യുന്നു';

  @override
  String get backupStageChoosing =>
      'എവിടെ സേവ് ചെയ്യണമെന്ന് തിരഞ്ഞെടുക്കാൻ കാത്തിരിക്കുന്നു';

  @override
  String get backupStageEncrypting => 'എൻക്രിപ്റ്റ് ചെയ്യുന്നു';

  @override
  String get backupDone => 'ബാക്കപ്പ് സേവ് ചെയ്തു';

  @override
  String get backupCancelled => 'ബാക്കപ്പ് റദ്ദാക്കി';

  @override
  String get backupNothingToSave =>
      'ബാക്കപ്പ് ചെയ്യാൻ ടാഗുകളോ ആൽബങ്ങളോ കുറിപ്പുകളോ പ്രിയപ്പെട്ടവയോ ഇതുവരെ ഇല്ല';

  @override
  String get backupFailed => 'ബാക്കപ്പ് സേവ് ചെയ്യാനായില്ല';

  @override
  String get restorePreviewTitle => 'എന്ത് പുനഃസ്ഥാപിക്കും';

  @override
  String restoreFromBackupDate(String date) {
    return '$date ലെ ബാക്കപ്പ്';
  }

  @override
  String restorePlanTags(int count) {
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
  String restorePlanAlbums(int count) {
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
  String restorePlanLinks(int count) {
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
  String restorePlanUpdates(int count) {
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
  String restorePlanUnmatched(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ബാക്കപ്പിലെ $count ഫോട്ടോകൾ ഈ ഉപകരണത്തിൽ ഇല്ല',
      one: 'ബാക്കപ്പിലെ 1 ഫോട്ടോ ഈ ഉപകരണത്തിൽ ഇല്ല',
    );
    return '$_temp0';
  }

  @override
  String get restorePlanNothing => 'ഈ ബാക്കപ്പ് ഈ ഉപകരണത്തിൽ ഒന്നും മാറ്റില്ല';

  @override
  String get restoreApply => 'പുനഃസ്ഥാപിക്കുക';

  @override
  String get restoreDone => 'പുനഃസ്ഥാപനം പൂർത്തിയായി';

  @override
  String get restoreWrongPassword =>
      'തെറ്റായ പാസ്‌വേഡ്, അല്ലെങ്കിൽ ഫയൽ കേടായിരിക്കുന്നു';

  @override
  String get restoreNotAnArchive => 'അത് ഒരു ഗാലറി ബാക്കപ്പ് ഫയൽ അല്ല';

  @override
  String get restoreTooLarge => 'ഒരു ഗാലറി ബാക്കപ്പ് ആകാൻ ആ ഫയൽ വളരെ വലുതാണ്';

  @override
  String get restoreTooNew =>
      'ആ ബാക്കപ്പ് ആപ്പിന്റെ പുതിയ പതിപ്പ് ഉണ്ടാക്കിയതാണ്';

  @override
  String get restoreFailed => 'ബാക്കപ്പ് പുനഃസ്ഥാപിക്കാനായില്ല';

  @override
  String get syncTitle => 'ട്രാൻസ്ഫർ';

  @override
  String get syncOpen => 'ഒരു ഉപകരണത്തിലേക്ക് ട്രാൻസ്ഫർ';

  @override
  String get syncIntro =>
      'അതേ വൈ-ഫൈയിലുള്ള മറ്റൊരു ഫോണിലേക്ക് നേരിട്ട് ഫോട്ടോകൾ അയയ്ക്കുക. ഒന്നും ഇന്റർനെറ്റിലേക്ക് പോകുന്നില്ല, അക്കൗണ്ട് വേണ്ട.';

  @override
  String get syncPrivacyNote =>
      'രണ്ട് ഫോണുകളും ഒരേ വൈ-ഫൈയിൽ ആയിരിക്കണം. മറ്റേ ഉപകരണം നിങ്ങളുടെ ലോക്കൽ നെറ്റ്‌വർക്കിൽ അല്ലെങ്കിൽ കണക്ഷൻ നിരസിക്കും, ഈ സ്ക്രീൻ വിട്ടാലുടൻ അത് അടയ്ക്കും.';

  @override
  String get syncSend => 'അയയ്ക്കുക';

  @override
  String get syncReceive => 'സ്വീകരിക്കുക';

  @override
  String get syncSendBody =>
      'ഈ ഫോണിൽ ഒരു കോഡ് കാണിക്കുക, അല്ലെങ്കിൽ മറ്റേത് സ്കാൻ ചെയ്യുക';

  @override
  String get syncReceiveBody => 'മറ്റേ ഫോൺ സ്കാൻ ചെയ്യാൻ ഒരു കോഡ് കാണിക്കുക';

  @override
  String get syncShowCode => 'ഒരു കോഡ് കാണിക്കുക';

  @override
  String get syncScanCode => 'ഒരു കോഡ് സ്കാൻ ചെയ്യുക';

  @override
  String get syncScanTitle => 'മറ്റേ ഫോൺ സ്കാൻ ചെയ്യുക';

  @override
  String get syncPairingHeading => 'മറ്റേ ഫോൺ ഈ കോഡിലേക്ക് ചൂണ്ടുക';

  @override
  String get syncManualCodeHeading => 'അല്ലെങ്കിൽ ഈ കോഡ് ടൈപ്പ് ചെയ്യുക';

  @override
  String get syncManualCodeLabel => 'ജോടിയാക്കൽ കോഡ്';

  @override
  String get syncManualCodeInvalid => 'ആ കോഡ് സാധുവല്ല';

  @override
  String get syncWaiting => 'മറ്റേ ഫോണിനായി കാത്തിരിക്കുന്നു';

  @override
  String syncPairedWith(String name) {
    return '$name മായി ജോടിയാക്കി';
  }

  @override
  String get syncTransferring => 'ട്രാൻസ്ഫർ ചെയ്യുന്നു';

  @override
  String syncProgressFiles(int done, int total) {
    return '$total ഫയലുകളിൽ $done';
  }

  @override
  String get syncNothingSelected =>
      'ആദ്യം അയയ്ക്കാൻ കുറച്ച് ഫോട്ടോകൾ തിരഞ്ഞെടുക്കുക';

  @override
  String syncOfferHeading(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഫയലുകൾ വാഗ്ദാനം ചെയ്തു',
      one: '1 ഫയൽ വാഗ്ദാനം ചെയ്തു',
    );
    return '$_temp0';
  }

  @override
  String get syncDone => 'ട്രാൻസ്ഫർ പൂർത്തിയായി';

  @override
  String syncResultReceived(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഫയലുകൾ ലഭിച്ചു',
      one: '1 ഫയൽ ലഭിച്ചു',
    );
    return '$_temp0';
  }

  @override
  String syncResultSent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഫയലുകൾ അയച്ചു',
      one: '1 ഫയൽ അയച്ചു',
    );
    return '$_temp0';
  }

  @override
  String syncResultSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഫയലുകൾ നേരത്തെ ഉണ്ടായിരുന്നു',
      one: '1 ഫയൽ നേരത്തെ ഉണ്ടായിരുന്നു',
    );
    return '$_temp0';
  }

  @override
  String syncResultFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഫയലുകൾ എത്തിയില്ല',
      one: '1 ഫയൽ എത്തിയില്ല',
    );
    return '$_temp0';
  }

  @override
  String get syncSavedToAppFolder =>
      'ആൻഡ്രോയ്ഡിന്റെ ഈ പതിപ്പിൽ ഫയലുകൾ നിങ്ങളുടെ ഗാലറിക്ക് പകരം ആപ്പിന്റെ സ്വന്തം ഫോൾഡറിൽ സേവ് ചെയ്തു.';

  @override
  String get syncStop => 'നിർത്തുക';

  @override
  String get syncErrorNoNetwork => 'ഈ ഫോൺ ഒരു വൈ-ഫൈ നെറ്റ്‌വർക്കിൽ അല്ല';

  @override
  String get syncErrorPairingTimeout =>
      'സമയത്ത് ഒരു ഉപകരണവും കണക്റ്റ് ചെയ്തില്ല';

  @override
  String get syncErrorRefused =>
      'ആ ഉപകരണം നിങ്ങളുടെ ലോക്കൽ നെറ്റ്‌വർക്കിൽ അല്ല';

  @override
  String get syncErrorHandshake =>
      'ആ കോഡ് കാണിച്ചതെന്ന് മറ്റേ ഉപകരണത്തിന് തെളിയിക്കാനായില്ല';

  @override
  String get syncErrorProtocol =>
      'മറ്റേ ഉപകരണം ആപ്പിന്റെ മറ്റൊരു പതിപ്പാണ് പ്രവർത്തിപ്പിക്കുന്നത്';

  @override
  String get syncErrorConnection => 'മറ്റേ ഉപകരണവുമായുള്ള കണക്ഷൻ നഷ്ടപ്പെട്ടു';

  @override
  String get syncErrorIdle => 'മറ്റേ ഉപകരണം പ്രതികരിക്കുന്നത് നിർത്തി';

  @override
  String get syncErrorCancelled => 'ട്രാൻസ്ഫർ നിർത്തി';

  @override
  String get syncErrorUnknown => 'ട്രാൻസ്ഫർ പൂർത്തിയാക്കാനായില്ല';

  @override
  String get syncCameraPermission =>
      'കോഡ് സ്കാൻ ചെയ്യാൻ ക്യാമറ ആക്‌സസ് വേണം. പകരം കോഡ് ടൈപ്പ് ചെയ്യാം.';

  @override
  String get syncTypeCodeInstead => 'പകരം കോഡ് ടൈപ്പ് ചെയ്യുക';

  @override
  String get viewerMoreActions => 'കൂടുതൽ';

  @override
  String get codeScanOpen => 'കോഡുകൾ സ്കാൻ ചെയ്യുക';

  @override
  String get codeScanTitle => 'ഈ ചിത്രത്തിലെ കോഡുകൾ';

  @override
  String get codeScanLooking => 'കോഡുകൾ തിരയുന്നു';

  @override
  String get codeScanNoCodes => 'ഈ ചിത്രത്തിൽ കോഡുകളൊന്നും കണ്ടെത്തിയില്ല';

  @override
  String get codeScanFailed => 'ഈ ചിത്രം സ്കാൻ ചെയ്യാൻ കഴിഞ്ഞില്ല';

  @override
  String get codeScanRetry => 'വീണ്ടും ശ്രമിക്കുക';

  @override
  String codeScanFoundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count കോഡുകൾ കണ്ടെത്തി',
      one: '1 കോഡ് കണ്ടെത്തി',
    );
    return '$_temp0';
  }

  @override
  String get codeScanKindUrl => 'വെബ് വിലാസം';

  @override
  String get codeScanKindWifi => 'വൈ-ഫൈ നെറ്റ്‌വർക്ക്';

  @override
  String get codeScanKindPhone => 'ഫോൺ നമ്പർ';

  @override
  String get codeScanKindEmail => 'ഇമെയിൽ വിലാസം';

  @override
  String get codeScanKindSms => 'സന്ദേശം';

  @override
  String get codeScanKindGeo => 'ഭൂപട സ്ഥാനം';

  @override
  String get codeScanKindContact => 'കോൺടാക്ട് കാർഡ്';

  @override
  String get codeScanKindCalendar => 'കലണ്ടർ ഇനം';

  @override
  String get codeScanKindText => 'ടെക്സ്റ്റ്';

  @override
  String get codeScanActionCopy => 'പകർത്തുക';

  @override
  String get codeScanActionOpen => 'തുറക്കുക';

  @override
  String get codeScanActionDial => 'വിളിക്കുക';

  @override
  String get codeScanActionEmail => 'ഇമെയിൽ എഴുതുക';

  @override
  String get codeScanActionSms => 'സന്ദേശം അയയ്ക്കുക';

  @override
  String get codeScanActionMap => 'ഭൂപടത്തിൽ കാണിക്കുക';

  @override
  String get codeScanActionCopyWifiPassword => 'പാസ്‌വേഡ് പകർത്തുക';

  @override
  String get codeScanActionConnectWifi => 'കണക്റ്റ് ചെയ്യുക';

  @override
  String get codeScanActionSaveToNotes => 'കുറിപ്പുകളിൽ സൂക്ഷിക്കുക';

  @override
  String get codeScanBlockedScheme => 'ഈ തരം വിലാസം ആപ്പ് തുറക്കില്ല';

  @override
  String get codeScanBlockedMalformed => 'ഈ വിലാസം വായിക്കാൻ കഴിഞ്ഞില്ല';

  @override
  String get codeScanBlockedIncompleteWifi =>
      'ഈ വൈ-ഫൈ കോഡിൽ നെറ്റ്‌വർക്ക് പേരോ പാസ്‌വേഡോ ഇല്ല';

  @override
  String get codeScanBlockedTooLong =>
      'ഈ കോഡ് ഉപയോഗിക്കാൻ കഴിയാത്തത്ര നീളമുള്ളതാണ്';

  @override
  String get codeScanCopied => 'പകർത്തി';

  @override
  String get codeScanPasswordCopied => 'പാസ്‌വേഡ് പകർത്തി';

  @override
  String get codeScanSavedToNotes => 'കുറിപ്പുകളിൽ സൂക്ഷിച്ചു';

  @override
  String get codeScanOpenFailed =>
      'ഇത് തുറക്കാൻ കഴിയുന്ന ആപ്പ് ഈ ഉപകരണത്തിൽ ഇല്ല';

  @override
  String get codeScanWifiSuggested =>
      'നെറ്റ്‌വർക്ക് Android-ന് നൽകി. വൈ-ഫൈ ക്രമീകരണങ്ങളിൽ അത് തിരഞ്ഞെടുക്കുക.';

  @override
  String get codeScanWifiManual =>
      'വൈ-ഫൈ ക്രമീകരണങ്ങൾ തുറന്ന് നെറ്റ്‌വർക്ക് സ്വയം തിരഞ്ഞെടുക്കുക.';

  @override
  String codeScanWifiSecurity(String security) {
    return 'സുരക്ഷ: $security';
  }

  @override
  String get codeScanWifiHidden => 'മറഞ്ഞിരിക്കുന്ന നെറ്റ്‌വർക്ക്';

  @override
  String get codeScanWifiOpen => 'തുറന്ന നെറ്റ്‌വർക്ക്';

  @override
  String get ocrOpen => 'ടെക്സ്റ്റ് എടുക്കുക';

  @override
  String get ocrTitle => 'ഈ ചിത്രത്തിലെ ടെക്സ്റ്റ്';

  @override
  String get ocrReading => 'ടെക്സ്റ്റ് വായിക്കുന്നു';

  @override
  String get ocrSlowHint => 'വലിയ ഫോട്ടോയ്ക്ക് കുറച്ച് സെക്കൻഡ് എടുത്തേക്കാം.';

  @override
  String get ocrLanguage => 'ഭാഷ';

  @override
  String get ocrLanguageEnglish => 'ഇംഗ്ലീഷ്';

  @override
  String get ocrLanguageMalayalam => 'മലയാളം';

  @override
  String get ocrLanguageBoth => 'ഇംഗ്ലീഷും മലയാളവും';

  @override
  String get ocrNoText => 'ഈ ചിത്രത്തിൽ ടെക്സ്റ്റ് ഒന്നും കണ്ടെത്തിയില്ല';

  @override
  String get ocrCopyAll => 'എല്ലാം പകർത്തുക';

  @override
  String get ocrCopied => 'ടെക്സ്റ്റ് പകർത്തി';

  @override
  String get ocrSaveToNotes => 'കുറിപ്പുകളിൽ സൂക്ഷിക്കുക';

  @override
  String get ocrSavedToNotes => 'കുറിപ്പുകളിൽ സൂക്ഷിച്ചു';

  @override
  String get ocrReadAgain => 'വീണ്ടും വായിക്കുക';

  @override
  String ocrWordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count വാക്കുകൾ',
      one: '1 വാക്ക്',
    );
    return '$_temp0';
  }

  @override
  String get ocrFailedUnreadable => 'ഈ ചിത്രം തുറക്കാൻ കഴിഞ്ഞില്ല';

  @override
  String get ocrFailedTooLarge => 'ഈ ചിത്രം വായിക്കാൻ കഴിയാത്തത്ര വലുതാണ്';

  @override
  String get ocrFailedMissingData => 'ഈ ബിൽഡിൽ ഭാഷാ ഫയലുകൾ ഇല്ല';

  @override
  String get ocrFailedTimeout => 'വായന വളരെ നീണ്ടുപോയതിനാൽ നിർത്തി';

  @override
  String get ocrFailedEngine => 'ടെക്സ്റ്റ് വായിക്കാൻ കഴിഞ്ഞില്ല';

  @override
  String get notesOpen => 'കുറിപ്പുകൾ';

  @override
  String get notesTitle => 'കുറിപ്പുകൾ';

  @override
  String get notesWriteTab => 'എഴുതുക';

  @override
  String get notesPreviewTab => 'പ്രിവ്യൂ';

  @override
  String get notesHint =>
      'ഈ ഇനത്തെക്കുറിച്ച് ഒരു കുറിപ്പ് എഴുതുക. മാർക്ക്ഡൗൺ ഉപയോഗിക്കാം.';

  @override
  String get notesEmpty => 'ഇതുവരെ കുറിപ്പില്ല';

  @override
  String get notesSave => 'സൂക്ഷിക്കുക';

  @override
  String get notesSaved => 'കുറിപ്പ് സൂക്ഷിച്ചു';

  @override
  String get notesSaveFailed => 'കുറിപ്പ് സൂക്ഷിക്കാൻ കഴിഞ്ഞില്ല';

  @override
  String get notesDelete => 'കുറിപ്പ് ഇല്ലാതാക്കുക';

  @override
  String get notesDeleteTitle => 'ഈ കുറിപ്പ് ഇല്ലാതാക്കണോ?';

  @override
  String get notesDeleteBody => 'കുറിപ്പ് നീക്കം ചെയ്യും. ഫയലിന് മാറ്റമില്ല.';

  @override
  String get notesDeleted => 'കുറിപ്പ് ഇല്ലാതാക്കി';

  @override
  String get notesCancel => 'റദ്ദാക്കുക';

  @override
  String notesCharacterCount(int used, int total) {
    return '$total അക്ഷരങ്ങളിൽ $used';
  }

  @override
  String get notesTooLong => 'ഈ കുറിപ്പ് സൂക്ഷിക്കാൻ കഴിയാത്തത്ര നീളമുള്ളതാണ്';

  @override
  String get notesDiscardTitle => 'സൂക്ഷിക്കാതെ പോകണോ?';

  @override
  String get notesDiscardBody => 'ഈ കുറിപ്പിലെ മാറ്റങ്ങൾ നഷ്ടപ്പെടും.';

  @override
  String get notesDiscardLeave => 'പോകുക';

  @override
  String get notesDiscardKeep => 'എഴുത്ത് തുടരുക';

  @override
  String get notesLinkBlocked => 'ഈ തരം ലിങ്ക് ആപ്പ് തുറക്കില്ല';

  @override
  String get notesDetailsLabel => 'കുറിപ്പ്';

  @override
  String get notesAddFromDetails => 'ഒരു കുറിപ്പ് ചേർക്കുക';

  @override
  String get pdfImagesOpen => 'PDF-ൽ നിന്ന് ചിത്രങ്ങൾ എടുക്കുക';

  @override
  String get pdfImagesTitle => 'PDF-ലെ ചിത്രങ്ങൾ';

  @override
  String get pdfImagesPick => 'ഒരു PDF തിരഞ്ഞെടുക്കുക';

  @override
  String get pdfImagesChooseAnother => 'മറ്റൊരു PDF തിരഞ്ഞെടുക്കുക';

  @override
  String get pdfImagesReading => 'PDF വായിക്കുന്നു';

  @override
  String get pdfImagesEmptyTitle => 'ഇതുവരെ PDF തിരഞ്ഞെടുത്തിട്ടില്ല';

  @override
  String get pdfImagesEmptyBody =>
      'ഒരു PDF തിരഞ്ഞെടുക്കുക, അതിനുള്ളിലെ ചിത്രങ്ങൾ ആപ്പ് കാണിക്കും. PDF-ന് ഒരു മാറ്റവും വരുത്തില്ല.';

  @override
  String get pdfImagesNone => 'ഈ PDF-ൽ ചിത്രങ്ങളൊന്നുമില്ല';

  @override
  String pdfImagesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ചിത്രങ്ങൾ കണ്ടെത്തി',
      one: '1 ചിത്രം കണ്ടെത്തി',
    );
    return '$_temp0';
  }

  @override
  String pdfImagesSkippedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count എണ്ണം വായിക്കാൻ കഴിഞ്ഞില്ല',
      one: '1 എണ്ണം വായിക്കാൻ കഴിഞ്ഞില്ല',
    );
    return '$_temp0';
  }

  @override
  String get pdfImagesSave => 'തിരഞ്ഞെടുത്തവ സൂക്ഷിക്കുക';

  @override
  String get pdfImagesSaving => 'സൂക്ഷിക്കുന്നു';

  @override
  String pdfImagesSavedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ചിത്രങ്ങൾ ഗാലറിയിൽ സൂക്ഷിച്ചു',
      one: '1 ചിത്രം ഗാലറിയിൽ സൂക്ഷിച്ചു',
    );
    return '$_temp0';
  }

  @override
  String pdfImagesSaveFailedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count എണ്ണം സൂക്ഷിക്കാൻ കഴിഞ്ഞില്ല',
      one: '1 എണ്ണം സൂക്ഷിക്കാൻ കഴിഞ്ഞില്ല',
    );
    return '$_temp0';
  }

  @override
  String get pdfImagesSelectAll => 'എല്ലാം തിരഞ്ഞെടുക്കുക';

  @override
  String get pdfImagesClearSelection => 'മായ്ക്കുക';

  @override
  String get pdfImagesNothingSelected =>
      'സൂക്ഷിക്കാൻ ഒരു ചിത്രമെങ്കിലും തിരഞ്ഞെടുക്കുക';

  @override
  String get pdfImagesTruncated =>
      'ഈ PDF-ൽ വളരെയധികം ചിത്രങ്ങൾ ഉള്ളതിനാൽ ആദ്യത്തേവ മാത്രമേ വായിച്ചുള്ളൂ.';

  @override
  String get pdfImagesFallbackDirectory =>
      'ഗാലറിയിൽ എഴുതാൻ കഴിയാത്തതിനാൽ ആപ്പ് ഫോൾഡറിൽ സൂക്ഷിച്ചു';

  @override
  String pdfImageSize(int width, int height) {
    return '$width x $height';
  }

  @override
  String get pdfRefusedNotPdf => 'ഈ ഫയൽ ഒരു PDF അല്ല';

  @override
  String get pdfRefusedEncrypted =>
      'ഈ PDF പാസ്‌വേഡ് ഉപയോഗിച്ച് സംരക്ഷിച്ചതാണ്, അതിനാൽ തുറക്കാൻ കഴിയില്ല';

  @override
  String get pdfRefusedTooLarge => 'ഈ PDF തുറക്കാൻ കഴിയാത്തത്ര വലുതാണ്';

  @override
  String get pdfRefusedUnreadable => 'ഈ PDF വായിക്കാൻ കഴിഞ്ഞില്ല';

  @override
  String get pdfSkipUnsupportedFilter =>
      'ആപ്പിന് വായിക്കാൻ കഴിയാത്ത രീതിയിൽ കംപ്രസ് ചെയ്തത്';

  @override
  String get pdfSkipUnsupportedColor =>
      'ആപ്പിന് വായിക്കാൻ കഴിയാത്ത കളർ സ്പേസ് ഉപയോഗിക്കുന്നു';

  @override
  String get pdfSkipUnsupportedDepth =>
      'ആപ്പിന് വായിക്കാൻ കഴിയാത്ത കളർ ഡെപ്ത് ഉപയോഗിക്കുന്നു';

  @override
  String get pdfSkipTooLarge => 'എടുക്കാൻ കഴിയാത്തത്ര വലുത്';

  @override
  String get pdfSkipMalformed => 'ചിത്ര ഡാറ്റ അപൂർണ്ണമാണ്';

  @override
  String get pdfSkipDecodeFailed => 'ചിത്രം ഡീകംപ്രസ് ചെയ്യാൻ കഴിഞ്ഞില്ല';

  @override
  String get settingsAppearance => 'രൂപം';

  @override
  String get settingsLanguage => 'ഭാഷ';

  @override
  String get settingsSafety => 'സുരക്ഷ';

  @override
  String get settingsPrivacy => 'സംഭരണവും സ്വകാര്യതയും';

  @override
  String get settingsDeveloper => 'ഡെവലപ്പർ';

  @override
  String get languageSystem => 'സിസ്റ്റം ഭാഷ';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageMalayalam => 'മലയാളം';

  @override
  String get languageSubtitle =>
      'ആപ്പ് ഉടൻ ഭാഷ മാറ്റും. വീണ്ടും തുറക്കേണ്ടതില്ല.';

  @override
  String get gridDensity => 'ഗ്രിഡ് സാന്ദ്രത';

  @override
  String get gridDensitySubtitle =>
      'ടൈംലൈനിൽ ഒരു വരിയിൽ എത്ര ചിത്രങ്ങൾ വരണം. ഗ്രിഡിൽ നുള്ളിയും ഇത് മാറ്റാം.';

  @override
  String gridDensityValue(int count) {
    return 'ഒരു വരിയിൽ $count';
  }

  @override
  String get showFlashbacks => 'ഓർമ്മകൾ കാണിക്കുക';

  @override
  String get showFlashbacksSubtitle =>
      'കഴിഞ്ഞ വർഷങ്ങളിൽ ഇന്നത്തെ ദിവസം എടുത്ത ചിത്രങ്ങൾ, ടൈംലൈനിന്റെ മുകളിൽ.';

  @override
  String get confirmDestructive => 'മായ്ക്കുന്നതിനു മുമ്പ് ചോദിക്കുക';

  @override
  String get confirmDestructiveSubtitle =>
      'മായ്ക്കുന്നതിനോ മാറ്റിയെഴുതുന്നതിനോ മുമ്പ് ഒരിക്കൽ കൂടി ചോദിക്കും. ചില മുന്നറിയിപ്പുകൾ ഇത് ഓഫാക്കിയാലും എപ്പോഴും കാണിക്കും.';

  @override
  String get privacyNoServer => 'വിദൂര സെർവർ ഇല്ല';

  @override
  String get privacyNoServerBody =>
      'നിങ്ങളുടെ ചിത്രങ്ങളും ടാഗുകളും കുറിപ്പുകളും ഈ ഫോണിൽ തന്നെ തുടരും. ഒന്നും അപ്‌ലോഡ് ചെയ്യുന്നില്ല, അക്കൗണ്ട് ഇല്ല. നിങ്ങളുടെ സ്വന്തം വൈ-ഫൈയിലെ മറ്റൊരു ഫോണിലേക്ക് എത്താൻ ട്രാൻസ്ഫർ സ്ക്രീൻ മാത്രമാണ് ഇന്റർനെറ്റ് ഉപയോഗിക്കുന്നത്.';

  @override
  String get aboutOpen => 'ഈ ആപ്പിനെക്കുറിച്ച്';

  @override
  String get aboutOpenSubtitle => 'പതിപ്പ്, രചയിതാവ്, ലൈസൻസ്';

  @override
  String aboutBuild(String build) {
    return 'ബിൽഡ് $build';
  }

  @override
  String get aboutBuildDate => 'ബിൽഡ് തീയതി';

  @override
  String get aboutMailFailed => 'ആ വിലാസം തുറക്കാൻ ഈ ഫോണിൽ ആപ്പ് ഒന്നുമില്ല.';

  @override
  String get aboutAppName => 'ആപ്പ്';

  @override
  String get vaultSettingsOpenSubtitle => 'ലോക്ക് സമയം, പിൻ, ഷ്രെഡ്ഡിങ്';

  @override
  String get backupOpenSubtitle =>
      'പാസ്‌വേഡ് സംരക്ഷിത ബാക്കപ്പും പുനഃസ്ഥാപനവും';

  @override
  String get settingsResetTitle => 'ക്രമീകരണങ്ങൾ പഴയപോലാക്കുക';

  @override
  String get settingsResetBody =>
      'ഈ സ്ക്രീനിലെ എല്ലാ ക്രമീകരണങ്ങളും തുടക്കത്തിലേക്ക് മാറ്റും. ചിത്രങ്ങൾ, ടാഗുകൾ, ആൽബങ്ങൾ, വോൾട്ട് എന്നിവയ്ക്ക് മാറ്റമില്ല.';

  @override
  String get settingsResetDone => 'ക്രമീകരണങ്ങൾ തുടക്കത്തിലേക്ക് മാറ്റി.';

  @override
  String get settingsCancel => 'റദ്ദാക്കുക';

  @override
  String get settingsResetConfirm => 'പഴയപോലാക്കുക';

  @override
  String get settingsHelp => 'സഹായവും വഴികാട്ടിയും';

  @override
  String get settingsHelpSubtitle =>
      'ഓരോ സവിശേഷതയെക്കുറിച്ചുമുള്ള വഴികാട്ടികളും നുറുങ്ങുകളും ഓഫ്‌ലൈൻ ഉറപ്പുകളും പരിശോധിക്കുക';

  @override
  String get settingsAbout => 'വിവരണം';

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
  String get settingsDefaultApp => 'ഡിഫോൾട്ട് ഗാലറി ആപ്പ്';

  @override
  String get settingsDefaultAppSubtitle =>
      'ഫോട്ടോകളും വീഡിയോകളും കാണുന്നതിനുള്ള പ്രധാന ആപ്പായി സജ്ജീകരിക്കുക';

  @override
  String get defaultAppDialogTitle => 'ഡിഫോൾട്ട് ഗാലറിയാക്കുക';

  @override
  String get defaultAppDialogBody =>
      'ഈ ആപ്പ് ഡിഫോൾട്ട് ആക്കുന്നതിന്:\n\n1. ഫോണിലെ ഏതെങ്കിലും ഫോട്ടോയോ വീഡിയോയോ തുറക്കുക (ഉദാഹരണത്തിന് Files അല്ലെങ്കിൽ Downloads-ൽ നിന്ന്).\n2. SreerajP ഗാലറി തിരഞ്ഞെടുത്ത് \'Always\' നൽകുക.\n\nആൻഡ്രോയിഡ് സെറ്റിംഗ്സിലും ഇത് ക്രമീകരിക്കാം.';

  @override
  String get defaultAppOpenSettings => 'ആൻഡ്രോയിഡ് സെറ്റിംഗ്സ് തുറക്കുക';

  @override
  String get trashTitle => 'ചവറ്റുകുട്ട';

  @override
  String get trashEmpty => 'ചവറ്റുകുട്ട ശൂന്യമാണ്';

  @override
  String get trashEmptySubtitle =>
      'നിങ്ങൾ ഇല്ലാതാക്കുന്ന ഇനങ്ങൾ ചവറ്റുകുട്ട ശൂന്യമാക്കുന്നതുവരെ ഇവിടെ സൂക്ഷിക്കും.';

  @override
  String get trashEmptyAction => 'ചവറ്റുകുട്ട ശൂന്യമാക്കുക';

  @override
  String get trashEmptyConfirmTitle => 'ചവറ്റുകുട്ട ശൂന്യമാക്കണോ?';

  @override
  String get trashEmptyConfirmBody =>
      'ഇത് നിങ്ങളുടെ ഫോൺ സംഭരണത്തിൽ നിന്ന് എല്ലാ ഇനങ്ങളും ശാശ്വതമായി ഇല്ലാതാക്കും. ഈ പ്രവർത്തനം പഴയപടിയാക്കാൻ കഴിയില്ല.';

  @override
  String get trashDeletePermanentlyAction => 'ശാശ്വതമായി ഇല്ലാതാക്കുക';

  @override
  String get trashDeletePermanentlyConfirmTitle => 'ശാശ്വതമായി ഇല്ലാതാക്കണോ?';

  @override
  String get trashDeletePermanentlyConfirmBody =>
      'ഈ ഇനം നിങ്ങളുടെ ഫോൺ സംഭരണത്തിൽ നിന്ന് ശാശ്വതമായി ഇല്ലാതാക്കും. ഈ പ്രവർത്തനം പഴയപടിയാക്കാൻ കഴിയില്ല.';

  @override
  String get trashDeletedPermanentlySnackbar => 'ഇനം ശാശ്വതമായി ഇല്ലാതാക്കി';

  @override
  String get trashRestoreAction => 'പുനഃസ്ഥാപിക്കുക';

  @override
  String get trashRestoreAllAction => 'എല്ലാം പുനഃസ്ഥാപിക്കുക';

  @override
  String get trashRestoreAllConfirmBody =>
      'ചവറ്റുകുട്ടയിലെ എല്ലാ ഇനങ്ങളും നിങ്ങളുടെ ലൈബ്രറിയിലേക്ക് മടക്കും.';

  @override
  String get trashRestoredSnackbar => 'ചവറ്റുകുട്ടയിൽ നിന്ന് പുനഃസ്ഥാപിച്ചു';

  @override
  String get trashEmptiedSnackbar => 'ചവറ്റുകുട്ട ശൂന്യമാക്കി';

  @override
  String trashItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഇനങ്ങൾ ചവറ്റുകുട്ടയിൽ',
      one: '1 ഇനം ചവറ്റുകുട്ടയിൽ',
    );
    return '$_temp0';
  }

  @override
  String get settingsAppearanceSubtitle => 'തീം, ഗ്രിഡ് സാന്ദ്രത, ഓർമ്മകൾ';

  @override
  String get settingsLanguageSubtitle => 'സിസ്റ്റം, ഇംഗ്ലീഷ്, മലയാളം';

  @override
  String get settingsSafetySubtitle => 'ഇല്ലാതാക്കുന്നതിന് മുമ്പ് സ്ഥിരീകരണം';

  @override
  String get settingsDefaultAppCardSubtitle =>
      'ഡിഫോൾട്ട് ഗാലറി ആപ്പ് ആയി സജ്ജമാക്കുക';

  @override
  String get settingsPrivacySubtitle => 'വാൾട്ട്, ബാക്കപ്പ്, നെറ്റ്‌വർക്ക് നയം';

  @override
  String get settingsHelpCardSubtitle =>
      'എല്ലാ ഫീച്ചറുകൾക്കുമുള്ള ഗൈഡുകളും സ്വകാര്യത ഉറപ്പുകളും';

  @override
  String get settingsAboutSubtitle => 'പതിപ്പ്, രചയിതാവ്, ലൈസൻസ്';

  @override
  String get settingsDeveloperSubtitle => 'മീഡിയ സ്കാനർ ടൂളുകൾ';

  @override
  String get viewerTrashTooltip => 'ട്രാഷിലേക്ക് മാറ്റുക';

  @override
  String get viewerTrashConfirmTitle => 'ട്രാഷിലേക്ക് മാറ്റണോ?';

  @override
  String get viewerTrashConfirmBody =>
      'ഈ ഇനം ട്രാഷിലേക്ക് മാറ്റപ്പെടും. ട്രാഷ് ആൽബത്തിൽ നിന്ന് ഇത് എപ്പോൾ വേണമെങ്കിലും പുനഃസ്ഥാപിക്കാം.';

  @override
  String get viewerTrashSuccess => 'ട്രാഷിലേക്ക് മാറ്റി';

  @override
  String get viewerTrashUndo => 'പഴയപടിയാക്കുക';

  @override
  String get comparePhotosTitle => 'A/B ഫോട്ടോ താരതമ്യം';

  @override
  String get compareModeSplit => 'സ്പ്ലിറ്റ് കാഴ്ച';

  @override
  String get compareModeCurtain => 'സ്ലൈഡിംഗ് കർട്ടൻ';

  @override
  String get compareSplitHorizontal => 'വശങ്ങളിലായി';

  @override
  String get compareSplitVertical => 'മുകളിലും താഴെയുമായി';

  @override
  String get compareSyncLocked => 'പാനും സൂമും ലോക്ക് ചെയ്‌തു';

  @override
  String get compareSyncUnlocked => 'വ്യത്യസ്ത പാനും സൂമും';

  @override
  String get compareSwap => 'ഫോട്ടോകൾ പരസ്പരം മാറ്റുക';

  @override
  String get compareResetZoom => 'സൂം പുനഃക്രമീകരിക്കുക';

  @override
  String get compareDetails => 'വിശദാംശങ്ങൾ താരതമ്യം ചെയ്യുക';

  @override
  String get comparePickPhoto => 'ഫോട്ടോ മാറ്റുക';

  @override
  String get comparePhotoA => 'ഫോട്ടോ A';

  @override
  String get comparePhotoB => 'ഫോട്ടോ B';

  @override
  String get compareWithPrevious => 'മുമ്പത്തെ ഫോട്ടോയുമായി താരതമ്യം ചെയ്യുക';

  @override
  String get compareWithNext => 'അടുത്ത ഫോട്ടോയുമായി താരതമ്യം ചെയ്യുക';

  @override
  String get compareChooseFromGallery => 'ഗാലറിയിൽ നിന്ന് തിരഞ്ഞെടുക്കുക';

  @override
  String get compareAction => 'താരതമ്യം ചെയ്യുക';

  @override
  String get compareTooltip => 'ഫോട്ടോകൾ പരസ്പരം താരതമ്യം ചെയ്യുക';

  @override
  String get compareSelectSecondPhoto =>
      'താരതമ്യം ചെയ്യാൻ ഫോട്ടോ തിരഞ്ഞെടുക്കുക';

  @override
  String get compareDimensions => 'അളവുകൾ';

  @override
  String get compareFileSize => 'ഫയൽ വലുപ്പം';

  @override
  String get compareDateTaken => 'എടുത്ത തീയതി';

  @override
  String get compareCamera => 'ക്യാമറ';

  @override
  String get compareExposure => 'എക്സ്പോഷർ';

  @override
  String get compareIso => 'ISO';

  @override
  String get compareAperture => 'അപ്പർച്ചർ';

  @override
  String get compareShutterSpeed => 'ഷട്ടർ സ്പീഡ്';

  @override
  String get compareFocalLength => 'ഫോക്കൽ ലെങ്ത്';

  @override
  String get compareNoExif => 'EXIF വിവരങ്ങൾ ലഭ്യമല്ല';

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
  String get privacyScrubberTitle => 'മീഡിയ സ്വകാര്യതയും സ്ക്രബ്ബറും';

  @override
  String get privacyScrubberSubtitle =>
      'പങ്കുവെക്കുന്നതിന് മുമ്പ് സെൻസിറ്റീവ് EXIF മെറ്റാഡാറ്റ നീക്കം ചെയ്യുകയും GPS സ്ഥാനം മാറ്റുകയും ചെയ്യുക';

  @override
  String get privacyScrubberMenu => 'സ്വകാര്യതയും EXIF സ്ക്രബ്ബറും';

  @override
  String get privacyCardTitle => 'മീഡിയ സ്വകാര്യതയും EXIF വിവരങ്ങളും';

  @override
  String get privacyCardBody =>
      'ഫോട്ടോ പങ്കിടുന്നതിന് മുമ്പ് കൃത്യമായ GPS ലൊക്കേഷൻ, ക്യാമറ സീരിയൽ നമ്പറുകൾ എന്നിവ നീക്കം ചെയ്ത് സ്വകാര്യത സംരക്ഷിക്കുക.';

  @override
  String get privacyOpenScrubber => 'സ്വകാര്യതാ ക്രമീകരണങ്ങൾ തുറക്കുക';

  @override
  String get privacyTabStripper => 'EXIF നീക്കം ചെയ്യൽ';

  @override
  String get privacyTabGeofence => 'GPS ജിയോഫെൻസ് ഷിഫ്റ്റർ';

  @override
  String get privacyStripAndShareAction =>
      'ഒറ്റ ടാപ്പിൽ നീക്കം ചെയ്ത് പങ്കിടുക';

  @override
  String get privacySaveSanitizedAction =>
      'നീക്കം ചെയ്ത കോപ്പി ഗാലറിയിൽ സൂക്ഷിക്കുക';

  @override
  String get privacyGranularTitle => 'തിരഞ്ഞെടുത്ത മെറ്റാഡാറ്റ നീക്കം ചെയ്യൽ';

  @override
  String get privacyStripAll => 'എല്ലാം നീക്കം ചെയ്യുക';

  @override
  String get privacyCustom => 'ഇഷ്‌ടാനുസൃതം';

  @override
  String get privacyOptionGps => 'GPS ലൊക്കേഷനും ഉയരവും നീക്കം ചെയ്യുക';

  @override
  String get privacyOptionSerials =>
      'ക്യാമറ, ലെൻസ് സീരിയൽ നമ്പറുകൾ നീക്കം ചെയ്യുക';

  @override
  String get privacyOptionTimestamps =>
      'ഫോട്ടോ എടുത്ത തീയതിയും സമയവും നീക്കം ചെയ്യുക';

  @override
  String get privacyOptionAuthor =>
      'സോഫ്റ്റ്‌വെയർ, നിർമ്മാതാവിന്റെ വിവരങ്ങൾ നീക്കം ചെയ്യുക';

  @override
  String get privacyErrorReadingFile => 'ഫയൽ വായിക്കാൻ സാധിച്ചില്ല';

  @override
  String get privacyShareTitle => 'സുരക്ഷിതമായി മീഡിയ പങ്കിടുക';

  @override
  String get privacyShareFailed => 'പങ്കിടാൻ സാധിച്ചില്ല';

  @override
  String get privacyProcessError =>
      'മെറ്റാഡാറ്റ നീക്കം ചെയ്യുന്നതിൽ പിശക് സംഭവിച്ചു';

  @override
  String get privacySavedToGallery => 'സുരക്ഷിതമായ കോപ്പി ഗാലറിയിൽ സേവ് ചെയ്തു';

  @override
  String get privacySaveFailed => 'സേവ് ചെയ്യാൻ സാധിച്ചില്ല';

  @override
  String get privacyNoLocation => 'ഈ ഫോട്ടോയിൽ GPS വിവരങ്ങൾ കണ്ടെത്തിയില്ല';

  @override
  String get geofenceOffsetDistance => 'ഷിഫ്റ്റ് ചെയ്യേണ്ട ദൂരം';

  @override
  String get geofenceReroll => 'പുതിയ റാൻഡം ലൊക്കേഷൻ കണ്ടെത്തുക';

  @override
  String get geofenceRandomPreset => 'റാൻഡം (2–5 കി.മീ)';

  @override
  String geofenceShiftSummary(String summary) {
    return '$summary ലേക്ക് മാറ്റി';
  }

  @override
  String geofenceFuzzedCoordinates(String lat, String lon) {
    return '$lat, $lon ലേക്ക് മാറ്റി';
  }

  @override
  String get geofenceExplanation =>
      'കൃത്യമായ വീടിന്റെയോ താമസസ്ഥലത്തിന്റെയോ വിലാസം മറച്ചുവെച്ച് നഗരത്തിന്റെ പൊതുവായ ലൊക്കേഷൻ മാത്രം നിലനിർത്തുന്നു.';

  @override
  String get geofenceShareTitle => 'ലൊക്കേഷൻ മാറ്റിയ ഫോട്ടോ പങ്കിടുക';

  @override
  String get geofenceShareAction => 'ലൊക്കേഷൻ മാറ്റി പങ്കിടുക';

  @override
  String get geofenceSaveAction => 'ഗാലറിയിലേക്ക് സേവ് ചെയ്യുക';

  @override
  String get geofenceSavedToGallery =>
      'ലൊക്കേഷൻ മാറ്റിയ ഫോട്ടോ ഗാലറിയിൽ സേവ് ചെയ്തു';

  @override
  String get geofenceNoCoordinates => 'ലൊക്കേഷൻ കണ്ടെത്തിയില്ല';

  @override
  String get geofenceNoCoordinatesBody =>
      'ഈ ഫോട്ടോയിൽ മാറ്റാൻ തക്ക GPS വിവരങ്ങൾ അടങ്ങിയിട്ടില്ല.';

  @override
  String get privacyAuditSensitiveDetected => 'സ്വകാര്യ വിവരങ്ങൾ കണ്ടെത്തി';

  @override
  String get privacyAuditClean => 'സെൻസിറ്റീവ് വിവരങ്ങൾ ഒന്നുമില്ല';

  @override
  String privacyAuditSensitiveDetails(String gps, String camera) {
    return 'അടങ്ങിയിരിക്കുന്നത്: $gps $camera';
  }

  @override
  String get privacyAuditGps => 'GPS ലൊക്കേഷൻ';

  @override
  String get privacyAuditCamera => 'ഡിവൈസ് വിവരങ്ങൾ';

  @override
  String get privacyAuditCleanDetails =>
      'ഈ ഫയലിൽ ലൊക്കേഷനോ സീരിയൽ നമ്പറോ അടങ്ങിയിട്ടില്ല.';

  @override
  String get forensicInspectorTitle => 'ഫോറൻസിക് ലെൻസ് & സെൻസർ ഇൻസ്പെക്ടർ';

  @override
  String get forensicInspectorSubtitle =>
      'വിശദമായ ഒപ്റ്റിക്കൽ, ഹാർഡ്‌വെയർ സാങ്കേതിക വിവരങ്ങൾ';

  @override
  String get forensicInspectorButton => 'ലെൻസ് & സെൻസർ വിവരങ്ങൾ പരിശോധിക്കുക';

  @override
  String get forensicInspectorQuickHint =>
      'സെൻസർ ക്രോപ്പ് ഫാക്ടർ, 35mm തുല്യത, ഷട്ടർ കൗണ്ട്, എക്സ്പോഷർ ബയസ്';

  @override
  String get forensicNoData => 'ഫോറൻസിക് മെറ്റാഡാറ്റ ലഭ്യമല്ല.';

  @override
  String get forensicSectionSensorOptics => 'സെൻസർ & ഒപ്റ്റിക്കൽ സവിശേഷതകൾ';

  @override
  String get forensicSectionMechanicsColor =>
      'മെക്കാനിക്കൽ റിലീസുകളും കളർ സ്പേസും';

  @override
  String get forensicSectionHardwareIdentity =>
      'ഹാർഡ്‌വെയർ & ലെൻസ് തിരിച്ചറിയൽ';

  @override
  String get forensicSensorFormat => 'സെൻസർ ഫോർമാറ്റ്';

  @override
  String get forensicCropFactor => 'ക്രോപ്പ് ഫാക്ടർ';

  @override
  String get forensicFocal35mm => '35mm തുല്യത';

  @override
  String get forensicPhysicalFocalLength => 'യഥാർത്ഥ ഫോക്കൽ ലെങ്ത്';

  @override
  String get forensicHyperfocalDistance => 'ഹൈപ്പർഫോക്കൽ ദൂരം';

  @override
  String get forensicExposureBias => 'എക്സ്പോഷർ കോമ്പൻസേഷൻ (EV)';

  @override
  String get forensicShutterActuations => 'ഷട്ടർ ആക്ച്വേഷനുകൾ';

  @override
  String get forensicShutterNotReported => 'ഇലക്ട്രോണിക് ഷട്ടർ / ലഭ്യമല്ല';

  @override
  String get forensicColorProfile => 'കളർ സ്പേസ് പ്രൊഫൈൽ';

  @override
  String get forensicExposureProgram => 'എക്സ്പോഷർ പ്രോഗ്രാം';

  @override
  String get forensicMeteringMode => 'മീറ്ററിംഗ് മോഡ്';

  @override
  String get forensicSensingMethod => 'സെൻസിംഗ് രീതി';

  @override
  String get forensicSceneCaptureType => 'സീൻ ക്യാപ്‌ചർ തരം';

  @override
  String get forensicFlashStatus => 'ഫ്ലാഷ് നില';

  @override
  String get forensicCameraSerial => 'ക്യാമറ സീരിയൽ നമ്പർ';

  @override
  String get forensicLensModel => 'ലെൻസ് മോഡൽ';

  @override
  String get forensicLensSpecification => 'ലെൻസ് സ്പെസിഫിക്കേഷൻ';

  @override
  String get forensicLensSerial => 'ലെൻസ് സീരിയൽ നമ്പർ';

  @override
  String get forensicSerialNotEmbedded => 'രേഖപ്പെടുത്തിയിട്ടില്ല';
}
