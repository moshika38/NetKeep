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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cardBgColor,
          borderRadius: BorderRadius.circular(AppRadii.control),
          border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.4)),
              ),
              child: const Icon(
                Icons.language,
                size: 16,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              selected.isRecommended
                  ? '${selected.name} (Recommended)'
                  : selected.name,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.primaryColor),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppColors.borderColor),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.tune, size: 16, color: AppColors.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'SELECT CONNECTION TARGET',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        letterSpacing: 1.2,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              for (var i = 0; i < supportedIsps.length; i++)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Material(
                    color: supportedIsps[i].url == selectedUrl
                        ? AppColors.primaryColor.withValues(alpha: 0.15)
                        : AppColors.cardBgColor,
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
                                ? AppColors.primaryColor
                                : AppColors.borderColor,
                            width: supportedIsps[i].url == selectedUrl ? 1.5 : 1,
                          ),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.radar,
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
                              fontWeight: FontWeight.w700,
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
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
