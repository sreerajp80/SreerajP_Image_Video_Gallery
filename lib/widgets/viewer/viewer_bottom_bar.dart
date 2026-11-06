import 'package:material_ui/material_ui.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';

/// The bottom bar with quick action buttons for images.
class ImageViewerBottomBar extends StatelessWidget {
  final MediaItem item;
  final VoidCallback onEdit;
  final VoidCallback onRotateLeft;
  final VoidCallback onRotateRight;
  final VoidCallback onShowDetails;
  final VoidCallback onMoveToTrash;
  final VoidCallback? onRestore;
  final VoidCallback? onDeletePermanently;

  const ImageViewerBottomBar({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onRotateLeft,
    required this.onRotateRight,
    required this.onShowDetails,
    required this.onMoveToTrash,
    this.onRestore,
    this.onDeletePermanently,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (item.isTrash) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black87, Colors.black54, Colors.transparent],
              stops: [0.0, 0.7, 1.0],
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.restore),
                      label: Text(l10n.actionTrashRestore),
                      onPressed: onRestore,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.delete_forever),
                      label: Text(l10n.titleTrashDeletePermanentlyAction),
                      onPressed: onDeletePermanently,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black87, Colors.black54, Colors.transparent],
            stops: [0.0, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            // Each action gets an equal share of the width, so longer
            // Malayalam and Sanskrit labels wrap instead of overflowing (G12).
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ViewerBottomAction(
                  icon: Icons.tune,
                  label: l10n.titleEditorOpen,
                  onPressed: onEdit,
                ),
                _ViewerBottomAction(
                  icon: Icons.rotate_left,
                  label: l10n.labelViewerRotateLeft,
                  onPressed: onRotateLeft,
                ),
                _ViewerBottomAction(
                  icon: Icons.rotate_right,
                  label: l10n.labelViewerRotateRight,
                  onPressed: onRotateRight,
                ),
                _ViewerBottomAction(
                  icon: Icons.info_outline,
                  label: l10n.tooltipDetailsTitle,
                  onPressed: onShowDetails,
                ),
                _ViewerBottomAction(
                  icon: Icons.delete_outline,
                  label: l10n.titleBatchActionMoveToTrash,
                  onPressed: onMoveToTrash,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Action item in the image viewer bottom bar.
class _ViewerBottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ViewerBottomAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black38,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
