import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/help/help_topic.dart';

void main() {
  group('HelpTopic model', () {
    test('defines 12 comprehensive topics', () {
      expect(HelpTopic.all.length, 12);
    });

    test('every topic has a unique id', () {
      final ids = HelpTopic.all.map((t) => t.id).toSet();
      expect(ids.length, HelpTopic.all.length);
    });

    test('findById returns matching topic', () {
      final topic = HelpTopic.findById('timeline');
      expect(topic, isNotNull);
      expect(topic!.id, 'timeline');
      expect(topic.badge, HelpBadge.offline);
    });

    test('findById returns null for unknown topic id', () {
      expect(HelpTopic.findById('non_existent'), isNull);
    });

    testWidgets('all getters return non-empty strings in English', (
      tester,
    ) async {
      late AppLocalizations l10n;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
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
        expect(topic.title(l10n), isNotEmpty);
        expect(topic.summary(l10n), isNotEmpty);
        expect(topic.overview(l10n), isNotEmpty);
        expect(topic.steps(l10n), isNotEmpty);
        expect(topic.tips(l10n), isNotEmpty);
        expect(topic.privacy(l10n), isNotEmpty);
        expect(topic.badgeLabel(l10n), isNotEmpty);
      }
    });

    testWidgets('all getters return non-empty strings in Malayalam', (
      tester,
    ) async {
      late AppLocalizations l10n;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ml'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
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
        expect(topic.title(l10n), isNotEmpty);
        expect(topic.summary(l10n), isNotEmpty);
        expect(topic.overview(l10n), isNotEmpty);
        expect(topic.steps(l10n), isNotEmpty);
        expect(topic.tips(l10n), isNotEmpty);
        expect(topic.privacy(l10n), isNotEmpty);
        expect(topic.badgeLabel(l10n), isNotEmpty);
      }
    });
  });
}
