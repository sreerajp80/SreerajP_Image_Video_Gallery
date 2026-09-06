import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/crop_transform.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/filter_preset.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/markup_layer.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/redaction_region.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/tone_adjustments.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/watermark_config.dart';

/// The whole edit as one immutable description, never as pixels.
///
/// This is the heart of the non-destructive editor. Every tool only produces
/// a new session; nothing is drawn and no file is touched until the user
/// saves. That also makes undo and redo simple: the notifier just keeps the
/// previous sessions in a list.
@immutable
class EditSession {
  /// Id of the media item being edited.
  final String mediaId;

  /// Geometry: crop, turns, straighten, flips, perspective.
  final CropTransform crop;

  /// Light and colour sliders, plus the RGB curves.
  final ToneAdjustments tone;

  /// The one-tap look, applied after the manual tone sliders.
  final FilterPreset filter;

  /// Areas blurred, pixelated, or blacked out, in the coordinates of the
  /// image after the crop and rotation have been applied.
  final List<RedactionRegion> redactions;

  /// Doodles, shapes, and text, drawn in list order.
  final List<MarkupLayer> markup;

  /// The stamp added last, on top of everything else.
  final WatermarkConfig watermark;

  const EditSession({
    required this.mediaId,
    this.crop = CropTransform.identity,
    this.tone = ToneAdjustments.neutral,
    this.filter = FilterPreset.none,
    this.redactions = const <RedactionRegion>[],
    this.markup = const <MarkupLayer>[],
    this.watermark = WatermarkConfig.none,
  });

  /// A fresh session for [mediaId] with nothing changed yet.
  factory EditSession.initial(String mediaId) => EditSession(mediaId: mediaId);

  /// Whether the user has changed anything worth saving.
  ///
  /// The save button and the "discard changes?" prompt both read this, so an
  /// untouched photo never offers to write a copy it does not need.
  bool get isDirty =>
      !crop.isIdentity ||
      !tone.isNeutral ||
      !filter.isNone ||
      redactions.isNotEmpty ||
      markup.isNotEmpty ||
      !watermark.isNone;

  /// Whether any stage needs the pixels re-read at full resolution.
  ///
  /// Used by the preview to decide whether it can reuse a cached decode.
  bool get hasPixelWork =>
      redactions.isNotEmpty ||
      !crop.isIdentity ||
      !tone.isNeutral ||
      !filter.isNone;

  /// Everything cleared, keeping the same media item.
  EditSession reset() => EditSession.initial(mediaId);

  EditSession copyWith({
    String? mediaId,
    CropTransform? crop,
    ToneAdjustments? tone,
    FilterPreset? filter,
    List<RedactionRegion>? redactions,
    List<MarkupLayer>? markup,
    WatermarkConfig? watermark,
  }) {
    return EditSession(
      mediaId: mediaId ?? this.mediaId,
      crop: crop ?? this.crop,
      tone: tone ?? this.tone,
      filter: filter ?? this.filter,
      redactions: redactions ?? this.redactions,
      markup: markup ?? this.markup,
      watermark: watermark ?? this.watermark,
    );
  }

  /// Returns a copy with one more markup layer on top.
  EditSession addMarkup(MarkupLayer layer) =>
      copyWith(markup: <MarkupLayer>[...markup, layer]);

  /// Returns a copy with the layer carrying [layerId] removed.
  EditSession removeMarkup(String layerId) => copyWith(
    markup: markup
        .where((layer) => layer.id != layerId)
        .toList(growable: false),
  );

  /// Returns a copy where the layer with the same id is swapped for [layer].
  ///
  /// Used while a stroke is still being drawn, so the in-progress line is
  /// replaced rather than piling up a layer per finger move.
  EditSession replaceMarkup(MarkupLayer layer) => copyWith(
    markup: markup
        .map((existing) => existing.id == layer.id ? layer : existing)
        .toList(growable: false),
  );

  /// Returns a copy with one more redaction area.
  EditSession addRedaction(RedactionRegion region) =>
      copyWith(redactions: <RedactionRegion>[...redactions, region]);

  /// Returns a copy with the redaction carrying [regionId] removed.
  EditSession removeRedaction(String regionId) => copyWith(
    redactions: redactions
        .where((region) => region.id != regionId)
        .toList(growable: false),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    'mediaId': mediaId,
    'crop': crop.toMap(),
    'tone': tone.toMap(),
    'filter': filter.toMap(),
    'redactions': redactions.map((r) => r.toMap()).toList(),
    'markup': markup.map((m) => m.toMap()).toList(),
    'watermark': watermark.toMap(),
  };

  /// Rebuilds a session from a map, ignoring any part that is unreadable.
  ///
  /// A stored session that was written by an older build must never crash the
  /// editor, so every field falls back to its neutral value.
  factory EditSession.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? readMap(String key) {
      final raw = map[key];
      return raw is Map ? Map<String, dynamic>.from(raw) : null;
    }

    final redactionsRaw = map['redactions'];
    final markupRaw = map['markup'];

    return EditSession(
      mediaId: map['mediaId'] as String? ?? '',
      crop: readMap('crop') != null
          ? CropTransform.fromMap(readMap('crop')!)
          : CropTransform.identity,
      tone: readMap('tone') != null
          ? ToneAdjustments.fromMap(readMap('tone')!)
          : ToneAdjustments.neutral,
      filter: readMap('filter') != null
          ? FilterPreset.fromMap(readMap('filter')!)
          : FilterPreset.none,
      redactions: redactionsRaw is List
          ? redactionsRaw
                .whereType<Map>()
                .map(
                  (e) => RedactionRegion.fromMap(Map<String, dynamic>.from(e)),
                )
                .toList(growable: false)
          : const <RedactionRegion>[],
      markup: markupRaw is List
          ? markupRaw
                .whereType<Map>()
                .map((e) => MarkupLayer.fromMap(Map<String, dynamic>.from(e)))
                .whereType<MarkupLayer>()
                .toList(growable: false)
          : const <MarkupLayer>[],
      watermark: readMap('watermark') != null
          ? WatermarkConfig.fromMap(readMap('watermark')!)
          : WatermarkConfig.none,
    );
  }

  /// The session as a JSON string, used to hand it to the render isolate.
  String toJson() => jsonEncode(toMap());

  /// Reads a session back from [source], or a blank one if it is unreadable.
  factory EditSession.fromJson(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is Map) {
        return EditSession.fromMap(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      // A corrupt session is not worth failing over; start clean instead.
    }
    return EditSession.initial('');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditSession &&
          runtimeType == other.runtimeType &&
          mediaId == other.mediaId &&
          crop == other.crop &&
          tone == other.tone &&
          filter == other.filter &&
          listEquals(redactions, other.redactions) &&
          listEquals(markup, other.markup) &&
          watermark == other.watermark;

  @override
  int get hashCode => Object.hash(
    mediaId,
    crop,
    tone,
    filter,
    Object.hashAll(redactions),
    Object.hashAll(markup),
    watermark,
  );

  @override
  String toString() =>
      'EditSession($mediaId, dirty: $isDirty, '
      'redactions: ${redactions.length}, markup: ${markup.length})';
}
