// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Sanskrit (`sa`).
class AppLocalizationsSa extends AppLocalizations {
  AppLocalizationsSa([String locale = 'sa']) : super(locale);

  @override
  String get titleApp => 'दृश्य';

  @override
  String get labelDevBanner => 'विकाससंस्करणम्';

  @override
  String get titleSettings => 'विन्यासः';

  @override
  String get titleAbout => 'विषयपरिचयः';

  @override
  String get labelTheme => 'रूपविन्यासः';

  @override
  String get actionThemeSystem => 'तन्त्रपूर्वनिर्धारितम्';

  @override
  String get actionThemeLight => 'दीप्तम्';

  @override
  String get actionThemeDark => 'श्यामम्';

  @override
  String get actionThemeAmoled => 'अतिकृष्णम्';

  @override
  String get titleVersion => 'संस्करणम्';

  @override
  String get labelPermissionRequired => 'माध्यमप्रवेश्यम्';

  @override
  String get bodyPermissionRequired =>
      'चित्रप्रदर्शनाय प्रवेशो दीयताम्। न किञ्चिद् यन्त्राद् बहिर्याति।';

  @override
  String get labelGrantPermission => 'प्रवेशो दीयताम्';

  @override
  String get labelOpenSettings => 'विन्यासोद्घाटनम्';

  @override
  String get bodyPermissionPartial =>
      'केवलं चितानि माध्यमानि दृश्यन्ते। सर्वं द्रष्टुं सर्वेषां माध्यमानाम् अनुमतिः दीयताम्।';

  @override
  String get labelScanMedia => 'माध्यमान्वीक्षणम्';

  @override
  String get bodyScanningMedia => 'माध्यमानि अन्वीक्ष्यन्ते...';

  @override
  String bodyScanProgress(int scanned, int total) {
    return '$total मध्ये $scanned अन्वीक्षितानि';
  }

  @override
  String bodyScanComplete(int count) {
    return 'अन्वीक्षणं समाप्तम्: $count वस्तूनि सूचीकृतानि';
  }

  @override
  String get errorScanFailed => 'माध्यमान्वीक्षणम् असफलम्';

  @override
  String bodyIndexedItems(int count) {
    return 'सूचीकृतानि वस्तूनि: $count';
  }

  @override
  String get bodyNoMediaFound => 'न किमपि चित्रं दृश्यं वा प्राप्तम्';

  @override
  String get labelMediaUnavailable => 'पूर्वदर्शनमप्राप्यम्';

  @override
  String get labelTimelineToday => 'अद्य';

  @override
  String get labelTimelineYesterday => 'ह्यः';

  @override
  String get titleTimeline => 'कालक्रमः';

  @override
  String get bodyNoMediaInTimeline => 'भवतः चित्रशाला रिक्ता';

  @override
  String get bodyPullToScan =>
      'नूतनानि चित्राणि दृश्यानि च अन्वेष्टुम् अधः कृष्यताम्।';

  @override
  String get titleFlashback => 'अस्मिन् दिने';

  @override
  String get tooltipExpandFlashback => 'स्मृतीः दर्शय';

  @override
  String get tooltipCollapseFlashback => 'स्मृतीः गोपय';

  @override
  String get labelFlashbackOneYearAgo => 'एकवर्षात् पूर्वम्';

  @override
  String bodyFlashbackYearsAgo(int years) {
    return '$years वर्षेभ्यः पूर्वम्';
  }

  @override
  String bodyGridColumns(int count) {
    return 'प्रतिपङ्क्ति $count';
  }

  @override
  String get labelBadgeGif => 'GIF';

  @override
  String get labelBadgeRaw => 'RAW';

  @override
  String get labelBadgeHd => 'HD';

  @override
  String labelBadgeVideoDuration(String duration) {
    return 'दृश्यम्, $duration';
  }

  @override
  String get labelScrollToDate => 'दिनाङ्कगमनम्';

  @override
  String get tooltipViewerClose => 'पिधीयताम्';

  @override
  String get labelViewerRotateLeft => 'वामतः भ्राम्यताम्';

  @override
  String get labelViewerRotateRight => 'दक्षिणतः भ्राम्यताम्';

  @override
  String get labelViewerAddFavorite => 'प्रियेषु योज्यताम्';

  @override
  String get bodyViewerRemoveFavorite => 'प्रियेभ्यः अपनीयताम्';

  @override
  String get actionPlay => 'प्रवर्त्यताम्';

  @override
  String get actionPause => 'स्थग्यताम्';

  @override
  String get tooltipFrameForward => 'अग्रिमचित्रखण्डः';

  @override
  String get tooltipFrameBackward => 'पूर्वचित्रखण्डः';

  @override
  String get tooltipSkipForward => 'दशक्षणमग्रे';

  @override
  String get tooltipSkipBackward => 'दशक्षणं पृष्ठे';

  @override
  String get tooltipLoopPlayback => 'पुनरावृत्तिः';

  @override
  String get tooltipPlaybackSpeed => 'प्रवर्तनवेगः';

  @override
  String get bodyVideoCannotPlay => 'एतत् दृश्यं प्रवर्तयितुं न शक्यते।';

  @override
  String get bodyVideoFormatUnsupported =>
      'एतद् उपकरणम् इदं दृश्यप्रारूपं प्रवर्तयितुं न शक्नोति।';

  @override
  String get tooltipDetailsTitle => 'विवरणम्';

  @override
  String get labelDetailsFileName => 'सञ्चिकानाम';

  @override
  String get labelDetailsFormat => 'प्रारूपम्';

  @override
  String get labelDetailsSize => 'परिमाणम्';

  @override
  String get labelDetailsDimensions => 'आयामाः';

  @override
  String get labelDetailsDuration => 'कालावधिः';

  @override
  String get labelDetailsDateTaken => 'ग्रहणदिनाङ्कः';

  @override
  String get labelDetailsDateModified => 'अन्तिमपरिवर्तनम्';

  @override
  String get labelDetailsFolder => 'संपुटम्';

  @override
  String get labelDetailsCameraSection => 'छायाग्राहकाधिदत्तांशौ';

  @override
  String get bodyDetailsNoMetadata =>
      'अस्यां सञ्चिकायां छायाग्राहकाधिदत्तांशः न प्राप्तः।';

  @override
  String get labelDetailsCamera => 'छायाग्राहकः';

  @override
  String get labelDetailsLens => 'काचः';

  @override
  String get labelDetailsAperture => 'रन्ध्रम्';

  @override
  String get labelDetailsShutter => 'आवरणवेगः';

  @override
  String get labelDetailsIso => 'ISO';

  @override
  String get labelDetailsFocalLength => 'नाभ्यन्तरम्';

  @override
  String get labelDetailsFlash => 'प्रकाशस्फुरणम्';

  @override
  String get labelDetailsWhiteBalance => 'श्वेतसन्तुलनम्';

  @override
  String get labelDetailsMeteringMode => 'मापनविधिः';

  @override
  String get labelDetailsColorSpace => 'वर्णावकाशः';

  @override
  String get labelDetailsSoftware => 'तन्त्रांशः';

  @override
  String get labelDetailsLocation => 'स्थानम्';

  @override
  String get labelDetailsAltitude => 'उन्नतिः';

  @override
  String get titleEditor => 'सम्पादनम्';

  @override
  String get titleEditorOpen => 'सम्पाद्यताम्';

  @override
  String get labelEditorSave => 'प्रती रक्ष्यताम्';

  @override
  String get bodyEditorSaving => 'प्रतिलिपिः रक्ष्यते...';

  @override
  String bodyEditorSaved(String fileName) {
    return 'प्रतिलिपिः रक्षिता: $fileName';
  }

  @override
  String get errorEditorSaveFailed => 'प्रतिलिपिः रक्षितुमशक्या';

  @override
  String get bodyEditorOriginalKept => 'भवतः मूलचित्रं न परिवर्तितम्';

  @override
  String get bodyEditorCannotOpen => 'इदं चित्रं सम्पादयितुं न शक्यते';

  @override
  String get bodyEditorTooLarge =>
      'इदं चित्रम् अस्मिन् उपकरणे सम्पादनाय अतिबृहत्';

  @override
  String get errorEditorPreviewFailed => 'पूर्वदर्शनं रचयितुं न शक्तम्';

  @override
  String get tooltipEditorUndo => 'प्रत्यावर्त्यताम्';

  @override
  String get tooltipEditorRedo => 'पुनःक्रियताम्';

  @override
  String get tooltipEditorResetAll => 'सर्वं पूर्ववत्';

  @override
  String get titleEditorDiscard => 'विकाराः त्यज्यन्ताम्?';

  @override
  String get bodyEditorDiscardMessage =>
      'भवतः सम्पादनानि न रक्षितानि। इदानीं निर्गमने तानि नश्यन्ति।';

  @override
  String get actionEditorDiscard => 'त्यज्यताम्';

  @override
  String get actionEditorKeepEditing => 'सम्पादनमनुवर्त्यताम्';

  @override
  String get labelEditorToolCrop => 'कर्तनम्';

  @override
  String get labelEditorToolTune => 'समायोजनम्';

  @override
  String get labelEditorToolMasks => 'आवरणानि';

  @override
  String get labelEditorToolFilters => 'परिशोधकाः';

  @override
  String get labelEditorToolMarkup => 'अङ्कनम्';

  @override
  String get labelEditorToolRedact => 'गोपनम्';

  @override
  String get labelEditorToolWatermark => 'जलचिह्नम्';

  @override
  String get labelCropAspectFree => 'मुक्तम्';

  @override
  String get labelCropAspectOriginal => 'मूलम्';

  @override
  String get labelCropAspectSquare => 'चतुरस्रम्';

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
  String get tooltipCropRotateLeft => 'वामतः भ्राम्यताम्';

  @override
  String get tooltipCropRotateRight => 'दक्षिणतः भ्राम्यताम्';

  @override
  String get tooltipCropFlipHorizontal => 'पार्श्वप्रतिबिम्बनम्';

  @override
  String get tooltipCropFlipVertical => 'ऊर्ध्वाधःप्रतिबिम्बनम्';

  @override
  String get labelCropStraighten => 'ऋजूकरणम्';

  @override
  String get labelCropPerspectiveVertical => 'ऊर्ध्वनतिः';

  @override
  String get labelCropPerspectiveHorizontal => 'तिर्यङ्नतिः';

  @override
  String get actionCropReset => 'कर्तनपुनःस्थापनम्';

  @override
  String get labelToneExposure => 'प्रकाशनम्';

  @override
  String get labelToneContrast => 'वैषम्यम्';

  @override
  String get labelToneHighlights => 'उज्ज्वलांशाः';

  @override
  String get labelToneShadows => 'छायाः';

  @override
  String get labelToneTemperature => 'ऊष्मा';

  @override
  String get labelToneTint => 'वर्णच्छाया';

  @override
  String get labelToneVibrance => 'स्फूर्तिः';

  @override
  String get labelToneSaturation => 'वर्णगाढता';

  @override
  String get actionToneReset => 'समायोजनपुनःस्थापनम्';

  @override
  String get labelToneCurves => 'वक्ररेखाः';

  @override
  String get labelCurveChannelRgb => 'सर्वे';

  @override
  String get labelCurveChannelRed => 'रक्तः';

  @override
  String get labelCurveChannelGreen => 'हरितः';

  @override
  String get labelCurveChannelBlue => 'नीलः';

  @override
  String get actionCurveReset => 'वक्रपुनःस्थापनम्';

  @override
  String get helpCurveAddHint =>
      'बिन्दुं योजयितुं स्पृश्यताम्, अपनेतुं दीर्घं निपीड्यताम्';

  @override
  String get labelMaskShapeLinear => 'रेखीयम्';

  @override
  String get labelMaskShapeRadial => 'वृत्तीयम्';

  @override
  String get labelMaskFeather => 'मृदुप्रान्तः';

  @override
  String get labelMaskInvert => 'विपर्यासः';

  @override
  String get labelMaskBlur => 'अस्पष्टीकरणम्';

  @override
  String get tooltipMaskAddLinear => 'रेखीयावरणं योज्यताम्';

  @override
  String get tooltipMaskAddRadial => 'वृत्तावरणं योज्यताम्';

  @override
  String get emptyMask => 'आवरणं योजयितुं + स्पृश्यताम्';

  @override
  String get titleHsl => 'HSL वर्णसमायोजकः';

  @override
  String get labelHslHue => 'वर्णः';

  @override
  String get labelHslSaturation => 'वर्णगाढता';

  @override
  String get labelHslLuminance => 'दीप्तिः';

  @override
  String get actionHslReset => 'HSL-पुनःस्थापनम्';

  @override
  String get labelHslRangeRed => 'रक्तः';

  @override
  String get labelHslRangeOrange => 'नारङ्गः';

  @override
  String get labelHslRangeYellow => 'पीतः';

  @override
  String get labelHslRangeGreen => 'हरितः';

  @override
  String get labelHslRangeCyan => 'आकाशनीलः';

  @override
  String get labelHslRangeBlue => 'नीलः';

  @override
  String get labelHslRangePurple => 'धूम्रः';

  @override
  String get labelHslRangeMagenta => 'पाटलः';

  @override
  String get labelFilterNone => 'मूलम्';

  @override
  String get labelFilterMono => 'एकवर्णम्';

  @override
  String get labelFilterSepia => 'पिङ्गलम्';

  @override
  String get labelFilterVintage => 'पुरातनम्';

  @override
  String get labelFilterVivid => 'उज्ज्वलम्';

  @override
  String get labelFilterCool => 'शीतलम्';

  @override
  String get labelFilterWarm => 'उष्णम्';

  @override
  String get labelFilterFade => 'म्लानम्';

  @override
  String get labelFilterIntensity => 'तीव्रता';

  @override
  String get labelMarkupFreehand => 'आलेखनम्';

  @override
  String get labelMarkupRectangle => 'आयतम्';

  @override
  String get labelMarkupEllipse => 'वृत्तम्';

  @override
  String get labelMarkupLine => 'रेखा';

  @override
  String get labelMarkupArrow => 'बाणः';

  @override
  String get labelMarkupText => 'पाठः';

  @override
  String get labelMarkupColor => 'वर्णः';

  @override
  String get labelMarkupThickness => 'स्थूलता';

  @override
  String get titleMarkupFilled => 'आकृतिः पूर्यताम्';

  @override
  String get actionMarkupUndoLayer => 'अन्तिमम् अपनीयताम्';

  @override
  String get titleMarkupText => 'पाठः योज्यताम्';

  @override
  String get helpMarkupTextHint => 'भवतः पाठः लिख्यताम्';

  @override
  String get actionMarkupTextAdd => 'योज्यताम्';

  @override
  String get helpMarkupHint => 'आलेखितुं चित्रे कृष्यताम्';

  @override
  String get labelRedactBlur => 'अस्पष्टीकरणम्';

  @override
  String get labelRedactPixelate => 'खण्डीकरणम्';

  @override
  String get labelRedactBlackout => 'कृष्णावरणम्';

  @override
  String get labelRedactStrength => 'तीव्रता';

  @override
  String get helpRedactHint => 'यत् गोपनीयं तस्य उपरि कृष्यताम्';

  @override
  String get actionRedactRemoveLast => 'अन्तिमम् अपनीयताम्';

  @override
  String bodyRedactCount(int count) {
    return '$count क्षेत्राणि गोपितानि';
  }

  @override
  String get labelWatermarkNone => 'किमपि न';

  @override
  String get labelWatermarkText => 'पाठः';

  @override
  String get labelWatermarkTimestamp => 'दिनाङ्कः समयः च';

  @override
  String get labelWatermarkLogo => 'लाञ्छनम्';

  @override
  String get helpWatermarkTextHint => 'जलचिह्नपाठः';

  @override
  String get labelWatermarkPosition => 'विकाराः त्यज्यन्ताम्?';

  @override
  String get labelWatermarkOpacity => 'अपारदर्शिता';

  @override
  String get labelWatermarkSize => 'परिमाणम्';

  @override
  String get labelWatermarkMargin => 'सम्पादनमनुवर्त्यताम्';

  @override
  String get actionWatermarkPickLogo => 'लाञ्छनं चीयताम्';

  @override
  String get bodyWatermarkNoLogo => 'अद्यापि लाञ्छनं न चितम्';

  @override
  String get labelPositionTopLeft => 'उपरि वामे';

  @override
  String get labelPositionTopCenter => 'उपरि मध्ये';

  @override
  String get labelPositionTopRight => 'उपरि दक्षिणे';

  @override
  String get labelPositionCenterLeft => 'मध्ये वामे';

  @override
  String get labelPositionCenter => 'मध्ये';

  @override
  String get labelPositionCenterRight => 'मध्ये दक्षिणे';

  @override
  String get labelPositionBottomLeft => 'अधः वामे';

  @override
  String get labelPositionBottomCenter => 'अधः मध्ये';

  @override
  String get labelPositionBottomRight => 'अधः दक्षिणे';

  @override
  String get titleConvertOpen => 'रूपान्तर्यताम्';

  @override
  String get titleConvert => 'रूपान्तरणपरिमाणे';

  @override
  String get bodyConvertCannotOpen => 'इयं सञ्चिका रूपान्तरयितुं न शक्यते';

  @override
  String get bodyConvertTooLarge => 'इयं सञ्चिका रूपान्तरणाय अतिबृहती';

  @override
  String get bodyConvertUnreadable => 'इदं चित्रं पठितुमशक्यम्';

  @override
  String get labelConvertFormat => 'प्रारूपम्';

  @override
  String get labelConvertQuality => 'गुणवत्ता';

  @override
  String get labelConvertResize => 'परिमाणम्';

  @override
  String get labelConvertResizeNone => 'मूलम्';

  @override
  String get labelConvertResizeLongestSide => 'दीर्घतमा भुजा';

  @override
  String get labelConvertResizePercent => 'प्रतिशतम्';

  @override
  String get labelConvertResizeExact => 'विस्तारः उच्चता च';

  @override
  String get titleConvertKeepAspect => 'आकारः रक्ष्यताम्';

  @override
  String get labelConvertWidth => 'विस्तारः';

  @override
  String get labelConvertHeight => 'उच्चता';

  @override
  String get labelConvertLongestSide => 'दीर्घभुजा (px)';

  @override
  String get labelConvertPercent => 'मूलस्य प्रतिशतम्';

  @override
  String get titleConvertStripMetadata => 'छायाग्राहकविवरणलोपः';

  @override
  String get helpConvertStripMetadataHint =>
      'स्थानं छायाग्राहकविन्यासः च प्रतिलिप्यां न योज्यन्ते';

  @override
  String get labelConvertOriginalSize => 'मूलम्';

  @override
  String get labelConvertNewSize => 'नूतना प्रतिलिपिः';

  @override
  String get bodyConvertEstimating => 'परिमाणं गण्यते';

  @override
  String get bodyConvertNoEstimate =>
      'अस्याः सञ्चिकायाः परिमाणं गणयितुं न शक्यते';

  @override
  String get bodyConvertLargerWarning => 'प्रतिलिपिः मूलात् बृहत्तरा';

  @override
  String get labelConvertSave => 'प्रती रक्ष्यताम्';

  @override
  String get labelConvertSaving => 'रक्ष्यते';

  @override
  String get errorConvertFailed => 'प्रतिलिपिः रक्षितुमशक्या';

  @override
  String get bodyConvertOriginalKept => 'भवतः मूलसञ्चिका न परिवर्तिता';

  @override
  String get tooltipPdfOpen => 'PDF-निर्यापणम्';

  @override
  String get titlePdfExport => 'PDF रूपेण निर्यापणम्';

  @override
  String get labelPdfChoosePhotos => 'चित्राणि चीयन्ताम्';

  @override
  String get bodyPdfNoSelection => 'न्यूनातिन्यूनम् एकं चित्रं चीयताम्';

