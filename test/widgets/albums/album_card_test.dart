import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/l10n/sanskrit_fallback_delegates.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/album.dart';
import 'package:in_sreerajp_imgvidgal/models/album_summary.dart';
import 'package:in_sreerajp_imgvidgal/widgets/albums/album_card.dart';
import 'package:material_ui/material_ui.dart';

/// Draws one card with no cover, so no thumbnail work runs in the test.
Future<void> _pump(
  WidgetTester tester,
  AlbumSummary summary, {
  Locale locale = const Locale('en'),
  double? size = 120,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 200,
            child: AlbumCard(summary: summary, size: size),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

AlbumSummary _summary({int itemCount = 3, int totalBytes = 0}) => AlbumSummary(
  id: '/DCIM/Camera',
  name: 'Camera',
  albumType: AlbumType.physicalFolder,
  folderPath: '/DCIM/Camera',
  itemCount: itemCount,
  totalBytes: totalBytes,
);

void main() {
  testWidgets('shows the total size over the cover', (tester) async {
    await _pump(tester, _summary(totalBytes: 3 * 1024 * 1024));

    expect(find.text('3.0 MB'), findsOneWidget);
  });

  testWidgets('the badge sits in the top-left corner of the cover', (
    tester,
  ) async {
    await _pump(tester, _summary(totalBytes: 2048));

    final badge = tester.getTopLeft(find.text('2.0 KB'));
    final card = tester.getTopLeft(find.byType(AlbumCard));
    // Inside the card's own padding plus the badge inset, not far down or
    // across the cover.
    expect(badge.dx - card.dx, lessThan(24));
    expect(badge.dy - card.dy, lessThan(24));
  });

  testWidgets('a grid card that fills its width also shows the size', (
    tester,
  ) async {
    await _pump(tester, _summary(totalBytes: 2048), size: null);

    expect(find.text('2.0 KB'), findsOneWidget);
  });

  testWidgets('an empty album shows no size badge', (tester) async {
    await _pump(tester, _summary(itemCount: 0));

    expect(find.textContaining('KB'), findsNothing);
  });

  testWidgets('screen readers hear the size once, in the card label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, _summary(totalBytes: 2048));

    expect(find.bySemanticsLabel(RegExp(r'^Camera, .*, 2\.0 KB')), findsOne);
    expect(find.bySemanticsLabel('2.0 KB'), findsNothing);
    handle.dispose();
  });

  for (final locale in const <Locale>[Locale('ml'), Locale('sa')]) {
    testWidgets('draws the size in ${locale.languageCode}', (tester) async {
      await _pump(tester, _summary(totalBytes: 2048), locale: locale);

      expect(tester.takeException(), isNull);
      expect(find.byType(AlbumCard), findsOneWidget);
    });
  }
}
