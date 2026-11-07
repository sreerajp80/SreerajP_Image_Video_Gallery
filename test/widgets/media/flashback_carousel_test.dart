import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/flashback_memory.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/timeline_providers.dart';
import 'package:in_sreerajp_imgvidgal/widgets/media/flashback_carousel.dart';
import 'package:in_sreerajp_imgvidgal/widgets/media/media_grid_tile.dart';
import 'package:material_ui/material_ui.dart';

MediaItem _item(String id) => MediaItem(
  id: id,
  path: 'sample/$id.jpg',
  displayName: '$id.jpg',
  mediaType: MediaType.image,
  mimeType: 'image/jpeg',
  size: 1,
  dateAdded: DateTime(2025, 11, 7),
  dateModified: DateTime(2025, 11, 7),
);

final _memories = [
  FlashbackMemory(
    year: 2025,
    yearsAgo: 1,
    date: DateTime(2025, 11, 7),
    items: [_item('a'), _item('b')],
  ),
  FlashbackMemory(
    year: 2024,
    yearsAgo: 2,
    date: DateTime(2024, 11, 7),
    items: [_item('c')],
  ),
];

/// Hosts the carousel the way the timeline does: open state in
/// [flashbackExpandedProvider], toggled by the title bar.
class _Host extends ConsumerWidget {
  const _Host();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expanded = ref.watch(flashbackExpandedProvider);
    return FlashbackCarousel(
      memories: _memories,
      expanded: expanded,
      onToggle: () =>
          ref.read(flashbackExpandedProvider.notifier).state = !expanded,
    );
  }
}

Future<ThemeData> _pump(WidgetTester tester) async {
  final theme = ThemeData(brightness: Brightness.light);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [thumbnailProvider.overrideWith((ref, item) async => null)],
      child: MaterialApp(
        theme: theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const Scaffold(body: SingleChildScrollView(child: _Host())),
      ),
    ),
  );
  await tester.pump();
  return theme;
}

void main() {
  testWidgets('starts collapsed: title, total count, no tiles', (tester) async {
    await _pump(tester);

    expect(find.text('On This Day'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.byType(MediaGridTile), findsNothing);
    expect(find.text('1 year ago'), findsNothing);
    expect(find.byTooltip('Show memories'), findsOneWidget);
  });

  testWidgets('tapping the title bar opens and closes it', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('On This Day'));
    await tester.pump();
    expect(find.byType(MediaGridTile), findsNWidgets(3));
    expect(find.text('1 year ago'), findsOneWidget);
    expect(find.byTooltip('Hide memories'), findsOneWidget);

    await tester.tap(find.byTooltip('Hide memories'));
    await tester.pump();
    expect(find.byType(MediaGridTile), findsNothing);
  });

  testWidgets('has a border and a tertiary title shade', (tester) async {
    final theme = await _pump(tester);

    final bordered = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(FlashbackCarousel),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((box) => box.decoration)
        .whereType<BoxDecoration>()
        .where((d) => d.border != null);
    expect(bordered, isNotEmpty);
    expect(
      (bordered.first.border! as Border).top.color,
      theme.colorScheme.outlineVariant,
    );

    final shade = tester.widget<Material>(
      find
          .ancestor(
            of: find.text('On This Day'),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(shade.color, theme.colorScheme.tertiaryContainer);
  });

  testWidgets('draws nothing when there are no memories', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: FlashbackCarousel(memories: [])),
    );
    expect(find.byType(DecoratedBox), findsNothing);
  });
}
