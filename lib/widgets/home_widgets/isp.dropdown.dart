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
      borderRadius: BorderRadius.circular(AppRadii.control),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cardBgColor,
          borderRadius: BorderRadius.circular(AppRadii.control),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.public,
                size: 15,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              selected.isRecommended
                  ? '${selected.name} (Recommended)'
                  : selected.name,
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
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  'SELECT ISP',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              for (var i = 0; i < supportedIsps.length; i++)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Material(
                    color: supportedIsps[i].url == selectedUrl
                        ? AppColors.primaryColor.withValues(alpha: 0.1)
                        : AppColors.cardAltColor,
                    borderRadius: BorderRadius.circular(AppRadii.tile),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadii.tile),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        onChanged(supportedIsps[i]);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadii.tile),
                          border: Border.all(
                            color: supportedIsps[i].url == selectedUrl
                                ? AppColors.primaryColor.withValues(alpha: 0.7)
                                : AppColors.borderColor,
                            width: supportedIsps[i].url == selectedUrl ? 1.5 : 1,
                          ),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.public,
                            color: supportedIsps[i].url == selectedUrl
                                ? AppColors.primaryColor
                                : AppColors.textColor,
                          ),
                          title: Text(
                            supportedIsps[i].isRecommended
                                ? '${supportedIsps[i].name} (Recommended)'
                                : supportedIsps[i].name,
                            style: TextStyle(
                              color: supportedIsps[i].url == selectedUrl
                                  ? AppColors.white
                                  : AppColors.textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: supportedIsps[i].url == selectedUrl
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primaryColor,
                                  size: 20,
                                )
                              : null,
                        ),
                      ),
                    ),
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
