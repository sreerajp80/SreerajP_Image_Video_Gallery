import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/l10n/sanskrit_fallback_delegates.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/help/help_topic.dart';
import 'package:in_sreerajp_imgvidgal/widgets/help/help_topic_presentation.dart';

void main() {
  group('HelpTopicPresentation', () {
    test('every topic has its own icon, not the fallback', () {
      final icons = HelpTopic.all.map((t) => t.icon).toList();
      expect(icons, isNot(contains(Icons.help_outline)));
      expect(icons.toSet().length, HelpTopic.all.length);
    });

    for (final locale in const <Locale>[
      Locale('en'),
      Locale('ml'),
      Locale('sa'),
    ]) {
      testWidgets('all text is filled in ${locale.languageCode}', (
        tester,
      ) async {
        late AppLocalizations l10n;

        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) {
                l10n = AppLocalizations.of(context)!;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        for (final topic in HelpTopic.all) {
          expect(topic.title(l10n), isNot(topic.id));
          expect(topic.summary(l10n), isNotEmpty);
          expect(topic.overview(l10n), isNotEmpty);
          expect(topic.steps(l10n), isNotEmpty);
          expect(topic.tips(l10n), isNotEmpty);
          expect(topic.privacy(l10n), isNotEmpty);
          expect(topic.badgeLabel(l10n), isNotEmpty);
        }
      });
    }
  });
}
