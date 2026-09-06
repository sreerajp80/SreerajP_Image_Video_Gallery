import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/markup_layer.dart';

void main() {
  group('NormalizedPoint', () {
    test('survives a round trip through a map', () {
      const point = NormalizedPoint(0.25, 0.75);
      expect(NormalizedPoint.fromMap(point.toMap()), point);
    });
  });

  group('DoodleStroke', () {
    const stroke = DoodleStroke(
      id: 'd1',
      colorArgb: 0xFFFF0000,
      points: <NormalizedPoint>[
        NormalizedPoint(0.1, 0.1),
        NormalizedPoint(0.5, 0.5),
      ],
      strokeWidth: 0.02,
    );

    test('a new point is appended without changing the original', () {
      final extended = stroke.withPoint(const NormalizedPoint(0.9, 0.9));

      expect(extended.points, hasLength(3));
      expect(stroke.points, hasLength(2));
    });

    test('survives a round trip through a map', () {
      final restored = MarkupLayer.fromMap(stroke.toMap());
      expect(restored, stroke);
    });
  });

  group('ShapeAnnotation', () {
    const shape = ShapeAnnotation(
      id: 's1',
      colorArgb: 0xFF00FF00,
      shape: ShapeKind.arrow,
      start: NormalizedPoint(0.1, 0.2),
      end: NormalizedPoint(0.8, 0.9),
      filled: true,
    );

    test('survives a round trip through a map', () {
      expect(MarkupLayer.fromMap(shape.toMap()), shape);
    });

    test('an unknown shape name falls back to a rectangle', () {
      expect(ShapeKind.fromName('triangle'), ShapeKind.rectangle);
    });
  });

  group('TextAnnotation', () {
    const text = TextAnnotation(
      id: 't1',
      colorArgb: 0xFFFFFFFF,
      text: 'hello',
      position: NormalizedPoint(0.2, 0.3),
      hasBackground: true,
    );

    test('survives a round trip through a map', () {
      expect(MarkupLayer.fromMap(text.toMap()), text);
    });

    test('its description does not leak the text itself', () {
      expect(text.toString(), isNot(contains('hello')));
    });
  });

  test('an unknown layer kind reads back as null rather than throwing', () {
    expect(
      MarkupLayer.fromMap(const <String, dynamic>{'kind': 'sticker'}),
      isNull,
    );
  });
}
