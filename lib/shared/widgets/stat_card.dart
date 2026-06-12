import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';

/// Card showing a big number with a label, tinted with a domain color.
class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final String? emoji;
  final Color accent;
  final Color deep;
  final Color soft;

  const StatCard({
    super.key,
    required this.value,
    required this.label,
    this.emoji,
    this.accent = AppColors.primary,
    this.deep = AppColors.primaryDeep,
    this.soft = AppColors.primarySoft,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = AppColors.softOf(context, accent, soft);
    final fg = AppColors.onSoftOf(context, deep, accent);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.lg,
        vertical: AppDimens.lg,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppDimens.cardRadius,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji != null ? '$emoji $value' : value,
            style: theme.textTheme.displaySmall?.copyWith(color: fg),
          ),
          const SizedBox(height: AppDimens.xs),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: fg.withValues(alpha: 0.85),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
