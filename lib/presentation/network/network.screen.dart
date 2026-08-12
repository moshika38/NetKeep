import 'package:flutter/material.dart';
import 'package:netkeep/services/data.usage.service.dart';
import 'package:netkeep/utils/theme.dart';
import 'package:netkeep/widgets/app.bar.dart';
import 'package:netkeep/widgets/network_widgets/usage.hero.dart';
import 'package:netkeep/widgets/network_widgets/usage.table.dart';
import 'package:netkeep/widgets/section.header.dart';

class NetworkScreen extends StatefulWidget {
  const NetworkScreen({super.key});

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

// 1. 'with WidgetsBindingObserver' එකතු කරන්න
class _NetworkScreenState extends State<NetworkScreen>
    with WidgetsBindingObserver {
  bool _hasPermission = false;
  bool _isLoading = true;
  List<WeeklyUsage> _weeklyData = [];

  int _totalMobileBytes = 0;
  int _totalWifiBytes = 0;

  @override
  void initState() {
    super.initState();
    // 2. Lifecycle Observer එක Register කරන්න
    WidgetsBinding.instance.addObserver(this);
    _loadDataUsage();
  }

  @override
  void dispose() {
    // 3. Screen එක අයින් වෙද්දී Observer එක Remove කරන්න
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 4. User Settings වලින් ආපසු App එකට ආපු ගමන් මේ Method එක Auto Run වෙනවා
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadDataUsage();
    }
  }

  Future<void> _loadDataUsage() async {
    bool granted = await DataUsageService.isPermissionGranted();

    if (granted) {
      List<WeeklyUsage> data = await DataUsageService.getWeeklyBreakdown();
      _calculateTotals(data);

      if (mounted) {
        setState(() {
          _hasPermission = true;
          _weeklyData = data;
          _isLoading = false;
        });
      }

      List<WeeklyUsage> freshData = await DataUsageService.getWeeklyBreakdown(
        forceRefresh: true,
      );
      _calculateTotals(freshData);

      if (mounted) {
        setState(() {
          _weeklyData = freshData;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _hasPermission = false;
          _isLoading = false;
        });
      }
    }
  }

  void _calculateTotals(List<WeeklyUsage> data) {
    int mobile = 0;
    int wifi = 0;
    for (var item in data) {
      mobile += item.mobileBytes;
      wifi += item.wifiBytes;
    }
    _totalMobileBytes = mobile;
    _totalWifiBytes = wifi;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: NetKeepAppBar(title: 'Network'),
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryColor,  
          ),
        ),
      );
    }
    if (!_hasPermission) {
      final availableHeight =
          MediaQuery.of(context).size.height -
          kToolbarHeight -
          MediaQuery.of(context).padding.top -
          MediaQuery.of(context).padding.bottom -
          48;
      return Scaffold(
        appBar: const NetKeepAppBar(title: 'Network'),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: availableHeight),
              child: Center(
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 480),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardBgColor,
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadii.tile),
                          border: Border.all(
                            color: AppColors.primaryColor.withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          color: AppColors.primaryColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Usage Access Permission Required",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await DataUsageService.requestPermission();
                          _loadDataUsage();
                        },
                        icon: const Icon(Icons.lock_open, size: 18),
                        label: const Text("Grant Permission"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    int grandTotalBytes = _totalMobileBytes + _totalWifiBytes;
    String totalMobileFormatted = DataUsageService.formatBytes(
      _totalMobileBytes,
    );
    String totalWifiFormatted = DataUsageService.formatBytes(_totalWifiBytes);
    String grandTotalFormatted = DataUsageService.formatBytes(grandTotalBytes);

    List<UsageRow> tableRows = _weeklyData.map((item) {
      return UsageRow(
        item.weekName,
        item.mobileData,
        item.wifiData,
        item.totalData,
      );
    }).toList();

    return Scaffold(
      appBar: const NetKeepAppBar(title: 'Network'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SectionHeader(
                  title: 'Data Usage',
                  subtitle: 'Network statistics overview',
                ),
                const SizedBox(height: 12),
                UsageHero(
                  amount: grandTotalFormatted.split(' ').first,
                  unit: grandTotalFormatted.contains('GB') ? "GB" : "MB",
                  caption: "Total usage for current month",
                  progress: 1.0,
                  download: totalMobileFormatted,
                  upload: totalWifiFormatted,
                ),
                const SizedBox(height: 28),
                const SectionHeader(
                  title: 'This Month',
                  subtitle: 'Weekly network traffic',
                ),
                const SizedBox(height: 12),

                UsageTable(rows: tableRows),

                const SizedBox(height: 28),
                const SectionHeader(
                  title: 'By Network',
                  subtitle: 'Mobile data vs Wi-Fi',
                ),
                const SizedBox(height: 12),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildNetworkRow(
                          context,
                          icon: Icons.smartphone,
                          label: "Mobile Data",
                          value: totalMobileFormatted,
                          color: AppColors.primaryColor,
                        ),
                        const Divider(height: 28, color: AppColors.borderColor),
                        _buildNetworkRow(
                          context,
                          icon: Icons.wifi,
                          label: "Wi-Fi",
                          value: totalWifiFormatted,
                          color: AppColors.secondaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildNetworkRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
