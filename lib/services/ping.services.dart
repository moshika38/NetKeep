import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:intl/intl.dart';

/// Measures round-trip latency through the active WireGuard tunnel by hitting
/// Cloudflare's `generate_204` endpoint. When the tunnel is up with
/// AllowedIPs 0.0.0.0/0 the request egresses via WARP, so the RTT reflects the
/// tunnel path (and confirms a live, 403-free route). Returns null on failure.
Future<int?> measureTunnelLatency() async {
  final httpClient = http.Client();
  try {
    final stopwatch = Stopwatch()..start();
    final response = await httpClient
        .head(Uri.parse('https://cp.cloudflare.com/generate_204'))
        .timeout(const Duration(seconds: 4));
    stopwatch.stop();
    // Cloudflare's generate_204 answers with 204 when the egress path is
    // healthy. A 403/429 means the route is still blocked even through the
    // tunnel, so report it as a failed probe.
    if (response.statusCode == 403 || response.statusCode == 429) {
      return null;
    }
    return stopwatch.elapsedMilliseconds;
  } catch (_) {
    return null;
  } finally {
    httpClient.close();
  }
}

class PingService {
  Timer? _pingTimer;
  late http.Client _httpClient;

  String targetUrl = dotenv.env['TARGET_URL'] ?? 'https://google.com';

  PingService() {
    _httpClient = http.Client();
  }

  void setTargetUrl(String url) {
    targetUrl = url;
  }

  void startNormalMode(void Function((String, String) log) onLogGenerated) {
    WakelockPlus.disable();
    stopPing();

    final String initTime = DateFormat('HH:mm:ss').format(DateTime.now());
    onLogGenerated(("[$initTime]", " Running [NORMAL MODE] (5s interval)..."));
    onLogGenerated(("[$initTime]", " Initializing connection... OK"));

    _pingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final stopwatch = Stopwatch()..start();
      final String currentTime = DateFormat('HH:mm:ss').format(DateTime.now());

      try {
        final response = await _httpClient
            .head(
              Uri.parse(targetUrl),
              headers: {
                'Connection': 'keep-alive',
                'User-Agent': 'Flutter-PingService/1.0',
              },
            )
            .timeout(const Duration(seconds: 4));

        stopwatch.stop();

        final double timeTotal = stopwatch.elapsedMilliseconds / 1000.0;
        final int statusCode = response.statusCode;

        onLogGenerated((
          "[$currentTime]",
          " Normal Mode | Time: ${timeTotal.toStringAsFixed(3)}s | Status: $statusCode",
        ));
      } catch (e) {
        stopwatch.stop();
        final double timeTotal = stopwatch.elapsedMilliseconds / 1000.0;

        onLogGenerated((
          "[$currentTime]",
          " Normal Mode | Time: ${timeTotal.toStringAsFixed(3)}s | Status: Timeout/Error",
        ));
      }
    });
  }

  void startSaverMode(void Function((String, String) log) onLogGenerated) {
    WakelockPlus.disable();
    stopPing();

    final String initTime = DateFormat('HH:mm:ss').format(DateTime.now());
    onLogGenerated(("[$initTime]", " Running [SAVER MODE] (20s interval)..."));

    _pingTimer = Timer.periodic(const Duration(seconds: 20), (timer) async {
      final stopwatch = Stopwatch()..start();
      final String currentTime = DateFormat('HH:mm:ss').format(DateTime.now());

      try {
        final response = await _httpClient
            .head(
              Uri.parse(targetUrl),
              headers: {
                'Connection': 'keep-alive',
                'User-Agent': 'Flutter-PingService/1.0',
              },
            )
            .timeout(const Duration(seconds: 4));

        stopwatch.stop();
        final double timeTotal = stopwatch.elapsedMilliseconds / 1000.0;

        onLogGenerated((
          "[$currentTime]",
          " Saver Mode | Time: ${timeTotal.toStringAsFixed(3)}s | Status: ${response.statusCode}",
        ));
      } catch (e) {
        stopwatch.stop();
        final double timeTotal = stopwatch.elapsedMilliseconds / 1000.0;

        onLogGenerated((
          "[$currentTime]",
          " Saver Mode | Time: ${timeTotal.toStringAsFixed(3)}s | Status: Timeout/Error",
        ));
      }
    });
  }

  void startCustomMode(
    int intervalSeconds,
    void Function((String, String) log) onLogGenerated,
  ) {
    WakelockPlus.enable();
    stopPing();

    final String initTime = DateFormat('HH:mm:ss').format(DateTime.now());
    onLogGenerated((
      "[$initTime]",
      " Running [CUSTOM MODE] (${intervalSeconds}s interval)...",
    ));

    _pingTimer =
        Timer.periodic(Duration(seconds: intervalSeconds), (timer) async {
      final stopwatch = Stopwatch()..start();
      final String currentTime = DateFormat('HH:mm:ss').format(DateTime.now());

      try {
        final response = await _httpClient
            .head(
              Uri.parse(targetUrl),
              headers: {
                'Connection': 'keep-alive',
                'User-Agent': 'Flutter-PingService/1.0',
                'Accept-Encoding': 'gzip, deflate',
              },
            )
            .timeout(const Duration(seconds: 4));

        stopwatch.stop();
        final double timeTotal = stopwatch.elapsedMilliseconds / 1000.0;

        onLogGenerated((
          "[$currentTime]",
          " Custom (${intervalSeconds}s) | Time: ${timeTotal.toStringAsFixed(3)}s | Status: ${response.statusCode}",
        ));
      } catch (e) {
        stopwatch.stop();
        final double timeTotal = stopwatch.elapsedMilliseconds / 1000.0;

        onLogGenerated((
          "[$currentTime]",
          " Custom (${intervalSeconds}s) | Time: ${timeTotal.toStringAsFixed(3)}s | Status: Timeout/Error",
        ));
      }
    });
  }

  void stopPing() {
    _pingTimer?.cancel();
    _pingTimer = null;
    WakelockPlus.disable();
  }

  void dispose() {
    stopPing();
    _httpClient.close();
  }
}