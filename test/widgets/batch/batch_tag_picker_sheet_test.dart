import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/batch/batch_action.dart';
import 'package:in_sreerajp_imgvidgal/models/tag.dart';
import 'package:in_sreerajp_imgvidgal/providers/tag_providers.dart';
import 'package:in_sreerajp_imgvidgal/repositories/tag_repository.dart';
import 'package:in_sreerajp_imgvidgal/widgets/batch/batch_tag_picker_sheet.dart';

class FakeTagRepository implements TagRepository {
  final List<Tag> tags;

  FakeTagRepository({List<Tag>? initialTags})
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

void main() {
  testWidgets(
    'BatchTagPickerSheet shows empty state and allows inline tag creation',
    (tester) async {
      final fakeRepo = FakeTagRepository();
      Set<String>? returnedTags;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [tagRepositoryProvider.overrideWithValue(fakeRepo)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    returnedTags = await BatchTagPickerSheet.show(
                      context,
                      action: BatchAction.addTags,
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open sheet
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Empty label and input should appear
      expect(find.text('No tags yet'), findsOneWidget);
      expect(find.text('Add a new tag'), findsOneWidget);

      // Continue button should be disabled when nothing chosen
      final continueButtonFinder = find.widgetWithText(
        FilledButton,
        'Continue',
      );
      expect(continueButtonFinder, findsOneWidget);
      final button = tester.widget<FilledButton>(continueButtonFinder);
      expect(button.onPressed, isNull);

      // Enter a new tag name and tap Add
      await tester.enterText(find.byType(TextField), 'Vacation');
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();

      // The new tag should appear and be checked
      expect(find.text('Vacation'), findsOneWidget);
      final checkbox = tester.widget<CheckboxListTile>(
        find.widgetWithText(CheckboxListTile, 'Vacation'),
      );
      expect(checkbox.value, isTrue);

      // Continue button is now enabled
      final enabledButton = tester.widget<FilledButton>(continueButtonFinder);
      expect(enabledButton.onPressed, isNotNull);

      // Tap Continue to close and verify result
      await tester.tap(continueButtonFinder);
      await tester.pumpAndSettle();

      expect(returnedTags, contains('tag_1'));
    },
  );

  testWidgets('BatchTagPickerSheet with existing tags allows selecting them', (
    tester,
  ) async {
    final existingTag = Tag(
      id: 'existing_tag_1',
      name: 'Nature',
      colorValue: 0xFF2196F3,
      dateCreated: DateTime.now(),
    );
    final fakeRepo = FakeTagRepository(initialTags: [existingTag]);
    Set<String>? returnedTags;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [tagRepositoryProvider.overrideWithValue(fakeRepo)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  returnedTags = await BatchTagPickerSheet.show(
                    context,
                    action: BatchAction.addTags,
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    // Open sheet
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Nature'), findsOneWidget);

    // Tap checkbox to select
    await tester.tap(find.text('Nature'));
    await tester.pumpAndSettle();

    // Tap Continue
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(returnedTags, contains('existing_tag_1'));
  });

  testWidgets(
    'BatchTagPickerSheet for removeTags does not display add tag row',
    (tester) async {
      final existingTag = Tag(
        id: 't1',
        name: 'Travel',
        colorValue: 0xFF00FF00,
        dateCreated: DateTime.now(),
      );
      final fakeRepo = FakeTagRepository(initialTags: [existingTag]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [tagRepositoryProvider.overrideWithValue(fakeRepo)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => BatchTagPickerSheet.show(
                    context,
                    action: BatchAction.removeTags,
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Remove tags'), findsOneWidget);
      expect(find.text('Add a new tag'), findsNothing);
      expect(find.text('Travel'), findsOneWidget);
    },
  );
}
