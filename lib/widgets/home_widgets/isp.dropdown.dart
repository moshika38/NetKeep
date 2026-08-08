import 'package:flutter/material.dart';
import 'package:netkeep/services/isp.config.dart';
import 'package:netkeep/utils/theme.dart';

class IspDropdown extends StatelessWidget {
  final String selectedUrl;
  final ValueChanged<IspConfig> onChanged;

  const IspDropdown({
    super.key,
    required this.selectedUrl,
    required this.onChanged,
  });

  IspConfig get _selected {
    return supportedIsps.firstWhere(
      (isp) => isp.url == selectedUrl,
      orElse: () => supportedIsps.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return InkWell(
      onTap: () => _showPicker(context),
      borderRadius: BorderRadius.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cardBgColor,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.public, size: 16, color: AppColors.primaryColor),
            const SizedBox(width: 8),
            Text(
              "ISP: ${selected.name}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.expand_more, size: 18, color: AppColors.textColor),
          ],
        ),
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
                  "SELECT ISP",
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              for (var i = 0; i < supportedIsps.length; i++)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  decoration: BoxDecoration(
                    color: supportedIsps[i].url == selectedUrl
                        ? AppColors.primaryColor.withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.zero,
                    border: Border.all(
                      color: supportedIsps[i].url == selectedUrl
                          ? AppColors.primaryColor
                          : AppColors.white.withValues(alpha: 0.06),
                      width: supportedIsps[i].url == selectedUrl ? 1.5 : 1,
                    ),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.public,
                      color: AppColors.primaryColor,
                    ),
                    title: Text(
                      supportedIsps[i].isRecommended
                          ? "${supportedIsps[i].name} (Recommended)"
                          : supportedIsps[i].name,
                    ),
                    trailing: supportedIsps[i].url == selectedUrl
                        ? const Icon(Icons.check, color: AppColors.primaryColor)
                        : null,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      onChanged(supportedIsps[i]);
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
