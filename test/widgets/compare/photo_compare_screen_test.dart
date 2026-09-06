import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/viewer_providers.dart';
import 'package:in_sreerajp_imgvidgal/screens/compare/photo_compare_screen.dart';
import 'package:in_sreerajp_imgvidgal/widgets/compare/compare_metadata_sheet.dart';
import 'package:in_sreerajp_imgvidgal/widgets/compare/curtain_comparison_view.dart';
import 'package:in_sreerajp_imgvidgal/widgets/compare/split_comparison_view.dart';

void main() {
  final photoA = MediaItem(
    id: 'photo_a',
    path: '/storage/emulated/0/DCIM/photo_a.jpg',
    displayName: 'Burst_001.jpg',
    mediaType: MediaType.image,
    mimeType: 'image/jpeg',
    size: 2048000,
    width: 4000,
    height: 3000,
    dateAdded: DateTime(2026, 9, 6),
    dateModified: DateTime(2026, 9, 6),
  );

  final photoB = MediaItem(
    id: 'photo_b',
    path: '/storage/emulated/0/DCIM/photo_b.jpg',
    displayName: 'Burst_002.jpg',
    mediaType: MediaType.image,
    mimeType: 'image/jpeg',
    size: 2200000,
    width: 4000,
    height: 3000,
    dateAdded: DateTime(2026, 9, 6),
    dateModified: DateTime(2026, 9, 6),
  );

  Widget createCompareWidget({
    required MediaItem itemA,
    required MediaItem itemB,
  }) {
    return ProviderScope(
      overrides: [
        mediaItemProvider(itemA.id).overrideWith((ref) => itemA),
        mediaItemProvider(itemB.id).overrideWith((ref) => itemB),
        fullImageBytesProvider(itemA).overrideWith((ref) => Uint8List(0)),
        fullImageBytesProvider(itemB).overrideWith((ref) => Uint8List(0)),
        thumbnailProvider(itemA).overrideWith((ref) => Uint8List(0)),
        thumbnailProvider(itemB).overrideWith((ref) => Uint8List(0)),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PhotoCompareScreen(
          firstMediaId: itemA.id,
          secondMediaId: itemB.id,
        ),
      ),
    );
  }

  testWidgets('PhotoCompareScreen renders curtain mode by default', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(createCompareWidget(itemA: photoA, itemB: photoB));
    await tester.pumpAndSettle();

    // Verifies title and header elements
    expect(find.byType(CurtainComparisonView), findsOneWidget);
    expect(find.byType(SplitComparisonView), findsNothing);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.byIcon(Icons.splitscreen), findsOneWidget);
    expect(find.byIcon(Icons.swap_horiz), findsAtLeastNWidgets(1));
    expect(find.byIcon(Icons.info_outline), findsOneWidget);

    // Verifies photo titles displayed
    expect(find.textContaining('Burst_001.jpg'), findsAtLeastNWidgets(1));
    expect(find.textContaining('Burst_002.jpg'), findsAtLeastNWidgets(1));
  });

  testWidgets('PhotoCompareScreen switches to split view and toggles sync', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(createCompareWidget(itemA: photoA, itemB: photoB));
    await tester.pumpAndSettle();

    // Tap switch mode button
    await tester.tap(find.byIcon(Icons.splitscreen));
    await tester.pumpAndSettle();

    // Now SplitComparisonView is shown
    expect(find.byType(SplitComparisonView), findsOneWidget);
    expect(find.byType(CurtainComparisonView), findsNothing);

    // Sync lock button is visible in split mode
    expect(find.byIcon(Icons.lock), findsOneWidget);

    // Tap sync lock button to unlock
    await tester.tap(find.byIcon(Icons.lock));
    await tester.pumpAndSettle();

    // Now unlocked
    expect(find.byIcon(Icons.lock_open), findsOneWidget);
  });

  testWidgets('PhotoCompareScreen swap button exchanges Photo A and Photo B', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(createCompareWidget(itemA: photoA, itemB: photoB));
    await tester.pumpAndSettle();

    // Check initial badge texts
    expect(find.text('A: Burst_001.jpg'), findsOneWidget);
    expect(find.text('B: Burst_002.jpg'), findsOneWidget);

    // Tap the swap button in top bar
    await tester.tap(find.byIcon(Icons.swap_horiz).first);
    await tester.pumpAndSettle();

    // Badges swapped
    expect(find.text('A: Burst_002.jpg'), findsOneWidget);
    expect(find.text('B: Burst_001.jpg'), findsOneWidget);
  });

  testWidgets('PhotoCompareScreen info button opens CompareMetadataSheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(createCompareWidget(itemA: photoA, itemB: photoB));
    await tester.pumpAndSettle();

    // Tap info button
    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();

    // Check CompareMetadataSheet opened
    expect(find.byType(CompareMetadataSheet), findsOneWidget);
  });
}
