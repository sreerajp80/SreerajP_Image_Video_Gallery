import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/l10n/sanskrit_fallback_delegates.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/widgets/home/manage_media_prompt_dialog.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Future<List<bool>> open(WidgetTester tester, {Locale? locale}) async {
    final results = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: locale ?? const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  results.add(await showManageMediaPromptDialog(context)),
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

  testWidgets('Open settings returns true', (tester) async {
    final results = await open(tester);
    expect(find.text('Allow Manage media?'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('manage_media_prompt_open')),
    );
    await tester.pumpAndSettle();
    expect(results, <bool>[true]);
  });

  testWidgets('Not now returns false', (tester) async {
    final results = await open(tester);
    await tester.tap(
      find.byKey(const ValueKey<String>('manage_media_prompt_not_now')),
    );
    await tester.pumpAndSettle();
    expect(results, <bool>[false]);
    expect(find.text('Allow Manage media?'), findsNothing);
  });

  for (final code in <String>['ml', 'sa']) {
    testWidgets('shows in $code without English', (tester) async {
      await open(tester, locale: Locale(code));
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Allow Manage media?'), findsNothing);
      expect(find.text('Not now'), findsNothing);
    });
  }
}
