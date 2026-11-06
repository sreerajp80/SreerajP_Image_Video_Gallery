import 'package:material_ui/material_ui.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';

/// The fixed "Made with ❤️ from India" badge at the bottom of the About
/// screen (`docs/guidelines/guideline.md` §1.7). The words are localized; the
/// heart is always the same red vector icon.
class MadeWithLove extends StatelessWidget {
  const MadeWithLove({super.key});

  static const Color _heartColor = Color(0xFFE53935);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final base = theme.textTheme.bodySmall!.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    // Split the localized text around the {heart} placeholder so the heart
    // keeps its own colour in every language. The sentinel can never appear
    // in translated text, so the split is exact.
    const sentinel = '\u0000';
    final parts = l10n.madeWithLove(sentinel).split(sentinel);

    return Semantics(
      label: l10n.madeWithLoveA11y,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(text: parts.first, style: base),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Icon(
                    Icons.favorite,
                    size: (base.fontSize ?? 12) * 1.1,
                    color: _heartColor,
                  ),
                ),
                TextSpan(text: parts.length > 1 ? parts[1] : '', style: base),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
