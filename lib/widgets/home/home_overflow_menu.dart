import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:in_sreerajp_imgvidgal/core/routing/app_router.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';

/// The ⋮ menu shown in the top bar of every home tab, folder and album.
///
/// Each of those screens builds its own top bar. They all use this one
/// widget, so Settings and the other tools can be reached from any of them,
/// and the screens cannot drift apart when an item is added later.
///
/// Tags, the cleaner and the rest live here rather than in the bar itself:
/// they are used now and then, unlike search, and a crowded bar helps nobody.
///
/// A screen with its own actions (a user album: rename, cover...) passes
/// them as [extraItems]. They are shown first, above a divider, so one bar
/// never holds two ⋮ buttons. Their values must not be one of the shared
/// routes; picking one calls [onExtraSelected] instead of navigating.
class HomeOverflowMenu extends StatelessWidget {
  /// Screen-specific items, shown above the shared ones.
  final List<PopupMenuEntry<String>> extraItems;

  /// Called with the value of a picked item from [extraItems].
  final ValueChanged<String>? onExtraSelected;

  const HomeOverflowMenu({
    super.key,
    this.extraItems = const <PopupMenuEntry<String>>[],
    this.onExtraSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final entries = <(String, IconData, String)>[
      (kRouteTags, Icons.label_outline, l10n.titleTagsOpen),
      (kRouteCleaner, Icons.copy_all_outlined, l10n.titleCleanerOpen),
      (kRouteTrash, Icons.delete_outline, l10n.titleTrash),
      (kRouteVault, Icons.lock_outline, l10n.titleVaultMenuLabel),
      (kRouteSync, Icons.send_to_mobile_outlined, l10n.titleSyncOpen),
      (kRoutePdfImages, Icons.image_search_outlined, l10n.titlePdfImagesOpen),
      (kRouteBackup, Icons.backup_outlined, l10n.titleBackupOpen),
      (kRouteSettings, Icons.settings_outlined, l10n.titleSettings),
    ];
    final routes = <String>{for (final (route, _, _) in entries) route};

    return PopupMenuButton<String>(
      onSelected: (value) {
        if (routes.contains(value)) {
          context.push(value);
        } else {
          onExtraSelected?.call(value);
        }
      },
      itemBuilder: (context) => <PopupMenuEntry<String>>[
        ...extraItems,
        if (extraItems.isNotEmpty) const PopupMenuDivider(),
        for (final (route, icon, label) in entries)
          PopupMenuItem<String>(
            value: route,
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(icon),
              title: Text(label),
            ),
          ),
      ],
    );
  }
}
