import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:in_sreerajp_imgvidgal/core/l10n/formatting_locale.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/flashback_memory.dart';

/// Header above one year on the Memories tab.
///
/// The first line says how long ago ("3 years ago"); the second gives the
/// date, or the date range when the tab fell back to the week around today.
class MemorySectionHeader extends StatelessWidget {
  final FlashbackMemory memory;

  const MemorySectionHeader({super.key, required this.memory});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = formattingLocale(Localizations.localeOf(context));

    final title = memory.yearsAgo == 1
        ? l10n.labelFlashbackOneYearAgo
        : l10n.bodyFlashbackYearsAgo(memory.yearsAgo);
    final full = DateFormat.yMMMd(locale);
    final dateText = memory.isRange
        ? l10n.labelMemoryDateRange(
            memory.rangeStart.year == memory.rangeEnd.year
                ? DateFormat.MMMd(locale).format(memory.rangeStart)
                : full.format(memory.rangeStart),
            full.format(memory.rangeEnd),
          )
        : full.format(memory.date);

    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              dateText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
