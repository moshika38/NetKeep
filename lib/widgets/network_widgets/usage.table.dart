import 'package:flutter/material.dart';
import 'package:netkeep/utils/theme.dart';

class UsageRow {
  final String label;
  final String download;
  final String upload;
  final String total;
  final bool highlight;

  const UsageRow(
    this.label,
    this.download,
    this.upload,
    this.total, {
    this.highlight = false,
  });
}

class UsageTable extends StatelessWidget {
  final List<UsageRow> rows;

  const UsageTable({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 8),
            Divider(height: 1, color: AppColors.white.withValues(alpha: 0.06)),
            for (var i = 0; i < rows.length; i++) ...[
              _buildRow(context, rows[i]),
              if (i < rows.length - 1)
                Divider(
                  height: 1,
                  color: AppColors.white.withValues(alpha: 0.06),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          flex: 3,
          child: Text(
            "Data",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textColor,
              letterSpacing: 0.4,
            ),
          ),
        ),
        _headerCell(context, "Download"),
        _headerCell(context, "Upload"),
        _headerCell(context, "Total"),
      ],
    );
  }

  Widget _headerCell(BuildContext context, String label) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.right,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textColor,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, UsageRow row) {
    final valueStyle = Theme.of(context).textTheme.labelSmall!.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              row.label,
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: row.highlight
                    ? AppColors.primaryColor
                    : AppColors.textColor,
                fontWeight: row.highlight ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              row.download,
              textAlign: TextAlign.right,
              style: valueStyle,
            ),
          ),
          Expanded(
            child: Text(
              row.upload,
              textAlign: TextAlign.right,
              style: valueStyle,
            ),
          ),
          Expanded(
            child: Text(
              row.total,
              textAlign: TextAlign.right,
              style: valueStyle.copyWith(
                color: row.highlight ? AppColors.primaryColor : Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
