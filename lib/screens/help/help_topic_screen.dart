import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/help/help_topic.dart';

/// A detailed help page displaying guides, steps, tips, and privacy assurances
/// for one specific feature topic.
class HelpTopicScreen extends StatelessWidget {
  final String topicId;

  const HelpTopicScreen({super.key, required this.topicId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topic = HelpTopic.findById(topicId) ?? HelpTopic.all.first;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(topic.title(l10n))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: <Widget>[
          // Hero header card
          _HeaderCard(topic: topic),
          const SizedBox(height: 16),

          // Overview
          _SectionTitle(icon: Icons.info_outline, title: l10n.helpOverview),
          const SizedBox(height: 8),
          _ContentCard(
            content: topic.overview(l10n),
            iconColor: colorScheme.primary,
          ),
          const SizedBox(height: 20),

          // How to use
          _SectionTitle(
            icon: Icons.checklist_rtl_rounded,
            title: l10n.helpHowToUse,
          ),
          const SizedBox(height: 8),
          _ContentCard(
            content: topic.steps(l10n),
            iconColor: colorScheme.secondary,
          ),
          const SizedBox(height: 20),

          // Tips and shortcuts
          _SectionTitle(icon: Icons.lightbulb_outline, title: l10n.helpTips),
          const SizedBox(height: 8),
          _ContentCard(
            content: topic.tips(l10n),
            iconColor: colorScheme.tertiary,
          ),
          const SizedBox(height: 20),

          // Privacy & offline guarantees
          _SectionTitle(icon: Icons.shield_outlined, title: l10n.helpPrivacy),
          const SizedBox(height: 8),
          _PrivacyCard(content: topic.privacy(l10n)),
        ],
      ),
    );
  }
}

/// The hero card at the top of the help page displaying icon, title and badge.
class _HeaderCard extends StatelessWidget {
  final HelpTopic topic;

  const _HeaderCard({required this.topic});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primaryContainer.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(topic.icon, color: colorScheme.primary, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      topic.title(l10n),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer.withValues(
                          alpha: 0.8,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        topic.badgeLabel(l10n),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            topic.summary(l10n),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// A section heading with an icon and title text.
class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: <Widget>[
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

/// An informative content card presenting text.
class _ContentCard extends StatelessWidget {
  final String content;
  final Color iconColor;

  const _ContentCard({required this.content, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        content,
        style: theme.textTheme.bodyMedium?.copyWith(
          height: 1.5,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}

/// A specialized card for privacy guarantees.
class _PrivacyCard extends StatelessWidget {
  final String content;

  const _PrivacyCard({required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.tertiaryContainer.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.lock_clock_outlined,
            size: 20,
            color: colorScheme.tertiary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              content,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
