import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/l10n/sanskrit_fallback_delegates.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/timeline_group.dart';
import 'package:in_sreerajp_imgvidgal/providers/settings_providers.dart';
import 'package:in_sreerajp_imgvidgal/widgets/timeline/timeline_body.dart';

/// A timeline with one day header and nothing else: far shorter than the
/// screen, like a phone that holds only a few photos.
TimelineData _shortTimeline() {
  final day = DateTime(2026, 9, 28);
  return TimelineData(
    groups: [
      TimelineGroup(
        date: day,
        headerKind: TimelineHeaderKind.dayThisYear,
        items: const [],
      ),
    ],
    rows: [
      TimelineRow.header(
        groupIndex: 0,
        date: day,
        headerKind: TimelineHeaderKind.dayThisYear,
      ),
    ],
    columnCount: 3,
    itemCount: 0,
  );
}

void main() {
  testWidgets('pull-to-refresh works when the timeline fits on one screen', (
    tester,
  ) async {
    var refreshCalls = 0;
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [showFlashbacksProvider.overrideWithValue(false)],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TimelineBody(
              data: _shortTimeline(),
              scrollController: scrollController,
              onRefresh: () async => refreshCalls++,
              onItemTap: (_) {},
              onItemLongPress: (_) {},
              onScaleStart: (_) {},
              onScaleUpdate: (_) {},
              onScaleEnd: (_) {},
              onMetrics: (_) {},
              flashbackKey: GlobalKey(),
              leadingExtent: () => 0,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, 400),
      1000,
    );
    await tester.pumpAndSettle();

    expect(refreshCalls, 1);
  });
}
