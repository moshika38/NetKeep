import 'package:flutter/material.dart';
import 'package:netkeep/utils/theme.dart';

class _ProfileOption {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isCustom;
  const _ProfileOption(
    this.icon,
    this.title,
    this.subtitle,
    this.color, {
    this.isCustom = false,
  });
}

const _options = [
  _ProfileOption(
    Icons.sync,
    "Normal Mode",
    "Interval 15s · Balanced",
    AppColors.primaryColor,
  ),
  _ProfileOption(
    Icons.battery_charging_full,
    "Saver Mode (Recommended)",
    "Interval 60s · Power saving",
    AppColors.secondaryColor,
  ),
  _ProfileOption(
    Icons.tune,
    "Custom Mode",
    "Adjustable interval",
    AppColors.tertiaryColor,
    isCustom: true,
  ),
];

class ProfileDropdown extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final int customIntervalSeconds;
  final ValueChanged<int> onCustomIntervalChanged;

  const ProfileDropdown({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
    required this.customIntervalSeconds,
    required this.onCustomIntervalChanged,
  });

  /// The observed Z Pinger interval set; Custom Mode cycles through these.
  static const List<int> _customIntervals = [5, 10, 15, 30, 60];
  static const int _minIntervalSeconds = 5;
  static const int _maxIntervalSeconds = 60;

  @override
  Widget build(BuildContext context) {
    final option = _options[selectedIndex];
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: option.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.zero,
                border: Border.all(color: option.color.withValues(alpha: 0.35)),
              ),
              child: Icon(option.icon, color: option.color, size: 20),
            ),
            title: Text(
              option.isCustom
                  ? "Custom (${customIntervalSeconds}s)"
                  : option.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              option.isCustom
                  ? "Interval ${customIntervalSeconds}s · Adjustable"
                  : option.subtitle,
            ),
            trailing: const Icon(Icons.expand_more),
            onTap: () => _showPicker(context),
          ),
          if (option.isCustom)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Interval duration",
                    style: TextStyle(
                      color: AppColors.textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      _StepperButton(
                        icon: Icons.remove,
                        onPressed:
                            customIntervalSeconds > _minIntervalSeconds
                            ? () {
                                final index = _customIntervals.indexOf(
                                  customIntervalSeconds,
                                );
                                if (index > 0) {
                                  onCustomIntervalChanged(
                                    _customIntervals[index - 1],
                                  );
                                }
                              }
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          "${customIntervalSeconds}s",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _StepperButton(
                        icon: Icons.add,
                        onPressed:
                            customIntervalSeconds < _maxIntervalSeconds
                            ? () {
                                final index = _customIntervals.indexOf(
                                  customIntervalSeconds,
                                );
                                if (index >= 0 &&
                                    index < _customIntervals.length - 1) {
                                  onCustomIntervalChanged(
                                    _customIntervals[index + 1],
                                  );
                                }
                              }
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "SELECT PROFILE",
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              for (var i = 0; i < _options.length; i++)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  decoration: BoxDecoration(
                    color: i == selectedIndex
                        ? AppColors.primaryColor.withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.zero,
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

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  const _StepperButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.zero,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primaryColor.withValues(alpha: 0.12)
              : AppColors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: enabled
                ? AppColors.primaryColor
                : AppColors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled
              ? AppColors.primaryColor
              : AppColors.textColor.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
