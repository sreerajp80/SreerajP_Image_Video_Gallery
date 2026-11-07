import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/widgets/common/adaptive_directionality.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';

/// The high-contrast bar across the top of the viewer.
class ViewerAppBar extends StatelessWidget {
  final MediaItem item;
  final VoidCallback onToggleFavorite;
  final VoidCallback onShowDetails;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onCompare;
  final VoidCallback onConvert;
  final VoidCallback onVideoTools;
  final VoidCallback onEditTags;
  final VoidCallback onAddToAlbum;
  final VoidCallback onMoveToVault;
  final VoidCallback onScanCodes;
  final VoidCallback onExtractText;
  final VoidCallback onOpenNotes;
  final VoidCallback onPrivacyScrubber;

  const ViewerAppBar({
    super.key,
    required this.item,
    required this.onToggleFavorite,
    required this.onShowDetails,
    required this.onDelete,
    required this.onEdit,
    required this.onCompare,
    required this.onConvert,
    required this.onVideoTools,
    required this.onEditTags,
    required this.onAddToAlbum,
    required this.onMoveToVault,
    required this.onScanCodes,
    required this.onExtractText,
    required this.onOpenNotes,
    required this.onPrivacyScrubber,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Align(
      alignment: Alignment.topCenter,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black87, Colors.black54, Colors.transparent],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 24),
            child: Row(
              children: [
                _ViewerCircleButton(
                  icon: Icons.arrow_back,
                  tooltip: l10n.tooltipViewerClose,
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      SystemNavigator.pop();
                    }
                  },
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: AdaptiveDirectionality(
                    text: item.displayName,
                    child: Text(
                      item.displayName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(color: Colors.black87, blurRadius: 8),
                          Shadow(blurRadius: 2),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                if (item.isTrash)
                  _ViewerCircleButton(
                    icon: Icons.info_outline,
                    tooltip: l10n.tooltipDetailsTitle,
                    onPressed: onShowDetails,
                  )
                else ...[
                  _ViewerCircleButton(
                    icon: item.isFavorite ? Icons.star : Icons.star_border,
                    color: item.isFavorite ? Colors.amber : Colors.white,
                    tooltip: item.isFavorite
                        ? l10n.bodyViewerRemoveFavorite
                        : l10n.labelViewerAddFavorite,
                    onPressed: onToggleFavorite,
                  ),
                  _ViewerCircleButton(
                    icon: Icons.shield_outlined,
                    tooltip: l10n.tooltipPrivacyScrubberTitle,
                    onPressed: onPrivacyScrubber,
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: const BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                    ),
                    child: PopupMenuButton<_ViewerMenuAction>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      tooltip: l10n.tooltipViewerMoreActions,
                      onSelected: (action) {
                        switch (action) {
                          case _ViewerMenuAction.edit:
                            onEdit();
                          case _ViewerMenuAction.compare:
                            onCompare();
                          case _ViewerMenuAction.scanCodes:
                            onScanCodes();
                          case _ViewerMenuAction.extractText:
                            onExtractText();
                          case _ViewerMenuAction.notes:
                            onOpenNotes();
                          case _ViewerMenuAction.convert:
                            onConvert();
                          case _ViewerMenuAction.videoTools:
                            onVideoTools();
                          case _ViewerMenuAction.editTags:
                            onEditTags();
                          case _ViewerMenuAction.addToAlbum:
                            onAddToAlbum();
                          case _ViewerMenuAction.moveToVault:
                            onMoveToVault();
                          case _ViewerMenuAction.privacyScrubber:
                            onPrivacyScrubber();
                          case _ViewerMenuAction.details:
                            onShowDetails();
                          case _ViewerMenuAction.trash:
                            onDelete();
                        }
                      },
                      itemBuilder: (context) =>
                          <PopupMenuEntry<_ViewerMenuAction>>[
                            PopupMenuItem<_ViewerMenuAction>(
                              value: _ViewerMenuAction.privacyScrubber,
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.shield_outlined),
                                title: Text(l10n.titlePrivacyScrubberMenu),
                              ),
                            ),
                            if (item.isVideo)
                              PopupMenuItem<_ViewerMenuAction>(
                                value: _ViewerMenuAction.videoTools,
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(
                                    Icons.movie_filter_outlined,
                                  ),
                                  title: Text(l10n.titleVideoToolsOpen),
                                ),
                              ),
                            PopupMenuItem<_ViewerMenuAction>(
                              value: _ViewerMenuAction.addToAlbum,
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.photo_album_outlined),
                                title: Text(l10n.titleAlbumPicker),
                              ),
                            ),
                            PopupMenuItem<_ViewerMenuAction>(
                              value: _ViewerMenuAction.editTags,
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.label_outline),
                                title: Text(l10n.titleTagSheetOpen),
                              ),
                            ),
                            PopupMenuItem<_ViewerMenuAction>(
                              value: _ViewerMenuAction.moveToVault,
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.lock_outline),
                                title: Text(l10n.titleVaultMoveToVault),
                              ),
                            ),
                            if (item.isImage) ...<
                              PopupMenuEntry<_ViewerMenuAction>
                            >[
                              PopupMenuItem<_ViewerMenuAction>(
                                value: _ViewerMenuAction.compare,
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.compare_arrows),
                                  title: Text(l10n.titleComparePhotos),
                                ),
                              ),
                              PopupMenuItem<_ViewerMenuAction>(
                                value: _ViewerMenuAction.convert,
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.transform),
                                  title: Text(l10n.titleConvertOpen),
                                ),
                              ),
                            ],
                            if (item.isImage) ...<
                              PopupMenuEntry<_ViewerMenuAction>
                            >[
                              PopupMenuItem<_ViewerMenuAction>(
                                value: _ViewerMenuAction.scanCodes,
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(
                                    Icons.qr_code_scanner_outlined,
                                  ),
                                  title: Text(l10n.titleCodeScanOpen),
                                ),
                              ),
                              PopupMenuItem<_ViewerMenuAction>(
                                value: _ViewerMenuAction.extractText,
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(
                                    Icons.text_fields_outlined,
                                  ),
                                  title: Text(l10n.titleOcrOpen),
                                ),
                              ),
                            ],
                            PopupMenuItem<_ViewerMenuAction>(
                              value: _ViewerMenuAction.notes,
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.sticky_note_2_outlined,
                                ),
                                title: Text(l10n.titleNotesOpen),
                              ),
                            ),
                            if (item.isVideo) ...[
                              const PopupMenuDivider(),
                              PopupMenuItem<_ViewerMenuAction>(
                                value: _ViewerMenuAction.details,
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.info_outline),
                                  title: Text(l10n.tooltipDetailsTitle),
                                ),
                              ),
                              PopupMenuItem<_ViewerMenuAction>(
                                value: _ViewerMenuAction.trash,
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.delete_outline),
                                  title: Text(l10n.titleBatchActionDelete),
                                ),
                              ),
                            ],
                          ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Circular button with high-contrast background for viewer chrome.
class _ViewerCircleButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final String tooltip;
  final VoidCallback onPressed;

  const _ViewerCircleButton({
    required this.icon,
    this.color,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(
        color: Colors.black38,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color ?? Colors.white),
        tooltip: tooltip,
      ),
    );
  }
}

/// What the viewer's overflow menu can do.
enum _ViewerMenuAction {
  edit,
  compare,
  scanCodes,
  extractText,
  notes,
  convert,
  videoTools,
  editTags,
  addToAlbum,
  moveToVault,
  privacyScrubber,
  details,
  trash,
}
