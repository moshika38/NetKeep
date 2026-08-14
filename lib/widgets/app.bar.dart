import 'package:flutter/material.dart';
import 'package:netkeep/utils/theme.dart';

class NetKeepAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  const NetKeepAppBar({super.key, required this.title, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 16,
      actions: actions,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryColor, AppColors.accentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadii.tile),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withValues(alpha: 0.5),
                  blurRadius: 14,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.bolt, size: 20, color: Color(0xFF080B11)),
          ),
          const SizedBox(width: 12),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: '⚡ ',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 14,
                  ),
                ),
                TextSpan(
                  text: title.toUpperCase(),
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontSize: 16,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
