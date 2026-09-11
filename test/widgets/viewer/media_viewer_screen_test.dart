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

  Widget createMultiViewerWidget({required List<MediaItem> items}) {
    return ProviderScope(
      overrides: [
        timelineItemsProvider.overrideWith((ref) => items),
        for (final item in items) ...[
          mediaItemProvider(item.id).overrideWith((ref) => item),
          externalMediaItemProvider(item.id).overrideWith((ref) => null),
          fullImageBytesProvider(item).overrideWith((ref) => Uint8List(0)),
          thumbnailProvider(item).overrideWith((ref) => Uint8List(0)),
        ],
        viewerPageIndexProvider.overrideWith((ref) => 0),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaViewerScreen(mediaId: items.first.id),
      ),
    );
  }

  Widget createViewerWidget({required MediaItem item}) {
    return createMultiViewerWidget(items: [item]);
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

  testWidgets(
    'Rotating an image updates RotatedBox and allows zoom in and out',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createViewerWidget(item: testImage));
      await tester.pumpAndSettle();

      // Starts unrotated
      expect(find.byType(RotatedBox), findsOneWidget);
      var rotatedBox = tester.widget<RotatedBox>(find.byType(RotatedBox));
      expect(rotatedBox.quarterTurns, equals(0));

      // Rotate clockwise (right)
      await tester.tap(find.byIcon(Icons.rotate_right));
      await tester.pumpAndSettle();

      rotatedBox = tester.widget<RotatedBox>(find.byType(RotatedBox));
      expect(rotatedBox.quarterTurns, equals(1));

      // Double tap to zoom in on the rotated image
      final ivFinder = find.byType(InteractiveViewer);
      final center = tester.getCenter(ivFinder);
      await tester.tapAt(center);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(center);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      var iv = tester.widget<InteractiveViewer>(ivFinder);
      expect(
        iv.transformationController?.value.getMaxScaleOnAxis(),
        closeTo(2.5, 0.01),
      );

      // Rotating again resets scale to 1.0 cleanly
      await tester.tap(find.byIcon(Icons.rotate_right));
      await tester.pumpAndSettle();

      rotatedBox = tester.widget<RotatedBox>(find.byType(RotatedBox));
      expect(rotatedBox.quarterTurns, equals(2));

      iv = tester.widget<InteractiveViewer>(ivFinder);
      expect(
        iv.transformationController?.value.getMaxScaleOnAxis(),
        closeTo(1.0, 0.01),
      );

      // Double tap to zoom in again
      await tester.tapAt(center);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(center);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      iv = tester.widget<InteractiveViewer>(ivFinder);
      expect(
        iv.transformationController?.value.getMaxScaleOnAxis(),
        closeTo(2.5, 0.01),
      );

      // Double tap to zoom out back to fitted view
      await tester.tapAt(center);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(center);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      iv = tester.widget<InteractiveViewer>(ivFinder);
      expect(
        iv.transformationController?.value.getMaxScaleOnAxis(),
        closeTo(1.0, 0.01),
      );
    },
  );

  testWidgets(
    'Double finger horizontal swipe does not page, only single finger horizontal swipe does',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final secondImage = testImage.copyWith(
        id: 'test_img_2',
        displayName: 'Second_Photo.jpg',
      );

      await tester.pumpWidget(
        createMultiViewerWidget(items: [testImage, secondImage]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Beautiful_Sunset.jpg'), findsOneWidget);

      final center = tester.getCenter(find.byType(InteractiveViewer));

      // Two fingers swipe horizontally to the left
      final touch1 = await tester.startGesture(center.translate(-50, 0));
      final touch2 = await tester.startGesture(center.translate(50, 0));
      await tester.pump();

      for (int i = 0; i < 8; i++) {
        await touch1.moveBy(const Offset(-40, 0));
        await touch2.moveBy(const Offset(-40, 0));
        await tester.pump(const Duration(milliseconds: 20));
      }

      await touch1.up();
      await touch2.up();
      await tester.pumpAndSettle();

      // Must remain on first image!
      expect(find.text('Beautiful_Sunset.jpg'), findsOneWidget);
      expect(find.text('Second_Photo.jpg'), findsNothing);

      // Now single finger fling to the left
      await tester.fling(
        find.byType(InteractiveViewer),
        const Offset(-500, 0),
        1000,
      );
      await tester.pumpAndSettle();

      // Now it navigated to second image!
      expect(find.text('Second_Photo.jpg'), findsOneWidget);
    },
  );
}
