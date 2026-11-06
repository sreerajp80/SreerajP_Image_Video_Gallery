import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/l10n/sanskrit_fallback_delegates.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/crop_transform.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/markup_layer.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/selective_mask.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/tone_adjustments.dart';
import 'package:in_sreerajp_imgvidgal/providers/editor_providers.dart';
import 'package:in_sreerajp_imgvidgal/widgets/editor/crop_overlay.dart';
import 'package:in_sreerajp_imgvidgal/widgets/editor/curve_editor.dart';
import 'package:in_sreerajp_imgvidgal/widgets/editor/markup_canvas.dart';
import 'package:in_sreerajp_imgvidgal/widgets/editor/redaction_panel.dart';
import 'package:in_sreerajp_imgvidgal/widgets/editor/selective_mask_overlay.dart';

/// The drawing tools a screen reader meets (standard §7.3): each has a name,
/// a value, a hint, and where it can work without touch, actions.
void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Locale locale = const Locale('en'),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(width: 400, height: 600, child: child),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Runs the custom action named [label] on the node labelled [node].
  void perform(WidgetTester tester, String node, String label) {
    final semantics = tester.getSemantics(find.bySemanticsLabel(node));
    final id = CustomSemanticsAction.getIdentifier(
      CustomSemanticsAction(label: label),
    );
    semantics.owner!.performAction(
      semantics.id,
      SemanticsAction.customAction,
      id,
    );
  }

  const rect = NormalizedRect(left: 0.1, top: 0.1, right: 0.6, bottom: 0.6);

  testWidgets('crop box reads its position and moves with an action', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    NormalizedRect? ended;
    await pump(
      tester,
      CropOverlay(
        rect: rect,
        onChanged: (_) {},
        onChangeEnd: (value) => ended = value,
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('Crop area')),
      isSemantics(
        label: 'Crop area',
        value: 'Left 10%, top 10%, width 50%, height 50%',
        hint: 'Drag the corners, or use the actions to move or resize',
      ),
    );

    perform(tester, 'Crop area', 'Move right');
    expect(ended!.left, closeTo(0.15, 1e-9));
    expect(ended!.width, closeTo(0.5, 1e-9));

    perform(tester, 'Crop area', 'Make smaller');
    expect(ended!.width, closeTo(0.45, 1e-9));
    handle.dispose();
  });

  testWidgets('markup surface says drawing needs touch', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      MarkupCanvas(
        layers: const <MarkupLayer>[],
        settings: const MarkupToolSettings(),
        onLayerCompleted: (_) {},
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Drawing area')),
      isSemantics(
        value: 'Nothing drawn',
        hint:
            'Drawing needs touch. Use the panel below to change or remove '
            'marks.',
      ),
    );
    handle.dispose();
  });

  testWidgets('hide surface reads how many areas are hidden', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      RedactionCanvas(
        regions: const [],
        settings: const RedactionToolSettings(),
        onRegionCompleted: (_) {},
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Hide area')),
      isSemantics(value: 'Nothing hidden'),
    );
    handle.dispose();
  });

  testWidgets('curve graph reads its point count', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      CurveEditor(adjustments: ToneAdjustments.neutral, onChanged: (_) {}),
    );
    final node = tester.getSemantics(find.bySemanticsLabel('Tone curve'));
    expect(node.value, matches(RegExp(r'^\d+ points?$')));
    handle.dispose();
  });

  testWidgets('selected mask reads its centre and moves with an action', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    SelectiveMask? updated;
    await pump(
      tester,
      SelectiveMaskOverlay(
        masks: const <SelectiveMask>[SelectiveMask(id: 'm1')],
        selectedMaskId: 'm1',
        onMaskUpdated: (value) => updated = value,
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('Mask position')),
      isSemantics(value: 'Linear, centre at 50% across, 50% down'),
    );

    perform(tester, 'Mask position', 'Move up');
    expect(updated!.startPoint.y, closeTo(0.25, 1e-9));
    expect(updated!.endPoint.y, closeTo(0.65, 1e-9));
    handle.dispose();
  });

  testWidgets('labels are translated in Sanskrit', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      CropOverlay(rect: rect, onChanged: (_) {}, onChangeEnd: (_) {}),
      locale: const Locale('sa'),
    );
    expect(find.bySemanticsLabel('कर्तनक्षेत्रम्'), findsOneWidget);
    handle.dispose();
  });
}
