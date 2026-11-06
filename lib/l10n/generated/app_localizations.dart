import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_sa.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ml'),
    Locale('sa'),
  ];

  /// The title of the gallery application
  ///
  /// In en, this message translates to:
  /// **'SreerajP Gallery'**
  String get titleApp;

  /// Banner text indicating the development flavor
  ///
  /// In en, this message translates to:
  /// **'DEV BUILD'**
  String get labelDevBanner;

  /// Title of the settings screen or section
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get titleSettings;

  /// Title of the about screen or section
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get titleAbout;

  /// Theme selection header
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get labelTheme;

  /// System default theme option
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get actionThemeSystem;

  /// Light theme option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get actionThemeLight;

  /// Dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get actionThemeDark;

  /// AMOLED true black theme option
  ///
  /// In en, this message translates to:
  /// **'AMOLED True Black'**
  String get actionThemeAmoled;

  /// Label for application version
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get titleVersion;

  /// Title shown when media permission has not been granted
  ///
  /// In en, this message translates to:
  /// **'Media access needed'**
  String get labelPermissionRequired;

  /// Explanation of why the app needs media permission
  ///
  /// In en, this message translates to:
  /// **'Allow access to your photos and videos so the gallery can show them. Nothing ever leaves your device.'**
  String get bodyPermissionRequired;

  /// Button that opens the system media permission dialog
  ///
  /// In en, this message translates to:
  /// **'Allow access'**
  String get labelGrantPermission;

  /// Button that opens app settings when permission was permanently denied
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get labelOpenSettings;

  /// Notice shown when the user granted partial photo access
  ///
  /// In en, this message translates to:
  /// **'Only selected media is visible. Allow all media to see everything.'**
  String get bodyPermissionPartial;

  /// Button that starts scanning the device for media
  ///
  /// In en, this message translates to:
  /// **'Scan device media'**
  String get labelScanMedia;

  /// Status text shown while the media scan runs
  ///
  /// In en, this message translates to:
  /// **'Scanning media...'**
  String get bodyScanningMedia;

  /// Live count of scanned media items
  ///
  /// In en, this message translates to:
  /// **'{scanned} of {total} scanned'**
  String bodyScanProgress(int scanned, int total);

  /// Message shown when a media scan finishes
  ///
  /// In en, this message translates to:
  /// **'Scan complete: {count} items indexed'**
  String bodyScanComplete(int count);

  /// Message shown when a media scan could not finish
  ///
  /// In en, this message translates to:
  /// **'Media scan failed'**
  String get errorScanFailed;

  /// Number of media items currently stored in the local index
  ///
  /// In en, this message translates to:
  /// **'Indexed items: {count}'**
  String bodyIndexedItems(int count);

  /// Empty state shown when the device has no readable media
  ///
  /// In en, this message translates to:
  /// **'No photos or videos found'**
  String get bodyNoMediaFound;

  /// Placeholder label when a thumbnail cannot be generated
  ///
  /// In en, this message translates to:
  /// **'Preview unavailable'**
  String get labelMediaUnavailable;

  /// Date header shown above media captured today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get labelTimelineToday;

  /// Date header shown above media captured yesterday
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get labelTimelineYesterday;

  /// Title of the main chronological timeline screen
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get titleTimeline;

  /// Empty state shown when no media has been indexed yet
  ///
  /// In en, this message translates to:
  /// **'Your gallery is empty'**
  String get bodyNoMediaInTimeline;

  /// Hint telling the user that pull-to-refresh starts a media scan
  ///
  /// In en, this message translates to:
  /// **'Pull down to scan for new photos and videos.'**
  String get bodyPullToScan;

  /// Title of the flashback memories carousel
  ///
  /// In en, this message translates to:
  /// **'On This Day'**
  String get titleFlashback;

  /// Caption for a flashback memory from exactly one year ago
  ///
  /// In en, this message translates to:
  /// **'1 year ago'**
  String get labelFlashbackOneYearAgo;

  /// Caption for a flashback memory from several years ago
  ///
  /// In en, this message translates to:
  /// **'{years} years ago'**
  String bodyFlashbackYearsAgo(int years);

  /// Announces the current grid density after a pinch gesture
  ///
  /// In en, this message translates to:
  /// **'{count} per row'**
  String bodyGridColumns(int count);

  /// Badge marking an animated GIF tile
  ///
  /// In en, this message translates to:
  /// **'GIF'**
  String get labelBadgeGif;

  /// Badge marking a RAW camera image tile
  ///
  /// In en, this message translates to:
  /// **'RAW'**
  String get labelBadgeRaw;

  /// Badge marking a high resolution media tile
  ///
  /// In en, this message translates to:
  /// **'HD'**
  String get labelBadgeHd;

  /// Accessibility label for the duration pill on a video tile
  ///
  /// In en, this message translates to:
  /// **'Video, {duration}'**
  String labelBadgeVideoDuration(String duration);

  /// Accessibility label for the fast scroll scrubber handle
  ///
  /// In en, this message translates to:
  /// **'Scroll to date'**
  String get labelScrollToDate;

  /// Tooltip for the button that closes the fullscreen viewer
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get tooltipViewerClose;

  /// Tooltip for rotating the photo 90 degrees anticlockwise
  ///
  /// In en, this message translates to:
  /// **'Rotate left'**
  String get labelViewerRotateLeft;

  /// Tooltip for rotating the photo 90 degrees clockwise
  ///
  /// In en, this message translates to:
  /// **'Rotate right'**
  String get labelViewerRotateRight;

  /// Tooltip for marking the open item as a favorite
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get labelViewerAddFavorite;

  /// Tooltip for removing the favorite mark
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get bodyViewerRemoveFavorite;

  /// Tooltip for the play button of the video player
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get actionPlay;

  /// Tooltip for the pause button of the video player
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get actionPause;

  /// Tooltip for stepping the video one frame forward
  ///
  /// In en, this message translates to:
  /// **'Next frame'**
  String get tooltipFrameForward;

  /// Tooltip for stepping the video one frame back
  ///
  /// In en, this message translates to:
  /// **'Previous frame'**
  String get tooltipFrameBackward;

  /// Tooltip for skipping the video forward
  ///
  /// In en, this message translates to:
  /// **'Forward 10 seconds'**
  String get tooltipSkipForward;

  /// Tooltip for skipping the video back
  ///
  /// In en, this message translates to:
  /// **'Back 10 seconds'**
  String get tooltipSkipBackward;

  /// Tooltip for turning repeat playback on or off
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get tooltipLoopPlayback;

  /// Tooltip for the playback speed menu
  ///
  /// In en, this message translates to:
  /// **'Playback speed'**
  String get tooltipPlaybackSpeed;

  /// Message shown when a video file cannot be opened
  ///
  /// In en, this message translates to:
  /// **'This video cannot be played.'**
  String get bodyVideoCannotPlay;

  /// Message shown when the device has no decoder for the video
  ///
  /// In en, this message translates to:
  /// **'This device cannot play this video format.'**
  String get bodyVideoFormatUnsupported;

  /// Title of the media details drawer
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get tooltipDetailsTitle;

  /// Label for the file name row in the details drawer
  ///
  /// In en, this message translates to:
  /// **'File name'**
  String get labelDetailsFileName;

  /// Label for the file format row in the details drawer
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get labelDetailsFormat;

  /// Label for the file size row in the details drawer
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get labelDetailsSize;

  /// Label for the pixel width and height row
  ///
  /// In en, this message translates to:
  /// **'Dimensions'**
  String get labelDetailsDimensions;

  /// Label for the video length row
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get labelDetailsDuration;

  /// Label for the capture date row
  ///
  /// In en, this message translates to:
  /// **'Date taken'**
  String get labelDetailsDateTaken;

  /// Label for the last modified date row
  ///
  /// In en, this message translates to:
  /// **'Last modified'**
  String get labelDetailsDateModified;

  /// Label for the folder path row
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get labelDetailsFolder;

  /// Heading of the EXIF section in the details drawer
  ///
  /// In en, this message translates to:
  /// **'Camera and metadata'**
  String get labelDetailsCameraSection;

  /// Shown when a file carries no readable EXIF data
  ///
  /// In en, this message translates to:
  /// **'No camera metadata was found in this file.'**
  String get bodyDetailsNoMetadata;

  /// Label for the camera make and model row
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get labelDetailsCamera;

  /// Label for the lens model row
  ///
  /// In en, this message translates to:
  /// **'Lens'**
  String get labelDetailsLens;

  /// Label for the aperture f-number row
  ///
  /// In en, this message translates to:
  /// **'Aperture'**
  String get labelDetailsAperture;

  /// Label for the shutter speed row
  ///
  /// In en, this message translates to:
  /// **'Shutter'**
  String get labelDetailsShutter;

  /// Label for the ISO sensitivity row
  ///
  /// In en, this message translates to:
  /// **'ISO'**
  String get labelDetailsIso;

  /// Label for the focal length row
  ///
  /// In en, this message translates to:
  /// **'Focal length'**
  String get labelDetailsFocalLength;

  /// Label for the flash state row
  ///
  /// In en, this message translates to:
  /// **'Flash'**
  String get labelDetailsFlash;

  /// Label for the white balance row
  ///
  /// In en, this message translates to:
  /// **'White balance'**
  String get labelDetailsWhiteBalance;

  /// Label for the metering mode row
  ///
  /// In en, this message translates to:
  /// **'Metering mode'**
  String get labelDetailsMeteringMode;

  /// Label for the color space row
  ///
  /// In en, this message translates to:
  /// **'Color space'**
  String get labelDetailsColorSpace;

  /// Label for the processing software row
  ///
  /// In en, this message translates to:
  /// **'Software'**
  String get labelDetailsSoftware;

  /// Label for the GPS coordinates row
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get labelDetailsLocation;

  /// Label for the GPS altitude row
  ///
  /// In en, this message translates to:
  /// **'Altitude'**
  String get labelDetailsAltitude;

  /// Title of the image editor screen
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get titleEditor;

  /// Viewer button that opens the image editor
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get titleEditorOpen;

  /// Button that writes the edit as a new file
  ///
  /// In en, this message translates to:
  /// **'Save copy'**
  String get labelEditorSave;

  /// Shown while the edited copy is being written
  ///
  /// In en, this message translates to:
  /// **'Saving a copy...'**
  String get bodyEditorSaving;

  /// Message shown after an edited copy is written
  ///
  /// In en, this message translates to:
  /// **'Saved a copy: {fileName}'**
  String bodyEditorSaved(String fileName);

  /// Message shown when writing the edited copy failed
  ///
  /// In en, this message translates to:
  /// **'The copy could not be saved'**
  String get errorEditorSaveFailed;

  /// Reassurance shown next to the saved message
  ///
  /// In en, this message translates to:
  /// **'Your original photo was not changed'**
  String get bodyEditorOriginalKept;

  /// Shown when the file cannot be decoded or is too large
  ///
  /// In en, this message translates to:
  /// **'This photo cannot be edited'**
  String get bodyEditorCannotOpen;

  /// Shown when the file is above the editable size limit
  ///
  /// In en, this message translates to:
  /// **'This photo is too large to edit on this device'**
  String get bodyEditorTooLarge;

  /// Shown when a preview render fails
  ///
  /// In en, this message translates to:
  /// **'The preview could not be drawn'**
  String get errorEditorPreviewFailed;

  /// Button that steps one edit back
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get tooltipEditorUndo;

  /// Button that puts back an undone edit
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get tooltipEditorRedo;

  /// Button that clears every edit
  ///
  /// In en, this message translates to:
  /// **'Reset all'**
  String get tooltipEditorResetAll;

  /// Title of the dialog shown when leaving with unsaved edits
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get titleEditorDiscard;

  /// Body of the discard dialog
  ///
  /// In en, this message translates to:
  /// **'Your edits have not been saved. Leaving now will lose them.'**
  String get bodyEditorDiscardMessage;

  /// Button that leaves the editor and loses the edits
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get actionEditorDiscard;

  /// Button that stays in the editor
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get actionEditorKeepEditing;

  /// Name of the crop and rotate tool
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get labelEditorToolCrop;

  /// Name of the light and colour tool
  ///
  /// In en, this message translates to:
  /// **'Tune'**
  String get labelEditorToolTune;

  /// Name of the selective gradient and radial masks tool
  ///
  /// In en, this message translates to:
  /// **'Masks'**
  String get labelEditorToolMasks;

  /// Name of the filter preset tool
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get labelEditorToolFilters;

  /// Name of the drawing and text tool
  ///
  /// In en, this message translates to:
  /// **'Markup'**
  String get labelEditorToolMarkup;

  /// Name of the privacy redaction tool
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get labelEditorToolRedact;

  /// Name of the watermark tool
  ///
  /// In en, this message translates to:
  /// **'Watermark'**
  String get labelEditorToolWatermark;

  /// Crop shape that can be dragged to any size
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get labelCropAspectFree;

  /// Crop shape matching the photo's own shape
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get labelCropAspectOriginal;

  /// Square crop shape
  ///
  /// In en, this message translates to:
  /// **'Square'**
  String get labelCropAspectSquare;

  /// Four by three crop shape
  ///
  /// In en, this message translates to:
  /// **'4:3'**
  String get labelCropAspect4x3;

  /// Three by four crop shape
  ///
  /// In en, this message translates to:
  /// **'3:4'**
  String get labelCropAspect3x4;

  /// Sixteen by nine crop shape
  ///
  /// In en, this message translates to:
  /// **'16:9'**
  String get labelCropAspect16x9;

  /// Nine by sixteen crop shape
  ///
  /// In en, this message translates to:
  /// **'9:16'**
  String get labelCropAspect9x16;

  /// Three by two crop shape
  ///
  /// In en, this message translates to:
  /// **'3:2'**
  String get labelCropAspect3x2;

  /// Two by three crop shape
  ///
  /// In en, this message translates to:
  /// **'2:3'**
  String get labelCropAspect2x3;

  /// Button that turns the photo a quarter turn anticlockwise
  ///
  /// In en, this message translates to:
  /// **'Rotate left'**
  String get tooltipCropRotateLeft;

  /// Button that turns the photo a quarter turn clockwise
  ///
  /// In en, this message translates to:
  /// **'Rotate right'**
  String get tooltipCropRotateRight;

  /// Button that mirrors the photo left to right
  ///
  /// In en, this message translates to:
  /// **'Mirror sideways'**
  String get tooltipCropFlipHorizontal;

  /// Button that mirrors the photo top to bottom
  ///
  /// In en, this message translates to:
  /// **'Mirror upside down'**
  String get tooltipCropFlipVertical;

  /// Label of the fine levelling slider
  ///
  /// In en, this message translates to:
  /// **'Straighten'**
  String get labelCropStraighten;

  /// Label of the vertical perspective slider
  ///
  /// In en, this message translates to:
  /// **'Vertical tilt'**
  String get labelCropPerspectiveVertical;

  /// Label of the horizontal perspective slider
  ///
  /// In en, this message translates to:
  /// **'Horizontal tilt'**
  String get labelCropPerspectiveHorizontal;

  /// Button that clears every geometry change
  ///
  /// In en, this message translates to:
  /// **'Reset crop'**
  String get actionCropReset;

  /// Label of the brightness slider
  ///
  /// In en, this message translates to:
  /// **'Exposure'**
  String get labelToneExposure;

  /// Label of the contrast slider
  ///
  /// In en, this message translates to:
  /// **'Contrast'**
  String get labelToneContrast;

  /// Label of the highlights slider
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get labelToneHighlights;

  /// Label of the shadows slider
  ///
  /// In en, this message translates to:
  /// **'Shadows'**
  String get labelToneShadows;

  /// Label of the colour temperature slider
  ///
  /// In en, this message translates to:
  /// **'Warmth'**
  String get labelToneTemperature;

  /// Label of the green and magenta slider
  ///
  /// In en, this message translates to:
  /// **'Tint'**
  String get labelToneTint;

  /// Label of the vibrance slider
  ///
  /// In en, this message translates to:
  /// **'Vibrance'**
  String get labelToneVibrance;

  /// Label of the saturation slider
  ///
  /// In en, this message translates to:
  /// **'Saturation'**
  String get labelToneSaturation;

  /// Button that puts every tone slider back to neutral
  ///
  /// In en, this message translates to:
  /// **'Reset tune'**
  String get actionToneReset;

  /// Header of the RGB curve control
  ///
  /// In en, this message translates to:
  /// **'Curves'**
  String get labelToneCurves;

  /// Curve applied to all three channels
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get labelCurveChannelRgb;

  /// Red channel curve
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get labelCurveChannelRed;

  /// Green channel curve
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get labelCurveChannelGreen;

  /// Blue channel curve
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get labelCurveChannelBlue;

  /// Button that straightens the shown curve
  ///
  /// In en, this message translates to:
  /// **'Reset curve'**
  String get actionCurveReset;

  /// Hint under the spline curve editor
  ///
  /// In en, this message translates to:
  /// **'Tap to add a point, long-press to remove'**
  String get helpCurveAddHint;

  /// Linear gradient mask shape option
  ///
  /// In en, this message translates to:
  /// **'Linear'**
  String get labelMaskShapeLinear;

  /// Radial circular mask shape option
  ///
  /// In en, this message translates to:
  /// **'Radial'**
  String get labelMaskShapeRadial;

  /// Label of the mask edge feathering slider
  ///
  /// In en, this message translates to:
  /// **'Feather'**
  String get labelMaskFeather;

  /// Toggle to invert the selective mask area
  ///
  /// In en, this message translates to:
  /// **'Invert'**
  String get labelMaskInvert;

  /// Label of the selective mask blur slider
  ///
  /// In en, this message translates to:
  /// **'Blur'**
  String get labelMaskBlur;

  /// Tooltip for adding a linear gradient mask
  ///
  /// In en, this message translates to:
  /// **'Add linear gradient'**
  String get tooltipMaskAddLinear;

  /// Tooltip for adding a radial mask
  ///
  /// In en, this message translates to:
  /// **'Add radial mask'**
  String get tooltipMaskAddRadial;

  /// Message displayed when no selective masks exist
  ///
  /// In en, this message translates to:
  /// **'Tap + to add a mask'**
  String get emptyMask;

  /// Section header for the 8-channel HSL color tuner
  ///
  /// In en, this message translates to:
  /// **'HSL Color Tuner'**
  String get titleHsl;

  /// Label for the HSL hue adjustment slider
  ///
  /// In en, this message translates to:
  /// **'Hue'**
  String get labelHslHue;

  /// Label for the HSL saturation adjustment slider
  ///
  /// In en, this message translates to:
  /// **'Saturation'**
  String get labelHslSaturation;

  /// Label for the HSL luminance adjustment slider
  ///
  /// In en, this message translates to:
  /// **'Luminance'**
  String get labelHslLuminance;

  /// Button to reset HSL color adjustments to neutral
  ///
  /// In en, this message translates to:
  /// **'Reset HSL'**
  String get actionHslReset;

  /// HSL color range for red tones
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get labelHslRangeRed;

  /// HSL color range for orange tones
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get labelHslRangeOrange;

  /// HSL color range for yellow tones
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get labelHslRangeYellow;

  /// HSL color range for green tones
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get labelHslRangeGreen;

  /// HSL color range for cyan tones
  ///
  /// In en, this message translates to:
  /// **'Cyan'**
  String get labelHslRangeCyan;

  /// HSL color range for blue tones
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get labelHslRangeBlue;

  /// HSL color range for purple tones
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get labelHslRangePurple;

  /// HSL color range for magenta tones
  ///
  /// In en, this message translates to:
  /// **'Magenta'**
  String get labelHslRangeMagenta;

  /// Filter preset that changes nothing
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get labelFilterNone;

  /// Black and white filter preset
  ///
  /// In en, this message translates to:
  /// **'Mono'**
  String get labelFilterMono;

  /// Sepia filter preset
  ///
  /// In en, this message translates to:
  /// **'Sepia'**
  String get labelFilterSepia;

  /// Faded warm filter preset
  ///
  /// In en, this message translates to:
  /// **'Vintage'**
  String get labelFilterVintage;

  /// Strong colour filter preset
  ///
  /// In en, this message translates to:
  /// **'Vivid'**
  String get labelFilterVivid;

  /// Cool blue filter preset
  ///
  /// In en, this message translates to:
  /// **'Cool'**
  String get labelFilterCool;

  /// Warm orange filter preset
  ///
  /// In en, this message translates to:
  /// **'Warm'**
  String get labelFilterWarm;

  /// Soft low contrast filter preset
  ///
  /// In en, this message translates to:
  /// **'Fade'**
  String get labelFilterFade;

  /// Label of the filter strength slider
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get labelFilterIntensity;

  /// Freehand doodle tool
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get labelMarkupFreehand;

  /// Rectangle shape tool
  ///
  /// In en, this message translates to:
  /// **'Rectangle'**
  String get labelMarkupRectangle;

  /// Circle shape tool
  ///
  /// In en, this message translates to:
  /// **'Circle'**
  String get labelMarkupEllipse;

  /// Line shape tool
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get labelMarkupLine;

  /// Arrow shape tool
  ///
  /// In en, this message translates to:
  /// **'Arrow'**
  String get labelMarkupArrow;

  /// Text overlay tool
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get labelMarkupText;

  /// Label of the markup colour picker
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get labelMarkupColor;

  /// Label of the markup line thickness slider
  ///
  /// In en, this message translates to:
  /// **'Thickness'**
  String get labelMarkupThickness;

  /// Switch that fills the inside of a shape
  ///
  /// In en, this message translates to:
  /// **'Fill shape'**
  String get titleMarkupFilled;

  /// Button that removes the most recent drawing
  ///
  /// In en, this message translates to:
  /// **'Remove last'**
  String get actionMarkupUndoLayer;

  /// Title of the add text dialog
  ///
  /// In en, this message translates to:
  /// **'Add text'**
  String get titleMarkupText;

  /// Hint inside the add text field
  ///
  /// In en, this message translates to:
  /// **'Type your text'**
  String get helpMarkupTextHint;

  /// Button that adds the typed text to the photo
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionMarkupTextAdd;

  /// Hint shown under the markup tools
  ///
  /// In en, this message translates to:
  /// **'Drag on the photo to draw'**
  String get helpMarkupHint;

  /// Redaction that softens the area
  ///
  /// In en, this message translates to:
  /// **'Blur'**
  String get labelRedactBlur;

  /// Redaction that turns the area into blocks
  ///
  /// In en, this message translates to:
  /// **'Pixelate'**
  String get labelRedactPixelate;

  /// Redaction that paints the area solid
  ///
  /// In en, this message translates to:
  /// **'Blackout'**
  String get labelRedactBlackout;

  /// Label of the redaction strength slider
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get labelRedactStrength;

  /// Hint shown under the redaction tools
  ///
  /// In en, this message translates to:
  /// **'Drag over anything you want hidden'**
  String get helpRedactHint;

  /// Button that removes the most recent hidden area
  ///
  /// In en, this message translates to:
  /// **'Remove last'**
  String get actionRedactRemoveLast;

  /// Number of redacted areas on the photo
  ///
  /// In en, this message translates to:
  /// **'{count} areas hidden'**
  String bodyRedactCount(int count);

  /// No watermark
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get labelWatermarkNone;

  /// Watermark showing typed text
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get labelWatermarkText;

  /// Watermark showing the photo's date
  ///
  /// In en, this message translates to:
  /// **'Date and time'**
  String get labelWatermarkTimestamp;

  /// Watermark showing a picture file
  ///
  /// In en, this message translates to:
  /// **'Logo'**
  String get labelWatermarkLogo;

  /// Hint inside the watermark text field
  ///
  /// In en, this message translates to:
  /// **'Watermark text'**
  String get helpWatermarkTextHint;

  /// Label of the watermark position picker
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get labelWatermarkPosition;

  /// Label of the watermark opacity slider
  ///
  /// In en, this message translates to:
  /// **'Opacity'**
  String get labelWatermarkOpacity;

  /// Label of the watermark size slider
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get labelWatermarkSize;

  /// Label of the watermark margin slider
  ///
  /// In en, this message translates to:
  /// **'Edge gap'**
  String get labelWatermarkMargin;

  /// Button that picks the watermark picture
  ///
  /// In en, this message translates to:
  /// **'Choose a logo file'**
  String get actionWatermarkPickLogo;

  /// Shown when the logo watermark has no file
  ///
  /// In en, this message translates to:
  /// **'No logo chosen yet'**
  String get bodyWatermarkNoLogo;

  /// Watermark corner
  ///
  /// In en, this message translates to:
  /// **'Top left'**
  String get labelPositionTopLeft;

  /// Watermark position
  ///
  /// In en, this message translates to:
  /// **'Top centre'**
  String get labelPositionTopCenter;

  /// Watermark corner
  ///
  /// In en, this message translates to:
  /// **'Top right'**
  String get labelPositionTopRight;

  /// Watermark position
  ///
  /// In en, this message translates to:
  /// **'Middle left'**
  String get labelPositionCenterLeft;

  /// Watermark position
  ///
  /// In en, this message translates to:
  /// **'Centre'**
  String get labelPositionCenter;

  /// Watermark position
  ///
  /// In en, this message translates to:
  /// **'Middle right'**
  String get labelPositionCenterRight;

  /// Watermark corner
  ///
  /// In en, this message translates to:
  /// **'Bottom left'**
  String get labelPositionBottomLeft;

  /// Watermark position
  ///
  /// In en, this message translates to:
  /// **'Bottom centre'**
  String get labelPositionBottomCenter;

  /// Watermark corner
  ///
  /// In en, this message translates to:
  /// **'Bottom right'**
  String get labelPositionBottomRight;

  /// Tooltip on the viewer button that opens the converter
  ///
  /// In en, this message translates to:
  /// **'Convert'**
  String get titleConvertOpen;

  /// Title of the converter screen
  ///
  /// In en, this message translates to:
  /// **'Convert and resize'**
  String get titleConvert;

  /// Shown when the chosen item is not a still picture
  ///
  /// In en, this message translates to:
  /// **'This file cannot be converted'**
  String get bodyConvertCannotOpen;

  /// Shown when the picture is over the size limit
  ///
  /// In en, this message translates to:
  /// **'This file is too large to convert'**
  String get bodyConvertTooLarge;

  /// Shown when the picture bytes cannot be loaded
  ///
  /// In en, this message translates to:
  /// **'This picture could not be read'**
  String get bodyConvertUnreadable;

  /// Heading above the output format chips
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get labelConvertFormat;

  /// Heading above the quality slider
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get labelConvertQuality;

  /// Heading above the resize controls
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get labelConvertResize;

  /// Resize choice that keeps the picture size
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get labelConvertResizeNone;

  /// Resize choice that fits inside a longest side
  ///
  /// In en, this message translates to:
  /// **'Longest side'**
  String get labelConvertResizeLongestSide;

  /// Resize choice that scales by a percentage
  ///
  /// In en, this message translates to:
  /// **'Percent'**
  String get labelConvertResizePercent;

  /// Resize choice that uses exact numbers
  ///
  /// In en, this message translates to:
  /// **'Width and height'**
  String get labelConvertResizeExact;

  /// Switch that stops the picture being stretched
  ///
  /// In en, this message translates to:
  /// **'Keep the shape'**
  String get titleConvertKeepAspect;

  /// Label of the width box
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get labelConvertWidth;

  /// Label of the height box
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get labelConvertHeight;

  /// Label of the longest side box
  ///
  /// In en, this message translates to:
  /// **'Longest side (px)'**
  String get labelConvertLongestSide;

  /// Label of the percent box
  ///
  /// In en, this message translates to:
  /// **'Percent of original'**
  String get labelConvertPercent;

  /// Switch that drops EXIF data from the copy
  ///
  /// In en, this message translates to:
  /// **'Remove camera info'**
  String get titleConvertStripMetadata;

  /// Explains what removing camera details does
  ///
  /// In en, this message translates to:
  /// **'Location and camera settings are left out of the copy'**
  String get helpConvertStripMetadataHint;

  /// Label of the original file size in the size preview
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get labelConvertOriginalSize;

  /// Label of the new file size in the size preview
  ///
  /// In en, this message translates to:
  /// **'New copy'**
  String get labelConvertNewSize;

  /// Shown while the size preview is being encoded
  ///
  /// In en, this message translates to:
  /// **'Working out the size'**
  String get bodyConvertEstimating;

  /// Shown when the size preview fails
  ///
  /// In en, this message translates to:
  /// **'The size cannot be worked out for this file'**
  String get bodyConvertNoEstimate;

  /// Warning when the chosen format grows the file
  ///
  /// In en, this message translates to:
  /// **'The copy is larger than the original'**
  String get bodyConvertLargerWarning;

  /// Button that writes the converted file
  ///
  /// In en, this message translates to:
  /// **'Save a copy'**
  String get labelConvertSave;

  /// Shown while the converted copy is being written
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get labelConvertSaving;

  /// Shown when the conversion fails
  ///
  /// In en, this message translates to:
  /// **'The copy could not be saved'**
  String get errorConvertFailed;

  /// Reassures the user that nothing is overwritten
  ///
  /// In en, this message translates to:
  /// **'Your original file is not changed'**
  String get bodyConvertOriginalKept;

  /// Menu item that opens the PDF export screen
  ///
  /// In en, this message translates to:
  /// **'Export as PDF'**
  String get tooltipPdfOpen;

  /// Title of the PDF export screen
  ///
  /// In en, this message translates to:
  /// **'Export as PDF'**
  String get titlePdfExport;

  /// Heading above the photo picker grid
  ///
  /// In en, this message translates to:
  /// **'Choose photos'**
  String get labelPdfChoosePhotos;

  /// Shown when nothing is picked yet
  ///
  /// In en, this message translates to:
  /// **'Choose at least one photo'**
  String get bodyPdfNoSelection;

  /// Shown when the library holds no pictures
  ///
  /// In en, this message translates to:
  /// **'There are no photos to choose from'**
  String get bodyPdfNoPhotos;

  /// Heading above the page size choices
  ///
  /// In en, this message translates to:
  /// **'Page size'**
  String get labelPdfPageSize;

  /// Page size choice
  ///
  /// In en, this message translates to:
  /// **'A4'**
  String get labelPdfPageA4;

  /// Page size choice
  ///
  /// In en, this message translates to:
  /// **'Letter'**
  String get labelPdfPageLetter;

  /// Page size choice that matches each photo
  ///
  /// In en, this message translates to:
  /// **'Fit the photo'**
  String get labelPdfPageFitImage;

  /// Heading above the page direction choices
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get labelPdfOrientation;

  /// Page direction choice
  ///
  /// In en, this message translates to:
  /// **'Upright'**
  String get labelPdfOrientationPortrait;

  /// Page direction choice
  ///
  /// In en, this message translates to:
  /// **'Sideways'**
  String get labelPdfOrientationLandscape;

  /// Page direction choice that matches each photo
  ///
  /// In en, this message translates to:
  /// **'Follow the photo'**
  String get labelPdfOrientationAuto;

  /// Heading above the photo placement choices
  ///
  /// In en, this message translates to:
  /// **'Placement'**
  String get labelPdfFit;

  /// Placement choice that shows all of the photo
  ///
  /// In en, this message translates to:
  /// **'Fit the whole photo'**
  String get labelPdfFitContain;

  /// Placement choice that crops the photo
  ///
  /// In en, this message translates to:
  /// **'Fill the page'**
  String get labelPdfFitFill;

  /// Heading above the page border choices
  ///
  /// In en, this message translates to:
  /// **'Border'**
  String get labelPdfMargin;

  /// Page border choice
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get labelPdfMarginNone;

  /// Page border choice
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get labelPdfMarginSmall;

  /// Page border choice
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get labelPdfMarginMedium;

  /// Page border choice
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get labelPdfMarginLarge;

  /// Heading above the PDF photo quality slider
  ///
  /// In en, this message translates to:
  /// **'Photo quality'**
  String get labelPdfQuality;

  /// Button that builds the document
  ///
  /// In en, this message translates to:
  /// **'Create the PDF'**
  String get actionPdfExport;

  /// Shown while the document is being built
  ///
  /// In en, this message translates to:
  /// **'Creating the PDF'**
  String get labelPdfExporting;

  /// Shown when the export fails
  ///
  /// In en, this message translates to:
  /// **'The PDF could not be created'**
  String get errorPdfFailed;

  /// Tooltip on the viewer button that opens the video tools
  ///
  /// In en, this message translates to:
  /// **'Video tools'**
  String get titleVideoToolsOpen;

  /// Title of the video tools screen
  ///
  /// In en, this message translates to:
  /// **'Video tools'**
  String get titleVideoTools;

  /// Shown when the platform cannot open the clip
  ///
  /// In en, this message translates to:
  /// **'This clip could not be read'**
  String get bodyVideoToolsUnavailable;

  /// Tab that grabs a still picture
  ///
  /// In en, this message translates to:
  /// **'Frame'**
  String get tabVideoTabFrame;

  /// Tab that makes an animated GIF
  ///
  /// In en, this message translates to:
  /// **'GIF'**
  String get tabVideoTabGif;

  /// Tab that cuts the clip
  ///
  /// In en, this message translates to:
  /// **'Trim'**
  String get tabVideoTabTrim;

  /// Label of the frame position slider
  ///
  /// In en, this message translates to:
  /// **'Position in the clip'**
  String get labelFramePosition;

  /// Heading above the frame format choices
  ///
  /// In en, this message translates to:
  /// **'Save as'**
  String get labelFrameFormat;

  /// Button that writes the still picture
  ///
  /// In en, this message translates to:
  /// **'Save this frame'**
  String get actionFrameSave;

  /// Shown when the platform gives no frame
  ///
  /// In en, this message translates to:
  /// **'No frame could be read here'**
  String get bodyFrameUnavailable;

  /// Heading above the GIF frame rate choices
  ///
  /// In en, this message translates to:
  /// **'Frames per second'**
  String get labelGifFrameRate;

  /// Heading above the GIF size choices
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get labelGifSize;

  /// Switch that makes the GIF repeat
  ///
  /// In en, this message translates to:
  /// **'Play on a loop'**
  String get titleGifLoopLabel;

  /// Shown when the frame or length cap applies
  ///
  /// In en, this message translates to:
  /// **'The GIF is shortened to keep the file small'**
  String get bodyGifCapped;

  /// Button that writes the GIF
  ///
  /// In en, this message translates to:
  /// **'Create the GIF'**
  String get actionGifExport;

  /// Shown while the GIF is being made
  ///
  /// In en, this message translates to:
  /// **'Creating the GIF'**
  String get labelGifExporting;

  /// Label of the trim start handle
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get labelTrimStart;

  /// Label of the trim end handle
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get labelTrimEnd;

  /// Label of the kept length
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get labelTrimLength;

  /// Button that writes the trimmed video
  ///
  /// In en, this message translates to:
  /// **'Save trimmed clip'**
  String get actionTrim;

  /// Explains how the lossless trim works
  ///
  /// In en, this message translates to:
  /// **'Nothing is re-encoded, so no quality is lost. The cut may begin a moment earlier, at the nearest key frame.'**
  String get bodyTrimLosslessNote;

  /// Shown when the trim range is below the minimum
  ///
  /// In en, this message translates to:
  /// **'The chosen part is too short'**
  String get bodyTrimTooShort;

  /// Shown while a video job is running
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get labelVideoWorking;

  /// Shown when a video job fails
  ///
  /// In en, this message translates to:
  /// **'That could not be finished'**
  String get errorVideoJobFailed;

  /// Pixel size shown in the size preview
  ///
  /// In en, this message translates to:
  /// **'{width} by {height} pixels'**
  String bodyConvertPixelSize(int width, int height);

  /// How much smaller the new copy is
  ///
  /// In en, this message translates to:
  /// **'{percent} percent smaller'**
  String bodyConvertSmallerBy(int percent);

  /// Shown after a converted copy is written
  ///
  /// In en, this message translates to:
  /// **'Saved as {name}'**
  String bodyConvertSavedAs(String name);

  /// How many photos are picked for the PDF
  ///
  /// In en, this message translates to:
  /// **'{count} chosen'**
  String bodyPdfSelectedCount(int count);

  /// Shown when the page cap stops more photos being picked
  ///
  /// In en, this message translates to:
  /// **'Only {count} photos fit in one PDF'**
  String bodyPdfMaxPagesReached(int count);

  /// Shown after a PDF is written
  ///
  /// In en, this message translates to:
  /// **'Saved {name} with {pages} pages'**
  String bodyPdfExportedAs(String name, int pages);

  /// Shown when some chosen photos were skipped
  ///
  /// In en, this message translates to:
  /// **'{count} photos could not be read and were left out'**
  String bodyPdfSkippedCount(int count);

  /// How many frames the GIF will hold
  ///
  /// In en, this message translates to:
  /// **'{count} frames'**
  String bodyGifFrameCount(int count);

  /// Shown after a video job writes a file
  ///
  /// In en, this message translates to:
  /// **'Saved as {name}'**
  String bodyVideoJobSavedAs(String name);

  /// Title of the search screen
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get titleSearch;

  /// Opens the search screen
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get tooltipSearchOpen;

  /// Placeholder text inside the search box
  ///
  /// In en, this message translates to:
  /// **'Search names, tags, notes, places'**
  String get helpSearchHint;

  /// Clears the search box
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get tooltipSearchClear;

  /// Opens the search filter sheet
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get tooltipSearchFilters;

  /// Shown before anything is typed
  ///
  /// In en, this message translates to:
  /// **'Search your library'**
  String get titleSearchStart;

  /// Explains what search can do
  ///
  /// In en, this message translates to:
  /// **'Look through names, tags, notes, camera and place. Start a word with tag:, type:, place:, camera:, before: or after: to narrow the search.'**
  String get bodySearchStart;

  /// Shown when a search finds nothing
  ///
  /// In en, this message translates to:
  /// **'Nothing matched'**
  String get titleSearchNoResults;

  /// Advice when a search finds nothing
  ///
  /// In en, this message translates to:
  /// **'Try fewer words, or check the filters.'**
  String get bodySearchNoResults;

  /// Shown when a search throws an error
  ///
  /// In en, this message translates to:
  /// **'The search could not run'**
  String get errorSearchFailed;

  /// Heading above the recent search list
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get titleSearchRecent;

  /// Forgets every recent search
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get actionSearchRecentClear;

  /// Forgets one recent search
  ///
  /// In en, this message translates to:
  /// **'Forget this search'**
  String get tooltipSearchRecentRemove;

  /// How many items a search found
  ///
  /// In en, this message translates to:
  /// **'{count} results'**
  String bodySearchResultCount(int count);

  /// Why a result came back
  ///
  /// In en, this message translates to:
  /// **'Matched the file name'**
  String get bodySearchMatchedInName;

  /// Why a result came back
  ///
  /// In en, this message translates to:
  /// **'Matched a tag'**
  String get labelSearchMatchedInTags;

  /// Why a result came back
  ///
  /// In en, this message translates to:
  /// **'Matched a note'**
  String get labelSearchMatchedInNotes;

  /// Why a result came back
  ///
  /// In en, this message translates to:
  /// **'Matched a place'**
  String get labelSearchMatchedInPlace;

  /// Why a result came back
  ///
  /// In en, this message translates to:
  /// **'Matched the photo details'**
  String get bodySearchMatchedInDetails;

  /// Title of the filter sheet
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get tooltipFilterTitle;

  /// Heading for the media kind filter
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get labelFilterMediaType;

  /// Media kind filter chip
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get labelFilterTypeImage;

  /// Media kind filter chip
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get labelFilterTypeVideo;

  /// Media kind filter chip
  ///
  /// In en, this message translates to:
  /// **'GIFs'**
  String get labelFilterTypeGif;

  /// Media kind filter chip
  ///
  /// In en, this message translates to:
  /// **'RAW'**
  String get labelFilterTypeRaw;

  /// Media kind filter chip
  ///
  /// In en, this message translates to:
  /// **'SVG'**
  String get labelFilterTypeSvg;

  /// Filter switch for favourite items
  ///
  /// In en, this message translates to:
  /// **'Favourites only'**
  String get titleFilterFavoritesOnly;

  /// Filter switch for items with a GPS fix
  ///
  /// In en, this message translates to:
  /// **'Has a place'**
  String get titleFilterHasLocation;

  /// Heading for the date filter
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get labelFilterDateRange;

  /// Shown when no date range is set
  ///
  /// In en, this message translates to:
  /// **'Any date'**
  String get labelFilterDateAny;

  /// Opens the date range picker
  ///
  /// In en, this message translates to:
  /// **'Choose dates'**
  String get actionFilterDateChoose;

  /// Removes the date range
  ///
  /// In en, this message translates to:
  /// **'Clear dates'**
  String get actionFilterDateClear;

  /// Heading for the tag filter
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get labelFilterTags;

  /// Tag filter requiring every chosen tag
  ///
  /// In en, this message translates to:
  /// **'Has all'**
  String get actionFilterTagModeAll;

  /// Tag filter requiring one chosen tag
  ///
  /// In en, this message translates to:
  /// **'Has any'**
  String get actionFilterTagModeAny;

  /// Shown in the filter sheet when no tag exists
  ///
  /// In en, this message translates to:
  /// **'No tags yet'**
  String get labelFilterNoTags;

  /// Clears every filter
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get actionFilterReset;

  /// Closes the filter sheet keeping the choices
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get actionFilterApply;

  /// Title of the tag management screen
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get titleTags;

  /// Opens the tag screen
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get titleTagsOpen;

  /// Shown when no tag has been made
  ///
  /// In en, this message translates to:
  /// **'No tags yet'**
  String get titleTagsEmpty;

  /// Advice when no tag has been made
  ///
  /// In en, this message translates to:
  /// **'Make a tag to group photos your own way.'**
  String get bodyTagsEmpty;

  /// Starts making a tag
  ///
  /// In en, this message translates to:
  /// **'New tag'**
  String get actionTagNew;

  /// Title of the tag edit dialog
  ///
  /// In en, this message translates to:
  /// **'Edit tag'**
  String get tooltipTagEditTitle;

  /// Label of the tag name field
  ///
  /// In en, this message translates to:
  /// **'Tag name'**
  String get labelTagName;

  /// Label of the tag colour picker
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get labelTagColor;

  /// Saves a tag
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionTagSave;

  /// Closes a dialog without saving
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionTagCancel;

  /// Deletes a tag
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get tooltipTagDelete;

  /// Title of the delete tag confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete this tag?'**
  String get titleTagDelete;

  /// Explains what deleting a tag does
  ///
  /// In en, this message translates to:
  /// **'The tag comes off every photo that has it. No photo is deleted.'**
  String get bodyTagDelete;

  /// How many items carry a tag
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String descTagItemCount(int count);

  /// Shown when a tag name is blank
  ///
  /// In en, this message translates to:
  /// **'A tag needs a name'**
  String get emptyTagError;

  /// Shown when a tag name is over the limit
  ///
  /// In en, this message translates to:
  /// **'That name is too long'**
  String get bodyTagErrorTooLong;

  /// Shown when a tag name is taken
  ///
  /// In en, this message translates to:
  /// **'That tag already exists'**
  String get bodyTagErrorDuplicate;

  /// Shown when a tag write fails
  ///
  /// In en, this message translates to:
  /// **'The tag could not be saved'**
  String get errorTagErrorFailed;

  /// Title of the tag sheet in the viewer
  ///
  /// In en, this message translates to:
  /// **'Tags on this item'**
  String get titleTagSheet;

  /// Placeholder of the new tag field
  ///
  /// In en, this message translates to:
  /// **'Add a new tag'**
  String get helpTagSheetNewHint;

  /// Adds the typed tag
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionTagSheetAdd;

  /// Closes the tag sheet
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionTagSheetDone;

  /// Opens the tag sheet from the viewer
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get titleTagSheetOpen;

  /// Title of the duplicate cleaner screen
  ///
  /// In en, this message translates to:
  /// **'Duplicate cleaner'**
  String get titleCleaner;

  /// Opens the duplicate cleaner
  ///
  /// In en, this message translates to:
  /// **'Duplicate cleaner'**
  String get titleCleanerOpen;

  /// Starts a duplicate scan
  ///
  /// In en, this message translates to:
  /// **'Find duplicates'**
  String get labelCleanerStart;

  /// Stops a running duplicate scan
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get actionCleanerStop;

  /// Runs the duplicate scan a second time
  ///
  /// In en, this message translates to:
  /// **'Scan again'**
  String get labelCleanerRescan;

  /// Shown before a duplicate scan is run
  ///
  /// In en, this message translates to:
  /// **'Find duplicates'**
  String get titleCleanerIdle;

  /// Explains how the duplicate scan works
  ///
  /// In en, this message translates to:
  /// **'Each file is read once and what was found is remembered, so scanning again later is quick.'**
  String get bodyCleanerIdle;

  /// Live duplicate scan progress
  ///
  /// In en, this message translates to:
  /// **'Checked {processed} of {total}'**
  String bodyCleanerScanning(int processed, int total);

  /// Shown while duplicate groups are built
  ///
  /// In en, this message translates to:
  /// **'Grouping the copies'**
  String get labelCleanerGrouping;

  /// Shown when the user stops the scan
  ///
  /// In en, this message translates to:
  /// **'Scan stopped'**
  String get labelCleanerCancelled;

  /// Shown when the duplicate scan fails
  ///
  /// In en, this message translates to:
  /// **'The scan could not finish'**
  String get errorCleanerFailed;

  /// Shown when the scan finds no copies
  ///
  /// In en, this message translates to:
  /// **'No duplicates found'**
  String get titleCleanerNone;

  /// Explains an empty duplicate result
  ///
  /// In en, this message translates to:
  /// **'Nothing in your library looks like a copy of anything else.'**
  String get bodyCleanerNone;

  /// How many duplicate groups were found
  ///
  /// In en, this message translates to:
  /// **'{count} groups of copies'**
  String bodyCleanerGroupsFound(int count);

  /// How much space the extra copies take
  ///
  /// In en, this message translates to:
  /// **'About {size} could be freed'**
  String bodyCleanerReclaimable(String size);

  /// How many files the scan could not read
  ///
  /// In en, this message translates to:
  /// **'{count} files could not be read and were skipped'**
  String bodyCleanerFailures(int count);

  /// Badge for a byte-identical duplicate group
  ///
  /// In en, this message translates to:
  /// **'Identical files'**
  String get labelCleanerKindExact;

  /// Badge for a visually similar group
  ///
  /// In en, this message translates to:
  /// **'Looks the same'**
  String get labelCleanerKindSimilar;

  /// How many copies are in a group
  ///
  /// In en, this message translates to:
  /// **'{count} copies'**
  String bodyCleanerMemberCount(int count);

  /// Opens the side-by-side comparison
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get actionCleanerCompare;

  /// Title of the comparison screen
  ///
  /// In en, this message translates to:
  /// **'Compare copies'**
  String get titleCompare;

  /// Shown when a group no longer exists
  ///
  /// In en, this message translates to:
  /// **'This group has already been dealt with'**
  String get bodyCompareGroupGone;

  /// Chooses which copy to keep
  ///
  /// In en, this message translates to:
  /// **'Keep this one'**
  String get actionCompareKeepThis;

  /// Marks the copy the app suggests keeping
  ///
  /// In en, this message translates to:
  /// **'Suggested'**
  String get labelCompareBestBadge;

  /// The confirm action on the compare screen
  ///
  /// In en, this message translates to:
  /// **'Keep 1, move {count} to trash'**
  String bodyCompareKeepAndTrash(int count);

  /// Explains that files are not deleted
  ///
  /// In en, this message translates to:
  /// **'Nothing is erased. The other copies move to the trash and can be brought back.'**
  String get bodyCompareTrashNotice;

  /// Title of the trash confirmation
  ///
  /// In en, this message translates to:
  /// **'Move {count} copies to the trash?'**
  String titleCompareConfirm(int count);

  /// Body of the trash confirmation
  ///
  /// In en, this message translates to:
  /// **'Only the copy you kept stays in the gallery. The files stay on the device and can be brought back.'**
  String get bodyCompareConfirm;

  /// Confirms moving copies to the trash
  ///
  /// In en, this message translates to:
  /// **'Move to trash'**
  String get actionCompareConfirm;

  /// Closes the confirmation without acting
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCompareCancel;

  /// Shown after copies are trashed
  ///
  /// In en, this message translates to:
  /// **'{count} copies moved to the trash'**
  String bodyCompareMoved(int count);

  /// Shown when trashing copies fails
  ///
  /// In en, this message translates to:
  /// **'The copies could not be moved'**
  String get errorCompareFailed;

  /// Row label on the comparison screen
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get labelCompareFieldSize;

  /// Row label on the comparison screen
  ///
  /// In en, this message translates to:
  /// **'Pixels'**
  String get labelCompareFieldPixels;

  /// Row label on the comparison screen
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get labelCompareFieldDate;

  /// Row label on the comparison screen
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get labelCompareFieldCamera;

  /// Shown when a detail is missing
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get labelCompareUnknown;

  /// Title of the albums screen
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get titleAlbums;

  /// Heading above the user's own albums
  ///
  /// In en, this message translates to:
  /// **'My albums'**
  String get labelAlbumsSectionMine;

  /// Heading above the automatic albums
  ///
  /// In en, this message translates to:
  /// **'Smart albums'**
  String get labelAlbumsSectionSmart;

  /// Heading above the storage folders
  ///
  /// In en, this message translates to:
  /// **'Device folders'**
  String get labelAlbumsSectionFolders;

  /// Shown when the user has made no albums
  ///
  /// In en, this message translates to:
  /// **'No albums yet'**
  String get titleAlbumsEmpty;

  /// Explains what an album is
  ///
  /// In en, this message translates to:
  /// **'Make an album to group photos and videos your own way. The files stay where they are.'**
  String get bodyAlbumsEmpty;

  /// Shown when the device has no indexed folders
  ///
  /// In en, this message translates to:
  /// **'No folders found'**
  String get emptyAlbumsFolders;

  /// Shown when reading albums fails
  ///
  /// In en, this message translates to:
  /// **'Albums could not be loaded'**
  String get errorAlbumsLoadFailed;

  /// How many items an album holds
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Empty} =1{1 item} other{{count} items}}'**
  String descAlbumItemCount(int count);

  /// Name of the starred-items album
  ///
  /// In en, this message translates to:
  /// **'Favourites'**
  String get labelSmartAlbumFavorites;

  /// Name of the videos-only album
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get labelSmartAlbumVideos;

  /// Name of the animated images album
  ///
  /// In en, this message translates to:
  /// **'Animated & GIFs'**
  String get labelSmartAlbumGifs;

  /// Name of the raw photos album
  ///
  /// In en, this message translates to:
  /// **'RAW captures'**
  String get labelSmartAlbumRaw;

  /// Name of the wide photos album
  ///
  /// In en, this message translates to:
  /// **'Panoramas'**
  String get labelSmartAlbumPanoramas;

  /// Name of the newest items album
  ///
  /// In en, this message translates to:
  /// **'Recently added'**
  String get labelSmartAlbumRecent;

  /// Name of the trashed items smart album
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get labelSmartAlbumTrash;

  /// Makes a new album
  ///
  /// In en, this message translates to:
  /// **'New album'**
  String get actionAlbumNew;

  /// Title of the create-album dialog
  ///
  /// In en, this message translates to:
  /// **'New album'**
  String get titleAlbumCreate;

  /// Title of the rename-album dialog
  ///
  /// In en, this message translates to:
  /// **'Rename album'**
  String get titleAlbumRenameTitle;

  /// Label of the album name box
  ///
  /// In en, this message translates to:
  /// **'Album name'**
  String get labelAlbumName;

  /// Example album name
  ///
  /// In en, this message translates to:
  /// **'Holiday 2026'**
  String get helpAlbumNameHint;

  /// Confirms the album dialog
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get labelAlbumSave;

  /// Closes a dialog without saving
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionAlbumCancel;

  /// Renames the album
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get titleAlbumRename;

  /// Deletes the album
  ///
  /// In en, this message translates to:
  /// **'Delete album'**
  String get titleAlbumDelete;

  /// Opens the cover chooser
  ///
  /// In en, this message translates to:
  /// **'Choose cover'**
  String get titleAlbumChooseCover;

  /// Opens the reorder screen
  ///
  /// In en, this message translates to:
  /// **'Change order'**
  String get titleAlbumReorder;

  /// Takes one item out of the album
  ///
  /// In en, this message translates to:
  /// **'Remove from album'**
  String get titleAlbumRemoveMedia;

  /// Pins the album
  ///
  /// In en, this message translates to:
  /// **'Pin to top'**
  String get titleAlbumPin;

  /// Shown when the name box is empty
  ///
  /// In en, this message translates to:
  /// **'An album needs a name'**
  String get emptyAlbumError;

  /// Shown when the name is over the limit
  ///
  /// In en, this message translates to:
  /// **'That name is too long'**
  String get bodyAlbumErrorTooLong;

  /// Shown when the name is taken
  ///
  /// In en, this message translates to:
  /// **'An album with that name already exists'**
  String get bodyAlbumErrorDuplicate;

  /// Shown when an album change fails
  ///
  /// In en, this message translates to:
  /// **'That change could not be saved'**
  String get errorAlbumErrorFailed;

  /// Title of the delete confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String titleAlbumDeleteConfirm(String name);

  /// Explains that no file is deleted
  ///
  /// In en, this message translates to:
  /// **'Only the album goes. Every photo and video stays on the device exactly where it is.'**
  String get bodyAlbumDeleteConfirm;

  /// Confirms deleting the album
  ///
  /// In en, this message translates to:
  /// **'Delete album'**
  String get actionAlbumDeleteConfirm;

  /// Shown after an album is deleted
  ///
  /// In en, this message translates to:
  /// **'Album deleted'**
  String get bodyAlbumDeleted;

  /// Shown after an item leaves an album
  ///
  /// In en, this message translates to:
  /// **'Removed from the album'**
  String get bodyAlbumRemovedFromAlbum;

  /// Shown after the cover is changed
  ///
  /// In en, this message translates to:
  /// **'Cover updated'**
  String get bodyAlbumCoverSet;

  /// Shown after a reorder is saved
  ///
  /// In en, this message translates to:
  /// **'New order saved'**
  String get bodyAlbumOrderSaved;

  /// Shown when an album holds nothing
  ///
  /// In en, this message translates to:
  /// **'This album is empty'**
  String get titleAlbumEmpty;

  /// Explains how to fill an album
  ///
  /// In en, this message translates to:
  /// **'Add photos and videos from the gallery. They are not moved or copied.'**
  String get bodyAlbumEmpty;

  /// Shown when an album id does not resolve
  ///
  /// In en, this message translates to:
  /// **'This album is no longer there'**
  String get bodyAlbumGone;

  /// Title of the reorder screen
  ///
  /// In en, this message translates to:
  /// **'Change order'**
  String get titleAlbumReorderTitle;

  /// Explains how to reorder
  ///
  /// In en, this message translates to:
  /// **'Drag an item to move it. The new order is saved when you tap Save.'**
  String get helpAlbumReorderHint;

  /// Saves the new order
  ///
  /// In en, this message translates to:
  /// **'Save order'**
  String get actionAlbumReorderSave;

  /// Title of the cover chooser
  ///
  /// In en, this message translates to:
  /// **'Choose a cover'**
  String get titleAlbumCover;

  /// Clears the chosen cover
  ///
  /// In en, this message translates to:
  /// **'Use the newest item'**
  String get actionAlbumCoverClear;

  /// Title of the add-to-album sheet
  ///
  /// In en, this message translates to:
  /// **'Add to album'**
  String get titleAlbumPicker;

  /// Shown when there is nothing to tick
  ///
  /// In en, this message translates to:
  /// **'You have no albums yet'**
  String get emptyAlbumPicker;

  /// Makes an album from inside the sheet
  ///
  /// In en, this message translates to:
  /// **'New album'**
  String get actionAlbumPickerCreate;

  /// Closes the add-to-album sheet
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionAlbumPickerDone;

  /// Shown after album membership changes
  ///
  /// In en, this message translates to:
  /// **'Albums updated'**
  String get bodyAlbumPickerSaved;

  /// Shown when a device folder has nothing to show
  ///
  /// In en, this message translates to:
  /// **'This folder is empty'**
  String get titleFolderEmpty;

  /// Shown when a smart album is empty
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get titleSmartAlbumEmpty;

  /// Shown for an unknown smart album key
  ///
  /// In en, this message translates to:
  /// **'That album does not exist'**
  String get bodySmartAlbumUnknown;

  /// Filter row keeping only items with a tag
  ///
  /// In en, this message translates to:
  /// **'Tagged only'**
  String get titleFilterHasTags;

  /// Heading of the file size filter
  ///
  /// In en, this message translates to:
  /// **'File size'**
  String get labelFilterFileSize;

  /// Shown when no size range is set
  ///
  /// In en, this message translates to:
  /// **'Any size'**
  String get labelFilterSizeAny;

  /// Small file size choice
  ///
  /// In en, this message translates to:
  /// **'Under 1 MB'**
  String get labelFilterSizeSmall;

  /// Medium file size choice
  ///
  /// In en, this message translates to:
  /// **'1 to 10 MB'**
  String get bodyFilterSizeMedium;

  /// Large file size choice
  ///
  /// In en, this message translates to:
  /// **'Over 10 MB'**
  String get labelFilterSizeLarge;

  /// Heading of the sort choice
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get labelFilterSortBy;

  /// Sort choice
  ///
  /// In en, this message translates to:
  /// **'Date taken'**
  String get labelFilterSortDateTaken;

  /// Sort choice
  ///
  /// In en, this message translates to:
  /// **'Date added'**
  String get labelFilterSortDateAdded;

  /// Sort choice
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get labelFilterSortName;

  /// Sort choice
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get labelFilterSortSize;

  /// Sort direction
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get actionFilterSortNewestFirst;

  /// Sort direction
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get actionFilterSortOldestFirst;

  /// Title of the private vault
  ///
  /// In en, this message translates to:
  /// **'Private Vault'**
  String get titleVault;

  /// Menu entry that opens the private vault
  ///
  /// In en, this message translates to:
  /// **'Private Vault'**
  String get titleVaultMenuLabel;

  /// Viewer action that puts an item in the vault
  ///
  /// In en, this message translates to:
  /// **'Move to vault'**
  String get titleVaultMoveToVault;

  /// Title of the first-run vault set-up
  ///
  /// In en, this message translates to:
  /// **'Create your vault'**
  String get titleVaultSetUp;

  /// Explains what the vault does
  ///
  /// In en, this message translates to:
  /// **'Items you move here are encrypted with a key held by this device and hidden from the gallery.'**
  String get bodyVaultSetUp;

  /// Warning shown before a PIN is chosen
  ///
  /// In en, this message translates to:
  /// **'There is no way to recover a forgotten PIN. Without it nobody can open the vault, not even this app.'**
  String get bodyVaultNoRecoveryWarning;

  /// Prompt for the first PIN entry
  ///
  /// In en, this message translates to:
  /// **'Choose a PIN'**
  String get labelVaultChoosePin;

  /// Prompt for the second PIN entry
  ///
  /// In en, this message translates to:
  /// **'Enter the PIN again'**
  String get bodyVaultConfirmPin;

  /// Prompt on the unlock screen
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN'**
  String get labelVaultEnterPin;

  /// Button that creates the vault
  ///
  /// In en, this message translates to:
  /// **'Create vault'**
  String get labelVaultCreate;

  /// Button that opens the vault
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get labelVaultUnlock;

  /// Button that starts the biometric prompt
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint'**
  String get labelVaultUseBiometrics;

  /// Line Android shows in the biometric prompt
  ///
  /// In en, this message translates to:
  /// **'Unlock your private vault'**
  String get bodyVaultUnlockReason;

  /// Action that shuts the vault straight away
  ///
  /// In en, this message translates to:
  /// **'Lock now'**
  String get tooltipVaultLockNow;

  /// Shown when the confirmation PIN differs
  ///
  /// In en, this message translates to:
  /// **'The two PINs are not the same'**
  String get bodyVaultPinMismatch;

  /// Shown after a wrong PIN
  ///
  /// In en, this message translates to:
  /// **'That PIN is not right'**
  String get bodyVaultWrongPin;

  /// How many tries remain before the pad shuts
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 try left} other{{count} tries left}}'**
  String bodyVaultAttemptsLeft(int count);

  /// Shown while the pad is shut after repeated wrong PINs
  ///
  /// In en, this message translates to:
  /// **'Too many tries. Wait {seconds} seconds.'**
  String bodyVaultLockedOut(int seconds);

  /// PIN rejected for being too short
  ///
  /// In en, this message translates to:
  /// **'A PIN needs at least {count} digits'**
  String bodyVaultPinTooShort(int count);

  /// PIN rejected for being too long
  ///
  /// In en, this message translates to:
  /// **'A PIN can have at most {count} digits'**
  String bodyVaultPinTooLong(int count);

  /// PIN rejected for holding something other than digits
  ///
  /// In en, this message translates to:
  /// **'A PIN can only have digits'**
  String get bodyVaultPinNotDigits;

  /// PIN rejected for being one repeated digit
  ///
  /// In en, this message translates to:
  /// **'Do not use the same digit all the way through'**
  String get bodyVaultPinAllSame;

  /// PIN rejected for being a sequence
  ///
  /// In en, this message translates to:
  /// **'Do not use digits in a straight run'**
  String get bodyVaultPinSequential;

  /// Shown when the sensor does not recognise the user
  ///
  /// In en, this message translates to:
  /// **'Not recognised. Use your PIN.'**
  String get errorVaultBiometricFailed;

  /// Shown when no biometric can be used
  ///
  /// In en, this message translates to:
  /// **'Fingerprint unlock is not available. Use your PIN.'**
  String get bodyVaultBiometricUnavailable;

  /// Shown when unlocking fails for a reason the user cannot act on
  ///
  /// In en, this message translates to:
  /// **'The vault could not be opened'**
  String get errorVaultAuth;

  /// Title shown when the keystore is unusable
  ///
  /// In en, this message translates to:
  /// **'No safe key storage'**
  String get titleVaultKeystoreUnavailable;

  /// Explains why the vault will not open
  ///
  /// In en, this message translates to:
  /// **'The vault needs a hardware-backed key store, and this device does not have a working one. Nothing is encrypted without it, so the vault stays shut.'**
  String get bodyVaultKeystoreUnavailable;

  /// Title shown when no items are in the vault
  ///
  /// In en, this message translates to:
  /// **'The vault is empty'**
  String get titleVaultEmpty;

  /// Body shown when no items are in the vault
  ///
  /// In en, this message translates to:
  /// **'Add photos and videos here to encrypt them and take them out of the gallery.'**
  String get bodyVaultEmpty;

  /// How many items are selected
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String bodyVaultSelectedCount(int count);

  /// Action that opens the import sheet
  ///
  /// In en, this message translates to:
  /// **'Add items'**
  String get labelVaultAddItems;

  /// Action that takes items back out of the vault
  ///
  /// In en, this message translates to:
  /// **'Restore to gallery'**
  String get tooltipVaultRestore;

  /// Action that erases items and their payloads
  ///
  /// In en, this message translates to:
  /// **'Delete for good'**
  String get tooltipVaultDeleteForever;

  /// Action that opens the vault settings
  ///
  /// In en, this message translates to:
  /// **'Vault settings'**
  String get tooltipVaultSettingsAction;

  /// Dismisses a vault dialog
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionVaultCancel;

  /// Clears the current selection
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get tooltipVaultClearSelection;

  /// Title of the import sheet
  ///
  /// In en, this message translates to:
  /// **'Move to vault'**
  String get titleVaultImport;

  /// Explains what an import does
  ///
  /// In en, this message translates to:
  /// **'The items are encrypted and taken out of the gallery. What happens to the originals is up to you.'**
  String get bodyVaultImport;

  /// Import choice that leaves the public files alone
  ///
  /// In en, this message translates to:
  /// **'Keep the originals'**
  String get titleVaultImportKeepOriginal;

  /// Explains the keep choice
  ///
  /// In en, this message translates to:
  /// **'The originals stay where they are. Delete them yourself later if you want to.'**
  String get bodyVaultImportKeepOriginal;

  /// Import choice that destroys the public files
  ///
  /// In en, this message translates to:
  /// **'Shred the originals'**
  String get titleVaultImportShredOriginal;

  /// Explains the shred choice
  ///
  /// In en, this message translates to:
  /// **'The original files are overwritten and deleted. This cannot be undone.'**
  String get bodyVaultImportShredOriginal;

  /// Button that starts the import
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Move 1 item} other{Move {count} items}}'**
  String bodyVaultImportConfirm(int count);

  /// Shown when the import sheet has no selection
  ///
  /// In en, this message translates to:
  /// **'Nothing is selected'**
  String get labelVaultImportNothingSelected;

  /// Title of the shred confirmation
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Destroy 1 original?} other{Destroy {count} originals?}}'**
  String bodyVaultShredConfirmTitle(int count);

  /// Body of the shred confirmation
  ///
  /// In en, this message translates to:
  /// **'The original files will be overwritten and deleted. There is no undo, and no way to get them back.'**
  String get bodyVaultShredConfirm;

  /// Confirms shredding the originals
  ///
  /// In en, this message translates to:
  /// **'Shred them'**
  String get actionVaultShredConfirm;

  /// Shown after a successful import
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item moved to the vault} other{{count} items moved to the vault}}'**
  String bodyVaultImportDone(int count);

  /// Shown when only some of a batch imported
  ///
  /// In en, this message translates to:
  /// **'{moved} moved, {failed} could not be read'**
  String bodyVaultImportPartial(int moved, int failed);

  /// Shown when a whole import failed
  ///
  /// In en, this message translates to:
  /// **'Nothing could be moved to the vault'**
  String get errorVaultImportFailed;

  /// Title of the restore confirmation
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Restore 1 item?} other{Restore {count} items?}}'**
  String bodyVaultRestoreConfirmTitle(int count);

  /// Body of the restore confirmation
  ///
  /// In en, this message translates to:
  /// **'The items are written back into your gallery folders and taken out of the vault.'**
  String get bodyVaultRestoreConfirm;

  /// Confirms restoring items
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get actionVaultRestoreConfirm;

  /// Title of the delete confirmation
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Delete 1 item for good?} other{Delete {count} items for good?}}'**
  String bodyVaultDeleteConfirmTitle(int count);

  /// Body of the delete confirmation
  ///
  /// In en, this message translates to:
  /// **'The encrypted files are overwritten and deleted. There is no undo, and no copy anywhere else.'**
  String get bodyVaultDeleteConfirm;

  /// Shown when a vault item will not decrypt
  ///
  /// In en, this message translates to:
  /// **'This item could not be opened'**
  String get errorVaultViewerFailed;

  /// Shown when a payload fails its authentication tag
  ///
  /// In en, this message translates to:
  /// **'This item failed its integrity check and was not opened'**
  String get bodyVaultViewerTampered;

  /// Title of the vault settings screen
  ///
  /// In en, this message translates to:
  /// **'Vault settings'**
  String get titleVaultSettings;

  /// Heading of the auto-lock choice
  ///
  /// In en, this message translates to:
  /// **'Auto-lock'**
  String get titleVaultAutoLockHeading;

  /// Explains the auto-lock rules
  ///
  /// In en, this message translates to:
  /// **'The vault always locks when the app leaves the screen. This is how long it waits while you are not touching it.'**
  String get bodyVaultAutoLock;

  /// An auto-lock choice measured in seconds
  ///
  /// In en, this message translates to:
  /// **'{count} seconds'**
  String bodyVaultAutoLockSeconds(int count);

  /// An auto-lock choice measured in minutes
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute} other{{count} minutes}}'**
  String bodyVaultAutoLockMinutes(int count);

  /// Heading of the biometric toggle
  ///
  /// In en, this message translates to:
  /// **'Fingerprint unlock'**
  String get titleVaultBiometricHeading;

  /// Explains the biometric toggle
  ///
  /// In en, this message translates to:
  /// **'A shortcut, not a replacement. Your PIN opens the vault whether this is on or off.'**
  String get bodyVaultBiometric;

  /// Heading of the shred pass choice
  ///
  /// In en, this message translates to:
  /// **'Shred passes'**
  String get titleVaultShredHeading;

  /// Explains shredding and its limits
  ///
  /// In en, this message translates to:
  /// **'How many times a file is overwritten before it is deleted. More passes take longer. On flash storage an overwrite is a strong measure, not a guarantee.'**
  String get bodyVaultShred;

  /// A shred pass choice
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 pass} other{{count} passes}}'**
  String bodyVaultShredPassCount(int count);

  /// Heading of the shred-on-import default
  ///
  /// In en, this message translates to:
  /// **'Shred by default'**
  String get titleVaultShredDefaultHeading;

  /// Explains the shred-on-import default
  ///
  /// In en, this message translates to:
  /// **'Pre-selects the shred choice when you add items. It still asks you to confirm every time.'**
  String get bodyVaultShredDefault;

  /// Action that opens the change PIN dialog
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get titleVaultChangePin;

  /// Field label for the existing PIN
  ///
  /// In en, this message translates to:
  /// **'Current PIN'**
  String get labelVaultCurrentPin;

  /// Field label for the replacement PIN
  ///
  /// In en, this message translates to:
  /// **'New PIN'**
  String get labelVaultNewPin;

  /// Shown after a successful PIN change
  ///
  /// In en, this message translates to:
  /// **'Your PIN has been changed'**
  String get bodyVaultPinChanged;

  /// Heading of the secure window note
  ///
  /// In en, this message translates to:
  /// **'Screenshots blocked'**
  String get titleVaultSecureScreenHeading;

  /// Explains the secure window flag
  ///
  /// In en, this message translates to:
  /// **'While the vault is open, Android blocks screenshots and screen recording, and hides the vault in the app switcher.'**
  String get bodyVaultSecureScreen;

  /// Title while items are selected
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 selected} other{{count} selected}}'**
  String bodySelectionCount(int count);

  /// Tooltip that unticks everything
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get tooltipSelectionClear;

  /// Tooltip that ticks everything on screen
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get tooltipSelectionSelectAll;

  /// Shown when the selection cap is reached
  ///
  /// In en, this message translates to:
  /// **'That is as many as one batch can hold'**
  String get bodySelectionFull;

  /// Batch action: change image format
  ///
  /// In en, this message translates to:
  /// **'Convert'**
  String get labelBatchActionConvert;

  /// Batch action bar: last button, opens a sheet with the less common actions
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get labelBatchActionMore;

  /// Batch action: stamp the photos
  ///
  /// In en, this message translates to:
  /// **'Watermark'**
  String get labelBatchActionWatermark;

  /// Batch action: one PDF from many photos
  ///
  /// In en, this message translates to:
  /// **'Make a PDF'**
  String get labelBatchActionExportPdf;

  /// Batch action: tag everything selected
  ///
  /// In en, this message translates to:
  /// **'Add tags'**
  String get labelBatchActionAddTags;

  /// Batch action: untag everything selected
  ///
  /// In en, this message translates to:
  /// **'Remove tags'**
  String get labelBatchActionRemoveTags;

  /// Batch action: put everything in an album
  ///
  /// In en, this message translates to:
  /// **'Add to album'**
  String get labelBatchActionAddToAlbum;

  /// Batch action: mark as favourite
  ///
  /// In en, this message translates to:
  /// **'Add to favourites'**
  String get labelBatchActionFavourite;

  /// Batch action: clear the favourite mark
  ///
  /// In en, this message translates to:
  /// **'Remove from favourites'**
  String get bodyBatchActionUnfavourite;

  /// Batch action: encrypt into the private vault
  ///
  /// In en, this message translates to:
  /// **'Move to vault'**
  String get labelBatchActionMoveToVault;

  /// Batch action: offer the files over local Wi-Fi
  ///
  /// In en, this message translates to:
  /// **'Send to a device'**
  String get bodyBatchActionTransfer;

  /// Batch action: flag as trashed
  ///
  /// In en, this message translates to:
  /// **'Move to trash'**
  String get titleBatchActionMoveToTrash;

  /// Why an action is unavailable: nothing selected
  ///
  /// In en, this message translates to:
  /// **'Select something first'**
  String get emptyBatchBlocked;

  /// Why an action is unavailable: over the cap
  ///
  /// In en, this message translates to:
  /// **'Too many items for one batch'**
  String get bodyBatchBlockedTooLarge;

  /// Why an action is unavailable: wrong media types
  ///
  /// In en, this message translates to:
  /// **'Not available for these files'**
  String get bodyBatchBlockedUnsupported;

  /// Why an action is unavailable: mixed selection
  ///
  /// In en, this message translates to:
  /// **'Videos cannot be included in this action'**
  String get bodyBatchBlockedMixed;

  /// Title of the batch progress dialog
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get titleBatchRunning;

  /// Progress line of the batch dialog
  ///
  /// In en, this message translates to:
  /// **'{done} of {total}'**
  String bodyBatchProgress(int done, int total);

  /// Stops the running batch after the current file
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get labelBatchCancel;

  /// Shown once a cancel has been asked for
  ///
  /// In en, this message translates to:
  /// **'Stopping after this file'**
  String get bodyBatchCancelling;

  /// Title of the batch result sheet
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get labelBatchDone;

  /// How many files the batch finished
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file done} other{{count} files done}}'**
  String bodyBatchResultSucceeded(int count);

  /// How many files the batch could not finish
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file could not be done} other{{count} files could not be done}}'**
  String errorBatchResultFailed(int count);

  /// How many files the batch passed over
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file skipped} other{{count} files skipped}}'**
  String bodyBatchResultSkipped(int count);

  /// Title of the confirmation before a batch that writes files
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get titleBatchConfirm;

  /// Confirmation body for a vault batch
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo will be moved into the vault} other{{count} photos will be moved into the vault}}'**
  String bodyBatchConfirmVault(int count);

  /// Confirmation body for a trash batch
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item will be moved to the trash. Nothing is erased.} other{{count} items will be moved to the trash. Nothing is erased.}}'**
  String bodyBatchConfirmTrash(int count);

  /// Confirmation body for a batch that writes new files
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{A new file will be saved beside the original.} other{{count} new files will be saved beside the originals.}}'**
  String bodyBatchConfirmNewFiles(int count);

  /// Confirms and starts the batch
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionBatchConfirmContinue;

  /// Title of the tag picker used by a batch
  ///
  /// In en, this message translates to:
  /// **'Choose tags'**
  String get labelBatchPickTags;

  /// Title of the album picker used by a batch
  ///
  /// In en, this message translates to:
  /// **'Choose an album'**
  String get labelBatchPickAlbum;

  /// Title of the backup screen
  ///
  /// In en, this message translates to:
  /// **'Backup and restore'**
  String get titleBackup;

  /// Menu entry that opens the backup screen
  ///
  /// In en, this message translates to:
  /// **'Backup and restore'**
  String get titleBackupOpen;

  /// Heading of the create half of the backup screen
  ///
  /// In en, this message translates to:
  /// **'Create a backup'**
  String get titleBackupCreate;

  /// Explains what a backup does and does not hold
  ///
  /// In en, this message translates to:
  /// **'Saves your tags, albums, favourites and notes into one password-protected file. Photos and videos are not included: send those to another device with Transfer.'**
  String get bodyBackupCreate;

  /// Button that starts a backup
  ///
  /// In en, this message translates to:
  /// **'Create backup'**
  String get actionBackupCreate;

  /// Heading of the restore half of the backup screen
  ///
  /// In en, this message translates to:
  /// **'Restore a backup'**
  String get titleBackupRestore;

  /// Explains what a restore does
  ///
  /// In en, this message translates to:
  /// **'Brings back tags, albums, favourites and notes for the photos that are on this device. Nothing on this device is deleted.'**
  String get bodyBackupRestore;

  /// Button that starts a restore
  ///
  /// In en, this message translates to:
  /// **'Choose a backup file'**
  String get actionBackupRestore;

  /// Title of the password dialog
  ///
  /// In en, this message translates to:
  /// **'Backup password'**
  String get titleBackupPassword;

  /// Label of the password field
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get labelBackupPassword;

  /// Label of the confirm password field
  ///
  /// In en, this message translates to:
  /// **'Type it again'**
  String get labelBackupPasswordConfirm;

  /// Warns that a forgotten password loses the archive
  ///
  /// In en, this message translates to:
  /// **'There is no way to recover this password. If you forget it, the backup cannot be opened.'**
  String get bodyBackupPasswordWarning;

  /// Validation message for a short password
  ///
  /// In en, this message translates to:
  /// **'At least {count} characters'**
  String bodyBackupPasswordTooShort(int count);

  /// Validation message when the confirm field differs
  ///
  /// In en, this message translates to:
  /// **'The two do not match'**
  String get bodyBackupPasswordMismatch;

  /// Backup progress stage
  ///
  /// In en, this message translates to:
  /// **'Reading your library'**
  String get labelBackupStageCollecting;

  /// Backup progress stage
  ///
  /// In en, this message translates to:
  /// **'Packing'**
  String get labelBackupStagePacking;

  /// Backup progress stage
  ///
  /// In en, this message translates to:
  /// **'Waiting for you to choose where to save'**
  String get bodyBackupStageChoosing;

  /// Backup progress stage
  ///
  /// In en, this message translates to:
  /// **'Encrypting'**
  String get labelBackupStageEncrypting;

  /// Shown after a successful backup
  ///
  /// In en, this message translates to:
  /// **'Backup saved'**
  String get labelBackupDone;

  /// Shown when the user backed out of the file picker
  ///
  /// In en, this message translates to:
  /// **'Backup cancelled'**
  String get labelBackupCancelled;

  /// Shown when the library holds nothing worth backing up
  ///
  /// In en, this message translates to:
  /// **'There are no tags, albums, notes or favourites to back up yet'**
  String get bodyBackupNothingToSave;

  /// Shown when a backup fails
  ///
  /// In en, this message translates to:
  /// **'The backup could not be saved'**
  String get errorBackupFailed;

  /// Title of the restore preview sheet
  ///
  /// In en, this message translates to:
  /// **'To be restored'**
  String get titleRestorePreview;

  /// Says when the archive was made
  ///
  /// In en, this message translates to:
  /// **'Backup from {date}'**
  String bodyRestoreFromBackupDate(String date);

  /// How many tags a restore would create
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No new tags} =1{1 new tag} other{{count} new tags}}'**
  String bodyRestorePlanTags(int count);

  /// How many albums a restore would create
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No new albums} =1{1 new album} other{{count} new albums}}'**
  String bodyRestorePlanAlbums(int count);

  /// How many links a restore would add
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No tags or album places to add} =1{1 tag or album place to add} other{{count} tags and album places to add}}'**
  String bodyRestorePlanLinks(int count);

  /// How many media rows a restore would change
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No photos to update} =1{1 photo to update} other{{count} photos to update}}'**
  String bodyRestorePlanUpdates(int count);

  /// How many archive records found no local file
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo in the backup is not on this device} other{{count} photos in the backup are not on this device}}'**
  String bodyRestorePlanUnmatched(int count);

  /// Shown when the plan is empty
  ///
  /// In en, this message translates to:
  /// **'This backup would change nothing on this device'**
  String get bodyRestorePlanNothing;

  /// Confirms and applies the restore plan
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get labelRestoreApply;

  /// Shown after a successful restore
  ///
  /// In en, this message translates to:
  /// **'Restore finished'**
  String get labelRestoreDone;

  /// Shown when the archive will not open
  ///
  /// In en, this message translates to:
  /// **'Wrong password, or the file is damaged'**
  String get bodyRestoreWrongPassword;

  /// Shown when the chosen file is the wrong kind
  ///
  /// In en, this message translates to:
  /// **'That is not a gallery backup file'**
  String get bodyRestoreNotAnArchive;

  /// Shown when the chosen file is implausibly large
  ///
  /// In en, this message translates to:
  /// **'That file is too large to be a gallery backup'**
  String get bodyRestoreTooLarge;

  /// Shown when the archive format is from the future
  ///
  /// In en, this message translates to:
  /// **'That backup was made by a newer version of the app'**
  String get bodyRestoreTooNew;

  /// Shown when a restore fails
  ///
  /// In en, this message translates to:
  /// **'The backup could not be restored'**
  String get errorRestoreFailed;

  /// Title of the transfer screen
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get titleSync;

  /// Menu entry that opens the transfer screen
  ///
  /// In en, this message translates to:
  /// **'Transfer to a device'**
  String get titleSyncOpen;

  /// Explains what the transfer feature does
  ///
  /// In en, this message translates to:
  /// **'Send photos straight to another phone on the same Wi-Fi. Nothing goes to the internet, and no account is needed.'**
  String get bodySyncIntro;

  /// Explains the local-network-only guarantee
  ///
  /// In en, this message translates to:
  /// **'Both phones must be on the same Wi-Fi. The connection is refused unless the other device is on your local network, and it is closed as soon as you leave this screen.'**
  String get bodySyncPrivacyNote;

  /// Chooses the sending role
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get labelSyncSend;

  /// Chooses the receiving role
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get labelSyncReceive;

  /// Explains the sending flow
  ///
  /// In en, this message translates to:
  /// **'Show a code on this phone, or scan the other one'**
  String get bodySyncSend;

  /// Explains the receiving flow
  ///
  /// In en, this message translates to:
  /// **'Show a code for the other phone to scan'**
  String get bodySyncReceive;

  /// Opens the camera to read a pairing code
  ///
  /// In en, this message translates to:
  /// **'Scan a code'**
  String get actionSyncScanCode;

  /// Title of the scanner screen
  ///
  /// In en, this message translates to:
  /// **'Scan the other phone'**
  String get titleSyncScan;

  /// Heading above the QR code
  ///
  /// In en, this message translates to:
  /// **'Scan on other phone'**
  String get titleSyncPairingHeading;

  /// Heading above the typed fallback code
  ///
  /// In en, this message translates to:
  /// **'Or type this code'**
  String get titleSyncManualCodeHeading;

  /// Label of the typed code field
  ///
  /// In en, this message translates to:
  /// **'Pairing code'**
  String get labelSyncManualCode;

  /// Shown when a typed code does not check out
  ///
  /// In en, this message translates to:
  /// **'That code is not valid'**
  String get bodySyncManualCodeInvalid;

  /// Shown while the listener is open
  ///
  /// In en, this message translates to:
  /// **'Waiting for the other phone'**
  String get bodySyncWaiting;

  /// Shown once a peer has connected
  ///
  /// In en, this message translates to:
  /// **'Paired with {name}'**
  String bodySyncPairedWith(String name);

  /// Shown while files are moving
  ///
  /// In en, this message translates to:
  /// **'Transferring'**
  String get labelSyncTransferring;

  /// Per-file progress line
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} files'**
  String bodySyncProgressFiles(int done, int total);

  /// Shown when the sending role has an empty outbox
  ///
  /// In en, this message translates to:
  /// **'Choose some photos to send first'**
  String get bodySyncNothingSelected;

  /// How many files the peer is offering
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file offered} other{{count} files offered}}'**
  String bodySyncOfferHeading(int count);

  /// Shown when a transfer completes
  ///
  /// In en, this message translates to:
  /// **'Transfer finished'**
  String get labelSyncDone;

  /// How many files arrived
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file received} other{{count} files received}}'**
  String bodySyncResultReceived(int count);

  /// How many files were sent
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file sent} other{{count} files sent}}'**
  String bodySyncResultSent(int count);

  /// How many files the receiver already had
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file was already there} other{{count} files were already there}}'**
  String bodySyncResultSkipped(int count);

  /// How many files failed their checks
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file did not arrive} other{{count} files did not arrive}}'**
  String errorSyncResultFailed(int count);

  /// Explains the pre-Android-10 fallback location
  ///
  /// In en, this message translates to:
  /// **'On this version of Android the files were saved in the app\'s own folder rather than your gallery.'**
  String get bodySyncSavedToAppFolder;

  /// Ends the transfer session
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get actionSyncStop;

  /// Transfer failure: no local network
  ///
  /// In en, this message translates to:
  /// **'This phone is not on a Wi-Fi network'**
  String get bodySyncErrorNoNetwork;

  /// Transfer failure: nobody paired
  ///
  /// In en, this message translates to:
  /// **'No device connected in time'**
  String get bodySyncErrorPairingTimeout;

  /// Transfer failure: the peer address was refused
  ///
  /// In en, this message translates to:
  /// **'That device is not on your local network'**
  String get bodySyncErrorRefused;

  /// Transfer failure: the handshake was rejected
  ///
  /// In en, this message translates to:
  /// **'The other device could not prove it showed that code'**
  String get bodySyncErrorHandshake;

  /// Transfer failure: protocol version mismatch
  ///
  /// In en, this message translates to:
  /// **'The other device is running a different version of the app'**
  String get bodySyncErrorProtocol;

  /// Transfer failure: the socket dropped
  ///
  /// In en, this message translates to:
  /// **'The connection to the other device was lost'**
  String get bodySyncErrorConnection;

  /// Transfer failure: idle timeout
  ///
  /// In en, this message translates to:
  /// **'The other device stopped responding'**
  String get bodySyncErrorIdle;

  /// Transfer failure: cancelled by a user
  ///
  /// In en, this message translates to:
  /// **'The transfer was stopped'**
  String get bodySyncErrorCancelled;

  /// Transfer failure: anything else
  ///
  /// In en, this message translates to:
  /// **'The transfer could not be finished'**
  String get bodySyncErrorUnknown;

  /// Shown when the camera permission is refused
  ///
  /// In en, this message translates to:
  /// **'Camera access is needed to scan the code. You can type the code instead.'**
  String get bodySyncCameraPermission;

  /// Switches from the scanner to the typed code field
  ///
  /// In en, this message translates to:
  /// **'Type the code'**
  String get actionSyncTypeCodeInstead;

  /// Opens the overflow menu in the fullscreen viewer
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get tooltipViewerMoreActions;

  /// Viewer menu entry that looks for QR and barcodes in the picture
  ///
  /// In en, this message translates to:
  /// **'Scan codes'**
  String get titleCodeScanOpen;

  /// Title of the in-image scanner screen
  ///
  /// In en, this message translates to:
  /// **'Codes in picture'**
  String get titleCodeScan;

  /// Shown while a picture is being scanned
  ///
  /// In en, this message translates to:
  /// **'Looking for codes'**
  String get labelCodeScanLooking;

  /// Shown when the scan worked but the picture held no codes
  ///
  /// In en, this message translates to:
  /// **'No codes were found in this picture'**
  String get bodyCodeScanNoCodes;

  /// Shown when the decoder itself could not run
  ///
  /// In en, this message translates to:
  /// **'This picture could not be scanned'**
  String get errorCodeScanFailed;

  /// Runs the scan again
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tooltipCodeScanRetry;

  /// How many codes the picture held
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 code found} other{{count} codes found}}'**
  String bodyCodeScanFoundCount(int count);

  /// Label for a scanned code holding a web address
  ///
  /// In en, this message translates to:
  /// **'Web address'**
  String get labelCodeScanKindUrl;

  /// Label for a scanned Wi-Fi joining code
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi network'**
  String get labelCodeScanKindWifi;

  /// Label for a scanned phone number
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get labelCodeScanKindPhone;

  /// Label for a scanned email address
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get labelCodeScanKindEmail;

  /// Label for a scanned text message code
  ///
  /// In en, this message translates to:
  /// **'Text message'**
  String get labelCodeScanKindSms;

  /// Label for a scanned map location
  ///
  /// In en, this message translates to:
  /// **'Map point'**
  String get labelCodeScanKindGeo;

  /// Label for a scanned vCard or MECARD
  ///
  /// In en, this message translates to:
  /// **'Contact card'**
  String get labelCodeScanKindContact;

  /// Label for a scanned calendar event
  ///
  /// In en, this message translates to:
  /// **'Calendar entry'**
  String get labelCodeScanKindCalendar;

  /// Label for a scanned code that is just text
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get labelCodeScanKindText;

  /// Copies the raw code text to the clipboard
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get labelCodeScanActionCopy;

  /// Opens a scanned web address in the browser
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get labelCodeScanActionOpen;

  /// Offers a scanned number to the dialler
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get labelCodeScanActionDial;

  /// Starts an email to a scanned address
  ///
  /// In en, this message translates to:
  /// **'Write email'**
  String get labelCodeScanActionEmail;

  /// Starts a text message to a scanned number
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get labelCodeScanActionSms;

  /// Shows a scanned map point
  ///
  /// In en, this message translates to:
  /// **'Show on map'**
  String get labelCodeScanActionMap;

  /// Copies only the Wi-Fi password from a scanned code
  ///
  /// In en, this message translates to:
  /// **'Copy password'**
  String get labelCodeScanActionCopyWifiPassword;

  /// Offers the scanned network to Android and opens the Wi-Fi settings
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get labelCodeScanActionConnectWifi;

  /// Adds the code text to this item's notes
  ///
  /// In en, this message translates to:
  /// **'Save to notes'**
  String get labelCodeScanActionSaveToNotes;

  /// Why an action is blocked: the scheme is not on the permitted list
  ///
  /// In en, this message translates to:
  /// **'The app does not open this kind of address'**
  String get bodyCodeScanBlockedScheme;

  /// Why an action is blocked: the target is malformed
  ///
  /// In en, this message translates to:
  /// **'This address could not be read'**
  String get bodyCodeScanBlockedMalformed;

  /// Why an action is blocked: incomplete Wi-Fi details
  ///
  /// In en, this message translates to:
  /// **'This Wi-Fi code is missing the network name or the password'**
  String get bodyCodeScanBlockedIncompleteWifi;

  /// Why an action is blocked: the payload is past the cap
  ///
  /// In en, this message translates to:
  /// **'This code is too long to use'**
  String get bodyCodeScanBlockedTooLong;

  /// Confirms the code text went to the clipboard
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get labelCodeScanCopied;

  /// Confirms the Wi-Fi password went to the clipboard
  ///
  /// In en, this message translates to:
  /// **'Password copied'**
  String get labelCodeScanPasswordCopied;

  /// Confirms the code text was added to the notes
  ///
  /// In en, this message translates to:
  /// **'Saved to notes'**
  String get labelCodeScanSavedToNotes;

  /// Shown when no installed app handles the scanned address
  ///
  /// In en, this message translates to:
  /// **'No app on this device can open it'**
  String get errorCodeScanOpenFailed;

  /// Shown after a Wi-Fi suggestion was accepted
  ///
  /// In en, this message translates to:
  /// **'The network was offered to Android. Pick it in the Wi-Fi settings.'**
  String get bodyCodeScanWifiSuggested;

  /// Shown when Android would not take the Wi-Fi suggestion
  ///
  /// In en, this message translates to:
  /// **'Open the Wi-Fi settings and pick the network yourself.'**
  String get bodyCodeScanWifiManual;

  /// Names how a scanned Wi-Fi network is protected
  ///
  /// In en, this message translates to:
  /// **'Security: {security}'**
  String bodyCodeScanWifiSecurity(String security);

  /// Marks a scanned Wi-Fi network that hides its name
  ///
  /// In en, this message translates to:
  /// **'Hidden network'**
  String get labelCodeScanWifiHidden;

  /// Marks a scanned Wi-Fi network with no password
  ///
  /// In en, this message translates to:
  /// **'Open network'**
  String get labelCodeScanWifiOpen;

  /// Viewer menu entry that reads the text out of the picture
  ///
  /// In en, this message translates to:
  /// **'Extract text'**
  String get titleOcrOpen;

  /// Title of the extracted text screen
  ///
  /// In en, this message translates to:
  /// **'Text in this picture'**
  String get titleOcr;

  /// Shown while the reader is running
  ///
  /// In en, this message translates to:
  /// **'Reading the text'**
  String get labelOcrReading;

  /// Sets the expectation that OCR is not instant
  ///
  /// In en, this message translates to:
  /// **'A large photo can take a few seconds.'**
  String get helpOcrSlowHint;

  /// Label of the language chooser on the text screen
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get labelOcrLanguage;

  /// OCR language choice: English only
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get labelOcrLanguageEnglish;

  /// OCR language choice: Malayalam only
  ///
  /// In en, this message translates to:
  /// **'Malayalam'**
  String get labelOcrLanguageMalayalam;

  /// OCR language choice: both at once
  ///
  /// In en, this message translates to:
  /// **'English and Malayalam'**
  String get bodyOcrLanguageBoth;

  /// Shown when the reader ran but found nothing
  ///
  /// In en, this message translates to:
  /// **'No text was found in this picture'**
  String get bodyOcrNoText;

  /// Copies the whole extracted text
  ///
  /// In en, this message translates to:
  /// **'Copy all'**
  String get actionOcrCopyAll;

  /// Confirms the extracted text went to the clipboard
  ///
  /// In en, this message translates to:
  /// **'Text copied'**
  String get labelOcrCopied;

  /// Adds the extracted text to this item's notes
  ///
  /// In en, this message translates to:
  /// **'Save to notes'**
  String get labelOcrSaveToNotes;

  /// Confirms the extracted text was added to the notes
  ///
  /// In en, this message translates to:
  /// **'Saved to notes'**
  String get labelOcrSavedToNotes;

  /// Runs the reader again, usually after changing the language
  ///
  /// In en, this message translates to:
  /// **'Read again'**
  String get actionOcrReadAgain;

  /// How many words were read out of the picture
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 word} other{{count} words}}'**
  String bodyOcrWordCount(int count);

  /// OCR failure: the file is missing or unreadable
  ///
  /// In en, this message translates to:
  /// **'This picture could not be opened'**
  String get bodyOcrFailedUnreadable;

  /// OCR failure: the image is past the size cap
  ///
  /// In en, this message translates to:
  /// **'This picture is too large to read'**
  String get bodyOcrFailedTooLarge;

  /// OCR failure: the traineddata assets are not present
  ///
  /// In en, this message translates to:
  /// **'The language files are missing from this build'**
  String get bodyOcrFailedMissingData;

  /// OCR failure: the reader was given up on
  ///
  /// In en, this message translates to:
  /// **'Reading took too long and was stopped'**
  String get bodyOcrFailedTimeout;

  /// OCR failure: anything else
  ///
  /// In en, this message translates to:
  /// **'The text could not be read'**
  String get bodyOcrFailedEngine;

  /// Viewer menu entry that opens the note editor
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get titleNotesOpen;

  /// Title of the note editor screen
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get titleNotes;

  /// Tab showing the note's markdown source for editing
  ///
  /// In en, this message translates to:
  /// **'Write'**
  String get tabNotesWrite;

  /// Tab showing the note as formatted text
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get tabNotesPreview;

  /// Placeholder text of the empty note editor
  ///
  /// In en, this message translates to:
  /// **'Write a note about this item. Markdown is supported.'**
  String get helpNotesHint;

  /// Shown in the preview when nothing has been written
  ///
  /// In en, this message translates to:
  /// **'No note yet'**
  String get emptyNotes;

  /// Writes the note
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get tooltipNotesSave;

  /// Confirms the note was written
  ///
  /// In en, this message translates to:
  /// **'Note saved'**
  String get labelNotesSaved;

  /// Shown when writing the note failed
  ///
  /// In en, this message translates to:
  /// **'The note could not be saved'**
  String get errorNotesSaveFailed;

  /// Removes the note from this item
  ///
  /// In en, this message translates to:
  /// **'Delete note'**
  String get tooltipNotesDelete;

  /// Title of the delete confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete this note?'**
  String get titleNotesDelete;

  /// Body of the delete confirmation, making clear the media is untouched
  ///
  /// In en, this message translates to:
  /// **'The note will be removed. The file is not changed.'**
  String get bodyNotesDelete;

  /// Confirms the note was removed
  ///
  /// In en, this message translates to:
  /// **'Note deleted'**
  String get labelNotesDeleted;

  /// Closes a note dialog without doing anything
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionNotesCancel;

  /// How much of the note length budget is used
  ///
  /// In en, this message translates to:
  /// **'{used} of {total} characters'**
  String bodyNotesCharacterCount(int used, int total);

  /// Shown when the note is past the length cap
  ///
  /// In en, this message translates to:
  /// **'This note is too long to save'**
  String get bodyNotesTooLong;

  /// Title of the unsaved changes prompt
  ///
  /// In en, this message translates to:
  /// **'Leave unsaved?'**
  String get titleNotesDiscard;

  /// Body of the unsaved changes prompt
  ///
  /// In en, this message translates to:
  /// **'Your changes to this note will be lost.'**
  String get bodyNotesDiscard;

  /// Leaves the note editor and loses the changes
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get actionNotesDiscardLeave;

  /// Stays in the note editor
  ///
  /// In en, this message translates to:
  /// **'Keep writing'**
  String get actionNotesDiscardKeep;

  /// Shown when a link in a note uses a scheme the app will not launch
  ///
  /// In en, this message translates to:
  /// **'The app does not open this kind of link'**
  String get bodyNotesLinkBlocked;

  /// Label of the note line in the details sheet
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get titleNotesDetailsLabel;

  /// Details sheet action when the item has no note yet
  ///
  /// In en, this message translates to:
  /// **'Add a note'**
  String get labelNotesAddFromDetails;

  /// Home screen entry point for the PDF image tool
  ///
  /// In en, this message translates to:
  /// **'Images from PDF'**
  String get titlePdfImagesOpen;

  /// Title of the PDF image extraction screen
  ///
  /// In en, this message translates to:
  /// **'Images in a PDF'**
  String get titlePdfImages;

  /// Opens the system file picker for a PDF
  ///
  /// In en, this message translates to:
  /// **'Choose a PDF'**
  String get actionPdfImagesPick;

  /// Picks a different PDF once one has been read
  ///
  /// In en, this message translates to:
  /// **'Choose another PDF'**
  String get tooltipPdfImagesChooseAnother;

  /// Shown while a PDF is being parsed
  ///
  /// In en, this message translates to:
  /// **'Reading the PDF'**
  String get labelPdfImagesReading;

  /// Title of the empty state before a PDF is picked
  ///
  /// In en, this message translates to:
  /// **'No PDF chosen yet'**
  String get titlePdfImagesEmpty;

  /// Body of the empty state, making clear the source file is untouched
  ///
  /// In en, this message translates to:
  /// **'Pick a PDF and the app will list the pictures inside it. The PDF itself is never changed.'**
  String get bodyPdfImagesEmpty;

  /// Shown when a PDF was read but had no image objects
  ///
  /// In en, this message translates to:
  /// **'This PDF holds no pictures'**
  String get bodyPdfImagesNone;

  /// How many pictures the PDF held
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 picture found} other{{count} pictures found}}'**
  String bodyPdfImagesFound(int count);

  /// How many pictures were found but cannot be extracted
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 could not be read} other{{count} could not be read}}'**
  String bodyPdfImagesSkippedCount(int count);

  /// Writes the ticked pictures into the gallery
  ///
  /// In en, this message translates to:
  /// **'Save selected'**
  String get labelPdfImagesSave;

  /// Shown while pictures are being written
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get labelPdfImagesSaving;

  /// Confirms how many pictures were written
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 picture saved to the gallery} other{{count} pictures saved to the gallery}}'**
  String bodyPdfImagesSavedCount(int count);

  /// Reports how many pictures failed to save
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 could not be saved} other{{count} could not be saved}}'**
  String bodyPdfImagesSaveFailedCount(int count);

  /// Ticks every picture that can be saved
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get actionPdfImagesSelectAll;

  /// Unticks every picture
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get labelPdfImagesClearSelection;

  /// Shown when save is tapped with nothing ticked
  ///
  /// In en, this message translates to:
  /// **'Tick at least one picture to save'**
  String get bodyPdfImagesNothingSelected;

  /// Warns that the image count cap was reached
  ///
  /// In en, this message translates to:
  /// **'Only the first pictures were read, because this PDF holds a great many.'**
  String get bodyPdfImagesTruncated;

  /// Shown when MediaStore was unavailable and a plain folder was used
  ///
  /// In en, this message translates to:
  /// **'Saved to the app folder, because the gallery could not be written to'**
  String get bodyPdfImagesFallbackDirectory;

  /// Pixel size of one extracted picture
  ///
  /// In en, this message translates to:
  /// **'{width} by {height}'**
  String bodyPdfImageSize(int width, int height);

  /// Refusal: the chosen file has no PDF header
  ///
  /// In en, this message translates to:
  /// **'This file is not a PDF'**
  String get bodyPdfRefusedNotPdf;

  /// Refusal: the PDF is encrypted
  ///
  /// In en, this message translates to:
  /// **'This PDF is password protected, so it cannot be opened'**
  String get bodyPdfRefusedEncrypted;

  /// Refusal: the PDF is past the size cap
  ///
  /// In en, this message translates to:
  /// **'This PDF is too large to open'**
  String get bodyPdfRefusedTooLarge;

  /// Refusal: anything else
  ///
  /// In en, this message translates to:
  /// **'This PDF could not be read'**
  String get bodyPdfRefusedUnreadable;

  /// Why one picture was skipped: unsupported filter
  ///
  /// In en, this message translates to:
  /// **'Compressed in a way the app cannot read'**
  String get bodyPdfSkipUnsupportedFilter;

  /// Why one picture was skipped: unsupported colour space
  ///
  /// In en, this message translates to:
  /// **'Uses a colour space the app cannot read'**
  String get bodyPdfSkipUnsupportedColor;

  /// Why one picture was skipped: unsupported bit depth
  ///
  /// In en, this message translates to:
  /// **'Uses a colour depth the app cannot read'**
  String get bodyPdfSkipUnsupportedDepth;

  /// Why one picture was skipped: past the caps
  ///
  /// In en, this message translates to:
  /// **'Too large to pull out'**
  String get bodyPdfSkipTooLarge;

  /// Why one picture was skipped: the stream does not match its size
  ///
  /// In en, this message translates to:
  /// **'The picture data is incomplete'**
  String get bodyPdfSkipMalformed;

  /// Why one picture was skipped: decompression failed
  ///
  /// In en, this message translates to:
  /// **'The picture could not be decompressed'**
  String get errorPdfSkipDecodeFailed;

  /// Heading of the appearance group on the settings screen
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get titleSettingsAppearance;

  /// Heading of the language group on the settings screen
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get titleSettingsLanguage;

  /// Heading of the safety group on the settings screen
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get titleSettingsSafety;

  /// Title of the privacy settings screen and its card on the settings screen
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get titleSettingsPrivacy;

  /// Heading of the developer-only group, shown on dev builds
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get titleSettingsDeveloper;

  /// Language choice that follows the phone's own language
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get titleLanguageSystem;

  /// Name of the English language, written in English
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get titleLanguageEnglish;

  /// Name of the Malayalam language, written in Malayalam
  ///
  /// In en, this message translates to:
  /// **'മലയാളം'**
  String get titleLanguageMalayalam;

  /// Note under the language row saying the change is immediate
  ///
  /// In en, this message translates to:
  /// **'The app changes language at once. No restart is needed.'**
  String get descLanguageSubtitle;

  /// Label of the grid column count setting
  ///
  /// In en, this message translates to:
  /// **'Grid density'**
  String get labelGridDensity;

  /// Note under the grid density setting
  ///
  /// In en, this message translates to:
  /// **'How many photos fit across the timeline. Pinching the grid changes it too.'**
  String get descGridDensitySubtitle;

  /// Shows the chosen number of grid columns
  ///
  /// In en, this message translates to:
  /// **'{count} per row'**
  String labelGridDensityValue(int count);

  /// Label of the switch that shows the flashback memories row
  ///
  /// In en, this message translates to:
  /// **'Show memories'**
  String get titleShowFlashbacks;

  /// Note under the show memories switch
  ///
  /// In en, this message translates to:
  /// **'A row of photos from this day in past years, at the top of the timeline.'**
  String get descShowFlashbacksSubtitle;

  /// Label of the switch that asks again before a destructive action
  ///
  /// In en, this message translates to:
  /// **'Ask before deleting'**
  String get titleConfirmDestructive;

  /// Note under the confirm-before-deleting switch
  ///
  /// In en, this message translates to:
  /// **'Ask one more time before a delete or an overwrite. Some warnings always appear, whatever this is set to.'**
  String get descConfirmDestructiveSubtitle;

  /// Title of the privacy summary row on the settings screen
  ///
  /// In en, this message translates to:
  /// **'No remote server'**
  String get titlePrivacyNoServer;

  /// Body of the privacy summary row on the settings screen
  ///
  /// In en, this message translates to:
  /// **'Your photos, tags and notes stay on this phone. Nothing is uploaded, and there is no account. Internet access is used only by the transfer screen, to reach another phone on your own Wi-Fi.'**
  String get bodyPrivacyNoServer;

  /// Shows the build number beside the version
  ///
  /// In en, this message translates to:
  /// **'Build {build}'**
  String bodyAboutBuild(String build);

  /// Label for the build date row on the About screen
  ///
  /// In en, this message translates to:
  /// **'Build date'**
  String get titleAboutBuildDate;

  /// Message when no mail app can open an About screen email row
  ///
  /// In en, this message translates to:
  /// **'No app on this phone can open that address.'**
  String get errorAboutMailFailed;

  /// Note under the settings row that opens the vault settings
  ///
  /// In en, this message translates to:
  /// **'Lock timing, PIN and shredding'**
  String get descVaultSettingsOpenSubtitle;

  /// Note under the settings row that opens the backup screen
  ///
  /// In en, this message translates to:
  /// **'Password-protected backup and restore'**
  String get descBackupOpenSubtitle;

  /// Title of the reset settings row and dialog
  ///
  /// In en, this message translates to:
  /// **'Reset settings'**
  String get titleSettingsReset;

  /// Body of the reset settings confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Put every setting on this screen back to how it started. Your photos, tags, albums and vault are not touched.'**
  String get bodySettingsReset;

  /// Confirmation shown after the settings are reset
  ///
  /// In en, this message translates to:
  /// **'Settings put back to the defaults.'**
  String get bodySettingsResetDone;

  /// Dismisses the settings reset dialog without changing anything
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionSettingsCancel;

  /// Confirms the settings reset in the dialog
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get actionSettingsResetConfirm;

  /// Title of the help section on settings screen
  ///
  /// In en, this message translates to:
  /// **'Help & Guides'**
  String get helpSettings;

  /// Subtitle for the help section on settings screen
  ///
  /// In en, this message translates to:
  /// **'Explore guides, pro-tips and offline guarantees for every feature'**
  String get descSettingsHelpSubtitle;

  /// Header for the about section in settings
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get labelSettingsAbout;

  /// Header for overview section in help topic
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get helpOverview;

  /// Header for how to use section in help topic
  ///
  /// In en, this message translates to:
  /// **'How to use'**
  String get helpHowToUse;

  /// Header for tips and shortcuts section in help topic
  ///
  /// In en, this message translates to:
  /// **'Tips & shortcuts'**
  String get helpTips;

  /// Header for privacy and offline guarantee in help topic
  ///
  /// In en, this message translates to:
  /// **'Privacy & offline guarantee'**
  String get helpPrivacy;

  /// Badge indicating 100% offline functionality
  ///
  /// In en, this message translates to:
  /// **'100% Offline'**
  String get helpBadgeOffline;

  /// Badge indicating hardware-backed encryption
  ///
  /// In en, this message translates to:
  /// **'Hardware Encrypted'**
  String get helpBadgeEncrypted;

  /// Badge indicating local network only
  ///
  /// In en, this message translates to:
  /// **'Local Wi-Fi Only'**
  String get helpBadgeLocal;

  /// Badge indicating non-destructive operations
  ///
  /// In en, this message translates to:
  /// **'Non-Destructive'**
  String get helpBadgeSafe;

  /// Title of the timeline help topic
  ///
  /// In en, this message translates to:
  /// **'Timeline & Memories'**
  String get helpTopicTimelineTitle;

  /// Summary of timeline help topic
  ///
  /// In en, this message translates to:
  /// **'Browse photos by date, pinch to change grid size, and view flashbacks.'**
  String get helpTopicTimelineSummary;

  /// Overview of timeline help topic
  ///
  /// In en, this message translates to:
  /// **'The timeline organizes all your indexed photos and videos in reverse chronological order with date headers. It includes an \'On This Day\' flashback carousel showing photos from today in past years.'**
  String get helpTopicTimelineOverview;

  /// Steps for timeline help topic
  ///
  /// In en, this message translates to:
  /// **'• Pinch in or out to dynamically switch between 1 and 5 columns.\n• Drag the floating date scrubber on the right to jump quickly through months and years.\n• Tap any photo or video to open it in high resolution.'**
  String get helpTopicTimelineSteps;

  /// Tips for timeline help topic
  ///
  /// In en, this message translates to:
  /// **'• Long-press any photo to enter multi-selection mode for batch actions.\n• You can toggle flashback memories on or off in Settings.'**
  String get helpTopicTimelineTips;

  /// Privacy note for timeline help topic
  ///
  /// In en, this message translates to:
  /// **'All timeline grouping and date indexing happen strictly on device using local SQLite. No remote server is ever contacted.'**
  String get helpTopicTimelinePrivacy;

  /// Title of the viewer help topic
  ///
  /// In en, this message translates to:
  /// **'Fullscreen Viewer & Video Player'**
  String get helpTopicViewerTitle;

  /// Summary of viewer help topic
  ///
  /// In en, this message translates to:
  /// **'High-resolution viewer with gestures, EXIF details, and hardware video playback.'**
  String get helpTopicViewerSummary;

  /// Overview of viewer help topic
  ///
  /// In en, this message translates to:
  /// **'View photos and videos with smooth hardware acceleration. Swipe through your timeline seamlessly with responsive gesture controls.'**
  String get helpTopicViewerOverview;

  /// Steps for viewer help topic
  ///
  /// In en, this message translates to:
  /// **'• Double-tap or pinch to zoom into fine details.\n• Swipe down to dismiss and return to the timeline.\n• Swipe up to view the EXIF metadata drawer (camera, exposure, resolution, location).\n• While watching video: swipe up/down on left for brightness, on right for volume, or swipe horizontally to seek.'**
  String get helpTopicViewerSteps;

  /// Tips for viewer help topic
  ///
  /// In en, this message translates to:
  /// **'• Use the video controls to adjust playback speed (0.25x to 2.0x), step frame-by-frame, or repeat video in a loop.\n• Tap the overflow menu for quick access to editing, converting, scanning, and notes.'**
  String get helpTopicViewerTips;

  /// Privacy note for viewer help topic
  ///
  /// In en, this message translates to:
  /// **'EXIF metadata is parsed and cached locally in SQLite. Video decoding is hardware-accelerated without any network streaming components.'**
  String get helpTopicViewerPrivacy;

  /// Title of the photo editor help topic
  ///
  /// In en, this message translates to:
  /// **'Photo Editor & Markup'**
  String get helpTopicEditorTitle;

  /// Summary of photo editor help topic
  ///
  /// In en, this message translates to:
  /// **'Crop, rotate, adjust colors, apply filters, doodle markup, and redact private areas.'**
  String get helpTopicEditorSummary;

  /// Overview of photo editor help topic
  ///
  /// In en, this message translates to:
  /// **'A full-featured non-destructive photo editor with transformations, color adjustments, artistic filters, freehand markup, privacy redaction, and watermarking.'**
  String get helpTopicEditorOverview;

  /// Steps for photo editor help topic
  ///
  /// In en, this message translates to:
  /// **'• Open any photo and tap the Edit icon in the toolbar.\n• Transform: Crop with standard aspect ratios, rotate quarter turns, flip, or straighten.\n• Adjust: Fine-tune exposure, contrast, highlights, shadows, warmth, and RGB curves.\n• Markup & Redact: Draw shapes, add text, or redact sensitive areas using Gaussian blur, pixelation, or blackout.\n• Tap Save to export.'**
  String get helpTopicEditorSteps;

  /// Tips for photo editor help topic
  ///
  /// In en, this message translates to:
  /// **'• Privacy redactions permanently replace underlying pixels in the exported image.\n• Full undo and redo history is available throughout the editing session.'**
  String get helpTopicEditorTips;

  /// Privacy note for photo editor help topic
  ///
  /// In en, this message translates to:
  /// **'All image operations are performed completely offline on a background isolate. Edits are saved as a new version beside the original, never overwriting your original photo without consent.'**
  String get helpTopicEditorPrivacy;

  /// Title of format converter help topic
  ///
  /// In en, this message translates to:
  /// **'Format Converter & Compression'**
  String get helpTopicConverterTitle;

  /// Summary of format converter help topic
  ///
  /// In en, this message translates to:
  /// **'Convert formats (JPEG, PNG, WEBP, BMP), compress file sizes, and trim videos.'**
  String get helpTopicConverterSummary;

  /// Overview of format converter help topic
  ///
  /// In en, this message translates to:
  /// **'Convert photos between popular image formats, compress file sizes with real-time size estimation, extract still frames from video, convert video clips to GIF, and trim videos losslessly.'**
  String get helpTopicConverterOverview;

  /// Steps for format converter help topic
  ///
  /// In en, this message translates to:
  /// **'• Select Convert from the viewer overflow menu.\n• Choose target format (JPEG, PNG, WEBP, BMP) and adjust the quality slider.\n• Set resize mode (percentage, longest side, or custom dimensions) if desired.\n• Tap Convert to generate the optimized file.'**
  String get helpTopicConverterSteps;

  /// Tips for format converter help topic
  ///
  /// In en, this message translates to:
  /// **'• In Video Tools: Use lossless trimming to cut sections without re-encoding or quality loss.\n• Create animated GIFs from video clips with custom framerate and loop settings.'**
  String get helpTopicConverterTips;

  /// Privacy note for format converter help topic
  ///
  /// In en, this message translates to:
  /// **'All image and video conversions take place entirely on-device with zero network transmission. Results are saved as new files.'**
  String get helpTopicConverterPrivacy;

  /// Title of PDF tools help topic
  ///
  /// In en, this message translates to:
  /// **'PDF Export & Image Extraction'**
  String get helpTopicPdfTitle;

  /// Summary of PDF tools help topic
  ///
  /// In en, this message translates to:
  /// **'Export multi-image PDF documents and extract embedded pictures from PDFs offline.'**
  String get helpTopicPdfSummary;

  /// Overview of PDF tools help topic
  ///
  /// In en, this message translates to:
  /// **'Create professional PDF documents from selected photos with custom layouts, or extract high-quality images embedded inside PDF documents.'**
  String get helpTopicPdfOverview;

  /// Steps for PDF tools help topic
  ///
  /// In en, this message translates to:
  /// **'• PDF Export: Select photos, choose page size (A4, Letter), orientation, margins, and tap Export.\n• PDF Image Extract: Open the tool from the timeline menu, pick a PDF file, review detected pictures, and tap Save to extract them to your gallery.'**
  String get helpTopicPdfSteps;

  /// Tips for PDF tools help topic
  ///
  /// In en, this message translates to:
  /// **'• Reorder photos before PDF export to control page sequence.\n• The PDF extractor walks file objects directly, working even if the PDF\'s cross-reference table is damaged.'**
  String get helpTopicPdfTips;

  /// Privacy note for PDF tools help topic
  ///
  /// In en, this message translates to:
  /// **'PDF generation and extraction are executed 100% offline using an app-private sandbox. No PDF data is ever uploaded to any cloud service.'**
  String get helpTopicPdfPrivacy;

  /// Title of search and tags help topic
  ///
  /// In en, this message translates to:
  /// **'Search & Tags'**
  String get helpTopicSearchTitle;

  /// Summary of search and tags help topic
  ///
  /// In en, this message translates to:
  /// **'Instant SQLite FTS5 search with query filters and 12-color tag management.'**
  String get helpTopicSearchSummary;

  /// Overview of search and tags help topic
  ///
  /// In en, this message translates to:
  /// **'Locate photos and videos instantly using full-text search across titles, notes, camera models, and tags, with prefix operators and multi-criteria filters.'**
  String get helpTopicSearchOverview;

  /// Steps for search and tags help topic
  ///
  /// In en, this message translates to:
  /// **'• Tap the Search icon on the timeline.\n• Type any search keywords, or use prefixes: \'tag:nature\', \'type:video\', \'camera:sony\', \'place:kochi\', \'before:2024-01-01\'.\n• Tap the Filter icon to combine date range, media type, favorites, and size filters.\n• To manage tags, visit the Tags screen from the timeline menu.'**
  String get helpTopicSearchSteps;

  /// Tips for search and tags help topic
  ///
  /// In en, this message translates to:
  /// **'• Create custom tags with 12 distinct Material colors.\n• Tags update the search index immediately, making photos findable in milliseconds.'**
  String get helpTopicSearchTips;

  /// Privacy note for search and tags help topic
  ///
  /// In en, this message translates to:
  /// **'Search indexes are stored locally in SQLite with FTS5. Your search queries and history remain strictly on your device.'**
  String get helpTopicSearchPrivacy;

  /// Title of albums help topic
  ///
  /// In en, this message translates to:
  /// **'Albums & Smart Albums'**
  String get helpTopicAlbumsTitle;

  /// Summary of albums help topic
  ///
  /// In en, this message translates to:
  /// **'Organize into virtual albums, browse device folders, and view smart auto-albums.'**
  String get helpTopicAlbumsSummary;

  /// Overview of albums help topic
  ///
  /// In en, this message translates to:
  /// **'Manage your collection with user-created virtual albums, physical device folder browsing, and smart auto-albums that organize media automatically.'**
  String get helpTopicAlbumsOverview;

  /// Steps for albums help topic
  ///
  /// In en, this message translates to:
  /// **'• Tap Albums on the timeline app bar.\n• Virtual Albums: Tap \'+\' to create an album, add media, reorder items, or set a custom cover photo.\n• Smart Albums: Automatically gathers Favorites, Videos, GIFs, RAW photos, Panoramas, and Recently Added.\n• Device Folders: Browse physical folders on your storage (Camera, Screenshots, WhatsApp, Downloads).'**
  String get helpTopicAlbumsSteps;

  /// Tips for albums help topic
  ///
  /// In en, this message translates to:
  /// **'• Pin favorite albums to keep them at the top of the list.\n• Virtual albums do not duplicate media files on disk, saving storage space.'**
  String get helpTopicAlbumsTips;

  /// Privacy note for albums help topic
  ///
  /// In en, this message translates to:
  /// **'Album memberships and metadata are stored in the local database. Device folder scanning adheres to Android scoped storage.'**
  String get helpTopicAlbumsPrivacy;

  /// Title of duplicate cleaner help topic
  ///
  /// In en, this message translates to:
  /// **'Duplicate Cleaner'**
  String get helpTopicCleanerTitle;

  /// Summary of duplicate cleaner help topic
  ///
  /// In en, this message translates to:
  /// **'Detect exact and visually similar duplicates with side-by-side comparison.'**
  String get helpTopicCleanerSummary;

  /// Overview of duplicate cleaner help topic
  ///
  /// In en, this message translates to:
  /// **'Free up storage by identifying exact duplicate files (via SHA-256 hash) and visually similar photos (via perceptual pHash and dHash).'**
  String get helpTopicCleanerOverview;

  /// Steps for duplicate cleaner help topic
  ///
  /// In en, this message translates to:
  /// **'• Open Duplicate Cleaner from the timeline menu.\n• Tap Scan to analyze your library.\n• Review duplicate groups and tap any group for side-by-side comparison.\n• Use \'Keep Best Photo\' to automatically pick the highest resolution, sharpest image and move others to trash.'**
  String get helpTopicCleanerSteps;

  /// Tips for duplicate cleaner help topic
  ///
  /// In en, this message translates to:
  /// **'• Perceptual hashing finds photos taken in rapid succession or with minor edits.\n• No file is ever deleted without your confirmation.'**
  String get helpTopicCleanerTips;

  /// Privacy note for duplicate cleaner help topic
  ///
  /// In en, this message translates to:
  /// **'Hashing runs completely locally. Downsampled 32x32 previews are used for DCT computation and cleared immediately.'**
  String get helpTopicCleanerPrivacy;

  /// Title of vault help topic
  ///
  /// In en, this message translates to:
  /// **'Secure Private Vault'**
  String get helpTopicVaultTitle;

  /// Summary of vault help topic
  ///
  /// In en, this message translates to:
  /// **'Hardware-backed AES-256-GCM encryption, biometric & PIN authentication, and shredding.'**
  String get helpTopicVaultSummary;

  /// Overview of vault help topic
  ///
  /// In en, this message translates to:
  /// **'Protect sensitive photos and videos in an encrypted vault. Payloads are encrypted with a 256-bit key protected by the Android Keystore, with biometric unlock and screenshot prevention.'**
  String get helpTopicVaultOverview;

  /// Steps for vault help topic
  ///
  /// In en, this message translates to:
  /// **'• Tap the Vault icon on the timeline to unlock or configure your vault.\n• Set a master PIN (and enable Biometrics for convenient access).\n• Import media from the timeline or viewer. Choose whether to securely shred the original file.\n• View encrypted photos and videos safely inside the vault.'**
  String get helpTopicVaultSteps;

  /// Tips for vault help topic
  ///
  /// In en, this message translates to:
  /// **'• Screenshot protection (FLAG_SECURE) is active while inside the vault.\n• The vault locks automatically when the app is switched to the background or after an idle timeout.'**
  String get helpTopicVaultTips;

  /// Privacy note for vault help topic
  ///
  /// In en, this message translates to:
  /// **'Decrypted data is held in memory only. Keys never leave the Android Keystore hardware module, and no plaintext files are left on disk.'**
  String get helpTopicVaultPrivacy;

  /// Title of local transfer help topic
  ///
  /// In en, this message translates to:
  /// **'Local Wi-Fi Transfer'**
  String get helpTopicSyncTitle;

  /// Summary of local transfer help topic
  ///
  /// In en, this message translates to:
  /// **'Direct peer-to-peer transfer between devices on the same Wi-Fi with zero internet.'**
  String get helpTopicSyncSummary;

  /// Overview of local transfer help topic
  ///
  /// In en, this message translates to:
  /// **'Transfer photos and videos directly between two phones on the same local Wi-Fi router. Connections are end-to-end encrypted with an authenticated handshake.'**
  String get helpTopicSyncOverview;

  /// Steps for local transfer help topic
  ///
  /// In en, this message translates to:
  /// **'• On receiving device: Open Transfer > Receive to show the QR pairing code.\n• On sending device: Open Transfer > Send and scan the code (or enter the 6-character code).\n• Select photos or albums to transfer and start the transfer.\n• Received files are verified by SHA-256 digest and published directly to your gallery.'**
  String get helpTopicSyncSteps;

  /// Tips for local transfer help topic
  ///
  /// In en, this message translates to:
  /// **'• No internet access or router configuration is needed; devices connect directly over local IP addresses.\n• The transfer socket binds only while the transfer screen is open and shuts down immediately when you leave.'**
  String get helpTopicSyncTips;

  /// Privacy note for local transfer help topic
  ///
  /// In en, this message translates to:
  /// **'Connections to external or public IP addresses are strictly blocked by LocalAddressRules. Zero tracking, zero telemetry, zero cloud intermediary.'**
  String get helpTopicSyncPrivacy;

  /// Title of backup help topic
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get helpTopicBackupTitle;

  /// Summary of backup help topic
  ///
  /// In en, this message translates to:
  /// **'Create password-protected encrypted .gbak archives and restore safely.'**
  String get helpTopicBackupSummary;

  /// Overview of backup help topic
  ///
  /// In en, this message translates to:
  /// **'Safeguard your tags, album structures, media notes, and user metadata in an encrypted GBAK backup archive protected by AES-256-GCM.'**
  String get helpTopicBackupOverview;

  /// Steps for backup help topic
  ///
  /// In en, this message translates to:
  /// **'• Tap Backup from the timeline menu.\n• Create Backup: Enter a strong password and save the backup file via Android\'s document picker.\n• Restore: Select a previously exported .gbak file, enter your password, inspect the preview summary, and apply.'**
  String get helpTopicBackupSteps;

  /// Tips for backup help topic
  ///
  /// In en, this message translates to:
  /// **'• The restore process is non-destructive: it fills gaps and merges tags and albums without overwriting existing data.\n• Keep a safe record of your backup password; without it, the encrypted archive cannot be recovered.'**
  String get helpTopicBackupTips;

  /// Privacy note for backup help topic
  ///
  /// In en, this message translates to:
  /// **'Backup files are encrypted using PBKDF2-derived keys and AES-256-GCM. Backups are stored wherever you choose on your device or SD card.'**
  String get helpTopicBackupPrivacy;

  /// Title of scanner and OCR help topic
  ///
  /// In en, this message translates to:
  /// **'QR Scanner & OCR'**
  String get helpTopicScannerTitle;

  /// Summary of scanner and OCR help topic
  ///
  /// In en, this message translates to:
  /// **'Scan QR/barcodes from photos with safe schemes, and extract text with offline OCR.'**
  String get helpTopicScannerSummary;

  /// Overview of scanner and OCR help topic
  ///
  /// In en, this message translates to:
  /// **'Analyze existing photos to scan QR codes and barcodes, or run offline Tesseract optical character recognition to extract English and Malayalam text.'**
  String get helpTopicScannerOverview;

  /// Steps for scanner and OCR help topic
  ///
  /// In en, this message translates to:
  /// **'• Open a photo in the viewer and select \'Scan code\' or \'Extract text\' from the menu.\n• Scanned codes: View detected URL, Wi-Fi credentials, or text. Safe URL schemes (http, https, tel, mailto, sms, geo) can be opened with confirmation.\n• Extracted text: View recognized text, copy it to clipboard, or append it directly to the media item\'s notes.'**
  String get helpTopicScannerSteps;

  /// Tips for scanner and OCR help topic
  ///
  /// In en, this message translates to:
  /// **'• Optical character recognition uses bundled offline language models (English and Malayalam); no internet connection is required.\n• Wi-Fi codes allow copying network credentials securely or suggesting network connection without silent joining.'**
  String get helpTopicScannerTips;

  /// Privacy note for scanner and OCR help topic
  ///
  /// In en, this message translates to:
  /// **'All barcode decoding and OCR processing are executed locally on your device. Untrusted QR payloads are validated before launching external apps.'**
  String get helpTopicScannerPrivacy;

  /// Title of the default gallery app settings option
  ///
  /// In en, this message translates to:
  /// **'Default Gallery App'**
  String get titleSettingsDefaultApp;

  /// Subtitle explaining default app settings option
  ///
  /// In en, this message translates to:
  /// **'Set as default app for viewing photos and videos'**
  String get descSettingsDefaultAppSubtitle;

  /// Title of dialog explaining how to set default app
  ///
  /// In en, this message translates to:
  /// **'Set Default Gallery'**
  String get titleDefaultAppDialog;

  /// Instructions explaining how to make the app default in Android
  ///
  /// In en, this message translates to:
  /// **'To make this your default gallery:\n\n1. Open any photo or video on your device (e.g. from Files, Downloads, or messages).\n2. Choose SreerajP Image Video Gallery and tap \'Always\'.\n\nIf another app already opens your photos, first clear its default: Android Settings → Apps → that app → Open by default.'**
  String get bodyDefaultAppDialog;

  /// Title of the trash screen
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get titleTrash;

  /// Shown when the trash holds no items
  ///
  /// In en, this message translates to:
  /// **'Trash is empty'**
  String get emptyTrash;

  /// Explanation shown below the empty trash message
  ///
  /// In en, this message translates to:
  /// **'Items you delete are kept here until you empty the trash.'**
  String get descTrashEmptySubtitle;

  /// Button that permanently removes all trashed items
  ///
  /// In en, this message translates to:
  /// **'Empty trash'**
  String get tooltipTrashEmptyAction;

  /// Title of the empty trash confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Empty trash?'**
  String get titleTrashEmptyConfirm;

  /// Body of the empty trash confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all trashed items from your device storage. This action cannot be undone.'**
  String get bodyTrashEmptyConfirm;

  /// Button to permanently delete an item from storage
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get titleTrashDeletePermanentlyAction;

  /// Title of permanent deletion confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete permanently?'**
  String get titleTrashDeletePermanentlyConfirm;

  /// Body of permanent deletion confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'This item will be permanently deleted from your device storage. This action cannot be undone.'**
  String get bodyTrashDeletePermanentlyConfirm;

  /// Snackbar shown after an item is permanently deleted
  ///
  /// In en, this message translates to:
  /// **'Item permanently deleted'**
  String get bodyTrashDeletedPermanentlySnackbar;

  /// Button that restores items from the trash
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get actionTrashRestore;

  /// Button that restores every item from the trash
  ///
  /// In en, this message translates to:
  /// **'Restore all'**
  String get tooltipTrashRestoreAllAction;

  /// Body of the restore all confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Every item in the trash will be moved back to your library.'**
  String get bodyTrashRestoreAllConfirm;

  /// Snackbar shown after items are restored from trash
  ///
  /// In en, this message translates to:
  /// **'Restored from trash'**
  String get bodyTrashRestoredSnackbar;

  /// Snackbar shown after the trash is emptied
  ///
  /// In en, this message translates to:
  /// **'Trash emptied'**
  String get bodyTrashEmptiedSnackbar;

  /// Shows how many items are in the trash
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item in trash} other{{count} items in trash}}'**
  String bodyTrashItemCount(int count);

  /// Subtitle for the appearance card on the settings hub
  ///
  /// In en, this message translates to:
  /// **'Theme, grid density, memories'**
  String get descSettingsAppearanceSubtitle;

  /// Subtitle for the language card on the settings hub
  ///
  /// In en, this message translates to:
  /// **'System, English, Malayalam, Sanskrit'**
  String get descSettingsLanguageSubtitle;

  /// Subtitle for the safety card on the settings hub
  ///
  /// In en, this message translates to:
  /// **'Confirmation before destructive actions'**
  String get descSettingsSafetySubtitle;

  /// Subtitle for the default app card on the settings hub
  ///
  /// In en, this message translates to:
  /// **'Set as default gallery app'**
  String get descSettingsDefaultAppCardSubtitle;

  /// Subtitle for the privacy card on the settings hub
  ///
  /// In en, this message translates to:
  /// **'Hide content and vault'**
  String get descSettingsPrivacySubtitle;

  /// Subtitle for the help card on the settings hub
  ///
  /// In en, this message translates to:
  /// **'Guides and privacy guarantees for every feature'**
  String get descSettingsHelpCardSubtitle;

  /// Subtitle for the about card on the settings hub
  ///
  /// In en, this message translates to:
  /// **'Version, author and licence'**
  String get descSettingsAboutSubtitle;

  /// Subtitle for the developer card on the settings hub
  ///
  /// In en, this message translates to:
  /// **'Media scanner tools'**
  String get descSettingsDeveloperSubtitle;

  /// Title of the confirmation dialog before moving an item to trash
  ///
  /// In en, this message translates to:
  /// **'Move to trash?'**
  String get titleViewerTrashConfirm;

  /// Body message of the confirmation dialog before moving an item to trash
  ///
  /// In en, this message translates to:
  /// **'This item will be moved to the trash. You can restore it anytime from the Trash album.'**
  String get bodyViewerTrashConfirm;

  /// Snackbar message shown after moving an item to trash
  ///
  /// In en, this message translates to:
  /// **'Moved to trash'**
  String get bodyViewerTrashSuccess;

  /// Undo action label in the snackbar after trashing an item
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get actionViewerTrashUndo;

  /// Title of the A/B photo comparison screen
  ///
  /// In en, this message translates to:
  /// **'A/B Comparison'**
  String get titleComparePhotos;

  /// Label for split screen comparison mode
  ///
  /// In en, this message translates to:
  /// **'Split View'**
  String get labelCompareModeSplit;

  /// Label for sliding curtain comparison mode
  ///
  /// In en, this message translates to:
  /// **'Sliding Curtain'**
  String get labelCompareModeCurtain;

  /// Label for horizontal split orientation
  ///
  /// In en, this message translates to:
  /// **'Side by Side'**
  String get labelCompareSplitHorizontal;

  /// Label for vertical split orientation
  ///
  /// In en, this message translates to:
  /// **'Top and Bottom'**
  String get labelCompareSplitVertical;

  /// Status text when pan and zoom are synchronized
  ///
  /// In en, this message translates to:
  /// **'Pan & Zoom Locked'**
  String get bodyCompareSyncLocked;

  /// Status text when pan and zoom can be adjusted independently
  ///
  /// In en, this message translates to:
  /// **'Independent Pan & Zoom'**
  String get bodyCompareSyncUnlocked;

  /// Tooltip and label to swap Photo A and Photo B positions
  ///
  /// In en, this message translates to:
  /// **'Swap Photos'**
  String get tooltipCompareSwap;

  /// Tooltip and button label to reset zoom back to 1.0x
  ///
  /// In en, this message translates to:
  /// **'Reset Zoom'**
  String get tooltipCompareResetZoom;

  /// Tooltip and label for comparing photo technical metadata
  ///
  /// In en, this message translates to:
  /// **'Compare Details'**
  String get tooltipCompareDetails;

  /// Label identifying the first photo
  ///
  /// In en, this message translates to:
  /// **'Photo A'**
  String get labelComparePhotoA;

  /// Label identifying the second photo
  ///
  /// In en, this message translates to:
  /// **'Photo B'**
  String get labelComparePhotoB;

  /// Option in media viewer to compare with previous photo
  ///
  /// In en, this message translates to:
  /// **'Compare previous'**
  String get titleCompareWithPrevious;

  /// Option in media viewer to compare with next photo
  ///
  /// In en, this message translates to:
  /// **'Compare next'**
  String get titleCompareWithNext;

  /// Option in media viewer to choose any photo from gallery to compare
  ///
  /// In en, this message translates to:
  /// **'Pick from gallery'**
  String get titleCompareChooseFromGallery;

  /// Tooltip on the compare button
  ///
  /// In en, this message translates to:
  /// **'Compare photos'**
  String get tooltipCompare;

  /// Title of the photo picker sheet for comparison
  ///
  /// In en, this message translates to:
  /// **'Select a photo to compare with'**
  String get bodyCompareSelectSecondPhoto;

  /// Label for photo dimensions in comparison sheet
  ///
  /// In en, this message translates to:
  /// **'Dimensions'**
  String get labelCompareDimensions;

  /// Label for file size in comparison sheet
  ///
  /// In en, this message translates to:
  /// **'File Size'**
  String get labelCompareFileSize;

  /// Label for date taken in comparison sheet
  ///
  /// In en, this message translates to:
  /// **'Date Taken'**
  String get labelCompareDateTaken;

  /// Label for camera make and model in comparison sheet
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get labelCompareCamera;

  /// Label for ISO value in comparison sheet
  ///
  /// In en, this message translates to:
  /// **'ISO'**
  String get labelCompareIso;

  /// Label for aperture f-number in comparison sheet
  ///
  /// In en, this message translates to:
  /// **'Aperture'**
  String get labelCompareAperture;

  /// Label for shutter speed in comparison sheet
  ///
  /// In en, this message translates to:
  /// **'Shutter Speed'**
  String get labelCompareShutterSpeed;

  /// Label for focal length in comparison sheet
  ///
  /// In en, this message translates to:
  /// **'Focal Length'**
  String get labelCompareFocalLength;

  /// Label of the Timeline tab in bottom navigation
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get tabTimeline;

  /// Label of the Folders tab in bottom navigation
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get tabFolders;

  /// Label of the Albums tab in bottom navigation
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get tabAlbums;

  /// Title of the folders tab screen
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get titleFolders;

  /// Shown when no device folders have been indexed
  ///
  /// In en, this message translates to:
  /// **'No folders found'**
  String get emptyFolders;

  /// Hint shown below the empty folders message
  ///
  /// In en, this message translates to:
  /// **'Pull down to scan for photos and videos on your device.'**
  String get bodyFoldersEmpty;

  /// Title of the media privacy and EXIF scrubber tool
  ///
  /// In en, this message translates to:
  /// **'Privacy Scrubber'**
  String get tooltipPrivacyScrubberTitle;

  /// Subtitle explaining privacy scrubber capabilities
  ///
  /// In en, this message translates to:
  /// **'Strip sensitive EXIF metadata and fuzz GPS coordinates before sharing'**
  String get descPrivacyScrubberSubtitle;

  /// Overflow menu item for privacy scrubber
  ///
  /// In en, this message translates to:
  /// **'Privacy Scrubber'**
  String get titlePrivacyScrubberMenu;

  /// Title of the privacy card in details sheet
  ///
  /// In en, this message translates to:
  /// **'Media Privacy & EXIF'**
  String get titlePrivacyCard;

  /// Body description in the details sheet privacy card
  ///
  /// In en, this message translates to:
  /// **'Protect your privacy by stripping GPS location, camera serial numbers, and device identifiers before sharing.'**
  String get bodyPrivacyCard;

  /// Button to open privacy scrubber sheet
  ///
  /// In en, this message translates to:
  /// **'Open Privacy Controls'**
  String get bodyPrivacyOpenScrubber;

  /// Tab label for EXIF stripper
  ///
  /// In en, this message translates to:
  /// **'EXIF Stripper'**
  String get labelPrivacyTabStripper;

  /// Tab label for GPS geofence shifter
  ///
  /// In en, this message translates to:
  /// **'GPS Geofence Shifter'**
  String get labelPrivacyTabGeofence;

  /// Primary action button to strip metadata and share
  ///
  /// In en, this message translates to:
  /// **'Strip & Share'**
  String get actionPrivacyStripAndShare;

  /// Button to save stripped copy to gallery
  ///
  /// In en, this message translates to:
  /// **'Save Clean Copy'**
  String get actionPrivacySaveSanitized;

  /// Title of granular metadata options section
  ///
  /// In en, this message translates to:
  /// **'Choose What to Strip'**
  String get titlePrivacyGranular;

  /// Action to reset toggles to strip all metadata
  ///
  /// In en, this message translates to:
  /// **'Strip All'**
  String get labelPrivacyStripAll;

  /// Label indicating custom toggle selection
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get labelPrivacyCustom;

  /// Checkbox to strip location coordinates
  ///
  /// In en, this message translates to:
  /// **'GPS Location'**
  String get titlePrivacyOptionGps;

  /// Checkbox to strip hardware serial numbers
  ///
  /// In en, this message translates to:
  /// **'Serial Numbers'**
  String get titlePrivacyOptionSerials;

  /// Checkbox to strip timestamps
  ///
  /// In en, this message translates to:
  /// **'Capture Dates'**
  String get titlePrivacyOptionTimestamps;

  /// Checkbox to strip author and software tags
  ///
  /// In en, this message translates to:
  /// **'Author & Software'**
  String get titlePrivacyOptionAuthor;

  /// Error when image bytes cannot be read
  ///
  /// In en, this message translates to:
  /// **'Unable to read image data for privacy processing'**
  String get bodyPrivacyErrorReadingFile;

  /// Title of share sheet for sanitized media
  ///
  /// In en, this message translates to:
  /// **'Share Clean Copy'**
  String get titlePrivacyShare;

  /// Error when share sheet launch fails
  ///
  /// In en, this message translates to:
  /// **'Sharing could not be initiated'**
  String get errorPrivacyShareFailed;

  /// General error during sanitization
  ///
  /// In en, this message translates to:
  /// **'An error occurred while sanitizing media'**
  String get errorPrivacyProcess;

  /// Snackbar confirming sanitized copy saved
  ///
  /// In en, this message translates to:
  /// **'Sanitized copy saved to gallery'**
  String get bodyPrivacySavedToGallery;

  /// Error when saving sanitized copy fails
  ///
  /// In en, this message translates to:
  /// **'Failed to save sanitized image'**
  String get errorPrivacySaveFailed;

  /// Message when media has no GPS tags
  ///
  /// In en, this message translates to:
  /// **'No embedded GPS location found in this photo'**
  String get bodyPrivacyNoLocation;

  /// Label for geofence distance selector
  ///
  /// In en, this message translates to:
  /// **'Shift Distance Offset'**
  String get bodyGeofenceOffsetDistance;

  /// Tooltip for reroll button
  ///
  /// In en, this message translates to:
  /// **'Reroll random shift'**
  String get tooltipGeofenceReroll;

  /// Chip for randomized 2-5 km offset
  ///
  /// In en, this message translates to:
  /// **'Random (2–5 km)'**
  String get labelGeofenceRandomPreset;

  /// Summary of shift displacement
  ///
  /// In en, this message translates to:
  /// **'Shifted {summary}'**
  String bodyGeofenceShiftSummary(String summary);

  /// New fuzzed latitude and longitude coordinates
  ///
  /// In en, this message translates to:
  /// **'Shifted to {lat}, {lon}'**
  String bodyGeofenceFuzzedCoordinates(String lat, String lon);

  /// Explanation of how location fuzzing protects privacy
  ///
  /// In en, this message translates to:
  /// **'Adds an offset within 2–5 km to preserve general regional travel context while hiding exact residential street coordinates.'**
  String get descGeofenceExplanation;

  /// Share sheet title for fuzzed photo
  ///
  /// In en, this message translates to:
  /// **'Share Fuzzed Photo'**
  String get titleGeofenceShare;

  /// Action button to fuzz location and share
  ///
  /// In en, this message translates to:
  /// **'Fuzz & Share'**
  String get actionGeofenceShare;

  /// Action button to save fuzzed copy
  ///
  /// In en, this message translates to:
  /// **'Save Fuzzed Copy'**
  String get actionGeofenceSave;

  /// Snackbar confirming fuzzed copy saved
  ///
  /// In en, this message translates to:
  /// **'Geofuzzed copy saved to gallery'**
  String get bodyGeofenceSavedToGallery;

  /// Header when media has no GPS coordinates
  ///
  /// In en, this message translates to:
  /// **'No Location Found'**
  String get labelGeofenceNoCoordinates;

  /// Explanation when photo has no GPS metadata
  ///
  /// In en, this message translates to:
  /// **'This media item does not have embedded GPS coordinates to shift.'**
  String get bodyGeofenceNoCoordinates;

  /// Audit badge when sensitive EXIF tags are found
  ///
  /// In en, this message translates to:
  /// **'Sensitive Metadata Detected'**
  String get bodyPrivacyAuditSensitiveDetected;

  /// Audit badge when no sensitive EXIF tags are found
  ///
  /// In en, this message translates to:
  /// **'No Sensitive Metadata Detected'**
  String get bodyPrivacyAuditClean;

  /// Audit details list
  ///
  /// In en, this message translates to:
  /// **'Contains {gps} {camera}'**
  String bodyPrivacyAuditSensitiveDetails(String gps, String camera);

  /// Label indicating GPS presence in audit
  ///
  /// In en, this message translates to:
  /// **'GPS Coordinates'**
  String get labelPrivacyAuditGps;

  /// Label indicating camera identifiers in audit
  ///
  /// In en, this message translates to:
  /// **'Device Identifiers'**
  String get labelPrivacyAuditCamera;

  /// Description for clean metadata audit
  ///
  /// In en, this message translates to:
  /// **'This file does not contain embedded location or camera serial identifiers.'**
  String get bodyPrivacyAuditCleanDetails;

  /// Title of forensic inspector sheet
  ///
  /// In en, this message translates to:
  /// **'Lens & Sensor Data'**
  String get titleForensicInspector;

  /// Subtitle of forensic inspector
  ///
  /// In en, this message translates to:
  /// **'Deep technical optical and hardware forensic insights'**
  String get descForensicInspectorSubtitle;

  /// Button to launch forensic inspector
  ///
  /// In en, this message translates to:
  /// **'Inspect Lens Data'**
  String get actionForensicInspector;

  /// Quick summary of forensic metrics
  ///
  /// In en, this message translates to:
  /// **'Sensor crop factor, 35mm equivalent, shutter actuation, exposure bias'**
  String get helpForensicInspectorQuickHint;

  /// Message when no forensic EXIF tags are present
  ///
  /// In en, this message translates to:
  /// **'No forensic lens or sensor metadata found in this item.'**
  String get bodyForensicNoData;

  /// Card header for sensor and optics
  ///
  /// In en, this message translates to:
  /// **'Sensor & Optical Characteristics'**
  String get bodyForensicSectionSensorOptics;

  /// Card header for shutter and color
  ///
  /// In en, this message translates to:
  /// **'Mechanical Actuations & Color Space'**
  String get bodyForensicSectionMechanicsColor;

  /// Card header for serials and hardware
  ///
  /// In en, this message translates to:
  /// **'Hardware & Lens Serial Identity'**
  String get bodyForensicSectionHardwareIdentity;

  /// Label for sensor format classification
  ///
  /// In en, this message translates to:
  /// **'Sensor Format'**
  String get labelForensicSensorFormat;

  /// Label for sensor crop factor
  ///
  /// In en, this message translates to:
  /// **'Crop Factor'**
  String get labelForensicCropFactor;

  /// Label for 35mm equivalent focal length
  ///
  /// In en, this message translates to:
  /// **'35mm Equivalent'**
  String get labelForensicFocal35mm;

  /// Label for lens physical focal length
  ///
  /// In en, this message translates to:
  /// **'Real Focal Length'**
  String get labelForensicPhysicalFocalLength;

  /// Label for calculated hyperfocal distance
  ///
  /// In en, this message translates to:
  /// **'Hyperfocal Distance'**
  String get labelForensicHyperfocalDistance;

  /// Label for exposure compensation EV
  ///
  /// In en, this message translates to:
  /// **'Exposure Bias (EV)'**
  String get labelForensicExposureBias;

  /// Label for shutter actuation count
  ///
  /// In en, this message translates to:
  /// **'Shutter Releases'**
  String get labelForensicShutterActuations;

  /// Notice when shutter count is absent
  ///
  /// In en, this message translates to:
  /// **'Electronic shutter / Not reported'**
  String get bodyForensicShutterNotReported;

  /// Label for color space profile
  ///
  /// In en, this message translates to:
  /// **'Color Profile'**
  String get labelForensicColorProfile;

  /// Label for exposure program
  ///
  /// In en, this message translates to:
  /// **'Exposure Program'**
  String get labelForensicExposureProgram;

  /// Label for metering mode
  ///
  /// In en, this message translates to:
  /// **'Metering Mode'**
  String get labelForensicMeteringMode;

  /// Label for sensor sensing method
  ///
  /// In en, this message translates to:
  /// **'Sensing Method'**
  String get labelForensicSensingMethod;

  /// Label for scene capture type
  ///
  /// In en, this message translates to:
  /// **'Scene Capture Type'**
  String get labelForensicSceneCaptureType;

  /// Label for flash details
  ///
  /// In en, this message translates to:
  /// **'Flash Status'**
  String get labelForensicFlashStatus;

  /// Label for camera body serial number
  ///
  /// In en, this message translates to:
  /// **'Camera Serial Number'**
  String get labelForensicCameraSerial;

  /// Label for lens model
  ///
  /// In en, this message translates to:
  /// **'Lens Model'**
  String get labelForensicLensModel;

  /// Label for lens specification
  ///
  /// In en, this message translates to:
  /// **'Lens Specification'**
  String get labelForensicLensSpecification;

  /// Label for lens serial number
  ///
  /// In en, this message translates to:
  /// **'Lens Serial Number'**
  String get labelForensicLensSerial;

  /// Notice when hardware serial is not embedded
  ///
  /// In en, this message translates to:
  /// **'Not embedded in headers'**
  String get bodyForensicSerialNotEmbedded;

  /// Tooltip on the eye button that reveals the typed password
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get tooltipShowPassword;

  /// Tooltip on the eye button that hides the typed password again
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get tooltipHidePassword;

  /// Chip that picks how far to move the GPS position, in kilometres. {distance} is an already formatted number such as 2.0
  ///
  /// In en, this message translates to:
  /// **'{distance} km'**
  String labelDistanceKm(String distance);

  /// Badge on each side of the sliding comparison. {photo} is 'Photo A' or 'Photo B', {name} is the file name
  ///
  /// In en, this message translates to:
  /// **'{photo}: {name}'**
  String labelCompareBadge(String photo, String name);

  /// About screen row label for the app author
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get aboutDetailAuthor;

  /// About screen row label for the licence note
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get aboutDetailLicense;

  /// About screen row label for the code editors used to build the app
  ///
  /// In en, this message translates to:
  /// **'IDE used'**
  String get aboutDetailIdeUsed;

  /// About screen row label for the AI assistants used to build the app
  ///
  /// In en, this message translates to:
  /// **'AI used'**
  String get aboutDetailAiUsed;

  /// About screen row label for how the app reads media storage
  ///
  /// In en, this message translates to:
  /// **'Storage model'**
  String get aboutDetailStorageModel;

  /// About screen row label for the app's network rules
  ///
  /// In en, this message translates to:
  /// **'Network policy'**
  String get aboutDetailNetworkPolicy;

  /// About screen row label for the vault security features
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get aboutDetailSecurity;

  /// About screen row label for the languages the app ships in
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get aboutDetailLanguages;

  /// About-screen signature badge. {heart} is a red heart glyph.
  ///
  /// In en, this message translates to:
  /// **'Made with {heart} from India'**
  String madeWithLove(String heart);

  /// Screen-reader text for the About badge
  ///
  /// In en, this message translates to:
  /// **'Made with love from India'**
  String get madeWithLoveA11y;

  /// Name of the Sanskrit language, written in Sanskrit
  ///
  /// In en, this message translates to:
  /// **'संस्कृतम्'**
  String get titleLanguageSanskrit;

  /// A size in bytes. The number is already formatted for the language; keep the unit symbol B.
  ///
  /// In en, this message translates to:
  /// **'{value} B'**
  String bodyUnitBytes(String value);

  /// A size in kilobytes. Keep the unit symbol KB.
  ///
  /// In en, this message translates to:
  /// **'{value} KB'**
  String bodyUnitKilobytes(String value);

  /// A size in megabytes. Keep the unit symbol MB.
  ///
  /// In en, this message translates to:
  /// **'{value} MB'**
  String bodyUnitMegabytes(String value);

  /// A size in gigabytes. Keep the unit symbol GB.
  ///
  /// In en, this message translates to:
  /// **'{value} GB'**
  String bodyUnitGigabytes(String value);

  /// A size in terabytes. Keep the unit symbol TB.
  ///
  /// In en, this message translates to:
  /// **'{value} TB'**
  String bodyUnitTerabytes(String value);

  /// A length in millimetres, such as a lens focal length. Keep the unit symbol mm.
  ///
  /// In en, this message translates to:
  /// **'{value} mm'**
  String bodyUnitMillimetres(String value);

  /// A distance in metres. Keep the unit symbol m.
  ///
  /// In en, this message translates to:
  /// **'{value} m'**
  String bodyUnitMetres(String value);

  /// A camera ISO sensitivity value. ISO is a standard name; keep it.
  ///
  /// In en, this message translates to:
  /// **'ISO {value}'**
  String bodyUnitIsoValue(String value);

  /// A camera crop factor, such as 1.5x. Keep the x.
  ///
  /// In en, this message translates to:
  /// **'{value}x'**
  String bodyUnitCropFactor(String value);

  /// How many times the camera shutter has fired, from the photo metadata.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 release} other{{count} releases}}'**
  String bodyForensicShutterCount(int count);

  /// Transfer progress in bytes, such as "2.4 MB of 10 MB". Both values are already formatted sizes.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total}'**
  String bodyTransferBytesProgress(String done, String total);

  /// File format and size of an image found in a PDF, such as "JPG · 245 KB".
  ///
  /// In en, this message translates to:
  /// **'{format} · {size}'**
  String bodyPdfImageFormatAndSize(String format, String size);

  /// Name of the colour red, read out by the screen reader on a colour choice.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get labelColorRed;

  /// Name of the colour pink, read out by the screen reader on a colour choice.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get labelColorPink;

  /// Name of the colour purple, read out by the screen reader on a colour choice.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get labelColorPurple;

  /// Name of the colour deep purple, read out by the screen reader on a colour choice.
  ///
  /// In en, this message translates to:
  /// **'Deep purple'**
  String get labelColorDeepPurple;

  /// Name of the colour indigo, read out by the screen reader on a colour choice.
  ///
  /// In en, this message translates to:
  /// **'Indigo'**
  String get labelColorIndigo;

  /// Name of the colour blue, read out by the screen reader on a colour choice.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get labelColorBlue;

  /// Name of the colour teal, read out by the screen reader on a colour choice.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get labelColorTeal;

  /// Name of the colour green, read out by the screen reader on a colour choice.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get labelColorGreen;

  /// Name of the colour light green, read out by the screen reader on a colour choice.
  ///
  /// In en, this message translates to:
  /// **'Light green'**
  String get labelColorLightGreen;

  /// Name of the colour amber, read out by the screen reader on a colour choice.
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get labelColorAmber;

  /// Name of the colour deep orange, read out by the screen reader on a colour choice.
  ///
  /// In en, this message translates to:
  /// **'Deep orange'**
  String get labelColorDeepOrange;

  /// Name of the colour brown, read out by the screen reader on a colour choice.
  ///
  /// In en, this message translates to:
  /// **'Brown'**
  String get labelColorBrown;

  /// Name of the colour yellow, read out by the screen reader on a colour choice.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get labelColorYellow;

  /// Name of the colour white, read out by the screen reader on a colour choice.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get labelColorWhite;

  /// Name of the colour black, read out by the screen reader on a colour choice.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get labelColorBlack;

  /// Screen-reader name of the crop box drawn over the photo.
  ///
  /// In en, this message translates to:
  /// **'Crop area'**
  String get labelA11yCropArea;

  /// Screen-reader value of the crop box, as percentages of the photo.
  ///
  /// In en, this message translates to:
  /// **'Left {left}%, top {top}%, width {width}%, height {height}%'**
  String bodyA11yCropAreaValue(int left, int top, int width, int height);

  /// Screen-reader hint for the crop box.
  ///
  /// In en, this message translates to:
  /// **'Drag the corners, or use the actions to move or resize'**
  String get helpA11yCropAreaHint;

  /// Screen-reader action that moves the crop box or mask left.
  ///
  /// In en, this message translates to:
  /// **'Move left'**
  String get labelA11yMoveLeft;

  /// Screen-reader action that moves the crop box or mask right.
  ///
  /// In en, this message translates to:
  /// **'Move right'**
  String get labelA11yMoveRight;

  /// Screen-reader action that moves the crop box or mask up.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get labelA11yMoveUp;

  /// Screen-reader action that moves the crop box or mask down.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get labelA11yMoveDown;

  /// Screen-reader action that shrinks the crop box.
  ///
  /// In en, this message translates to:
  /// **'Make smaller'**
  String get labelA11yMakeSmaller;

  /// Screen-reader action that grows the crop box.
  ///
  /// In en, this message translates to:
  /// **'Make larger'**
  String get labelA11yMakeLarger;

  /// Screen-reader name of the tone-curve graph.
  ///
  /// In en, this message translates to:
  /// **'Tone curve'**
  String get labelA11yCurveArea;

  /// Screen-reader value of the tone curve: how many points it has.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 point} other{{count} points}}'**
  String bodyA11yCurveValue(int count);

  /// Screen-reader name of the markup drawing surface.
  ///
  /// In en, this message translates to:
  /// **'Drawing area'**
  String get labelA11yMarkupArea;

  /// Screen-reader value of the drawing surface: how many marks it holds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing drawn} =1{1 mark} other{{count} marks}}'**
  String bodyA11yMarkupValue(int count);

  /// Screen-reader hint on the markup and hide surfaces: freehand drawing cannot be done with a screen reader, so it points to the accessible controls panel.
  ///
  /// In en, this message translates to:
  /// **'Drawing needs touch. Use the panel below to change or remove marks.'**
  String get helpA11yDrawingNeedsTouchHint;

  /// Screen-reader name of the surface where areas are hidden (blurred or blacked out).
  ///
  /// In en, this message translates to:
  /// **'Hide area'**
  String get labelA11yRedactionArea;

  /// Screen-reader value of the hide surface: how many areas are hidden.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing hidden} =1{1 area hidden} other{{count} areas hidden}}'**
  String bodyA11yRedactionValue(int count);

  /// Screen-reader name of the selected mask drawn over the photo.
  ///
  /// In en, this message translates to:
  /// **'Mask position'**
  String get labelA11yMaskArea;

  /// Screen-reader value of the selected mask: its shape name and where its centre is, as percentages of the photo.
  ///
  /// In en, this message translates to:
  /// **'{shape}, centre at {x}% across, {y}% down'**
  String bodyA11yMaskValue(String shape, int x, int y);

  /// Screen-reader hint for the selected mask.
  ///
  /// In en, this message translates to:
  /// **'Drag the handles, or use the actions to move the mask'**
  String get helpA11yMaskHint;

  /// Screen-reader name of the handle that slides the curtain between two photos.
  ///
  /// In en, this message translates to:
  /// **'Comparison divider'**
  String get labelA11yCompareDivider;

  /// A percentage read out by the screen reader, such as the curtain position.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String bodyA11yPercentValue(int percent);

  /// Shown when another app asks this app to open a file it is not allowed to open, such as one inside this app's private storage.
  ///
  /// In en, this message translates to:
  /// **'This file can\'t be opened here. Open it from the gallery instead.'**
  String get errorOpenWithRefused;

  /// Shown when a file another app asked to open could not be read.
  ///
  /// In en, this message translates to:
  /// **'The file couldn\'t be opened. It may have been moved or deleted.'**
  String get errorOpenWithFailed;

  /// Shown under the "scan failed" title on the duplicate cleaner screen.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while comparing photos. Try again.'**
  String get bodyCleanerFailed;

  /// About screen row label for the public support email address.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get aboutDetailEmail;

  /// About screen row label for the link to the privacy policy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get aboutDetailPrivacyPolicy;

  /// Short switch label: block screenshots and the recent-apps preview on every screen.
  ///
  /// In en, this message translates to:
  /// **'Hide content'**
  String get titleSettingsProtectScreens;

  /// Explains the "Hide content" switch on the privacy settings screen.
  ///
  /// In en, this message translates to:
  /// **'Block screenshots and screen recording, and show a blank card in recent apps, on every screen. The vault is always protected.'**
  String get descSettingsProtectScreens;

  /// Title of the screen and settings card that list every Android permission the app uses
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get titleSettingsPermissions;

  /// Subtitle of the Permissions card on the settings screen
  ///
  /// In en, this message translates to:
  /// **'What the app can use, and why'**
  String get descSettingsPermissionsSubtitle;

  /// Section heading: runtime permissions that Android asks the user about
  ///
  /// In en, this message translates to:
  /// **'You allow these'**
  String get labelPermissionsExplicit;

  /// Section heading: normal permissions Android grants at install without asking
  ///
  /// In en, this message translates to:
  /// **'Granted at install'**
  String get labelPermissionsImplicit;

  /// Section heading: permissions libraries ask for that the app strips out
  ///
  /// In en, this message translates to:
  /// **'Removed on purpose'**
  String get labelPermissionsRemoved;

  /// Explains the 'You allow these' section of the Permissions screen
  ///
  /// In en, this message translates to:
  /// **'Android asks you before the app can use these. You can change them at any time in Android settings.'**
  String get descPermissionsExplicit;

  /// Explains the 'Granted at install' section of the Permissions screen
  ///
  /// In en, this message translates to:
  /// **'Android gives these when the app is installed, without asking. None of them gives access to your photos or files.'**
  String get descPermissionsImplicit;

  /// Explains the 'Removed on purpose' section of the Permissions screen
  ///
  /// In en, this message translates to:
  /// **'Some libraries the app is built with ask for these. The app removes them, so it never holds them.'**
  String get descPermissionsRemoved;

  /// Line above the button that opens Android's settings page for this app
  ///
  /// In en, this message translates to:
  /// **'To change what you allow, open this app\'s page in Android settings.'**
  String get descPermissionsManage;

  /// Permissions screen row: media read permissions
  ///
  /// In en, this message translates to:
  /// **'Photos and videos'**
  String get labelPermPhotosVideos;

  /// Permissions screen row: CAMERA
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get labelPermCamera;

  /// Permissions screen row: USE_BIOMETRIC and USE_FINGERPRINT
  ///
  /// In en, this message translates to:
  /// **'Fingerprint unlock'**
  String get labelPermBiometric;

  /// Permissions screen row: INTERNET, used for local Wi-Fi transfer only
  ///
  /// In en, this message translates to:
  /// **'Local network'**
  String get labelPermNetwork;

  /// Permissions screen row: ACCESS_WIFI_STATE
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi details'**
  String get labelPermWifiState;

  /// Permissions screen row: ACCESS_NETWORK_STATE
  ///
  /// In en, this message translates to:
  /// **'Network state'**
  String get labelPermNetworkState;

  /// Permissions screen row: CHANGE_WIFI_STATE
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi suggestions'**
  String get labelPermChangeWifi;

  /// Permissions screen row: DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION added by AndroidX
  ///
  /// In en, this message translates to:
  /// **'App-private messages'**
  String get labelPermReceiverPrivate;

  /// Permissions screen row: WAKE_LOCK, removed on purpose
  ///
  /// In en, this message translates to:
  /// **'Keep phone awake'**
  String get labelPermWakeLock;

  /// Permissions screen row: RECORD_AUDIO, removed on purpose
  ///
  /// In en, this message translates to:
  /// **'Record sound'**
  String get labelPermRecordAudio;

  /// Permissions screen row: WRITE_EXTERNAL_STORAGE, removed on purpose
  ///
  /// In en, this message translates to:
  /// **'Write to storage'**
  String get labelPermWriteStorage;

  /// Why the app needs the photos and videos permissions
  ///
  /// In en, this message translates to:
  /// **'Shows the photos and videos on this phone. On Android 14 and up you can allow only the ones you pick.'**
  String get descPermPhotosVideos;

  /// Why the app needs the camera permission
  ///
  /// In en, this message translates to:
  /// **'Scans the pairing QR code on the transfer screen only. The app never takes a photo.'**
  String get descPermCamera;

  /// Why the app needs the biometric permissions
  ///
  /// In en, this message translates to:
  /// **'Unlocks the vault with your fingerprint. Your PIN always works too.'**
  String get descPermBiometric;

  /// Why the app declares INTERNET: local transfer only
  ///
  /// In en, this message translates to:
  /// **'Used only by the transfer screen, to reach another phone on your own Wi-Fi. The app never goes on the internet.'**
  String get descPermNetwork;

  /// Why the app needs ACCESS_WIFI_STATE
  ///
  /// In en, this message translates to:
  /// **'Reads this phone\'s own Wi-Fi address to make the pairing code.'**
  String get descPermWifiState;

  /// Why the app declares ACCESS_NETWORK_STATE
  ///
  /// In en, this message translates to:
  /// **'Part of the local transfer set. The app does not use it to go online.'**
  String get descPermNetworkState;

  /// Why the app needs CHANGE_WIFI_STATE
  ///
  /// In en, this message translates to:
  /// **'Offers a Wi-Fi code you scanned to Android. You still choose the network yourself.'**
  String get descPermChangeWifi;

  /// Why the merged manifest holds the app-private receiver permission
  ///
  /// In en, this message translates to:
  /// **'Added by an Android library. It keeps the app\'s own internal messages private and gives no access to anything.'**
  String get descPermReceiverPrivate;

  /// Why WAKE_LOCK is removed
  ///
  /// In en, this message translates to:
  /// **'The video player asks for it for streaming. The app plays only files on this phone.'**
  String get descPermWakeLock;

  /// Why RECORD_AUDIO is removed
  ///
  /// In en, this message translates to:
  /// **'The camera library asks for it. The QR scanner never records sound.'**
  String get descPermRecordAudio;

  /// Why WRITE_EXTERNAL_STORAGE is removed
  ///
  /// In en, this message translates to:
  /// **'The camera library asks for it. The QR scanner never saves a file.'**
  String get descPermWriteStorage;

  /// Live state of the photos and videos permission: full access
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get labelPermAllowed;

  /// Live state of the photos and videos permission: Android 14 partial access
  ///
  /// In en, this message translates to:
  /// **'Selected only'**
  String get labelPermSelectedOnly;

  /// Live state of the photos and videos permission: denied
  ///
  /// In en, this message translates to:
  /// **'Not allowed'**
  String get labelPermNotAllowed;

  /// Note after a permission name: used on this Android version and newer
  ///
  /// In en, this message translates to:
  /// **'Android {version}+'**
  String labelPermAndroidFrom(String version);

  /// Note after a permission name: used up to this Android version only
  ///
  /// In en, this message translates to:
  /// **'Up to Android {version}'**
  String labelPermAndroidUpTo(String version);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ml', 'sa'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ml':
      return AppLocalizationsMl();
    case 'sa':
      return AppLocalizationsSa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
