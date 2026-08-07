import 'package:flutter/material.dart';
import 'package:netkeep/utils/theme.dart';

class HomeAppBar {
  static AppBar homeAppBar(BuildContext context,String title) {
    return AppBar(
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      actions: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.secondaryColor,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            SizedBox(width: 5),
            Text(
              "42ms",
              style: Theme.of(
                context,
              ).textTheme.bodySmall!.copyWith(color: AppColors.secondaryColor),
            ),
          ],
        ),
        SizedBox(width: 10),
        Icon(Icons.signal_cellular_alt),
        SizedBox(width: 30),
      ],
    );
  }
}
