import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/l10n/sanskrit_fallback_delegates.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/widgets/viewer/viewer_app_bar.dart';
import '../../helpers/locale_checks.dart';

MediaItem item(MediaType type) {
  return MediaItem(
    id: '42',
    path: '/storage/emulated/0/DCIM/a.jpg',
    uri: 'content://media/external/images/media/42',
    displayName: 'a.jpg',
    mediaType: type,
    mimeType: type == MediaType.video ? 'video/mp4' : 'image/jpeg',
    size: 10,
    dateAdded: DateTime(2026),
    dateModified: DateTime(2026),
  );
}

Future<void> openMenu(
  WidgetTester tester,
  MediaItem media, {
  Locale locale = const Locale('en'),
  VoidCallback? onSetAsWallpaper,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  void noop() {}
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: ViewerAppBar(
          item: media,
          onToggleFavorite: noop,
          onShowDetails: noop,
          onDelete: noop,
          onEdit: noop,
          onCompare: noop,
          onConvert: noop,
          onVideoTools: noop,
          onEditTags: noop,
          onAddToAlbum: noop,
          onMoveToVault: noop,
          onScanCodes: noop,
          onExtractText: noop,
          onOpenNotes: noop,
          onPrivacyScrubber: noop,
          onSetAsWallpaper: onSetAsWallpaper,
        ),
      ),
    ),
  );
  await tester.tap(find.byIcon(Icons.more_vert));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a photo offers Set as wallpaper, and tapping calls it', (
    tester,
  ) async {
    var calls = 0;
    await openMenu(
      tester,
      item(MediaType.image),
      onSetAsWallpaper: () => calls++,
    );

    expect(find.text('Set as wallpaper'), findsOneWidget);
    await tester.tap(find.text('Set as wallpaper'));
    await tester.pumpAndSettle();
    expect(calls, 1);
  });

  testWidgets('a video does not offer it', (tester) async {
    await openMenu(tester, item(MediaType.video), onSetAsWallpaper: () {});

    expect(find.text('Set as wallpaper'), findsNothing);
  });

  testWidgets('no callback means no menu item', (tester) async {
    await openMenu(tester, item(MediaType.image));

    expect(find.byIcon(Icons.wallpaper_outlined), findsNothing);
  });

  group('every declared language', () {
    for (final locale in declaredLocales) {
      testWidgets('the menu renders cleanly in ${locale.languageCode}', (
        tester,
      ) async {
        await openMenu(
          tester,
          item(MediaType.image),
          locale: locale,
          onSetAsWallpaper: () {},
        );

        expect(find.byIcon(Icons.wallpaper_outlined), findsOneWidget);
        expectLocaleClean(tester, locale);
      });
    }
  });
}
