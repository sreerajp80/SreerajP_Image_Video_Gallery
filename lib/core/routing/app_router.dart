import 'package:go_router/go_router.dart';
import 'package:in_sreerajp_imgvidgal/screens/albums/album_media_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/albums/album_reorder_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/albums/albums_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/backup/backup_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/albums/smart_album_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/cleaner/duplicate_cleaner_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/cleaner/duplicate_compare_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/compare/photo_compare_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/convert/format_converter_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/convert/pdf_export_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/editor/image_editor_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/help/help_topic_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/settings/about_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/settings/appearance_settings_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/settings/default_app_settings_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/settings/developer_settings_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/settings/help_settings_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/settings/language_settings_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/settings/privacy_settings_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/settings/safety_settings_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/settings/settings_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/notes/media_notes_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/ocr/extracted_text_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/pdf/pdf_image_extract_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/scan/image_scan_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/search/search_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/tags/tags_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/viewer/media_viewer_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/timeline/timeline_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/vault/vault_gate_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/vault/vault_settings_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/vault/vault_viewer_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/sync/sync_home_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/sync/sync_receive_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/sync/sync_send_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/trash/trash_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/video/video_tools_screen.dart';

/// Route path of the main chronological timeline.
const String kRouteTimeline = '/';

/// Route path of the settings screen.
const String kRouteSettings = '/settings';

/// Route path of the config-driven About screen.
const String kRouteAbout = '$kRouteSettings/about';

/// Route path of the appearance settings screen.
const String kRouteSettingsAppearance = '$kRouteSettings/appearance';

/// Route path of the language settings screen.
const String kRouteSettingsLanguage = '$kRouteSettings/language';

/// Route path of the safety settings screen.
const String kRouteSettingsSafety = '$kRouteSettings/safety';

/// Route path of the default app settings screen.
const String kRouteSettingsDefaultApp = '$kRouteSettings/default-app';

/// Route path of the privacy settings screen.
const String kRouteSettingsPrivacy = '$kRouteSettings/privacy';

/// Route path of the help topics list screen.
const String kRouteSettingsHelp = '$kRouteSettings/help';

/// Route path of the developer diagnostics screen.
const String kRouteSettingsDeveloper = '$kRouteSettings/developer';

/// Route path of a help topic page.
const String kRouteHelpTopic = '$kRouteSettings/help/:topicId';

/// Builds the route path for one help topic.
String helpTopicPath(String topicId) => '$kRouteSettings/help/$topicId';

/// Route path of the fullscreen viewer, which takes a media id.
const String kRouteMediaViewer = '/media-viewer';

/// Builds the viewer path for one media item.
String mediaViewerPath(String mediaId) => '$kRouteMediaViewer/$mediaId';

/// Route path of the A/B photo comparison screen.
const String kRoutePhotoCompare = '/compare';

/// Builds the comparison path for two media items.
String photoComparePath(String firstId, String secondId) =>
    '$kRoutePhotoCompare?firstId=${Uri.encodeQueryComponent(firstId)}&secondId=${Uri.encodeQueryComponent(secondId)}';

/// Route path of the PDF export screen.
const String kRoutePdfExport = '/pdf-export';

/// Route path of the search screen.
const String kRouteSearch = '/search';

/// Route path of the tag management screen.
const String kRouteTags = '/tags';

/// Route path of the albums screen.
const String kRouteAlbums = '/albums';

/// Builds the path of one user-made album.
String albumPath(String albumId) =>
    '$kRouteAlbums/${Uri.encodeComponent(albumId)}';

/// Builds the path of one album's reorder screen.
String albumReorderPath(String albumId) => '${albumPath(albumId)}/reorder';

/// Builds the path of one smart album, from its route key.
String smartAlbumPath(String key) =>
    '$kRouteAlbums/auto/${Uri.encodeComponent(key)}';

/// Builds the path of one device folder.
///
/// The directory is encoded because it holds separators of its own, which
/// would otherwise read as extra route segments.
String folderAlbumPath(String directory) =>
    '$kRouteAlbums/folder/${Uri.encodeComponent(directory)}';

/// Route path of the duplicate cleaner.
const String kRouteCleaner = '/cleaner';

/// Route path of the backup and restore screen.
const String kRouteBackup = '/backup';

/// Route path of the trash screen.
const String kRouteTrash = '/trash';

