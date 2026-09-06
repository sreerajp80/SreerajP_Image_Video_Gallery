/// What a decoded code turned out to be.
///
/// The kind is worked out from the payload text alone, by
/// `BarcodePayloadParser`. It decides which actions the sheet offers, so it
/// stays a plain classification with no behaviour of its own.
enum ScannedCodeKind {
  /// A web address the app may hand to a browser.
  url,

  /// Wi-Fi joining details in the `WIFI:` form.
  wifi,

  /// A phone number, from `tel:` or a bare number.
  phone,

  /// An email address, from `mailto:` or a bare address.
  email,

  /// A text message, from `sms:` or `smsto:`.
  sms,

  /// A map point, from `geo:`.
  geo,

  /// A contact card, from `BEGIN:VCARD` or `MECARD:`.
  contact,

  /// A calendar entry, from `BEGIN:VEVENT`.
  calendar,

  /// Anything else, including a scheme the app will not open.
  text;

  /// Whether this kind carries something the app can act on beyond copying.
  bool get hasAction => this != ScannedCodeKind.text;
}
