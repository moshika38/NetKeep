import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A single WireGuard tunnel configuration.
///
/// Mirrors a `wg-quick` profile: an [Interface] block (client keys, address,
/// DNS) and one [Peer] block (server public key, endpoint, allowed IPs).
///
/// The default profile is Cloudflare WARP (https://developers.cloudflare.com/
/// warp-client/warp/): the keys below are the well-known WARP client identity
/// published by Cloudflare, so the tunnel is plug-and-play without running a
/// private WireGuard server.
class WireGuardConfig {
  final String serverAddress;
  final String address;
  final String dns;
  final String privateKey;
  final String peerPublicKey;
  final String allowedIps;
  final int persistentKeepalive;

  /// Cloudflare WARP relay endpoint (UDP 2408, IPv4).
  static const String warpServerAddress = '162.159.192.1:2408';

  /// Public WARP client private key (published by Cloudflare).
  static const String warpPrivateKey = 'AKjxw4rSti8akpgYy8jdajeyOGH7U8rGTEskRlw7A1M=';

  /// WARP relay public key (published by Cloudflare).
  static const String warpPublicKey = 'bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=';

  /// Assigned tunnel address handed out by the WARP relay.
  static const String warpAddress = '172.16.0.2/32';

  /// WARP resolver - returns Cloudflare IPs for the whole tunnel.
  static const String warpDns = '1.1.1.1';

  /// Route the entire IPv4 table through the tunnel.
  static const String warpAllowedIps = '0.0.0.0/0';

  /// The stock Cloudflare WARP profile used whenever no saved config exists.
  static const WireGuardConfig cloudflareWarp = WireGuardConfig(
    serverAddress: warpServerAddress,
    address: warpAddress,
    dns: warpDns,
    privateKey: warpPrivateKey,
    peerPublicKey: warpPublicKey,
    allowedIps: warpAllowedIps,
    persistentKeepalive: 25,
  );

  const WireGuardConfig({
    this.serverAddress = warpServerAddress,
    this.address = warpAddress,
    this.dns = warpDns,
    this.privateKey = warpPrivateKey,
    this.peerPublicKey = warpPublicKey,
    this.allowedIps = warpAllowedIps,
    this.persistentKeepalive = 25,
  });

  /// True when every field required to dial the tunnel is present.
  bool get isComplete =>
      serverAddress.trim().isNotEmpty &&
      address.trim().isNotEmpty &&
      privateKey.trim().isNotEmpty &&
      peerPublicKey.trim().isNotEmpty;

  WireGuardConfig copyWith({
    String? serverAddress,
    String? address,
    String? dns,
    String? privateKey,
    String? peerPublicKey,
    String? allowedIps,
    int? persistentKeepalive,
  }) {
    return WireGuardConfig(
      serverAddress: serverAddress ?? this.serverAddress,
      address: address ?? this.address,
      dns: dns ?? this.dns,
      privateKey: privateKey ?? this.privateKey,
      peerPublicKey: peerPublicKey ?? this.peerPublicKey,
      allowedIps: allowedIps ?? this.allowedIps,
      persistentKeepalive: persistentKeepalive ?? this.persistentKeepalive,
    );
  }

  /// Renders the `wg-quick` conf consumed by the native WireGuard runtime.
  String toWgQuick() {
    final buffer = StringBuffer()
      ..writeln('[Interface]')
      ..writeln('PrivateKey = $privateKey')
      ..writeln('Address = $address');
    if (dns.trim().isNotEmpty) {
      buffer.writeln('DNS = $dns');
    }
    buffer
      ..writeln()
      ..writeln('[Peer]')
      ..writeln('PublicKey = $peerPublicKey')
      ..writeln('Endpoint = $serverAddress')
      ..writeln('AllowedIPs = $allowedIps')
      ..writeln('PersistentKeepalive = $persistentKeepalive');
    return buffer.toString();
  }
}

/// Persists [WireGuardConfig] to SharedPreferences.
class WireGuardConfigStore {
  WireGuardConfigStore._();

  static const _serverAddressKey = 'wg_server_address';
  static const _addressKey = 'wg_address';
  static const _dnsKey = 'wg_dns';
  static const _privateKeyKey = 'wg_private_key';
  static const _peerPublicKeyKey = 'wg_peer_public_key';
  static const _allowedIpsKey = 'wg_allowed_ips';
  static const _keepaliveKey = 'wg_keepalive';

  static Future<WireGuardConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    final serverAddress = prefs.getString(_serverAddressKey);
    // First run: no saved keys, so fall back to the Cloudflare WARP profile.
    if (serverAddress == null || serverAddress.isEmpty) {
      return WireGuardConfig.cloudflareWarp;
    }
    return WireGuardConfig(
      serverAddress: serverAddress,
      address: prefs.getString(_addressKey) ?? WireGuardConfig.warpAddress,
      dns: prefs.getString(_dnsKey) ?? WireGuardConfig.warpDns,
      privateKey: prefs.getString(_privateKeyKey) ?? WireGuardConfig.warpPrivateKey,
      peerPublicKey:
          prefs.getString(_peerPublicKeyKey) ?? WireGuardConfig.warpPublicKey,
      allowedIps:
          prefs.getString(_allowedIpsKey) ?? WireGuardConfig.warpAllowedIps,
      persistentKeepalive: prefs.getInt(_keepaliveKey) ?? 25,
    );
  }

  static Future<void> save(WireGuardConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverAddressKey, config.serverAddress);
    await prefs.setString(_addressKey, config.address);
    await prefs.setString(_dnsKey, config.dns);
    await prefs.setString(_privateKeyKey, config.privateKey);
    await prefs.setString(_peerPublicKeyKey, config.peerPublicKey);
    await prefs.setString(_allowedIpsKey, config.allowedIps);
    await prefs.setInt(_keepaliveKey, config.persistentKeepalive);
  }
}

/// Generates a fresh WireGuard keypair (X25519 / Curve25519).
///
/// The private key goes in the [Interface] block of this app's conf; the
/// matching public key is the peer key you paste into the server's
/// `wg set ... peer` configuration.
Future<({String privateKey, String publicKey})> generateWireGuardKeyPair() async {
  final keyPair = await X25519().newKeyPair();
  final publicKey = await keyPair.extractPublicKey();
  final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
  return (
    privateKey: base64Encode(privateKeyBytes),
    publicKey: base64Encode(publicKey.bytes),
  );
}
