import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/providers/selection_providers.dart';
import 'package:in_sreerajp_imgvidgal/widgets/batch/selection_app_bar.dart';

void main() {
  testWidgets(
    'SelectionAppBar displays compare button when exactly 2 items selected',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Initial state: 1 item selected
      container.read(selectionProvider.notifier).toggle('item_1');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              appBar: SelectionAppBar(
                visibleIds: ['item_1', 'item_2', 'item_3'],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1 item selected: compare button should NOT be shown
      expect(find.byIcon(Icons.compare_arrows), findsNothing);

      // Select 2nd item: now 2 items selected
      container.read(selectionProvider.notifier).toggle('item_2');
      await tester.pumpAndSettle();

      // 2 items selected: compare button MUST be shown
      expect(find.byIcon(Icons.compare_arrows), findsOneWidget);

      // Select 3rd item: now 3 items selected
      container.read(selectionProvider.notifier).toggle('item_3');
      await tester.pumpAndSettle();

      // 3 items selected: compare button should NOT be shown
      expect(find.byIcon(Icons.compare_arrows), findsNothing);
    },
  );
}
