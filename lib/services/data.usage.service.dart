import 'package:flutter/services.dart';
import 'package:usage_stats/usage_stats.dart';

class WeeklyUsage {
  final String weekName;
  final String mobileData;
  final String wifiData;
  final String totalData;
  final int mobileBytes;
  final int wifiBytes;

  WeeklyUsage({
    required this.weekName,
    required this.mobileData,
    required this.wifiData,
    required this.totalData,
    required this.mobileBytes,
    required this.wifiBytes,
  });
}

class DataUsageService {
  static const MethodChannel _channel = MethodChannel(
    'com.netkeep.app/network_stats',
  );
  static List<WeeklyUsage>? _cachedWeeklyData;

  static Future<bool> isPermissionGranted() async {
    bool? granted = await UsageStats.checkUsagePermission();
    return granted ?? false;
  }

  static Future<void> requestPermission() async {
    await UsageStats.grantUsagePermission();
  }

  static String formatBytes(int bytes) {
    if (bytes <= 0) return "0 MB";
    double mb = bytes / (1024 * 1024);
    if (mb < 1024) {
      return "${mb.toStringAsFixed(1)} MB";
    }
    double gb = mb / 1024;
    return "${gb.toStringAsFixed(2)} GB";
  }

  static Future<int> _fetchDeviceTotalBytes(
    DateTime start,
    DateTime end,
    bool isMobile,
  ) async {
    try {
      final int bytes = await _channel.invokeMethod('getDeviceTotalData', {
        'startTime': start.millisecondsSinceEpoch,
        'endTime': end.millisecondsSinceEpoch,
        'isMobile': isMobile,
      });
      return bytes;
    } catch (e) {
      return 0;
    }
  }

  static Future<List<WeeklyUsage>> getWeeklyBreakdown({
    bool forceRefresh = false,
  }) async {
    if (_cachedWeeklyData != null && !forceRefresh) {
      return _cachedWeeklyData!;
    }

    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;

    List<Map<String, int>> weeks = [
      {'start': 1, 'end': 7},
      {'start': 8, 'end': 14},
      {'start': 15, 'end': 21},
      {'start': 22, 'end': lastDay},
    ];

    List<Future<WeeklyUsage>> futures = weeks.asMap().entries.map((
      entry,
    ) async {
      int i = entry.key;
      int startDay = entry.value['start']!;
      int endDay = entry.value['end']!;

      DateTime startDate = DateTime(now.year, now.month, startDay, 0, 0, 0);
      DateTime endDate = DateTime(now.year, now.month, endDay, 23, 59, 59);

      final results = await Future.wait([
        _fetchDeviceTotalBytes(startDate, endDate, true),
        _fetchDeviceTotalBytes(startDate, endDate, false),
      ]);

      int mobileBytes = results[0];
      int wifiBytes = results[1];

      return WeeklyUsage(
        weekName: "Week ${i + 1}",
        mobileData: formatBytes(mobileBytes),
        wifiData: formatBytes(wifiBytes),
        totalData: formatBytes(mobileBytes + wifiBytes),
        mobileBytes: mobileBytes,
        wifiBytes: wifiBytes,
      );
    }).toList();

    _cachedWeeklyData = await Future.wait(futures);
    return _cachedWeeklyData!;
  }
}
