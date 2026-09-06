import 'dart:typed_data';

import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/batch/batch_action.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/conversion_request.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/pdf_export_options.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/edit_session.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/watermark_config.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/album_repository.dart';
import 'package:in_sreerajp_imgvidgal/repositories/media_repository.dart';
import 'package:in_sreerajp_imgvidgal/repositories/tag_repository.dart';
import 'package:in_sreerajp_imgvidgal/services/batch/batch_runner_service.dart';
import 'package:in_sreerajp_imgvidgal/services/convert/format_conversion_service.dart';
import 'package:in_sreerajp_imgvidgal/services/convert/output_naming_service.dart';
import 'package:in_sreerajp_imgvidgal/services/convert/pdf_export_service.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/image_render_pipeline.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_import_service.dart';

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

/// Does the actual work behind each batch action.
///
/// Every method here is a thin call into a service built in an earlier phase.
/// Nothing new is implemented: converting a photo is Phase 7's job, stamping
/// one is Phase 6's, and encrypting one is Phase 10's. Putting a second copy
/// of any of that here would mean the batch and the single-file screen could
/// start behaving differently, which is the bug this class exists to avoid.
class GalleryBatchHandler extends BatchItemHandler {
  final MediaRepository _mediaRepository;
  final TagRepository _tagRepository;
  final AlbumRepository _albumRepository;
  final VaultImportService _vaultImport;
  final FormatConversionService _conversion;
  final PdfExportService _pdfExport;
  final ImageRenderPipeline _pipeline;
  final OutputNamingService _naming;

  /// What the user chose before the batch started.
  final BatchOptions options;

  GalleryBatchHandler({
    required MediaRepository mediaRepository,
    required TagRepository tagRepository,
    required AlbumRepository albumRepository,
    required VaultImportService vaultImport,
    required FormatConversionService conversion,
    required PdfExportService pdfExport,
    this.options = const BatchOptions(),
    ImageRenderPipeline pipeline = const ImageRenderPipeline(),
    OutputNamingService naming = const OutputNamingService(),
  }) : _mediaRepository = mediaRepository,
       _tagRepository = tagRepository,
       _albumRepository = albumRepository,
       _vaultImport = vaultImport,
       _conversion = conversion,
       _pdfExport = pdfExport,
       _pipeline = pipeline,
       _naming = naming;

  /// The PDF export is the one action that makes a single thing out of many.
  @override
  bool isWholeBatch(BatchAction action) => action == BatchAction.exportPdf;

  @override
  Future<List<String>> begin(BatchAction action, List<MediaItem> items) async {
    if (action != BatchAction.exportPdf) return const <String>[];

    final result = await _pdfExport.export(
      imagePaths: items
          .map((item) => item.path)
          .where((path) => path.isNotEmpty)
          .toList(growable: false),
      options: options.pdf,
    );
    return <String>[result.path];
  }

  @override
  Future<String?> handle(BatchAction action, MediaItem item) async {
    switch (action) {
      case BatchAction.convert:
        return _convert(item);

      case BatchAction.watermark:
        return _watermark(item);

      case BatchAction.addTags:
        for (final tagId in options.tagIds) {
          await _tagRepository.addTagToMedia(item.id, tagId);
        }
        return null;

      case BatchAction.removeTags:
        for (final tagId in options.tagIds) {
          await _tagRepository.removeTagFromMedia(item.id, tagId);
        }
        return null;

      case BatchAction.addToAlbum:
        final albumId = options.albumId;
        if (albumId == null) return null;
        await _albumRepository.addMedia(albumId, item.id);
        return null;

      case BatchAction.favourite:
        await _mediaRepository.setFavorite(item.id, true);
        return null;

      case BatchAction.unfavourite:
        await _mediaRepository.setFavorite(item.id, false);
        return null;

      case BatchAction.moveToVault:
        // One at a time through the same service the vault screen uses, so
        // the payload-before-row-before-original ordering that protects the
        // user's photo is exactly the ordering a batch gets too.
        final result = await _vaultImport.importItems(<MediaItem>[
          item,
        ], shredOriginals: options.shredOriginals);
        if (result.succeededIds.isEmpty) {
          throw StateError('The vault would not take ${item.displayName}');
        }
        return null;

      case BatchAction.moveToTrash:
        // Flagged, not erased. The file stays on disk and the action can be
        // undone, which is what hard rule 4 asks for.
        await _mediaRepository.setTrash(item.id, true);
        return null;

      case BatchAction.transfer:
        // The transfer screen owns the socket and the pairing. The batch's
        // part is only to hand it the selection, which the action bar does
        // by navigating; there is nothing to do per file here.
        return null;

      case BatchAction.exportPdf:
        // Handled entirely by begin().
        return null;
    }
  }

  /// Converts one photo to a new file beside the original.
  Future<String?> _convert(MediaItem item) async {
    final bytes = await _mediaRepository.readOriginalBytes(
      item,
      maxBytes: AppConstants.convertMaxSourceBytes,
    );
    if (bytes == null || bytes.isEmpty) {
      throw StateError('${item.displayName} could not be read');
    }

    final encoded = await _conversion.convert(
      sourceBytes: bytes,
      request: options.conversion,
    );

    final file = await _naming.saveBytes(
      sourcePath: item.path,
      suffix: AppConstants.convertOutputSuffix,
      extension: options.conversion.format.extension,
      bytes: encoded.bytes,
    );
    return file.path;
  }

  /// Stamps one photo and saves the result as a new file.
  Future<String?> _watermark(MediaItem item) async {
    final bytes = await _mediaRepository.readOriginalBytes(
      item,
      maxBytes: AppConstants.editorMaxSourceBytes,
    );
    if (bytes == null || bytes.isEmpty) {
      throw StateError('${item.displayName} could not be read');
    }

    // An edit session carrying nothing but the stamp. The pipeline runs its
    // usual fixed stage order, so a batch watermark lands in exactly the same
    // place as one applied in the editor.
    final session = EditSession(mediaId: item.id, watermark: options.watermark);

    final result = await _pipeline.renderInBackground(
      RenderRequest(
        sourceBytes: bytes,
        sessionJson: session.toJson(),
        captureDate: item.dateTaken,
      ),
    );

    final file = await _naming.saveBytes(
      sourcePath: item.path,
      suffix: AppConstants.editorOutputSuffix,
      extension: 'jpg',
      bytes: Uint8List.fromList(result.bytes),
    );
    return file.path;
  }
}
