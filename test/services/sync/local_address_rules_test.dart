import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/local_address_rules.dart';

/// These tests guard the one rule Phase 11 relaxed.
///
/// The app carries `android.permission.INTERNET` so two phones on the same
/// Wi-Fi can talk. If `LocalAddressRules` ever starts accepting an address
/// off the local network, that permission stops being narrow and the app's
/// privacy promise quietly becomes untrue. This file is what fails first.
void main() {
  group('LocalAddressRules.isLocal — private ranges are accepted', () {
    test('accepts every 10/8 address', () {
      expect(LocalAddressRules.isLocal('10.0.0.1'), isTrue);
      expect(LocalAddressRules.isLocal('10.255.255.254'), isTrue);
      expect(LocalAddressRules.isLocal('10.13.37.2'), isTrue);
    });

    test('accepts 172.16/12, and only that slice of 172', () {
      expect(LocalAddressRules.isLocal('172.16.0.1'), isTrue);
      expect(LocalAddressRules.isLocal('172.31.255.254'), isTrue);

      // Just outside the block on either side. These are public.
      expect(LocalAddressRules.isLocal('172.15.0.1'), isFalse);
      expect(LocalAddressRules.isLocal('172.32.0.1'), isFalse);
    });

    test('accepts 192.168/16', () {
      expect(LocalAddressRules.isLocal('192.168.0.1'), isTrue);
      expect(LocalAddressRules.isLocal('192.168.1.100'), isTrue);
      expect(LocalAddressRules.isLocal('192.168.255.254'), isTrue);
    });

    test('accepts 169.254/16 link-local, for Wi-Fi with no DHCP', () {
      expect(LocalAddressRules.isLocal('169.254.1.1'), isTrue);
      expect(LocalAddressRules.isLocal('169.253.1.1'), isFalse);
    });
  });

  group('LocalAddressRules.isLocal — everything else is refused', () {
    test('refuses well-known public addresses', () {
      expect(LocalAddressRules.isLocal('8.8.8.8'), isFalse);
      expect(LocalAddressRules.isLocal('1.1.1.1'), isFalse);
      expect(LocalAddressRules.isLocal('93.184.216.34'), isFalse);
      expect(LocalAddressRules.isLocal('203.0.113.5'), isFalse);
    });

    test('refuses addresses that only look private', () {
      // A public address whose first octet is close to a private one.
      expect(LocalAddressRules.isLocal('11.0.0.1'), isFalse);
      expect(LocalAddressRules.isLocal('9.255.255.255'), isFalse);
      expect(LocalAddressRules.isLocal('192.169.0.1'), isFalse);
      expect(LocalAddressRules.isLocal('192.167.255.255'), isFalse);
    });

    test('refuses loopback, which reaches no peer', () {
      expect(LocalAddressRules.isLocal('127.0.0.1'), isFalse);
      expect(LocalAddressRules.isLocal('127.1.2.3'), isFalse);
    });

    test('refuses the unspecified address', () {
      expect(LocalAddressRules.isLocal('0.0.0.0'), isFalse);
    });

    test('refuses every IPv6 form', () {
      expect(LocalAddressRules.isLocal('::1'), isFalse);
      expect(LocalAddressRules.isLocal('fe80::1'), isFalse);
      expect(LocalAddressRules.isLocal('fd00::1'), isFalse);
      expect(LocalAddressRules.isLocal('2001:4860:4860::8888'), isFalse);
      // An IPv4-mapped IPv6 address must not sneak a public address through.
      expect(LocalAddressRules.isLocal('::ffff:8.8.8.8'), isFalse);
      expect(LocalAddressRules.isLocal('::ffff:192.168.1.1'), isFalse);
    });

    test('refuses hostnames, which a check cannot resolve on its own', () {
      expect(LocalAddressRules.isLocal('localhost'), isFalse);
      expect(LocalAddressRules.isLocal('example.com'), isFalse);
      expect(LocalAddressRules.isLocal('router.local'), isFalse);
    });

    test('refuses rubbish and malformed input', () {
      expect(LocalAddressRules.isLocal(''), isFalse);
      expect(LocalAddressRules.isLocal('   '), isFalse);
      expect(LocalAddressRules.isLocal('192.168.1'), isFalse);
      expect(LocalAddressRules.isLocal('192.168.1.1.1'), isFalse);
      expect(LocalAddressRules.isLocal('192.168.1.256'), isFalse);
      expect(LocalAddressRules.isLocal('192.168.-1.1'), isFalse);
      expect(LocalAddressRules.isLocal('192.168.1.a'), isFalse);
      expect(LocalAddressRules.isLocal('...'), isFalse);
      expect(LocalAddressRules.isLocal('10'), isFalse);
    });

    test(
      'refuses leading zeros, which different resolvers read differently',
      () {
        // 010.0.0.1 is octal to some stacks and decimal to others. An address
        // that means two things is one a guard can be walked past, so it is
        // refused outright rather than normalised.
        expect(LocalAddressRules.isLocal('010.0.0.1'), isFalse);
        expect(LocalAddressRules.isLocal('192.168.01.1'), isFalse);
        expect(LocalAddressRules.isLocal('0177.0.0.1'), isFalse);
      },
    );

    test('refuses padding and whitespace tricks inside the address', () {
      expect(
        LocalAddressRules.isLocal('192.168.1.1 '),
        isTrue,
        reason: 'a trailing space is trimmed, the address is still private',
      );
      expect(LocalAddressRules.isLocal('192. 168.1.1'), isFalse);
      expect(LocalAddressRules.isLocal('19 2.168.1.1'), isFalse);
    });
  });

  group('LocalAddressRules.isBindable', () {
    test('allows the private ranges', () {
      expect(LocalAddressRules.isBindable('192.168.1.5'), isTrue);
      expect(LocalAddressRules.isBindable('10.0.0.5'), isTrue);
    });

    test('allows loopback, so the socket tests can run with no network', () {
      expect(LocalAddressRules.isBindable('127.0.0.1'), isTrue);
    });

    test('still refuses a public address', () {
      expect(LocalAddressRules.isBindable('8.8.8.8'), isFalse);
      expect(LocalAddressRules.isBindable('203.0.113.5'), isFalse);
    });

    test('refuses 0.0.0.0, which would listen on every interface', () {
      expect(LocalAddressRules.isBindable('0.0.0.0'), isFalse);
    });
  });

  group('LocalAddressRules.isLoopback and isUnspecified', () {
    test('identifies the loopback block', () {
      expect(LocalAddressRules.isLoopback('127.0.0.1'), isTrue);
      expect(LocalAddressRules.isLoopback('127.255.255.254'), isTrue);
      expect(LocalAddressRules.isLoopback('128.0.0.1'), isFalse);
      expect(LocalAddressRules.isLoopback('::1'), isFalse);
    });

    test('identifies the unspecified address', () {
      expect(LocalAddressRules.isUnspecified('0.0.0.0'), isTrue);
      expect(LocalAddressRules.isUnspecified('0.0.0.1'), isFalse);
      expect(LocalAddressRules.isUnspecified('192.168.1.1'), isFalse);
    });
  });

  group('LocalAddressRules.isUsablePort', () {
    test('accepts ephemeral ports', () {
      expect(LocalAddressRules.isUsablePort(1025), isTrue);
      expect(LocalAddressRules.isUsablePort(45123), isTrue);
      expect(LocalAddressRules.isUsablePort(65535), isTrue);
    });

    test('refuses zero, the well-known range, and out-of-range numbers', () {
      expect(LocalAddressRules.isUsablePort(0), isFalse);
      expect(LocalAddressRules.isUsablePort(80), isFalse);
      expect(LocalAddressRules.isUsablePort(443), isFalse);
      expect(LocalAddressRules.isUsablePort(1024), isFalse);
      expect(LocalAddressRules.isUsablePort(65536), isFalse);
      expect(LocalAddressRules.isUsablePort(-1), isFalse);
    });
  });

  group('LocalAddressRules.isConnectable', () {
    test('needs both a local address and a usable port', () {
      expect(LocalAddressRules.isConnectable('192.168.1.4', 45123), isTrue);
      expect(LocalAddressRules.isConnectable('192.168.1.4', 80), isFalse);
      expect(LocalAddressRules.isConnectable('8.8.8.8', 45123), isFalse);
      expect(LocalAddressRules.isConnectable('8.8.8.8', 443), isFalse);
    });

    test('allows loopback, which cannot leave the device', () {
      // Not a hole. A socket to 127.0.0.1 is the most local connection there
      // is, and allowing it is what lets the transport be tested for real.
      // A pairing *code* naming loopback is still refused, by PairingCodec.
      expect(LocalAddressRules.isConnectable('127.0.0.1', 45123), isTrue);
    });

    test('never allows a public address, whatever the port', () {
      for (final host in <String>['8.8.8.8', '1.1.1.1', '203.0.113.9']) {
        for (final port in <int>[1025, 45123, 65535]) {
          expect(
            LocalAddressRules.isConnectable(host, port),
            isFalse,
            reason: '$host:$port must never be connectable',
          );
        }
      }
    });
  });
}
