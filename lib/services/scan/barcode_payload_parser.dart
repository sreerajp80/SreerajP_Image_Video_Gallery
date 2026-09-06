import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/scan/scanned_code.dart';
import 'package:in_sreerajp_imgvidgal/models/scan/scanned_code_kind.dart';
import 'package:in_sreerajp_imgvidgal/models/scan/wifi_credentials.dart';

/// Turns the raw text of a code into something typed.
///
/// Pure, and the only place that reads a payload. A code is untrusted input:
/// it came off a poster or a screenshot, and it may be malformed on purpose.
/// So nothing here throws on bad text. The worst outcome is
/// [ScannedCodeKind.text], which offers a copy and nothing else.
class BarcodePayloadParser {
  const BarcodePayloadParser();

  /// Reads [rawValue] and says what it is.
  ///
  /// [format] is the symbology the decoder named; it is carried through
  /// untouched and never used to decide the kind.
  ScannedCode parse(String rawValue, {String format = ''}) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      return ScannedCode(
        rawValue: rawValue,
        kind: ScannedCodeKind.text,
        displayValue: '',
        format: format,
      );
    }

    // An absurdly long payload is kept, but not read any further. Parsing it
    // gains nothing and the sheet will refuse to act on it anyway.
    if (trimmed.length > AppConstants.scanMaxPayloadLength) {
      return ScannedCode(
        rawValue: rawValue,
        kind: ScannedCodeKind.text,
        displayValue: _shorten(trimmed),
        format: format,
      );
    }

    final lower = trimmed.toLowerCase();

    if (lower.startsWith('wifi:')) {
      return _parseWifi(rawValue, trimmed, format);
    }
    if (lower.startsWith('begin:vcard') || lower.startsWith('mecard:')) {
      return _simple(
        rawValue,
        ScannedCodeKind.contact,
        _contactName(trimmed),
        format,
      );
    }
    if (lower.startsWith('begin:vevent') ||
        lower.startsWith('begin:vcalendar')) {
      return _simple(
        rawValue,
        ScannedCodeKind.calendar,
        _eventName(trimmed),
        format,
      );
    }
    if (lower.startsWith('mailto:')) {
      final address = _afterScheme(trimmed, 'mailto:').split('?').first;
      return _simple(rawValue, ScannedCodeKind.email, address, format);
    }
    if (lower.startsWith('tel:')) {
      return _simple(
        rawValue,
        ScannedCodeKind.phone,
        _afterScheme(trimmed, 'tel:'),
        format,
      );
    }
    if (lower.startsWith('smsto:')) {
      // `SMSTO:number:message` is the older form some printers still emit.
      final rest = _afterScheme(trimmed, 'smsto:');
      final number = rest.split(':').first;
      return _simple(rawValue, ScannedCodeKind.sms, number, format);
    }
    if (lower.startsWith('sms:')) {
      final rest = _afterScheme(trimmed, 'sms:');
      final number = rest.split('?').first.split(':').first;
      return _simple(rawValue, ScannedCodeKind.sms, number, format);
    }
    if (lower.startsWith('geo:')) {
      return _simple(
        rawValue,
        ScannedCodeKind.geo,
        _afterScheme(trimmed, 'geo:').split('?').first,
        format,
      );
    }
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return _simple(rawValue, ScannedCodeKind.url, trimmed, format);
    }

    // A bare domain with no scheme is by far the most common thing on a
    // printed code. It is read as a web address, but the scheme the app will
    // actually launch is decided later, by the action resolver.
    if (_looksLikeBareDomain(trimmed)) {
      return _simple(rawValue, ScannedCodeKind.url, trimmed, format);
    }

    if (_looksLikeEmail(trimmed)) {
      return _simple(rawValue, ScannedCodeKind.email, trimmed, format);
    }

    if (_looksLikePhoneNumber(trimmed)) {
      return _simple(rawValue, ScannedCodeKind.phone, trimmed, format);
    }

    return _simple(rawValue, ScannedCodeKind.text, _shorten(trimmed), format);
  }

  ScannedCode _simple(
    String rawValue,
    ScannedCodeKind kind,
    String displayValue,
    String format,
  ) {
    return ScannedCode(
      rawValue: rawValue,
      kind: kind,
      displayValue: displayValue,
      format: format,
    );
  }

  /// Reads the `WIFI:T:WPA;S:name;P:secret;H:true;;` form.
  ///
  /// The escaping rule is the awkward part: inside a value, `\` escapes the
  /// next character, so a network called `a;b` arrives as `a\;b`. Splitting on
  /// a bare `;` would cut that in half, so the value is walked one character
  /// at a time instead.
  ScannedCode _parseWifi(String rawValue, String trimmed, String format) {
    final body = trimmed.substring('wifi:'.length);
    final fields = _splitWifiFields(body);

    var ssid = '';
    var password = '';
    var security = WifiSecurity.wpa;
    var hidden = false;
    var sawSecurityField = false;

    for (final field in fields) {
      final separator = field.indexOf(':');
      if (separator <= 0) continue;

      final key = field.substring(0, separator).toUpperCase();
      final value = _unescapeWifi(field.substring(separator + 1));

      switch (key) {
        case 'S':
          ssid = value;
        case 'P':
          password = value;
        case 'T':
          sawSecurityField = true;
          security = _wifiSecurity(value);
        case 'H':
          hidden = value.toLowerCase() == 'true';
      }
    }

    // A code with a password but no `T:` field is WPA in practice. One with
    // neither is an open network.
    if (!sawSecurityField && password.isEmpty) {
      security = WifiSecurity.open;
    }

    return ScannedCode(
      rawValue: rawValue,
      kind: ScannedCodeKind.wifi,
      displayValue: ssid,
      format: format,
      wifi: WifiCredentials(
        ssid: ssid,
        security: security,
        password: password,
        isHidden: hidden,
      ),
    );
  }

  WifiSecurity _wifiSecurity(String value) {
    final normalised = value.toUpperCase();
    if (normalised.isEmpty || normalised == 'NOPASS' || normalised == 'NONE') {
      return WifiSecurity.open;
    }
    if (normalised == 'WEP') return WifiSecurity.wep;
    if (normalised == 'SAE' || normalised == 'WPA3') return WifiSecurity.sae;
    return WifiSecurity.wpa;
  }

  /// Cuts the body into `key:value` fields on unescaped semicolons.
  List<String> _splitWifiFields(String body) {
    final fields = <String>[];
    final buffer = StringBuffer();
    var escaped = false;

    for (var index = 0; index < body.length; index++) {
      final character = body[index];

      if (escaped) {
        // Keep the backslash for now; `_unescapeWifi` takes it off once the
        // field boundaries are settled.
        buffer.write('\\');
        buffer.write(character);
        escaped = false;
        continue;
      }

      if (character == '\\') {
        escaped = true;
        continue;
      }

      if (character == ';') {
        if (buffer.isNotEmpty) fields.add(buffer.toString());
        buffer.clear();
        continue;
      }

      buffer.write(character);
    }

    // A trailing backslash is malformed. Keep what came before it rather than
    // dropping the whole field.
    if (buffer.isNotEmpty) fields.add(buffer.toString());
    return fields;
  }

  String _unescapeWifi(String value) {
    if (!value.contains('\\')) return value;

    final buffer = StringBuffer();
    var escaped = false;

    for (var index = 0; index < value.length; index++) {
      final character = value[index];
      if (escaped) {
        buffer.write(character);
        escaped = false;
        continue;
      }
      if (character == '\\') {
        escaped = true;
        continue;
      }
      buffer.write(character);
    }

    return buffer.toString();
  }

  /// Pulls a readable name out of a vCard or MECARD block.
  String _contactName(String payload) {
    for (final line in payload.split(RegExp(r'[\r\n]+'))) {
      final upper = line.toUpperCase();
      if (upper.startsWith('FN:')) return line.substring(3).trim();
      if (upper.startsWith('N:')) {
        return line
            .substring(2)
            .split(';')
            .where((part) => part.trim().isNotEmpty)
            .join(' ')
            .trim();
      }
      if (upper.startsWith('MECARD:N:')) {
        return line.substring('MECARD:N:'.length).split(';').first.trim();
      }
    }
    return '';
  }

  /// Pulls the summary line out of a calendar block.
  String _eventName(String payload) {
    for (final line in payload.split(RegExp(r'[\r\n]+'))) {
      if (line.toUpperCase().startsWith('SUMMARY:')) {
        return line.substring('SUMMARY:'.length).trim();
      }
    }
    return '';
  }

  String _afterScheme(String value, String scheme) =>
      value.substring(scheme.length).trim();

  /// Whether the text reads as `example.com/path` with no scheme in front.
  ///
  /// Kept strict on purpose. A loose rule here turns every stray word with a
  /// dot in it into a tappable link, and a link is the one action where being
  /// wrong actually costs the user something.
  bool _looksLikeBareDomain(String value) {
    if (value.contains(' ') || value.contains('\n')) return false;
    if (value.contains('://')) return false;
    if (value.startsWith('.') || value.startsWith('/')) return false;

    final host = value.split('/').first.split('?').first;
    if (!host.contains('.')) return false;

    final labels = host.split('.');
    if (labels.length < 2) return false;
    if (labels.any((label) => label.isEmpty)) return false;

    final topLevel = labels.last;
    if (topLevel.length < 2) return false;
    if (!RegExp(r'^[A-Za-z]{2,}$').hasMatch(topLevel)) return false;

    return labels.every((label) => RegExp(r'^[A-Za-z0-9-]+$').hasMatch(label));
  }

  bool _looksLikeEmail(String value) {
    if (value.contains(' ')) return false;
    return RegExp(r'^[^@\s]+@[^@\s.]+\.[A-Za-z]{2,}$').hasMatch(value);
  }

  /// Whether a bare number reads as a phone number rather than a barcode.
  ///
  /// A plain run of digits is refused, because that is exactly what a product
  /// barcode is: an EAN-13 off a cereal box is thirteen digits, and offering
  /// to dial it would be nonsense. So the number has to look written down by a
  /// person: a leading `+`, or spaces, dashes or brackets in it.
  bool _looksLikePhoneNumber(String value) {
    if (!RegExp(r'^\+?[0-9 ()-]{6,20}$').hasMatch(value)) return false;

    final hasCountryPrefix = value.startsWith('+');
    final hasSeparator = RegExp(r'[ ()-]').hasMatch(value);
    if (!hasCountryPrefix && !hasSeparator) return false;

    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 6 && digits.length <= 15;
  }

  /// Keeps a card title to one readable line.
  String _shorten(String value) {
    final singleLine = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (singleLine.length <= 120) return singleLine;
    return '${singleLine.substring(0, 117)}...';
  }
}
