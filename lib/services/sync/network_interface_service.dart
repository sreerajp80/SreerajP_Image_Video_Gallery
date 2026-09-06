import 'dart:io';

import 'package:in_sreerajp_imgvidgal/services/sync/local_address_rules.dart';

/// One usable address on this device.
class LocalNetworkAddress {
  /// The interface it belongs to, for the "connected to" line on screen.
  final String interfaceName;

  /// The IPv4 address, in dotted-quad form.
  final String address;

  const LocalNetworkAddress({
    required this.interfaceName,
    required this.address,
  });

  /// Whether this looks like a Wi-Fi interface rather than something else.
  ///
  /// Only a hint, used to sort. Android names its Wi-Fi interface `wlan0` in
  /// practice, but the app never depends on that: an address that passes
  /// [LocalAddressRules] is usable whatever it is called.
  bool get looksLikeWifi =>
      interfaceName.startsWith('wlan') || interfaceName.startsWith('ap');
}

/// Finds the local network addresses the transfer feature may use.
///
/// Everything it returns has already been through [LocalAddressRules]. There
/// is no path from this class to a public address: the filter is applied here
/// as well as at the socket, so a listener cannot end up bound somewhere it
/// should not be even if a caller forgets to check.
class NetworkInterfaceService {
  /// Lists the interfaces. Injectable so the filtering can be tested without
  /// depending on whatever network the test machine happens to be on.
  final Future<List<NetworkInterface>> Function() _lister;

  NetworkInterfaceService({Future<List<NetworkInterface>> Function()? lister})
    : _lister = lister ?? _defaultLister;

  static Future<List<NetworkInterface>> _defaultLister() =>
      NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
        includeLinkLocal: true,
      );

  /// Every private IPv4 address this device has, Wi-Fi-looking ones first.
  ///
  /// Sorted rather than filtered by name: a phone tethering, or on a network
  /// whose interface is called something unexpected, still works.
  Future<List<LocalNetworkAddress>> localAddresses() async {
    final List<NetworkInterface> interfaces;
    try {
      interfaces = await _lister();
    } catch (_) {
      // No network at all, or an OS that refused to enumerate. Neither is a
      // crash: the screen says there is no Wi-Fi to transfer over.
      return const <LocalNetworkAddress>[];
    }

    final found = <LocalNetworkAddress>[];
    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        if (address.type != InternetAddressType.IPv4) continue;
        if (!LocalAddressRules.isLocal(address.address)) continue;

        found.add(
          LocalNetworkAddress(
            interfaceName: interface.name,
            address: address.address,
          ),
        );
      }
    }

    found.sort((a, b) {
      if (a.looksLikeWifi == b.looksLikeWifi) {
        return a.interfaceName.compareTo(b.interfaceName);
      }
      return a.looksLikeWifi ? -1 : 1;
    });

    return List.unmodifiable(found);
  }

  /// The address the listener should bind to, or null if there is none.
  ///
  /// Null means the device is not on a local network, and the transfer screen
  /// says exactly that rather than opening a socket that could reach nobody.
  Future<LocalNetworkAddress?> preferredAddress() async {
    final addresses = await localAddresses();
    return addresses.isEmpty ? null : addresses.first;
  }
}
