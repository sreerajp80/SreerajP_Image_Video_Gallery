import 'package:in_sreerajp_imgvidgal/models/batch/batch_action.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/conversion_request.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/pdf_export_options.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/watermark_config.dart';

/// What a batch action needs beyond the selection itself.
///
/// Gathered by the action bar before the batch starts — which tags, which
/// album, which output format — so the runner never has to stop half way and
/// ask. A batch that paused for a dialog on file seventeen would be a batch
/// nobody could walk away from.
class BatchOptions {
  /// Tag ids for [BatchAction.addTags] and [BatchAction.removeTags].
  final Set<String> tagIds;

  /// Album id for [BatchAction.addToAlbum].
  final String? albumId;

  /// Output settings for [BatchAction.convert].
  final ConversionRequest conversion;

  /// The stamp for [BatchAction.watermark].
  final WatermarkConfig watermark;

  /// Page settings for [BatchAction.exportPdf].
  final PdfExportOptions pdf;

  /// Whether a vault import shreds the originals.
  ///
  /// Off unless the user chose it and confirmed it, exactly as in the vault
  /// screen: it destroys a file for good.
  final bool shredOriginals;

  const BatchOptions({
    this.tagIds = const <String>{},
    this.albumId,
    this.conversion = const ConversionRequest(),
    this.watermark = const WatermarkConfig(),
    this.pdf = const PdfExportOptions(),
    this.shredOriginals = false,
  });
}
