import 'dart:async';

import 'package:flutter/material.dart';
import 'package:netkeep/services/ping.services.dart';
import 'package:netkeep/services/vpn_service.dart';
import 'package:netkeep/services/wireguard_config.dart';
import 'package:netkeep/utils/theme.dart';
import 'package:netkeep/widgets/app.bar.dart';
import 'package:netkeep/widgets/section.header.dart';

class VpnScreen extends StatefulWidget {
  const VpnScreen({super.key});

  @override
  State<VpnScreen> createState() => _VpnScreenState();
}

class _VpnScreenState extends State<VpnScreen> with WidgetsBindingObserver {
  // WireGuard config form
  late final TextEditingController _endpointCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _dnsCtrl;
  late final TextEditingController _privateKeyCtrl;
  late final TextEditingController _peerKeyCtrl;
  late final TextEditingController _allowedIpsCtrl;

  // Live tunnel state
  String _wgStage = 'disconnected';
  bool _wgBusy = false;
  String _generatedPublicKey = '';
  String _downloadSpeed = '0 B/s';
  String _uploadSpeed = '0 B/s';
  String _totalDown = '0 B';
  String _totalUp = '0 B';
  String _latency = '--';
  String _handshake = '--';
  int? _prevRx;
  int? _prevTx;
  Timer? _latencyTimer;
  StreamSubscription<Map<String, dynamic>>? _eventSub;
  Map<String, dynamic> _deviceInfo = const {};
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _endpointCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _dnsCtrl = TextEditingController();
    _privateKeyCtrl = TextEditingController();
    _peerKeyCtrl = TextEditingController();
    _allowedIpsCtrl = TextEditingController();

    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _eventSub?.cancel();
    _latencyTimer?.cancel();
    _endpointCtrl.dispose();
    _addressCtrl.dispose();
    _dnsCtrl.dispose();
    _privateKeyCtrl.dispose();
    _peerKeyCtrl.dispose();
    _allowedIpsCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refreshes tunnel state after returning from the VPN consent dialog.
    if (state == AppLifecycleState.resumed) {
      _refreshAll();
    }
  }

  Future<void> _init() async {
    final config = await WireGuardConfigStore.load();
    _deviceInfo = await VpnService.deviceInfo();
    if (!mounted) return;

    _applyConfig(config);

    _eventSub = VpnService.eventStream.listen(_onVpnEvent);
    await _refreshAll();
    _addLog('WireGuard relay module ready (Cloudflare WARP defaults)');
  }

  void _applyConfig(WireGuardConfig config) {
    _endpointCtrl.text = config.serverAddress;
    _addressCtrl.text = config.address;
    _dnsCtrl.text = config.dns;
    _privateKeyCtrl.text = config.privateKey;
    _peerKeyCtrl.text = config.peerPublicKey;
    _allowedIpsCtrl.text = config.allowedIps;
  }

  Future<void> _refreshAll() async {
    final snapshot = await VpnService.status();
    if (!mounted) return;
    setState(() {
      _wgStage = snapshot['stage']?.toString() ?? 'disconnected';
      _totalDown = _fmtBytes(snapshot['rxBytes']);
      _totalUp = _fmtBytes(snapshot['txBytes']);
      if (_wgStage == 'connected') {
        _startLatencyProbe();
      } else {
        _stopLatencyProbe();
      }
    });
  }

  void _onVpnEvent(Map<String, dynamic> event) {
    if (!mounted) return;
    switch (event['type']) {
      case 'stage':
        final stage = event['stage']?.toString() ?? 'disconnected';
        setState(() {
          _wgStage = stage;
          if (stage == 'connected') {
            _startLatencyProbe();
          } else {
            _stopLatencyProbe();
          }
        });
        _logStageChange(stage);
      case 'stats':
        final rx = _asNum(event['rxBytes']);
        final tx = _asNum(event['txBytes']);
        final handshakeAge = _asNum(event['handshakeAgeMs']);
        setState(() {
          if (_prevRx != null && _prevTx != null) {
            final down = rx - _prevRx!;
            final up = tx - _prevTx!;
            _downloadSpeed = '${_fmtBytes(down > 0 ? down : 0)}/s';
            _uploadSpeed = '${_fmtBytes(up > 0 ? up : 0)}/s';
          }
          _prevRx = rx.toInt();
          _prevTx = tx.toInt();
          _totalDown = _fmtBytes(rx);
          _totalUp = _fmtBytes(tx);
          _handshake =
              handshakeAge < 0 ? '--' : _fmtDuration(handshakeAge.toInt());
        });
    }
  }

  void _logStageChange(String stage) {
    switch (stage) {
      case 'connected':
        _addLog('WireGuard tunnel CONNECTED');
      case 'connecting':
        _addLog('WireGuard tunnel connecting...');
      case 'error':
        _addLog('WireGuard tunnel error - check config and try again');
      default:
        _addLog('WireGuard tunnel disconnected');
    }
  }

  // ---------------------------------------------------------------- actions

  Future<void> _wgToggle() async {
    if (_wgBusy) return;
    final connected = _wgStage == 'connected';
    setState(() => _wgBusy = true);

    try {
      if (connected) {
        await VpnService.stop();
        _addLog('Stopping WireGuard relay');
      } else {
        final config = _readForm();
        if (!config.isComplete) {
          _addLog('WireGuard config incomplete - fill all fields');
          return;
        }
        await WireGuardConfigStore.save(config);

        _addLog('Dialing WireGuard endpoint ${config.serverAddress}...');
        final result = await VpnService.start(config);
        if (result['error'] != null) {
          _addLog('WireGuard error: ${result['error']}');
        } else if (result['consentRequired'] == true) {
          _addLog('Approve the VPN permission dialog');
        } else {
          _addLog('WireGuard relay starting...');
        }
        await VpnService.refreshStatus();
      }
    } catch (e) {
      _addLog('WireGuard error: $e');
    } finally {
      if (mounted) setState(() => _wgBusy = false);
    }
  }

  Future<void> _resetToWarp() async {
    setState(() => _applyConfig(WireGuardConfig.cloudflareWarp));
    _addLog('Config reset to Cloudflare WARP defaults');
  }

  Future<void> _generateKeys() async {
    setState(() => _wgBusy = true);
    try {
      final pair = await generateWireGuardKeyPair();
      _privateKeyCtrl.text = pair.privateKey;
      if (mounted) {
        setState(() => _generatedPublicKey = pair.publicKey);
      }
      _addLog('Keypair generated - paste public key into server');
    } catch (e) {
      _addLog('Keygen error: $e');
    } finally {
      if (mounted) setState(() => _wgBusy = false);
    }
  }

  WireGuardConfig _readForm() {
    return WireGuardConfig(
      serverAddress: _endpointCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      dns: _dnsCtrl.text.trim(),
      privateKey: _privateKeyCtrl.text.trim(),
      peerPublicKey: _peerKeyCtrl.text.trim(),
      allowedIps: _allowedIpsCtrl.text.trim().isEmpty
          ? WireGuardConfig.warpAllowedIps
          : _allowedIpsCtrl.text.trim(),
    );
  }

  // --------------------------------------------------------------- latency

  void _startLatencyProbe() {
    _latencyTimer?.cancel();
    _latencyTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final latency = await measureTunnelLatency();
      if (mounted && _wgStage == 'connected') {
        setState(() => _latency = latency == null ? '--' : '$latency ms');
      }
    });
    unawaited(_probeNow());
  }

  void _stopLatencyProbe() {
    _latencyTimer?.cancel();
    _latencyTimer = null;
    _latency = '--';
  }

  Future<void> _probeNow() async {
    final latency = await measureTunnelLatency();
    if (mounted && _wgStage == 'connected') {
      setState(() => _latency = latency == null ? '--' : '$latency ms');
    }
  }

  void _addLog(String message) {
    final timestamp = DateTime.now().toString().split('.')[0];
    setState(() {
      _logs.insert(0, '[$timestamp] $message');
      if (_logs.length > 40) {
        _logs.removeRange(40, _logs.length);
      }
    });
  }

  // ------------------------------------------------------------- formatting

  static num _asNum(dynamic value) {
    if (value is num) return value;
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _fmtBytes(dynamic value) {
    final bytes = _asNum(value);
    if (bytes >= 1 << 30) {
      return '${(bytes / (1 << 30)).toStringAsFixed(2)} GB';
    }
    if (bytes >= 1 << 20) {
      return '${(bytes / (1 << 20)).toStringAsFixed(2)} MB';
    }
    if (bytes >= 1 << 10) {
      return '${(bytes / (1 << 10)).toStringAsFixed(1)} KB';
    }
    return '${bytes.toInt()} B';
  }

  static String _fmtDuration(int ms) {
    if (ms < 1000) return '${ms}ms ago';
    return '${(ms / 1000).toStringAsFixed(1)}s ago';
  }

  // ------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final wgConnected = _wgStage == 'connected';
    return Scaffold(
      appBar: NetKeepAppBar(title: 'VPN Tunnel'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(
            title: 'WireGuard Relay',
            subtitle: 'Cloudflare WARP \u00b7 full tunnel mode',
          ),
          const SizedBox(height: 12),
          _WgStatusCard(
            stage: _wgStage,
            endpoint: _endpointCtrl.text.trim(),
            latency: _latency,
            handshake: _handshake,
            downloadSpeed: _downloadSpeed,
            uploadSpeed: _uploadSpeed,
            totalDown: _totalDown,
            totalUp: _totalUp,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 55,
            child: FilledButton.icon(
              onPressed: _wgBusy ? null : _wgToggle,
              icon: _wgBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      wgConnected ? Icons.power_settings_new : Icons.vpn_key,
                    ),
              label: Text(
                wgConnected
                    ? 'Disconnect WireGuard'
                    : (_wgBusy ? 'Working...' : 'Connect WireGuard'),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: wgConnected
                    ? AppColors.tertiaryColor
                    : AppColors.secondaryColor,
                foregroundColor: Colors.black,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Server Configuration',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _wgBusy ? null : _generateKeys,
                        icon: const Icon(Icons.fingerprint, size: 18),
                        label: const Text('GEN KEYS'),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: _wgBusy ? null : _resetToWarp,
                    icon: const Icon(Icons.restore, size: 18),
                    label: const Text('RESET TO WARP DEFAULTS'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryColor,
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (_generatedPublicKey.isNotEmpty) ...[
                    _CopyBox(
                      label: 'YOUR PUBLIC KEY (add to server)',
                      value: _generatedPublicKey,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _ConfigField(
                    controller: _endpointCtrl,
                    label: 'Server endpoint',
                    hint: WireGuardConfig.warpServerAddress,
                  ),
                  _ConfigField(
                    controller: _addressCtrl,
                    label: 'Interface address',
                    hint: WireGuardConfig.warpAddress,
                  ),
                  _ConfigField(
                    controller: _dnsCtrl,
                    label: 'DNS (optional)',
                    hint: WireGuardConfig.warpDns,
                  ),
                  _ConfigField(
                    controller: _privateKeyCtrl,
                    label: 'Client private key',
                    hint: 'base64 44 chars',
                    monospace: true,
                  ),
                  _ConfigField(
                    controller: _peerKeyCtrl,
                    label: 'Server public key',
                    hint: 'base64 44 chars',
                    monospace: true,
                  ),
                  _ConfigField(
                    controller: _allowedIpsCtrl,
                    label: 'Allowed IPs',
                    hint: WireGuardConfig.warpAllowedIps,
                    monospace: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          const SectionHeader(
            title: 'Device',
            subtitle: 'Target platform info',
          ),
          const SizedBox(height: 12),
          if (_deviceInfo.isEmpty)
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Unavailable on this platform',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            )
          else
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    _DetailRow('Device', _deviceInfo['device']?.toString() ?? '-'),
                    _DetailRow('Model', _deviceInfo['model']?.toString() ?? '-'),
                    _DetailRow('Android', _deviceInfo['android']?.toString() ?? '-'),
                    _DetailRow('SDK', _deviceInfo['sdk']?.toString() ?? '-'),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionHeader(
                title: 'Activity Log',
                subtitle: 'Tunnel event feed',
              ),
              if (_logs.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() => _logs.clear()),
                  child: Text(
                    'CLEAR',
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: AppColors.primaryColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.cardAltColor,
              borderRadius: BorderRadius.zero,
              border: Border.all(color: AppColors.borderColor),
            ),
            padding: const EdgeInsets.all(12),
            child: _logs.isEmpty
                ? const Center(
                    child: Text(
                      '> awaiting events',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: AppColors.textColor,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        _logs[index],
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          height: 1.4,
                          color: AppColors.textColor,
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          Text(
            'Routes all traffic through Cloudflare WARP (AllowedIPs 0.0.0.0/0, '
            'DNS 1.1.1.1). Keep-alive pings and the whole app egress via the '
            'tunnel, bypassing ISP-level 403 blocks and timeouts.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _WgStatusCard extends StatelessWidget {
  final String stage;
  final String endpoint;
  final String latency;
  final String handshake;
  final String downloadSpeed;
  final String uploadSpeed;
  final String totalDown;
  final String totalUp;

  const _WgStatusCard({
    required this.stage,
    required this.endpoint,
    required this.latency,
    required this.handshake,
    required this.downloadSpeed,
    required this.uploadSpeed,
    required this.totalDown,
    required this.totalUp,
  });

  static const _stageLabels = {
    'connected': 'CONNECTED',
    'connecting': 'CONNECTING',
    'disconnected': 'DISCONNECTED',
    'error': 'CONNECTION ERROR',
  };

  @override
  Widget build(BuildContext context) {
    final connected = stage == 'connected';
    final color = connected
        ? AppColors.secondaryColor
        : (stage == 'connecting')
            ? AppColors.primaryColor
            : (stage == 'error')
                ? AppColors.tertiaryColor
                : AppColors.textColor;

    return SizedBox(
      height: 150,
      child: Card(
        margin: EdgeInsets.zero,
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 3)),
          ),
          child: Center(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.zero,
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Icon(
                  connected ? Icons.shield : Icons.shield_outlined,
                  color: color,
                  size: 22,
                ),
              ),
              title: Text(
                _stageLabels[stage] ?? stage.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      children: [
                        _Stat('DOWN', downloadSpeed, AppColors.secondaryColor),
                        _Stat('UP', uploadSpeed, AppColors.primaryColor),
                        _Stat('LATENCY', latency, AppColors.white),
                      ],
                    ),
                    Wrap(
                      spacing: 12,
                      children: [
                        _Stat('TOTAL', '$totalDown / $totalUp', AppColors.white),
                        _Stat('HANDSHAKE', handshake, AppColors.textColor),
                      ],
                    ),
                  ],
                ),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.zero,
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Text(
                  connected ? 'LIVE' : stage.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Stat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(fontSize: 11, height: 1.6),
        children: [
          TextSpan(
            text: '$label ',
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
          TextSpan(text: value, style: const TextStyle(color: AppColors.white)),
        ],
      ),
    );
  }
}

class _ConfigField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool monospace;

  const _ConfigField({
    required this.controller,
    required this.label,
    required this.hint,
    this.monospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        style: TextStyle(
          fontFamily: monospace ? 'monospace' : null,
          color: AppColors.white,
          fontSize: 13,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textColor),
          labelStyle: const TextStyle(
            color: AppColors.textColor,
            letterSpacing: 0.8,
          ),
          filled: true,
          fillColor: AppColors.cardAltColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: AppColors.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: AppColors.primaryColor),
          ),
        ),
      ),
    );
  }
}

class _CopyBox extends StatelessWidget {
  final String label;
  final String value;

  const _CopyBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.secondaryColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.cardAltColor,
            border: Border.all(color: AppColors.secondaryColor.withValues(alpha: 0.4)),
          ),
          child: SelectableText(
            value,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: AppColors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
