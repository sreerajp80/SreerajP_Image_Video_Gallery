import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/media/media_delete_result.dart';
import 'package:in_sreerajp_imgvidgal/widgets/common/delete_choice_sheet.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  /// Opens the sheet from a button and records what it returned.
  Future<List<DeleteChoice?>> openSheet(
    WidgetTester tester, {
    int count = 1,
    bool secureDelete = false,
  }) async {
    final results = <DeleteChoice?>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => results.add(
                await showDeleteChoiceSheet(
                  context,
                  count: count,
                  secureDelete: secureDelete,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return results;
  }

  group('showDeleteChoiceSheet', () {
    testWidgets('offers trash first, then permanent', (tester) async {
      await openSheet(tester, count: 3);

      expect(find.text('Delete 3 items?'), findsOneWidget);
      final trash = tester.getTopLeft(
        find.byKey(const ValueKey<String>('delete_choice_trash')),
      );
      final permanent = tester.getTopLeft(
        find.byKey(const ValueKey<String>('delete_choice_permanent')),
      );
      expect(trash.dy, lessThan(permanent.dy));
    });

    testWidgets('says "it" for one item and "them" for several', (
      tester,
    ) async {
      await openSheet(tester);
      expect(find.text('You can restore it from the trash.'), findsOneWidget);
      Navigator.of(tester.element(find.text('Delete 1 item?'))).pop();
      await tester.pumpAndSettle();

      await openSheet(tester, count: 4);
      expect(find.text('You can restore them from the trash.'), findsOneWidget);
    });

    testWidgets('returns trash', (tester) async {
      final results = await openSheet(tester);
      await tester.tap(
        find.byKey(const ValueKey<String>('delete_choice_trash')),
      );
      await tester.pumpAndSettle();
      expect(results, <DeleteChoice?>[DeleteChoice.trash]);
    });

    testWidgets('returns permanent', (tester) async {
      final results = await openSheet(tester);
      await tester.tap(
        find.byKey(const ValueKey<String>('delete_choice_permanent')),
      );
      await tester.pumpAndSettle();
      expect(results, <DeleteChoice?>[DeleteChoice.permanent]);
    });

    testWidgets('says the file is written over when secure', (tester) async {
      await openSheet(tester, secureDelete: true);
      expect(
        find.text(
          'Written over, then removed from the device. This cannot be undone.',
        ),
        findsOneWidget,
      );
    });
  });

  group('deleteResultMessage', () {
    late AppLocalizations l10n;

    setUpAll(() async {
      l10n = await AppLocalizations.delegate.load(const Locale('en'));
    });

    test('nothing deleted', () {
      expect(
        deleteResultMessage(l10n, MediaDeleteResult.empty),
        'Nothing was deleted.',
      );
    });

    test('a clean secure delete', () {
      const result = MediaDeleteResult(
        deleted: 2,
        overwritten: 2,
        failed: 0,
        secure: true,
      );
      expect(deleteResultMessage(l10n, result), '2 items securely deleted.');
    });

    test('a secure delete that could not overwrite says so', () {
      const result = MediaDeleteResult(
        deleted: 3,
        overwritten: 2,
        failed: 1,
        secure: true,
      );
      expect(
        deleteResultMessage(l10n, result),
        '3 items deleted for good. 1 of them could not be written over first. '
        '1 item could not be deleted.',
      );
    });
  });
}
