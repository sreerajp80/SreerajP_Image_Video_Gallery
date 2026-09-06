import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/timeline_group.dart';
import 'package:intl/intl.dart';

/// Turns a header kind and date into localized text.
///
/// Formatting lives here rather than in [TimelineGroupingService] because it
/// needs a locale, and services must not depend on `BuildContext`. If the
/// locale has no date patterns the plain ISO date is used, so a missing locale
/// never crashes the timeline.
String formatTimelineDate(
  BuildContext context,
  TimelineHeaderKind kind,
  DateTime date,
) {
  final l10n = AppLocalizations.of(context)!;

  switch (kind) {
    case TimelineHeaderKind.today:
      return l10n.timelineToday;
    case TimelineHeaderKind.yesterday:
      return l10n.timelineYesterday;
    case TimelineHeaderKind.dayThisYear:
    case TimelineHeaderKind.dayEarlierYear:
      final locale = Localizations.localeOf(context).toString();
      try {
        final format = kind == TimelineHeaderKind.dayThisYear
            ? DateFormat.MMMMd(locale)
            : DateFormat.yMMMMd(locale);
        return format.format(date);
      } catch (_) {
        return '${date.year}-'
            '${date.month.toString().padLeft(2, '0')}-'
            '${date.day.toString().padLeft(2, '0')}';
      }
  }
}

/// The date header drawn above each day of media in the timeline.
class TimelineDateHeader extends StatelessWidget {
  final TimelineHeaderKind headerKind;
  final DateTime date;

  /// Number of items in the day this header introduces.
  final int itemCount;

  const TimelineDateHeader({
    super.key,
    required this.headerKind,
    required this.date,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = formatTimelineDate(context, headerKind, date);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$itemCount',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
