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
    "Normal Model",
    "Interval 5s · Balanced",
    AppColors.primaryColor,
  ),
  _ProfileOption(
    Icons.battery_charging_full,
    "Saver Model",
    "Interval 10s · Power saving",
    AppColors.secondaryColor,
  ),
  _ProfileOption(
    Icons.sports_esports,
    "Game Model",
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
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [option.color, option.color.withValues(alpha: 0.6)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(option.icon, size: 22, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    option.subtitle,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: AppColors.iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: AppColors.cardBgColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "Select Profile",
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                "Choose a power profile",
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 14),
              for (var i = 0; i < _options.length; i++)
                _buildOptionTile(sheetContext, i),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionTile(BuildContext context, int index) {
    final option = _options[index];
    final selected = index == selectedIndex;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            onChanged(index);
          },
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? option.color.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? option.color.withValues(alpha: 0.5)
                    : AppColors.white.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: option.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(option.icon, size: 18, color: option.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.title,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        option.subtitle,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle, size: 20, color: option.color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
