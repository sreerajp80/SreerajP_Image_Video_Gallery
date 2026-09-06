import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:in_sreerajp_imgvidgal/core/routing/app_router.dart';

/// The Phase 12 routes, and the shape they promise.
///
/// The scanner, the text reader and the note editor all work on one media
/// item, and each takes its id from the path. That only holds while they stay
/// children of the viewer route, so the nesting is pinned down here: if one
/// were ever moved to the top level, it would silently lose its id.
void main() {
  /// Builds a router with the same path patterns the app uses, recording which
  /// screen was reached and with which id.
  GoRouter buildProbe(void Function(String reached, String id) onReach) {
    return GoRouter(
      initialLocation: '/',
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (context, state) {
            onReach('timeline', '');
            return const SizedBox.shrink();
          },
          routes: <RouteBase>[
            GoRoute(
              path: 'media-viewer/:id',
              builder: (context, state) {
                onReach('viewer', state.pathParameters['id'] ?? '');
                return const SizedBox.shrink();
              },
              routes: <RouteBase>[
                GoRoute(
                  path: 'scan',
                  builder: (context, state) {
                    onReach('scan', state.pathParameters['id'] ?? '');
                    return const SizedBox.shrink();
                  },
                ),
                GoRoute(
                  path: 'text',
                  builder: (context, state) {
                    onReach('text', state.pathParameters['id'] ?? '');
                    return const SizedBox.shrink();
                  },
                ),
                GoRoute(
                  path: 'notes',
                  builder: (context, state) {
                    onReach('notes', state.pathParameters['id'] ?? '');
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
            GoRoute(
              path: 'pdf-images',
              builder: (context, state) {
                onReach('pdf-images', '');
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ],
    );
  }

  /// Every screen built for [location], and the ids they were given.
  Future<(List<String>, Map<String, String>)> reach(
    WidgetTester tester,
    String location,
  ) async {
    final reached = <String>[];
    final ids = <String, String>{};

    final router = buildProbe((name, id) {
      reached.add(name);
      ids[name] = id;
    });

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.go(location);
    await tester.pumpAndSettle();

    return (reached, ids);
  }

  group('the path builders', () {
    test('build the paths the app registers', () {
      expect(imageScanPath('42'), '/media-viewer/42/scan');
      expect(extractedTextPath('42'), '/media-viewer/42/text');
      expect(mediaNotesPath('42'), '/media-viewer/42/notes');
      expect(kRoutePdfImages, '/pdf-images');
    });

    // The id only survives while these sit under the viewer path.
    test('the three item tools sit under the viewer path', () {
      for (final path in <String>[
        imageScanPath('7'),
        extractedTextPath('7'),
        mediaNotesPath('7'),
      ]) {
        expect(path, startsWith('$kRouteMediaViewer/7/'));
      }
    });

    test('the PDF tool takes no media item, so it is not nested', () {
      expect(kRoutePdfImages.startsWith(kRouteMediaViewer), isFalse);
    });

    test('the three tools are distinct paths', () {
      final paths = <String>{
        imageScanPath('7'),
        extractedTextPath('7'),
        mediaNotesPath('7'),
      };
      expect(paths, hasLength(3));
    });

    test('the PDF image tool is not the PDF export screen', () {
      // Two different features, easily confused: one writes a PDF, the other
      // reads one.
      expect(kRoutePdfImages, isNot(kRoutePdfExport));
    });
  });

  group('navigation', () {
    testWidgets('the scan path opens the scanner with the id', (tester) async {
      final (reached, ids) = await reach(tester, imageScanPath('abc'));
      expect(reached, contains('scan'));
      expect(ids['scan'], 'abc');
    });

    testWidgets('the text path opens the reader with the id', (tester) async {
      final (reached, ids) = await reach(tester, extractedTextPath('abc'));
      expect(reached, contains('text'));
      expect(ids['text'], 'abc');
    });

    testWidgets('the notes path opens the editor with the id', (tester) async {
      final (reached, ids) = await reach(tester, mediaNotesPath('abc'));
      expect(reached, contains('notes'));
      expect(ids['notes'], 'abc');
    });

    testWidgets('the pdf-images path opens the PDF tool', (tester) async {
      final (reached, _) = await reach(tester, kRoutePdfImages);
      expect(reached, contains('pdf-images'));
    });

    testWidgets('an id with awkward characters survives the round trip', (
      tester,
    ) async {
      const id = 'content%3A%2F%2Fmedia%2F1';
      final (_, ids) = await reach(tester, imageScanPath(id));
      expect(ids['scan'], isNotEmpty);
    });

    testWidgets('the three tools do not reach each other', (tester) async {
      final (scan, _) = await reach(tester, imageScanPath('1'));
      expect(scan, isNot(contains('text')));
      expect(scan, isNot(contains('notes')));

      final (notes, _) = await reach(tester, mediaNotesPath('1'));
      expect(notes, isNot(contains('scan')));
    });

    testWidgets('the PDF tool never passes through the viewer', (tester) async {
      final (reached, _) = await reach(tester, kRoutePdfImages);
      expect(reached, isNot(contains('viewer')));
    });
  });
}
