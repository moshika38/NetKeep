import 'package:flutter/material.dart';
import 'package:netkeep/utils/theme.dart';

class NetKeepAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const NetKeepAppBar({super.key, required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryColor, AppColors.accentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.zero,
              border: Border.all(color: AppColors.primaryColor, width: 0.5),
            ),
            child: const Icon(Icons.wifi, size: 18, color: Colors.black),
          ),
          // Image.asset("assets/app_icon.png",width: 34,height: 34,fit: BoxFit.cover,),
          const SizedBox(width: 12),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: '> ',
                  style: TextStyle(
                    color: AppColors.secondaryColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: title.toUpperCase(),
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontSize: 17,
                    letterSpacing: 1.6,
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
