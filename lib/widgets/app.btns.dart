import 'package:flutter/material.dart';
import 'package:netkeep/utils/theme.dart';

class AppBtns extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isActive;
  final String activeLabel;
  final String idleLabel;
  const AppBtns({
    super.key,
    this.onTap,
    this.isActive = false,
    this.activeLabel = 'Stop Keep-Alive',
    this.idleLabel = 'Start Keep-Alive',
  });

  @override
  Widget build(BuildContext context) {
    final gradient = isActive
        ? const LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF16A34A)])
        : const LinearGradient(colors: [Color(0xFFF5A623), Color(0xFFEA580C)]);
    final icon = isActive
        ? Icons.stop_circle_outlined
        : Icons.power_settings_new_outlined;
    final label = isActive ? activeLabel : idleLabel;
    final accent = isActive ? AppColors.secondaryColor : AppColors.primaryColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.4),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
