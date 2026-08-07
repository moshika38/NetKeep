import 'package:flutter/material.dart';
import 'package:netkeep/utils/theme.dart';
import 'package:netkeep/widgets/app.bar.dart';
import 'package:netkeep/widgets/network_widgets/usage.bar.dart';
import 'package:netkeep/widgets/network_widgets/usage.hero.dart';
import 'package:netkeep/widgets/network_widgets/usage.table.dart';
import 'package:netkeep/widgets/section.header.dart';

class NetworkScreen extends StatelessWidget {
  const NetworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const NetKeepAppBar(title: 'Network'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(
            title: 'Data Usage',
            subtitle: 'Network statistics overview',
          ),
          const SizedBox(height: 12),
          const UsageHero(
            amount: "4.8",
            unit: "GB",
            caption: "of 7 GB plan · Resets in 12 days",
            progress: 0.68,
            download: "3.6 GB",
            upload: "1.2 GB",
          ),
          const SizedBox(height: 28),
          const SectionHeader(
            title: 'This Month',
            subtitle: 'Weekly network traffic',
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
                children: const [
                  UsageBar(
                    icon: Icons.smartphone,
                    title: "Mobile Data",
                    value: "2.9 GB",
                    progress: 0.6,
                    color: AppColors.primaryColor,
                  ),
                  Divider(height: 28, color: Colors.white12),
                  UsageBar(
                    icon: Icons.wifi,
                    title: "Wi-Fi",
                    value: "1.9 GB",
                    progress: 0.4,
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
}