/// Route path of the local transfer screen.
///
/// The socket listener lives only while a screen under this path is on
/// screen. Nothing outside it may open one.
const String kRouteSync = '/sync';

/// Route path of the receiving half of a transfer, which shows the code.
const String kRouteSyncReceive = '$kRouteSync/receive';

/// Route path of the sending half, which reads the other phone's code.
const String kRouteSyncSend = '$kRouteSync/send';

/// Route path of the private vault.
///
/// This is the gate, not the contents. Nothing inside the vault is built while
/// it is locked, so a locked vault holds no decrypted bytes anywhere in the
/// widget tree.
const String kRouteVault = '/vault';

/// Route path of the vault settings.
const String kRouteVaultSettings = '$kRouteVault/settings';

/// Builds the in-vault viewer path for one vault item.
String vaultViewerPath(String itemId) =>
    '$kRouteVault/viewer/${Uri.encodeComponent(itemId)}';

/// Query parameter carrying a tag id into the search screen.
const String kSearchTagQueryParam = 'tag';

/// Builds the search path pre-filtered to one tag.
String searchPathForTag(String tagId) =>
    '$kRouteSearch?$kSearchTagQueryParam=$tagId';

/// Builds the comparison path for one duplicate group.
String duplicateComparePath(String groupId) =>
    '$kRouteCleaner/compare/${Uri.encodeComponent(groupId)}';

/// Builds the image editor path for one media item.
String imageEditorPath(String mediaId) => '$kRouteMediaViewer/$mediaId/editor';

/// Builds the format converter path for one media item.
String formatConverterPath(String mediaId) =>
    '$kRouteMediaViewer/$mediaId/convert';

/// Builds the video tools path for one media item.
String videoToolsPath(String mediaId) =>
    '$kRouteMediaViewer/$mediaId/video-tools';

/// Builds the in-image code scanner path for one media item.
String imageScanPath(String mediaId) => '$kRouteMediaViewer/$mediaId/scan';

/// Builds the extracted text path for one media item.
String extractedTextPath(String mediaId) => '$kRouteMediaViewer/$mediaId/text';

/// Builds the note editor path for one media item.
String mediaNotesPath(String mediaId) => '$kRouteMediaViewer/$mediaId/notes';

/// Route path of the PDF image extraction tool.
const String kRoutePdfImages = '/pdf-images';

