import 'package:flutter/material.dart';
import 'package:netkeep/utils/theme.dart';

class _ProfileOption {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _ProfileOption(this.icon, this.title, this.subtitle, this.color);
}

const _options = [
  _ProfileOption(
    Icons.sync,
    "Normal Mode",
    "Interval 5s · Balanced",
    AppColors.primaryColor,
  ),
  _ProfileOption(
    Icons.battery_charging_full,
    "Saver Mode (Recommended)",
    "Interval 10s · Power saving",
    AppColors.secondaryColor,
  ),
  _ProfileOption(
    Icons.sports_esports,
    "Game Mode",
    "Interval 2s · Low latency",
    AppColors.tertiaryColor,
  ),
];

class ProfileDropdown extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const ProfileDropdown({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final option = _options[selectedIndex];
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: option.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(option.icon, color: option.color, size: 20),
        ),
        title: Text(
          option.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(option.subtitle),
        trailing: const Icon(Icons.expand_more),
        onTap: () => _showPicker(context),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Select Profile",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (var i = 0; i < _options.length; i++)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  decoration: BoxDecoration(
                    color: i == selectedIndex
                        ? AppColors.primaryColor.withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: i == selectedIndex
                          ? AppColors.primaryColor
                          : AppColors.white.withValues(alpha: 0.06),
                      width: i == selectedIndex ? 1.5 : 1,
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(_options[i].icon, color: _options[i].color),
                    title: Text(_options[i].title),
                    subtitle: Text(_options[i].subtitle),
                    trailing: i == selectedIndex
                        ? const Icon(Icons.check, color: AppColors.primaryColor)
                        : null,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      onChanged(i);
                    },
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
