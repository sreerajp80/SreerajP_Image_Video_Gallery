import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_intent_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/timeline_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/viewer_providers.dart';
import 'package:in_sreerajp_imgvidgal/screens/viewer/media_viewer_screen.dart';
import 'package:in_sreerajp_imgvidgal/core/l10n/sanskrit_fallback_delegates.dart';
import '../../helpers/locale_checks.dart';

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

  Widget createMultiViewerWidget({
    required List<MediaItem> items,
    Locale locale = const Locale('en'),
    String? openId,
    bool openFromLauncher = false,
  }) {
    final viewer = MediaViewerScreen(mediaId: openId ?? items.first.id);
    return ProviderScope(
      overrides: [
        // The first load is ready at once, as when the viewer opens from a
        // timeline that is already on screen. A star tap bumps the reload
        // counter, and the list then takes a moment to come back, like the
        // real database query.
        timelineItemsProvider.overrideWith((ref) {
          if (ref.watch(_reloadCountProvider) == 0) {
            return Stream.value(items);
          }
          return Stream.fromFuture(
            Future<void>.delayed(
              const Duration(milliseconds: 50),
            ).then((_) => items),
          );
        }),
        viewerActionsProvider.overrideWith(_FakeViewerActions.new),
        for (final item in items) ...[
          mediaItemProvider(item.id).overrideWith((ref) => item),
          externalMediaItemProvider(item.id).overrideWith((ref) => null),
          fullImageBytesProvider(item).overrideWith((ref) => Uint8List(0)),
          thumbnailProvider(item).overrideWith((ref) => Uint8List(0)),
        ],
        viewerPageIndexProvider.overrideWith((ref) => 0),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: openFromLauncher ? _Launcher(viewer: viewer) : viewer,
      ),
    );
  }

  Widget createViewerWidget({required MediaItem item}) {
    return createMultiViewerWidget(items: [item]);
  }

  testWidgets('a snackbar left over from the last screen is cleared', (
    tester,
  ) async {
    // The "Moved to trash · Undo" bar used to follow into the next viewer
    // and sit over its Delete button, so a tap on Delete pressed Undo.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      createMultiViewerWidget(items: [testImage], openFromLauncher: true),
    );
    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    expect(find.text('Leftover'), findsOneWidget);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(MediaViewerScreen), findsOneWidget);
    expect(find.text('Leftover'), findsNothing);
  });

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

  testWidgets('Tapping the star keeps the same photo and title on screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final second = testImage.copyWith(
      id: 'test_img_2',
      displayName: 'City_Street.jpg',
    );
    final third = testImage.copyWith(
      id: 'test_img_3',
      displayName: 'Temple_Morning.jpg',
    );

    // Open the last photo, not the first, so a jump back to page 0 shows.
    await tester.pumpWidget(
      createMultiViewerWidget(
        items: [testImage, second, third],
        openId: third.id,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Temple_Morning.jpg'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('image-test_img_3')), findsOne);

    await tester.tap(find.byIcon(Icons.star_border));
    // Look in the middle of the reload as well as after it.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text('Temple_Morning.jpg'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('image-test_img_3')), findsOne);

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('Temple_Morning.jpg'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('image-test_img_3')), findsOne);
    expect(
      find.byKey(const ValueKey<String>('image-test_img_1')),
      findsNothing,
    );
  });

  group('every declared language', () {
    for (final locale in declaredLocales) {
      testWidgets(
        'MediaViewerScreen renders cleanly in ${locale.languageCode}',
        (tester) async {
          await tester.pumpWidget(
            createMultiViewerWidget(items: [testImage], locale: locale),
          );
          await tester.pumpAndSettle();
          expectLocaleClean(tester, locale);
        },
      );
    }
  });
}

/// How many times the fake star button asked for a reload.
final _reloadCountProvider = StateProvider<int>((ref) => 0);

/// Stands in for the real actions, so no database is needed. A star tap only
/// makes the timeline list reload, which is the part that caused the bug.
class _FakeViewerActions extends ViewerActions {
  final Ref _testRef;

  _FakeViewerActions(super.ref) : _testRef = ref;

  @override
  Future<void> toggleFavorite(String id) async {
    _testRef.read(_reloadCountProvider.notifier).state++;
  }
}

/// Shows a snackbar that would never hide by itself, then opens the viewer.
class _Launcher extends StatelessWidget {
  final Widget viewer;

  const _Launcher({required this.viewer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          TextButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Leftover'),
                persist: true,
                action: SnackBarAction(label: 'Undo', onPressed: () {}),
              ),
            ),
            child: const Text('show'),
          ),
          TextButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => viewer)),
            child: const Text('open'),
          ),
        ],
      ),
    );
  }
}
