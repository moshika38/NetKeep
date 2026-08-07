import 'package:flutter/material.dart';
import 'package:netkeep/utils/theme.dart';

class ProfileCards extends StatelessWidget {
  final bool isActive;
  final IconData icon;
  final String title;
  final String subTitle;
  final VoidCallback? onTap;
  const ProfileCards({
    super.key,
    required this.isActive,
    required this.icon,
    required this.title,
    required this.subTitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            width: double.infinity,
            height: 78,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primaryColor.withOpacity(0.10)
                  : AppColors.cardBgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive
                    ? AppColors.primaryColor.withOpacity(0.8)
                    : AppColors.white.withOpacity(0.06),
                width: isActive ? 1.5 : 1,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.primaryColor.withOpacity(0.12),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: isActive
                          ? const LinearGradient(
                              colors: [
                                AppColors.primaryColor,
                                Color(0xFFEA580C),
                              ],
                            )
                          : null,
                      color: isActive
                          ? null
                          : AppColors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      size: 22,
                      color: isActive ? Colors.white : AppColors.iconColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: isActive ? Colors.white : AppColors.textColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subTitle,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                  if (isActive)
                    Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primaryColor, Color(0xFFEA580C)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      ),
                    )
                  else
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: AppColors.white.withOpacity(0.3),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
