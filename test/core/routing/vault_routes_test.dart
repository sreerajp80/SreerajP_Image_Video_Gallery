import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:in_sreerajp_imgvidgal/core/routing/app_router.dart';

/// The vault sits under one route with two children, and one of those children
/// is a fixed word while the other takes an id. If `settings` were ever read as
/// a vault item id, opening vault settings would silently try to decrypt an
/// item that does not exist. These tests pin that apart, and pin the id
/// surviving the round trip through the URL.
void main() {
  /// Builds a router with the same path patterns the app uses, reporting which
  /// branch each location reached.
  GoRouter buildProbe(void Function(String branch, String value) onBranch) {
    return GoRouter(
      initialLocation: '/',
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (context, state) => const SizedBox.shrink(),
          routes: <RouteBase>[
            GoRoute(
              path: 'vault',
              builder: (context, state) {
                onBranch('gate', '');
                return const SizedBox.shrink();
              },
              routes: <RouteBase>[
                GoRoute(
                  path: 'settings',
                  builder: (context, state) {
                    onBranch('settings', '');
                    return const SizedBox.shrink();
                  },
                ),
                GoRoute(
                  path: 'viewer/:id',
                  builder: (context, state) {
                    onBranch('viewer', state.pathParameters['id'] ?? '');
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

  /// Every branch that built for [location].
  ///
  /// A nested route builds its parent too, so this collects them all rather
  /// than guessing at an order: what matters is which branches were reached
  /// and what id the viewer was handed.
  Future<Map<String, String>> branchesFor(
    WidgetTester tester,
    String location,
  ) async {
    final seen = <String, String>{};
    final router = buildProbe((branch, value) => seen[branch] = value);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    router.go(location);
    await tester.pumpAndSettle();

    return seen;
  }

  group('the vault route paths', () {
    test('the gate is the vault route itself', () {
      expect(kRouteVault, '/vault');
    });

    test('settings sits under the gate', () {
      expect(kRouteVaultSettings, '/vault/settings');
    });

    test('the viewer path is built from the item id', () {
      expect(vaultViewerPath('abc123'), '/vault/viewer/abc123');
    });

    test('an id with an awkward character is encoded', () {
      // Vault ids are hex today, but a path builder that only works for hex is
      // a trap for whatever writes ids next.
      expect(vaultViewerPath('a/b'), '/vault/viewer/a%2Fb');
      expect(vaultViewerPath('a b'), '/vault/viewer/a%20b');
    });
  });

  group('routing reaches the right screen', () {
    testWidgets('the vault route opens the gate and nothing else', (
      tester,
    ) async {
      final branches = await branchesFor(tester, kRouteVault);

      expect(branches.keys, <String>['gate']);
    });

    testWidgets('the settings route opens settings, not the viewer', (
      tester,
    ) async {
      final branches = await branchesFor(tester, kRouteVaultSettings);

      // The word `settings` must never be read as an item id.
      expect(branches, contains('settings'));
      expect(branches, isNot(contains('viewer')));
    });

    testWidgets('the viewer route opens the viewer with its id', (
      tester,
    ) async {
      final branches = await branchesFor(tester, vaultViewerPath('deadbeef'));

      expect(branches, contains('viewer'));
      expect(branches['viewer'], 'deadbeef');
      expect(branches, isNot(contains('settings')));
    });

    testWidgets('an encoded id arrives whole', (tester) async {
      final branches = await branchesFor(tester, vaultViewerPath('a b'));

      expect(branches['viewer'], 'a b');
    });
  });
}
