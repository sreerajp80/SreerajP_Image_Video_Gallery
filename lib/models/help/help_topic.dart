/// The privacy or assurance badge displayed in a help topic's header.
enum HelpBadge { offline, encrypted, local, safe }

/// An immutable definition of a help topic covering a feature of the gallery.
///
/// This is plain data. The icon and the localized text for a topic live in
/// `HelpTopicPresentation` (`lib/widgets/help/help_topic_presentation.dart`),
/// because a model must not depend on Flutter UI types.
class HelpTopic {
  final String id;
  final HelpBadge badge;

  const HelpTopic({required this.id, required this.badge});

  /// All 12 comprehensive topics covering every capability of the gallery.
  static const List<HelpTopic> all = <HelpTopic>[
    HelpTopic(id: 'timeline', badge: HelpBadge.offline),
    HelpTopic(id: 'viewer', badge: HelpBadge.offline),
    HelpTopic(id: 'editor', badge: HelpBadge.safe),
    HelpTopic(id: 'converter', badge: HelpBadge.safe),
    HelpTopic(id: 'pdf', badge: HelpBadge.offline),
    HelpTopic(id: 'search', badge: HelpBadge.offline),
    HelpTopic(id: 'albums', badge: HelpBadge.offline),
    HelpTopic(id: 'cleaner', badge: HelpBadge.safe),
    HelpTopic(id: 'vault', badge: HelpBadge.encrypted),
    HelpTopic(id: 'sync', badge: HelpBadge.local),
    HelpTopic(id: 'backup', badge: HelpBadge.encrypted),
    HelpTopic(id: 'scanner', badge: HelpBadge.offline),
  ];

  /// Finds a topic by its id, or returns null if not found.
  static HelpTopic? findById(String id) {
    for (final topic in all) {
      if (topic.id == id) return topic;
    }
    return null;
  }
}
