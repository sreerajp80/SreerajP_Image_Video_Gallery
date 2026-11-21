import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:in_sreerajp_imgvidgal/core/l10n/sanskrit_fallback_delegates.dart';
import 'package:in_sreerajp_imgvidgal/core/routing/app_router.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/timeline_providers.dart';
import 'package:in_sreerajp_imgvidgal/screens/memories/memories_screen.dart';
import 'package:in_sreerajp_imgvidgal/widgets/media/media_grid_tile.dart';
import '../../helpers/locale_checks.dart';

MediaItem itemAt(String id, DateTime taken) {
  return MediaItem(
    id: id,
    path: '/storage/emulated/0/DCIM/$id.jpg',
    displayName: '$id.jpg',
    mediaType: MediaType.image,
    mimeType: 'image/jpeg',
    size: 256,
    dateAdded: taken,
    dateModified: taken,
    dateTaken: taken,
  );
}

/// A fixed "today" so the test never depends on the wall clock.
final fixedNow = DateTime(2026, 8, 29, 14, 30);

Future<void> pumpMemories(
  WidgetTester tester,
  List<MediaItem> items, {
  Locale locale = const Locale('en'),
}) async {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const MemoriesScreen()),
      GoRoute(
        path: '$kRouteMediaViewer/:id',
        builder: (context, state) =>
            Text('viewer ${state.pathParameters['id']}'),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        timelineItemsProvider.overrideWith((ref) => Stream.value(items)),
        timelineNowProvider.overrideWithValue(() => fixedNow),
        gridColumnCountProvider.overrideWith(
          (ref) => GridColumnCountNotifier(),
        ),
        for (final item in items)
          thumbnailProvider(item).overrideWith((ref) => Uint8List(0)),
      ],
      child: MaterialApp.router(
        locale: locale,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows one section per earlier year with every item', (
    tester,
  ) async {
    await pumpMemories(tester, [
      itemAt('a', DateTime(2025, 8, 29, 9)),
      itemAt('b', DateTime(2025, 8, 29, 10)),
      itemAt('c', DateTime(2023, 8, 29, 9)),
    ]);

    expect(find.text('Memories'), findsOneWidget);
    expect(find.text('1 year ago'), findsOneWidget);
    expect(find.text('3 years ago'), findsOneWidget);
    expect(find.byType(MediaGridTile), findsNWidgets(3));
    expect(
      find.text('Nothing from today. Showing this week in past years.'),
      findsNothing,
    );
  });

  testWidgets('says so when it falls back to the week', (tester) async {
    await pumpMemories(tester, [itemAt('near', DateTime(2025, 8, 27, 9))]);

    expect(
      find.text('Nothing from today. Showing this week in past years.'),
      findsOneWidget,
    );
    expect(find.byType(MediaGridTile), findsOneWidget);
  });

  testWidgets('shows the empty message when there is nothing', (tester) async {
    await pumpMemories(tester, [itemAt('today', DateTime(2026, 8, 29, 9))]);

    expect(
      find.text(
        'No memories yet. Photos from this time in past years will show here.',
      ),
      findsOneWidget,
    );
    expect(find.byType(MediaGridTile), findsNothing);
  });

  testWidgets('tapping a tile opens the viewer for that item', (tester) async {
    await pumpMemories(tester, [itemAt('memory', DateTime(2025, 8, 29, 9))]);

    await tester.tap(find.byType(MediaGridTile));
    await tester.pumpAndSettle();

    expect(find.text('viewer memory'), findsOneWidget);
  });

  group('every declared language', () {
    for (final locale in declaredLocales) {
      testWidgets('renders cleanly in ${locale.languageCode}', (tester) async {
        await pumpMemories(tester, [
          itemAt('near', DateTime(2025, 8, 27, 9)),
          itemAt('older', DateTime(2022, 8, 30, 9)),
        ], locale: locale);

        expectLocaleClean(tester, locale);
      });

      testWidgets('empty renders cleanly in ${locale.languageCode}', (
        tester,
      ) async {
        await pumpMemories(tester, const <MediaItem>[], locale: locale);

        expectLocaleClean(tester, locale);
      });
    }
  });
}
