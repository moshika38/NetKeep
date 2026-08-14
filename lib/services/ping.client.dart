import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// Classification of a failed probe, used to render distinct console output.
enum PingErrorKind { none, timeout, dns, network, invalidUrl }

/// Outcome of a single HTTPS keep-alive probe.
///
/// [rttMs] is measured with a [Stopwatch] (monotonic) so it is never skewed by
/// wall-clock changes. A completed HTTP exchange that yields a status code is
/// always treated as a success - even 4xx/5xx, because the server responded;
/// only real socket-level failures (DNS, timeout, no route, TLS) are failures.
class PingResult {
  final bool ok;
  final PingErrorKind errorKind;
  final int? statusCode;
  final int rttMs;
  final String targetUrl;
  final bool viaFallback;

  const PingResult.success({
    required this.statusCode,
    required this.rttMs,
    required this.targetUrl,
    this.viaFallback = false,
  }) : ok = true,
       errorKind = PingErrorKind.none;

  const PingResult.failure({
    required this.errorKind,
    required this.rttMs,
    required this.targetUrl,
  }) : ok = false,
       statusCode = null,
       viaFallback = false;

  /// True when the network itself is unreachable (as opposed to an HTTP-level
  /// response or a malformed target).
  bool get connectionLost => !ok && errorKind != PingErrorKind.invalidUrl;

  /// Marks this successful probe as having been served by a fallback target.
  PingResult asFallback() => PingResult.success(
    statusCode: statusCode,
    rttMs: rttMs,
    targetUrl: targetUrl,
    viaFallback: true,
  );
}

/// Minimal HTTPS keep-alive probe client backed by [Dio].
///
/// Deliberately mirrors the observed Z Pinger configuration:
///  * a single long-lived [Dio] instance is reused across every probe so the
///    underlying `dart:io` [HttpClient] connection pool (persistent
///    connections / keep-alive) can serve subsequent probes without a fresh
///    TCP/TLS handshake;
///  * `validateStatus: (status) => true` - every HTTP status code (200, 301,
///    403, 404, 429, 500, ...) is a valid response, not an exception, so the
///    probe only "fails" on transport-level errors (DNS, TCP, TLS, timeout);
///  * a 10 second connect timeout;
///  * HTTPS HEAD requests only, so a probe moves zero payload bytes.
///
/// No fake browser headers, no User-Agent spoofing, no TLS validation bypass:
/// certificate validation stays fully secure.
class PingClient {
  PingClient({this._connectTimeout = const Duration(seconds: 10)});

  final Duration _connectTimeout;

  Dio? _dio;

  Dio get _client => _dio ??= _buildClient();

  Dio _buildClient() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: _connectTimeout,
        sendTimeout: _connectTimeout,
        receiveTimeout: _connectTimeout,
        validateStatus: (_) => true,
      ),
    );
    // Keep the underlying persistent connection alive longer than the
    // `dart:io` default (3s) so consecutive probes can reuse the same socket
    // across intervals up to 60s without a fresh TCP/TLS handshake. dart:io
    // does not expose a raw SO_KEEPALIVE socket option; idleTimeout is the
    // closest knob and directly controls socket lifetime/reuse.
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.idleTimeout = const Duration(seconds: 60);
        return client;
      },
    );
    return dio;
  }

  /// Runs a single HTTPS HEAD probe against [url] and returns a [PingResult].
  ///
  /// [timeout] overrides the connect timeout (used to keep fallback probing
  /// from inflating the loop cadence during an outage).
  Future<PingResult> probe(String url, {Duration? timeout}) async {
    final effectiveTimeout = timeout ?? _connectTimeout;
    final stopwatch = Stopwatch()..start();
    try {
      final response = await _client.head<dynamic>(
        url,
        options: Options(
          connectTimeout: effectiveTimeout,
          sendTimeout: effectiveTimeout,
          receiveTimeout: effectiveTimeout,
        ),
      );
      stopwatch.stop();
      return PingResult.success(
        statusCode: response.statusCode ?? 0,
        rttMs: stopwatch.elapsedMilliseconds,
        targetUrl: url,
      );
    } on DioException catch (error) {
      stopwatch.stop();
      return PingResult.failure(
        errorKind: _classify(error),
        rttMs: stopwatch.elapsedMilliseconds,
        targetUrl: url,
      );
    } catch (_) {
      stopwatch.stop();
      return PingResult.failure(
        errorKind: PingErrorKind.network,
        rttMs: stopwatch.elapsedMilliseconds,
        targetUrl: url,
      );
    }
  }

  PingErrorKind _classify(DioException error) {
    final message = error.message?.toLowerCase() ?? '';
    if (message.contains('invalid url') || error.error is ArgumentError) {
      return PingErrorKind.invalidUrl;
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return PingErrorKind.timeout;
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
      case DioExceptionType.badResponse:
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        final cause = error.error;
        if (cause is SocketException) {
          final causeMessage = cause.message.toLowerCase();
          if (causeMessage.contains('failed host lookup') ||
              causeMessage.contains('getaddrinfo') ||
              causeMessage.contains('nodename nor servname')) {
            return PingErrorKind.dns;
          }
          return PingErrorKind.network;
        }
        return PingErrorKind.network;
    }
  }
}
