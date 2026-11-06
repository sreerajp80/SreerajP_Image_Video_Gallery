import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/widgets/compare/compare_metadata_sheet.dart';
import 'package:in_sreerajp_imgvidgal/widgets/compare/curtain_comparison_view.dart';
import 'package:in_sreerajp_imgvidgal/widgets/compare/photo_selector_sheet.dart';
import 'package:in_sreerajp_imgvidgal/widgets/compare/split_comparison_view.dart';
import 'package:in_sreerajp_imgvidgal/widgets/compare/compare_controls.dart';

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

    final itemA = itemAsyncA.value;
    final itemB = itemAsyncB.value;

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
          // BackButton carries the framework's localized "Back" tooltip.
          leading: const BackButton(color: Colors.white),
          title: Text(
            l10n.titleComparePhotos,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        body: Center(
          child: Text(
            l10n.labelMediaUnavailable,
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
                child: CompareAppBar(
                  title: l10n.titleComparePhotos,
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
                child: CompareControllerTray(
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
