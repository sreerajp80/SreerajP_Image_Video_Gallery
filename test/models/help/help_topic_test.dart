import 'package:flutter_test/flutter_test.dart';
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
  });
}
