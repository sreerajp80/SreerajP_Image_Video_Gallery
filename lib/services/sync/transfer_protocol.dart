import 'dart:convert';
import 'dart:typed_data';

import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';

/// What a frame carries.
///
/// The value is written on the wire, so these numbers are part of the
/// protocol: change one and two builds stop understanding each other. Add new
/// kinds at the end.
enum FrameType {
  /// Client to server: "here is what I am, and here is proof I hold the key."
  hello(1),

  /// Server to client: "accepted", with its own proof so the client knows it
  /// reached the phone whose code it scanned rather than an impostor.
  welcome(2),

  /// The list of files about to be sent.
  manifest(3),

  /// Which of the offered files the receiver actually wants.
  manifestReply(4),

  /// Start of one file: its index in the manifest.
  fileStart(5),

  /// A slice of the file in flight.
  fileChunk(6),

  /// End of one file.
  fileEnd(7),

  /// One file landed and its digest matched.
  fileAck(8),

  /// The whole transfer finished.
  complete(9),

  /// Something went wrong; the body says what.
  error(10),

  /// The other side stopped.
  cancel(11);

  final int wireValue;
  const FrameType(this.wireValue);

  static FrameType? fromWire(int value) {
    for (final type in FrameType.values) {
      if (type.wireValue == value) return type;
    }
    return null;
  }
}

/// One decoded frame.
class TransferFrame {
  final FrameType type;
  final Uint8List body;

  const TransferFrame(this.type, this.body);

  /// Reads the body as JSON, or null if it is not a JSON object.
  Map<String, dynamic>? get json {
    try {
      final decoded = jsonDecode(utf8.decode(body));
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }
}

/// Thrown when a peer sends something the reader will not act on.
///
/// Always fatal to the session. There is no recovery from a peer that is
/// speaking a different protocol, and trying to resynchronise a byte stream
/// after a bad length is how a parser gets talked into an allocation it
/// cannot afford.
class TransferProtocolException implements Exception {
  final String message;
  const TransferProtocolException(this.message);

  @override
  String toString() => 'TransferProtocolException: $message';
}

/// Frames the transfer's byte stream.
///
/// The wire format is deliberately dull: a four-byte big-endian length, one
/// byte of type, then that many bytes of body.
///
/// ```
///  0      4    5              5 + length
///  +------+----+------------------+
///  | len  |type|      body        |
///  +------+----+------------------+
/// ```
///
/// `len` counts the body only. Every frame is capped at
/// [AppConstants.syncMaxFrameBytes]: a peer claiming more is refused rather
/// than trusted with the allocation, which is the entire reason the cap is
/// checked before a single byte of body is read.
///
/// TCP does not preserve message boundaries, so [FrameReader] buffers and
/// hands back whole frames only. Everything here is pure and works on byte
/// lists, which is what lets the protocol be tested without a socket.
class TransferProtocol {
  const TransferProtocol._();

  /// Bytes of length prefix.
  static const int lengthPrefixBytes = 4;

  /// Bytes of type marker.
  static const int typeBytes = 1;

  /// Bytes before the body starts.
  static const int headerBytes = lengthPrefixBytes + typeBytes;

  /// Builds one frame.
  static Uint8List encode(FrameType type, List<int> body) {
    if (body.length > AppConstants.syncMaxFrameBytes) {
      throw TransferProtocolException(
        'Frame body of ${body.length} bytes is over the '
        '${AppConstants.syncMaxFrameBytes} byte cap',
      );
    }

    final out = Uint8List(headerBytes + body.length);
    final view = ByteData.sublistView(out);
    view.setUint32(0, body.length, Endian.big);
    out[lengthPrefixBytes] = type.wireValue;
    out.setRange(headerBytes, headerBytes + body.length, body);
    return out;
  }

  /// Builds one frame whose body is a JSON object.
  static Uint8List encodeJson(FrameType type, Map<String, dynamic> body) =>
      encode(type, utf8.encode(jsonEncode(body)));

  /// Builds an error frame carrying a short reason.
  ///
  /// The reason is a fixed code, never a file path or an exception message:
  /// what went wrong on this device is not something the peer is owed.
  static Uint8List encodeError(String code) =>
      encodeJson(FrameType.error, <String, dynamic>{'code': code});
}

/// Turns an arriving byte stream into whole frames.
///
/// Feed it whatever the socket produced, however it was split, and take back
/// however many complete frames that made. A frame split across five reads
/// and five frames arriving in one read both work, which is the only way to
/// read TCP correctly.
class FrameReader {
  /// Bytes seen but not yet formed into a frame.
  final BytesBuilder _buffer = BytesBuilder(copy: true);

  /// Largest body this reader will accept.
  final int maxFrameBytes;

  FrameReader({this.maxFrameBytes = AppConstants.syncMaxFrameBytes});

  /// How many bytes are waiting for the rest of their frame.
  int get pendingBytes => _buffer.length;

  /// Adds [data] and returns every frame that is now complete.
  ///
  /// Throws [TransferProtocolException] on a frame that is over the cap or
  /// carries a type this build does not know. Both are fatal: the session
  /// ends and the socket closes.
  List<TransferFrame> add(List<int> data) {
    if (data.isNotEmpty) _buffer.add(data);
    final frames = <TransferFrame>[];

    // takeBytes() empties the builder, so the leftover is put back at the end
    // of each pass rather than the buffer being read through repeatedly.
    var bytes = _buffer.takeBytes();
    var offset = 0;

    while (bytes.length - offset >= TransferProtocol.headerBytes) {
      final view = ByteData.sublistView(bytes, offset);
      final bodyLength = view.getUint32(0, Endian.big);

      if (bodyLength > maxFrameBytes) {
        throw TransferProtocolException(
          'Peer announced a $bodyLength byte frame, over the '
          '$maxFrameBytes byte cap',
        );
      }

      final frameLength = TransferProtocol.headerBytes + bodyLength;
      if (bytes.length - offset < frameLength) break;

      final typeValue = bytes[offset + TransferProtocol.lengthPrefixBytes];
      final type = FrameType.fromWire(typeValue);
      if (type == null) {
        throw TransferProtocolException('Unknown frame type $typeValue');
      }

      final bodyStart = offset + TransferProtocol.headerBytes;
      frames.add(
        TransferFrame(
          type,
          Uint8List.sublistView(bytes, bodyStart, bodyStart + bodyLength),
        ),
      );
      offset += frameLength;
    }

    if (offset < bytes.length) {
      _buffer.add(Uint8List.sublistView(bytes, offset));
    }
    return frames;
  }

  /// Drops everything buffered.
  void reset() => _buffer.clear();
}
