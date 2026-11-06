import 'package:material_ui/material_ui.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';

/// The spoken name of a palette colour, or null when it has none.
///
/// Covers the tag palette and the markup pen colours. A colour is never shown
/// by its look alone: the screen reader says this name (standard §7.2).
String? colorName(AppLocalizations l10n, int argb) => switch (argb) {
  0xFFEF5350 || 0xFFFF3B30 => l10n.labelColorRed,
  0xFFEC407A => l10n.labelColorPink,
  0xFFAB47BC => l10n.labelColorPurple,
  0xFF7E57C2 => l10n.labelColorDeepPurple,
  0xFF5C6BC0 => l10n.labelColorIndigo,
  0xFF42A5F5 || 0xFF007AFF => l10n.labelColorBlue,
  0xFF26A69A => l10n.labelColorTeal,
  0xFF66BB6A || 0xFF34C759 => l10n.labelColorGreen,
  0xFF9CCC65 => l10n.labelColorLightGreen,
  0xFFFFCA28 => l10n.labelColorAmber,
  0xFFFF7043 => l10n.labelColorDeepOrange,
  0xFF8D6E63 => l10n.labelColorBrown,
  0xFFFFCC00 => l10n.labelColorYellow,
  0xFFFFFFFF => l10n.labelColorWhite,
  0xFF000000 => l10n.labelColorBlack,
  _ => null,
};

/// A tappable colour choice with a 48 x 48 dp hit area (standard §7.1).
///
/// [child] is the visible dot, which may be smaller. The screen reader hears
/// the colour's name and whether it is the selected one.
class ColorSwatchButton extends StatelessWidget {
  final int argb;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  const ColorSwatchButton({
    super.key,
    required this.argb,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  /// The smallest hit area on a phone.
  static const double minTarget = 48;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      selected: selected,
      label: colorName(l10n, argb),
      child: InkResponse(
        onTap: onTap,
        radius: minTarget / 2,
        child: SizedBox.square(
          dimension: minTarget,
          child: Center(child: ExcludeSemantics(child: child)),
        ),
      ),
    );
  }
}
