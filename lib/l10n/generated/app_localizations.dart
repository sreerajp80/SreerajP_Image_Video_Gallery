import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ml.dart';

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
  ];

  /// The title of the gallery application
  ///
  /// In en, this message translates to:
  /// **'SreerajP Gallery'**
  String get appTitle;

  /// Banner text indicating the development flavor
  ///
  /// In en, this message translates to:
  /// **'DEV BUILD'**
  String get devBanner;

  /// Title of the settings screen or section
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Title of the about screen or section
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Theme selection header
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// System default theme option
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get themeSystem;

  /// Light theme option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// AMOLED true black theme option
  ///
  /// In en, this message translates to:
  /// **'AMOLED True Black'**
  String get themeAmoled;

  /// Label indicating active build flavor
  ///
  /// In en, this message translates to:
  /// **'Current Flavor'**
  String get currentFlavor;

  /// Label for application version
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Status text confirming zero network dependencies
  ///
  /// In en, this message translates to:
  /// **'100% Offline (No Internet)'**
  String get offlineStatus;

  /// Title shown when media permission has not been granted
  ///
  /// In en, this message translates to:
  /// **'Media access needed'**
  String get permissionRequired;

  /// Explanation of why the app needs media permission
  ///
  /// In en, this message translates to:
  /// **'Allow access to your photos and videos so the gallery can show them. Nothing ever leaves your device.'**
  String get permissionRequiredBody;

  /// Button that opens the system media permission dialog
  ///
  /// In en, this message translates to:
  /// **'Allow access'**
  String get grantPermission;

  /// Button that opens app settings when permission was permanently denied
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// Notice shown when the user granted partial photo access
  ///
  /// In en, this message translates to:
  /// **'Only selected media is visible. Allow all media to see everything.'**
  String get permissionPartial;

  /// Button that starts scanning the device for media
  ///
  /// In en, this message translates to:
  /// **'Scan device media'**
  String get scanMedia;

  /// Status text shown while the media scan runs
  ///
  /// In en, this message translates to:
  /// **'Scanning media...'**
  String get scanningMedia;

  /// Live count of scanned media items
  ///
  /// In en, this message translates to:
  /// **'{scanned} of {total} scanned'**
  String scanProgress(int scanned, int total);

  /// Message shown when a media scan finishes
  ///
  /// In en, this message translates to:
  /// **'Scan complete: {count} items indexed'**
  String scanComplete(int count);

  /// Message shown when a media scan could not finish
  ///
  /// In en, this message translates to:
  /// **'Media scan failed'**
  String get scanFailed;

  /// Number of media items currently stored in the local index
  ///
  /// In en, this message translates to:
  /// **'Indexed items: {count}'**
  String indexedItems(int count);

  /// Empty state shown when the device has no readable media
  ///
  /// In en, this message translates to:
  /// **'No photos or videos found'**
  String get noMediaFound;

  /// Placeholder label when a thumbnail cannot be generated
  ///
  /// In en, this message translates to:
  /// **'Preview unavailable'**
  String get mediaUnavailable;

  /// Date header shown above media captured today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get timelineToday;

  /// Date header shown above media captured yesterday
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get timelineYesterday;

  /// Title of the main chronological timeline screen
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timelineTitle;

  /// Empty state shown when no media has been indexed yet
  ///
  /// In en, this message translates to:
  /// **'Your gallery is empty'**
  String get noMediaInTimeline;

  /// Hint telling the user that pull-to-refresh starts a media scan
  ///
  /// In en, this message translates to:
  /// **'Pull down to scan for new photos and videos.'**
  String get pullToScan;

  /// Title of the flashback memories carousel
  ///
  /// In en, this message translates to:
  /// **'On This Day'**
  String get flashbackTitle;

  /// Caption for a flashback memory from exactly one year ago
  ///
  /// In en, this message translates to:
  /// **'1 year ago'**
  String get flashbackOneYearAgo;

  /// Caption for a flashback memory from several years ago
  ///
  /// In en, this message translates to:
  /// **'{years} years ago'**
  String flashbackYearsAgo(int years);

  /// Announces the current grid density after a pinch gesture
  ///
  /// In en, this message translates to:
  /// **'{count} per row'**
  String gridColumns(int count);

  /// Badge marking an animated GIF tile
  ///
  /// In en, this message translates to:
  /// **'GIF'**
  String get badgeGif;

  /// Badge marking a RAW camera image tile
  ///
  /// In en, this message translates to:
  /// **'RAW'**
  String get badgeRaw;

  /// Badge marking a high resolution media tile
  ///
  /// In en, this message translates to:
  /// **'HD'**
  String get badgeHd;

  /// Accessibility label for the duration pill on a video tile
  ///
  /// In en, this message translates to:
  /// **'Video, {duration}'**
  String badgeVideoDuration(String duration);

  /// Accessibility label for a media tile in the grid
  ///
  /// In en, this message translates to:
  /// **'{name}, {date}'**
  String mediaTileLabel(String name, String date);

  /// Accessibility label for the fast scroll scrubber handle
  ///
  /// In en, this message translates to:
  /// **'Scroll to date'**
  String get scrollToDate;

  /// Tooltip for the button that closes the fullscreen viewer
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get viewerClose;

  /// Tooltip for rotating the photo 90 degrees anticlockwise
  ///
  /// In en, this message translates to:
  /// **'Rotate left'**
  String get viewerRotateLeft;

  /// Tooltip for rotating the photo 90 degrees clockwise
  ///
  /// In en, this message translates to:
  /// **'Rotate right'**
  String get viewerRotateRight;

  /// Tooltip for marking the open item as a favorite
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get viewerAddFavorite;

  /// Tooltip for removing the favorite mark
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get viewerRemoveFavorite;

  /// Tooltip for the play button of the video player
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// Tooltip for the pause button of the video player
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// Tooltip for stepping the video one frame forward
  ///
  /// In en, this message translates to:
  /// **'Next frame'**
  String get frameForward;

  /// Tooltip for stepping the video one frame back
  ///
  /// In en, this message translates to:
  /// **'Previous frame'**
  String get frameBackward;

  /// Tooltip for skipping the video forward
  ///
  /// In en, this message translates to:
  /// **'Skip forward 10 seconds'**
  String get skipForward;

  /// Tooltip for skipping the video back
  ///
  /// In en, this message translates to:
  /// **'Skip back 10 seconds'**
  String get skipBackward;

  /// Tooltip for turning repeat playback on or off
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get loopPlayback;

  /// Tooltip for the playback speed menu
  ///
  /// In en, this message translates to:
  /// **'Playback speed'**
  String get playbackSpeed;

  /// Message shown when a video file cannot be opened
  ///
  /// In en, this message translates to:
  /// **'This video cannot be played.'**
  String get videoCannotPlay;

  /// Message shown when the device has no decoder for the video
  ///
  /// In en, this message translates to:
  /// **'This device cannot play this video format.'**
  String get videoFormatUnsupported;

  /// Title of the media details drawer
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsTitle;

  /// Label for the file name row in the details drawer
  ///
  /// In en, this message translates to:
  /// **'File name'**
  String get detailsFileName;

  /// Label for the file format row in the details drawer
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get detailsFormat;

  /// Label for the file size row in the details drawer
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get detailsSize;

  /// Label for the pixel width and height row
  ///
  /// In en, this message translates to:
  /// **'Dimensions'**
  String get detailsDimensions;

  /// Label for the video length row
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get detailsDuration;

  /// Label for the capture date row
  ///
  /// In en, this message translates to:
  /// **'Date taken'**
  String get detailsDateTaken;

  /// Label for the last modified date row
  ///
  /// In en, this message translates to:
  /// **'Last modified'**
  String get detailsDateModified;

  /// Label for the folder path row
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get detailsFolder;

  /// Heading of the EXIF section in the details drawer
  ///
  /// In en, this message translates to:
  /// **'Camera and metadata'**
  String get detailsCameraSection;

  /// Shown when a file carries no readable EXIF data
  ///
  /// In en, this message translates to:
  /// **'No camera metadata was found in this file.'**
  String get detailsNoMetadata;

  /// Label for the camera make and model row
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get detailsCamera;

  /// Label for the lens model row
  ///
  /// In en, this message translates to:
  /// **'Lens'**
  String get detailsLens;

  /// Label for the aperture f-number row
  ///
  /// In en, this message translates to:
  /// **'Aperture'**
  String get detailsAperture;

  /// Label for the shutter speed row
  ///
  /// In en, this message translates to:
  /// **'Shutter'**
  String get detailsShutter;

  /// Label for the ISO sensitivity row
  ///
  /// In en, this message translates to:
  /// **'ISO'**
  String get detailsIso;

  /// Label for the focal length row
  ///
  /// In en, this message translates to:
  /// **'Focal length'**
  String get detailsFocalLength;

  /// Label for the flash state row
  ///
  /// In en, this message translates to:
  /// **'Flash'**
  String get detailsFlash;

  /// Label for the white balance row
  ///
  /// In en, this message translates to:
  /// **'White balance'**
  String get detailsWhiteBalance;

  /// Label for the metering mode row
  ///
  /// In en, this message translates to:
  /// **'Metering mode'**
  String get detailsMeteringMode;

  /// Label for the color space row
  ///
  /// In en, this message translates to:
  /// **'Color space'**
  String get detailsColorSpace;

  /// Label for the processing software row
  ///
  /// In en, this message translates to:
  /// **'Software'**
  String get detailsSoftware;

  /// Label for the GPS coordinates row
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get detailsLocation;

  /// Label for the GPS altitude row
  ///
  /// In en, this message translates to:
  /// **'Altitude'**
  String get detailsAltitude;

  /// Title of the image editor screen
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editorTitle;

  /// Viewer button that opens the image editor
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editorOpen;

  /// Button that writes the edit as a new file
  ///
  /// In en, this message translates to:
  /// **'Save copy'**
  String get editorSave;

  /// Shown while the edited copy is being written
  ///
  /// In en, this message translates to:
  /// **'Saving a copy...'**
  String get editorSaving;

  /// Message shown after an edited copy is written
  ///
  /// In en, this message translates to:
  /// **'Saved a copy: {fileName}'**
  String editorSaved(String fileName);

  /// Message shown when writing the edited copy failed
  ///
  /// In en, this message translates to:
  /// **'The copy could not be saved'**
  String get editorSaveFailed;

  /// Reassurance shown next to the saved message
  ///
  /// In en, this message translates to:
  /// **'Your original photo was not changed'**
  String get editorOriginalKept;

  /// Shown when the file cannot be decoded or is too large
  ///
  /// In en, this message translates to:
  /// **'This photo cannot be edited'**
  String get editorCannotOpen;

  /// Shown when the file is above the editable size limit
  ///
  /// In en, this message translates to:
  /// **'This photo is too large to edit on this device'**
  String get editorTooLarge;

  /// Shown while the photo is being loaded into the editor
  ///
  /// In en, this message translates to:
  /// **'Preparing the photo...'**
  String get editorLoading;

  /// Shown when a preview render fails
  ///
  /// In en, this message translates to:
  /// **'The preview could not be drawn'**
  String get editorPreviewFailed;

  /// Button that steps one edit back
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get editorUndo;

  /// Button that puts back an undone edit
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get editorRedo;

  /// Button that clears every edit
  ///
  /// In en, this message translates to:
  /// **'Reset all'**
  String get editorResetAll;

  /// Title of the dialog shown when leaving with unsaved edits
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get editorDiscardTitle;

  /// Body of the discard dialog
  ///
  /// In en, this message translates to:
  /// **'Your edits have not been saved. Leaving now will lose them.'**
  String get editorDiscardMessage;

  /// Button that leaves the editor and loses the edits
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get editorDiscard;

  /// Button that stays in the editor
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get editorKeepEditing;

  /// Name of the crop and rotate tool
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get editorToolCrop;

  /// Name of the light and colour tool
  ///
  /// In en, this message translates to:
  /// **'Tune'**
  String get editorToolTune;

  /// Name of the selective gradient and radial masks tool
  ///
  /// In en, this message translates to:
  /// **'Masks'**
  String get editorToolMasks;

  /// Name of the filter preset tool
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get editorToolFilters;

  /// Name of the drawing and text tool
  ///
  /// In en, this message translates to:
  /// **'Markup'**
  String get editorToolMarkup;

  /// Name of the privacy redaction tool
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get editorToolRedact;

  /// Name of the watermark tool
  ///
  /// In en, this message translates to:
  /// **'Watermark'**
  String get editorToolWatermark;

  /// Crop shape that can be dragged to any size
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get cropAspectFree;

  /// Crop shape matching the photo's own shape
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get cropAspectOriginal;

  /// Square crop shape
  ///
  /// In en, this message translates to:
  /// **'Square'**
  String get cropAspectSquare;

  /// Four by three crop shape
  ///
  /// In en, this message translates to:
  /// **'4:3'**
  String get cropAspect4x3;

  /// Three by four crop shape
  ///
  /// In en, this message translates to:
  /// **'3:4'**
  String get cropAspect3x4;

  /// Sixteen by nine crop shape
  ///
  /// In en, this message translates to:
  /// **'16:9'**
  String get cropAspect16x9;

  /// Nine by sixteen crop shape
  ///
  /// In en, this message translates to:
  /// **'9:16'**
  String get cropAspect9x16;

  /// Three by two crop shape
  ///
  /// In en, this message translates to:
  /// **'3:2'**
  String get cropAspect3x2;

  /// Two by three crop shape
  ///
  /// In en, this message translates to:
  /// **'2:3'**
  String get cropAspect2x3;

  /// Button that turns the photo a quarter turn anticlockwise
  ///
  /// In en, this message translates to:
  /// **'Rotate left'**
  String get cropRotateLeft;

  /// Button that turns the photo a quarter turn clockwise
  ///
  /// In en, this message translates to:
  /// **'Rotate right'**
  String get cropRotateRight;

  /// Button that mirrors the photo left to right
  ///
  /// In en, this message translates to:
  /// **'Mirror sideways'**
  String get cropFlipHorizontal;

  /// Button that mirrors the photo top to bottom
  ///
  /// In en, this message translates to:
  /// **'Mirror upside down'**
  String get cropFlipVertical;

  /// Label of the fine levelling slider
  ///
  /// In en, this message translates to:
  /// **'Straighten'**
  String get cropStraighten;

  /// Label of the vertical perspective slider
  ///
  /// In en, this message translates to:
  /// **'Vertical tilt'**
  String get cropPerspectiveVertical;

  /// Label of the horizontal perspective slider
  ///
  /// In en, this message translates to:
  /// **'Horizontal tilt'**
  String get cropPerspectiveHorizontal;

  /// Button that clears every geometry change
  ///
  /// In en, this message translates to:
  /// **'Reset crop'**
  String get cropReset;

  /// Label of the brightness slider
  ///
  /// In en, this message translates to:
  /// **'Exposure'**
  String get toneExposure;

  /// Label of the contrast slider
  ///
  /// In en, this message translates to:
  /// **'Contrast'**
  String get toneContrast;

  /// Label of the highlights slider
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get toneHighlights;

  /// Label of the shadows slider
  ///
  /// In en, this message translates to:
  /// **'Shadows'**
  String get toneShadows;

  /// Label of the colour temperature slider
  ///
  /// In en, this message translates to:
  /// **'Warmth'**
  String get toneTemperature;

  /// Label of the green and magenta slider
  ///
  /// In en, this message translates to:
  /// **'Tint'**
  String get toneTint;

  /// Label of the vibrance slider
  ///
  /// In en, this message translates to:
  /// **'Vibrance'**
  String get toneVibrance;

  /// Label of the saturation slider
  ///
  /// In en, this message translates to:
  /// **'Saturation'**
  String get toneSaturation;

  /// Button that puts every tone slider back to neutral
  ///
  /// In en, this message translates to:
  /// **'Reset tune'**
  String get toneReset;

  /// Header of the RGB curve control
  ///
  /// In en, this message translates to:
  /// **'Curves'**
  String get toneCurves;

  /// Curve applied to all three channels
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get curveChannelRgb;

  /// Red channel curve
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get curveChannelRed;

  /// Green channel curve
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get curveChannelGreen;

  /// Blue channel curve
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get curveChannelBlue;

  /// Button that straightens the shown curve
  ///
  /// In en, this message translates to:
  /// **'Reset curve'**
  String get curveReset;

  /// Hint under the curve control
  ///
  /// In en, this message translates to:
  /// **'Drag a point to shape the curve'**
  String get curveHint;

  /// Hint under the spline curve editor
  ///
  /// In en, this message translates to:
  /// **'Tap to add a point, long-press to remove'**
  String get curveAddHint;

  /// Linear gradient mask shape option
  ///
  /// In en, this message translates to:
  /// **'Linear'**
  String get maskShapeLinear;

  /// Radial circular mask shape option
  ///
  /// In en, this message translates to:
  /// **'Radial'**
  String get maskShapeRadial;

  /// Label of the mask edge feathering slider
  ///
  /// In en, this message translates to:
  /// **'Feather'**
  String get maskFeather;

  /// Toggle to invert the selective mask area
  ///
  /// In en, this message translates to:
  /// **'Invert'**
  String get maskInvert;

  /// Label of the selective mask blur slider
  ///
  /// In en, this message translates to:
  /// **'Blur'**
  String get maskBlur;

  /// Tooltip for adding a linear gradient mask
  ///
  /// In en, this message translates to:
  /// **'Add linear gradient'**
  String get maskAddLinear;

  /// Tooltip for adding a radial mask
  ///
  /// In en, this message translates to:
  /// **'Add radial mask'**
  String get maskAddRadial;

  /// Tooltip for removing a selective mask
  ///
  /// In en, this message translates to:
  /// **'Remove mask'**
  String get maskRemove;

  /// Message displayed when no selective masks exist
  ///
  /// In en, this message translates to:
  /// **'Tap + to add a mask'**
  String get maskEmpty;

  /// Section header for the 8-channel HSL color tuner
  ///
  /// In en, this message translates to:
  /// **'HSL Color Tuner'**
  String get hslTitle;

  /// Label for the HSL hue adjustment slider
  ///
  /// In en, this message translates to:
  /// **'Hue'**
  String get hslHue;

  /// Label for the HSL saturation adjustment slider
  ///
  /// In en, this message translates to:
  /// **'Saturation'**
  String get hslSaturation;

  /// Label for the HSL luminance adjustment slider
  ///
  /// In en, this message translates to:
  /// **'Luminance'**
  String get hslLuminance;

  /// Button to reset HSL color adjustments to neutral
  ///
  /// In en, this message translates to:
  /// **'Reset HSL'**
  String get hslReset;

  /// HSL color range for red tones
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get hslRangeRed;

  /// HSL color range for orange tones
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get hslRangeOrange;

  /// HSL color range for yellow tones
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get hslRangeYellow;

  /// HSL color range for green tones
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get hslRangeGreen;

  /// HSL color range for cyan tones
  ///
  /// In en, this message translates to:
  /// **'Cyan'**
  String get hslRangeCyan;

  /// HSL color range for blue tones
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get hslRangeBlue;

  /// HSL color range for purple tones
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get hslRangePurple;

  /// HSL color range for magenta tones
  ///
  /// In en, this message translates to:
  /// **'Magenta'**
  String get hslRangeMagenta;

  /// Filter preset that changes nothing
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get filterNone;

  /// Black and white filter preset
  ///
  /// In en, this message translates to:
  /// **'Mono'**
  String get filterMono;

  /// Sepia filter preset
  ///
  /// In en, this message translates to:
  /// **'Sepia'**
  String get filterSepia;

  /// Faded warm filter preset
  ///
  /// In en, this message translates to:
  /// **'Vintage'**
  String get filterVintage;

  /// Strong colour filter preset
  ///
  /// In en, this message translates to:
  /// **'Vivid'**
  String get filterVivid;

  /// Cool blue filter preset
  ///
  /// In en, this message translates to:
  /// **'Cool'**
  String get filterCool;

  /// Warm orange filter preset
  ///
  /// In en, this message translates to:
  /// **'Warm'**
  String get filterWarm;

  /// Soft low contrast filter preset
  ///
  /// In en, this message translates to:
  /// **'Fade'**
  String get filterFade;

  /// Label of the filter strength slider
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get filterIntensity;

  /// Freehand doodle tool
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get markupFreehand;

  /// Rectangle shape tool
  ///
  /// In en, this message translates to:
  /// **'Rectangle'**
  String get markupRectangle;

  /// Circle shape tool
  ///
  /// In en, this message translates to:
  /// **'Circle'**
  String get markupEllipse;

  /// Line shape tool
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get markupLine;

  /// Arrow shape tool
  ///
  /// In en, this message translates to:
  /// **'Arrow'**
  String get markupArrow;

  /// Text overlay tool
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get markupText;

  /// Label of the markup colour picker
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get markupColor;

  /// Label of the markup line thickness slider
  ///
  /// In en, this message translates to:
  /// **'Thickness'**
  String get markupThickness;

  /// Switch that fills the inside of a shape
  ///
  /// In en, this message translates to:
  /// **'Fill shape'**
  String get markupFilled;

  /// Button that removes the most recent drawing
  ///
  /// In en, this message translates to:
  /// **'Remove last'**
  String get markupUndoLayer;

  /// Title of the add text dialog
  ///
  /// In en, this message translates to:
  /// **'Add text'**
  String get markupTextTitle;

  /// Hint inside the add text field
  ///
  /// In en, this message translates to:
  /// **'Type your text'**
  String get markupTextHint;

  /// Button that adds the typed text to the photo
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get markupTextAdd;

  /// Hint shown under the markup tools
  ///
  /// In en, this message translates to:
  /// **'Drag on the photo to draw'**
  String get markupHint;

  /// Redaction that softens the area
  ///
  /// In en, this message translates to:
  /// **'Blur'**
  String get redactBlur;

  /// Redaction that turns the area into blocks
  ///
  /// In en, this message translates to:
  /// **'Pixelate'**
  String get redactPixelate;

  /// Redaction that paints the area solid
  ///
  /// In en, this message translates to:
  /// **'Blackout'**
  String get redactBlackout;

  /// Label of the redaction strength slider
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get redactStrength;

  /// Hint shown under the redaction tools
  ///
  /// In en, this message translates to:
  /// **'Drag over anything you want hidden'**
  String get redactHint;

  /// Button that removes the most recent hidden area
  ///
  /// In en, this message translates to:
  /// **'Remove last'**
  String get redactRemoveLast;

  /// Number of redacted areas on the photo
  ///
  /// In en, this message translates to:
  /// **'{count} areas hidden'**
  String redactCount(int count);

  /// No watermark
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get watermarkNone;

  /// Watermark showing typed text
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get watermarkText;

  /// Watermark showing the photo's date
  ///
  /// In en, this message translates to:
  /// **'Date and time'**
  String get watermarkTimestamp;

  /// Watermark showing a picture file
  ///
  /// In en, this message translates to:
  /// **'Logo'**
  String get watermarkLogo;

  /// Hint inside the watermark text field
  ///
  /// In en, this message translates to:
  /// **'Watermark text'**
  String get watermarkTextHint;

  /// Label of the watermark position picker
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get watermarkPosition;

  /// Label of the watermark opacity slider
  ///
  /// In en, this message translates to:
  /// **'Opacity'**
  String get watermarkOpacity;

  /// Label of the watermark size slider
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get watermarkSize;

  /// Label of the watermark margin slider
  ///
  /// In en, this message translates to:
  /// **'Edge gap'**
  String get watermarkMargin;

  /// Button that picks the watermark picture
  ///
  /// In en, this message translates to:
  /// **'Choose a logo file'**
  String get watermarkPickLogo;

  /// Shown when the logo watermark has no file
  ///
  /// In en, this message translates to:
  /// **'No logo chosen yet'**
  String get watermarkNoLogo;

  /// Button that clears the chosen logo
  ///
  /// In en, this message translates to:
  /// **'Remove logo'**
  String get watermarkClearLogo;

  /// Watermark corner
  ///
  /// In en, this message translates to:
  /// **'Top left'**
  String get positionTopLeft;

  /// Watermark position
  ///
  /// In en, this message translates to:
  /// **'Top centre'**
  String get positionTopCenter;

  /// Watermark corner
  ///
  /// In en, this message translates to:
  /// **'Top right'**
  String get positionTopRight;

  /// Watermark position
  ///
  /// In en, this message translates to:
  /// **'Middle left'**
  String get positionCenterLeft;

  /// Watermark position
  ///
  /// In en, this message translates to:
  /// **'Centre'**
  String get positionCenter;

  /// Watermark position
  ///
  /// In en, this message translates to:
  /// **'Middle right'**
  String get positionCenterRight;

  /// Watermark corner
  ///
  /// In en, this message translates to:
  /// **'Bottom left'**
  String get positionBottomLeft;

  /// Watermark position
  ///
  /// In en, this message translates to:
  /// **'Bottom centre'**
  String get positionBottomCenter;

  /// Watermark corner
  ///
  /// In en, this message translates to:
  /// **'Bottom right'**
  String get positionBottomRight;

  /// Tooltip on the viewer button that opens the converter
  ///
  /// In en, this message translates to:
  /// **'Convert'**
  String get convertOpen;

  /// Title of the converter screen
  ///
  /// In en, this message translates to:
  /// **'Convert and resize'**
  String get convertTitle;

  /// Shown when the chosen item is not a still picture
  ///
  /// In en, this message translates to:
  /// **'This file cannot be converted'**
  String get convertCannotOpen;

  /// Shown when the picture is over the size limit
  ///
  /// In en, this message translates to:
  /// **'This file is too large to convert'**
  String get convertTooLarge;

  /// Shown when the picture bytes cannot be loaded
  ///
  /// In en, this message translates to:
  /// **'This picture could not be read'**
  String get convertUnreadable;

  /// Heading above the output format chips
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get convertFormatLabel;

  /// Heading above the quality slider
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get convertQualityLabel;

  /// Heading above the resize controls
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get convertResizeLabel;

  /// Resize choice that keeps the picture size
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get convertResizeNone;

  /// Resize choice that fits inside a longest side
  ///
  /// In en, this message translates to:
  /// **'Longest side'**
  String get convertResizeLongestSide;

  /// Resize choice that scales by a percentage
  ///
  /// In en, this message translates to:
  /// **'Percent'**
  String get convertResizePercent;

  /// Resize choice that uses exact numbers
  ///
  /// In en, this message translates to:
  /// **'Width and height'**
  String get convertResizeExact;

  /// Switch that stops the picture being stretched
  ///
  /// In en, this message translates to:
  /// **'Keep the shape'**
  String get convertKeepAspect;

  /// Label of the width box
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get convertWidth;

  /// Label of the height box
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get convertHeight;

  /// Label of the longest side box
  ///
  /// In en, this message translates to:
  /// **'Longest side in pixels'**
  String get convertLongestSideLabel;

  /// Label of the percent box
  ///
  /// In en, this message translates to:
  /// **'Percent of the original'**
  String get convertPercentLabel;

  /// Switch that drops EXIF data from the copy
  ///
  /// In en, this message translates to:
  /// **'Remove camera details'**
  String get convertStripMetadata;

  /// Explains what removing camera details does
  ///
  /// In en, this message translates to:
  /// **'Location and camera settings are left out of the copy'**
  String get convertStripMetadataHint;

  /// Label of the original file size in the size preview
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get convertOriginalSize;

  /// Label of the new file size in the size preview
  ///
  /// In en, this message translates to:
  /// **'New copy'**
  String get convertNewSize;

  /// Shown while the size preview is being encoded
  ///
  /// In en, this message translates to:
  /// **'Working out the size'**
  String get convertEstimating;

  /// Shown when the size preview fails
  ///
  /// In en, this message translates to:
  /// **'The size cannot be worked out for this file'**
  String get convertNoEstimate;

  /// Warning when the chosen format grows the file
  ///
  /// In en, this message translates to:
  /// **'The copy is larger than the original'**
  String get convertLargerWarning;

  /// Button that writes the converted file
  ///
  /// In en, this message translates to:
  /// **'Save a copy'**
  String get convertSave;

  /// Shown while the converted copy is being written
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get convertSaving;

  /// Shown when the conversion fails
  ///
  /// In en, this message translates to:
  /// **'The copy could not be saved'**
  String get convertFailed;

  /// Reassures the user that nothing is overwritten
  ///
  /// In en, this message translates to:
  /// **'Your original file is not changed'**
  String get convertOriginalKept;

  /// Menu item that opens the PDF export screen
  ///
  /// In en, this message translates to:
  /// **'Export as PDF'**
  String get pdfOpen;

  /// Title of the PDF export screen
  ///
  /// In en, this message translates to:
  /// **'Export as PDF'**
  String get pdfExportTitle;

  /// Heading above the photo picker grid
  ///
  /// In en, this message translates to:
  /// **'Choose photos'**
  String get pdfChoosePhotos;

  /// Shown when nothing is picked yet
  ///
  /// In en, this message translates to:
  /// **'Choose at least one photo'**
  String get pdfNoSelection;

  /// Shown when the library holds no pictures
  ///
  /// In en, this message translates to:
  /// **'There are no photos to choose from'**
  String get pdfNoPhotos;

  /// Heading above the page size choices
  ///
  /// In en, this message translates to:
  /// **'Page size'**
  String get pdfPageSizeLabel;

  /// Page size choice
  ///
  /// In en, this message translates to:
  /// **'A4'**
  String get pdfPageA4;

  /// Page size choice
  ///
  /// In en, this message translates to:
  /// **'Letter'**
  String get pdfPageLetter;

  /// Page size choice that matches each photo
  ///
  /// In en, this message translates to:
  /// **'Fit the photo'**
  String get pdfPageFitImage;

  /// Heading above the page direction choices
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get pdfOrientationLabel;

  /// Page direction choice
  ///
  /// In en, this message translates to:
  /// **'Upright'**
  String get pdfOrientationPortrait;

  /// Page direction choice
  ///
  /// In en, this message translates to:
  /// **'Sideways'**
  String get pdfOrientationLandscape;

  /// Page direction choice that matches each photo
  ///
  /// In en, this message translates to:
  /// **'Follow the photo'**
  String get pdfOrientationAuto;

  /// Heading above the photo placement choices
  ///
  /// In en, this message translates to:
  /// **'Placement'**
  String get pdfFitLabel;

  /// Placement choice that shows all of the photo
  ///
  /// In en, this message translates to:
  /// **'Fit the whole photo'**
  String get pdfFitContain;

  /// Placement choice that crops the photo
  ///
  /// In en, this message translates to:
  /// **'Fill the page'**
  String get pdfFitFill;

  /// Heading above the page border choices
  ///
  /// In en, this message translates to:
  /// **'Border'**
  String get pdfMarginLabel;

  /// Page border choice
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get pdfMarginNone;

  /// Page border choice
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get pdfMarginSmall;

  /// Page border choice
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get pdfMarginMedium;

  /// Page border choice
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get pdfMarginLarge;

  /// Heading above the PDF photo quality slider
  ///
  /// In en, this message translates to:
  /// **'Photo quality'**
  String get pdfQualityLabel;

  /// Button that builds the document
  ///
  /// In en, this message translates to:
  /// **'Create the PDF'**
  String get pdfExportAction;

  /// Shown while the document is being built
  ///
  /// In en, this message translates to:
  /// **'Creating the PDF'**
  String get pdfExporting;

  /// Shown when the export fails
  ///
  /// In en, this message translates to:
  /// **'The PDF could not be created'**
  String get pdfFailed;

  /// Tooltip on the viewer button that opens the video tools
  ///
  /// In en, this message translates to:
  /// **'Video tools'**
  String get videoToolsOpen;

  /// Title of the video tools screen
  ///
  /// In en, this message translates to:
  /// **'Video tools'**
  String get videoToolsTitle;

  /// Shown when the platform cannot open the clip
  ///
  /// In en, this message translates to:
  /// **'This clip could not be read'**
  String get videoToolsUnavailable;

  /// Tab that grabs a still picture
  ///
  /// In en, this message translates to:
  /// **'Frame'**
  String get videoTabFrame;

  /// Tab that makes an animated GIF
  ///
  /// In en, this message translates to:
  /// **'GIF'**
  String get videoTabGif;

  /// Tab that cuts the clip
  ///
  /// In en, this message translates to:
  /// **'Trim'**
  String get videoTabTrim;

  /// Label of the frame position slider
  ///
  /// In en, this message translates to:
  /// **'Position in the clip'**
  String get framePositionLabel;

  /// Heading above the frame format choices
  ///
  /// In en, this message translates to:
  /// **'Save as'**
  String get frameFormatLabel;

  /// Button that writes the still picture
  ///
  /// In en, this message translates to:
  /// **'Save this frame'**
  String get frameSaveAction;

  /// Shown when the platform gives no frame
  ///
  /// In en, this message translates to:
  /// **'No frame could be read here'**
  String get frameUnavailable;

  /// Heading above the GIF frame rate choices
  ///
  /// In en, this message translates to:
  /// **'Frames per second'**
  String get gifFrameRateLabel;

  /// Heading above the GIF size choices
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get gifSizeLabel;

  /// Switch that makes the GIF repeat
  ///
  /// In en, this message translates to:
  /// **'Play on a loop'**
  String get gifLoopLabel;

  /// Shown when the frame or length cap applies
  ///
  /// In en, this message translates to:
  /// **'The GIF is shortened to keep the file small'**
  String get gifCapped;

  /// Button that writes the GIF
  ///
  /// In en, this message translates to:
  /// **'Create the GIF'**
  String get gifExportAction;

  /// Shown while the GIF is being made
  ///
  /// In en, this message translates to:
  /// **'Creating the GIF'**
  String get gifExporting;

  /// Label of the trim start handle
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get trimStartLabel;

  /// Label of the trim end handle
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get trimEndLabel;

  /// Label of the kept length
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get trimLengthLabel;

  /// Button that writes the trimmed video
  ///
  /// In en, this message translates to:
  /// **'Save the trimmed clip'**
  String get trimAction;

  /// Explains how the lossless trim works
  ///
  /// In en, this message translates to:
  /// **'Nothing is re-encoded, so no quality is lost. The cut may begin a moment earlier, at the nearest key frame.'**
  String get trimLosslessNote;

  /// Shown when the trim range is below the minimum
  ///
  /// In en, this message translates to:
  /// **'The chosen part is too short'**
  String get trimTooShort;

  /// Shown while a video job is running
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get videoWorking;

  /// Shown when a video job fails
  ///
  /// In en, this message translates to:
  /// **'That could not be finished'**
  String get videoJobFailed;

  /// Pixel size shown in the size preview
  ///
  /// In en, this message translates to:
  /// **'{width} by {height} pixels'**
  String convertPixelSize(int width, int height);

  /// How much smaller the new copy is
  ///
  /// In en, this message translates to:
  /// **'{percent} percent smaller'**
  String convertSmallerBy(int percent);

  /// Shown after a converted copy is written
  ///
  /// In en, this message translates to:
  /// **'Saved as {name}'**
  String convertSavedAs(String name);

  /// How many photos are picked for the PDF
  ///
  /// In en, this message translates to:
  /// **'{count} chosen'**
  String pdfSelectedCount(int count);

  /// Shown when the page cap stops more photos being picked
  ///
  /// In en, this message translates to:
  /// **'Only {count} photos fit in one PDF'**
  String pdfMaxPagesReached(int count);

  /// Shown after a PDF is written
  ///
  /// In en, this message translates to:
  /// **'Saved {name} with {pages} pages'**
  String pdfExportedAs(String name, int pages);

  /// Shown when some chosen photos were skipped
  ///
  /// In en, this message translates to:
  /// **'{count} photos could not be read and were left out'**
  String pdfSkippedCount(int count);

  /// How many frames the GIF will hold
  ///
  /// In en, this message translates to:
  /// **'{count} frames'**
  String gifFrameCount(int count);

  /// Shown after a video job writes a file
  ///
  /// In en, this message translates to:
  /// **'Saved as {name}'**
  String videoJobSavedAs(String name);

  /// Title of the search screen
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// Opens the search screen
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchOpen;

  /// Placeholder text inside the search box
  ///
  /// In en, this message translates to:
  /// **'Search names, tags, notes, places'**
  String get searchHint;

  /// Clears the search box
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get searchClear;

  /// Opens the search filter sheet
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get searchFilters;

  /// Shown before anything is typed
  ///
  /// In en, this message translates to:
  /// **'Search your library'**
  String get searchStartTitle;

  /// Explains what search can do
  ///
  /// In en, this message translates to:
  /// **'Look through names, tags, notes, camera and place. Start a word with tag:, type:, place:, camera:, before: or after: to narrow the search.'**
  String get searchStartBody;

  /// Shown when a search finds nothing
  ///
  /// In en, this message translates to:
  /// **'Nothing matched'**
  String get searchNoResultsTitle;

  /// Advice when a search finds nothing
  ///
  /// In en, this message translates to:
  /// **'Try fewer words, or check the filters.'**
  String get searchNoResultsBody;

  /// Shown when a search throws an error
  ///
  /// In en, this message translates to:
  /// **'The search could not run'**
  String get searchFailed;

  /// Heading above the recent search list
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get searchRecentTitle;

  /// Forgets every recent search
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get searchRecentClear;

  /// Forgets one recent search
  ///
  /// In en, this message translates to:
  /// **'Forget this search'**
  String get searchRecentRemove;

  /// How many items a search found
  ///
  /// In en, this message translates to:
  /// **'{count} results'**
  String searchResultCount(int count);

  /// Why a result came back
  ///
  /// In en, this message translates to:
  /// **'Matched the file name'**
  String get searchMatchedInName;

  /// Why a result came back
  ///
  /// In en, this message translates to:
  /// **'Matched a tag'**
  String get searchMatchedInTags;

  /// Why a result came back
  ///
  /// In en, this message translates to:
  /// **'Matched a note'**
  String get searchMatchedInNotes;

  /// Why a result came back
  ///
  /// In en, this message translates to:
  /// **'Matched a place'**
  String get searchMatchedInPlace;

  /// Why a result came back
  ///
  /// In en, this message translates to:
  /// **'Matched the photo details'**
  String get searchMatchedInDetails;

  /// Title of the filter sheet
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filterTitle;

  /// Heading for the media kind filter
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get filterMediaType;

  /// Media kind filter chip
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get filterTypeImage;

  /// Media kind filter chip
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get filterTypeVideo;

  /// Media kind filter chip
  ///
  /// In en, this message translates to:
  /// **'GIFs'**
  String get filterTypeGif;

  /// Media kind filter chip
  ///
  /// In en, this message translates to:
  /// **'RAW'**
  String get filterTypeRaw;

  /// Media kind filter chip
  ///
  /// In en, this message translates to:
  /// **'SVG'**
  String get filterTypeSvg;

  /// Filter switch for favourite items
  ///
  /// In en, this message translates to:
  /// **'Favourites only'**
  String get filterFavoritesOnly;

  /// Filter switch for items with a GPS fix
  ///
  /// In en, this message translates to:
  /// **'Has a place'**
  String get filterHasLocation;

  /// Heading for the date filter
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get filterDateRange;

  /// Shown when no date range is set
  ///
  /// In en, this message translates to:
  /// **'Any date'**
  String get filterDateAny;

  /// Opens the date range picker
  ///
  /// In en, this message translates to:
  /// **'Choose dates'**
  String get filterDateChoose;

  /// Removes the date range
  ///
  /// In en, this message translates to:
  /// **'Clear dates'**
  String get filterDateClear;

  /// Heading for the tag filter
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get filterTags;

  /// Tag filter requiring every chosen tag
  ///
  /// In en, this message translates to:
  /// **'Has all'**
  String get filterTagModeAll;

  /// Tag filter requiring one chosen tag
  ///
  /// In en, this message translates to:
  /// **'Has any'**
  String get filterTagModeAny;

  /// Shown in the filter sheet when no tag exists
  ///
  /// In en, this message translates to:
  /// **'No tags yet'**
  String get filterNoTags;

  /// Clears every filter
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get filterReset;

  /// Closes the filter sheet keeping the choices
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get filterApply;

  /// Title of the tag management screen
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tagsTitle;

  /// Opens the tag screen
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tagsOpen;

  /// Shown when no tag has been made
  ///
  /// In en, this message translates to:
  /// **'No tags yet'**
  String get tagsEmptyTitle;

  /// Advice when no tag has been made
  ///
  /// In en, this message translates to:
  /// **'Make a tag to group photos your own way.'**
  String get tagsEmptyBody;

  /// Starts making a tag
  ///
  /// In en, this message translates to:
  /// **'New tag'**
  String get tagNew;

  /// Title of the tag edit dialog
  ///
  /// In en, this message translates to:
  /// **'Edit tag'**
  String get tagEditTitle;

  /// Label of the tag name field
  ///
  /// In en, this message translates to:
  /// **'Tag name'**
  String get tagNameLabel;

  /// Label of the tag colour picker
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get tagColorLabel;

  /// Saves a tag
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get tagSave;

  /// Closes a dialog without saving
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get tagCancel;

  /// Deletes a tag
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get tagDelete;

  /// Title of the delete tag confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete this tag?'**
  String get tagDeleteTitle;

  /// Explains what deleting a tag does
  ///
  /// In en, this message translates to:
  /// **'The tag comes off every photo that has it. No photo is deleted.'**
  String get tagDeleteBody;

  /// How many items carry a tag
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String tagItemCount(int count);

  /// Opens search filtered to one tag
  ///
  /// In en, this message translates to:
  /// **'Show photos'**
  String get tagShowMedia;

  /// Shown when a tag name is blank
  ///
  /// In en, this message translates to:
  /// **'A tag needs a name'**
  String get tagErrorEmpty;

  /// Shown when a tag name is over the limit
  ///
  /// In en, this message translates to:
  /// **'That name is too long'**
  String get tagErrorTooLong;

  /// Shown when a tag name is taken
  ///
  /// In en, this message translates to:
  /// **'That tag already exists'**
  String get tagErrorDuplicate;

  /// Shown when a tag write fails
  ///
  /// In en, this message translates to:
  /// **'The tag could not be saved'**
  String get tagErrorFailed;

  /// Title of the tag sheet in the viewer
  ///
  /// In en, this message translates to:
  /// **'Tags on this item'**
  String get tagSheetTitle;

  /// Placeholder of the new tag field
  ///
  /// In en, this message translates to:
  /// **'Add a new tag'**
  String get tagSheetNewHint;

  /// Adds the typed tag
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get tagSheetAdd;

  /// Closes the tag sheet
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get tagSheetDone;

  /// Opens the tag sheet from the viewer
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tagSheetOpen;

  /// Title of the duplicate cleaner screen
  ///
  /// In en, this message translates to:
  /// **'Duplicate cleaner'**
  String get cleanerTitle;

  /// Opens the duplicate cleaner
  ///
  /// In en, this message translates to:
  /// **'Duplicate cleaner'**
  String get cleanerOpen;

  /// Starts a duplicate scan
  ///
  /// In en, this message translates to:
  /// **'Find duplicates'**
  String get cleanerStart;

  /// Stops a running duplicate scan
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get cleanerStop;

  /// Runs the duplicate scan a second time
  ///
  /// In en, this message translates to:
  /// **'Scan again'**
  String get cleanerRescan;

  /// Shown before a duplicate scan is run
  ///
  /// In en, this message translates to:
  /// **'Find duplicate photos'**
  String get cleanerIdleTitle;

  /// Explains how the duplicate scan works
  ///
  /// In en, this message translates to:
  /// **'Each file is read once and what was found is remembered, so scanning again later is quick.'**
  String get cleanerIdleBody;

  /// Live duplicate scan progress
  ///
  /// In en, this message translates to:
  /// **'Checked {processed} of {total}'**
  String cleanerScanning(int processed, int total);

  /// Shown while duplicate groups are built
  ///
  /// In en, this message translates to:
  /// **'Grouping the copies'**
  String get cleanerGrouping;

  /// Shown when the user stops the scan
  ///
  /// In en, this message translates to:
  /// **'Scan stopped'**
  String get cleanerCancelled;

  /// Shown when the duplicate scan fails
  ///
  /// In en, this message translates to:
  /// **'The scan could not finish'**
  String get cleanerFailed;

  /// Shown when the scan finds no copies
  ///
  /// In en, this message translates to:
  /// **'No duplicates found'**
  String get cleanerNoneTitle;

  /// Explains an empty duplicate result
  ///
  /// In en, this message translates to:
  /// **'Nothing in your library looks like a copy of anything else.'**
  String get cleanerNoneBody;

  /// How many duplicate groups were found
  ///
  /// In en, this message translates to:
  /// **'{count} groups of copies'**
  String cleanerGroupsFound(int count);

  /// How much space the extra copies take
  ///
  /// In en, this message translates to:
  /// **'About {size} could be freed'**
  String cleanerReclaimable(String size);

  /// How many files the scan could not read
  ///
  /// In en, this message translates to:
  /// **'{count} files could not be read and were skipped'**
  String cleanerFailures(int count);

  /// Badge for a byte-identical duplicate group
  ///
  /// In en, this message translates to:
  /// **'Identical files'**
  String get cleanerKindExact;

  /// Badge for a visually similar group
  ///
  /// In en, this message translates to:
  /// **'Looks the same'**
  String get cleanerKindSimilar;

  /// How many copies are in a group
  ///
  /// In en, this message translates to:
  /// **'{count} copies'**
  String cleanerMemberCount(int count);

  /// Opens the side-by-side comparison
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get cleanerCompare;

  /// Title of the comparison screen
  ///
  /// In en, this message translates to:
  /// **'Compare copies'**
  String get compareTitle;

  /// Shown when a group no longer exists
  ///
  /// In en, this message translates to:
  /// **'This group has already been dealt with'**
  String get compareGroupGone;

  /// Chooses which copy to keep
  ///
  /// In en, this message translates to:
  /// **'Keep this one'**
  String get compareKeepThis;

  /// Marks the copy the app suggests keeping
  ///
  /// In en, this message translates to:
  /// **'Suggested'**
  String get compareBestBadge;

  /// The confirm action on the compare screen
  ///
  /// In en, this message translates to:
  /// **'Keep 1, move {count} to trash'**
  String compareKeepAndTrash(int count);

  /// Explains that files are not deleted
  ///
  /// In en, this message translates to:
  /// **'Nothing is erased. The other copies move to the trash and can be brought back.'**
  String get compareTrashNotice;

  /// Title of the trash confirmation
  ///
  /// In en, this message translates to:
  /// **'Move {count} copies to the trash?'**
  String compareConfirmTitle(int count);

  /// Body of the trash confirmation
  ///
  /// In en, this message translates to:
  /// **'Only the copy you kept stays in the gallery. The files stay on the device and can be brought back.'**
  String get compareConfirmBody;

  /// Confirms moving copies to the trash
  ///
  /// In en, this message translates to:
  /// **'Move to trash'**
  String get compareConfirm;

  /// Closes the confirmation without acting
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get compareCancel;

  /// Shown after copies are trashed
  ///
  /// In en, this message translates to:
  /// **'{count} copies moved to the trash'**
  String compareMoved(int count);

  /// Shown when trashing copies fails
  ///
  /// In en, this message translates to:
  /// **'The copies could not be moved'**
  String get compareFailed;

  /// Row label on the comparison screen
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get compareFieldSize;

  /// Row label on the comparison screen
  ///
  /// In en, this message translates to:
  /// **'Pixels'**
  String get compareFieldPixels;

  /// Row label on the comparison screen
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get compareFieldDate;

  /// Row label on the comparison screen
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get compareFieldCamera;

  /// Shown when a detail is missing
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get compareUnknown;

  /// Title of the albums screen
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get albumsTitle;

  /// Opens the albums screen
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get albumsOpen;

  /// Heading above the user's own albums
  ///
  /// In en, this message translates to:
  /// **'My albums'**
  String get albumsSectionMine;

  /// Heading above the automatic albums
  ///
  /// In en, this message translates to:
  /// **'Smart albums'**
  String get albumsSectionSmart;

  /// Heading above the storage folders
  ///
  /// In en, this message translates to:
  /// **'Device folders'**
  String get albumsSectionFolders;

  /// Shown when the user has made no albums
  ///
  /// In en, this message translates to:
  /// **'No albums yet'**
  String get albumsEmptyTitle;

  /// Explains what an album is
  ///
  /// In en, this message translates to:
  /// **'Make an album to group photos and videos your own way. The files stay where they are.'**
  String get albumsEmptyBody;

  /// Shown when the device has no indexed folders
  ///
  /// In en, this message translates to:
  /// **'No folders found'**
  String get albumsFoldersEmpty;

  /// Shown when reading albums fails
  ///
  /// In en, this message translates to:
  /// **'Albums could not be loaded'**
  String get albumsLoadFailed;

  /// How many items an album holds
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Empty} =1{1 item} other{{count} items}}'**
  String albumItemCount(int count);

  /// Name of the starred-items album
  ///
  /// In en, this message translates to:
  /// **'Favourites'**
  String get smartAlbumFavorites;

  /// Name of the videos-only album
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get smartAlbumVideos;

  /// Name of the animated images album
  ///
  /// In en, this message translates to:
  /// **'Animated & GIFs'**
  String get smartAlbumGifs;

  /// Name of the raw photos album
  ///
  /// In en, this message translates to:
  /// **'RAW captures'**
  String get smartAlbumRaw;

  /// Name of the wide photos album
  ///
  /// In en, this message translates to:
  /// **'Panoramas'**
  String get smartAlbumPanoramas;

  /// Name of the newest items album
  ///
  /// In en, this message translates to:
  /// **'Recently added'**
  String get smartAlbumRecent;

  /// Name of the trashed items smart album
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get smartAlbumTrash;

  /// Makes a new album
  ///
  /// In en, this message translates to:
  /// **'New album'**
  String get albumNew;

  /// Title of the create-album dialog
  ///
  /// In en, this message translates to:
  /// **'New album'**
  String get albumCreateTitle;

  /// Title of the rename-album dialog
  ///
  /// In en, this message translates to:
  /// **'Rename album'**
  String get albumRenameTitle;

  /// Label of the album name box
  ///
  /// In en, this message translates to:
  /// **'Album name'**
  String get albumNameLabel;

  /// Example album name
  ///
  /// In en, this message translates to:
  /// **'Holiday 2026'**
  String get albumNameHint;

  /// Confirms the album dialog
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get albumSave;

  /// Closes a dialog without saving
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get albumCancel;

  /// Renames the album
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get albumRename;

  /// Deletes the album
  ///
  /// In en, this message translates to:
  /// **'Delete album'**
  String get albumDelete;

  /// Opens the cover chooser
  ///
  /// In en, this message translates to:
  /// **'Choose cover'**
  String get albumChooseCover;

  /// Opens the reorder screen
  ///
  /// In en, this message translates to:
  /// **'Change order'**
  String get albumReorder;

  /// Adds media to the album
  ///
  /// In en, this message translates to:
  /// **'Add photos'**
  String get albumAddMedia;

  /// Takes one item out of the album
  ///
  /// In en, this message translates to:
  /// **'Remove from album'**
  String get albumRemoveMedia;

  /// Pins the album
  ///
  /// In en, this message translates to:
  /// **'Pin to top'**
  String get albumPin;

  /// Unpins the album
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get albumUnpin;

  /// Shown when the name box is empty
  ///
  /// In en, this message translates to:
  /// **'An album needs a name'**
  String get albumErrorEmpty;

  /// Shown when the name is over the limit
  ///
  /// In en, this message translates to:
  /// **'That name is too long'**
  String get albumErrorTooLong;

  /// Shown when the name is taken
  ///
  /// In en, this message translates to:
  /// **'An album with that name already exists'**
  String get albumErrorDuplicate;

  /// Shown when an album change fails
  ///
  /// In en, this message translates to:
  /// **'That change could not be saved'**
  String get albumErrorFailed;

  /// Title of the delete confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String albumDeleteConfirmTitle(String name);

  /// Explains that no file is deleted
  ///
  /// In en, this message translates to:
  /// **'Only the album goes. Every photo and video stays on the device exactly where it is.'**
  String get albumDeleteConfirmBody;

  /// Confirms deleting the album
  ///
  /// In en, this message translates to:
  /// **'Delete album'**
  String get albumDeleteConfirm;

  /// Shown after an album is deleted
  ///
  /// In en, this message translates to:
  /// **'Album deleted'**
  String get albumDeleted;

  /// Shown after an item leaves an album
  ///
  /// In en, this message translates to:
  /// **'Removed from the album'**
  String get albumRemovedFromAlbum;

  /// Shown after the cover is changed
  ///
  /// In en, this message translates to:
  /// **'Cover updated'**
  String get albumCoverSet;

  /// Shown after a reorder is saved
  ///
  /// In en, this message translates to:
  /// **'New order saved'**
  String get albumOrderSaved;

  /// Shown when an album holds nothing
  ///
  /// In en, this message translates to:
  /// **'This album is empty'**
  String get albumEmptyTitle;

  /// Explains how to fill an album
  ///
  /// In en, this message translates to:
  /// **'Add photos and videos from the gallery. They are not moved or copied.'**
  String get albumEmptyBody;

  /// Shown when an album id does not resolve
  ///
  /// In en, this message translates to:
  /// **'This album is no longer there'**
  String get albumGone;

  /// Title of the reorder screen
  ///
  /// In en, this message translates to:
  /// **'Change order'**
  String get albumReorderTitle;

  /// Explains how to reorder
  ///
  /// In en, this message translates to:
  /// **'Drag an item to move it. The new order is saved when you tap Save.'**
  String get albumReorderHint;

  /// Saves the new order
  ///
  /// In en, this message translates to:
  /// **'Save order'**
  String get albumReorderSave;

  /// Title of the cover chooser
  ///
  /// In en, this message translates to:
  /// **'Choose a cover'**
  String get albumCoverTitle;

  /// Clears the chosen cover
  ///
  /// In en, this message translates to:
  /// **'Use the newest item'**
  String get albumCoverClear;

  /// Title of the add-to-album sheet
  ///
  /// In en, this message translates to:
  /// **'Add to album'**
  String get albumPickerTitle;

  /// Shown when there is nothing to tick
  ///
  /// In en, this message translates to:
  /// **'You have no albums yet'**
  String get albumPickerEmpty;

  /// Makes an album from inside the sheet
  ///
  /// In en, this message translates to:
  /// **'New album'**
  String get albumPickerCreate;

  /// Closes the add-to-album sheet
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get albumPickerDone;

  /// Shown after album membership changes
  ///
  /// In en, this message translates to:
  /// **'Albums updated'**
  String get albumPickerSaved;

  /// Shown when a device folder has nothing to show
  ///
  /// In en, this message translates to:
  /// **'This folder is empty'**
  String get folderEmptyTitle;

  /// Shown when a smart album is empty
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get smartAlbumEmptyTitle;

  /// Shown for an unknown smart album key
  ///
  /// In en, this message translates to:
  /// **'That album does not exist'**
  String get smartAlbumUnknown;

  /// Filter row keeping only items with a tag
  ///
  /// In en, this message translates to:
  /// **'Tagged only'**
  String get filterHasTags;

  /// Heading of the file size filter
  ///
  /// In en, this message translates to:
  /// **'File size'**
  String get filterFileSize;

  /// Shown when no size range is set
  ///
  /// In en, this message translates to:
  /// **'Any size'**
  String get filterSizeAny;

  /// Small file size choice
  ///
  /// In en, this message translates to:
  /// **'Under 1 MB'**
  String get filterSizeSmall;

  /// Medium file size choice
  ///
  /// In en, this message translates to:
  /// **'1 to 10 MB'**
  String get filterSizeMedium;

  /// Large file size choice
  ///
  /// In en, this message translates to:
  /// **'Over 10 MB'**
  String get filterSizeLarge;

  /// Heading of the sort choice
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get filterSortBy;

  /// Sort choice
  ///
  /// In en, this message translates to:
  /// **'Date taken'**
  String get filterSortDateTaken;

  /// Sort choice
  ///
  /// In en, this message translates to:
  /// **'Date added'**
  String get filterSortDateAdded;

  /// Sort choice
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get filterSortName;

  /// Sort choice
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get filterSortSize;

  /// Sort direction
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get filterSortNewestFirst;

  /// Sort direction
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get filterSortOldestFirst;

  /// Title of the private vault
  ///
  /// In en, this message translates to:
  /// **'Private Vault'**
  String get vaultTitle;

  /// Menu entry that opens the private vault
  ///
  /// In en, this message translates to:
  /// **'Private Vault'**
  String get vaultMenuLabel;

  /// Viewer action that puts an item in the vault
  ///
  /// In en, this message translates to:
  /// **'Move to vault'**
  String get vaultMoveToVault;

  /// Title of the first-run vault set-up
  ///
  /// In en, this message translates to:
  /// **'Create your vault'**
  String get vaultSetUpTitle;

  /// Explains what the vault does
  ///
  /// In en, this message translates to:
  /// **'Items you move here are encrypted with a key held by this device and hidden from the gallery.'**
  String get vaultSetUpBody;

  /// Warning shown before a PIN is chosen
  ///
  /// In en, this message translates to:
  /// **'There is no way to recover a forgotten PIN. Without it nobody can open the vault, not even this app.'**
  String get vaultNoRecoveryWarning;

  /// Prompt for the first PIN entry
  ///
  /// In en, this message translates to:
  /// **'Choose a PIN'**
  String get vaultChoosePin;

  /// Prompt for the second PIN entry
  ///
  /// In en, this message translates to:
  /// **'Enter the PIN again'**
  String get vaultConfirmPin;

  /// Prompt on the unlock screen
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN'**
  String get vaultEnterPin;

  /// Button that creates the vault
  ///
  /// In en, this message translates to:
  /// **'Create vault'**
  String get vaultCreate;

  /// Button that opens the vault
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get vaultUnlock;

  /// Button that starts the biometric prompt
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint'**
  String get vaultUseBiometrics;

  /// Line Android shows in the biometric prompt
  ///
  /// In en, this message translates to:
  /// **'Unlock your private vault'**
  String get vaultUnlockReason;

  /// Action that shuts the vault straight away
  ///
  /// In en, this message translates to:
  /// **'Lock now'**
  String get vaultLockNow;

  /// Shown when the confirmation PIN differs
  ///
  /// In en, this message translates to:
  /// **'The two PINs are not the same'**
  String get vaultPinMismatch;

  /// Shown after a wrong PIN
  ///
  /// In en, this message translates to:
  /// **'That PIN is not right'**
  String get vaultWrongPin;

  /// How many tries remain before the pad shuts
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 try left} other{{count} tries left}}'**
  String vaultAttemptsLeft(int count);

  /// Shown while the pad is shut after repeated wrong PINs
  ///
  /// In en, this message translates to:
  /// **'Too many tries. Wait {seconds} seconds.'**
  String vaultLockedOut(int seconds);

  /// PIN rejected for being too short
  ///
  /// In en, this message translates to:
  /// **'A PIN needs at least {count} digits'**
  String vaultPinTooShort(int count);

  /// PIN rejected for being too long
  ///
  /// In en, this message translates to:
  /// **'A PIN can have at most {count} digits'**
  String vaultPinTooLong(int count);

  /// PIN rejected for holding something other than digits
  ///
  /// In en, this message translates to:
  /// **'A PIN can only have digits'**
  String get vaultPinNotDigits;

  /// PIN rejected for being one repeated digit
  ///
  /// In en, this message translates to:
  /// **'Do not use the same digit all the way through'**
  String get vaultPinAllSame;

  /// PIN rejected for being a sequence
  ///
  /// In en, this message translates to:
  /// **'Do not use digits in a straight run'**
  String get vaultPinSequential;

  /// Shown when the sensor does not recognise the user
  ///
  /// In en, this message translates to:
  /// **'Not recognised. Use your PIN.'**
  String get vaultBiometricFailed;

  /// Shown when no biometric can be used
  ///
  /// In en, this message translates to:
  /// **'Fingerprint unlock is not available. Use your PIN.'**
  String get vaultBiometricUnavailable;

  /// Shown when unlocking fails for a reason the user cannot act on
  ///
  /// In en, this message translates to:
  /// **'The vault could not be opened'**
  String get vaultAuthError;

  /// Title shown when the keystore is unusable
  ///
  /// In en, this message translates to:
  /// **'This device cannot hold the vault key'**
  String get vaultKeystoreUnavailableTitle;

  /// Explains why the vault will not open
  ///
  /// In en, this message translates to:
  /// **'The vault needs a hardware-backed key store, and this device does not have a working one. Nothing is encrypted without it, so the vault stays shut.'**
  String get vaultKeystoreUnavailableBody;

  /// Title shown when no items are in the vault
  ///
  /// In en, this message translates to:
  /// **'The vault is empty'**
  String get vaultEmptyTitle;

  /// Body shown when no items are in the vault
  ///
  /// In en, this message translates to:
  /// **'Add photos and videos here to encrypt them and take them out of the gallery.'**
  String get vaultEmptyBody;

  /// How many items the vault holds
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No items} =1{1 item} other{{count} items}}'**
  String vaultItemCount(int count);

  /// How many items are selected
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String vaultSelectedCount(int count);

  /// Action that opens the import sheet
  ///
  /// In en, this message translates to:
  /// **'Add items'**
  String get vaultAddItems;

  /// Action that takes items back out of the vault
  ///
  /// In en, this message translates to:
  /// **'Restore to gallery'**
  String get vaultRestore;

  /// Action that erases items and their payloads
  ///
  /// In en, this message translates to:
  /// **'Delete for good'**
  String get vaultDeleteForever;

  /// Action that opens the vault settings
  ///
  /// In en, this message translates to:
  /// **'Vault settings'**
  String get vaultSettingsAction;

  /// Shown while a batch runs
  ///
  /// In en, this message translates to:
  /// **'Working…'**
  String get vaultWorking;

  /// Dismisses a vault dialog
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get vaultCancel;

  /// Selects every item in the vault
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get vaultSelectAll;

  /// Clears the current selection
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get vaultClearSelection;

  /// Title of the import sheet
  ///
  /// In en, this message translates to:
  /// **'Move to vault'**
  String get vaultImportTitle;

  /// Explains what an import does
  ///
  /// In en, this message translates to:
  /// **'The items are encrypted and taken out of the gallery. What happens to the originals is up to you.'**
  String get vaultImportBody;

  /// Import choice that leaves the public files alone
  ///
  /// In en, this message translates to:
  /// **'Keep the originals'**
  String get vaultImportKeepOriginal;

  /// Explains the keep choice
  ///
  /// In en, this message translates to:
  /// **'The originals stay where they are. Delete them yourself later if you want to.'**
  String get vaultImportKeepOriginalBody;

  /// Import choice that destroys the public files
  ///
  /// In en, this message translates to:
  /// **'Shred the originals'**
  String get vaultImportShredOriginal;

  /// Explains the shred choice
  ///
  /// In en, this message translates to:
  /// **'The original files are overwritten and deleted. This cannot be undone.'**
  String get vaultImportShredOriginalBody;

  /// Button that starts the import
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Move 1 item} other{Move {count} items}}'**
  String vaultImportConfirm(int count);

  /// Shown when the import sheet has no selection
  ///
  /// In en, this message translates to:
  /// **'Nothing is selected'**
  String get vaultImportNothingSelected;

  /// Title of the shred confirmation
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Destroy 1 original?} other{Destroy {count} originals?}}'**
  String vaultShredConfirmTitle(int count);

  /// Body of the shred confirmation
  ///
  /// In en, this message translates to:
  /// **'The original files will be overwritten and deleted. There is no undo, and no way to get them back.'**
  String get vaultShredConfirmBody;

  /// Confirms shredding the originals
  ///
  /// In en, this message translates to:
  /// **'Shred them'**
  String get vaultShredConfirmAction;

  /// Shown after a successful import
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item moved to the vault} other{{count} items moved to the vault}}'**
  String vaultImportDone(int count);

  /// Shown when only some of a batch imported
  ///
  /// In en, this message translates to:
  /// **'{moved} moved, {failed} could not be read'**
  String vaultImportPartial(int moved, int failed);

  /// Shown when a whole import failed
  ///
  /// In en, this message translates to:
  /// **'Nothing could be moved to the vault'**
  String get vaultImportFailed;

  /// Title of the restore confirmation
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Restore 1 item?} other{Restore {count} items?}}'**
  String vaultRestoreConfirmTitle(int count);

  /// Body of the restore confirmation
  ///
  /// In en, this message translates to:
  /// **'The items are written back into your gallery folders and taken out of the vault.'**
  String get vaultRestoreConfirmBody;

  /// Confirms restoring items
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get vaultRestoreConfirmAction;

  /// Shown after a successful restore
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item restored} other{{count} items restored}}'**
  String vaultRestoreDone(int count);

  /// Shown when a whole restore failed
  ///
  /// In en, this message translates to:
  /// **'Nothing could be restored'**
  String get vaultRestoreFailed;

  /// Title of the delete confirmation
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Delete 1 item for good?} other{Delete {count} items for good?}}'**
  String vaultDeleteConfirmTitle(int count);

  /// Body of the delete confirmation
  ///
  /// In en, this message translates to:
  /// **'The encrypted files are overwritten and deleted. There is no undo, and no copy anywhere else.'**
  String get vaultDeleteConfirmBody;

  /// Shown after a successful delete
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item deleted} other{{count} items deleted}}'**
  String vaultDeleteDone(int count);

  /// Shown when a vault item will not decrypt
  ///
  /// In en, this message translates to:
  /// **'This item could not be opened'**
  String get vaultViewerFailed;

  /// Shown when a payload fails its authentication tag
  ///
  /// In en, this message translates to:
  /// **'This item failed its integrity check and was not opened'**
  String get vaultViewerTampered;

  /// Title of the vault settings screen
  ///
  /// In en, this message translates to:
  /// **'Vault settings'**
  String get vaultSettingsTitle;

  /// Heading of the auto-lock choice
  ///
  /// In en, this message translates to:
  /// **'Auto-lock'**
  String get vaultAutoLockHeading;

  /// Explains the auto-lock rules
  ///
  /// In en, this message translates to:
  /// **'The vault always locks when the app leaves the screen. This is how long it waits while you are not touching it.'**
  String get vaultAutoLockBody;

  /// An auto-lock choice measured in seconds
  ///
  /// In en, this message translates to:
  /// **'{count} seconds'**
  String vaultAutoLockSeconds(int count);

  /// An auto-lock choice measured in minutes
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute} other{{count} minutes}}'**
  String vaultAutoLockMinutes(int count);

  /// Heading of the biometric toggle
  ///
  /// In en, this message translates to:
  /// **'Unlock with fingerprint'**
  String get vaultBiometricHeading;

  /// Explains the biometric toggle
  ///
  /// In en, this message translates to:
  /// **'A shortcut, not a replacement. Your PIN opens the vault whether this is on or off.'**
  String get vaultBiometricBody;

  /// Heading of the shred pass choice
  ///
  /// In en, this message translates to:
  /// **'Shred passes'**
  String get vaultShredHeading;

  /// Explains shredding and its limits
  ///
  /// In en, this message translates to:
  /// **'How many times a file is overwritten before it is deleted. More passes take longer. On flash storage an overwrite is a strong measure, not a guarantee.'**
  String get vaultShredBody;

  /// A shred pass choice
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 pass} other{{count} passes}}'**
  String vaultShredPassCount(int count);

  /// Heading of the shred-on-import default
  ///
  /// In en, this message translates to:
  /// **'Shred originals by default'**
  String get vaultShredDefaultHeading;

  /// Explains the shred-on-import default
  ///
  /// In en, this message translates to:
  /// **'Pre-selects the shred choice when you add items. It still asks you to confirm every time.'**
  String get vaultShredDefaultBody;

  /// Action that opens the change PIN dialog
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get vaultChangePin;

  /// Field label for the existing PIN
  ///
  /// In en, this message translates to:
  /// **'Current PIN'**
  String get vaultCurrentPin;

  /// Field label for the replacement PIN
  ///
  /// In en, this message translates to:
  /// **'New PIN'**
  String get vaultNewPin;

  /// Shown after a successful PIN change
  ///
  /// In en, this message translates to:
  /// **'Your PIN has been changed'**
  String get vaultPinChanged;

  /// Heading of the secure window note
  ///
  /// In en, this message translates to:
  /// **'Screenshots are blocked'**
  String get vaultSecureScreenHeading;

  /// Explains the secure window flag
  ///
  /// In en, this message translates to:
  /// **'While the vault is open, Android blocks screenshots and screen recording, and hides the vault in the app switcher.'**
  String get vaultSecureScreenBody;

  /// Title while items are selected
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 selected} other{{count} selected}}'**
  String selectionCount(int count);

  /// Tooltip that unticks everything
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get selectionClear;

  /// Tooltip that ticks everything on screen
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectionSelectAll;

  /// Shown when the selection cap is reached
  ///
  /// In en, this message translates to:
  /// **'That is as many as one batch can hold'**
  String get selectionFull;

  /// Title of the batch action sheet
  ///
  /// In en, this message translates to:
  /// **'Batch actions'**
  String get batchTitle;

  /// Batch action: change image format
  ///
  /// In en, this message translates to:
  /// **'Convert'**
  String get batchActionConvert;

  /// Batch action: stamp the photos
  ///
  /// In en, this message translates to:
  /// **'Watermark'**
  String get batchActionWatermark;

  /// Batch action: one PDF from many photos
  ///
  /// In en, this message translates to:
  /// **'Make a PDF'**
  String get batchActionExportPdf;

  /// Batch action: tag everything selected
  ///
  /// In en, this message translates to:
  /// **'Add tags'**
  String get batchActionAddTags;

  /// Batch action: untag everything selected
  ///
  /// In en, this message translates to:
  /// **'Remove tags'**
  String get batchActionRemoveTags;

  /// Batch action: put everything in an album
  ///
  /// In en, this message translates to:
  /// **'Add to album'**
  String get batchActionAddToAlbum;

  /// Batch action: mark as favourite
  ///
  /// In en, this message translates to:
  /// **'Add to favourites'**
  String get batchActionFavourite;

  /// Batch action: clear the favourite mark
  ///
  /// In en, this message translates to:
  /// **'Remove from favourites'**
  String get batchActionUnfavourite;

  /// Batch action: encrypt into the private vault
  ///
  /// In en, this message translates to:
  /// **'Move to vault'**
  String get batchActionMoveToVault;

  /// Batch action: offer the files over local Wi-Fi
  ///
  /// In en, this message translates to:
  /// **'Send to a device'**
  String get batchActionTransfer;

  /// Batch action: flag as trashed
  ///
  /// In en, this message translates to:
  /// **'Move to trash'**
  String get batchActionMoveToTrash;

  /// Why an action is unavailable: nothing selected
  ///
  /// In en, this message translates to:
  /// **'Select something first'**
  String get batchBlockedEmpty;

  /// Why an action is unavailable: over the cap
  ///
  /// In en, this message translates to:
  /// **'Too many items for one batch'**
  String get batchBlockedTooLarge;

  /// Why an action is unavailable: wrong media types
  ///
  /// In en, this message translates to:
  /// **'Not available for these files'**
  String get batchBlockedUnsupported;

  /// Why an action is unavailable: mixed selection
  ///
  /// In en, this message translates to:
  /// **'Videos cannot be included in this action'**
  String get batchBlockedMixed;

  /// Warns that some selected files are not applicable
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file will be skipped} other{{count} files will be skipped}}'**
  String batchWillSkip(int count);

  /// Title of the batch progress dialog
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get batchRunning;

  /// Progress line of the batch dialog
  ///
  /// In en, this message translates to:
  /// **'{done} of {total}'**
  String batchProgress(int done, int total);

  /// Stops the running batch after the current file
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get batchCancel;

  /// Shown once a cancel has been asked for
  ///
  /// In en, this message translates to:
  /// **'Stopping after this file'**
  String get batchCancelling;

  /// Title of the batch result sheet
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get batchDone;

  /// How many files the batch finished
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file done} other{{count} files done}}'**
  String batchResultSucceeded(int count);

  /// How many files the batch could not finish
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file could not be done} other{{count} files could not be done}}'**
  String batchResultFailed(int count);

  /// How many files the batch passed over
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file skipped} other{{count} files skipped}}'**
  String batchResultSkipped(int count);

  /// Title of the confirmation before a batch that writes files
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get batchConfirmTitle;

  /// Confirmation body for a vault batch
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo will be moved into the vault} other{{count} photos will be moved into the vault}}'**
  String batchConfirmVault(int count);

  /// Confirmation body for a trash batch
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item will be moved to the trash. Nothing is erased.} other{{count} items will be moved to the trash. Nothing is erased.}}'**
  String batchConfirmTrash(int count);

  /// Confirmation body for a batch that writes new files
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{A new file will be saved beside the original.} other{{count} new files will be saved beside the originals.}}'**
  String batchConfirmNewFiles(int count);

  /// Confirms and starts the batch
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get batchConfirmContinue;

  /// Title of the tag picker used by a batch
  ///
  /// In en, this message translates to:
  /// **'Choose tags'**
  String get batchPickTags;

  /// Title of the album picker used by a batch
  ///
  /// In en, this message translates to:
  /// **'Choose an album'**
  String get batchPickAlbum;

  /// Title of the backup screen
  ///
  /// In en, this message translates to:
  /// **'Backup and restore'**
  String get backupTitle;

  /// Menu entry that opens the backup screen
  ///
  /// In en, this message translates to:
  /// **'Backup and restore'**
  String get backupOpen;

  /// Heading of the create half of the backup screen
  ///
  /// In en, this message translates to:
  /// **'Create a backup'**
  String get backupCreateTitle;

  /// Explains what a backup does and does not hold
  ///
  /// In en, this message translates to:
  /// **'Saves your tags, albums, favourites and notes into one password-protected file. Photos and videos are not included: send those to another device with Transfer.'**
  String get backupCreateBody;

  /// Button that starts a backup
  ///
  /// In en, this message translates to:
  /// **'Create backup'**
  String get backupCreateAction;

  /// Heading of the restore half of the backup screen
  ///
  /// In en, this message translates to:
  /// **'Restore a backup'**
  String get backupRestoreTitle;

  /// Explains what a restore does
  ///
  /// In en, this message translates to:
  /// **'Brings back tags, albums, favourites and notes for the photos that are on this device. Nothing on this device is deleted.'**
  String get backupRestoreBody;

  /// Button that starts a restore
  ///
  /// In en, this message translates to:
  /// **'Choose a backup file'**
  String get backupRestoreAction;

  /// Title of the password dialog
  ///
  /// In en, this message translates to:
  /// **'Backup password'**
  String get backupPasswordTitle;

  /// Label of the password field
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get backupPasswordLabel;

  /// Label of the confirm password field
  ///
  /// In en, this message translates to:
  /// **'Type it again'**
  String get backupPasswordConfirmLabel;

  /// Warns that a forgotten password loses the archive
  ///
  /// In en, this message translates to:
  /// **'There is no way to recover this password. If you forget it, the backup cannot be opened.'**
  String get backupPasswordWarning;

  /// Validation message for a short password
  ///
  /// In en, this message translates to:
  /// **'At least {count} characters'**
  String backupPasswordTooShort(int count);

  /// Validation message when the confirm field differs
  ///
  /// In en, this message translates to:
  /// **'The two do not match'**
  String get backupPasswordMismatch;

  /// Backup progress stage
  ///
  /// In en, this message translates to:
  /// **'Reading your library'**
  String get backupStageCollecting;

  /// Backup progress stage
  ///
  /// In en, this message translates to:
  /// **'Packing'**
  String get backupStagePacking;

  /// Backup progress stage
  ///
  /// In en, this message translates to:
  /// **'Waiting for you to choose where to save'**
  String get backupStageChoosing;

  /// Backup progress stage
  ///
  /// In en, this message translates to:
  /// **'Encrypting'**
  String get backupStageEncrypting;

  /// Shown after a successful backup
  ///
  /// In en, this message translates to:
  /// **'Backup saved'**
  String get backupDone;

  /// Shown when the user backed out of the file picker
  ///
  /// In en, this message translates to:
  /// **'Backup cancelled'**
  String get backupCancelled;

  /// Shown when the library holds nothing worth backing up
  ///
  /// In en, this message translates to:
  /// **'There are no tags, albums, notes or favourites to back up yet'**
  String get backupNothingToSave;

  /// Shown when a backup fails
  ///
  /// In en, this message translates to:
  /// **'The backup could not be saved'**
  String get backupFailed;

  /// Title of the restore preview sheet
  ///
  /// In en, this message translates to:
  /// **'What will be restored'**
  String get restorePreviewTitle;

  /// Says when the archive was made
  ///
  /// In en, this message translates to:
  /// **'Backup from {date}'**
  String restoreFromBackupDate(String date);

  /// How many tags a restore would create
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No new tags} =1{1 new tag} other{{count} new tags}}'**
  String restorePlanTags(int count);

  /// How many albums a restore would create
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No new albums} =1{1 new album} other{{count} new albums}}'**
  String restorePlanAlbums(int count);

  /// How many links a restore would add
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No tags or album places to add} =1{1 tag or album place to add} other{{count} tags and album places to add}}'**
  String restorePlanLinks(int count);

  /// How many media rows a restore would change
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No photos to update} =1{1 photo to update} other{{count} photos to update}}'**
  String restorePlanUpdates(int count);

  /// How many archive records found no local file
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo in the backup is not on this device} other{{count} photos in the backup are not on this device}}'**
  String restorePlanUnmatched(int count);

  /// Shown when the plan is empty
  ///
  /// In en, this message translates to:
  /// **'This backup would change nothing on this device'**
  String get restorePlanNothing;

  /// Confirms and applies the restore plan
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreApply;

  /// Shown after a successful restore
  ///
  /// In en, this message translates to:
  /// **'Restore finished'**
  String get restoreDone;

  /// Shown when the archive will not open
  ///
  /// In en, this message translates to:
  /// **'Wrong password, or the file is damaged'**
  String get restoreWrongPassword;

  /// Shown when the chosen file is the wrong kind
  ///
  /// In en, this message translates to:
  /// **'That is not a gallery backup file'**
  String get restoreNotAnArchive;

  /// Shown when the chosen file is implausibly large
  ///
  /// In en, this message translates to:
  /// **'That file is too large to be a gallery backup'**
  String get restoreTooLarge;

  /// Shown when the archive format is from the future
  ///
  /// In en, this message translates to:
  /// **'That backup was made by a newer version of the app'**
  String get restoreTooNew;

  /// Shown when a restore fails
  ///
  /// In en, this message translates to:
  /// **'The backup could not be restored'**
  String get restoreFailed;

  /// Title of the transfer screen
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get syncTitle;

  /// Menu entry that opens the transfer screen
  ///
  /// In en, this message translates to:
  /// **'Transfer to a device'**
  String get syncOpen;

  /// Explains what the transfer feature does
  ///
  /// In en, this message translates to:
  /// **'Send photos straight to another phone on the same Wi-Fi. Nothing goes to the internet, and no account is needed.'**
  String get syncIntro;

  /// Explains the local-network-only guarantee
  ///
  /// In en, this message translates to:
  /// **'Both phones must be on the same Wi-Fi. The connection is refused unless the other device is on your local network, and it is closed as soon as you leave this screen.'**
  String get syncPrivacyNote;

  /// Chooses the sending role
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get syncSend;

  /// Chooses the receiving role
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get syncReceive;

  /// Explains the sending flow
  ///
  /// In en, this message translates to:
  /// **'Show a code on this phone, or scan the other one'**
  String get syncSendBody;

  /// Explains the receiving flow
  ///
  /// In en, this message translates to:
  /// **'Show a code for the other phone to scan'**
  String get syncReceiveBody;

  /// Starts listening and shows the pairing code
  ///
  /// In en, this message translates to:
  /// **'Show a code'**
  String get syncShowCode;

  /// Opens the camera to read a pairing code
  ///
  /// In en, this message translates to:
  /// **'Scan a code'**
  String get syncScanCode;

  /// Title of the scanner screen
  ///
  /// In en, this message translates to:
  /// **'Scan the other phone'**
  String get syncScanTitle;

  /// Heading above the QR code
  ///
  /// In en, this message translates to:
  /// **'Point the other phone at this code'**
  String get syncPairingHeading;

  /// Heading above the typed fallback code
  ///
  /// In en, this message translates to:
  /// **'Or type this code'**
  String get syncManualCodeHeading;

  /// Label of the typed code field
  ///
  /// In en, this message translates to:
  /// **'Pairing code'**
  String get syncManualCodeLabel;

  /// Shown when a typed code does not check out
  ///
  /// In en, this message translates to:
  /// **'That code is not valid'**
  String get syncManualCodeInvalid;

  /// Shown while the listener is open
  ///
  /// In en, this message translates to:
  /// **'Waiting for the other phone'**
  String get syncWaiting;

  /// Shown once a peer has connected
  ///
  /// In en, this message translates to:
  /// **'Paired with {name}'**
  String syncPairedWith(String name);

  /// Shown while files are moving
  ///
  /// In en, this message translates to:
  /// **'Transferring'**
  String get syncTransferring;

  /// Per-file progress line
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} files'**
  String syncProgressFiles(int done, int total);

  /// Shown when the sending role has an empty outbox
  ///
  /// In en, this message translates to:
  /// **'Choose some photos to send first'**
  String get syncNothingSelected;

  /// How many files the peer is offering
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file offered} other{{count} files offered}}'**
  String syncOfferHeading(int count);

  /// Shown when a transfer completes
  ///
  /// In en, this message translates to:
  /// **'Transfer finished'**
  String get syncDone;

  /// How many files arrived
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file received} other{{count} files received}}'**
  String syncResultReceived(int count);

  /// How many files were sent
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file sent} other{{count} files sent}}'**
  String syncResultSent(int count);

  /// How many files the receiver already had
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file was already there} other{{count} files were already there}}'**
  String syncResultSkipped(int count);

  /// How many files failed their checks
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file did not arrive} other{{count} files did not arrive}}'**
  String syncResultFailed(int count);

  /// Explains the pre-Android-10 fallback location
  ///
  /// In en, this message translates to:
  /// **'On this version of Android the files were saved in the app\'s own folder rather than your gallery.'**
  String get syncSavedToAppFolder;

  /// Ends the transfer session
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get syncStop;

  /// Transfer failure: no local network
  ///
  /// In en, this message translates to:
  /// **'This phone is not on a Wi-Fi network'**
  String get syncErrorNoNetwork;

  /// Transfer failure: nobody paired
  ///
  /// In en, this message translates to:
  /// **'No device connected in time'**
  String get syncErrorPairingTimeout;

  /// Transfer failure: the peer address was refused
  ///
  /// In en, this message translates to:
  /// **'That device is not on your local network'**
  String get syncErrorRefused;

  /// Transfer failure: the handshake was rejected
  ///
  /// In en, this message translates to:
  /// **'The other device could not prove it showed that code'**
  String get syncErrorHandshake;

  /// Transfer failure: protocol version mismatch
  ///
  /// In en, this message translates to:
  /// **'The other device is running a different version of the app'**
  String get syncErrorProtocol;

  /// Transfer failure: the socket dropped
  ///
  /// In en, this message translates to:
  /// **'The connection to the other device was lost'**
  String get syncErrorConnection;

  /// Transfer failure: idle timeout
  ///
  /// In en, this message translates to:
  /// **'The other device stopped responding'**
  String get syncErrorIdle;

  /// Transfer failure: cancelled by a user
  ///
  /// In en, this message translates to:
  /// **'The transfer was stopped'**
  String get syncErrorCancelled;

  /// Transfer failure: anything else
  ///
  /// In en, this message translates to:
  /// **'The transfer could not be finished'**
  String get syncErrorUnknown;

  /// Shown when the camera permission is refused
  ///
  /// In en, this message translates to:
  /// **'Camera access is needed to scan the code. You can type the code instead.'**
  String get syncCameraPermission;

  /// Switches from the scanner to the typed code field
  ///
  /// In en, this message translates to:
  /// **'Type the code instead'**
  String get syncTypeCodeInstead;

  /// Opens the overflow menu in the fullscreen viewer
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get viewerMoreActions;

  /// Viewer menu entry that looks for QR and barcodes in the picture
  ///
  /// In en, this message translates to:
  /// **'Scan codes'**
  String get codeScanOpen;

  /// Title of the in-image scanner screen
  ///
  /// In en, this message translates to:
  /// **'Codes in this picture'**
  String get codeScanTitle;

  /// Shown while a picture is being scanned
  ///
  /// In en, this message translates to:
  /// **'Looking for codes'**
  String get codeScanLooking;

  /// Shown when the scan worked but the picture held no codes
  ///
  /// In en, this message translates to:
  /// **'No codes were found in this picture'**
  String get codeScanNoCodes;

  /// Shown when the decoder itself could not run
  ///
  /// In en, this message translates to:
  /// **'This picture could not be scanned'**
  String get codeScanFailed;

  /// Runs the scan again
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get codeScanRetry;

  /// How many codes the picture held
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 code found} other{{count} codes found}}'**
  String codeScanFoundCount(int count);

  /// Label for a scanned code holding a web address
  ///
  /// In en, this message translates to:
  /// **'Web address'**
  String get codeScanKindUrl;

  /// Label for a scanned Wi-Fi joining code
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi network'**
  String get codeScanKindWifi;

  /// Label for a scanned phone number
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get codeScanKindPhone;

  /// Label for a scanned email address
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get codeScanKindEmail;

  /// Label for a scanned text message code
  ///
  /// In en, this message translates to:
  /// **'Text message'**
  String get codeScanKindSms;

  /// Label for a scanned map location
  ///
  /// In en, this message translates to:
  /// **'Map point'**
  String get codeScanKindGeo;

  /// Label for a scanned vCard or MECARD
  ///
  /// In en, this message translates to:
  /// **'Contact card'**
  String get codeScanKindContact;

  /// Label for a scanned calendar event
  ///
  /// In en, this message translates to:
  /// **'Calendar entry'**
  String get codeScanKindCalendar;

  /// Label for a scanned code that is just text
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get codeScanKindText;

  /// Copies the raw code text to the clipboard
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get codeScanActionCopy;

  /// Opens a scanned web address in the browser
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get codeScanActionOpen;

  /// Offers a scanned number to the dialler
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get codeScanActionDial;

  /// Starts an email to a scanned address
  ///
  /// In en, this message translates to:
  /// **'Write email'**
  String get codeScanActionEmail;

  /// Starts a text message to a scanned number
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get codeScanActionSms;

  /// Shows a scanned map point
  ///
  /// In en, this message translates to:
  /// **'Show on map'**
  String get codeScanActionMap;

  /// Copies only the Wi-Fi password from a scanned code
  ///
  /// In en, this message translates to:
  /// **'Copy password'**
  String get codeScanActionCopyWifiPassword;

  /// Offers the scanned network to Android and opens the Wi-Fi settings
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get codeScanActionConnectWifi;

  /// Adds the code text to this item's notes
  ///
  /// In en, this message translates to:
  /// **'Save to notes'**
  String get codeScanActionSaveToNotes;

  /// Why an action is blocked: the scheme is not on the permitted list
  ///
  /// In en, this message translates to:
  /// **'The app does not open this kind of address'**
  String get codeScanBlockedScheme;

  /// Why an action is blocked: the target is malformed
  ///
  /// In en, this message translates to:
  /// **'This address could not be read'**
  String get codeScanBlockedMalformed;

  /// Why an action is blocked: incomplete Wi-Fi details
  ///
  /// In en, this message translates to:
  /// **'This Wi-Fi code is missing the network name or the password'**
  String get codeScanBlockedIncompleteWifi;

  /// Why an action is blocked: the payload is past the cap
  ///
  /// In en, this message translates to:
  /// **'This code is too long to use'**
  String get codeScanBlockedTooLong;

  /// Confirms the code text went to the clipboard
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get codeScanCopied;

  /// Confirms the Wi-Fi password went to the clipboard
  ///
  /// In en, this message translates to:
  /// **'Password copied'**
  String get codeScanPasswordCopied;

  /// Confirms the code text was added to the notes
  ///
  /// In en, this message translates to:
  /// **'Saved to notes'**
  String get codeScanSavedToNotes;

  /// Shown when no installed app handles the scanned address
  ///
  /// In en, this message translates to:
  /// **'No app on this device can open it'**
  String get codeScanOpenFailed;

  /// Shown after a Wi-Fi suggestion was accepted
  ///
  /// In en, this message translates to:
  /// **'The network was offered to Android. Pick it in the Wi-Fi settings.'**
  String get codeScanWifiSuggested;

  /// Shown when Android would not take the Wi-Fi suggestion
  ///
  /// In en, this message translates to:
  /// **'Open the Wi-Fi settings and pick the network yourself.'**
  String get codeScanWifiManual;

  /// Names how a scanned Wi-Fi network is protected
  ///
  /// In en, this message translates to:
  /// **'Security: {security}'**
  String codeScanWifiSecurity(String security);

  /// Marks a scanned Wi-Fi network that hides its name
  ///
  /// In en, this message translates to:
  /// **'Hidden network'**
  String get codeScanWifiHidden;

  /// Marks a scanned Wi-Fi network with no password
  ///
  /// In en, this message translates to:
  /// **'Open network'**
  String get codeScanWifiOpen;

  /// Viewer menu entry that reads the text out of the picture
  ///
  /// In en, this message translates to:
  /// **'Extract text'**
  String get ocrOpen;

  /// Title of the extracted text screen
  ///
  /// In en, this message translates to:
  /// **'Text in this picture'**
  String get ocrTitle;

  /// Shown while the reader is running
  ///
  /// In en, this message translates to:
  /// **'Reading the text'**
  String get ocrReading;

  /// Sets the expectation that OCR is not instant
  ///
  /// In en, this message translates to:
  /// **'A large photo can take a few seconds.'**
  String get ocrSlowHint;

  /// Label of the language chooser on the text screen
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get ocrLanguage;

  /// OCR language choice: English only
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get ocrLanguageEnglish;

  /// OCR language choice: Malayalam only
  ///
  /// In en, this message translates to:
  /// **'Malayalam'**
  String get ocrLanguageMalayalam;

  /// OCR language choice: both at once
  ///
  /// In en, this message translates to:
  /// **'English and Malayalam'**
  String get ocrLanguageBoth;

  /// Shown when the reader ran but found nothing
  ///
  /// In en, this message translates to:
  /// **'No text was found in this picture'**
  String get ocrNoText;

  /// Copies the whole extracted text
  ///
  /// In en, this message translates to:
  /// **'Copy all'**
  String get ocrCopyAll;

  /// Confirms the extracted text went to the clipboard
  ///
  /// In en, this message translates to:
  /// **'Text copied'**
  String get ocrCopied;

  /// Adds the extracted text to this item's notes
  ///
  /// In en, this message translates to:
  /// **'Save to notes'**
  String get ocrSaveToNotes;

  /// Confirms the extracted text was added to the notes
  ///
  /// In en, this message translates to:
  /// **'Saved to notes'**
  String get ocrSavedToNotes;

  /// Runs the reader again, usually after changing the language
  ///
  /// In en, this message translates to:
  /// **'Read again'**
  String get ocrReadAgain;

  /// How many words were read out of the picture
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 word} other{{count} words}}'**
  String ocrWordCount(int count);

  /// OCR failure: the file is missing or unreadable
  ///
  /// In en, this message translates to:
  /// **'This picture could not be opened'**
  String get ocrFailedUnreadable;

  /// OCR failure: the image is past the size cap
  ///
  /// In en, this message translates to:
  /// **'This picture is too large to read'**
  String get ocrFailedTooLarge;

  /// OCR failure: the traineddata assets are not present
  ///
  /// In en, this message translates to:
  /// **'The language files are missing from this build'**
  String get ocrFailedMissingData;

  /// OCR failure: the reader was given up on
  ///
  /// In en, this message translates to:
  /// **'Reading took too long and was stopped'**
  String get ocrFailedTimeout;

  /// OCR failure: anything else
  ///
  /// In en, this message translates to:
  /// **'The text could not be read'**
  String get ocrFailedEngine;

  /// Viewer menu entry that opens the note editor
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesOpen;

  /// Title of the note editor screen
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesTitle;

  /// Tab showing the note's markdown source for editing
  ///
  /// In en, this message translates to:
  /// **'Write'**
  String get notesWriteTab;

  /// Tab showing the note as formatted text
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get notesPreviewTab;

  /// Placeholder text of the empty note editor
  ///
  /// In en, this message translates to:
  /// **'Write a note about this item. Markdown is supported.'**
  String get notesHint;

  /// Shown in the preview when nothing has been written
  ///
  /// In en, this message translates to:
  /// **'No note yet'**
  String get notesEmpty;

  /// Writes the note
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get notesSave;

  /// Confirms the note was written
  ///
  /// In en, this message translates to:
  /// **'Note saved'**
  String get notesSaved;

  /// Shown when writing the note failed
  ///
  /// In en, this message translates to:
  /// **'The note could not be saved'**
  String get notesSaveFailed;

  /// Removes the note from this item
  ///
  /// In en, this message translates to:
  /// **'Delete note'**
  String get notesDelete;

  /// Title of the delete confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete this note?'**
  String get notesDeleteTitle;

  /// Body of the delete confirmation, making clear the media is untouched
  ///
  /// In en, this message translates to:
  /// **'The note will be removed. The file is not changed.'**
  String get notesDeleteBody;

  /// Confirms the note was removed
  ///
  /// In en, this message translates to:
  /// **'Note deleted'**
  String get notesDeleted;

  /// Closes a note dialog without doing anything
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get notesCancel;

  /// How much of the note length budget is used
  ///
  /// In en, this message translates to:
  /// **'{used} of {total} characters'**
  String notesCharacterCount(int used, int total);

  /// Shown when the note is past the length cap
  ///
  /// In en, this message translates to:
  /// **'This note is too long to save'**
  String get notesTooLong;

  /// Title of the unsaved changes prompt
  ///
  /// In en, this message translates to:
  /// **'Leave without saving?'**
  String get notesDiscardTitle;

  /// Body of the unsaved changes prompt
  ///
  /// In en, this message translates to:
  /// **'Your changes to this note will be lost.'**
  String get notesDiscardBody;

  /// Leaves the note editor and loses the changes
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get notesDiscardLeave;

  /// Stays in the note editor
  ///
  /// In en, this message translates to:
  /// **'Keep writing'**
  String get notesDiscardKeep;

  /// Shown when a link in a note uses a scheme the app will not launch
  ///
  /// In en, this message translates to:
  /// **'The app does not open this kind of link'**
  String get notesLinkBlocked;

  /// Label of the note line in the details sheet
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get notesDetailsLabel;

  /// Details sheet action when the item has no note yet
  ///
  /// In en, this message translates to:
  /// **'Add a note'**
  String get notesAddFromDetails;

  /// Home screen entry point for the PDF image tool
  ///
  /// In en, this message translates to:
  /// **'Extract images from PDF'**
  String get pdfImagesOpen;

  /// Title of the PDF image extraction screen
  ///
  /// In en, this message translates to:
  /// **'Images in a PDF'**
  String get pdfImagesTitle;

  /// Opens the system file picker for a PDF
  ///
  /// In en, this message translates to:
  /// **'Choose a PDF'**
  String get pdfImagesPick;

  /// Picks a different PDF once one has been read
  ///
  /// In en, this message translates to:
  /// **'Choose another PDF'**
  String get pdfImagesChooseAnother;

  /// Shown while a PDF is being parsed
  ///
  /// In en, this message translates to:
  /// **'Reading the PDF'**
  String get pdfImagesReading;

  /// Title of the empty state before a PDF is picked
  ///
  /// In en, this message translates to:
  /// **'No PDF chosen yet'**
  String get pdfImagesEmptyTitle;

  /// Body of the empty state, making clear the source file is untouched
  ///
  /// In en, this message translates to:
  /// **'Pick a PDF and the app will list the pictures inside it. The PDF itself is never changed.'**
  String get pdfImagesEmptyBody;

  /// Shown when a PDF was read but had no image objects
  ///
  /// In en, this message translates to:
  /// **'This PDF holds no pictures'**
  String get pdfImagesNone;

  /// How many pictures the PDF held
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 picture found} other{{count} pictures found}}'**
  String pdfImagesFound(int count);

  /// How many pictures were found but cannot be extracted
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 could not be read} other{{count} could not be read}}'**
  String pdfImagesSkippedCount(int count);

  /// Writes the ticked pictures into the gallery
  ///
  /// In en, this message translates to:
  /// **'Save selected'**
  String get pdfImagesSave;

  /// Shown while pictures are being written
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get pdfImagesSaving;

  /// Confirms how many pictures were written
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 picture saved to the gallery} other{{count} pictures saved to the gallery}}'**
  String pdfImagesSavedCount(int count);

  /// Reports how many pictures failed to save
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 could not be saved} other{{count} could not be saved}}'**
  String pdfImagesSaveFailedCount(int count);

  /// Ticks every picture that can be saved
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get pdfImagesSelectAll;

  /// Unticks every picture
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get pdfImagesClearSelection;

  /// Shown when save is tapped with nothing ticked
  ///
  /// In en, this message translates to:
  /// **'Tick at least one picture to save'**
  String get pdfImagesNothingSelected;

  /// Warns that the image count cap was reached
  ///
  /// In en, this message translates to:
  /// **'Only the first pictures were read, because this PDF holds a great many.'**
  String get pdfImagesTruncated;

  /// Shown when MediaStore was unavailable and a plain folder was used
  ///
  /// In en, this message translates to:
  /// **'Saved to the app folder, because the gallery could not be written to'**
  String get pdfImagesFallbackDirectory;

  /// Pixel size of one extracted picture
  ///
  /// In en, this message translates to:
  /// **'{width} by {height}'**
  String pdfImageSize(int width, int height);

  /// Refusal: the chosen file has no PDF header
  ///
  /// In en, this message translates to:
  /// **'This file is not a PDF'**
  String get pdfRefusedNotPdf;

  /// Refusal: the PDF is encrypted
  ///
  /// In en, this message translates to:
  /// **'This PDF is password protected, so it cannot be opened'**
  String get pdfRefusedEncrypted;

  /// Refusal: the PDF is past the size cap
  ///
  /// In en, this message translates to:
  /// **'This PDF is too large to open'**
  String get pdfRefusedTooLarge;

  /// Refusal: anything else
  ///
  /// In en, this message translates to:
  /// **'This PDF could not be read'**
  String get pdfRefusedUnreadable;

  /// Why one picture was skipped: unsupported filter
  ///
  /// In en, this message translates to:
  /// **'Compressed in a way the app cannot read'**
  String get pdfSkipUnsupportedFilter;

  /// Why one picture was skipped: unsupported colour space
  ///
  /// In en, this message translates to:
  /// **'Uses a colour space the app cannot read'**
  String get pdfSkipUnsupportedColor;

  /// Why one picture was skipped: unsupported bit depth
  ///
  /// In en, this message translates to:
  /// **'Uses a colour depth the app cannot read'**
  String get pdfSkipUnsupportedDepth;

  /// Why one picture was skipped: past the caps
  ///
  /// In en, this message translates to:
  /// **'Too large to pull out'**
  String get pdfSkipTooLarge;

  /// Why one picture was skipped: the stream does not match its size
  ///
  /// In en, this message translates to:
  /// **'The picture data is incomplete'**
  String get pdfSkipMalformed;

  /// Why one picture was skipped: decompression failed
  ///
  /// In en, this message translates to:
  /// **'The picture could not be decompressed'**
  String get pdfSkipDecodeFailed;

  /// Heading of the appearance group on the settings screen
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// Heading of the language group on the settings screen
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Heading of the safety group on the settings screen
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get settingsSafety;

  /// Heading of the storage and privacy group on the settings screen
  ///
  /// In en, this message translates to:
  /// **'Storage and privacy'**
  String get settingsPrivacy;

  /// Heading of the developer-only group, shown on dev builds
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get settingsDeveloper;

  /// Language choice that follows the phone's own language
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// Name of the English language, written in English
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Name of the Malayalam language, written in Malayalam
  ///
  /// In en, this message translates to:
  /// **'മലയാളം'**
  String get languageMalayalam;

  /// Note under the language row saying the change is immediate
  ///
  /// In en, this message translates to:
  /// **'The app changes language at once. No restart is needed.'**
  String get languageSubtitle;

  /// Label of the grid column count setting
  ///
  /// In en, this message translates to:
  /// **'Grid density'**
  String get gridDensity;

  /// Note under the grid density setting
  ///
  /// In en, this message translates to:
  /// **'How many photos fit across the timeline. Pinching the grid changes it too.'**
  String get gridDensitySubtitle;

  /// Shows the chosen number of grid columns
  ///
  /// In en, this message translates to:
  /// **'{count} per row'**
  String gridDensityValue(int count);

  /// Label of the switch that shows the flashback memories row
  ///
  /// In en, this message translates to:
  /// **'Show memories'**
  String get showFlashbacks;

  /// Note under the show memories switch
  ///
  /// In en, this message translates to:
  /// **'A row of photos from this day in past years, at the top of the timeline.'**
  String get showFlashbacksSubtitle;

  /// Label of the switch that asks again before a destructive action
  ///
  /// In en, this message translates to:
  /// **'Ask before deleting'**
  String get confirmDestructive;

  /// Note under the confirm-before-deleting switch
  ///
  /// In en, this message translates to:
  /// **'Ask one more time before a delete or an overwrite. Some warnings always appear, whatever this is set to.'**
  String get confirmDestructiveSubtitle;

  /// Title of the privacy summary row on the settings screen
  ///
  /// In en, this message translates to:
  /// **'No remote server'**
  String get privacyNoServer;

  /// Body of the privacy summary row on the settings screen
  ///
  /// In en, this message translates to:
  /// **'Your photos, tags and notes stay on this phone. Nothing is uploaded, and there is no account. Internet access is used only by the transfer screen, to reach another phone on your own Wi-Fi.'**
  String get privacyNoServerBody;

  /// Row that opens the About screen
  ///
  /// In en, this message translates to:
  /// **'About this app'**
  String get aboutOpen;

  /// Note under the row that opens the About screen
  ///
  /// In en, this message translates to:
  /// **'Version, author and licence'**
  String get aboutOpenSubtitle;

  /// Shows the build number beside the version
  ///
  /// In en, this message translates to:
  /// **'Build {build}'**
  String aboutBuild(String build);

  /// Label for the build date row on the About screen
  ///
  /// In en, this message translates to:
  /// **'Build date'**
  String get aboutBuildDate;

  /// Message when no mail app can open an About screen email row
  ///
  /// In en, this message translates to:
  /// **'No app on this phone can open that address.'**
  String get aboutMailFailed;

  /// Label of the application name row on the About screen
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get aboutAppName;

  /// Note under the settings row that opens the vault settings
  ///
  /// In en, this message translates to:
  /// **'Lock timing, PIN and shredding'**
  String get vaultSettingsOpenSubtitle;

  /// Note under the settings row that opens the backup screen
  ///
  /// In en, this message translates to:
  /// **'Password-protected backup and restore'**
  String get backupOpenSubtitle;

  /// Title of the reset settings row and dialog
  ///
  /// In en, this message translates to:
  /// **'Reset settings'**
  String get settingsResetTitle;

  /// Body of the reset settings confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Put every setting on this screen back to how it started. Your photos, tags, albums and vault are not touched.'**
  String get settingsResetBody;

  /// Confirmation shown after the settings are reset
  ///
  /// In en, this message translates to:
  /// **'Settings put back to the defaults.'**
  String get settingsResetDone;

  /// Dismisses the settings reset dialog without changing anything
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settingsCancel;

  /// Confirms the settings reset in the dialog
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get settingsResetConfirm;

  /// Title of the help section on settings screen
  ///
  /// In en, this message translates to:
  /// **'Help & Guides'**
  String get settingsHelp;

  /// Subtitle for the help section on settings screen
  ///
  /// In en, this message translates to:
  /// **'Explore guides, pro-tips and offline guarantees for every feature'**
  String get settingsHelpSubtitle;

  /// Header for the about section in settings
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

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
  String get settingsDefaultApp;

  /// Subtitle explaining default app settings option
  ///
  /// In en, this message translates to:
  /// **'Set as default app for viewing photos and videos'**
  String get settingsDefaultAppSubtitle;

  /// Title of dialog explaining how to set default app
  ///
  /// In en, this message translates to:
  /// **'Set as Default Gallery'**
  String get defaultAppDialogTitle;

  /// Instructions explaining how to make the app default in Android
  ///
  /// In en, this message translates to:
  /// **'To make this your default gallery:\n\n1. Open any photo or video on your device (e.g. from Files, Downloads, or messages).\n2. Choose SreerajP Image Video Gallery and tap \'Always\'.\n\nYou can also configure defaults in Android Settings.'**
  String get defaultAppDialogBody;

  /// Button to open Android system default apps settings
  ///
  /// In en, this message translates to:
  /// **'Open Android Settings'**
  String get defaultAppOpenSettings;

  /// Title of the trash screen
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get trashTitle;

  /// Shown when the trash holds no items
  ///
  /// In en, this message translates to:
  /// **'Trash is empty'**
  String get trashEmpty;

  /// Explanation shown below the empty trash message
  ///
  /// In en, this message translates to:
  /// **'Items you delete are kept here until you empty the trash.'**
  String get trashEmptySubtitle;

  /// Button that permanently removes all trashed items
  ///
  /// In en, this message translates to:
  /// **'Empty trash'**
  String get trashEmptyAction;

  /// Title of the empty trash confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Empty trash?'**
  String get trashEmptyConfirmTitle;

  /// Body of the empty trash confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all trashed items from your device storage. This action cannot be undone.'**
  String get trashEmptyConfirmBody;

  /// Button to permanently delete an item from storage
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get trashDeletePermanentlyAction;

  /// Title of permanent deletion confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete permanently?'**
  String get trashDeletePermanentlyConfirmTitle;

  /// Body of permanent deletion confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'This item will be permanently deleted from your device storage. This action cannot be undone.'**
  String get trashDeletePermanentlyConfirmBody;

  /// Snackbar shown after an item is permanently deleted
  ///
  /// In en, this message translates to:
  /// **'Item permanently deleted'**
  String get trashDeletedPermanentlySnackbar;

  /// Button that restores items from the trash
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get trashRestoreAction;

  /// Button that restores every item from the trash
  ///
  /// In en, this message translates to:
  /// **'Restore all'**
  String get trashRestoreAllAction;

  /// Body of the restore all confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Every item in the trash will be moved back to your library.'**
  String get trashRestoreAllConfirmBody;

  /// Snackbar shown after items are restored from trash
  ///
  /// In en, this message translates to:
  /// **'Restored from trash'**
  String get trashRestoredSnackbar;

  /// Snackbar shown after the trash is emptied
  ///
  /// In en, this message translates to:
  /// **'Trash emptied'**
  String get trashEmptiedSnackbar;

  /// Shows how many items are in the trash
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item in trash} other{{count} items in trash}}'**
  String trashItemCount(int count);

  /// Subtitle for the appearance card on the settings hub
  ///
  /// In en, this message translates to:
  /// **'Theme, grid density, memories'**
  String get settingsAppearanceSubtitle;

  /// Subtitle for the language card on the settings hub
  ///
  /// In en, this message translates to:
  /// **'System, English, Malayalam'**
  String get settingsLanguageSubtitle;

  /// Subtitle for the safety card on the settings hub
  ///
  /// In en, this message translates to:
  /// **'Confirmation before destructive actions'**
  String get settingsSafetySubtitle;

  /// Subtitle for the default app card on the settings hub
  ///
  /// In en, this message translates to:
  /// **'Set as default gallery app'**
  String get settingsDefaultAppCardSubtitle;

  /// Subtitle for the privacy card on the settings hub
  ///
  /// In en, this message translates to:
  /// **'Vault, backup, network policy'**
  String get settingsPrivacySubtitle;

  /// Subtitle for the help card on the settings hub
  ///
  /// In en, this message translates to:
  /// **'Guides and privacy guarantees for every feature'**
  String get settingsHelpCardSubtitle;

  /// Subtitle for the about card on the settings hub
  ///
  /// In en, this message translates to:
  /// **'Version, author and licence'**
  String get settingsAboutSubtitle;

  /// Subtitle for the developer card on the settings hub
  ///
  /// In en, this message translates to:
  /// **'Media scanner tools'**
  String get settingsDeveloperSubtitle;

  /// Tooltip for the trash button in the media viewer
  ///
  /// In en, this message translates to:
  /// **'Move to trash'**
  String get viewerTrashTooltip;

  /// Title of the confirmation dialog before moving an item to trash
  ///
  /// In en, this message translates to:
  /// **'Move to trash?'**
  String get viewerTrashConfirmTitle;

  /// Body message of the confirmation dialog before moving an item to trash
  ///
  /// In en, this message translates to:
  /// **'This item will be moved to the trash. You can restore it anytime from the Trash album.'**
  String get viewerTrashConfirmBody;

  /// Snackbar message shown after moving an item to trash
  ///
  /// In en, this message translates to:
  /// **'Moved to trash'**
  String get viewerTrashSuccess;

  /// Undo action label in the snackbar after trashing an item
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get viewerTrashUndo;

  /// Title of the A/B photo comparison screen
  ///
  /// In en, this message translates to:
  /// **'A/B Comparison'**
  String get comparePhotosTitle;

  /// Label for split screen comparison mode
  ///
  /// In en, this message translates to:
  /// **'Split View'**
  String get compareModeSplit;

  /// Label for sliding curtain comparison mode
  ///
  /// In en, this message translates to:
  /// **'Sliding Curtain'**
  String get compareModeCurtain;

  /// Label for horizontal split orientation
  ///
  /// In en, this message translates to:
  /// **'Side by Side'**
  String get compareSplitHorizontal;

  /// Label for vertical split orientation
  ///
  /// In en, this message translates to:
  /// **'Top and Bottom'**
  String get compareSplitVertical;

  /// Status text when pan and zoom are synchronized
  ///
  /// In en, this message translates to:
  /// **'Pan & Zoom Locked'**
  String get compareSyncLocked;

  /// Status text when pan and zoom can be adjusted independently
  ///
  /// In en, this message translates to:
  /// **'Independent Pan & Zoom'**
  String get compareSyncUnlocked;

  /// Tooltip and label to swap Photo A and Photo B positions
  ///
  /// In en, this message translates to:
  /// **'Swap Photos'**
  String get compareSwap;

  /// Tooltip and button label to reset zoom back to 1.0x
  ///
  /// In en, this message translates to:
  /// **'Reset Zoom'**
  String get compareResetZoom;

  /// Tooltip and label for comparing photo technical metadata
  ///
  /// In en, this message translates to:
  /// **'Compare Details'**
  String get compareDetails;

  /// Label on photo change button
  ///
  /// In en, this message translates to:
  /// **'Choose Photo'**
  String get comparePickPhoto;

  /// Label identifying the first photo
  ///
  /// In en, this message translates to:
  /// **'Photo A'**
  String get comparePhotoA;

  /// Label identifying the second photo
  ///
  /// In en, this message translates to:
  /// **'Photo B'**
  String get comparePhotoB;

  /// Option in media viewer to compare with previous photo
  ///
  /// In en, this message translates to:
  /// **'Compare with previous photo'**
  String get compareWithPrevious;

  /// Option in media viewer to compare with next photo
  ///
  /// In en, this message translates to:
  /// **'Compare with next photo'**
  String get compareWithNext;

  /// Option in media viewer to choose any photo from gallery to compare
  ///
  /// In en, this message translates to:
  /// **'Pick photo from gallery'**
  String get compareChooseFromGallery;

  /// Action label to open comparison from selection
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get compareAction;

  /// Tooltip on the compare button
  ///
  /// In en, this message translates to:
  /// **'Compare photos side-by-side'**
  String get compareTooltip;

  /// Title of the photo picker sheet for comparison
  ///
  /// In en, this message translates to:
  /// **'Select a photo to compare with'**
  String get compareSelectSecondPhoto;

  /// Label for photo dimensions in comparison sheet
  ///
  /// In en, this message translates to:
  /// **'Dimensions'**
  String get compareDimensions;

  /// Label for file size in comparison sheet
  ///
  /// In en, this message translates to:
  /// **'File Size'**
  String get compareFileSize;

  /// Label for date taken in comparison sheet
  ///
  /// In en, this message translates to:
  /// **'Date Taken'**
  String get compareDateTaken;

  /// Label for camera make and model in comparison sheet
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get compareCamera;

  /// Label for exposure settings in comparison sheet
  ///
  /// In en, this message translates to:
  /// **'Exposure'**
  String get compareExposure;

  /// Label for ISO value in comparison sheet
  ///
  /// In en, this message translates to:
  /// **'ISO'**
  String get compareIso;

  /// Label for aperture f-number in comparison sheet
  ///
  /// In en, this message translates to:
  /// **'Aperture'**
  String get compareAperture;

  /// Label for shutter speed in comparison sheet
  ///
  /// In en, this message translates to:
  /// **'Shutter Speed'**
  String get compareShutterSpeed;

  /// Label for focal length in comparison sheet
  ///
  /// In en, this message translates to:
  /// **'Focal Length'**
  String get compareFocalLength;

  /// Message when no EXIF metadata exists for photo
  ///
  /// In en, this message translates to:
  /// **'No EXIF data available'**
  String get compareNoExif;

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
  String get foldersTitle;

  /// Shown when no device folders have been indexed
  ///
  /// In en, this message translates to:
  /// **'No folders found'**
  String get foldersEmpty;

  /// Hint shown below the empty folders message
  ///
  /// In en, this message translates to:
  /// **'Pull down to scan for photos and videos on your device.'**
  String get foldersEmptyBody;

  /// How many items a device folder contains
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Empty} =1{1 item} other{{count} items}}'**
  String folderItemCount(int count);

  /// Title of the media privacy and EXIF scrubber tool
  ///
  /// In en, this message translates to:
  /// **'Media Privacy & Scrubber'**
  String get privacyScrubberTitle;

  /// Subtitle explaining privacy scrubber capabilities
  ///
  /// In en, this message translates to:
  /// **'Strip sensitive EXIF metadata and fuzz GPS coordinates before sharing'**
  String get privacyScrubberSubtitle;

  /// Overflow menu item for privacy scrubber
  ///
  /// In en, this message translates to:
  /// **'Privacy & EXIF Scrubber'**
  String get privacyScrubberMenu;

  /// Title of the privacy card in details sheet
  ///
  /// In en, this message translates to:
  /// **'Media Privacy & EXIF'**
  String get privacyCardTitle;

  /// Body description in the details sheet privacy card
  ///
  /// In en, this message translates to:
  /// **'Protect your privacy by stripping GPS location, camera serial numbers, and device identifiers before sharing.'**
  String get privacyCardBody;

  /// Button to open privacy scrubber sheet
  ///
  /// In en, this message translates to:
  /// **'Open Privacy Controls'**
  String get privacyOpenScrubber;

  /// Tab label for EXIF stripper
  ///
  /// In en, this message translates to:
  /// **'EXIF Stripper'**
  String get privacyTabStripper;

  /// Tab label for GPS geofence shifter
  ///
  /// In en, this message translates to:
  /// **'GPS Geofence Shifter'**
  String get privacyTabGeofence;

  /// Primary action button to strip metadata and share
  ///
  /// In en, this message translates to:
  /// **'One-Tap Strip & Share'**
  String get privacyStripAndShareAction;

  /// Button to save stripped copy to gallery
  ///
  /// In en, this message translates to:
  /// **'Save Sanitized Copy to Gallery'**
  String get privacySaveSanitizedAction;

  /// Title of granular metadata options section
  ///
  /// In en, this message translates to:
  /// **'Selective Metadata Scrubbing'**
  String get privacyGranularTitle;

  /// Action to reset toggles to strip all metadata
  ///
  /// In en, this message translates to:
  /// **'Strip All'**
  String get privacyStripAll;

  /// Label indicating custom toggle selection
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get privacyCustom;

  /// Checkbox to strip location coordinates
  ///
  /// In en, this message translates to:
  /// **'Strip GPS Coordinates & Altitude'**
  String get privacyOptionGps;

  /// Checkbox to strip hardware serial numbers
  ///
  /// In en, this message translates to:
  /// **'Strip Camera & Lens Serial Numbers'**
  String get privacyOptionSerials;

  /// Checkbox to strip timestamps
  ///
  /// In en, this message translates to:
  /// **'Strip Capture & Digitization Dates'**
  String get privacyOptionTimestamps;

  /// Checkbox to strip author and software tags
  ///
  /// In en, this message translates to:
  /// **'Strip Author & Software Info'**
  String get privacyOptionAuthor;

  /// Error when image bytes cannot be read
  ///
  /// In en, this message translates to:
  /// **'Unable to read image data for privacy processing'**
  String get privacyErrorReadingFile;

  /// Title of share sheet for sanitized media
  ///
  /// In en, this message translates to:
  /// **'Share Sanitized Media'**
  String get privacyShareTitle;

  /// Error when share sheet launch fails
  ///
  /// In en, this message translates to:
  /// **'Sharing could not be initiated'**
  String get privacyShareFailed;

  /// General error during sanitization
  ///
  /// In en, this message translates to:
  /// **'An error occurred while sanitizing media'**
  String get privacyProcessError;

  /// Snackbar confirming sanitized copy saved
  ///
  /// In en, this message translates to:
  /// **'Sanitized copy saved to gallery'**
  String get privacySavedToGallery;

  /// Error when saving sanitized copy fails
  ///
  /// In en, this message translates to:
  /// **'Failed to save sanitized image'**
  String get privacySaveFailed;

  /// Message when media has no GPS tags
  ///
  /// In en, this message translates to:
  /// **'No embedded GPS location found in this photo'**
  String get privacyNoLocation;

  /// Label for geofence distance selector
  ///
  /// In en, this message translates to:
  /// **'Shift Distance Offset'**
  String get geofenceOffsetDistance;

  /// Tooltip for reroll button
  ///
  /// In en, this message translates to:
  /// **'Reroll random shift'**
  String get geofenceReroll;

  /// Chip for randomized 2-5 km offset
  ///
  /// In en, this message translates to:
  /// **'Random (2–5 km)'**
  String get geofenceRandomPreset;

  /// Summary of shift displacement
  ///
  /// In en, this message translates to:
  /// **'Shifted {summary}'**
  String geofenceShiftSummary(String summary);

  /// New fuzzed latitude and longitude coordinates
  ///
  /// In en, this message translates to:
  /// **'Shifted to {lat}, {lon}'**
  String geofenceFuzzedCoordinates(String lat, String lon);

  /// Explanation of how location fuzzing protects privacy
  ///
  /// In en, this message translates to:
  /// **'Adds an offset within 2–5 km to preserve general regional travel context while hiding exact residential street coordinates.'**
  String get geofenceExplanation;

  /// Share sheet title for fuzzed photo
  ///
  /// In en, this message translates to:
  /// **'Share Geofuzzed Photo'**
  String get geofenceShareTitle;

  /// Action button to fuzz location and share
  ///
  /// In en, this message translates to:
  /// **'Fuzz Location & Share'**
  String get geofenceShareAction;

  /// Action button to save fuzzed copy
  ///
  /// In en, this message translates to:
  /// **'Save Geofuzzed Copy to Gallery'**
  String get geofenceSaveAction;

  /// Snackbar confirming fuzzed copy saved
  ///
  /// In en, this message translates to:
  /// **'Geofuzzed copy saved to gallery'**
  String get geofenceSavedToGallery;

  /// Header when media has no GPS coordinates
  ///
  /// In en, this message translates to:
  /// **'No Location Found'**
  String get geofenceNoCoordinates;

  /// Explanation when photo has no GPS metadata
  ///
  /// In en, this message translates to:
  /// **'This media item does not have embedded GPS coordinates to shift.'**
  String get geofenceNoCoordinatesBody;

  /// Audit badge when sensitive EXIF tags are found
  ///
  /// In en, this message translates to:
  /// **'Sensitive Metadata Detected'**
  String get privacyAuditSensitiveDetected;

  /// Audit badge when no sensitive EXIF tags are found
  ///
  /// In en, this message translates to:
  /// **'No Sensitive Metadata Detected'**
  String get privacyAuditClean;

  /// Audit details list
  ///
  /// In en, this message translates to:
  /// **'Contains {gps} {camera}'**
  String privacyAuditSensitiveDetails(String gps, String camera);

  /// Label indicating GPS presence in audit
  ///
  /// In en, this message translates to:
  /// **'GPS Coordinates'**
  String get privacyAuditGps;

  /// Label indicating camera identifiers in audit
  ///
  /// In en, this message translates to:
  /// **'Device Identifiers'**
  String get privacyAuditCamera;

  /// Description for clean metadata audit
  ///
  /// In en, this message translates to:
  /// **'This file does not contain embedded location or camera serial identifiers.'**
  String get privacyAuditCleanDetails;

  /// Title of forensic inspector sheet
  ///
  /// In en, this message translates to:
  /// **'Forensic Lens & Sensor Inspector'**
  String get forensicInspectorTitle;

  /// Subtitle of forensic inspector
  ///
  /// In en, this message translates to:
  /// **'Deep technical optical and hardware forensic insights'**
  String get forensicInspectorSubtitle;

  /// Button to launch forensic inspector
  ///
  /// In en, this message translates to:
  /// **'Inspect Lens & Sensor Forensics'**
  String get forensicInspectorButton;

  /// Quick summary of forensic metrics
  ///
  /// In en, this message translates to:
  /// **'Sensor crop factor, 35mm equivalent, shutter actuation, exposure bias'**
  String get forensicInspectorQuickHint;

  /// Message when no forensic EXIF tags are present
  ///
  /// In en, this message translates to:
  /// **'No forensic lens or sensor metadata found in this item.'**
  String get forensicNoData;

  /// Card header for sensor and optics
  ///
  /// In en, this message translates to:
  /// **'Sensor & Optical Characteristics'**
  String get forensicSectionSensorOptics;

  /// Card header for shutter and color
  ///
  /// In en, this message translates to:
  /// **'Mechanical Actuations & Color Space'**
  String get forensicSectionMechanicsColor;

  /// Card header for serials and hardware
  ///
  /// In en, this message translates to:
  /// **'Hardware & Lens Serial Identity'**
  String get forensicSectionHardwareIdentity;

  /// Label for sensor format classification
  ///
  /// In en, this message translates to:
  /// **'Sensor Format'**
  String get forensicSensorFormat;

  /// Label for sensor crop factor
  ///
  /// In en, this message translates to:
  /// **'Crop Factor'**
  String get forensicCropFactor;

  /// Label for 35mm equivalent focal length
  ///
  /// In en, this message translates to:
  /// **'35mm Equivalent'**
  String get forensicFocal35mm;

  /// Label for lens physical focal length
  ///
  /// In en, this message translates to:
  /// **'Physical Focal Length'**
  String get forensicPhysicalFocalLength;

  /// Label for calculated hyperfocal distance
  ///
  /// In en, this message translates to:
  /// **'Hyperfocal Distance'**
  String get forensicHyperfocalDistance;

  /// Label for exposure compensation EV
  ///
  /// In en, this message translates to:
  /// **'Exposure Bias (EV)'**
  String get forensicExposureBias;

  /// Label for shutter actuation count
  ///
  /// In en, this message translates to:
  /// **'Shutter Releases'**
  String get forensicShutterActuations;

  /// Notice when shutter count is absent
  ///
  /// In en, this message translates to:
  /// **'Electronic shutter / Not reported'**
  String get forensicShutterNotReported;

  /// Label for color space profile
  ///
  /// In en, this message translates to:
  /// **'Color Space / Profile'**
  String get forensicColorProfile;

  /// Label for exposure program
  ///
  /// In en, this message translates to:
  /// **'Exposure Program'**
  String get forensicExposureProgram;

  /// Label for metering mode
  ///
  /// In en, this message translates to:
  /// **'Metering Mode'**
  String get forensicMeteringMode;

  /// Label for sensor sensing method
  ///
  /// In en, this message translates to:
  /// **'Sensing Method'**
  String get forensicSensingMethod;

  /// Label for scene capture type
  ///
  /// In en, this message translates to:
  /// **'Scene Capture Type'**
  String get forensicSceneCaptureType;

  /// Label for flash details
  ///
  /// In en, this message translates to:
  /// **'Flash & Strobe Status'**
  String get forensicFlashStatus;

  /// Label for camera body serial number
  ///
  /// In en, this message translates to:
  /// **'Camera Serial Number'**
  String get forensicCameraSerial;

  /// Label for lens model
  ///
  /// In en, this message translates to:
  /// **'Lens Model'**
  String get forensicLensModel;

  /// Label for lens specification
  ///
  /// In en, this message translates to:
  /// **'Lens Specification'**
  String get forensicLensSpecification;

  /// Label for lens serial number
  ///
  /// In en, this message translates to:
  /// **'Lens Serial Number'**
  String get forensicLensSerial;

  /// Notice when hardware serial is not embedded
  ///
  /// In en, this message translates to:
  /// **'Not embedded in headers'**
  String get forensicSerialNotEmbedded;
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
      <String>['en', 'ml'].contains(locale.languageCode);

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
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
