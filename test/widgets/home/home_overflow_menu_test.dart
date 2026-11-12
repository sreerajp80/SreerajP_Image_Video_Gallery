import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:in_sreerajp_imgvidgal/core/l10n/sanskrit_fallback_delegates.dart';
import 'package:in_sreerajp_imgvidgal/core/routing/app_router.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/widgets/home/home_overflow_menu.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/locale_checks.dart';

/// A small router: a home page whose bar holds the menu, plus a stand-in
/// Settings page, so a tap can be followed to where it leads.
GoRouter _router({Widget menu = const HomeOverflowMenu()}) => GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (context, state) =>
          Scaffold(appBar: AppBar(actions: <Widget>[menu])),
      routes: <RouteBase>[
        GoRoute(
          path: 'settings',
          builder: (context, state) =>
              const Scaffold(body: Text('settings-page')),
        ),
      ],
    ),
  ],
);

Future<void> _pump(
  WidgetTester tester,
  Locale locale, {
  Widget menu = const HomeOverflowMenu(),
}) async {
  await tester.pumpWidget(
    MaterialApp.router(
      locale: locale,
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _router(menu: menu),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('the stand-in settings path matches the real route', () {
    expect(kRouteSettings, '/settings');
  });

  testWidgets('shows all eight items and opens Settings', (tester) async {
    await _pump(tester, const Locale('en'));

    await tester.tap(find.byType(HomeOverflowMenu));
    await tester.pumpAndSettle();

    expect(find.byType(PopupMenuItem<String>), findsNWidgets(8));
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('settings-page'), findsOneWidget);
  });

  testWidgets('extra items show first, above a divider, and call back', (
    tester,
  ) async {
    final picked = <String>[];
    await _pump(
      tester,
      const Locale('en'),
      menu: HomeOverflowMenu(
        onExtraSelected: picked.add,
        extraItems: const <PopupMenuEntry<String>>[
          PopupMenuItem<String>(value: 'rename', child: Text('extra-rename')),
        ],
      ),
    );

    await tester.tap(find.byType(HomeOverflowMenu));
    await tester.pumpAndSettle();

    expect(find.byType(PopupMenuItem<String>), findsNWidgets(9));
    expect(find.byType(PopupMenuDivider), findsOneWidget);
    // The extra item sits above the shared ones.
    expect(
      tester.getTopLeft(find.text('extra-rename')).dy,
      lessThan(tester.getTopLeft(find.byIcon(Icons.label_outline)).dy),
    );

    await tester.tap(find.text('extra-rename'));
    await tester.pumpAndSettle();

    expect(picked, <String>['rename']);
    // It called back instead of navigating.
    expect(find.text('settings-page'), findsNothing);
  });

  testWidgets('no extra items means no divider', (tester) async {
    await _pump(tester, const Locale('en'));
    await tester.tap(find.byType(HomeOverflowMenu));
    await tester.pumpAndSettle();
    expect(find.byType(PopupMenuDivider), findsNothing);
  });

  group('every declared language', () {
    for (final locale in declaredLocales) {
      testWidgets('open menu renders cleanly in ${locale.languageCode}', (
        tester,
      ) async {
        await _pump(tester, locale);
        await tester.tap(find.byType(HomeOverflowMenu));
        await tester.pumpAndSettle();
        expect(find.byType(PopupMenuItem<String>), findsNWidgets(8));
        expectLocaleClean(tester, locale);
      });
    }
  });
}
