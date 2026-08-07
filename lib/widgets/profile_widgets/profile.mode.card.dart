import 'package:flutter/material.dart';
import 'package:netkeep/utils/theme.dart';

class ProfileModeSpec {
  final String label;
  final String value;
  const ProfileModeSpec(this.label, this.value);
}

class ProfileModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final Color accent;
  final List<ProfileModeSpec> specs;
  final String description;

  const ProfileModeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.accent,
    required this.specs,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.25), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 14),
          _buildBadge(context),
          const SizedBox(height: 14),
          _buildSpecs(context),
          const SizedBox(height: 14),
          _buildDescription(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accent, accent.withValues(alpha: 0.6)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, size: 22, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            badge,
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecs(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < specs.length; i++) ...[
            if (i > 0)
              Divider(height: 18, color: AppColors.white.withValues(alpha: 0.05)),
            _buildSpecRow(context, specs[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildSpecRow(BuildContext context, ProfileModeSpec spec) {
    return Row(
      children: [
        Text(
          spec.label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const Spacer(),
        Flexible(
          child: Text(
            spec.value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 15, color: accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            description,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
