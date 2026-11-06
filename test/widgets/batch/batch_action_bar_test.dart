import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/album_summary.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/tag.dart';
import 'package:in_sreerajp_imgvidgal/providers/album_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/selection_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/tag_providers.dart';
import 'package:in_sreerajp_imgvidgal/repositories/tag_repository.dart';
import 'package:in_sreerajp_imgvidgal/widgets/batch/batch_action_bar.dart';
import 'package:in_sreerajp_imgvidgal/core/l10n/sanskrit_fallback_delegates.dart';

class FakeTagRepo implements TagRepository {
  final List<Tag> tags;

  FakeTagRepo({List<Tag>? initialTags})
    : tags = List<Tag>.from(initialTags ?? <Tag>[]);

  @override
  Future<List<Tag>> getAllTags() async => List<Tag>.unmodifiable(tags);

  @override
  Future<Tag> findOrCreateTag(String name, {int? colorValue}) async {
    final existing = tags
        .where((t) => t.name.toLowerCase() == name.trim().toLowerCase())
        .firstOrNull;
    if (existing != null) return existing;

    final created = Tag(
      id: 'tag_${tags.length + 1}',
      name: name.trim(),
      colorValue: colorValue ?? 0xFF123456,
      dateCreated: DateTime.now(),
    );
    tags.add(created);
    return created;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MediaItem _sampleItem(String id) => MediaItem(
  id: id,
  path: '/storage/$id.jpg',
  displayName: '$id.jpg',
  mediaType: MediaType.image,
  mimeType: 'image/jpeg',
  size: 1024,
  dateAdded: DateTime(2026),
  dateModified: DateTime(2026),
);

void main() {
  testWidgets(
    'BatchActionBar Add tags button opens BatchTagPickerSheet even when no tags exist',
    (tester) async {
      final fakeRepo = FakeTagRepo();
      final item = _sampleItem('photo1');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedMediaProvider.overrideWith((ref) async => [item]),
            tagRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(bottomNavigationBar: BatchActionBar()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tags live in the More sheet, not the bar.
      expect(find.widgetWithText(InkWell, 'Add tags'), findsNothing);
      await tester.tap(find.widgetWithText(InkWell, 'More'));
      await tester.pumpAndSettle();

      final addTagsFinder = find.widgetWithText(ListTile, 'Add tags');
      expect(addTagsFinder, findsOneWidget);

      // Tap "Add tags"
      await tester.tap(addTagsFinder);
      await tester.pumpAndSettle();

      // The sheet should open with "Add a new tag" input and "No tags yet"
      expect(find.text('Choose tags'), findsOneWidget);
      expect(find.text('No tags yet'), findsOneWidget);
      expect(find.text('Add a new tag'), findsOneWidget);
    },
  );

  testWidgets(
    'BatchActionBar Remove tags displays SnackBar when no tags exist',
    (tester) async {
      final fakeRepo = FakeTagRepo();
      final item = _sampleItem('photo1');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedMediaProvider.overrideWith((ref) async => [item]),
            tagRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(bottomNavigationBar: BatchActionBar()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(InkWell, 'More'));
      await tester.pumpAndSettle();

      final removeTagsFinder = find.widgetWithText(ListTile, 'Remove tags');
      expect(removeTagsFinder, findsOneWidget);

      await tester.tap(removeTagsFinder);
      await tester.pumpAndSettle();

      // Should show SnackBar with 'No tags yet'
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('No tags yet'), findsOneWidget);
    },
  );

  testWidgets(
    'BatchActionBar Add to album opens album picker with create button when empty',
    (tester) async {
      final item = _sampleItem('photo1');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedMediaProvider.overrideWith((ref) async => [item]),
            virtualAlbumsProvider.overrideWith((ref) async => <AlbumSummary>[]),
          ],
          child: const MaterialApp(
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(bottomNavigationBar: BatchActionBar()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final addToAlbumFinder = find.widgetWithText(InkWell, 'Add to album');
      expect(addToAlbumFinder, findsOneWidget);

      await tester.tap(addToAlbumFinder);
      await tester.pumpAndSettle();

      // Sheet opens showing "Choose an album", empty message and "New album" button
      expect(find.text('Choose an album'), findsOneWidget);
      expect(find.text('You have no albums yet'), findsOneWidget);
      expect(find.text('New album'), findsOneWidget);
    },
  );

  testWidgets('BatchActionBar shows the quick actions and More in the bar', (
    tester,
  ) async {
    final item = _sampleItem('photo1');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedMediaProvider.overrideWith((ref) async => [item]),
        ],
        child: const MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(bottomNavigationBar: BatchActionBar()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final label in <String>[
      'Send to a device',
      'Add to favourites',
      'Add to album',
      'Move to trash',
      'More',
    ]) {
      expect(
        find.widgetWithText(InkWell, label),
        findsOneWidget,
        reason: label,
      );
    }
    expect(find.widgetWithText(InkWell, 'Convert'), findsNothing);
    expect(find.byType(ListView), findsNothing);

    await tester.tap(find.widgetWithText(InkWell, 'More'));
    await tester.pumpAndSettle();

    for (final label in <String>['Convert', 'Watermark', 'Add tags']) {
      expect(
        find.widgetWithText(ListTile, label),
        findsOneWidget,
        reason: label,
      );
    }
  });
}
