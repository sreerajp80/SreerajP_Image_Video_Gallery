import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';

/// The privacy or assurance badge displayed in a help topic's header.
enum HelpBadge { offline, encrypted, local, safe }

/// An immutable definition of a help topic covering a feature of the gallery.
class HelpTopic {
  final String id;
  final IconData icon;
  final HelpBadge badge;

  const HelpTopic({required this.id, required this.icon, required this.badge});

  /// The localized title of this topic.
  String title(AppLocalizations l10n) {
    switch (id) {
      case 'timeline':
        return l10n.helpTopicTimelineTitle;
      case 'viewer':
        return l10n.helpTopicViewerTitle;
      case 'editor':
        return l10n.helpTopicEditorTitle;
      case 'converter':
        return l10n.helpTopicConverterTitle;
      case 'pdf':
        return l10n.helpTopicPdfTitle;
      case 'search':
        return l10n.helpTopicSearchTitle;
      case 'albums':
        return l10n.helpTopicAlbumsTitle;
      case 'cleaner':
        return l10n.helpTopicCleanerTitle;
      case 'vault':
        return l10n.helpTopicVaultTitle;
      case 'sync':
        return l10n.helpTopicSyncTitle;
      case 'backup':
        return l10n.helpTopicBackupTitle;
      case 'scanner':
        return l10n.helpTopicScannerTitle;
      default:
        return id;
    }
  }

  /// A single-sentence summary of the topic.
  String summary(AppLocalizations l10n) {
    switch (id) {
      case 'timeline':
        return l10n.helpTopicTimelineSummary;
      case 'viewer':
        return l10n.helpTopicViewerSummary;
      case 'editor':
        return l10n.helpTopicEditorSummary;
      case 'converter':
        return l10n.helpTopicConverterSummary;
      case 'pdf':
        return l10n.helpTopicPdfSummary;
      case 'search':
        return l10n.helpTopicSearchSummary;
      case 'albums':
        return l10n.helpTopicAlbumsSummary;
      case 'cleaner':
        return l10n.helpTopicCleanerSummary;
      case 'vault':
        return l10n.helpTopicVaultSummary;
      case 'sync':
        return l10n.helpTopicSyncSummary;
      case 'backup':
        return l10n.helpTopicBackupSummary;
      case 'scanner':
        return l10n.helpTopicScannerSummary;
      default:
        return '';
    }
  }

  /// A detailed paragraph explaining what the feature does.
  String overview(AppLocalizations l10n) {
    switch (id) {
      case 'timeline':
        return l10n.helpTopicTimelineOverview;
      case 'viewer':
        return l10n.helpTopicViewerOverview;
      case 'editor':
        return l10n.helpTopicEditorOverview;
      case 'converter':
        return l10n.helpTopicConverterOverview;
      case 'pdf':
        return l10n.helpTopicPdfOverview;
      case 'search':
        return l10n.helpTopicSearchOverview;
      case 'albums':
        return l10n.helpTopicAlbumsOverview;
      case 'cleaner':
        return l10n.helpTopicCleanerOverview;
      case 'vault':
        return l10n.helpTopicVaultOverview;
      case 'sync':
        return l10n.helpTopicSyncOverview;
      case 'backup':
        return l10n.helpTopicBackupOverview;
      case 'scanner':
        return l10n.helpTopicScannerOverview;
      default:
        return '';
    }
  }

  /// Bullet points or steps guiding the user through using the feature.
  String steps(AppLocalizations l10n) {
    switch (id) {
      case 'timeline':
        return l10n.helpTopicTimelineSteps;
      case 'viewer':
        return l10n.helpTopicViewerSteps;
      case 'editor':
        return l10n.helpTopicEditorSteps;
      case 'converter':
        return l10n.helpTopicConverterSteps;
      case 'pdf':
        return l10n.helpTopicPdfSteps;
      case 'search':
        return l10n.helpTopicSearchSteps;
      case 'albums':
        return l10n.helpTopicAlbumsSteps;
      case 'cleaner':
        return l10n.helpTopicCleanerSteps;
      case 'vault':
        return l10n.helpTopicVaultSteps;
      case 'sync':
        return l10n.helpTopicSyncSteps;
      case 'backup':
        return l10n.helpTopicBackupSteps;
      case 'scanner':
        return l10n.helpTopicScannerSteps;
      default:
        return '';
    }
  }

