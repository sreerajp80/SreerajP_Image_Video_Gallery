import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/album.dart';
import 'package:in_sreerajp_imgvidgal/models/album_summary.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/album_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/screens/home/folders_tab.dart';
import 'package:in_sreerajp_imgvidgal/widgets/home/home_overflow_menu.dart';
import 'package:in_sreerajp_imgvidgal/core/l10n/sanskrit_fallback_delegates.dart';
import '../../helpers/locale_checks.dart';

MediaItem _sampleItem(String id) => MediaItem(
  id: id,
  path: '/storage/emulated/0/DCIM/Camera/$id.jpg',
  displayName: '$id.jpg',
  mediaType: MediaType.image,
  mimeType: 'image/jpeg',
  size: 1024,
  dateAdded: DateTime(2026),
  dateModified: DateTime(2026),
);

void main() {
  testWidgets('FoldersTab renders folder grid properly without layout errors', (
    tester,
  ) async {
    final item = _sampleItem('img1');
    final folders = <AlbumSummary>[
      AlbumSummary(
        id: '/storage/emulated/0/DCIM/Camera',
        name: 'Camera',
        albumType: AlbumType.physicalFolder,
        folderPath: '/storage/emulated/0/DCIM/Camera',
        itemCount: 42,
        coverItem: item,
      ),
      const AlbumSummary(
        id: '/storage/emulated/0/Pictures/Screenshots',
        name: 'Screenshots',
        albumType: AlbumType.physicalFolder,
        folderPath: '/storage/emulated/0/Pictures/Screenshots',
        itemCount: 7,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deviceFolderAlbumsProvider.overrideWith((ref) async => folders),
          thumbnailProvider(item).overrideWith((ref) => Uint8List(0)),
        ],
        child: const MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FoldersTab(),
        ),
      ),
    );

    // Let the FutureProvider complete and re-render.
    await tester.pumpAndSettle();

    // Verify folders are drawn with correct text and no exception was thrown.
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Screenshots'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
    // The ⋮ menu, the way to Settings, is on this tab too.
    expect(find.byType(HomeOverflowMenu), findsOneWidget);
  });

  testWidgets('FoldersTab renders empty state when folder list is empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deviceFolderAlbumsProvider.overrideWith(
            (ref) async => const <AlbumSummary>[],
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FoldersTab(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.folder_off_outlined), findsOneWidget);
    expect(find.byType(GridView), findsNothing);
  });

  group('every declared language, with folders', () {
    for (final locale in declaredLocales) {
      testWidgets(
        'FoldersTab with folders renders cleanly in ${locale.languageCode}',
        (tester) async {
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                deviceFolderAlbumsProvider.overrideWith(
                  (ref) async => <AlbumSummary>[
                    const AlbumSummary(
                      id: '/storage/emulated/0/DCIM/Munnar Trip',
                      // Not a word the app translates, so it is not leaked English.
                      name: 'Munnar Trip',
                      albumType: AlbumType.physicalFolder,
                      folderPath: '/storage/emulated/0/DCIM/Munnar Trip',
                      itemCount: 3,
                    ),
                  ],
                ),
              ],
              child: MaterialApp(
                locale: locale,
                localizationsDelegates: appLocalizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: const FoldersTab(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expectLocaleClean(tester, locale);
        },
      );
    }
  });

  group('every declared language, empty', () {
    for (final locale in declaredLocales) {
      testWidgets(
        'FoldersTab empty renders cleanly in ${locale.languageCode}',
        (tester) async {
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                deviceFolderAlbumsProvider.overrideWith(
                  (ref) async => <AlbumSummary>[],
                ),
              ],
              child: MaterialApp(
                locale: locale,
                localizationsDelegates: appLocalizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: const FoldersTab(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expectLocaleClean(tester, locale);
        },
      );
    }
  });
}
