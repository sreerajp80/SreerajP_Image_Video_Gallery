import 'dart:typed_data';

/// A PDF name, such as `/Image`.
///
/// Wrapped rather than kept as a bare string so a name can never be confused
/// with a string value that happens to hold the same characters.
class PdfName {
  final String value;

  const PdfName(this.value);

  @override
  bool operator ==(Object other) => other is PdfName && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => '/$value';
}

/// A reference to another object, such as `12 0 R`.
class PdfRef {
  final int number;
  final int generation;

  const PdfRef(this.number, this.generation);

  @override
  bool operator ==(Object other) =>
      other is PdfRef &&
      other.number == number &&
      other.generation == generation;

  @override
  int get hashCode => Object.hash(number, generation);

  @override
  String toString() => '$number $generation R';
}

/// One indirect object read out of the file.
class PdfObject {
  final int number;
  final int generation;

  /// The object's value. A dictionary for anything with a stream.
  final Object? value;

  /// Offset of the first stream byte, or -1 when there is no stream.
  final int streamStart;

  /// Length of the stream in bytes, or -1 when there is no stream.
  final int streamLength;

  const PdfObject({
    required this.number,
    required this.generation,
    required this.value,
    this.streamStart = -1,
    this.streamLength = -1,
  });

  /// Whether this object carries a stream.
  bool get hasStream => streamStart >= 0 && streamLength >= 0;

  /// The object's dictionary, or an empty map when it is not one.
  Map<String, Object?> get dictionary {
    final value = this.value;
    return value is Map<String, Object?> ? value : const <String, Object?>{};
  }

  @override
  String toString() => 'PdfObject($number $generation, stream: $hasStream)';
}

/// Reads the objects out of a PDF file.
///
/// Pure, works on bytes, and never throws on a malformed file: a PDF is
/// untrusted input, and half the PDFs in the world are slightly broken anyway.
/// Anything it cannot read it skips.
///
/// It walks the whole file looking for `N G obj` rather than following the
/// cross-reference table. That is slower, but a broken or rewritten table is
/// the single most common thing wrong with a real PDF, and this way such a
/// file still gives up its pictures.
class PdfLexer {
  /// The bytes being read.
  final Uint8List bytes;

  int _offset = 0;

  PdfLexer(this.bytes);

  /// Whether the file starts with a PDF header.
  ///
  /// The header is allowed to sit a little way in, because some tools glue
  /// bytes on the front and every reader tolerates it.
  bool get hasPdfHeader {
    final limit = bytes.length < 1024 ? bytes.length : 1024;
    for (var index = 0; index + 4 < limit; index++) {
      if (bytes[index] == 0x25 && // %
          bytes[index + 1] == 0x50 && // P
          bytes[index + 2] == 0x44 && // D
          bytes[index + 3] == 0x46 && // F
          bytes[index + 4] == 0x2D) {
        // -
        return true;
      }
    }
    return false;
  }

  /// Reads every indirect object in the file, in the order they appear.
  ///
  /// A `/Length` given as a reference is resolved once all objects are known,
  /// and a length that does not land on `endstream` is thrown away in favour
  /// of searching for the keyword. Both happen in real files.
  List<PdfObject> readObjects() {
    final found = <PdfObject>[];
    final lengths = <int, int>{};

    var index = 0;
    while (index < bytes.length) {
      final objAt = _indexOfKeyword(_objKeyword, index);
      if (objAt < 0) break;

      final header = _readObjectHeader(objAt);
      if (header == null) {
        index = objAt + 3;
        continue;
      }

      _offset = objAt + 3;
      final value = _readValue(0);

      // A plain number object is how `/Length 12 0 R` is satisfied, so keep
      // those aside before anything else is worked out.
      if (value is num) {
        lengths[header.number] = value.toInt();
      }

      _skipWhitespace();
      var streamStart = -1;
      var streamLength = -1;

      if (_matchesKeyword(_streamKeyword, _offset)) {
        streamStart = _streamDataStart(_offset + _streamKeyword.length);
        streamLength = -1; // Resolved below, once every length is known.
      }

      found.add(
        PdfObject(
          number: header.number,
          generation: header.generation,
          value: value,
          streamStart: streamStart,
          streamLength: streamLength,
        ),
      );

      index = streamStart >= 0 ? streamStart : _offset;
      if (index <= objAt) index = objAt + 3;
    }

    return found
        .map((object) => _withResolvedLength(object, lengths))
        .toList(growable: false);
  }

