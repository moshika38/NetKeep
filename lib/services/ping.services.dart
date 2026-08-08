import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:intl/intl.dart';

class PingService {
  Timer? _pingTimer;
  late http.Client _httpClient;

  final String targetUrl = dotenv.env['TARGET_URL'] ?? 'https://google.com';

  PingService() {
    _httpClient = http.Client();
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