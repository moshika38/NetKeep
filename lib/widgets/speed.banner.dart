import 'package:flutter/material.dart';

class SpeedBanner extends StatelessWidget {
  final String speed;
  final IconData icon;
  final Color color;
  const SpeedBanner({
    super.key,
    required this.speed,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon,size: 15,color: color,),
        const SizedBox(width: 3),
        Text(
          speed,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: color),
        ),
        const SizedBox(width: 8,),
        Text("Mbps", style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