  /// Useful shortcuts, gestures, and pro-tips.
  String tips(AppLocalizations l10n) {
    switch (id) {
      case 'timeline':
        return l10n.helpTopicTimelineTips;
      case 'viewer':
        return l10n.helpTopicViewerTips;
      case 'editor':
        return l10n.helpTopicEditorTips;
      case 'converter':
        return l10n.helpTopicConverterTips;
      case 'pdf':
        return l10n.helpTopicPdfTips;
      case 'search':
        return l10n.helpTopicSearchTips;
      case 'albums':
        return l10n.helpTopicAlbumsTips;
      case 'cleaner':
        return l10n.helpTopicCleanerTips;
      case 'vault':
        return l10n.helpTopicVaultTips;
      case 'sync':
        return l10n.helpTopicSyncTips;
      case 'backup':
        return l10n.helpTopicBackupTips;
      case 'scanner':
        return l10n.helpTopicScannerTips;
      default:
        return '';
    }
  }

  /// The offline and privacy guarantee for this feature.
  String privacy(AppLocalizations l10n) {
    switch (id) {
      case 'timeline':
        return l10n.helpTopicTimelinePrivacy;
      case 'viewer':
        return l10n.helpTopicViewerPrivacy;
      case 'editor':
        return l10n.helpTopicEditorPrivacy;
      case 'converter':
        return l10n.helpTopicConverterPrivacy;
      case 'pdf':
        return l10n.helpTopicPdfPrivacy;
      case 'search':
        return l10n.helpTopicSearchPrivacy;
      case 'albums':
        return l10n.helpTopicAlbumsPrivacy;
      case 'cleaner':
        return l10n.helpTopicCleanerPrivacy;
      case 'vault':
        return l10n.helpTopicVaultPrivacy;
      case 'sync':
        return l10n.helpTopicSyncPrivacy;
      case 'backup':
        return l10n.helpTopicBackupPrivacy;
      case 'scanner':
        return l10n.helpTopicScannerPrivacy;
      default:
        return '';
    }
  }

  /// Returns the localized label for this topic's badge.
  String badgeLabel(AppLocalizations l10n) {
    switch (badge) {
      case HelpBadge.offline:
        return l10n.helpBadgeOffline;
      case HelpBadge.encrypted:
        return l10n.helpBadgeEncrypted;
      case HelpBadge.local:
        return l10n.helpBadgeLocal;
      case HelpBadge.safe:
        return l10n.helpBadgeSafe;
    }
  }

  /// All 12 comprehensive topics covering every capability of the gallery.
  static const List<HelpTopic> all = <HelpTopic>[
    HelpTopic(
      id: 'timeline',
      icon: Icons.timeline_outlined,
      badge: HelpBadge.offline,
    ),
    HelpTopic(
      id: 'viewer',
      icon: Icons.photo_size_select_actual_outlined,
      badge: HelpBadge.offline,
    ),
    HelpTopic(
      id: 'editor',
      icon: Icons.auto_fix_high_outlined,
      badge: HelpBadge.safe,
    ),
    HelpTopic(
      id: 'converter',
      icon: Icons.transform_outlined,
      badge: HelpBadge.safe,
    ),
    HelpTopic(
      id: 'pdf',
      icon: Icons.picture_as_pdf_outlined,
      badge: HelpBadge.offline,
    ),
    HelpTopic(
      id: 'search',
      icon: Icons.search_outlined,
      badge: HelpBadge.offline,
    ),
    HelpTopic(
      id: 'albums',
      icon: Icons.photo_album_outlined,
      badge: HelpBadge.offline,
    ),
    HelpTopic(
      id: 'cleaner',
      icon: Icons.cleaning_services_outlined,
      badge: HelpBadge.safe,
    ),
    HelpTopic(
      id: 'vault',
      icon: Icons.lock_outline,
      badge: HelpBadge.encrypted,
    ),
    HelpTopic(
      id: 'sync',
      icon: Icons.wifi_tethering_outlined,
      badge: HelpBadge.local,
    ),
    HelpTopic(
      id: 'backup',
      icon: Icons.backup_outlined,
      badge: HelpBadge.encrypted,
    ),
    HelpTopic(
      id: 'scanner',
      icon: Icons.document_scanner_outlined,
      badge: HelpBadge.offline,
    ),
  ];

  /// Finds a topic by its id, or returns null if not found.
  static HelpTopic? findById(String id) {
    for (final topic in all) {
      if (topic.id == id) return topic;
    }
    return null;
  }
}
