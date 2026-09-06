import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/services/pdf/pdf_lexer.dart';

import 'pdf_test_files.dart';

Uint8List _bytes(String source) => Uint8List.fromList(latin1.encode(source));

void main() {
  group('the header check', () {
    test('a real header is found', () {
      expect(PdfLexer(_bytes('%PDF-1.7\n')).hasPdfHeader, isTrue);
    });

    test('a header a little way in is still found', () {
      expect(PdfLexer(_bytes('junk bytes\n%PDF-1.4\n')).hasPdfHeader, isTrue);
    });

    test('a file with no header is refused', () {
      expect(PdfLexer(_bytes('not a pdf at all')).hasPdfHeader, isFalse);
      expect(PdfLexer(Uint8List(0)).hasPdfHeader, isFalse);
    });
  });

  group('reading objects', () {
    test('every object is found, with its number', () {
      final lexer = PdfLexer(
        _bytes(
          '%PDF-1.4\n'
          '1 0 obj\n<< /Type /Catalog >>\nendobj\n'
          '2 0 obj\n<< /Type /Pages >>\nendobj\n',
        ),
      );

      final objects = lexer.readObjects();
      expect(objects.map((o) => o.number), <int>[1, 2]);
      expect(objects.first.dictionary['Type'], const PdfName('Catalog'));
    });

    test('a generation other than zero is kept', () {
      final objects = PdfLexer(
        _bytes('%PDF-1.4\n5 3 obj\n42\nendobj\n'),
      ).readObjects();
      expect(objects.single.number, 5);
      expect(objects.single.generation, 3);
      expect(objects.single.value, 42);
    });

    test('numbers, names, booleans and nulls are read', () {
      final objects = PdfLexer(
        _bytes(
          '%PDF-1.4\n1 0 obj\n'
          '<< /A 7 /B -3 /C 2.5 /D /Name /E true /F false /G null >>\n'
          'endobj\n',
        ),
      ).readObjects();

      final dictionary = objects.single.dictionary;
      expect(dictionary['A'], 7);
      expect(dictionary['B'], -3);
      expect(dictionary['C'], 2.5);
      expect(dictionary['D'], const PdfName('Name'));
      expect(dictionary['E'], isTrue);
      expect(dictionary['F'], isFalse);
      expect(dictionary['G'], isNull);
    });

    test('a reference is read as a reference, not two numbers', () {
      final objects = PdfLexer(
        _bytes('%PDF-1.4\n1 0 obj\n<< /Pages 2 0 R /Count 3 >>\nendobj\n'),
      ).readObjects();

      expect(objects.single.dictionary['Pages'], const PdfRef(2, 0));
      expect(objects.single.dictionary['Count'], 3);
    });

    test('arrays and nested dictionaries are read', () {
      final objects = PdfLexer(
        _bytes(
          '%PDF-1.4\n1 0 obj\n'
          '<< /Kids [3 0 R 4 0 R] /Box [0 0 200 300] '
          '/Inner << /Deep [ /A /B ] >> >>\nendobj\n',
        ),
      ).readObjects();

      final dictionary = objects.single.dictionary;
      expect(dictionary['Kids'], <Object>[
        const PdfRef(3, 0),
        const PdfRef(4, 0),
      ]);
      expect(dictionary['Box'], <int>[0, 0, 200, 300]);

      final inner = dictionary['Inner'] as Map<String, Object?>;
      expect(inner['Deep'], <Object>[const PdfName('A'), const PdfName('B')]);
    });

    test('a name with a hash escape is decoded', () {
      final objects = PdfLexer(
        _bytes('%PDF-1.4\n1 0 obj\n<< /A#20B 1 >>\nendobj\n'),
      ).readObjects();
      expect(objects.single.dictionary.keys.single, 'A B');
    });

    test('comments are skipped', () {
      final objects = PdfLexer(
        _bytes('%PDF-1.4\n1 0 obj\n% a comment\n<< /A 1 >>\nendobj\n'),
      ).readObjects();
      expect(objects.single.dictionary['A'], 1);
    });

    test('strings do not derail the parser', () {
      final objects = PdfLexer(
        _bytes(
          '%PDF-1.4\n1 0 obj\n'
          r'<< /T (a string with \) and obj inside) /H <48656C6C6F> /A 1 >>'
          '\nendobj\n',
        ),
      ).readObjects();
      expect(objects.single.dictionary['A'], 1);
    });
  });

  group('streams', () {
    test('the stream bytes come back exactly', () {
      final data = <int>[1, 2, 3, 4, 5, 250, 0, 99];
      final file = PdfTestFiles.withImage(
        dictionary: '/Type /XObject /Subtype /Image',
        stream: data,
      );

      final lexer = PdfLexer(file);
      final image = lexer.readObjects().firstWhere((o) => o.hasStream);
      expect(lexer.streamBytes(image), data);
    });

    test('a length given as a reference is resolved', () {
      final data = <int>[9, 8, 7, 6];
      final lexer = PdfLexer(
        PdfTestFiles.withIndirectLength(
          dictionary: '/Type /XObject /Subtype /Image',
          stream: data,
        ),
      );

      final image = lexer.readObjects().firstWhere((o) => o.hasStream);
      expect(lexer.streamBytes(image), data);
    });

    // A wrong /Length is one of the most common faults in a real PDF, and
    // believing it would hand back half a picture.
    test(
      'a length that is too short is thrown away and endstream is found',
      () {
        final data = <int>[1, 2, 3, 4, 5, 6, 7, 8];
        final lexer = PdfLexer(
          PdfTestFiles.withImage(
            dictionary: '/Type /XObject /Subtype /Image',
            stream: data,
            declaredLength: 3,
          ),
        );

        final image = lexer.readObjects().firstWhere((o) => o.hasStream);
        expect(lexer.streamBytes(image), data);
      },
    );

    test('a length that runs past the file is thrown away', () {
      final data = <int>[1, 2, 3, 4];
      final lexer = PdfLexer(
        PdfTestFiles.withImage(
          dictionary: '/Type /XObject /Subtype /Image',
          stream: data,
          declaredLength: 9999,
        ),
      );

      final image = lexer.readObjects().firstWhere((o) => o.hasStream);
      expect(lexer.streamBytes(image), data);
    });

    test('a stream with no endstream keyword takes what is left', () {
      final lexer = PdfLexer(
        _bytes('%PDF-1.4\n1 0 obj\n<< /Length 4 >>\nstream\nabcd'),
      );
      final object = lexer.readObjects().firstWhere((o) => o.hasStream);
      expect(lexer.streamBytes(object), isNotEmpty);
    });
  });

  group('broken files are survived, never thrown on', () {
    const broken = <String>[
      '',
      '%PDF-1.4\n',
      '%PDF-1.4\n1 0 obj',
      '%PDF-1.4\n1 0 obj\n<<',
      '%PDF-1.4\n1 0 obj\n<< /A',
      '%PDF-1.4\n1 0 obj\n<< /A >>',
      '%PDF-1.4\n1 0 obj\n[[[[[[',
      '%PDF-1.4\n1 0 obj\n<< /A << /B << /C 1 >> >>',
      '%PDF-1.4\nobj\nendobj',
      '%PDF-1.4\n0 0 obj\n<< >>\nendobj',
      '%PDF-1.4\n1 0 obj\nstream',
      '%PDF-1.4\n1 0 obj\n(unclosed string',
      '%PDF-1.4\n1 0 obj\n<abcd',
      '%PDF-1.4\n99999999999999 0 obj\n<< >>\nendobj',
    ];

    for (final source in broken) {
      test('"${source.replaceAll('\n', ' ')}" is read without throwing', () {
        expect(() => PdfLexer(_bytes(source)).readObjects(), returnsNormally);
      });
    }

    test('a deeply nested array does not blow the stack', () {
      final nested = '${'[' * 500}1${']' * 500}';
      expect(
        () => PdfLexer(
          _bytes('%PDF-1.4\n1 0 obj\n$nested\nendobj\n'),
        ).readObjects(),
        returnsNormally,
      );
    });

    test('random bytes are read without throwing', () {
      final random = Uint8List.fromList(
        List<int>.generate(4096, (index) => (index * 37) % 256),
      );
      expect(() => PdfLexer(random).readObjects(), returnsNormally);
    });
  });

  group('resolving references', () {
    test('a reference is followed to the object it names', () {
      final objects = PdfLexer(
        _bytes(
          '%PDF-1.4\n1 0 obj\n<< /Length 2 0 R >>\nendobj\n2 0 obj\n55\nendobj\n',
        ),
      ).readObjects();

      final byNumber = <int, PdfObject>{
        for (final object in objects) object.number: object,
      };
      final length = objects.first.dictionary['Length'];
      expect(PdfLexer.resolve(length, byNumber), 55);
    });

    test('a plain value is handed straight back', () {
      expect(PdfLexer.resolve(7, const <int, PdfObject>{}), 7);
    });

    test('a reference to nothing gives null', () {
      expect(
        PdfLexer.resolve(const PdfRef(9, 0), const <int, PdfObject>{}),
        isNull,
      );
    });
  });
}