/// Declarative navigation for the app.
///
/// Phases 4 to 13 wire the timeline, settings, About, viewer, image editor,
/// format
/// converter, video tools, PDF export, search, tags, the duplicate cleaner,
/// the albums, the private vault, backup and restore, the local transfer, and
/// the in-image scanner, text reader, notes and PDF image tool.
/// That completes the route hierarchy in `docs/architecture.md`.
final GoRouter appRouter = GoRouter(
  initialLocation: kRouteTimeline,
  routes: <RouteBase>[
    GoRoute(
      path: kRouteTimeline,
      builder: (context, state) => const TimelineScreen(),
      routes: <RouteBase>[
        GoRoute(
          path: 'settings',
          builder: (context, state) => const SettingsScreen(),
          routes: <RouteBase>[
            GoRoute(
              path: 'about',
              builder: (context, state) => const AboutScreen(),
            ),
            GoRoute(
              path: 'appearance',
              builder: (context, state) => const AppearanceSettingsScreen(),
            ),
            GoRoute(
              path: 'language',
              builder: (context, state) => const LanguageSettingsScreen(),
            ),
            GoRoute(
              path: 'safety',
              builder: (context, state) => const SafetySettingsScreen(),
            ),
            GoRoute(
              path: 'default-app',
              builder: (context, state) => const DefaultAppSettingsScreen(),
            ),
            GoRoute(
              path: 'privacy',
              builder: (context, state) => const PrivacySettingsScreen(),
            ),
            GoRoute(
              path: 'help',
              builder: (context, state) => const HelpSettingsScreen(),
              routes: <RouteBase>[
                GoRoute(
                  path: ':topicId',
                  builder: (context, state) => HelpTopicScreen(
                    topicId: state.pathParameters['topicId'] ?? '',
                  ),
                ),
              ],
            ),
            GoRoute(
              path: 'developer',
              builder: (context, state) => const DeveloperSettingsScreen(),
            ),
          ],
        ),
        GoRoute(
          path: 'media-viewer/:id',
          builder: (context, state) =>
              MediaViewerScreen(mediaId: state.pathParameters['id'] ?? ''),
          routes: <RouteBase>[
            GoRoute(
              path: 'editor',
              builder: (context, state) =>
                  ImageEditorScreen(mediaId: state.pathParameters['id'] ?? ''),
            ),
            GoRoute(
              path: 'convert',
              builder: (context, state) => FormatConverterScreen(
                mediaId: state.pathParameters['id'] ?? '',
              ),
            ),
            GoRoute(
              path: 'video-tools',
              builder: (context, state) =>
                  VideoToolsScreen(mediaId: state.pathParameters['id'] ?? ''),
            ),
            GoRoute(
              path: 'scan',
              builder: (context, state) =>
                  ImageScanScreen(mediaId: state.pathParameters['id'] ?? ''),
            ),
            GoRoute(
              path: 'text',
              builder: (context, state) => ExtractedTextScreen(
                mediaId: state.pathParameters['id'] ?? '',
              ),
            ),
            GoRoute(
              path: 'notes',
              builder: (context, state) =>
                  MediaNotesScreen(mediaId: state.pathParameters['id'] ?? ''),
            ),
          ],
        ),
        GoRoute(
          path: 'pdf-export',
          builder: (context, state) => const PdfExportScreen(),
        ),
        GoRoute(
          path: 'pdf-images',
          builder: (context, state) => const PdfImageExtractScreen(),
        ),
        GoRoute(
          path: 'search',
          builder: (context, state) => SearchScreen(
            initialTagId: state.uri.queryParameters[kSearchTagQueryParam],
          ),
        ),
        GoRoute(path: 'tags', builder: (context, state) => const TagsScreen()),
        GoRoute(
          path: 'albums',
          builder: (context, state) => const AlbumsScreen(),
          routes: <RouteBase>[
            // The two fixed sub-paths come before ':id' so a smart album or a
            // folder is never read as an album id.
            GoRoute(
              path: 'auto/:type',
              builder: (context, state) {
                final type = state.pathParameters['type'] ?? '';
                if (type == 'trash') {
                  return const TrashScreen();
                }
                return SmartAlbumScreen(albumKey: type);
              },
            ),
            GoRoute(
              path: 'folder/:path',
              builder: (context, state) => FolderAlbumScreen(
                directory: state.pathParameters['path'] ?? '',
              ),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) =>
                  AlbumMediaScreen(albumId: state.pathParameters['id'] ?? ''),
              routes: <RouteBase>[
                GoRoute(
                  path: 'reorder',
                  builder: (context, state) => AlbumReorderScreen(
                    albumId: state.pathParameters['id'] ?? '',
                  ),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: 'vault',
          builder: (context, state) => const VaultGateScreen(),
          routes: <RouteBase>[
            // 'settings' comes before the viewer's ':id' would ever be read,
            // and the two do not overlap: the viewer sits under 'viewer/'.
            GoRoute(
              path: 'settings',
              builder: (context, state) => const VaultSettingsScreen(),
            ),
            GoRoute(
              path: 'viewer/:id',
              builder: (context, state) =>
                  VaultViewerScreen(itemId: state.pathParameters['id'] ?? ''),
            ),
          ],
        ),
        GoRoute(
          path: 'backup',
          builder: (context, state) => const BackupScreen(),
        ),
        GoRoute(
          path: 'sync',
          builder: (context, state) => const SyncHomeScreen(),
          routes: <RouteBase>[
            GoRoute(
              path: 'receive',
              builder: (context, state) => const SyncReceiveScreen(),
            ),
            GoRoute(
              path: 'send',
              builder: (context, state) => const SyncSendScreen(),
            ),
          ],
        ),
        GoRoute(
          path: 'cleaner',
          builder: (context, state) => const DuplicateCleanerScreen(),
          routes: <RouteBase>[
            GoRoute(
              path: 'compare/:groupId',
              builder: (context, state) => DuplicateCompareScreen(
                groupId: state.pathParameters['groupId'] ?? '',
              ),
            ),
          ],
        ),
        GoRoute(
          path: 'trash',
          builder: (context, state) => const TrashScreen(),
        ),
        GoRoute(
          path: 'compare',
          builder: (context, state) => PhotoCompareScreen(
            firstMediaId: state.uri.queryParameters['firstId'] ?? '',
            secondMediaId: state.uri.queryParameters['secondId'] ?? '',
          ),
        ),
      ],
    ),
  ],
);
