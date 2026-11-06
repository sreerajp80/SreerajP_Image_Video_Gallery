import 'package:material_ui/material_ui.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/timeline_group.dart';
import 'package:intl/intl.dart';
import 'package:in_sreerajp_imgvidgal/core/l10n/formatting_locale.dart';

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
      return l10n.labelTimelineToday;
    case TimelineHeaderKind.yesterday:
      return l10n.labelTimelineYesterday;
    case TimelineHeaderKind.dayThisYear:
    case TimelineHeaderKind.dayEarlierYear:
      final locale = formattingLocale(Localizations.localeOf(context));
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
          // A filled pill in theme colours, so the count stays readable on
          // both light and dark backgrounds.
          DecoratedBox(
            decoration: ShapeDecoration(
              color: theme.colorScheme.secondaryContainer,
              shape: const StadiumBorder(),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Text(
                '$itemCount',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
