/// Decides whether an IPv4 address is on the local network.
///
/// This is the file that keeps hard rule 2 honest.
///
/// The app declares `android.permission.INTERNET` for one feature only, and a
/// permission is not a promise — this class is. Every socket the transfer
/// feature opens, in either direction, is checked here first: the listener
/// will not bind to an address this rejects, the client will not connect to
/// one, and a connected peer whose remote address this rejects is dropped
/// before a single byte is read from it.
///
/// It is deliberately pure and has no imports. There is nothing here to mock,
/// nothing to configure, and no way to switch it off, which is exactly what a
/// guard on a promise should look like. `test/services/sync/` fails the build
/// if a public address is ever accepted.
class LocalAddressRules {
  const LocalAddressRules._();

  /// Whether [address] is an IPv4 address the transfer feature may talk to.
  ///
  /// True only for the ranges reserved for private networks and for the
  /// link-local range a phone falls back to with no DHCP:
  ///
  /// * `10.0.0.0/8`      — RFC 1918
  /// * `172.16.0.0/12`   — RFC 1918
  /// * `192.168.0.0/16`  — RFC 1918
  /// * `169.254.0.0/16`  — RFC 3927 link-local
  ///
  /// Everything else is false, including loopback in release use, every
  /// public address, every IPv6 form, a hostname, and rubbish.
  static bool isLocal(String address) {
    final octets = _parseIpv4(address);
    if (octets == null) return false;
    return _isPrivateOctets(octets);
  }

  /// Whether [address] may be *bound to* by the listener.
  ///
  /// The same ranges, plus loopback, so the socket tests can run a real
  /// server and client without a Wi-Fi network. Loopback is allowed here and
  /// refused by [isLocal] on purpose: binding to your own machine reaches
  /// nobody, while *connecting* to a peer that claims to be loopback is a
  /// sign something is wrong, not a transfer anyone asked for.
  static bool isBindable(String address) {
    if (isLoopback(address)) return true;
    return isLocal(address);
  }

  /// Whether [address] is the IPv4 loopback range `127.0.0.0/8`.
  static bool isLoopback(String address) {
    final octets = _parseIpv4(address);
    if (octets == null) return false;
    return octets[0] == 127;
  }

  /// Whether [address] is the unspecified address, `0.0.0.0`.
  ///
  /// Never bound to. Binding there would put the listener on every interface
  /// the device has, which is the one thing the narrowed rule rules out.
  static bool isUnspecified(String address) {
    final octets = _parseIpv4(address);
    if (octets == null) return false;
    return octets.every((octet) => octet == 0);
  }

  /// Whether [port] is one a transfer may use.
  ///
  /// Above the well-known range, and inside the valid range. Zero is refused
  /// here because by the time an address is being checked the operating
  /// system has already handed out a real port; zero only means "choose one"
  /// at bind time.
  static bool isUsablePort(int port) => port > 1024 && port <= 65535;

  /// True when both the address and the port are fit to connect to.
  ///
  /// Uses [isBindable] rather than [isLocal], so loopback is allowed here.
  /// That is not a hole: loopback is the most local address there is, and a
  /// socket to it cannot leave the device. The security property — never
  /// connect to anything off the local network — is untouched, and it is what
  /// lets the socket layer be tested against a real server and client.
  ///
  /// A *pairing code* naming loopback is still refused, by [PairingCodec]:
  /// a code that tells the other phone to dial itself reaches nobody, so it
  /// is a sign something is wrong rather than a transfer anyone asked for.
  static bool isConnectable(String address, int port) =>
      isBindable(address) && isUsablePort(port);

  // ------------------------------------------------------------------ inner

  /// Splits a dotted-quad into four octets, or null if it is not one.
  ///
  /// Strict on purpose. Leading zeros are refused because `010.0.0.1` is read
  /// as octal by some resolvers and as decimal by others, and an address that
  /// means two things is an address a check can be walked past.
  static List<int>? _parseIpv4(String address) {
    final trimmed = address.trim();
    if (trimmed.isEmpty || trimmed.length > 15) return null;

    final parts = trimmed.split('.');
    if (parts.length != 4) return null;

    final octets = <int>[];
    for (final part in parts) {
      if (part.isEmpty || part.length > 3) return null;
      if (part.length > 1 && part.startsWith('0')) return null;

      var value = 0;
      for (var i = 0; i < part.length; i++) {
        final code = part.codeUnitAt(i);
        if (code < 0x30 || code > 0x39) return null;
        value = value * 10 + (code - 0x30);
      }
      if (value > 255) return null;
      octets.add(value);
    }
    return octets;
  }

  static bool _isPrivateOctets(List<int> o) {
    if (o[0] == 10) return true;
    if (o[0] == 172 && o[1] >= 16 && o[1] <= 31) return true;
    if (o[0] == 192 && o[1] == 168) return true;
    if (o[0] == 169 && o[1] == 254) return true;
    return false;
  }
}