  /// Returns the raw bytes of [object]'s stream, before any filter is undone.
  Uint8List streamBytes(PdfObject object) {
    if (!object.hasStream) return Uint8List(0);

    final start = object.streamStart;
    final end = start + object.streamLength;
    if (start < 0 || end > bytes.length || end < start) return Uint8List(0);

    return Uint8List.sublistView(bytes, start, end);
  }

  /// Resolves a value that may be a reference into the object it points at.
  static Object? resolve(Object? value, Map<int, PdfObject> byNumber) {
    if (value is! PdfRef) return value;
    return byNumber[value.number]?.value;
  }

  PdfObject _withResolvedLength(PdfObject object, Map<int, int> lengths) {
    if (object.streamStart < 0) return object;

    final declared = object.dictionary['Length'];
    var length = -1;

    if (declared is num) {
      length = declared.toInt();
    } else if (declared is PdfRef) {
      length = lengths[declared.number] ?? -1;
    }

    // Trust the declared length only if `endstream` really does follow it.
    // A wrong length is common, and believing it would cut a picture in half.
    if (length >= 0 && _endsAtEndstream(object.streamStart, length)) {
      return PdfObject(
        number: object.number,
        generation: object.generation,
        value: object.value,
        streamStart: object.streamStart,
        streamLength: length,
      );
    }

    final searched = _searchStreamEnd(object.streamStart);
    return PdfObject(
      number: object.number,
      generation: object.generation,
      value: object.value,
      streamStart: object.streamStart,
      streamLength: searched,
    );
  }

  bool _endsAtEndstream(int start, int length) {
    var cursor = start + length;
    if (cursor > bytes.length) return false;

    // Allow the usual line ending between the data and the keyword.
    var slack = 0;
    while (cursor < bytes.length && slack < 4 && _isWhitespace(bytes[cursor])) {
      cursor++;
      slack++;
    }
    return _matchesKeyword(_endstreamKeyword, cursor);
  }

  int _searchStreamEnd(int start) {
    final at = _indexOfKeyword(_endstreamKeyword, start);
    if (at < 0) return bytes.length - start;

    var end = at;
    // Step back over the line ending that belongs to the keyword, not the data.
    if (end > start && bytes[end - 1] == 0x0A) end--;
    if (end > start && bytes[end - 1] == 0x0D) end--;
    return end - start;
  }

  /// Finds where the stream data begins, after `stream` and its line ending.
  int _streamDataStart(int afterKeyword) {
    var cursor = afterKeyword;
    if (cursor < bytes.length && bytes[cursor] == 0x0D) cursor++;
    if (cursor < bytes.length && bytes[cursor] == 0x0A) cursor++;
    return cursor;
  }

  /// Reads `N G obj` backwards from the `obj` keyword at [objAt].
  _ObjectHeader? _readObjectHeader(int objAt) {
    var cursor = objAt - 1;
    cursor = _skipBackWhitespace(cursor);
    final generation = _readBackNumber(cursor);
    if (generation == null) return null;

    cursor = _skipBackWhitespace(generation.startIndex - 1);
    final number = _readBackNumber(cursor);
    if (number == null) return null;

    return _ObjectHeader(number.value, generation.value);
  }

  int _skipBackWhitespace(int from) {
    var cursor = from;
    while (cursor >= 0 && _isWhitespace(bytes[cursor])) {
      cursor--;
    }
    return cursor;
  }

  _BackNumber? _readBackNumber(int from) {
    if (from < 0 || !_isDigit(bytes[from])) return null;

    var start = from;
    while (start > 0 && _isDigit(bytes[start - 1])) {
      start--;
    }

    var value = 0;
    for (var index = start; index <= from; index++) {
      value = value * 10 + (bytes[index] - 0x30);
      // A number this long is not an object number; give up rather than
      // overflow into nonsense.
      if (value > 0x7FFFFFF) return null;
    }

    return _BackNumber(value, start);
  }

  // --- value reading -------------------------------------------------------