  @override
  String get bodyPdfNoPhotos => 'चयनाय चित्राणि न सन्ति';

  @override
  String get labelPdfPageSize => 'पृष्ठपरिमाणम्';

  @override
  String get labelPdfPageA4 => 'A4';

  @override
  String get labelPdfPageLetter => 'लेटर्';

  @override
  String get labelPdfPageFitImage => 'चित्रानुसारम्';

  @override
  String get labelPdfOrientation => 'दिशा';

  @override
  String get labelPdfOrientationPortrait => 'ऊर्ध्वम्';

  @override
  String get labelPdfOrientationLandscape => 'तिर्यक्';

  @override
  String get labelPdfOrientationAuto => 'चित्रम् अनुसरतु';

  @override
  String get labelPdfFit => 'स्थापनम्';

  @override
  String get labelPdfFitContain => 'सम्पूर्णचित्रम्';

  @override
  String get labelPdfFitFill => 'पृष्ठपूरणम्';

  @override
  String get labelPdfMargin => 'सीमा';

  @override
  String get labelPdfMarginNone => 'किमपि न';

  @override
  String get labelPdfMarginSmall => 'लघु';

  @override
  String get labelPdfMarginMedium => 'मध्यमम्';

  @override
  String get labelPdfMarginLarge => 'बृहत्';

  @override
  String get labelPdfQuality => 'चित्रगुणवत्ता';

  @override
  String get actionPdfExport => 'PDF सृज्यताम्';

  @override
  String get labelPdfExporting => 'PDF सृज्यते';

  @override
  String get errorPdfFailed => 'PDF स्रष्टुं नाशक्यत';

  @override
  String get titleVideoToolsOpen => 'दृश्यसाधनानि';

  @override
  String get titleVideoTools => 'दृश्यसाधनानि';

  @override
  String get bodyVideoToolsUnavailable => 'इदं दृश्यं पठितुं न शक्तम्';

  @override
  String get tabVideoTabFrame => 'चित्रखण्डः';

  @override
  String get tabVideoTabGif => 'GIF';

  @override
  String get tabVideoTabTrim => 'कर्तनम्';

  @override
  String get labelFramePosition => 'दृश्ये स्थानम्';

  @override
  String get labelFrameFormat => 'एवं रक्ष्यताम्';

  @override
  String get actionFrameSave => 'चित्रखण्डो रक्ष्यताम्';

  @override
  String get bodyFrameUnavailable => 'अत्र चित्रखण्डः पठितुं न शक्तः';

  @override
  String get labelGifFrameRate => 'प्रतिक्षणचित्रखण्डाः';

  @override
  String get labelGifSize => 'परिमाणम्';

  @override
  String get titleGifLoopLabel => 'आवर्तितप्रवर्तनम्';

  @override
  String get bodyGifCapped => 'सञ्चिका लघ्वी स्यात् इति GIF ह्रस्वीकृतम्';

  @override
  String get actionGifExport => 'GIF सृज्यताम्';

  @override
  String get labelGifExporting => 'GIF सृज्यते';

  @override
  String get labelTrimStart => 'आरम्भः';

  @override
  String get labelTrimEnd => 'अन्तः';

  @override
  String get labelTrimLength => 'दैर्घ्यम्';

  @override
  String get actionTrim => 'कर्तितदृश्यरक्षणम्';

  @override
  String get bodyTrimLosslessNote =>
      'किमपि पुनः न सङ्केत्यते, अतः गुणवत्ता न नश्यति। कर्तनं समीपस्थात् मुख्यचित्रखण्डात् किञ्चित् पूर्वम् आरभेत।';

  @override
  String get bodyTrimTooShort => 'चितः भागः अतिह्रस्वः';

  @override
  String get labelVideoWorking => 'प्रक्रिया प्रचलति';

  @override
  String get errorVideoJobFailed => 'तत् समापयितुं न शक्तम्';

  @override
  String bodyConvertPixelSize(int width, int height) {
    return '$width × $height चित्राणवः';
  }

  @override
  String bodyConvertSmallerBy(int percent) {
    return '$percent प्रतिशतं लघुतरम्';
  }

  @override
  String bodyConvertSavedAs(String name) {
    return '$name इति रक्षितम्';
  }

  @override
  String bodyPdfSelectedCount(int count) {
    return '$count चितानि';
  }

  @override
  String bodyPdfMaxPagesReached(int count) {
    return 'एकस्मिन् PDF मध्ये केवलं $count चित्राणि मान्ति';
  }

  @override
  String bodyPdfExportedAs(String name, int pages) {
    return '$pages पृष्ठैः सह $name रक्षितम्';
  }

  @override
  String bodyPdfSkippedCount(int count) {
    return '$count चित्राणि पठितुमशक्यानि, अतः त्यक्तानि';
  }

  @override
  String bodyGifFrameCount(int count) {
    return '$count चित्रखण्डाः';
  }

  @override
  String bodyVideoJobSavedAs(String name) {
    return '$name इति रक्षितम्';
  }

  @override
  String get titleSearch => 'अन्वेषणम्';

  @override
  String get tooltipSearchOpen => 'अन्विष्यताम्';

  @override
  String get helpSearchHint =>
      'नामानि, चिह्नानि, टिप्पण्यः, स्थानानि अन्विष्यन्ताम्';

  @override
  String get tooltipSearchClear => 'रिक्तीक्रियताम्';

  @override
  String get tooltipSearchFilters => 'परिशोधकाः';

  @override
  String get titleSearchStart => 'सङ्ग्रहान्वेषणम्';

  @override
  String get bodySearchStart =>
      'नाम, चिह्नम्, टिप्पणी, छायाग्राहकः, स्थानम् इत्येतेषु अन्विष्यताम्। अन्वेषणं सङ्कोचयितुं शब्दस्य आदौ tag:, type:, place:, camera:, before: after: वा लिख्यताम्।';

  @override
  String get titleSearchNoResults => 'न किमपि मिलितम्';

  @override
  String get bodySearchNoResults =>
      'अल्पतरैः शब्दैः प्रयत्यताम्, परिशोधकान् वा परीक्ष्यताम्।';

  @override
  String get errorSearchFailed => 'अन्वेषणं प्रवर्तयितुं न शक्तम्';

  @override
  String get titleSearchRecent => 'सद्योऽन्वेषणानि';

  @override
  String get actionSearchRecentClear => 'सर्वं मार्ज्यताम्';

  @override
  String get tooltipSearchRecentRemove => 'अन्वेषणं विस्मर्यताम्';

  @override
  String bodySearchResultCount(int count) {
    return '$count फलानि';
  }

  @override
  String get bodySearchMatchedInName => 'सञ्चिकानाम्नि मिलितम्';

  @override
  String get labelSearchMatchedInTags => 'चिह्ने मिलितम्';

  @override
  String get labelSearchMatchedInNotes => 'टिप्पण्यां मिलितम्';

  @override
  String get labelSearchMatchedInPlace => 'स्थाने मिलितम्';

  @override
  String get bodySearchMatchedInDetails => 'चित्रविवरणे मिलितम्';

  @override
  String get tooltipFilterTitle => 'परिशोधकाः';

  @override
  String get labelFilterMediaType => 'प्रकारः';

  @override
  String get labelFilterTypeImage => 'चित्राणि';

  @override
  String get labelFilterTypeVideo => 'दृश्यानि';

  @override
  String get labelFilterTypeGif => 'GIF चित्राणि';

  @override
  String get labelFilterTypeRaw => 'RAW';

  @override
  String get labelFilterTypeSvg => 'SVG';

  @override
  String get titleFilterFavoritesOnly => 'केवलं प्रियाणि';

  @override
  String get titleFilterHasLocation => 'स्थानयुक्तम्';

  @override
  String get labelFilterDateRange => 'दिनाङ्कपरिधिः';

  @override
  String get labelFilterDateAny => 'कोऽपि दिनाङ्कः';

  @override
  String get actionFilterDateChoose => 'दिनाङ्काः चीयन्ताम्';

  @override
  String get actionFilterDateClear => 'दिनाङ्कमार्जनम्';

  @override
  String get labelFilterTags => 'चिह्नानि';

  @override
  String get actionFilterTagModeAll => 'सर्वाणि सन्ति';

  @override
  String get actionFilterTagModeAny => 'किमपि अस्ति';

  @override
  String get labelFilterNoTags => 'चिह्नानि न सन्ति';

  @override
  String get actionFilterReset => 'पुनःसज्जीक्रियताम्';

  @override
  String get actionFilterApply => 'प्रयुज्यताम्';

  @override
  String get titleTags => 'चिह्नानि';

  @override
  String get titleTagsOpen => 'चिह्नानि';

  @override
  String get titleTagsEmpty => 'चिह्नानि न सन्ति';

  @override
  String get bodyTagsEmpty =>
      'स्वरीत्या चित्राणि वर्गीकर्तुं चिह्नं सृज्यताम्।';

  @override
  String get actionTagNew => 'नूतनं चिह्नम्';

  @override
  String get tooltipTagEditTitle => 'चिह्नसम्पादनम्';

  @override
  String get labelTagName => 'चिह्ननाम';

  @override
  String get labelTagColor => 'वर्णः';

  @override
  String get actionTagSave => 'रक्ष्यताम्';

  @override
  String get actionTagCancel => 'निरस्यताम्';

  @override
  String get tooltipTagDelete => 'लुप्यताम्';

  @override
  String get titleTagDelete => 'चिह्नं लुप्यताम् वा?';

  @override
  String get bodyTagDelete =>
      'यस्मिन् यस्मिन् चित्रे इदं चिह्नम् अस्ति, तस्मात् तस्मात् अपनीयते। किमपि चित्रं न लुप्यते।';

  @override
  String descTagItemCount(int count) {
    return '$count वस्तूनि';
  }

  @override
  String get emptyTagError => 'चिह्नस्य नाम आवश्यकम्';

  @override
  String get bodyTagErrorTooLong => 'तत् नाम अतिदीर्घम्';

  @override
  String get bodyTagErrorDuplicate => 'तत् चिह्नं पूर्वमेव अस्ति';

  @override
  String get errorTagErrorFailed => 'चिह्नं रक्षितुं न शक्तम्';

  @override
  String get titleTagSheet => 'वस्तुचिह्नानि';

  @override
  String get helpTagSheetNewHint => 'नूतनं चिह्नं योज्यताम्';

  @override
  String get actionTagSheetAdd => 'योज्यताम्';

  @override
  String get actionTagSheetDone => 'समाप्तम्';

  @override
  String get titleTagSheetOpen => 'चिह्नानि';

  @override
  String get titleCleaner => 'द्विरुक्तशोधकः';

  @override
  String get titleCleanerOpen => 'द्विरुक्तशोधकः';

  @override
  String get labelCleanerStart => 'द्विरुक्तान्वेषणम्';

  @override
  String get actionCleanerStop => 'विरम्यताम्';

  @override
  String get labelCleanerRescan => 'पुनः अन्वीक्ष्यताम्';

  @override
  String get titleCleanerIdle => 'द्विरुक्तान्वेषणम्';

  @override
  String get bodyCleanerIdle =>
      'प्रत्येकं सञ्चिका एकवारं पठ्यते, यत् प्राप्तं तत् स्मर्यते, अतः पश्चात् पुनरन्वीक्षणं शीघ्रम्।';

  @override
  String bodyCleanerScanning(int processed, int total) {
    return '$total मध्ये $processed परीक्षितानि';
  }

  @override
  String get labelCleanerGrouping => 'प्रतीवर्गीकरणम्';

  @override
  String get labelCleanerCancelled => 'अन्वीक्षणं विरतम्';

  @override
  String get errorCleanerFailed => 'अन्वीक्षणं समापयितुं न शक्तम्';

  @override
  String get titleCleanerNone => 'द्विरुक्तं न प्राप्तम्';

  @override
  String get bodyCleanerNone =>
      'भवतः माध्यमकोशे किमपि अन्यस्य प्रतिलिपिः इव न दृश्यते।';

  @override
  String bodyCleanerGroupsFound(int count) {
    return 'प्रतिलिपीनां $count वर्गाः';
  }

  @override
  String bodyCleanerReclaimable(String size) {
    return 'प्रायः $size मोचयितुं शक्यते';
  }

  @override
  String bodyCleanerFailures(int count) {
    return '$count सञ्चिकाः पठितुमशक्याः, अतः त्यक्ताः';
  }

  @override
  String get labelCleanerKindExact => 'समानसञ्चिकाः';

  @override
  String get labelCleanerKindSimilar => 'सदृशरूपम्';

  @override
  String bodyCleanerMemberCount(int count) {
    return '$count प्रतिलिपयः';
  }

  @override
  String get actionCleanerCompare => 'तुल्यताम्';

  @override
  String get titleCompare => 'प्रतिलिपितुलना';

  @override
  String get bodyCompareGroupGone => 'अयं वर्गः पूर्वमेव निर्णीतः';

  @override
  String get actionCompareKeepThis => 'इयं रक्ष्यताम्';

  @override
  String get labelCompareBestBadge => 'सूचितम्';

  @override
  String bodyCompareKeepAndTrash(int count) {
    return '1 रक्ष्यताम्, $count अवकरपात्रं नीयन्ताम्';
  }

  @override
  String get bodyCompareTrashNotice =>
      'किमपि न मार्ज्यते। अन्याः प्रतिलिपयः अवकरपात्रं गच्छन्ति, पुनः आनेतुं च शक्यन्ते।';

  @override
  String titleCompareConfirm(int count) {
    return '$count प्रतयोऽवकरं नीयन्ताम्?';
  }

  @override
  String get bodyCompareConfirm =>
      'भवता रक्षिता प्रतिलिपिः एव चित्रशालायां तिष्ठति। सञ्चिकाः उपकरणे एव तिष्ठन्ति, पुनः आनेतुं च शक्यन्ते।';

  @override
  String get actionCompareConfirm => 'अवकरपात्रं नीयताम्';

  @override
  String get actionCompareCancel => 'निरस्यताम्';

  @override
  String bodyCompareMoved(int count) {
    return '$count प्रतिलिपयः अवकरपात्रं नीताः';
  }

  @override
  String get errorCompareFailed => 'प्रतिलिपयः नेतुं न शक्ताः';

  @override
  String get labelCompareFieldSize => 'परिमाणम्';

  @override
  String get labelCompareFieldPixels => 'चित्राणवः';

  @override
  String get labelCompareFieldDate => 'दिनाङ्कः';

  @override
  String get labelCompareFieldCamera => 'छायाग्राहकः';

  @override
  String get labelCompareUnknown => 'अज्ञातम्';

  @override
  String get titleAlbums => 'सङ्कलनानि';

  @override
  String get labelAlbumsSectionMine => 'मम सङ्कलनानि';

  @override
  String get labelAlbumsSectionSmart => 'स्वचालितसङ्कलनानि';

  @override
  String get labelAlbumsSectionFolders => 'उपकरणसंपुटानि';

  @override
  String get titleAlbumsEmpty => 'सङ्कलनानि न सन्ति';

  @override
  String get bodyAlbumsEmpty =>
      'स्वरीत्या चित्राणि दृश्यानि च वर्गीकर्तुं सङ्कलनं सृज्यताम्। सञ्चिकाः यथास्थानं तिष्ठन्ति।';

  @override
  String get emptyAlbumsFolders => 'न किमपि संपुटं प्राप्तम्';

  @override
  String get errorAlbumsLoadFailed => 'सङ्कलनानि आनेतुं न शक्तानि';

