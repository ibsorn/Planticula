import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';

/// Pill chip tinted with a domain accent color (water, soil, pest...).
///
/// Example: `DomainChip.water(label: 'Riega hoy')` or a custom accent via
/// the default constructor.
class DomainChip extends StatelessWidget {
  final String label;
  final String? emoji;
  final IconData? icon;
  final Color accent;
  final Color deep;
  final Color soft;

  const DomainChip({
    super.key,
    required this.label,
    required this.accent,
    required this.deep,
    required this.soft,
    this.emoji,
    this.icon,
  });

  const DomainChip.primary({super.key, required this.label, this.emoji, this.icon})
      : accent = AppColors.primary,
        deep = AppColors.primaryDeep,
        soft = AppColors.primarySoft;

  const DomainChip.water({super.key, required this.label, this.emoji, this.icon})
      : accent = AppColors.water,
        deep = AppColors.waterDeep,
        soft = AppColors.waterSoft;

  const DomainChip.sun({super.key, required this.label, this.emoji, this.icon})
      : accent = AppColors.sun,
        deep = AppColors.sunDeep,
        soft = AppColors.sunSoft;

  const DomainChip.soil({super.key, required this.label, this.emoji, this.icon})
      : accent = AppColors.soil,
        deep = AppColors.soilDeep,
        soft = AppColors.soilSoft;

  const DomainChip.pest({super.key, required this.label, this.emoji, this.icon})
      : accent = AppColors.pest,
        deep = AppColors.pestDeep,
        soft = AppColors.pestSoft;

  const DomainChip.market({super.key, required this.label, this.emoji, this.icon})
      : accent = AppColors.market,
        deep = AppColors.marketDeep,
        soft = AppColors.marketSoft;

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.softOf(context, accent, soft);
    final fg = AppColors.onSoftOf(context, deep, accent);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.md,
        vertical: AppDimens.xs + 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimens.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emoji != null) ...[
            Text(emoji!, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: AppDimens.xs),
          ] else if (icon != null) ...[
            Icon(icon, size: 15, color: fg),
            const SizedBox(width: AppDimens.xs),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
