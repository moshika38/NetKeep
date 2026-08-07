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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF23221F), Color(0xFF2E2413)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryColor.withOpacity(0.14),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "Data Used",
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                        color: AppColors.white.withOpacity(0.75),
                        letterSpacing: 0.4,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        "${(progress * 100).round()}% used",
                        style: const TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      amount,
                      style: const TextStyle(
                        fontSize: 46,
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
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: AppColors.white.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  caption,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.white.withOpacity(0.08),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _buildStat(
                        context,
                        icon: Icons.arrow_downward,
                        color: AppColors.secondaryColor,
                        value: download,
                        label: "Download",
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 34,
                      color: AppColors.white.withOpacity(0.08),
                    ),
                    Expanded(
                      child: _buildStat(
                        context,
                        icon: Icons.arrow_upward,
                        color: AppColors.primaryColor,
                        value: upload,
                        label: "Upload",
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ],
    );
  }
}
