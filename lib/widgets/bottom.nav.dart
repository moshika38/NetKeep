import 'package:flutter/material.dart';
import 'package:netkeep/utils/theme.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final List<IconData> icons;
  final List<String> labels;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
    required this.icons,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < icons.length; i++)
            Expanded(child: _buildItem(context, i)),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final active = index == currentIndex;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              width: active ? 68 : 40,
              height: 36,
              decoration: BoxDecoration(
                gradient: active
                    ? const LinearGradient(
                        colors: [AppColors.primaryColor, Color(0xFFEA580C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: active ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icons[index],
                size: 20,
                color: active ? Colors.white : AppColors.textColor,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              labels[index],
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? AppColors.primaryColor : AppColors.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
