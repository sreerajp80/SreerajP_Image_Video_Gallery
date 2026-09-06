import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:in_sreerajp_imgvidgal/core/routing/app_router.dart';

/// A folder path carries separators of its own, so the album routes lean on the
/// path parameter surviving a round trip through the URL. These tests pin that
/// down: if encoding or decoding ever changes, opening a device folder breaks,
/// and it breaks silently by showing the wrong folder rather than failing.
void main() {
  /// Builds a router with the same path patterns the app uses, reporting which
  /// parameter each screen was handed.
  GoRouter buildProbe(void Function(String name, String value) onParam) {
    return GoRouter(
      initialLocation: '/',
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (context, state) => const SizedBox.shrink(),
          routes: <RouteBase>[
            GoRoute(
              path: 'albums',
              builder: (context, state) => const SizedBox.shrink(),
              routes: <RouteBase>[
                GoRoute(
                  path: 'auto/:type',
                  builder: (context, state) {
                    onParam('type', state.pathParameters['type'] ?? '');
                    return const SizedBox.shrink();
                  },
                ),
                GoRoute(
                  path: 'folder/:path',
                  builder: (context, state) {
                    onParam('folder', state.pathParameters['path'] ?? '');
                    return const SizedBox.shrink();
                  },
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) {
                    onParam('id', state.pathParameters['id'] ?? '');
                    return const SizedBox.shrink();
                  },
                  routes: <RouteBase>[
                    GoRoute(
                      path: 'reorder',
                      builder: (context, state) {
                        onParam('reorder', state.pathParameters['id'] ?? '');
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Future<String?> paramFor(WidgetTester tester, String location) async {
    final seen = <String, String>{};
    final router = buildProbe((name, value) => seen[name] = value);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    router.go(location);
    await tester.pumpAndSettle();

    return seen.values.isEmpty ? null : seen.values.last;
  }

  group('folder paths survive the round trip', () {
    testWidgets('a normal folder path arrives whole', (tester) async {
      const directory = '/storage/emulated/0/DCIM/Camera';
      expect(await paramFor(tester, folderAlbumPath(directory)), directory);
    });

    testWidgets('a folder path with a space arrives whole', (tester) async {
      const directory = '/storage/My Photos/Trip 2026';
      expect(await paramFor(tester, folderAlbumPath(directory)), directory);
    });

    testWidgets('a folder name with a wildcard arrives whole', (tester) async {
      const directory = '/DCIM/100%';
      expect(await paramFor(tester, folderAlbumPath(directory)), directory);
    });

    testWidgets('the root folder arrives whole', (tester) async {
      expect(await paramFor(tester, folderAlbumPath('/')), '/');
    });
  });

  group('the other album routes', () {
    testWidgets('a smart album key arrives whole', (tester) async {
      expect(await paramFor(tester, smartAlbumPath('panoramas')), 'panoramas');
    });

    testWidgets('an album id arrives whole', (tester) async {
      expect(
        await paramFor(tester, albumPath('album_abc_123')),
        'album_abc_123',
      );
    });

    testWidgets('the reorder route keeps the album id', (tester) async {
      expect(
        await paramFor(tester, albumReorderPath('album_abc_123')),
        'album_abc_123',
      );
    });

    testWidgets('a smart album is not read as an album id', (tester) async {
      // Both patterns sit under /albums; the fixed segment must win, or every
      // smart album would open as a missing user album.
      final seen = <String, String>{};
      final router = buildProbe((name, value) => seen[name] = value);

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );
      router.go(smartAlbumPath('videos'));
      await tester.pumpAndSettle();

      expect(seen.containsKey('type'), isTrue);
      expect(seen.containsKey('id'), isFalse);
    });

    testWidgets('a folder is not read as an album id', (tester) async {
      final seen = <String, String>{};
      final router = buildProbe((name, value) => seen[name] = value);

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );
      router.go(folderAlbumPath('/DCIM/Camera'));
      await tester.pumpAndSettle();

      expect(seen.containsKey('folder'), isTrue);
      expect(seen.containsKey('id'), isFalse);
    });
  });
}
