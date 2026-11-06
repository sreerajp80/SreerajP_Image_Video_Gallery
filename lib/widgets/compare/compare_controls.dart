import 'package:material_ui/material_ui.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';

/// Available visualization modes for photo comparison.
enum ComparisonMode { curtain, split }

/// Top bar of the compare screen: title, mode, split, sync, swap and zoom reset.
class CompareAppBar extends StatelessWidget {
  final String title;
  final ComparisonMode mode;
  final bool isSplitHorizontal;
  final bool isSynchronized;
  final VoidCallback onToggleMode;
  final VoidCallback onToggleSplitOrientation;
  final VoidCallback onToggleSync;
  final VoidCallback onSwap;
  final VoidCallback onShowDetails;
  final VoidCallback onResetZoom;

  const CompareAppBar({
    super.key,
    required this.title,
    required this.mode,
    required this.isSplitHorizontal,
    required this.isSynchronized,
    required this.onToggleMode,
    required this.onToggleSplitOrientation,
    required this.onToggleSync,
    required this.onSwap,
    required this.onShowDetails,
    required this.onResetZoom,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.black54, Colors.transparent],
          stops: [0.0, 0.7, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                tooltip: l10n.tooltipViewerClose,
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Switch mode (Curtain vs Split)
              IconButton(
                icon: Icon(
                  mode == ComparisonMode.curtain
                      ? Icons.splitscreen
                      : Icons.compare,
                  color: Colors.white,
                ),
                tooltip: mode == ComparisonMode.curtain
                    ? l10n.labelCompareModeSplit
                    : l10n.labelCompareModeCurtain,
                onPressed: onToggleMode,
              ),
              // In split mode: toggle split orientation
              if (mode == ComparisonMode.split)
                IconButton(
                  icon: Icon(
                    isSplitHorizontal
                        ? Icons.view_agenda_outlined
                        : Icons.view_column_outlined,
                    color: Colors.white,
                  ),
                  tooltip: isSplitHorizontal
                      ? l10n.labelCompareSplitVertical
                      : l10n.labelCompareSplitHorizontal,
                  onPressed: onToggleSplitOrientation,
                ),
              // Synchronize lock toggle (in split mode)
              if (mode == ComparisonMode.split)
                IconButton(
                  icon: Icon(
                    isSynchronized ? Icons.lock : Icons.lock_open,
                    color: isSynchronized ? Colors.amber : Colors.white70,
                  ),
                  tooltip: isSynchronized
                      ? l10n.bodyCompareSyncLocked
                      : l10n.bodyCompareSyncUnlocked,
                  onPressed: onToggleSync,
                ),
              // Swap photos
              IconButton(
                icon: const Icon(Icons.swap_horiz, color: Colors.white),
                tooltip: l10n.tooltipCompareSwap,
                onPressed: onSwap,
              ),
              // Compare details
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.white),
                tooltip: l10n.tooltipCompareDetails,
                onPressed: onShowDetails,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom tray of the compare screen: pick either photo, swap, reset zoom.
class CompareControllerTray extends StatelessWidget {
  final MediaItem itemA;
  final MediaItem itemB;
  final VoidCallback onPickA;
  final VoidCallback onPickB;
  final VoidCallback onSwap;
  final VoidCallback onResetZoom;

  const CompareControllerTray({
    super.key,
    required this.itemA,
    required this.itemB,
    required this.onPickA,
    required this.onPickB,
    required this.onSwap,
    required this.onResetZoom,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: Colors.black.withValues(alpha: 0.75),
      borderRadius: BorderRadius.circular(16),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Photo A chip
            Expanded(
              child: InkWell(
                onTap: onPickA,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.35,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'A',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          itemA.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Icon(Icons.edit, size: 14, color: Colors.white70),
                    ],
                  ),
                ),
              ),
            ),
            // Swap icon
            IconButton(
              icon: const Icon(
                Icons.swap_horiz,
                color: Colors.white70,
                size: 20,
              ),
              tooltip: l10n.tooltipCompareSwap,
              onPressed: onSwap,
            ),
            // Photo B chip
            Expanded(
              child: InkWell(
                onTap: onPickB,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer.withValues(
                      alpha: 0.35,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'B',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          itemB.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Icon(Icons.edit, size: 14, color: Colors.white70),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Reset Zoom button
            IconButton(
              icon: const Icon(
                Icons.fit_screen_outlined,
                color: Colors.white,
                size: 22,
              ),
              tooltip: l10n.tooltipCompareResetZoom,
              onPressed: onResetZoom,
            ),
          ],
        ),
      ),
    );
  }
}
