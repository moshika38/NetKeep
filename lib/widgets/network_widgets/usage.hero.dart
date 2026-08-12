import 'package:flutter/material.dart';
import 'package:netkeep/utils/theme.dart';

class UsageHero extends StatelessWidget {
  final String amount;
  final String unit;
  final String caption;
  final double progress;
  final String download;
  final String upload;

  const UsageHero({
    super.key,
    required this.amount,
    required this.unit,
    required this.caption,
    required this.progress,
    required this.download,
    required this.upload,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.cardAltColor,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0x33FF7A1A),
              Color(0x11FFB84D),
              Colors.transparent,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.25, 1.0],
          ),
          border: Border(
            top: BorderSide(color: AppColors.primaryColor, width: 3),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "DATA USED",
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: AppColors.white.withValues(alpha: 0.75),
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  "${(progress * 100).round()}%",
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  amount,
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    unit,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(caption, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStat(
                    context,
                    icon: Icons.arrow_downward,
                    color: AppColors.primaryColor,
                    value: download,
                    label: "Download",
                  ),
                ),
                Container(width: 1, height: 32, color: AppColors.borderColor),
                Expanded(
                  child: _buildStat(
                    context,
                    icon: Icons.arrow_upward,
                    color: AppColors.accentColor,
                    value: upload,
                    label: "Upload",
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}
