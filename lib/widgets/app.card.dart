import 'package:flutter/material.dart';
import 'package:netkeep/utils/theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
