import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/album.dart';
import 'package:in_sreerajp_imgvidgal/models/album_summary.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/album_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/screens/home/folders_tab.dart';

MediaItem _sampleItem(String id) => MediaItem(
  id: id,
  path: '/storage/emulated/0/DCIM/Camera/$id.jpg',
  displayName: '$id.jpg',
  mediaType: MediaType.image,
  mimeType: 'image/jpeg',
  size: 1024,
  dateAdded: DateTime(2026, 1, 1),
  dateModified: DateTime(2026, 1, 1),
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
        coverItem: null,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deviceFolderAlbumsProvider.overrideWith((ref) async => folders),
          thumbnailProvider(item).overrideWith((ref) => Uint8List(0)),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FoldersTab(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.folder_off_outlined), findsOneWidget);
    expect(find.byType(GridView), findsNothing);
  });
}
