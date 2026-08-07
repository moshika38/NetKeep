import 'package:flutter/material.dart';
import 'package:netkeep/utils/theme.dart';

class AppBtns extends StatelessWidget {
  final VoidCallback? onTap;
  const AppBtns({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 10),
            Icon(Icons.power_settings_new_outlined, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              "Start Keep-Alive",
              style: Theme.of(
                context,
              ).textTheme.bodyLarge!.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
