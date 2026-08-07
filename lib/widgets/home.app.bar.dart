import 'package:flutter/material.dart';
import 'package:netkeep/utils/theme.dart';

class HomeAppBar {
  static AppBar homeAppBar(BuildContext context, String title) {
    return AppBar(
      titleSpacing: 4,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryColor, AppColors.tertiaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.wifi, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  "Connection Keeper",
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: AppColors.primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.cardBgColor,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.secondaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondaryColor.withValues(alpha: 0.6),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                "42ms",
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: AppColors.secondaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.cardBgColor,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
          ),
          child: const Icon(Icons.signal_cellular_alt, size: 20),
        ),
        const SizedBox(width: 14),
      ],
    );
  }
}
