import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_intent_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/timeline_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/viewer_providers.dart';
import 'package:in_sreerajp_imgvidgal/screens/viewer/media_viewer_screen.dart';

void main() {
  final testImage = MediaItem(
    id: 'test_img_1',
    path: '/storage/emulated/0/DCIM/test.jpg',
    displayName: 'Beautiful_Sunset.jpg',
    mediaType: MediaType.image,
    mimeType: 'image/jpeg',
    size: 2048000,
    dateAdded: DateTime(2026, 9, 6),
    dateModified: DateTime(2026, 9, 6),
  );

  Widget createViewerWidget({required MediaItem item}) {
    return ProviderScope(
      overrides: [
        timelineItemsProvider.overrideWith((ref) => [item]),
        mediaItemProvider(item.id).overrideWith((ref) => item),
        externalMediaItemProvider(item.id).overrideWith((ref) => null),
        fullImageBytesProvider(item).overrideWith((ref) => Uint8List(0)),
        thumbnailProvider(item).overrideWith((ref) => Uint8List(0)),
        viewerPageIndexProvider.overrideWith((ref) => 0),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaViewerScreen(mediaId: item.id),
      ),
    );
  }

  testWidgets(
    'MediaViewerScreen renders high-contrast top bar and bottom bar for images',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createViewerWidget(item: testImage));
      await tester.pumpAndSettle();

      // Top bar elements
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.text('Beautiful_Sunset.jpg'), findsOneWidget);
      expect(find.byIcon(Icons.star_border), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);

      // Bottom bar elements for images
      expect(find.byIcon(Icons.tune), findsOneWidget);
      expect(find.byIcon(Icons.rotate_left), findsOneWidget);
      expect(find.byIcon(Icons.rotate_right), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    },
  );

  testWidgets(
    'MediaViewerScreen single tap toggles chrome and does not auto-hide on images',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createViewerWidget(item: testImage));
      await tester.pumpAndSettle();

      // Controls start visible
      expect(find.byIcon(Icons.tune), findsOneWidget);

      // Wait 5 seconds (exceeding 3.5s auto-hide timer) - chrome should still be visible on images
      await tester.pump(const Duration(seconds: 5));
      expect(find.byIcon(Icons.tune), findsOneWidget);

      // Tap to hide chrome
      await tester.tap(find.byType(InteractiveViewer));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // AnimatedPositioned should move bottom bar down (-100)
      final bottomPos = tester.widget<AnimatedPositioned>(
        find.ancestor(
          of: find.byIcon(Icons.tune),
          matching: find.byType(AnimatedPositioned),
        ),
      );
      expect(bottomPos.bottom, equals(-100));

      // Tap again to show chrome
      await tester.tap(find.byType(InteractiveViewer));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      final bottomPosShown = tester.widget<AnimatedPositioned>(
        find.ancestor(
          of: find.byIcon(Icons.tune),
          matching: find.byType(AnimatedPositioned),
        ),
      );
      expect(bottomPosShown.bottom, equals(0));
    },
  );
}
