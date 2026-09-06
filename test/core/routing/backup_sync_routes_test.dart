import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:in_sreerajp_imgvidgal/core/routing/app_router.dart';

/// The transfer routes carry a promise, not just a location.
///
/// The socket listener lives only while a screen under `/sync` is on top. That
/// only holds if the paths really are nested under it, so these tests pin the
/// shape down: if `/sync/receive` ever stopped being a child of `/sync`, the
/// lifetime rule would quietly stop meaning anything.
void main() {
  /// Builds a router with the same path patterns the app uses, recording
  /// which screen was reached.
  GoRouter buildProbe(void Function(String reached) onReach) {
    return GoRouter(
      initialLocation: '/',
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (context, state) {
            onReach('timeline');
            return const SizedBox.shrink();
          },
          routes: <RouteBase>[
            GoRoute(
              path: 'backup',
              builder: (context, state) {
                onReach('backup');
                return const SizedBox.shrink();
              },
            ),
            GoRoute(
              path: 'sync',
              builder: (context, state) {
                onReach('sync');
                return const SizedBox.shrink();
              },
              routes: <RouteBase>[
                GoRoute(
                  path: 'receive',
                  builder: (context, state) {
                    onReach('sync/receive');
                    return const SizedBox.shrink();
                  },
                ),
                GoRoute(
                  path: 'send',
                  builder: (context, state) {
                    onReach('sync/send');
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Every screen that was built for [location].
  ///
  /// A list rather than one name, because a nested route builds its parent
  /// too and the leaf is not always the last entry.
  Future<List<String>> reach(WidgetTester tester, String location) async {
    final reached = <String>[];
    final router = buildProbe(reached.add);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.go(location);
    await tester.pumpAndSettle();

    return reached;
  }

  group('the route constants', () {
    test('are the paths the app actually registers', () {
      expect(kRouteBackup, '/backup');
      expect(kRouteSync, '/sync');
      expect(kRouteSyncReceive, '/sync/receive');
      expect(kRouteSyncSend, '/sync/send');
    });

    test('the transfer sub-paths sit under the transfer path', () {
      // This is the shape the listener's lifetime depends on.
      expect(kRouteSyncReceive, startsWith('$kRouteSync/'));
      expect(kRouteSyncSend, startsWith('$kRouteSync/'));
    });

    test('backup is not under the transfer path', () {
      // Backup opens no socket. Nesting it under /sync would suggest it did.
      expect(kRouteBackup.startsWith(kRouteSync), isFalse);
    });
  });

  group('navigation', () {
    testWidgets('the backup path opens the backup screen', (tester) async {
      expect(await reach(tester, kRouteBackup), contains('backup'));
    });

    testWidgets('the transfer path opens the transfer home', (tester) async {
      expect(await reach(tester, kRouteSync), contains('sync'));
    });

    testWidgets('the receive path opens the receiving screen', (tester) async {
      expect(await reach(tester, kRouteSyncReceive), contains('sync/receive'));
    });

    testWidgets('the send path opens the scanner screen', (tester) async {
      expect(await reach(tester, kRouteSyncSend), contains('sync/send'));
    });

    testWidgets('receive and send do not reach each other', (tester) async {
      expect(
        await reach(tester, kRouteSyncReceive),
        isNot(contains('sync/send')),
      );
      expect(
        await reach(tester, kRouteSyncSend),
        isNot(contains('sync/receive')),
      );
    });

    testWidgets('the backup path never reaches a transfer screen', (
      tester,
    ) async {
      // Backup opens no socket, and must not pass through a screen that does.
      final reached = await reach(tester, kRouteBackup);
      expect(reached, isNot(contains('sync')));
      expect(reached, isNot(contains('sync/receive')));
    });
  });
}
