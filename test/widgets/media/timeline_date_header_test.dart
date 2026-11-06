import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/timeline_group.dart';
import 'package:in_sreerajp_imgvidgal/widgets/media/timeline_date_header.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('shows the day count inside a filled pill', (tester) async {
    final theme = ThemeData(brightness: Brightness.dark);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: TimelineDateHeader(
            headerKind: TimelineHeaderKind.yesterday,
            date: DateTime(2026, 11, 4),
            itemCount: 7,
          ),
        ),
      ),
    );

    final count = find.text('7');
    expect(count, findsOneWidget);

    final pill = tester.widget<DecoratedBox>(
      find.ancestor(of: count, matching: find.byType(DecoratedBox)).first,
    );
    final decoration = pill.decoration as ShapeDecoration;
    expect(decoration.color, theme.colorScheme.secondaryContainer);

    final text = tester.widget<Text>(count);
    expect(text.style?.color, theme.colorScheme.onSecondaryContainer);
  });
}
