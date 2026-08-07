import 'package:flutter/material.dart';
import 'package:netkeep/utils/theme.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 26,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primaryColor, AppColors.tertiaryColor],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (icon != null)
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16),
          ),
      ],
    );
  }
}