  @override
  String descAlbumItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count वस्तूनि',
      one: '1 वस्तु',
      zero: 'रिक्तम्',
    );
    return '$_temp0';
  }

  @override
  String get labelSmartAlbumFavorites => 'प्रियाणि';

  @override
  String get labelSmartAlbumVideos => 'दृश्यानि';

  @override
  String get labelSmartAlbumGifs => 'चलचित्राणि GIF च';

  @override
  String get labelSmartAlbumRaw => 'RAW चित्राणि';

  @override
  String get labelSmartAlbumPanoramas => 'विहङ्गमचित्राणि';

  @override
  String get labelSmartAlbumRecent => 'सद्यः योजितानि';

  @override
  String get labelSmartAlbumTrash => 'अवकरपात्रम्';

  @override
  String get actionAlbumNew => 'नूतनं सङ्कलनम्';

  @override
  String get titleAlbumCreate => 'नूतनं सङ्कलनम्';

  @override
  String get titleAlbumRenameTitle => 'सङ्कलनपुनर्नामकरणम्';

  @override
  String get labelAlbumName => 'सङ्कलननाम';

  @override
  String get helpAlbumNameHint => 'विरामयात्रा 2026';

  @override
  String get labelAlbumSave => 'रक्ष्यताम्';

  @override
  String get actionAlbumCancel => 'निरस्यताम्';

  @override
  String get titleAlbumRename => 'पुनर्नामकरणम्';

  @override
  String get titleAlbumDelete => 'सङ्कलनं लुप्यताम्';

  @override
  String get titleAlbumChooseCover => 'आवरणचित्रं चीयताम्';

  @override
  String get titleAlbumReorder => 'क्रमः परिवर्त्यताम्';

  @override
  String get titleAlbumRemoveMedia => 'सङ्कलनात् अपनीयताम्';

  @override
  String get titleAlbumPin => 'उपरि स्थाप्यताम्';

  @override
  String get emptyAlbumError => 'सङ्कलनस्य नाम आवश्यकम्';

  @override
  String get bodyAlbumErrorTooLong => 'तत् नाम अतिदीर्घम्';

  @override
  String get bodyAlbumErrorDuplicate => 'तेन नाम्ना सङ्कलनं पूर्वमेव अस्ति';

  @override
  String get errorAlbumErrorFailed => 'तत् परिवर्तनं रक्षितुं न शक्तम्';

  @override
  String titleAlbumDeleteConfirm(String name) {
    return '\"$name\" लुप्यताम् वा?';
  }

  @override
  String get bodyAlbumDeleteConfirm =>
      'केवलं सङ्कलनं लुप्यते। प्रत्येकं चित्रं दृश्यं च उपकरणे यथास्थानं तिष्ठति।';

  @override
  String get actionAlbumDeleteConfirm => 'सङ्कलनं लुप्यताम्';

  @override
  String get bodyAlbumDeleted => 'सङ्कलनं लुप्तम्';

  @override
  String get bodyAlbumRemovedFromAlbum => 'सङ्कलनात् अपनीतम्';

  @override
  String get bodyAlbumCoverSet => 'आवरणचित्रम् अद्यतनीकृतम्';

  @override
  String get bodyAlbumOrderSaved => 'नूतनः क्रमः रक्षितः';

  @override
  String get titleAlbumEmpty => 'इदं सङ्कलनं रिक्तम्';

  @override
  String get bodyAlbumEmpty =>
      'चित्रशालातः चित्राणि दृश्यानि च योज्यन्ताम्। तानि न स्थानान्तरीक्रियन्ते न च प्रतिलिख्यन्ते।';

  @override
  String get bodyAlbumGone => 'इदं सङ्कलनम् इदानीं न विद्यते';

  @override
  String get titleAlbumReorderTitle => 'क्रमपरिवर्तनम्';

  @override
  String get helpAlbumReorderHint =>
      'वस्तु चालयितुं कृष्यताम्। \'रक्ष्यताम्\' स्पृष्टे नूतनः क्रमः रक्ष्यते।';

  @override
  String get actionAlbumReorderSave => 'क्रमः रक्ष्यताम्';

  @override
  String get titleAlbumCover => 'आवरणचित्रचयनम्';

  @override
  String get actionAlbumCoverClear => 'नवीनतमं प्रयुज्यताम्';

  @override
  String get titleAlbumPicker => 'सङ्कलने योज्यताम्';

  @override
  String get emptyAlbumPicker => 'भवतः अद्यापि सङ्कलनानि न सन्ति';

  @override
  String get actionAlbumPickerCreate => 'नूतनं सङ्कलनम्';

  @override
  String get actionAlbumPickerDone => 'समाप्तम्';

  @override
  String get bodyAlbumPickerSaved => 'सङ्कलनानि अद्यतनीकृतानि';

  @override
  String get titleFolderEmpty => 'इदं संपुटं रिक्तम्';

  @override
  String get titleSmartAlbumEmpty => 'अत्र किमपि नास्ति';

  @override
  String get bodySmartAlbumUnknown => 'तत् सङ्कलनं न विद्यते';

  @override
  String get titleFilterHasTags => 'केवलं चिह्नितानि';

  @override
  String get labelFilterFileSize => 'सञ्चिकापरिमाणम्';

  @override
  String get labelFilterSizeAny => 'किमपि परिमाणम्';

  @override
  String get labelFilterSizeSmall => '1 MB तः न्यूनम्';

  @override
  String get bodyFilterSizeMedium => '1 तः 10 MB पर्यन्तम्';

  @override
  String get labelFilterSizeLarge => '10 MB तः अधिकम्';

  @override
  String get labelFilterSortBy => 'क्रमाधारः';

  @override
  String get labelFilterSortDateTaken => 'ग्रहणदिनाङ्कः';

  @override
  String get labelFilterSortDateAdded => 'योजनदिनाङ्कः';

  @override
  String get labelFilterSortName => 'नाम';

  @override
  String get labelFilterSortSize => 'परिमाणम्';

  @override
  String get actionFilterSortNewestFirst => 'नवीनतमं प्रथमम्';

  @override
  String get actionFilterSortOldestFirst => 'प्राचीनतमं प्रथमम्';

  @override
  String get titleVault => 'गुप्तकोशः';

  @override
  String get titleVaultMenuLabel => 'गुप्तकोशः';

  @override
  String get titleVaultMoveToVault => 'गुप्तकोशं नीयताम्';

  @override
  String get titleVaultSetUp => 'गुप्तकोशः सृज्यताम्';

  @override
  String get bodyVaultSetUp =>
      'अत्र नीतानि वस्तूनि अनेन उपकरणेन धृतया कुञ्चिकया गूढीक्रियन्ते चित्रशालातः च गोप्यन्ते।';

  @override
  String get bodyVaultNoRecoveryWarning =>
      'विस्मृतं गूढाङ्कं पुनः प्राप्तुम् उपायः न विद्यते। तं विना कोऽपि गुप्तकोशम् उद्घाटयितुं न शक्नोति, अयम् अनुप्रयोगोऽपि न ।';

  @override
  String get labelVaultChoosePin => 'गूढाङ्कः चीयताम्';

  @override
  String get bodyVaultConfirmPin => 'गूढाङ्कः पुनः लिख्यताम्';

  @override
  String get labelVaultEnterPin => 'गूढाङ्कः लिख्यताम्';

  @override
  String get labelVaultCreate => 'गुप्तकोशः सृज्यताम्';

  @override
  String get labelVaultUnlock => 'उद्घाट्यताम्';

  @override
  String get labelVaultUseBiometrics => 'अङ्गुलिमुद्राप्रयोगः';

  @override
  String get bodyVaultUnlockReason => 'भवतः गुप्तकोशः उद्घाट्यताम्';

  @override
  String get tooltipVaultLockNow => 'इदानीं पिधीयताम्';

  @override
  String get bodyVaultPinMismatch => 'उभौ गूढाङ्कौ समानौ न स्तः';

  @override
  String get bodyVaultWrongPin => 'सः गूढाङ्कः अशुद्धः';

  @override
  String bodyVaultAttemptsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count प्रयत्नाः अवशिष्टाः',
      one: '1 प्रयत्नः अवशिष्टः',
    );
    return '$_temp0';
  }

  @override
  String bodyVaultLockedOut(int seconds) {
    return 'अतिबहवः प्रयत्नाः। $seconds क्षणान् प्रतीक्ष्यताम्।';
  }

  @override
  String bodyVaultPinTooShort(int count) {
    return 'गूढाङ्के न्यूनातिन्यूनं $count अङ्काः आवश्यकाः';
  }

  @override
  String bodyVaultPinTooLong(int count) {
    return 'गूढाङ्के अधिकतमं $count अङ्काः भवितुम् अर्हन्ति';
  }

  @override
  String get bodyVaultPinNotDigits => 'गूढाङ्के केवलम् अङ्काः भवितुम् अर्हन्ति';

  @override
  String get bodyVaultPinAllSame => 'आद्यन्तम् एकः एव अङ्कः न प्रयुज्यताम्';

  @override
  String get bodyVaultPinSequential => 'क्रमिकाः अङ्काः न प्रयुज्यन्ताम्';

  @override
  String get errorVaultBiometricFailed =>
      'न अभिज्ञातम्। गूढाङ्कः प्रयुज्यताम्।';

  @override
  String get bodyVaultBiometricUnavailable =>
      'अङ्गुलिमुद्रया उद्घाटनम् अनुपलब्धम्। गूढाङ्कः प्रयुज्यताम्।';

  @override
  String get errorVaultAuth => 'गुप्तकोशम् उद्घाटयितुं न शक्तम्';

  @override
  String get titleVaultKeystoreUnavailable => 'सुरक्षितकुञ्चिकाभावः';

  @override
  String get bodyVaultKeystoreUnavailable =>
      'गुप्तकोशाय यन्त्राधारितः कुञ्चिकाकोशः आवश्यकः, अस्मिन् उपकरणे च कार्यक्षमः सः नास्ति। तं विना किमपि न गूढीक्रियते, अतः गुप्तकोशः पिहितः एव तिष्ठति।';

  @override
  String get titleVaultEmpty => 'गुप्तकोशः रिक्तः';

  @override
  String get bodyVaultEmpty =>
      'चित्राणि दृश्यानि च गूढीकर्तुं चित्रशालातः अपनेतुं च अत्र योज्यन्ताम्।';

  @override
  String bodyVaultSelectedCount(int count) {
    return '$count चितानि';
  }

  @override
  String get labelVaultAddItems => 'वस्तूनि योज्यन्ताम्';

  @override
  String get tooltipVaultRestore => 'चित्रशालायां स्थाप्यताम्';

  @override
  String get tooltipVaultDeleteForever => 'सर्वथा लुप्यताम्';

  @override
  String get tooltipVaultSettingsAction => 'गुप्तकोशविन्यासः';

  @override
  String get actionVaultCancel => 'निरस्यताम्';

  @override
  String get tooltipVaultClearSelection => 'चयनं रिक्तीक्रियताम्';

  @override
  String get titleVaultImport => 'गुप्तकोशं नीयताम्';

  @override
  String get bodyVaultImport =>
      'वस्तूनि गूढीक्रियन्ते चित्रशालातः च अपनीयन्ते। मूलसञ्चिकानां किं भवेत् इति भवान् निर्णयतु।';

  @override
  String get titleVaultImportKeepOriginal => 'मूलानि रक्ष्यन्ताम्';

  @override
  String get bodyVaultImportKeepOriginal =>
      'मूलानि यथास्थानं तिष्ठन्ति। इच्छति चेत् पश्चात् भवान् स्वयं तानि लुम्पतु।';

  @override
  String get titleVaultImportShredOriginal => 'मूलानि विनाश्यन्ताम्';

  @override
  String get bodyVaultImportShredOriginal =>
      'मूलसञ्चिकाः अधिलिख्य लुप्यन्ते। एतत् प्रत्यावर्तयितुं न शक्यते।';

  @override
  String bodyVaultImportConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count वस्तूनि नीयन्ताम्',
      one: '1 वस्तु नीयताम्',
    );
    return '$_temp0';
  }

  @override
  String get labelVaultImportNothingSelected => 'किमपि न चितम्';

  @override
  String bodyVaultShredConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count मूलानि विनाश्यन्ताम् वा?',
      one: '1 मूलं विनाश्यताम् वा?',
    );
    return '$_temp0';
  }

  @override
  String get bodyVaultShredConfirm =>
      'मूलसञ्चिकाः अधिलिख्य लोप्स्यन्ते। प्रत्यावर्तनं नास्ति, पुनः प्राप्तुम् उपायः अपि नास्ति।';

  @override
  String get actionVaultShredConfirm => 'विनाश्यन्ताम्';

  @override
  String bodyVaultImportDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count वस्तूनि गुप्तकोशं नीतानि',
      one: '1 वस्तु गुप्तकोशं नीतम्',
    );
    return '$_temp0';
  }

  @override
  String bodyVaultImportPartial(int moved, int failed) {
    return '$moved नीतानि, $failed पठितुं न शक्तानि';
  }

  @override
  String get errorVaultImportFailed => 'किमपि गुप्तकोशं नेतुं न शक्तम्';

  @override
  String bodyVaultRestoreConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count वस्तूनि पुनःस्थाप्यन्ताम् वा?',
      one: '1 वस्तु पुनःस्थाप्यताम् वा?',
    );
    return '$_temp0';
  }

  @override
  String get bodyVaultRestoreConfirm =>
      'वस्तूनि भवतः चित्रशालासंपुटेषु पुनः लिख्यन्ते गुप्तकोशात् च अपनीयन्ते।';

  @override
  String get actionVaultRestoreConfirm => 'पुनःस्थाप्यताम्';

  @override
  String bodyVaultDeleteConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count वस्तूनि सर्वथा लुप्यन्ताम् वा?',
      one: '1 वस्तु सर्वथा लुप्यताम् वा?',
    );
    return '$_temp0';
  }

  @override
  String get bodyVaultDeleteConfirm =>
      'गूढीकृताः सञ्चिकाः अधिलिख्य लुप्यन्ते। प्रत्यावर्तनं नास्ति, अन्यत्र कापि प्रतिलिपिः अपि नास्ति।';

  @override
  String get errorVaultViewerFailed => 'इदं वस्तु उद्घाटयितुं न शक्तम्';

  @override
  String get bodyVaultViewerTampered =>
      'इदं वस्तु प्रामाणिकतापरीक्षायाम् असफलम्, अतः न उद्घाटितम्';

  @override
  String get titleVaultSettings => 'गुप्तकोशविन्यासः';

  @override
  String get titleVaultAutoLockHeading => 'स्वतःपिधानम्';

  @override
  String get bodyVaultAutoLock =>
      'अनुप्रयोगे पटलात् निर्गते गुप्तकोशः सदा पिधीयते। भवता अस्पृष्टे सति सः एतावत्कालं प्रतीक्षते।';

  @override
  String bodyVaultAutoLockSeconds(int count) {
    return '$count क्षणाः';
  }

  @override
  String bodyVaultAutoLockMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count निमेषाः',
      one: '1 निमेषः',
    );
    return '$_temp0';
  }

  @override
  String get titleVaultBiometricHeading => 'अङ्गुलिमुद्रोद्घाटनम्';

  @override
  String get bodyVaultBiometric =>
      'लघुमार्गः, न तु प्रतिनिधिः। एतत् सक्रियं निष्क्रियं वा, भवतः गूढाङ्कः गुप्तकोशम् उद्घाटयति एव।';

  @override
  String get titleVaultShredHeading => 'विनाशावृत्तयः';

  @override
  String get bodyVaultShred =>
      'लोपात् पूर्वं सञ्चिका कतिवारम् अधिलिख्यते इति। अधिकाः आवृत्तयः अधिकं कालं गृह्णन्ति। विद्युत्स्मृतौ अधिलेखनं दृढः उपायः, न तु निश्चितं प्रतिभूः।';

  @override
  String bodyVaultShredPassCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count आवृत्तयः',
      one: '1 आवृत्तिः',
    );
    return '$_temp0';
  }

  @override
  String get titleVaultShredDefaultHeading => 'स्वतो मूलविनाशनम्';

  @override
  String get bodyVaultShredDefault =>
      'वस्तुयोजने विनाशविकल्पः पूर्वमेव चीयते। तथापि प्रतिवारं स्थिरीकरणं पृच्छ्यते।';

  @override
  String get titleVaultChangePin => 'गूढाङ्कपरिवर्तनम्';

  @override
  String get labelVaultCurrentPin => 'वर्तमानगूढाङ्कः';

  @override
  String get labelVaultNewPin => 'नूतनगूढाङ्कः';

  @override
  String get bodyVaultPinChanged => 'भवतः गूढाङ्कः परिवर्तितः';

  @override
  String get titleVaultSecureScreenHeading => 'पटलचित्रनिरोधः';

  @override
  String get bodyVaultSecureScreen =>
      'गुप्तकोशे उद्घाटिते सति Android पटलचित्राणि पटलमुद्रणं च निरुणद्धि, अनुप्रयोगपरिवर्तके च गुप्तकोशं गोपयति।';

  @override
  String bodySelectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count चितानि',
      one: '1 चितम्',
    );
    return '$_temp0';
  }

  @override
  String get tooltipSelectionClear => 'चयनं रिक्तीक्रियताम्';

  @override
  String get tooltipSelectionSelectAll => 'सर्वं चीयताम्';

  @override
  String get bodySelectionFull => 'एकस्मिन् समूहे एतावन्ति एव भवितुम् अर्हन्ति';

  @override
  String get labelBatchActionConvert => 'रूपान्तर्यताम्';

  @override
  String get labelBatchActionMore => 'अधिकम्';

  @override
  String get labelBatchActionWatermark => 'जलचिह्नम्';

  @override
  String get labelBatchActionExportPdf => 'PDF सृज्यताम्';

  @override
  String get labelBatchActionAddTags => 'चिह्नानि योज्यन्ताम्';

  @override
  String get labelBatchActionRemoveTags => 'चिह्नानि अपनीयन्ताम्';

  @override
  String get labelBatchActionAddToAlbum => 'सङ्कलने योज्यताम्';

  @override
  String get labelBatchActionFavourite => 'प्रियेषु योज्यताम्';

  @override
  String get bodyBatchActionUnfavourite => 'प्रियेभ्यः अपनीयताम्';

  @override
  String get labelBatchActionMoveToVault => 'गुप्तकोशं नीयताम्';

  @override
  String get bodyBatchActionTransfer => 'उपकरणं प्रति प्रेष्यताम्';

  @override
  String get titleBatchActionMoveToTrash => 'अवकरपात्रं नीयताम्';

  @override
  String get emptyBatchBlocked => 'प्रथमं किमपि चीयताम्';

  @override
  String get bodyBatchBlockedTooLarge => 'एकस्य समूहस्य कृते अतिबहूनि वस्तूनि';

  @override
  String get bodyBatchBlockedUnsupported => 'एतासां सञ्चिकानां कृते अनुपलब्धम्';

  @override
  String get bodyBatchBlockedMixed =>
      'अस्यां क्रियायां दृश्यानि योजयितुं न शक्यन्ते';

  @override
  String get titleBatchRunning => 'प्रक्रिया प्रचलति';

  @override
  String bodyBatchProgress(int done, int total) {
    return '$total मध्ये $done';
  }

  @override
  String get labelBatchCancel => 'निरस्यताम्';

  @override
  String get bodyBatchCancelling => 'अस्याः सञ्चिकायाः अनन्तरं विरमति';

  @override
  String get labelBatchDone => 'समाप्तम्';

  @override
  String bodyBatchResultSucceeded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count सञ्चिकाः सिद्धाः',
      one: '1 सञ्चिका सिद्धा',
    );
    return '$_temp0';
  }

  @override
  String errorBatchResultFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count सञ्चिकाः साधयितुं न शक्ताः',
      one: '1 सञ्चिका साधयितुं न शक्ता',
    );
    return '$_temp0';
  }

  @override
  String bodyBatchResultSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count सञ्चिकाः त्यक्ताः',
      one: '1 सञ्चिका त्यक्ता',
    );
    return '$_temp0';
  }

  @override
  String get titleBatchConfirm => 'निश्चयेन वा?';

  @override
  String bodyBatchConfirmVault(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count चित्राणि गुप्तकोशं नेष्यन्ते',
      one: '1 चित्रं गुप्तकोशं नेष्यते',
    );
    return '$_temp0';
  }

  @override
  String bodyBatchConfirmTrash(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count वस्तूनि अवकरपात्रं नेष्यन्ते। किमपि न मार्ज्यते।',
      one: '1 वस्तु अवकरपात्रं नेष्यते। किमपि न मार्ज्यते।',
    );
    return '$_temp0';
  }

  @override
  String bodyBatchConfirmNewFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'मूलानां पार्श्वे $count नूतनाः सञ्चिकाः रक्षिष्यन्ते।',
      one: 'मूलस्य पार्श्वे एका नूतना सञ्चिका रक्षिष्यते।',
    );
    return '$_temp0';
  }

  @override
  String get actionBatchConfirmContinue => 'अनुवर्त्यताम्';

  @override
  String get labelBatchPickTags => 'चिह्नानि चीयन्ताम्';

  @override
  String get labelBatchPickAlbum => 'सङ्कलनं चीयताम्';

  @override
  String get titleBackup => 'रक्षाप्रती पुनःस्थापनं च';

  @override
  String get titleBackupOpen => 'रक्षाप्रती-उद्धारौ';

  @override
  String get titleBackupCreate => 'रक्षाप्रती सृज्यताम्';

  @override
  String get bodyBackupCreate =>
      'भवतः चिह्नानि, सङ्कलनानि, प्रियाणि, टिप्पण्यः च एकस्यां गूढशब्दरक्षितायां सञ्चिकायां रक्ष्यन्ते। चित्राणि दृश्यानि च न अन्तर्भवन्ति: तानि \'स्थानान्तरणम्\' द्वारा अन्यद् उपकरणं प्रेष्यन्ताम्।';

  @override
  String get actionBackupCreate => 'रक्षाप्रती सृज्यताम्';

  @override
  String get titleBackupRestore => 'रक्षाप्रत्युद्धारः';

  @override
  String get bodyBackupRestore =>
      'अस्मिन् उपकरणे विद्यमानानां चित्राणां चिह्नानि, सङ्कलनानि, प्रियाणि, टिप्पण्यः च पुनः आनीयन्ते। अस्मिन् उपकरणे किमपि न लुप्यते।';

  @override
  String get actionBackupRestore => 'रक्षासञ्चिका चीयताम्';

  @override
  String get titleBackupPassword => 'रक्षाप्रतीगूढशब्दः';

  @override
  String get labelBackupPassword => 'गूढशब्दः';

  @override
  String get labelBackupPasswordConfirm => 'पुनः लिख्यताम्';

  @override
  String get bodyBackupPasswordWarning =>
      'अस्य गूढशब्दस्य पुनःप्राप्तेः उपायः नास्ति। विस्मृते सति प्रतिलिपिः उद्घाटयितुं न शक्यते।';

  @override
  String bodyBackupPasswordTooShort(int count) {
    return 'न्यूनातिन्यूनं $count अक्षराणि';
  }

  @override
  String get bodyBackupPasswordMismatch => 'उभौ समानौ न स्तः';

  @override
  String get labelBackupStageCollecting => 'भवतः सङ्ग्रहः पठ्यते';

  @override
  String get labelBackupStagePacking => 'सङ्गृह्यते';

  @override
  String get bodyBackupStageChoosing =>
      'कुत्र रक्षणीयम् इति भवतः चयनं प्रतीक्ष्यते';

  @override
  String get labelBackupStageEncrypting => 'गूढीक्रियते';

  @override
  String get labelBackupDone => 'प्रतिलिपिः रक्षिता';

  @override
  String get labelBackupCancelled => 'रक्षाप्रती निरस्ता';

  @override
  String get bodyBackupNothingToSave =>
      'रक्षणाय अद्यापि चिह्नानि, सङ्कलनानि, टिप्पण्यः, प्रियाणि वा न सन्ति';

  @override
  String get errorBackupFailed => 'प्रतिलिपिः रक्षितुमशक्या';

  @override
  String get titleRestorePreview => 'किं पुनःस्थापयिष्यते';

  @override
  String bodyRestoreFromBackupDate(String date) {
    return '$date दिनाङ्कस्य प्रतिलिपिः';
  }

  @override
  String bodyRestorePlanTags(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count नूतनानि चिह्नानि',
      one: '1 नूतनं चिह्नम्',
      zero: 'नूतनानि चिह्नानि न सन्ति',
    );
    return '$_temp0';
  }

  @override
  String bodyRestorePlanAlbums(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count नूतनानि सङ्कलनानि',
      one: '1 नूतनं सङ्कलनम्',
      zero: 'नूतनानि सङ्कलनानि न सन्ति',
    );
    return '$_temp0';
  }

  @override
  String bodyRestorePlanLinks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'योजनाय $count चिह्नानि सङ्कलनस्थानानि च',
      one: 'योजनाय 1 चिह्नं सङ्कलनस्थानं वा',
      zero: 'योजनाय चिह्नानि सङ्कलनस्थानानि वा न सन्ति',
    );
    return '$_temp0';
  }

  @override
  String bodyRestorePlanUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'अद्यतनीकरणाय $count चित्राणि',
      one: 'अद्यतनीकरणाय 1 चित्रम्',
      zero: 'अद्यतनीकरणाय चित्राणि न सन्ति',
    );
    return '$_temp0';
  }

  @override
  String bodyRestorePlanUnmatched(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'प्रतिलिप्यां $count चित्राणि अस्मिन् उपकरणे न सन्ति',
      one: 'प्रतिलिप्यां 1 चित्रम् अस्मिन् उपकरणे नास्ति',
    );
    return '$_temp0';
  }

  @override
  String get bodyRestorePlanNothing =>
      'इयं प्रतिलिपिः अस्मिन् उपकरणे किमपि न परिवर्तयेत्';

  @override
  String get labelRestoreApply => 'पुनःस्थाप्यताम्';

  @override
  String get labelRestoreDone => 'पुनःस्थापनं समाप्तम्';

  @override
  String get bodyRestoreWrongPassword =>
      'अशुद्धः गूढशब्दः, अथवा सञ्चिका क्षतिग्रस्ता';

  @override
  String get bodyRestoreNotAnArchive => 'सा चित्रशालाप्रतिलिपिसञ्चिका न';

  @override
  String get bodyRestoreTooLarge =>
      'सा सञ्चिका चित्रशालाप्रतिलिपिः भवितुम् अतिबृहती';

  @override
  String get bodyRestoreTooNew =>
      'सा प्रतिलिपिः अनुप्रयोगस्य नूतनतरेण संस्करणेन कृता';

  @override
  String get errorRestoreFailed => 'प्रतिलिपिः पुनःस्थापयितुमशक्या';

  @override
  String get titleSync => 'स्थानान्तरणम्';

  @override
  String get titleSyncOpen => 'यन्त्रात् स्वीकरणम्';

  @override
  String get bodySyncIntro =>
      'समान Wi-Fi जालस्थाद् अन्यस्माद् दूरवाणीयन्त्रात् चित्राणि स्वीक्रियन्ताम्। किमपि अन्तर्जालं न गच्छति, उपयोक्तृविवरणम् अपि न आवश्यकम्।';

  @override
  String get bodySyncPrivacyNote =>
      'उभे दूरवाणीयन्त्रे समाने Wi-Fi जाले स्याताम्। अन्यद् उपकरणं भवतः स्थानीयजाले न चेत् सम्पर्कः निराक्रियते, अस्मात् पटलात् निर्गमनमात्रेण च पिधीयते।';

  @override
  String get labelSyncSend => 'प्रेष्यताम्';

  @override
  String get labelSyncReceive => 'स्वीक्रियताम्';

  @override
  String get bodySyncReceive => 'प्रेषकयन्त्रम् एतम् अन्वीक्षते';

  @override
  String titleSyncQuickSend(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count वस्तूनि प्रेष्यन्ताम्',
      one: '1 वस्तु प्रेष्यताम्',
    );
    return '$_temp0';
  }

  @override
  String get bodySyncQuickIntro =>
      'चितानि चित्राणि दृश्यानि च समान Wi-Fi जालस्थम् अन्यद् दूरवाणीयन्त्रं प्रति साक्षात् प्रेष्यन्ताम्। किमपि अन्तर्जालं न गच्छति।';

  @override
  String get bodySyncPhoneMoveIntro =>
      'अयम् अनुप्रयोगः नूतनं दूरवाणीयन्त्रं प्रति प्रतिलिख्यताम्। सम्बन्धनानन्तरं संपुटानि सङ्कलनानि च चीयन्ताम्। \'समाप्यताम्\' इति स्पृष्टे सर्वः अनुप्रयोगदत्तांशः विन्यासश्च गच्छतः। उभयोः यन्त्रयोः किमपि न लुप्यते।';

  @override
  String get labelSyncShowCode => 'सङ्केतः दर्श्यताम्';

  @override
  String get bodySyncShowCodeToReceiver => 'स्वीकर्तृयन्त्रम् एतम् अन्वीक्षते';

  @override
  String get labelSyncScanOther => 'अन्ययन्त्रस्य सङ्केतः अन्वीक्ष्यताम्';

  @override
  String get bodySyncScanReceiverCode => 'यदा स्वीकर्तृयन्त्रं सङ्केतं दर्शयति';

  @override
  String get bodySyncScanSenderCode => 'यदा प्रेषकयन्त्रं सङ्केतं दर्शयति';

  @override
  String get bodySyncHowToSend =>
      'प्रेषणाय वीथिकायां चित्राणि चित्वा \'उपकरणं प्रति प्रेष्यताम्\' स्पृश्यताम्। नूतनयन्त्रं प्रति स्थानान्तरणाय विन्यासः › उपकरणसमन्वयः उपयुज्यताम्।';

  @override
  String get bodyDeviceSyncWifiReceive =>
      'नूतने यन्त्रे: पुरातनात् संपुटानि सङ्कलनानि अनुप्रयोगदत्तांशः विन्यासश्च प्राप्यन्ताम्';

  @override
  String get bodySyncAppDataSending =>
      'अनुप्रयोगदत्तांशः विन्यासश्च प्रेष्येते';

  @override
  String get bodySyncAppDataReceiving =>
      'अनुप्रयोगदत्तांशः विन्यासश्च स्वीक्रियेते';

  @override
  String get bodySyncAppDataSent => 'अनुप्रयोगदत्तांशः विन्यासश्च प्रेषितौ';

  @override
  String bodySyncVaultReceived(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count सञ्चिकाः गुप्तकोशे स्थापिताः',
      one: '1 सञ्चिका गुप्तकोशे स्थापिता',
    );
    return '$_temp0';
  }

  @override
  String get actionSyncReviewAppData => 'अनुप्रयोगदत्तांशः परीक्ष्यताम्';

  @override
  String get bodySyncAppDataApplied => 'अनुप्रयोगदत्तांशः योजितः';

  @override
  String get errorSyncAppDataApply =>
      'अनुप्रयोगदत्तांशः योजयितुं न शक्तः। पुनः प्रयत्यताम्।';

  @override
  String get titleSyncUseSettings => 'पुरातनयन्त्रस्य विन्यासः उपयुज्यताम् वा?';

  @override
  String get bodySyncUseSettings =>
      'अस्य यन्त्रस्य वर्णयोजना भाषा जालकपरिमाणं सुरक्षाविकल्पाः च अन्ययन्त्रस्य विन्यासेन परिवर्त्यन्ते।';

  @override
  String get actionSyncKeepMySettings => 'मदीयः रक्ष्यताम्';

  @override
  String get actionSyncUseTheirSettings => 'तदीयः उपयुज्यताम्';

  @override
  String get bodySyncErrorAppData =>
      'सञ्चिकाः प्रेषिताः, किन्तु अनुप्रयोगदत्तांशः विन्यासश्च न प्रेषितौ। तौ प्रेषयितुं स्थानान्तरणं पुनः क्रियताम्।';

  @override
  String get labelSyncAppDataAndSettings => 'अनुप्रयोगदत्तांशः विन्यासश्च';

  @override
  String get bodySyncAppDataOnFinish =>
      'चिह्नानि, सङ्कलनानि, प्रियाणि, टिप्पण्यः, स्थानानि, विन्यासश्च। \'समाप्यताम्\' इति स्पृष्टे एतानि गच्छन्ति।';

  @override
  String get labelSyncIncludeVault => 'गुप्तकोशः';

  @override
  String get bodySyncIncludeVaultOff =>
      'निष्क्रियम्। गुप्तकोशम् अपि प्रतिलेखयितुं सक्रियं क्रियताम्। प्रथमं सः उद्घाटनीयः।';

  @override
  String get bodySyncIncludeVaultOn =>
      'सक्रियम्। \'समाप्यताम्\' इति स्पृष्टे गुप्तकोशवस्तूनि गच्छन्ति, अस्य यन्त्रस्य गुप्तकोशे अपि तिष्ठन्ति।';

  @override
  String get bodySyncVaultPeerNotReady =>
      'अन्यस्मिन् यन्त्रे गुप्तकोशः न सज्जीकृतः, अतः गुप्तकोशः न प्रेष्यते। तत्र सः सज्जीक्रियतां, स्थानान्तरणं च पुनः क्रियताम्।';

  @override
  String get bodySyncVaultNotSetUp => 'अस्मिन् यन्त्रे गुप्तकोशः नास्ति।';

  @override
  String get bodySyncVaultUnlockFirst =>
      'गुप्तकोशम् उद्घाट्य अत्र प्रत्यागम्यताम्।';

  @override
  String get actionSyncScanCode => 'सङ्केतोऽन्वीक्ष्यताम्';

  @override
  String get titleSyncScan => 'परयन्त्रमन्वीक्ष्यताम्';

  @override
  String get titleSyncPairingHeading => 'परयन्त्रेऽन्वीक्ष्यताम्';

  @override
  String get titleSyncManualCodeHeading => 'वा सङ्केतो लिख्यताम्';

  @override
  String get labelSyncManualCode => 'युग्मनसङ्केतः';

  @override
  String get bodySyncManualCodeInvalid => 'सः सङ्केतः अमान्यः';

  @override
  String get bodySyncWaiting => 'अन्यद् दूरवाणीयन्त्रं प्रतीक्ष्यते';

  @override
  String bodySyncPairedWith(String name) {
    return '$name इत्यनेन सह युग्मितम्';
  }

  @override
  String get labelSyncTransferring => 'स्थानान्तरणं प्रचलति';

  @override
  String bodySyncProgressFiles(int done, int total) {
    return '$total मध्ये $done सञ्चिकाः';
  }

  @override
  String get labelSyncDone => 'स्थानान्तरणं समाप्तम्';

  @override
  String bodySyncResultReceived(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count सञ्चिकाः स्वीकृताः',
      one: '1 सञ्चिका स्वीकृता',
    );
    return '$_temp0';
  }

  @override
  String bodySyncResultSent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count सञ्चिकाः प्रेषिताः',
      one: '1 सञ्चिका प्रेषिता',
    );
    return '$_temp0';
  }

  @override
  String bodySyncResultSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count सञ्चिकाः पूर्वमेव आसन्',
      one: '1 सञ्चिका पूर्वमेव आसीत्',
    );
    return '$_temp0';
  }

  @override
  String errorSyncResultFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count सञ्चिकाः न प्राप्ताः',
      one: '1 सञ्चिका न प्राप्ता',
    );
    return '$_temp0';
  }

  @override
  String get bodySyncSavedToAppFolder =>
      'Android इत्यस्य अस्मिन् संस्करणे सञ्चिकाः भवतः चित्रशालायां न, अपि तु अनुप्रयोगस्य स्वसंपुटे रक्षिताः।';

  @override
  String get actionSyncStop => 'विरम्यताम्';

  @override
  String get bodySyncErrorNoNetwork =>
      'इदं दूरवाणीयन्त्रं कस्मिंश्चित् Wi-Fi जाले नास्ति';

  @override
  String get bodySyncErrorPairingTimeout => 'समये किमपि उपकरणं न संयुक्तम्';

  @override
  String get bodySyncErrorRefused => 'तत् उपकरणं भवतः स्थानीयजाले नास्ति';

  @override
  String get bodySyncErrorHandshake =>
      'अन्यत् उपकरणं तं सङ्केतं दर्शितवत् इति प्रमाणयितुं न अशक्नोत्';

  @override
  String get bodySyncErrorProtocol =>
      'अन्यस्मिन् उपकरणे अनुप्रयोगस्य भिन्नं संस्करणं प्रचलति';

  @override
  String get bodySyncErrorConnection => 'अन्येन उपकरणेन सह सम्पर्कः नष्टः';

  @override
  String get bodySyncErrorIdle => 'अन्यत् उपकरणं प्रत्युत्तरं दातुं विरतम्';

  @override
  String get bodySyncErrorCancelled => 'स्थानान्तरणं विरमितम्';

  @override
  String get bodySyncErrorUnknown => 'स्थानान्तरणं समापयितुं न शक्तम्';

  @override
  String get bodySyncCameraPermission =>
      'सङ्केतान्वीक्षणाय छायाग्राहकानुमतिरावश्यकी। तत्स्थाने सङ्केतो लेखितुं शक्यते।';

  @override
  String get actionSyncTypeCodeInstead => 'सङ्केतः लिख्यताम्';

  @override
  String get tooltipViewerMoreActions => 'अधिकम्';

  @override
  String get titleCodeScanOpen => 'सङ्केतान्वीक्षणम्';

  @override
  String get titleCodeScan => 'चित्रस्थसङ्केताः';

  @override
  String get labelCodeScanLooking => 'सङ्केताः अन्विष्यन्ते';

  @override
  String get bodyCodeScanNoCodes => 'अस्मिन् चित्रे न कोऽपि सङ्केतः प्राप्तः';

  @override
  String get errorCodeScanFailed => 'इदं चित्रम् अन्वीक्षितुं न शक्तम्';

  @override
  String get tooltipCodeScanRetry => 'पुनः प्रयत्यताम्';

  @override
  String bodyCodeScanFoundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count सङ्केताः प्राप्ताः',
      one: '1 सङ्केतः प्राप्तः',
    );
    return '$_temp0';
  }

  @override
  String get labelCodeScanKindUrl => 'जालसङ्केतः';

  @override
  String get labelCodeScanKindWifi => 'Wi-Fi जालम्';

  @override
  String get labelCodeScanKindPhone => 'दूरवाणीसङ्ख्या';

  @override
  String get labelCodeScanKindEmail => 'विद्युत्पत्रसङ्केतः';

  @override
  String get labelCodeScanKindSms => 'लघुसन्देशः';

  @override
  String get labelCodeScanKindGeo => 'मानचित्रबिन्दुः';

  @override
  String get labelCodeScanKindContact => 'सम्पर्कपत्रम्';

  @override
  String get labelCodeScanKindCalendar => 'पञ्चाङ्गप्रविष्टिः';

  @override
  String get labelCodeScanKindText => 'पाठः';

  @override
  String get labelCodeScanActionCopy => 'प्रतिलिख्यताम्';

  @override
  String get labelCodeScanActionOpen => 'उद्घाट्यताम्';

  @override
  String get labelCodeScanActionDial => 'आहूयताम्';

  @override
  String get labelCodeScanActionEmail => 'ईपत्रं लिख्यताम्';

  @override
  String get labelCodeScanActionSms => 'सन्देशः प्रेष्यताम्';

  @override
  String get labelCodeScanActionMap => 'मानचित्रे दर्श्यताम्';

  @override
  String get labelCodeScanActionCopyWifiPassword => 'गूढशब्दप्रतिलेखनम्';

  @override
  String get labelCodeScanActionConnectWifi => 'संयुज्यताम्';

  @override
  String get labelCodeScanActionSaveToNotes => 'टिप्पण्यां रक्ष्यताम्';

  @override
  String get bodyCodeScanBlockedScheme =>
      'अनुप्रयोगः एतादृशं सङ्केतं न उद्घाटयति';

  @override
  String get bodyCodeScanBlockedMalformed => 'अयं सङ्केतः पठितुं न शक्तः';

  @override
  String get bodyCodeScanBlockedIncompleteWifi =>
      'अस्मिन् Wi-Fi सङ्केते जालनाम गूढशब्दः वा न्यूनः';

  @override
  String get bodyCodeScanBlockedTooLong => 'अयं सङ्केतः उपयोगाय अतिदीर्घः';

  @override
  String get labelCodeScanCopied => 'प्रतिलिखितम्';

  @override
  String get labelCodeScanPasswordCopied => 'गूढशब्दः प्रतिलिखितः';

  @override
  String get labelCodeScanSavedToNotes => 'टिप्पण्यां रक्षितम्';

  @override
  String get errorCodeScanOpenFailed =>
      'अस्मिन् उपकरणे कोऽपि अनुप्रयोगः तत् उद्घाटयितुं न शक्नोति';

  @override
  String get bodyCodeScanWifiSuggested =>
      'जालम् Android प्रति प्रस्तावितम्। Wi-Fi विन्यासे तत् चीयताम्।';

  @override
  String get bodyCodeScanWifiManual =>
      'Wi-Fi विन्यासः उद्घाट्य जालं स्वयं चीयताम्।';

  @override
  String bodyCodeScanWifiSecurity(String security) {
    return 'सुरक्षा: $security';
  }

  @override
  String get labelCodeScanWifiHidden => 'गुप्तजालम्';

  @override
  String get labelCodeScanWifiOpen => 'मुक्तजालम्';

  @override
  String get titleOcrOpen => 'पाठः निष्कास्यताम्';

  @override
  String get titleOcr => 'अस्मिन् चित्रे पाठः';

  @override
  String get labelOcrReading => 'पाठः पठ्यते';

  @override
  String get helpOcrSlowHint => 'बृहत् चित्रं कतिपयान् क्षणान् गृह्णीयात्।';

  @override
  String get labelOcrLanguage => 'भाषा';

  @override
  String get labelOcrLanguageEnglish => 'आङ्ग्लभाषा';

  @override
  String get labelOcrLanguageMalayalam => 'मलयाळभाषा';

  @override
  String get bodyOcrLanguageBoth => 'आङ्ग्लं मलयाळं च';

  @override
  String get bodyOcrNoText => 'अस्मिन् चित्रे न कोऽपि पाठः प्राप्तः';

  @override
  String get actionOcrCopyAll => 'सर्वं प्रतिलिख्यताम्';

  @override
  String get labelOcrCopied => 'पाठः प्रतिलिखितः';

  @override
  String get labelOcrSaveToNotes => 'टिप्पण्यां रक्ष्यताम्';

  @override
  String get labelOcrSavedToNotes => 'टिप्पण्यां रक्षितम्';

  @override
  String get actionOcrReadAgain => 'पुनः पठ्यताम्';

  @override
  String bodyOcrWordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count शब्दाः',
      one: '1 शब्दः',
    );
    return '$_temp0';
  }

  @override
  String get bodyOcrFailedUnreadable => 'इदं चित्रम् उद्घाटयितुं न शक्तम्';

  @override
  String get bodyOcrFailedTooLarge => 'इदं चित्रं पठनाय अतिबृहत्';

  @override
  String get bodyOcrFailedMissingData =>
      'अस्मिन् निर्माणे भाषासञ्चिकाः न सन्ति';

  @override
  String get bodyOcrFailedTimeout =>
      'पठनम् अतिदीर्घकालम् अगृह्णात्, अतः विरमितम्';

  @override
  String get bodyOcrFailedEngine => 'पाठः पठितुमशक्यः';

  @override
  String get titleNotesOpen => 'टिप्पण्यः';

  @override
  String get titleNotes => 'टिप्पण्यः';

  @override
  String get tabNotesWrite => 'लेखनम्';

  @override
  String get tabNotesPreview => 'पूर्वदर्शनम्';

  @override
  String get helpNotesHint =>
      'अस्य वस्तुनः विषये टिप्पणी लिख्यताम्। Markdown समर्थितम्।';

  @override
  String get emptyNotes => 'अद्यापि टिप्पणी नास्ति';

  @override
  String get tooltipNotesSave => 'रक्ष्यताम्';

  @override
  String get labelNotesSaved => 'टिप्पणी रक्षिता';

  @override
  String get errorNotesSaveFailed => 'टिप्पणी रक्षितुमशक्या';

  @override
  String get tooltipNotesDelete => 'टिप्पणी लुप्यताम्';

  @override
  String get titleNotesDelete => 'टिप्पणी लुप्यताम् वा?';

  @override
  String get bodyNotesDelete => 'टिप्पणी अपनेष्यते। सञ्चिका न परिवर्तते।';

  @override
  String get labelNotesDeleted => 'टिप्पणी लुप्ता';

  @override
  String get actionNotesCancel => 'निरस्यताम्';

  @override
  String bodyNotesCharacterCount(int used, int total) {
    return '$total मध्ये $used अक्षराणि';
  }

  @override
  String get bodyNotesTooLong => 'इयं टिप्पणी रक्षणाय अतिदीर्घा';

  @override
  String get titleNotesDiscard => 'अरक्षितं त्यज्यताम्?';

  @override
  String get bodyNotesDiscard => 'अस्यां टिप्पण्यां भवतः परिवर्तनानि नश्यन्ति।';

  @override
  String get actionNotesDiscardLeave => 'निर्गम्यताम्';

  @override
  String get actionNotesDiscardKeep => 'लेखनम् अनुवर्त्यताम्';

  @override
  String get bodyNotesLinkBlocked =>
      'अनुप्रयोगः एतादृशम् अनुबन्धम् न उद्घाटयति';

  @override
  String get titleNotesDetailsLabel => 'टिप्पणी';

  @override
  String get labelNotesAddFromDetails => 'टिप्पणी योज्यताम्';

  @override
  String get titlePdfImagesOpen => 'PDF-चित्रनिष्कासनम्';

  @override
  String get titlePdfImages => 'PDF मध्ये चित्राणि';

  @override
  String get actionPdfImagesPick => 'PDF चीयताम्';

  @override
  String get tooltipPdfImagesChooseAnother => 'अन्यत् PDF चीयताम्';

  @override
  String get labelPdfImagesReading => 'PDF पठ्यते';

  @override
  String get titlePdfImagesEmpty => 'अद्यापि PDF न चितम्';

  @override
  String get bodyPdfImagesEmpty =>
      'PDF चीयताम्, अनुप्रयोगः तस्य अन्तःस्थानि चित्राणि सूचयिष्यति। मूलं PDF कदापि न परिवर्तते।';

  @override
  String get bodyPdfImagesNone => 'अस्मिन् PDF मध्ये चित्राणि न सन्ति';

  @override
  String bodyPdfImagesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count चित्राणि प्राप्तानि',
      one: '1 चित्रं प्राप्तम्',
    );
    return '$_temp0';
  }

  @override
  String bodyPdfImagesSkippedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count पठितुं न शक्तानि',
      one: '1 पठितुं न शक्तम्',
    );
    return '$_temp0';
  }

  @override
  String get labelPdfImagesSave => 'चितानि रक्ष्यन्ताम्';

  @override
  String get labelPdfImagesSaving => 'रक्ष्यते';

  @override
  String bodyPdfImagesSavedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count चित्राणि चित्रशालायां रक्षितानि',
      one: '1 चित्रं चित्रशालायां रक्षितम्',
    );
    return '$_temp0';
  }

  @override
  String bodyPdfImagesSaveFailedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count रक्षितुं न शक्तानि',
      one: '1 रक्षितुं न शक्तम्',
    );
    return '$_temp0';
  }

  @override
  String get actionPdfImagesSelectAll => 'सर्वं चीयताम्';

  @override
  String get labelPdfImagesClearSelection => 'रिक्तीक्रियताम्';

  @override
  String get bodyPdfImagesNothingSelected =>
      'रक्षणाय न्यूनातिन्यूनम् एकं चित्रं चीयताम्';

  @override
  String get bodyPdfImagesTruncated =>
      'अस्मिन् PDF मध्ये अतिबहूनि चित्राणि सन्ति, अतः केवलं प्रथमानि पठितानि।';

  @override
  String get bodyPdfImagesFallbackDirectory =>
      'चित्रशालायां लेखितुं न शक्तम्, अतः अनुप्रयोगसंपुटे रक्षितम्';

  @override
  String bodyPdfImageSize(int width, int height) {
    return '$width × $height';
  }

  @override
  String get bodyPdfRefusedNotPdf => 'इयं सञ्चिका PDF न';

  @override
  String get bodyPdfRefusedEncrypted =>
      'इदं PDF गूढशब्दरक्षितम्, अतः उद्घाटयितुं न शक्यते';

  @override
  String get bodyPdfRefusedTooLarge => 'इदं PDF उद्घाटनाय अतिबृहत्';

  @override
  String get bodyPdfRefusedUnreadable => 'इदं PDF पठितुं न शक्तम्';

  @override
  String get bodyPdfSkipUnsupportedFilter =>
      'अनुप्रयोगेण अपठनीयरीत्या सङ्कुचितम्';

  @override
  String get bodyPdfSkipUnsupportedColor =>
      'अनुप्रयोगेण अपठनीयं वर्णावकाशं प्रयुङ्क्ते';

  @override
  String get bodyPdfSkipUnsupportedDepth =>
      'अनुप्रयोगेण अपठनीयां वर्णगभीरतां प्रयुङ्क्ते';

  @override
  String get bodyPdfSkipTooLarge => 'निष्कासनाय अतिबृहत्';

  @override
  String get bodyPdfSkipMalformed => 'चित्रदत्तांशः अपूर्णः';

  @override
  String get errorPdfSkipDecodeFailed => 'चित्रं विसङ्कोचयितुं न शक्तम्';

  @override
  String get titleSettingsAppearance => 'रूपम्';

  @override
  String get titleSettingsLanguage => 'भाषा';

  @override
  String get titleSettingsSafety => 'सुरक्षितता';

  @override
  String get titleSettingsPrivacy => 'गोपनीयता';

  @override
  String get titleSettingsDeveloper => 'विकासकः';

  @override
  String get titleLanguageSystem => 'तन्त्रपूर्वनिर्धारितम्';

  @override
  String get titleLanguageEnglish => 'English';

  @override
  String get titleLanguageMalayalam => 'മലയാളം';

  @override
  String get descLanguageSubtitle =>
      'अनुप्रयोगः सद्यः एव भाषां परिवर्तयति। पुनरारम्भः न आवश्यकः।';

  @override
  String get labelGridDensity => 'जालसान्द्रता';

  @override
  String get descGridDensitySubtitle =>
      'कालक्रमे प्रतिपङ्क्ति कति चित्राणि इति। जालस्य अङ्गुलिसङ्कोचनेन अपि एतत् परिवर्तते।';

  @override
  String labelGridDensityValue(int count) {
    return 'प्रतिपङ्क्ति $count';
  }

  @override
  String get titleShowFlashbacks => 'स्मृतयः दर्श्यन्ताम्';

  @override
  String get descShowFlashbacksSubtitle =>
      'गतवर्षेषु अस्य दिनस्य चित्राणां पङ्क्तिः, कालक्रमस्य शीर्षे।';

  @override
  String get titleConfirmDestructive => 'लोपात्पूर्वं प्रश्नः';

  @override
  String get descConfirmDestructiveSubtitle =>
      'लोपात् अधिलेखनात् वा पूर्वं पुनः एकवारं पृच्छ्यताम्। केचन सावधानसन्देशाः अस्य विन्यासं विना अपि सदा दृश्यन्ते।';

  @override
  String get titlePrivacyNoServer => 'दूरस्थः सेवकः नास्ति';

  @override
  String get bodyPrivacyNoServer =>
      'भवतः चित्राणि, चिह्नानि, टिप्पण्यः च अस्मिन् एव दूरवाणीयन्त्रे तिष्ठन्ति। किमपि न आरोप्यते, उपयोक्तृविवरणम् अपि नास्ति। अन्तर्जालप्रवेशः केवलं स्थानान्तरणपटलेन, भवतः स्वकीये Wi-Fi जाले अन्यद् दूरवाणीयन्त्रं प्राप्तुं, प्रयुज्यते।';

  @override
  String bodyAboutBuild(String build) {
    return 'निर्मितिसङ्ख्या $build';
  }

  @override
  String get titleAboutBuildDate => 'निर्मितिदिनाङ्कः';

  @override
  String get errorAboutMailFailed =>
      'अस्मिन् दूरवाणीयन्त्रे कोऽपि अनुप्रयोगः तं सङ्केतम् उद्घाटयितुं न शक्नोति।';

  @override
  String get descVaultSettingsOpenSubtitle => 'पिधानसमयः, गूढाङ्कः, विनाशनं च';

  @override
  String get descBackupOpenSubtitle =>
      'गूढशब्दरक्षितं प्रतिलिपिरक्षणं पुनःस्थापनं च';

  @override
  String get titleSettingsReset => 'विन्यासपुनःस्थापनम्';

  @override
  String get bodySettingsReset =>
      'अस्मिन् पटले प्रत्येकं विन्यासः आरम्भदशां प्रति पुनः नीयते। भवतः चित्राणि, चिह्नानि, सङ्कलनानि, गुप्तकोशः च न स्पृश्यन्ते।';

  @override
  String get bodySettingsResetDone =>
      'विन्यासः पूर्वनिर्धारितदशां प्रति पुनः नीतः।';

  @override
  String get actionSettingsCancel => 'निरस्यताम्';

  @override
  String get actionSettingsResetConfirm => 'पुनःसज्जीक्रियताम्';

  @override
  String get helpSettings => 'साहाय्यं मार्गदर्शिकाः च';

  @override
  String get descSettingsHelpSubtitle =>
      'प्रत्येकस्य विशेषस्य मार्गदर्शिकाः, उपयुक्तसूचनाः, असंयुक्तप्रतिज्ञाः च अवलोक्यन्ताम्';

  @override
  String get labelSettingsAbout => 'विषयपरिचयः';

  @override
  String get helpOverview => 'सारांशः';

  @override
  String get helpHowToUse => 'उपयोगविधिः';

  @override
  String get helpTips => 'सूचनाः लघुमार्गाः च';

  @override
  String get helpPrivacy => 'गोपनीयता असंयुक्तप्रतिज्ञा च';

  @override
  String get helpBadgeOffline => 'पूर्णतया असंयुक्तम्';

  @override
  String get helpBadgeEncrypted => 'यन्त्रगूढीकृतम्';

  @override
  String get helpBadgeLocal => 'केवलं स्थानीय Wi-Fi';

  @override
  String get helpBadgeSafe => 'अविनाशकम्';

  @override
  String get helpTopicTimelineTitle => 'कालक्रमः स्मृतयः च';

  @override
  String get helpTopicTimelineSummary =>
      'दिनाङ्कानुसारं चित्राणि अवलोक्यन्ताम्, जालपरिमाणं परिवर्तयितुम् अङ्गुलिभ्यां सङ्कोच्यताम्, स्मृतयः दृश्यन्ताम्।';

  @override
  String get helpTopicTimelineOverview =>
      'कालक्रमः भवतः सर्वाणि सूचीकृतानि चित्राणि दृश्यानि च दिनाङ्कशीर्षकैः सह विपरीतकालक्रमेण व्यवस्थापयति। तस्मिन् \'अस्मिन् दिने\' इति स्मृतिपङ्क्तिः अपि अस्ति, या गतवर्षेषु अद्यतनदिनस्य चित्राणि दर्शयति।';

  @override
  String get helpTopicTimelineSteps =>
      '• 1 तः 5 स्तम्भपर्यन्तं परिवर्तयितुम् अङ्गुलिभ्यां सङ्कोच्यतां विस्तार्यतां वा।\n• मासेषु वर्षेषु च शीघ्रं गन्तुं दक्षिणभागे स्थितं दिनाङ्कसूचकं कृष्यताम्।\n• उच्चविभेदेन उद्घाटयितुं किमपि चित्रं दृश्यं वा स्पृश्यताम्।';

  @override
  String get helpTopicTimelineTips =>
      '• समूहक्रियाणां कृते बहुचयनं प्रवेष्टुं किमपि चित्रं दीर्घं निपीड्यताम्।\n• विन्यासे स्मृतयः सक्रियाः निष्क्रियाः वा कर्तुं शक्यन्ते।';

  @override
  String get helpTopicTimelinePrivacy =>
      'कालक्रमस्य सर्वं वर्गीकरणं दिनाङ्कसूचीकरणं च स्थानीय SQLite द्वारा केवलम् उपकरणे एव भवति। कदापि कोऽपि दूरस्थः सेवकः न सम्पर्क्यते।';

  @override
  String get helpTopicViewerTitle => 'पूर्णपटलदर्शकः दृश्यप्रवर्तकः च';

  @override
  String get helpTopicViewerSummary =>
      'अङ्गुलिसङ्केतैः, EXIF विवरणेन, यन्त्राधारितदृश्यप्रवर्तनेन च युक्तः उच्चविभेददर्शकः।';

  @override
  String get helpTopicViewerOverview =>
      'सुगमेन यन्त्रत्वरणेन चित्राणि दृश्यानि च दृश्यन्ताम्। प्रतिक्रियाशीलैः अङ्गुलिसङ्केतैः कालक्रमे निर्बाधं सर्प्यताम्।';

  @override
  String get helpTopicViewerSteps =>
      '• सूक्ष्मविवरणं वर्धयितुं द्विवारं स्पृश्यताम् अङ्गुलिभ्यां विस्तार्यतां वा।\n• पिधाय कालक्रमं प्रति गन्तुम् अधः सर्प्यताम्।\n• EXIF अधिदत्तांशं (छायाग्राहकः, प्रकाशनम्, विभेदः, स्थानम्) द्रष्टुम् ऊर्ध्वं सर्प्यताम्।\n• दृश्ये प्रवर्तमाने: दीप्त्यर्थं वामभागे, ध्वन्यर्थं दक्षिणभागे ऊर्ध्वम् अधः वा सर्प्यताम्, अग्रे पृष्ठतः वा गन्तुं तिर्यक् सर्प्यताम्।';

  @override
  String get helpTopicViewerTips =>
      '• प्रवर्तनवेगं (0.25x तः 2.0x पर्यन्तम्) समायोजयितुं, प्रतिचित्रखण्डं चलितुं, पुनः पुनः प्रवर्तयितुं वा दृश्यनियन्त्रणानि प्रयुज्यन्ताम्।\n• सम्पादनं, रूपान्तरणम्, अन्वीक्षणं, टिप्पण्यः च शीघ्रं प्राप्तुम् अधिकसूची स्पृश्यताम्।';

  @override
  String get helpTopicViewerPrivacy =>
      'EXIF अधिदत्तांशः स्थानीयतया SQLite मध्ये विश्लिष्यते रक्ष्यते च। दृश्यविसङ्केतनं यन्त्रत्वरितं, केनापि जालप्रवाहघटकेन विना।';

  @override
  String get helpTopicEditorTitle => 'चित्रसम्पादकः अङ्कनं च';

  @override
  String get helpTopicEditorSummary =>
      'कर्तनं, भ्रमणं, वर्णसमायोजनं, परिशोधकप्रयोगः, आलेखनम्, गोप्यक्षेत्राणां गोपनं च।';

  @override
  String get helpTopicEditorOverview =>
      'परिवर्तनैः, वर्णसमायोजनैः, कलात्मकपरिशोधकैः, मुक्तहस्तालेखनेन, गोपनीयतागोपनेन, जलचिह्नेन च युक्तः सम्पूर्णः अविनाशकः चित्रसम्पादकः।';

  @override
  String get helpTopicEditorSteps =>
      '• किमपि चित्रम् उद्घाट्य उपकरणपट्टिकायां सम्पादनचिह्नं स्पृश्यताम्।\n• परिवर्तनम्: मानकानुपातैः कर्त्यताम्, चतुर्थांशं भ्राम्यताम्, प्रतिबिम्ब्यताम्, ऋजूक्रियतां वा।\n• समायोजनम्: प्रकाशनं, वैषम्यम्, उज्ज्वलांशाः, छायाः, ऊष्मा, RGB वक्ररेखाः च सूक्ष्मं समायोज्यन्ताम्।\n• अङ्कनं गोपनं च: आकृतयः आलिख्यन्ताम्, पाठः योज्यताम्, गौसीय-अस्पष्टीकरणेन खण्डीकरणेन कृष्णावरणेन वा गोप्यक्षेत्राणि गोप्यन्ताम्।\n• निर्यापणाय \'रक्ष्यताम्\' स्पृश्यताम्।';

  @override
  String get helpTopicEditorTips =>
      '• गोपनीयतागोपनं निर्यापिते चित्रे अधःस्थान् चित्राणून् स्थायिरूपेण प्रतिस्थापयति।\n• सम्पादनकाले सम्पूर्णः प्रत्यावर्तनपुनःकरणेतिहासः उपलभ्यते।';

  @override
  String get helpTopicEditorPrivacy =>
      'सर्वाः चित्रक्रियाः पृष्ठभूमिस्थे पृथक्कार्यक्षेत्रे पूर्णतया असंयुक्ततया क्रियन्ते। सम्पादनानि मूलस्य पार्श्वे नूतनसंस्करणरूपेण रक्ष्यन्ते, भवतः अनुमतिं विना मूलचित्रं कदापि न अधिलिख्यते।';

  @override
  String get helpTopicConverterTitle => 'प्रारूपरूपान्तरकः सङ्कोचनं च';

  @override
  String get helpTopicConverterSummary =>
      'प्रारूपाणि (JPEG, PNG, WEBP, BMP) रूपान्तर्यन्ताम्, सञ्चिकापरिमाणं सङ्कोच्यताम्, दृश्यानि कर्त्यन्ताम्।';

  @override
  String get helpTopicConverterOverview =>
      'प्रसिद्धचित्रप्रारूपेषु चित्राणि रूपान्तर्यन्ताम्, तत्कालपरिमाणानुमानेन सञ्चिकापरिमाणं सङ्कोच्यताम्, दृश्यात् स्थिरचित्रखण्डाः निष्कास्यन्ताम्, दृश्यांशाः GIF रूपेण परिवर्त्यन्ताम्, गुणहानिं विना दृश्यानि कर्त्यन्ताम् च।';

  @override
  String get helpTopicConverterSteps =>
      '• दर्शकस्य अधिकसूच्याः \'रूपान्तर्यताम्\' चीयताम्।\n• लक्ष्यप्रारूपं (JPEG, PNG, WEBP, BMP) चीयतां गुणवत्तासूचकश्च समायोज्यताम्।\n• इच्छति चेत् परिमाणविधिः (प्रतिशतं, दीर्घतमा भुजा, स्वनिर्धारितायामाः वा) निर्धार्यताम्।\n• अनुकूलितसञ्चिकां जनयितुं \'रूपान्तर्यताम्\' स्पृश्यताम्।';

  @override
  String get helpTopicConverterTips =>
      '• दृश्यसाधनेषु: पुनःसङ्केतनं गुणहानिं च विना भागान् कर्तुं गुणहानिरहितं कर्तनं प्रयुज्यताम्।\n• स्वनिर्धारितचित्रखण्डवेगेन पुनरावृत्तिविन्यासेन च दृश्यांशेभ्यः चलितानि GIF चित्राणि सृज्यन्ताम्।';

  @override
  String get helpTopicConverterPrivacy =>
      'सर्वाणि चित्रदृश्यरूपान्तरणानि जालप्रेषणं विना पूर्णतया उपकरणे एव भवन्ति। फलानि नूतनसञ्चिकारूपेण रक्ष्यन्ते।';

  @override
  String get helpTopicPdfTitle => 'PDF निर्यापणं चित्रनिष्कासनं च';

  @override
  String get helpTopicPdfSummary =>
      'बहुचित्रयुक्तानि PDF पत्राणि निर्याप्यन्ताम्, PDF अन्तःस्थानि चित्राणि च असंयुक्ततया निष्कास्यन्ताम्।';

  @override
  String get helpTopicPdfOverview =>
      'चितेभ्यः चित्रेभ्यः स्वनिर्धारितविन्यासेन व्यावसायिकानि PDF पत्राणि सृज्यन्ताम्, अथवा PDF पत्रेषु निहितानि उच्चगुणानि चित्राणि निष्कास्यन्ताम्।';

  @override
  String get helpTopicPdfSteps =>
      '• PDF निर्यापणम्: चित्राणि चीयन्ताम्, पृष्ठपरिमाणम् (A4, लेटर्), दिशा, सीमाः च निर्धार्य \'निर्याप्यताम्\' स्पृश्यताम्।\n• PDF चित्रनिष्कासनम्: कालक्रमसूच्याः साधनम् उद्घाट्य PDF सञ्चिकां चित्वा प्राप्तानि चित्राणि परीक्ष्य चित्रशालायां निष्कासनाय \'रक्ष्यताम्\' स्पृश्यताम्।';

  @override
  String get helpTopicPdfTips =>
      '• पृष्ठक्रमं नियन्त्रयितुं PDF निर्यापणात् पूर्वं चित्राणां क्रमः परिवर्त्यताम्।\n• PDF निष्कासकः सञ्चिकावस्तूनि साक्षात् परिक्रमते, अतः PDF इत्यस्य सन्दर्भसारणी क्षतिग्रस्ता चेदपि कार्यं करोति।';

  @override
  String get helpTopicPdfPrivacy =>
      'PDF-निर्माणं निष्कासनं च अनुप्रयोगस्य निजसुरक्षितक्षेत्रे पूर्णतया असंयुक्ततया क्रियेते। PDF-दत्तांशः कदापि कस्याञ्चिन्मेघसेवायां नारोप्यते।';

  @override
  String get helpTopicSearchTitle => 'अन्वेषणं चिह्नानि च';

  @override
  String get helpTopicSearchSummary =>
      'प्रश्नपरिशोधकैः सह सद्यः SQLite FTS5 अन्वेषणं, द्वादशवर्णचिह्नप्रबन्धनं च।';

  @override
  String get helpTopicSearchOverview =>
      'शीर्षकेषु, टिप्पणीषु, छायाग्राहकप्रतिरूपेषु, चिह्नेषु च पूर्णपाठान्वेषणेन, उपसर्गसञ्चालकैः बहुमानदण्डपरिशोधकैः च चित्राणि दृश्यानि च सद्यः अन्विष्यन्ताम्।';

  @override
  String get helpTopicSearchSteps =>
      '• कालक्रमे अन्वेषणचिह्नं स्पृश्यताम्।\n• कानिचित् अन्वेषणपदानि लिख्यन्ताम्, अथवा उपसर्गाः प्रयुज्यन्ताम्: \'tag:nature\', \'type:video\', \'camera:sony\', \'place:kochi\', \'before:2024-01-01\'।\n• दिनाङ्कपरिधिं, माध्यमप्रकारं, प्रियाणि, परिमाणपरिशोधकान् च संयोजयितुं परिशोधकचिह्नं स्पृश्यताम्।\n• चिह्नप्रबन्धनाय कालक्रमसूच्याः चिह्नपटलं गम्यताम्।';

  @override
  String get helpTopicSearchTips =>
      '• द्वादशभिः विशिष्टैः Material वर्णैः स्वचिह्नानि सृज्यन्ताम्।\n• चिह्नानि अन्वेषणसूचीं सद्यः अद्यतनीकुर्वन्ति, अतः चित्राणि क्षणार्धे प्राप्यन्ते।';

  @override
  String get helpTopicSearchPrivacy =>
      'अन्वेषणसूच्यः स्थानीयतया SQLite FTS5 मध्ये रक्ष्यन्ते। भवतः अन्वेषणप्रश्नाः इतिवृत्तं च केवलं भवतः उपकरणे एव तिष्ठन्ति।';

  @override
  String get helpTopicAlbumsTitle => 'सङ्कलनानि स्वचालितसङ्कलनानि च';

  @override
  String get helpTopicAlbumsSummary =>
      'आभासीसङ्कलनेषु व्यवस्थाप्यताम्, उपकरणसंपुटानि अवलोक्यन्ताम्, स्वचालितसङ्कलनानि च दृश्यन्ताम्।';

  @override
  String get helpTopicAlbumsOverview =>
      'उपयोक्तृसृष्टैः आभासीसङ्कलनैः, भौतिकोपकरणसंपुटावलोकनेन, माध्यमानि स्वतः व्यवस्थापयद्भिः स्वचालितसङ्कलनैः च भवतः सङ्ग्रहः प्रबध्यताम्।';

  @override
  String get helpTopicAlbumsSteps =>
      '• कालक्रमस्य शीर्षपट्टिकायां \'सङ्कलनानि\' स्पृश्यताम्।\n• आभासीसङ्कलनानि: सङ्कलनं स्रष्टुं \'+\' स्पृश्यताम्, माध्यमानि योज्यन्ताम्, वस्तूनां क्रमः परिवर्त्यताम्, स्वावरणचित्रं वा निर्धार्यताम्।\n• स्वचालितसङ्कलनानि: प्रियाणि, दृश्यानि, GIF, RAW चित्राणि, विहङ्गमचित्राणि, सद्यः योजितानि च स्वतः सङ्गृह्णन्ति।\n• उपकरणसंपुटानि: भवतः उपकरणस्मृतौ भौतिकसंपुटानि (Camera, Screenshots, WhatsApp, Downloads) अवलोक्यन्ताम्।';

  @override
  String get helpTopicAlbumsTips =>
      '• प्रियसङ्कलनानि सूच्याः शीर्षे रक्षितुम् उपरि स्थाप्यन्ताम्।\n• आभासीसङ्कलनानि माध्यमसञ्चिकाः न द्विगुणीकुर्वन्ति, अतः सङ्ग्रहस्थानं रक्ष्यते।';

  @override
  String get helpTopicAlbumsPrivacy =>
      'सङ्कलनसदस्यता अधिदत्तांशः च स्थानीयदत्तांशकोशे रक्ष्यन्ते। उपकरणसंपुटान्वीक्षणम् Android इत्यस्य सीमितसङ्ग्रहनियमान् अनुसरति।';

  @override
  String get helpTopicCleanerTitle => 'द्विरुक्तशोधकः';

  @override
  String get helpTopicCleanerSummary =>
      'पार्श्वतुलनया सह समानानि दृष्टिसदृशानि च द्विरुक्तानि अभिज्ञायन्ताम्।';

  @override
  String get helpTopicCleanerOverview =>
      'समानद्विरुक्तसञ्चिकाः (SHA-256 द्वारा) दृष्टिसदृशचित्राणि च (pHash dHash द्वारा) अभिज्ञाय सङ्ग्रहस्थानं मोच्यताम्।';

  @override
  String get helpTopicCleanerSteps =>
      '• कालक्रमसूच्याः द्विरुक्तशोधकः उद्घाट्यताम्।\n• भवतः सङ्ग्रहं विश्लेषयितुम् \'अन्वीक्ष्यताम्\' स्पृश्यताम्।\n• द्विरुक्तवर्गाः परीक्ष्यन्ताम्, पार्श्वतुलनायै कमपि वर्गं स्पृश्यताम्।\n• उच्चतमविभेदयुक्तं स्पष्टतमं चित्रं स्वतः चेतुम् अन्यानि अवकरपात्रं नेतुं च \'श्रेष्ठचित्रं रक्ष्यताम्\' प्रयुज्यताम्।';

  @override
  String get helpTopicCleanerTips =>
      '• दृष्टिसाम्यहैशनं शीघ्रक्रमेण गृहीतानि अल्पसम्पादितानि वा चित्राणि अपि प्राप्नोति।\n• भवतः स्थिरीकरणं विना कापि सञ्चिका कदापि न लुप्यते।';

  @override
  String get helpTopicCleanerPrivacy =>
      'हैशनं पूर्णतया स्थानीयतया प्रचलति। DCT गणनायै 32x32 लघुपूर्वदर्शनानि प्रयुज्यन्ते सद्यः च मार्ज्यन्ते।';

  @override
  String get helpTopicVaultTitle => 'सुरक्षितः गुप्तकोशः';

  @override
  String get helpTopicVaultSummary =>
      'यन्त्राधारितं AES-256-GCM गूढीकरणम्, अङ्गुलिमुद्रा-गूढाङ्क-प्रमाणीकरणं, विनाशनं च।';

  @override
  String get helpTopicVaultOverview =>
      'संवेदनशीलानि चित्राणि दृश्यानि च गूढीकृते गुप्तकोशे रक्ष्यन्ताम्। दत्तांशः Android कुञ्चिकाकोशेन रक्षितया 256-बिट् कुञ्चिकया गूढीक्रियते, अङ्गुलिमुद्रोद्घाटनेन पटलचित्रनिरोधेन च सह।';

  @override
  String get helpTopicVaultSteps =>
      '• गुप्तकोशम् उद्घाटयितुं विन्यसितुं वा कालक्रमे गुप्तकोशचिह्नं स्पृश्यताम्।\n• मुख्यगूढाङ्कः निर्धार्यताम् (सुलभप्रवेशाय अङ्गुलिमुद्रा अपि सक्रियीक्रियताम्)।\n• कालक्रमात् दर्शकात् वा माध्यमानि आनीयन्ताम्। मूलसञ्चिका सुरक्षितं विनाशनीया वा इति चीयताम्।\n• गूढीकृतानि चित्राणि दृश्यानि च गुप्तकोशे एव सुरक्षितं दृश्यन्ताम्।';

  @override
  String get helpTopicVaultTips =>
      '• गुप्तकोशे स्थिते सति पटलचित्ररक्षणं (FLAG_SECURE) सक्रियम्।\n• अनुप्रयोगे पृष्ठभूमिं प्रति गते निष्क्रियसमयानन्तरं वा गुप्तकोशः स्वतः पिधीयते।';

  @override
  String get helpTopicVaultPrivacy =>
      'विगूढः दत्तांशः केवलं स्मृतौ धार्यते। कुञ्चिकाः कदापि Android कुञ्चिकाकोशयन्त्रात् बहिः न गच्छन्ति, स्पष्टसञ्चिकाः अपि उपकरणस्मृतौ न अवशिष्यन्ते।';

  @override
  String get helpTopicSyncTitle => 'स्थानीय Wi-Fi स्थानान्तरणम्';

  @override
  String get helpTopicSyncSummary =>
      'अन्तर्जालं विना समाने Wi-Fi जाले उपकरणयोः मध्ये साक्षात् स्थानान्तरणम्।';

  @override
  String get helpTopicSyncOverview =>
      'समाने स्थानीय Wi-Fi जाले द्वयोः दूरवाणीयन्त्रयोः मध्ये साक्षात् चित्राणि दृश्यानि च स्थानान्तर्यन्ताम्। सम्पर्काः प्रमाणितेन हस्तमेलनेन आद्यन्तं गूढीक्रियन्ते।';

  @override
  String get helpTopicSyncSteps =>
      '• स्वीकर्तृ-उपकरणे: QR युग्मनसङ्केतं दर्शयितुं \'स्थानान्तरणम्\' > \'स्वीक्रियताम्\' उद्घाट्यताम्।\n• प्रेषक-उपकरणे: \'स्थानान्तरणम्\' > \'प्रेष्यताम्\' उद्घाट्य सङ्केतः अन्वीक्ष्यताम् (अथवा षडक्षरसङ्केतः लिख्यताम्)।\n• स्थानान्तरणाय चित्राणि सङ्कलनानि वा चित्वा स्थानान्तरणम् आरभ्यताम्।\n• स्वीकृताः सञ्चिकाः SHA-256 द्वारा परीक्ष्य साक्षात् भवतः चित्रशालायां प्रकाश्यन्ते।';

  @override
  String get helpTopicSyncTips =>
      '• अन्तर्जालप्रवेशः जालयन्त्रविन्यासः वा न आवश्यकः; उपकरणे स्थानीय IP सङ्केतैः साक्षात् संयुज्येते।\n• स्थानान्तरणसम्पर्कः केवलं स्थानान्तरणपटले उद्घाटिते सति बध्यते, भवतः निर्गमनमात्रेण च पिधीयते।';

  @override
  String get helpTopicSyncPrivacy =>
      'बाह्यैः सार्वजनिकैः वा IP सङ्केतैः सह सम्पर्काः LocalAddressRules द्वारा दृढं निरुध्यन्ते। न अनुसरणं, न दूरमापनं, न मेघमध्यस्थः।';

  @override
  String get helpTopicBackupTitle => 'प्रतिलिपिरक्षणं पुनःस्थापनं च';

  @override
  String get helpTopicBackupSummary =>
      'गूढशब्दरक्षिताः गूढीकृताः .gbak-सञ्चिकाः सृज्यन्तां सुरक्षितं पुनःस्थाप्यन्तां च।';

  @override
  String get helpTopicBackupOverview =>
      'भवतः चिह्नानि, सङ्कलनसंरचनाः, माध्यमटिप्पण्यः, उपयोक्त्रधिदत्तांशः च AES-256-GCM-रक्षितायां गूढीकृतायां GBAK-प्रतिलिपिसञ्चिकायां सुरक्ष्यन्ताम्।';

  @override
  String get helpTopicBackupSteps =>
      '• कालक्रमसूच्याः \'प्रतिलिपिरक्षणम्\' स्पृश्यताम्।\n• प्रतिलिपिरक्षणसृष्टिः: दृढं गूढशब्दं लिखित्वा Android इत्यस्य पत्रचयनकेन प्रतिलिपिसञ्चिका रक्ष्यताम्।\n• पुनःस्थापनम्: पूर्वनिर्यापितां .gbak सञ्चिकां चित्वा गूढशब्दं लिखित्वा पूर्वदर्शनसारं परीक्ष्य प्रयुज्यताम्।';

  @override
  String get helpTopicBackupTips =>
      '• पुनःस्थापनप्रक्रिया अविनाशिका: विद्यमानं दत्तांशम् अनधिलिख्य रिक्तस्थानानि पूरयति चिह्नानि सङ्कलनानि च संयोजयति।\n• प्रतिलिपिगूढशब्दस्य सुरक्षितं लेखं रक्ष्यताम्; तं विना गूढीकृतः सङ्ग्रहः पुनः प्राप्तुं न शक्यते।';

  @override
  String get helpTopicBackupPrivacy =>
      'प्रतिलिपिसञ्चिकाः PBKDF2 व्युत्पन्नकुञ्चिकाभिः AES-256-GCM द्वारा च गूढीक्रियन्ते। प्रतिलिपयः भवतः उपकरणे SD पत्रे वा यत्र भवान् चिनोति तत्र रक्ष्यन्ते।';

  @override
  String get helpTopicScannerTitle => 'QR अन्वीक्षकः OCR च';

  @override
  String get helpTopicScannerSummary =>
      'सुरक्षितसङ्केतविधिभिः चित्रेभ्यः QR/दण्डसङ्केताः अन्वीक्ष्यन्ताम्, असंयुक्त-OCR द्वारा पाठः निष्कास्यताम्।';

  @override
  String get helpTopicScannerOverview =>
      'QR सङ्केतान् दण्डसङ्केतान् च अन्वीक्षितुं विद्यमानचित्राणि विश्लेष्यन्ताम्, अथवा आङ्ग्लमलयाळपाठनिष्कासनाय असंयुक्तं Tesseract अक्षराभिज्ञानं प्रवर्त्यताम्।';

  @override
  String get helpTopicScannerSteps =>
      '• दर्शके चित्रम् उद्घाट्य सूच्याः \'सङ्केताः अन्वीक्ष्यन्ताम्\' \'पाठः निष्कास्यताम्\' वा चीयताम्।\n• अन्वीक्षितसङ्केताः: प्राप्तः URL, Wi-Fi प्रमाणपत्राणि, पाठः वा दृश्यताम्। सुरक्षितसङ्केतविधयः (http, https, tel, mailto, sms, geo) स्थिरीकरणेन सह उद्घाटयितुं शक्यन्ते।\n• निष्कासितपाठः: अभिज्ञातः पाठः दृश्यताम्, प्रतिलिख्यताम्, अथवा माध्यमवस्तुनः टिप्पण्यां साक्षात् योज्यताम्।';

  @override
  String get helpTopicScannerTips =>
      '• अक्षराभिज्ञानम् अन्तर्निहितानि असंयुक्तभाषाप्रतिरूपाणि (आङ्ग्लं मलयाळं च) प्रयुङ्क्ते; अन्तर्जालसम्पर्कः न आवश्यकः।\n• Wi-Fi सङ्केतैः जालप्रमाणपत्राणि सुरक्षितं प्रतिलेखितुं, मौनसंयोजनं विना जालसम्पर्कं प्रस्तावयितुं वा शक्यते।';

  @override
  String get helpTopicScannerPrivacy =>
      'सर्वं दण्डसङ्केतविसङ्केतनम् OCR प्रक्रिया च भवतः उपकरणे स्थानीयतया क्रियन्ते। अविश्वस्ताः QR विषयाः बाह्यानुप्रयोगप्रवर्तनात् पूर्वं परीक्ष्यन्ते।';

  @override
  String get titleSettingsDefaultApp => 'पूर्वनिर्धारितचित्रशाला';

  @override
  String get descSettingsDefaultAppSubtitle =>
      'चित्रदृश्यदर्शनाय मुख्यानुप्रयोगत्वेन निर्धार्यताम्';

  @override
  String get titleDefaultAppDialog => 'मुख्यचित्रशालानिर्धारणम्';

  @override
  String get bodyDefaultAppDialog =>
      'इमां भवतः मुख्यचित्रशालां कर्तुम्:\n\n1. भवतः उपकरणे किमपि चित्रं दृश्यं वा उद्घाट्यताम् (यथा Files, Downloads, सन्देशेभ्यः वा)।\n2. \'दृश्य\' चित्वा \'Always\' स्पृश्यताम्।\n\nयदि अन्यः अनुप्रयोगः इदानीं चित्राणि उद्घाटयति, तर्हि प्रथमं तस्य पूर्वनिर्धारणं निष्कास्यताम्: Android विन्यासः → Apps → सः अनुप्रयोगः → Open by default।';

  @override
  String get titleTrash => 'अवकरपात्रम्';

  @override
  String get emptyTrash => 'अवकरपात्रं रिक्तम्';

  @override
  String get descTrashEmptySubtitle =>
      'भवता लुप्तानि वस्तूनि अवकरपात्रस्य रिक्तीकरणपर्यन्तम् अत्र रक्ष्यन्ते।';

  @override
  String get tooltipTrashEmptyAction => 'अवकरो रिक्तीक्रियताम्';

  @override
  String get titleTrashEmptyConfirm => 'अवकरः शोध्यताम् वा?';

  @override
  String get bodyTrashEmptyConfirm =>
      'अनेन अवकरपात्रस्थानि सर्वाणि वस्तूनि भवतः उपकरणस्मृतेः सर्वथा लुप्यन्ते। इयं क्रिया प्रत्यावर्तयितुं न शक्यते।';

  @override
  String get titleTrashDeletePermanentlyAction => 'सर्वथा लुप्यताम्';

  @override
  String get titleTrashDeletePermanentlyConfirm => 'सर्वथा लुप्यताम् वा?';

  @override
  String get bodyTrashDeletePermanentlyConfirm =>
      'इदं वस्तु भवतः उपकरणस्मृतेः सर्वथा लोप्स्यते। इयं क्रिया प्रत्यावर्तयितुं न शक्यते।';

  @override
  String get bodyTrashDeletedPermanentlySnackbar => 'वस्तु सर्वथा लुप्तम्';

  @override
  String get actionTrashRestore => 'पुनःस्थाप्यताम्';

  @override
  String get tooltipTrashRestoreAllAction => 'सर्वं पुनःस्थाप्यताम्';

  @override
  String get bodyTrashRestoreAllConfirm =>
      'अवकरपात्रस्थं प्रत्येकं वस्तु भवतः सङ्ग्रहं प्रति पुनः नेष्यते।';

  @override
  String get bodyTrashRestoredSnackbar => 'अवकरपात्रात् पुनःस्थापितम्';

  @override
  String get bodyTrashEmptiedSnackbar => 'अवकरपात्रं रिक्तीकृतम्';

  @override
  String bodyTrashItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'अवकरपात्रे $count वस्तूनि',
      one: 'अवकरपात्रे 1 वस्तु',
    );
    return '$_temp0';
  }

  @override
  String get descSettingsAppearanceSubtitle =>
      'रूपविन्यासः, जालसान्द्रता, स्मृतयः';

  @override
  String get descSettingsLanguageSubtitle =>
      'तन्त्रम्, आङ्ग्लम्, मलयाळम्, संस्कृतम्';

  @override
  String get descSettingsSafetySubtitle =>
      'विनाशकक्रियाभ्यः पूर्वं स्थिरीकरणम्';

  @override
  String get descSettingsDefaultAppCardSubtitle =>
      'मुख्यचित्रशालात्वेन निर्धार्यताम्';

  @override
  String get descSettingsPrivacySubtitle => 'विषयगोपनं गुप्तकोशः च';

  @override
  String get descSettingsHelpCardSubtitle =>
      'प्रत्येकस्य विशेषस्य मार्गदर्शिकाः गोपनीयताप्रतिज्ञाः च';

  @override
  String get descSettingsAboutSubtitle => 'संस्करणं, लेखकः, अनुज्ञापत्रं च';

  @override
  String get descSettingsDeveloperSubtitle => 'माध्यमान्वीक्षणसाधनानि';

  @override
  String get titleViewerTrashConfirm => 'अवकरपात्रं नीयताम् वा?';

  @override
  String get bodyViewerTrashConfirm =>
      'इदं वस्तु अवकरपात्रं नेष्यते। \'अवकरपात्रम्\' सङ्कलनात् कदापि पुनःस्थापयितुं शक्यते।';

  @override
  String get bodyViewerTrashSuccess => 'अवकरपात्रं नीतम्';

  @override
  String get actionViewerTrashUndo => 'प्रत्यावर्त्यताम्';

  @override
  String get titleComparePhotos => 'A/B तुलना';

  @override
  String get labelCompareModeSplit => 'विभक्तदर्शनम्';

  @override
  String get labelCompareModeCurtain => 'सर्पद्यवनिका';

  @override
  String get labelCompareSplitHorizontal => 'पार्श्वे पार्श्वे';

  @override
  String get labelCompareSplitVertical => 'उपरि अधः च';

  @override
  String get bodyCompareSyncLocked => 'सञ्चालनवर्धने बद्धे';

  @override
  String get bodyCompareSyncUnlocked => 'स्वतन्त्रे सञ्चालनवर्धने';

  @override
  String get tooltipCompareSwap => 'चित्रे विनिमीयेताम्';

  @override
  String get tooltipCompareResetZoom => 'वर्धनपुनःस्थापनम्';

  @override
  String get tooltipCompareDetails => 'विवरणतुलना';

  @override
  String get labelComparePhotoA => 'चित्रम् A';

  @override
  String get labelComparePhotoB => 'चित्रम् B';

  @override
  String get titleCompareWithPrevious => 'पूर्वेण तुल्यताम्';

  @override
  String get titleCompareWithNext => 'अग्रिमेण तुल्यताम्';

  @override
  String get titleCompareChooseFromGallery => 'चित्रशालातः चयनम्';

  @override
  String get tooltipCompare => 'चित्रतुलना';

  @override
  String get bodyCompareSelectSecondPhoto => 'तुलनायै चित्रं चीयताम्';

  @override
  String get labelCompareDimensions => 'आयामाः';

  @override
  String get labelCompareFileSize => 'सञ्चिकापरिमाणम्';

  @override
  String get labelCompareDateTaken => 'ग्रहणदिनाङ्कः';

  @override
  String get labelCompareCamera => 'छायाग्राहकः';

  @override
  String get labelCompareIso => 'ISO';

  @override
  String get labelCompareAperture => 'रन्ध्रम्';

  @override
  String get labelCompareShutterSpeed => 'आवरणवेगः';

  @override
  String get labelCompareFocalLength => 'नाभ्यन्तरम्';

  @override
  String get tabTimeline => 'कालक्रमः';

  @override
  String get tabFolders => 'संपुटानि';

  @override
  String get tabAlbums => 'सङ्कलनानि';

  @override
  String get titleFolders => 'संपुटानि';

  @override
  String get emptyFolders => 'न किमपि संपुटं प्राप्तम्';

  @override
  String get bodyFoldersEmpty =>
      'भवतः उपकरणे चित्राणि दृश्यानि च अन्वेष्टुम् अधः कृष्यताम्।';

  @override
  String get tooltipPrivacyScrubberTitle => 'गोपनीयताशोधकः';

  @override
  String get descPrivacyScrubberSubtitle =>
      'वितरणात् पूर्वं संवेदनशीलः EXIF अधिदत्तांशः अपनीयतां GPS स्थानं च विचाल्यताम्';

  @override
  String get titlePrivacyScrubberMenu => 'गोपनीयताशोधकः';

  @override
  String get titlePrivacyCard => 'माध्यमगोपनीयता EXIF च';

  @override
  String get bodyPrivacyCard =>
      'वितरणात् पूर्वं GPS स्थानं, छायाग्राहकक्रमाङ्काः, उपकरणपरिचायकाः च अपनीय भवतः गोपनीयता रक्ष्यताम्।';

  @override
  String get bodyPrivacyOpenScrubber => 'गोपनीयतानियन्त्रणानि उद्घाट्यन्ताम्';

  @override
  String get labelPrivacyTabStripper => 'EXIF अपनायकः';

  @override
  String get labelPrivacyTabGeofence => 'GPS स्थानविचालकः';

  @override
  String get actionPrivacyStripAndShare => 'शोध्य वितीर्यताम्';

  @override
  String get actionPrivacySaveSanitized => 'शोधितप्रती रक्ष्यताम्';

  @override
  String get titlePrivacyGranular => 'शोधनीयं चीयताम्';

  @override
  String get labelPrivacyStripAll => 'सर्वम् अपनीयताम्';

  @override
  String get labelPrivacyCustom => 'स्वनिर्धारितम्';

  @override
  String get titlePrivacyOptionGps => 'GPS-स्थानम्';

  @override
  String get titlePrivacyOptionSerials => 'क्रमाङ्काः';

  @override
  String get titlePrivacyOptionTimestamps => 'ग्रहणदिनाङ्काः';

  @override
  String get titlePrivacyOptionAuthor => 'लेखकतन्त्रांशौ';

  @override
  String get bodyPrivacyErrorReadingFile =>
      'गोपनीयताप्रक्रियायै चित्रदत्तांशः पठितुं न शक्तः';

  @override
  String get titlePrivacyShare => 'शोधितमाध्यमवितरणम्';

  @override
  String get errorPrivacyShareFailed => 'वितरणम् आरब्धुं न शक्तम्';

  @override
  String get errorPrivacyProcess => 'माध्यमशोधने दोषः सञ्जातः';

  @override
  String get bodyPrivacySavedToGallery =>
      'शोधितप्रतिलिपिः चित्रशालायां रक्षिता';

  @override
  String get errorPrivacySaveFailed => 'शोधितचित्रं रक्षितुं न शक्तम्';

  @override
  String get bodyPrivacyNoLocation =>
      'अस्मिन् चित्रे निहितं GPS स्थानं न प्राप्तम्';

  @override
  String get bodyGeofenceOffsetDistance => 'विचालनदूरता';

  @override
  String get tooltipGeofenceReroll => 'पुनर्यादृच्छिकविचालनम्';

  @override
  String get labelGeofenceRandomPreset => 'यादृच्छिकम् (2–5 km)';

  @override
  String bodyGeofenceShiftSummary(String summary) {
    return 'विचालितम् $summary';
  }

  @override
  String bodyGeofenceFuzzedCoordinates(String lat, String lon) {
    return '$lat, $lon प्रति विचालितम्';
  }

  @override
  String get descGeofenceExplanation =>
      '2–5 कि.मी. अन्तरे विचालनं योजयति, येन प्रादेशिकयात्रासन्दर्भः तिष्ठति, निवासमार्गस्य यथार्थस्थानं च गोप्यते।';

  @override
  String get titleGeofenceShare => 'विचालितचित्रवितरणम्';

  @override
  String get actionGeofenceShare => 'विचाल्य वितीर्यताम्';

  @override
  String get actionGeofenceSave => 'विचालितं रक्ष्यताम्';

  @override
  String get bodyGeofenceSavedToGallery =>
      'स्थानविचालितप्रतिलिपिः चित्रशालायां रक्षिता';

  @override
  String get labelGeofenceNoCoordinates => 'स्थानं न प्राप्तम्';

  @override
  String get bodyGeofenceNoCoordinates =>
      'अस्मिन् माध्यमवस्तुनि विचालनाय निहितं GPS स्थानं नास्ति।';

  @override
  String get bodyPrivacyAuditSensitiveDetected =>
      'संवेदनशीलः अधिदत्तांशः प्राप्तः';

  @override
  String get bodyPrivacyAuditClean => 'संवेदनशीलः अधिदत्तांशः न प्राप्तः';

  @override
  String bodyPrivacyAuditSensitiveDetails(String gps, String camera) {
    return 'अन्तर्गतम्: $gps $camera';
  }

  @override
  String get labelPrivacyAuditGps => 'GPS स्थानम्';

  @override
  String get labelPrivacyAuditCamera => 'उपकरणपरिचायकाः';

  @override
  String get bodyPrivacyAuditCleanDetails =>
      'अस्यां सञ्चिकायां निहितं स्थानं छायाग्राहकक्रमाङ्कपरिचायकाः वा न सन्ति।';

  @override
  String get titleForensicInspector => 'काचसंवेदकदत्तांशः';

  @override
  String get descForensicInspectorSubtitle =>
      'गभीराः प्रकाशिक-यन्त्र-सूक्ष्मपरीक्षादृष्टयः';

  @override
  String get actionForensicInspector => 'काचदत्तांशपरीक्षणम्';

  @override
  String get helpForensicInspectorQuickHint =>
      'संवेदककर्तनगुणकः, 35mm तुल्यम्, आवरणप्रवर्तनानि, प्रकाशनपक्षपातः';

  @override
  String get bodyForensicNoData =>
      'अस्मिन् वस्तुनि काचसंवेदक-सूक्ष्माधिदत्तांशः न प्राप्तः।';

  @override
  String get bodyForensicSectionSensorOptics => 'संवेदकः प्रकाशिकगुणाः च';

  @override
  String get bodyForensicSectionMechanicsColor =>
      'यान्त्रिकप्रवर्तनानि वर्णावकाशः च';

  @override
  String get bodyForensicSectionHardwareIdentity => 'यन्त्रकाचक्रमाङ्कपरिचयः';

  @override
  String get labelForensicSensorFormat => 'संवेदकप्रारूपम्';

  @override
  String get labelForensicCropFactor => 'कर्तनगुणकः';

  @override
  String get labelForensicFocal35mm => '35mm तुल्यम्';

  @override
  String get labelForensicPhysicalFocalLength => 'भौतिकनाभ्यन्तरम्';

  @override
  String get labelForensicHyperfocalDistance => 'अतिनाभिदूरता';

  @override
  String get labelForensicExposureBias => 'प्रकाशनपक्षपातः (EV)';

  @override
  String get labelForensicShutterActuations => 'आवरणप्रवर्तनानि';

  @override
  String get bodyForensicShutterNotReported => 'विद्युदावरणम् / न सूचितम्';

  @override
  String get labelForensicColorProfile => 'वर्णावकाशः / रूपरेखा';

  @override
  String get labelForensicExposureProgram => 'प्रकाशनक्रमः';

  @override
  String get labelForensicMeteringMode => 'मापनविधिः';

  @override
  String get labelForensicSensingMethod => 'संवेदनविधिः';

  @override
  String get labelForensicSceneCaptureType => 'दृश्यग्रहणप्रकारः';

  @override
  String get labelForensicFlashStatus => 'प्रकाशस्फुरणस्थितिः';

  @override
  String get labelForensicCameraSerial => 'छायाग्राहकक्रमाङ्कः';

  @override
  String get labelForensicLensModel => 'काचप्रतिरूपम्';

  @override
  String get labelForensicLensSpecification => 'काचविनिर्देशः';

  @override
  String get labelForensicLensSerial => 'काचक्रमाङ्कः';

  @override
  String get bodyForensicSerialNotEmbedded => 'शीर्षेषु न निहितम्';

  @override
  String get tooltipShowPassword => 'गूढशब्दः दर्श्यताम्';

  @override
  String get tooltipHidePassword => 'गूढशब्दः गोप्यताम्';

  @override
  String labelDistanceKm(String distance) {
    return '$distance कि.मी.';
  }

  @override
  String labelCompareBadge(String photo, String name) {
    return '$photo: $name';
  }

  @override
  String get aboutDetailAuthor => 'लेखकः';

  @override
  String get aboutDetailLicense => 'अनुज्ञापत्रम्';

  @override
  String get aboutDetailIdeUsed => 'प्रयुक्तं विकाससाधनम्';

  @override
  String get aboutDetailAiUsed => 'प्रयुक्ता कृत्रिमबुद्धिः';

  @override
  String get aboutDetailStorageModel => 'सङ्ग्रहप्रतिरूपम्';

  @override
  String get aboutDetailNetworkPolicy => 'जालनीतिः';

  @override
  String get aboutDetailSecurity => 'सुरक्षा';

  @override
  String get aboutDetailLanguages => 'भाषाः';

  @override
  String madeWithLove(String heart) {
    return 'सस्नेहं निर्मितम् $heart भारततः';
  }

  @override
  String get madeWithLoveA11y => 'सस्नेहं निर्मितम् भारततः';

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
      other: '$count वारम्',
      one: 'एकवारम्',
    );
    return '$_temp0';
  }

  @override
  String bodyTransferBytesProgress(String done, String total) {
    return '$total मध्ये $done';
  }

  @override
  String bodyPdfImageFormatAndSize(String format, String size) {
    return '$format · $size';
  }

  @override
  String get labelColorRed => 'रक्तम्';

  @override
  String get labelColorPink => 'पाटलम्';

  @override
  String get labelColorPurple => 'नीललोहितम्';

  @override
  String get labelColorDeepPurple => 'गाढनीललोहितम्';

  @override
  String get labelColorIndigo => 'नीलीवर्णम्';

  @override
  String get labelColorBlue => 'नीलम्';

  @override
  String get labelColorTeal => 'हरितनीलम्';

  @override
  String get labelColorGreen => 'हरितम्';

  @override
  String get labelColorLightGreen => 'मृदुहरितम्';

  @override
  String get labelColorAmber => 'पिङ्गलम्';

  @override
  String get labelColorDeepOrange => 'गाढनारङ्गम्';

  @override
  String get labelColorBrown => 'कपिशम्';

  @override
  String get labelColorYellow => 'पीतम्';

  @override
  String get labelColorWhite => 'श्वेतम्';

  @override
  String get labelColorBlack => 'कृष्णम्';

  @override
  String get labelA11yCropArea => 'कर्तनक्षेत्रम्';

  @override
  String bodyA11yCropAreaValue(int left, int top, int width, int height) {
    return 'वामतः $left%, उपरि $top%, विस्तारः $width%, उच्चता $height%';
  }

  @override
  String get helpA11yCropAreaHint =>
      'कोणाः कृष्यन्ताम्, अथवा चालनाय परिमाणपरिवर्तनाय च क्रियाः उपयुज्यन्ताम्।';

  @override
  String get labelA11yMoveLeft => 'वामतः चाल्यताम्';

  @override
  String get labelA11yMoveRight => 'दक्षिणतः चाल्यताम्';

  @override
  String get labelA11yMoveUp => 'उपरि चाल्यताम्';

  @override
  String get labelA11yMoveDown => 'अधः चाल्यताम्';

  @override
  String get labelA11yMakeSmaller => 'लघूक्रियताम्';

  @override
  String get labelA11yMakeLarger => 'बृहत्क्रियताम्';

  @override
  String get labelA11yCurveArea => 'वर्णवक्ररेखा';

  @override
  String bodyA11yCurveValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count बिन्दवः',
      one: 'एकः बिन्दुः',
    );
    return '$_temp0';
  }

  @override
  String get labelA11yMarkupArea => 'अङ्कनक्षेत्रम्';

  @override
  String bodyA11yMarkupValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count चिह्नानि',
      one: 'एकं चिह्नम्',
      zero: 'किमपि न अङ्कितम्',
    );
    return '$_temp0';
  }

  @override
  String get helpA11yDrawingNeedsTouchHint =>
      'अङ्कनाय स्पर्शः आवश्यकः। चिह्नानि परिवर्तयितुम् अपनेतुं वा अधःस्थं फलकम् उपयुज्यताम्।';

  @override
  String get labelA11yRedactionArea => 'गोपनक्षेत्रम्';

  @override
  String bodyA11yRedactionValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count क्षेत्राणि गोपितानि',
      one: 'एकं क्षेत्रं गोपितम्',
      zero: 'किमपि न गोपितम्',
    );
    return '$_temp0';
  }

  @override
  String get labelA11yMaskArea => 'आवरणस्थानम्';

  @override
  String bodyA11yMaskValue(String shape, int x, int y) {
    return '$shape, मध्यं $x% तिर्यक्, $y% अधः';
  }

  @override
  String get helpA11yMaskHint =>
      'ग्रहणानि कृष्यन्ताम्, अथवा आवरणं चालयितुं क्रियाः उपयुज्यन्ताम्।';

  @override
  String get labelA11yCompareDivider => 'तुलनाविभाजिका';

  @override
  String bodyA11yPercentValue(int percent) {
    return '$percent%';
  }

  @override
  String get errorOpenWithRefused =>
      'इयं सञ्चिका अत्र उद्घाटयितुं न शक्यते। तस्य स्थाने चित्रशालातः उद्घाट्यताम्।';

  @override
  String get errorOpenWithFailed =>
      'सञ्चिका उद्घाटयितुं न अशक्यत। सा स्थानान्तरिता अपनीता वा स्यात्।';

  @override
  String get bodyCleanerFailed =>
      'चित्राणां तुलनायां काचित् त्रुटिः अभवत्। पुनः प्रयत्यताम्।';

  @override
  String get aboutDetailEmail => 'विद्युत्पत्रम्';

  @override
  String get aboutDetailPrivacyPolicy => 'गोपनीयतानीतिः';

  @override
  String get titleSettingsProtectScreens => 'विषयो गोप्यताम्';

  @override
  String get descSettingsProtectScreens =>
      'सर्वेषु पटलेषु पटलचित्राणि पटलमुद्रणं च निरुध्येते, सद्यःप्रयुक्तेषु च रिक्तं पत्रं दर्श्यते। गुप्तकोशः सर्वदा रक्षितः।';

  @override
  String get titleSettingsPermissions => 'अनुमतयः';

  @override
  String get descSettingsPermissionsSubtitle =>
      'अनुप्रयोगः किं किं प्रयुङ्क्ते, किमर्थं च';

  @override
  String get labelPermissionsExplicit => 'भवता अनुमताः';

  @override
  String get labelPermissionsImplicit => 'स्वतः प्रदत्ताः';

  @override
  String get labelPermissionsRemoved => 'सङ्कल्पेन निरस्ताः';

  @override
  String get descPermissionsExplicit =>
      'एतासां प्रयोगात् पूर्वम् Android भवन्तं पृच्छति। Android-विन्यासे एताः कदापि परिवर्तयितुं शक्यन्ते।';

  @override
  String get descPermissionsImplicit =>
      'अनुप्रयोगस्य स्थापनकाले Android अपृष्ट्वा एव एताः ददाति। एताभिः भवतः चित्राणि सञ्चिकाः वा न प्राप्यन्ते।';

  @override
  String get descPermissionsRemoved =>
      'अनुप्रयोगनिर्माणे प्रयुक्तानि कानिचित् सहायकतन्त्राणि एताः याचन्ते। अनुप्रयोगः एताः निरस्यति, अतः ताः कदापि न धारयति।';

  @override
  String get descPermissionsManage =>
      'अनुमतीः परिवर्तयितुम् Android-विन्यासे अस्य अनुप्रयोगस्य पत्रम् उद्घाट्यताम्।';

  @override
  String get labelPermPhotosVideos => 'चित्राणि दृश्यानि च';

  @override
  String get labelPermCamera => 'छायाग्राहकः';

  @override
  String get labelPermBiometric => 'अङ्गुलिमुद्रा';

  @override
  String get labelPermNetwork => 'स्थानीयजालम्';

  @override
  String get labelPermWifiState => 'Wi-Fi विवरणम्';

  @override
  String get labelPermNetworkState => 'जालस्थितिः';

  @override
  String get labelPermChangeWifi => 'Wi-Fi प्रस्तावाः';

  @override
  String get labelPermReceiverPrivate => 'आन्तरिकसन्देशाः';

  @override
  String get labelPermWakeLock => 'यन्त्रजागरणम्';

  @override
  String get labelPermRecordAudio => 'ध्वनिमुद्रणम्';

  @override
  String get labelPermWriteStorage => 'सङ्ग्रहलेखनम्';

  @override
  String get descPermPhotosVideos =>
      'अस्मिन् दूरवाणीयन्त्रे स्थितानि चित्राणि दृश्यानि च दर्शयितुम्। Android 14 आरभ्य भवता चितानि एव अनुमन्तुं शक्यन्ते।';

  @override
  String get descPermCamera =>
      'केवलं स्थानान्तरणपटले युग्मन-QR-सङ्केतस्य पठनाय। अनुप्रयोगः कदापि चित्रं न गृह्णाति।';

  @override
  String get descPermBiometric =>
      'अङ्गुलिमुद्रया गुप्तकोशस्य उद्घाटनाय। भवतः PIN अपि सर्वदा कार्यं करोति।';

  @override
  String get descPermNetwork =>
      'केवलं स्थानान्तरणपटलेन, भवतः स्वकीये Wi-Fi जाले अन्यद् दूरवाणीयन्त्रं प्राप्तुं प्रयुज्यते। अनुप्रयोगः कदापि अन्तर्जालं न गच्छति।';

  @override
  String get descPermWifiState =>
      'युग्मनसङ्केतस्य निर्माणाय अस्य दूरवाणीयन्त्रस्य स्वकीयः Wi-Fi सङ्केतस्थानं पठ्यते।';

  @override
  String get descPermNetworkState =>
      'स्थानीयस्थानान्तरणवर्गस्य भागः। अनुप्रयोगः अन्तर्जालं गन्तुम् एतां न प्रयुङ्क्ते।';

  @override
  String get descPermChangeWifi =>
      'भवता पठितः Wi-Fi सङ्केतः Android प्रति प्रस्तूयते। जालं भवान् एव चिनोति।';

  @override
  String get descPermReceiverPrivate =>
      'Android-सहायकतन्त्रेण योजिता। अनुप्रयोगस्य आन्तरिकसन्देशान् गोपयति, किमपि अन्यत् न प्रापयति।';

  @override
  String get descPermWakeLock =>
      'दृश्यवादकं प्रवाहार्थम् एतां याचते। अनुप्रयोगः अस्मिन् यन्त्रे स्थिताः सञ्चिकाः एव वादयति।';

  @override
  String get descPermRecordAudio =>
      'छायाग्राहकसहायकतन्त्रम् एतां याचते। QR-पाठकः कदापि ध्वनिं न मुद्रयति।';

  @override
  String get descPermWriteStorage =>
      'Android 9 तथा पूर्वतनेषु एव। चित्राणि सर्वथा सुरक्षितं वा लोप्तुं शक्यते। चित्रानुमत्या सह पृच्छ्यते।';

  @override
  String get labelPermissionsSpecial => 'भवता सक्रियीकृताः';

  @override
  String get descPermissionsSpecial =>
      'Android एताः कदापि न पृच्छति। Android-विन्यासे भवता स्वयं यावत् न सक्रियीक्रियन्ते, तावत् एताः निष्क्रियाः तिष्ठन्ति।';

  @override
  String get labelPermManageMedia => 'माध्यमप्रबन्धनम्';

  @override
  String get descPermManageMedia =>
      'Android 12 आरभ्य एव। भवता सक्रियीकृते एव प्रवर्तते। Android-स्य स्वप्रश्नं विना चित्राणि लोप्तुम् अनुप्रयोगाय अनुमतिं ददाति; तदा अनुप्रयोगः स्वयम् एकवारं पृच्छति।';

  @override
  String get descManageMediaSubtitle =>
      'Android 12 आरभ्य। सक्रिये सति प्रत्येकस्मात् सर्वथा-लोपात् पूर्वम् Android न पृच्छति; तस्य स्थाने अनुप्रयोगः एकवारं पृच्छति। Android-विन्यासे परिवर्तयितुं स्पृश्यताम्।';

  @override
  String get titleManageMediaPrompt => 'माध्यमप्रबन्धनम् अनुमन्यताम् किम्?';

  @override
  String get bodyManageMediaPrompt =>
      'प्रत्येकस्मात् सर्वथा-लोपात् पूर्वम् Android पुनः पृच्छति। अस्य अनुप्रयोगस्य कृते \"माध्यमप्रबन्धनम्\" सक्रियीक्रियताम्, तदा तस्य स्थाने अनुप्रयोगः स्वयम् एकवारं पृच्छति। पश्चात् विन्यासः → सुरक्षितता इत्यत्र एतत् परिवर्तयितुं शक्यते।';

  @override
  String get actionNotNow => 'इदानीं न';

  @override
  String get labelPermAllowed => 'अनुमतम्';

  @override
  String get labelPermSelectedOnly => 'चितानि एव';

  @override
  String get labelPermNotAllowed => 'न अनुमतम्';

  @override
  String labelPermAndroidFrom(String version) {
    return 'Android $version आरभ्य';
  }

  @override
  String labelPermAndroidUpTo(String version) {
    return 'Android $version पर्यन्तम्';
  }

  @override
  String get titleVaultFolderMissing => 'संपुटं न लब्धम्';

  @override
  String bodyVaultFolderMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count वस्तूनां पूर्वसंपुटम् इदानीं नास्ति। तेभ्यः संपुटं चीयताम्, अथवा त्यज्यन्ताम्; तानि गुप्तकोशे एव तिष्ठन्ति।',
      one:
          '1 वस्तुनः पूर्वसंपुटम् इदानीं नास्ति। तस्मै संपुटं चीयताम्, अथवा त्यज्यताम्; तत् गुप्तकोशे एव तिष्ठति।',
    );
    return '$_temp0';
  }

  @override
  String get actionVaultChooseFolder => 'संपुटं चीयताम्';

  @override
  String get actionVaultSkip => 'त्यज्यताम्';

  @override
  String bodyVaultRestoreSkipped(int done, int skipped) {
    return '$done पुनःस्थापितानि, $skipped गुप्तकोशे एव';
  }

  @override
  String bodyVaultRestoreSkippedFailed(int done, int skipped, int failed) {
    return '$done पुनःस्थापितानि, $skipped गुप्तकोशे एव, $failed विफलानि';
  }

  @override
  String get titleBatchActionDelete => 'लुप्यताम्';

  @override
  String titleDeleteChoice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'किम् $count वस्तूनि लोप्तव्यानि?',
      one: 'किम् 1 वस्तु लोप्तव्यम्?',
    );
    return '$_temp0';
  }

  @override
  String bodyDeleteChoiceTrash(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'अवकरपात्रात् पुनः प्राप्तुं शक्यते।',
      one: 'अवकरपात्रात् पुनः प्राप्तुं शक्यते।',
    );
    return '$_temp0';
  }

  @override
  String get bodyDeleteChoicePermanent =>
      'उपकरणात् सर्वथा लोप्स्यते। इदं प्रत्यावर्तयितुं न शक्यते।';

  @override
  String get bodyDeleteChoicePermanentSecure =>
      'प्रथमम् अधिलिख्य, ततः उपकरणात् सर्वथा लोप्स्यते। इदं प्रत्यावर्तयितुं न शक्यते।';

  @override
  String bodyDeletePermanentlyConfirmCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count वस्तूनि उपकरणात् सर्वथा लोप्स्यन्ते। इदं प्रत्यावर्तयितुं न शक्यते।',
      one: '1 वस्तु उपकरणात् सर्वथा लोप्स्यते। इदं प्रत्यावर्तयितुं न शक्यते।',
    );
    return '$_temp0';
  }

  @override
  String get bodyDeleteNothingDeleted => 'किमपि न लुप्तम्।';

  @override
  String bodyDeletedPermanentlyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count वस्तूनि सर्वथा लुप्तानि।',
      one: '1 वस्तु सर्वथा लुप्तम्।',
    );
    return '$_temp0';
  }

  @override
  String bodySecureDeletedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count वस्तूनि अधिलिख्य सर्वथा लुप्तानि।',
      one: '1 वस्तु अधिलिख्य सर्वथा लुप्तम्।',
    );
    return '$_temp0';
  }

  @override
  String bodySecureDeleteNotOverwritten(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'तेषु $count प्रथमम् अधिलेखितुं न शक्तानि।',
      one: 'तेषु 1 प्रथमम् अधिलेखितुं न शक्तम्।',
    );
    return '$_temp0';
  }

  @override
  String bodyDeleteFailedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count वस्तूनि लोप्तुं न शक्तानि।',
      one: '1 वस्तु लोप्तुं न शक्तम्।',
    );
    return '$_temp0';
  }

  @override
  String get titleSecureDelete => 'सुरक्षितलोपः';

  @override
  String get descSecureDeleteSubtitle =>
      'लोपात् पूर्वं प्रत्येकं सञ्चिका अधिलिख्यते, अतः पुनःप्राप्तिसाधनानि ताम् आनेतुं न शक्नुवन्ति। सर्वथा-लोपे अवकरपात्रात् लोपे च प्रयुज्यते। प्रथमम् Android अनुमतिं पृच्छति। विद्युत्स्मृतौ एतत् पुनःप्राप्तिसाधनानि निवारयति, न तु प्रयोगशालाम्।';

  @override
  String get bodySecureDeleteVaultNote =>
      'अयं विकल्पः यथा अपि स्यात्, गुप्तकोशात् लोपः सदा सुरक्षितः।';

  @override
  String bodyBatchTrashSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count वस्तूनि अवकरपात्रं नीतानि',
      one: '1 वस्तु अवकरपात्रं नीतम्',
    );
    return '$_temp0';
  }

  @override
  String get titleDeviceSync => 'उपकरणसमन्वयः';

  @override
  String get descDeviceSyncSubtitle =>
      'अनुप्रयोगदत्तांशं चित्राणि वा अन्यद् दूरवाणीयन्त्रं प्रति प्रतिलिख्यताम्';

  @override
  String get bodyDeviceSyncIntro =>
      'अस्य अनुप्रयोगस्य दत्तांशः, तेन सह भवतः चित्राणि वा, अनेन अनुप्रयोगेण युक्तम् अन्यद् दूरवाणीयन्त्रं प्रति प्रतिलिख्यन्ताम्। किमपि अन्तर्जालं न गच्छति, उभयोः यन्त्रयोः किमपि न अपनीयते।';

  @override
  String get labelDeviceSyncQrSend => 'QR द्वारा अनुप्रयोगदत्तांशः प्रेष्यताम्';

  @override
  String get bodyDeviceSyncQrSend =>
      'चिह्नानि, सङ्कलनानि, प्रियाणि, टिप्पण्यः, स्थानानि च। चित्राणि न, Wi-Fi अपि न आवश्यकम्। अन्यस्मिन् यन्त्रे तान्येव चित्राणि पूर्वमेव भवेयुः।';

  @override
  String get labelDeviceSyncWifiSend => 'नूतनयन्त्रं प्रति स्थानान्तरणम्';

  @override
  String get bodyDeviceSyncWifiSend =>
      'भवता चितानि संपुटानि सङ्कलनानि च, सर्वेण अनुप्रयोगदत्तांशेन विन्यासेन च सह। इच्छया गुप्तकोशः अपि। उभे यन्त्रे समाने Wi-Fi जाले।';

  @override
  String get labelDeviceSyncQrReceive =>
      'QR द्वारा अनुप्रयोगदत्तांशः स्वीक्रियताम्';

  @override
  String get bodyDeviceSyncQrReceive =>
      'एकः सङ्केतः दर्श्यताम्, ततः अन्यस्य यन्त्रस्य सङ्केताः अन्वीक्ष्यन्ताम्';

  @override
  String get labelDeviceSyncWifiReceive => 'पुरातनयन्त्रात् प्राप्यताम्';

  @override
  String get titleSyncPick => 'किं प्रेषणीयमिति चीयताम्';

  @override
  String get labelSyncSelectionSource => 'चितानि चित्राणि';

  @override
  String get labelSyncFoldersSection => 'संपुटानि';

  @override
  String get labelSyncAlbumsSection => 'सङ्कलनानि';

  @override
  String bodySyncSourceStats(String size, int sent, int count) {
    return '$size · $count मध्ये $sent प्रेषितानि';
  }

  @override
  String bodySyncPeerFreeSpace(String name, String size) {
    return '$name इत्यत्र रिक्तस्थानम्: $size';
  }

  @override
  String bodySyncPlanThisSend(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'अस्मिन् प्रेषणे: $count सञ्चिकाः, $size',
      one: 'अस्मिन् प्रेषणे: 1 सञ्चिका, $size',
    );
    return '$_temp0';
  }

  @override
  String bodySyncPlanLeft(int count, String size) {
    return 'अग्रिमप्रेषणाय शिष्टाः: $count सञ्चिकाः, $size';
  }

  @override
  String bodySyncPlanAlreadySent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'अन्यस्मिन् यन्त्रे पूर्वमेव: $count सञ्चिकाः',
      one: 'अन्यस्मिन् यन्त्रे पूर्वमेव: 1 सञ्चिका',
    );
    return '$_temp0';
  }

  @override
  String bodySyncPlanResend(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'एतद् यन्त्रं प्रति पूर्वं प्रेषितानि: $count सञ्चिकाः। ताः पुनः प्रेष्यन्ते।',
      one: 'एतद् यन्त्रं प्रति पूर्वं प्रेषितम्: 1 सञ्चिका। सा पुनः प्रेष्यते।',
    );
    return '$_temp0';
  }

  @override
  String bodySyncLimitCap(String size) {
    return 'एकस्मिन् प्रेषणे $size पर्यन्तमेव। शेषम् अनन्तरं प्रेष्यताम्।';
  }

  @override
  String get bodySyncLimitSpace =>
      'अन्यस्मिन् यन्त्रे स्थानम् अल्पम्। अधिकं प्रेषयितुं तत्र स्थानं रिक्तीक्रियताम्।';

  @override
  String bodySyncLimitCount(int count) {
    return 'एकस्मिन् प्रेषणे $count सञ्चिकाः पर्यन्तम्।';
  }

  @override
  String get bodySyncAllSent =>
      'सर्वं प्रेषितम्। अधिकं प्रेषयितुं चीयताम्, अथवा समाप्यताम् इति स्पृश्यताम्।';

  @override
  String get bodySyncPickSomething =>
      'प्रेषणाय संपुटानि सङ्कलनानि वा चीयन्ताम्।';

  @override
  String get actionSyncSendRest => 'शेषं प्रेष्यताम्';

  @override
  String get actionSyncFinish => 'समाप्यताम्';

  @override
  String get labelSyncPreparing => 'सञ्चिकाः सज्जीक्रियन्ते';

  @override
  String get labelSyncBatchDone => 'इदं प्रेषणं समाप्तम्';

  @override
  String get bodySyncWaitingForSend =>
      'सम्बद्धम्। अन्यद् यन्त्रं प्रेषयिष्यतीति प्रतीक्ष्यते।';

  @override
  String get bodySyncErrorNoSpace =>
      'एकस्मिन् यन्त्रे रिक्तस्थानं समाप्तम्। प्राप्ताः सञ्चिकाः रक्षिताः।';

  @override
  String get bodySyncSavedToFolder =>
      'प्राप्ताः सञ्चिकाः Pictures › Drishya Sync इत्यत्र सन्ति।';

  @override
  String get errorSyncSourcesLoad =>
      'भवतः संपुटानि सङ्कलनानि च पठितुं न शक्तानि।';

  @override
  String get titleQrSyncSend => 'QR द्वारा प्रेषणम्';

  @override
  String get titleQrSyncReceive => 'QR द्वारा स्वीकरणम्';

  @override
  String get bodyQrSyncScanKey => 'अन्यस्य यन्त्रस्य सङ्केतः अन्वीक्ष्यताम्';

  @override
  String get bodyQrSyncShowKey =>
      'प्रथमं सोपानम्: अन्यस्मिन् यन्त्रे अयं सङ्केतः अन्वीक्ष्यताम्। ततः अग्रिमम् इति स्पृश्यताम्।';

  @override
  String get actionQrSyncNext => 'अग्रिमम्';

  @override
  String get bodyQrSyncScanFrames =>
      'द्वितीयं सोपानम्: अन्यस्मिन् यन्त्रे परिवर्तमानान् सङ्केतान् प्रति छायाग्राहकः निर्दिश्यताम्।';

  @override
  String bodyQrSyncFramesProgress(int done, int total) {
    return '$total मध्ये $done सङ्केताः पठिताः';
  }

  @override
  String get bodyQrSyncShowFrames =>
      'अन्यद् यन्त्रं समाप्तम् इति यावत् दर्शयति तावत् इदं पटलं तस्य छायाग्राहकस्य पुरतः धार्यताम्।';

  @override
  String bodyQrSyncFrameCount(int count) {
    return '$count सङ्केताः पुनः पुनः दर्श्यन्ते';
  }

  @override
  String errorQrSyncTooBig(int count) {
    return 'QR कृते दत्तांशः अत्यधिकः ($count सङ्केताः)। तस्य स्थाने Wi-Fi उपयुज्यताम्।';
  }

  @override
  String get bodyQrSyncNothing => 'प्रेषणाय अनुप्रयोगदत्तांशः अद्यापि नास्ति।';

  @override
  String get errorQrSyncFailed =>
      'दत्तांशः पठितुं न शक्तः। उभयोः यन्त्रयोः पुनः आरभ्यताम्।';

  @override
  String get labelQrSyncPreparing => 'दत्तांशः सज्जीक्रियते';

  @override
  String get actionSyncScanAnother => 'अन्यः सङ्केतोऽन्वीक्ष्यताम्';

  @override
  String get actionSyncShowNewCode => 'नूतनः सङ्केतः दर्श्यताम्';

  @override
  String get actionSyncClose => 'पिधीयताम्';
}
