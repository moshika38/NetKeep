import 'package:flutter/material.dart';
import 'package:netkeep/utils/theme.dart';
import 'package:netkeep/widgets/home_widgets/app.header.dart';
import 'package:netkeep/widgets/home_widgets/home.app.bar.dart';
import 'package:netkeep/widgets/network_widgets/usage.bar.dart';
import 'package:netkeep/widgets/network_widgets/usage.hero.dart';
import 'package:netkeep/widgets/network_widgets/usage.table.dart';

class NetworkScreen extends StatelessWidget {
  const NetworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeAppBar.homeAppBar(context, "Network"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppHeader(
              title: "Data Usage",
              subtitle: "Network statistics overview",
            ),
            const SizedBox(height: 14),
            const UsageHero(
              amount: "4.8",
              unit: "GB",
              caption: "of 7 GB plan · Resets in 12 days",
              progress: 0.68,
              download: "3.6 GB",
              upload: "1.2 GB",
            ),
            const SizedBox(height: 24),
            const AppHeader(
              title: "This Month",
              subtitle: "Weekly network traffic",
            ),
            const SizedBox(height: 12),
            const UsageTable(
              rows: [
                UsageRow("Week 1", "0.8 GB", "0.3 GB", "1.1 GB"),
                UsageRow("Week 2", "1.1 GB", "0.4 GB", "1.5 GB"),
                UsageRow("Week 3", "0.9 GB", "0.3 GB", "1.2 GB", highlight: true),
                UsageRow("Week 4", "0.8 GB", "0.2 GB", "1.0 GB"),
              ],
            ),
            const SizedBox(height: 24),
            const AppHeader(
              title: "By Network",
              subtitle: "Mobile data vs Wi-Fi",
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBgColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.white.withOpacity(0.06)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const UsageBar(
                    icon: Icons.smartphone,
                    title: "Mobile Data",
                    value: "2.9 GB",
                    progress: 0.6,
                    color: AppColors.primaryColor,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Divider(
                      height: 1,
                      color: AppColors.white.withOpacity(0.06),
                    ),
                  ),
                  const UsageBar(
                    icon: Icons.wifi,
                    title: "Wi-Fi",
                    value: "1.9 GB",
                    progress: 0.4,
                    color: AppColors.secondaryColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
