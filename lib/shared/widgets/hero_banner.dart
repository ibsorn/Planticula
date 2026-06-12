import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';

/// Large soft-colored banner card used for weather, celebrations and
/// prominent contextual messages.
class HeroBanner extends StatelessWidget {
  final Color accent;
  final Color deep;
  final Color soft;
  final String? emoji;
  final String title;
  final String? subtitle;
  final Widget? child;
  final Widget? trailing;
  final VoidCallback? onTap;

  const HeroBanner({
    super.key,
    required this.title,
    required this.accent,
    required this.deep,
    required this.soft,
    this.emoji,
    this.subtitle,
    this.child,
    this.trailing,
    this.onTap,
  });

  const HeroBanner.success({
    super.key,
    required this.title,
    this.emoji,
    this.subtitle,
    this.child,
    this.trailing,
    this.onTap,
  })  : accent = AppColors.primary,
        deep = AppColors.primaryDeep,
        soft = AppColors.primarySoft;

  const HeroBanner.weather({
    super.key,
    required this.title,
    this.emoji,
    this.subtitle,
    this.child,
    this.trailing,
    this.onTap,
  })  : accent = AppColors.sun,
        deep = AppColors.sunDeep,
        soft = AppColors.sunSoft;

  const HeroBanner.water({
    super.key,
    required this.title,
    this.emoji,
    this.subtitle,
    this.child,
    this.trailing,
    this.onTap,
  })  : accent = AppColors.water,
        deep = AppColors.waterDeep,
        soft = AppColors.waterSoft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = AppColors.softOf(context, accent, soft);
    final fg = AppColors.onSoftOf(context, deep, accent);

    return Material(
      color: bg,
      borderRadius: AppDimens.cardRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDimens.cardRadius,
        child: Padding(
          padding: AppDimens.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (emoji != null) ...[
                    Text(emoji!, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: AppDimens.md),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(color: fg),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: AppDimens.xs),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: fg.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              if (child != null) ...[
                const SizedBox(height: AppDimens.lg),
                child!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