  /// Reads one value at the current offset.
  ///
  /// [depth] guards against a file that nests arrays inside arrays forever,
  /// which is a cheap way to blow the stack of a naive reader.
  Object? _readValue(int depth) {
    if (depth > 32) return null;
    _skipWhitespace();
    if (_offset >= bytes.length) return null;

    final byte = bytes[_offset];

    if (byte == 0x2F) return _readName(); // /
    if (byte == 0x3C) {
      // << is a dictionary, < on its own is a hex string.
      if (_offset + 1 < bytes.length && bytes[_offset + 1] == 0x3C) {
        return _readDictionary(depth);
      }
      return _readHexString();
    }
    if (byte == 0x5B) return _readArray(depth); // [
    if (byte == 0x28) return _readLiteralString(); // (
    if (_isDigit(byte) || byte == 0x2B || byte == 0x2D || byte == 0x2E) {
      return _readNumberOrRef();
    }

    final keyword = _readKeyword();
    if (keyword == 'true') return true;
    if (keyword == 'false') return false;
    if (keyword == 'null') return null;
    if (keyword.isEmpty) _offset++; // Never stand still on a junk byte.
    return null;
  }

  Map<String, Object?> _readDictionary(int depth) {
    _offset += 2; // <<
    final entries = <String, Object?>{};

    while (_offset < bytes.length) {
      _skipWhitespace();
      if (_offset + 1 < bytes.length &&
          bytes[_offset] == 0x3E &&
          bytes[_offset + 1] == 0x3E) {
        _offset += 2;
        break;
      }
      if (_offset >= bytes.length) break;

      if (bytes[_offset] != 0x2F) {
        // Not a name where a key must be: the dictionary is malformed. Step
        // over the byte and carry on rather than abandoning the object.
        _offset++;
        continue;
      }

      final key = _readName().value;
      final value = _readValue(depth + 1);
      entries[key] = value;
    }

    return entries;
  }

  List<Object?> _readArray(int depth) {
    _offset++; // [
    final items = <Object?>[];

    while (_offset < bytes.length) {
      _skipWhitespace();
      if (_offset >= bytes.length) break;
      if (bytes[_offset] == 0x5D) {
        _offset++; // ]
        break;
      }

      final before = _offset;
      items.add(_readValue(depth + 1));
      if (_offset == before) _offset++; // Guard against standing still.
    }

    return items;
  }

  PdfName _readName() {
    _offset++; // /
    final buffer = StringBuffer();

    while (_offset < bytes.length) {
      final byte = bytes[_offset];
      if (_isWhitespace(byte) || _isDelimiter(byte)) break;

      // `#41` is how a name holds an awkward character.
      if (byte == 0x23 && _offset + 2 < bytes.length) {
        final high = _hexValue(bytes[_offset + 1]);
        final low = _hexValue(bytes[_offset + 2]);
        if (high >= 0 && low >= 0) {
          buffer.writeCharCode(high * 16 + low);
          _offset += 3;
          continue;
        }
      }

      buffer.writeCharCode(byte);
      _offset++;
    }

    return PdfName(buffer.toString());
  }

  /// Reads a number, or the `N G R` form when that is what follows.
  Object? _readNumberOrRef() {
    final first = _readNumber();
    if (first == null) return null;

    // Only a whole, non-negative number can start a reference.
    if (first is! int || first < 0) return first;

    final save = _offset;
    _skipWhitespace();
    final second = _readNumber();

    if (second is int && second >= 0) {
      _skipWhitespace();
      if (_offset < bytes.length && bytes[_offset] == 0x52) {
        // R
        final after = _offset + 1;
        if (after >= bytes.length ||
            _isWhitespace(bytes[after]) ||
            _isDelimiter(bytes[after])) {
          _offset = after;
          return PdfRef(first, second);
        }
      }
    }

    _offset = save;
    return first;
  }

  num? _readNumber() {
    final start = _offset;
    var sawDigit = false;
    var sawDot = false;

    if (_offset < bytes.length &&
        (bytes[_offset] == 0x2B || bytes[_offset] == 0x2D)) {
      _offset++;
    }

    while (_offset < bytes.length) {
      final byte = bytes[_offset];
      if (_isDigit(byte)) {
        sawDigit = true;
        _offset++;
        continue;
      }
      if (byte == 0x2E && !sawDot) {
        sawDot = true;
        _offset++;
        continue;
      }
      break;
    }

    if (!sawDigit) {
      _offset = start;
      return null;
    }

    final text = String.fromCharCodes(bytes.sublist(start, _offset));
    return sawDot ? double.tryParse(text) : int.tryParse(text);
  }

