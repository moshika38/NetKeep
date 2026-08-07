import 'package:flutter/material.dart';
import 'package:netkeep/utils/theme.dart';
import 'package:netkeep/widgets/settings_widgets/settings.tile.dart';

class ToggleTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const ToggleTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: icon,
      color: color,
      title: title,
      subtitle: subtitle,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primaryColor,
        activeTrackColor: AppColors.primaryColor.withValues(alpha: 0.3),
      ),
    );
  }
}
