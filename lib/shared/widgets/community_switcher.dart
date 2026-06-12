import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';

/// Pill segmented control shown at the top of the Community tab to switch
/// between Pest Alerts (rose) and Marketplace (purple).
class CommunitySwitcher extends StatelessWidget {
  /// 0 = Plagas, 1 = Mercado.
  final int selected;

  const CommunitySwitcher({super.key, required this.selected});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.lg,
        AppDimens.sm,
        AppDimens.lg,
        AppDimens.md,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.xs),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppDimens.radiusChip),
        ),
        child: Row(
          children: [
            _Segment(
              label: 'Plagas',
              emoji: '🐛',
              isSelected: selected == 0,
              accent: AppColors.pest,
              deep: AppColors.pestDeep,
              soft: AppColors.pestSoft,
              onTap: () => context.go(AppConstants.routePestAlerts),
            ),
            _Segment(
              label: 'Mercado',
              emoji: '🛒',
              isSelected: selected == 1,
              accent: AppColors.market,
              deep: AppColors.marketDeep,
              soft: AppColors.marketSoft,
              onTap: () => context.go(AppConstants.routeMarketplace),
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final String emoji;
  final bool isSelected;
  final Color accent;
  final Color deep;
  final Color soft;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.accent,
    required this.deep,
    required this.soft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isSelected
        ? AppColors.softOf(context, accent, soft)
        : Colors.transparent;
    final fg = isSelected
        ? AppColors.onSoftOf(context, deep, accent)
        : theme.colorScheme.onSurfaceVariant;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: AppDimens.sm + 2),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppDimens.radiusChip),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: AppDimens.sm),
              Text(
                label,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: fg,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
