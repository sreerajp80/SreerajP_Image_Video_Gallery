import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/help/help_topic.dart';
import 'package:in_sreerajp_imgvidgal/screens/help/help_topic_screen.dart';
import 'package:in_sreerajp_imgvidgal/widgets/help/help_topic_card.dart';

void main() {
  group('HelpTopicCard', () {
    testWidgets('renders topic info and reacts to taps', (tester) async {
      bool tapped = false;
      const topic = HelpTopic(
        id: 'timeline',
        icon: Icons.timeline,
        badge: HelpBadge.offline,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: HelpTopicCard(topic: topic, onTap: () => tapped = true),
          ),
        ),
      );

      expect(find.text('Timeline & Memories'), findsOneWidget);
      expect(find.byIcon(Icons.timeline), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);

      await tester.tap(find.byType(HelpTopicCard));
      expect(tapped, isTrue);
    });
  });

  group('HelpTopicScreen', () {
    testWidgets('renders all section titles and content cards', (tester) async {
      tester.view.physicalSize = const Size(1200, 3600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HelpTopicScreen(topicId: 'vault'),
        ),
      );

      expect(find.text('Secure Private Vault'), findsWidgets);
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('How to use'), findsOneWidget);
      expect(find.text('Tips & shortcuts'), findsOneWidget);
      expect(find.text('Privacy & offline guarantee'), findsOneWidget);
      expect(find.text('Hardware Encrypted'), findsOneWidget);
    });

    testWidgets('falls back to default topic for unknown id', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HelpTopicScreen(topicId: 'unknown_topic_id'),
        ),
      );

      expect(find.text('Timeline & Memories'), findsWidgets);
    });

    testWidgets('renders in Malayalam when locale is ml', (tester) async {
      tester.view.physicalSize = const Size(1200, 3600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('ml'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HelpTopicScreen(topicId: 'sync'),
        ),
      );

      expect(find.text('ലോക്കൽ വൈ-ഫൈ കൈമാറ്റം'), findsWidgets);
      expect(find.text('അവലോകനം'), findsOneWidget);
      expect(find.text('എങ്ങനെ ഉപയോഗിക്കാം'), findsOneWidget);
      expect(find.text('നുറുങ്ങുകളും കുറുക്കുവഴികളും'), findsOneWidget);
      expect(find.text('സ്വകാര്യതയും ഓഫ്‌ലൈൻ ഉറപ്പും'), findsOneWidget);
      expect(find.text('ലോക്കൽ വൈ-ഫൈ മാത്രം'), findsOneWidget);
    });
  });
}