  /// Reads a `(literal)` string, keeping the bytes as they are.
  Uint8List _readLiteralString() {
    _offset++; // (
    final out = <int>[];
    var depth = 1;

    while (_offset < bytes.length) {
      final byte = bytes[_offset];

      if (byte == 0x5C && _offset + 1 < bytes.length) {
        // A backslash escape. The exact character does not matter here: no
        // string in a PDF decides whether a picture comes out, so the escaped
        // byte is kept and the parser moves on.
        out.add(bytes[_offset + 1]);
        _offset += 2;
        continue;
      }
      if (byte == 0x28) depth++;
      if (byte == 0x29) {
        depth--;
        if (depth == 0) {
          _offset++;
          break;
        }
      }

      out.add(byte);
      _offset++;
    }

    return Uint8List.fromList(out);
  }

  Uint8List _readHexString() {
    _offset++; // <
    final out = <int>[];
    var high = -1;

    while (_offset < bytes.length) {
      final byte = bytes[_offset];
      if (byte == 0x3E) {
        _offset++; // >
        break;
      }

      final value = _hexValue(byte);
      if (value >= 0) {
        if (high < 0) {
          high = value;
        } else {
          out.add(high * 16 + value);
          high = -1;
        }
      }
      _offset++;
    }

    // An odd number of digits means the last one is padded with zero.
    if (high >= 0) out.add(high * 16);
    return Uint8List.fromList(out);
  }

  String _readKeyword() {
    final buffer = StringBuffer();
    while (_offset < bytes.length) {
      final byte = bytes[_offset];
      if (_isWhitespace(byte) || _isDelimiter(byte)) break;
      buffer.writeCharCode(byte);
      _offset++;
    }
    return buffer.toString();
  }

  void _skipWhitespace() {
    while (_offset < bytes.length) {
      final byte = bytes[_offset];

      if (_isWhitespace(byte)) {
        _offset++;
        continue;
      }
      // A `%` comment runs to the end of the line.
      if (byte == 0x25) {
        while (_offset < bytes.length &&
            bytes[_offset] != 0x0A &&
            bytes[_offset] != 0x0D) {
          _offset++;
        }
        continue;
      }
      break;
    }
  }

  // --- byte helpers --------------------------------------------------------

  static const List<int> _objKeyword = <int>[0x6F, 0x62, 0x6A]; // obj
  static const List<int> _streamKeyword = <int>[
    0x73, 0x74, 0x72, 0x65, 0x61, 0x6D, // stream
  ];
  static const List<int> _endstreamKeyword = <int>[
    0x65, 0x6E, 0x64, 0x73, 0x74, 0x72, 0x65, 0x61, 0x6D, // endstream
  ];

  int _indexOfKeyword(List<int> keyword, int from) {
    final last = bytes.length - keyword.length;
    for (var index = from < 0 ? 0 : from; index <= last; index++) {
      if (_matchesKeyword(keyword, index)) return index;
    }
    return -1;
  }

  bool _matchesKeyword(List<int> keyword, int at) {
    if (at < 0 || at + keyword.length > bytes.length) return false;
    for (var offset = 0; offset < keyword.length; offset++) {
      if (bytes[at + offset] != keyword[offset]) return false;
    }
    return true;
  }

  static bool _isWhitespace(int byte) {
    return byte == 0x20 ||
        byte == 0x0A ||
        byte == 0x0D ||
        byte == 0x09 ||
        byte == 0x0C ||
        byte == 0x00;
  }

  static bool _isDelimiter(int byte) {
    return byte == 0x28 || // (
        byte == 0x29 || // )
        byte == 0x3C || // <
        byte == 0x3E || // >
        byte == 0x5B || // [
        byte == 0x5D || // ]
        byte == 0x7B || // {
        byte == 0x7D || // }
        byte == 0x2F || // /
        byte == 0x25; // %
  }

  static bool _isDigit(int byte) => byte >= 0x30 && byte <= 0x39;

  static int _hexValue(int byte) {
    if (byte >= 0x30 && byte <= 0x39) return byte - 0x30;
    if (byte >= 0x41 && byte <= 0x46) return byte - 0x41 + 10;
    if (byte >= 0x61 && byte <= 0x66) return byte - 0x61 + 10;
    return -1;
  }
}

class _ObjectHeader {
  final int number;
  final int generation;

  const _ObjectHeader(this.number, this.generation);
}

class _BackNumber {
  final int value;
  final int startIndex;

  const _BackNumber(this.value, this.startIndex);
}
