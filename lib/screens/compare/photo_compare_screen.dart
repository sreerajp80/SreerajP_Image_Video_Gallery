import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/widgets/compare/compare_metadata_sheet.dart';
import 'package:in_sreerajp_imgvidgal/widgets/compare/curtain_comparison_view.dart';
import 'package:in_sreerajp_imgvidgal/widgets/compare/photo_selector_sheet.dart';
import 'package:in_sreerajp_imgvidgal/widgets/compare/split_comparison_view.dart';

/// Available visualization modes for photo comparison.
enum ComparisonMode { curtain, split }

/// Screen for comparing two photos side-by-side or using a sliding curtain,
/// with locked or independent synchronized pan and pinch-to-zoom.
class PhotoCompareScreen extends ConsumerStatefulWidget {
  final String firstMediaId;
  final String secondMediaId;

  const PhotoCompareScreen({
    super.key,
    required this.firstMediaId,
    required this.secondMediaId,
  });

  @override
  ConsumerState<PhotoCompareScreen> createState() => _PhotoCompareScreenState();
}

class _PhotoCompareScreenState extends ConsumerState<PhotoCompareScreen> {
  late String _mediaIdA;
  late String _mediaIdB;

  ComparisonMode _mode = ComparisonMode.curtain;
  bool _isSplitHorizontal = true;
  bool _isSynchronized = true;
  bool _showChrome = true;

  final TransformationController _curtainController =
      TransformationController();
  final TransformationController _splitControllerA = TransformationController();
  final TransformationController _splitControllerB = TransformationController();

  @override
  void initState() {
    super.initState();
    _mediaIdA = widget.firstMediaId;
    _mediaIdB = widget.secondMediaId;
  }

  @override
  void dispose() {
    _curtainController.dispose();
    _splitControllerA.dispose();
    _splitControllerB.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleChrome() {
    setState(() => _showChrome = !_showChrome);
    SystemChrome.setEnabledSystemUIMode(
      _showChrome ? SystemUiMode.edgeToEdge : SystemUiMode.immersive,
    );
  }

  void _resetZoom() {
    setState(() {
      _curtainController.value = Matrix4.identity();
      _splitControllerA.value = Matrix4.identity();
      _splitControllerB.value = Matrix4.identity();
    });
  }

  void _swapPhotos() {
    setState(() {
      final temp = _mediaIdA;
      _mediaIdA = _mediaIdB;
      _mediaIdB = temp;
    });
  }

  Future<void> _pickPhotoA() async {
    final picked = await PhotoSelectorSheet.show(
      context,
      excludeMediaId: _mediaIdB,
    );
    if (picked != null && mounted) {
      setState(() => _mediaIdA = picked.id);
    }
  }

  Future<void> _pickPhotoB() async {
    final picked = await PhotoSelectorSheet.show(
      context,
      excludeMediaId: _mediaIdA,
    );
    if (picked != null && mounted) {
      setState(() => _mediaIdB = picked.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final itemAsyncA = ref.watch(mediaItemProvider(_mediaIdA));
    final itemAsyncB = ref.watch(mediaItemProvider(_mediaIdB));

    final itemA = itemAsyncA.valueOrNull;
    final itemB = itemAsyncB.valueOrNull;

    if (itemAsyncA.isLoading || itemAsyncB.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (itemA == null || itemB == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            l10n.comparePhotosTitle,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        body: Center(
          child: Text(
            l10n.mediaUnavailable,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            // Center comparison viewport
            Positioned.fill(
              child: _mode == ComparisonMode.curtain
                  ? CurtainComparisonView(
                      itemA: itemA,
                      itemB: itemB,
                      transformationController: _curtainController,
                      onTap: _toggleChrome,
                      onResetZoom: _resetZoom,
                    )
                  : SplitComparisonView(
                      itemA: itemA,
                      itemB: itemB,
                      isHorizontal: _isSplitHorizontal,
                      isSynchronized: _isSynchronized,
                      controllerA: _splitControllerA,
                      controllerB: _splitControllerB,
                      onTap: _toggleChrome,
                    ),
            ),

            // Top App Bar Chrome
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              top: _showChrome ? 0 : -100,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _showChrome ? 1.0 : 0.0,
                child: _CompareAppBar(
                  title: l10n.comparePhotosTitle,
                  mode: _mode,
                  isSplitHorizontal: _isSplitHorizontal,
                  isSynchronized: _isSynchronized,
                  onToggleMode: () {
                    setState(() {
                      _mode = _mode == ComparisonMode.curtain
                          ? ComparisonMode.split
                          : ComparisonMode.curtain;
                      _resetZoom();
                    });
                  },
                  onToggleSplitOrientation: () {
                    setState(() {
                      _isSplitHorizontal = !_isSplitHorizontal;
                    });
                  },
                  onToggleSync: () {
                    setState(() {
                      _isSynchronized = !_isSynchronized;
                    });
                  },
                  onSwap: _swapPhotos,
                  onShowDetails: () {
                    CompareMetadataSheet.show(
                      context,
                      itemA: itemA,
                      itemB: itemB,
                    );
                  },
                  onResetZoom: _resetZoom,
                ),
              ),
            ),

            // Bottom Controller Tray
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              bottom: _showChrome ? 16 : -120,
              left: 16,
              right: 16,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _showChrome ? 1.0 : 0.0,
                child: _BottomControllerTray(
                  itemA: itemA,
                  itemB: itemB,
                  onPickA: _pickPhotoA,
                  onPickB: _pickPhotoB,
                  onSwap: _swapPhotos,
                  onResetZoom: _resetZoom,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompareAppBar extends StatelessWidget {
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

  const _CompareAppBar({
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
                tooltip: l10n.viewerClose,
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
                    ? l10n.compareModeSplit
                    : l10n.compareModeCurtain,
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
                      ? l10n.compareSplitVertical
                      : l10n.compareSplitHorizontal,
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
                      ? l10n.compareSyncLocked
                      : l10n.compareSyncUnlocked,
                  onPressed: onToggleSync,
                ),
              // Swap photos
              IconButton(
                icon: const Icon(Icons.swap_horiz, color: Colors.white),
                tooltip: l10n.compareSwap,
                onPressed: onSwap,
              ),
              // Compare details
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.white),
                tooltip: l10n.compareDetails,
                onPressed: onShowDetails,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomControllerTray extends StatelessWidget {
  final MediaItem itemA;
  final MediaItem itemB;
  final VoidCallback onPickA;
  final VoidCallback onPickB;
  final VoidCallback onSwap;
  final VoidCallback onResetZoom;

  const _BottomControllerTray({
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
              tooltip: l10n.compareSwap,
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
              tooltip: l10n.compareResetZoom,
              onPressed: onResetZoom,
            ),
          ],
        ),
      ),
    );
  }
}
