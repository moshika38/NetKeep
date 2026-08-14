import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.card),
          gradient: const LinearGradient(
            colors: [
              Color(0x2200F0FF),
              Color(0x117000FF),
              Colors.transparent,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.35, 1.0],
          ),
          border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "TOTAL DATA TRAFFIC",
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: AppColors.white.withValues(alpha: 0.85),
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    "${(progress * 100).round()}% CAP",
                    style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    fontFamily: GoogleFonts.orbitron().fontFamily,
                    color: AppColors.white,
                    height: 1.0,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    unit,
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      fontFamily: GoogleFonts.orbitron().fontFamily,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(caption, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primaryColor,
                ),
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
                    label: "Mobile Data",
                  ),
                ),
                Container(width: 1, height: 32, color: AppColors.borderColor),
                Expanded(
                  child: _buildStat(
                    context,
                    icon: Icons.arrow_upward,
                    color: AppColors.secondaryColor,
                    value: upload,
                    label: "Wi-Fi Data",
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
