/// How a Wi-Fi network in a scanned code is protected.
enum WifiSecurity {
  /// No password at all.
  open,

  /// WPA or WPA2 personal.
  wpa,

  /// The old WEP scheme.
  wep,

  /// WPA3 with SAE.
  sae;

  /// Whether a password is expected for this kind of network.
  bool get needsPassword => this != WifiSecurity.open;
}

/// The joining details carried by a `WIFI:` code.
///
/// Immutable, and deliberately not logged anywhere: the password is a real
/// secret even though it arrived on a printed card.
class WifiCredentials {
  /// Network name.
  final String ssid;

  /// How the network is protected.
  final WifiSecurity security;

  /// The password, or an empty string for an open network.
  final String password;

  /// Whether the network hides its name.
  final bool isHidden;

  const WifiCredentials({
    required this.ssid,
    this.security = WifiSecurity.wpa,
    this.password = '',
    this.isHidden = false,
  });

  /// Whether there is enough here to try joining.
  bool get isUsable =>
      ssid.isNotEmpty && (!security.needsPassword || password.isNotEmpty);

  WifiCredentials copyWith({
    String? ssid,
    WifiSecurity? security,
    String? password,
    bool? isHidden,
  }) {
    return WifiCredentials(
      ssid: ssid ?? this.ssid,
      security: security ?? this.security,
      password: password ?? this.password,
      isHidden: isHidden ?? this.isHidden,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WifiCredentials &&
        other.ssid == ssid &&
        other.security == security &&
        other.password == password &&
        other.isHidden == isHidden;
  }

  @override
  int get hashCode => Object.hash(ssid, security, password, isHidden);

  /// Names the network only. The password never reaches a log line.
  @override
  String toString() => 'WifiCredentials($ssid, ${security.name})';
}
