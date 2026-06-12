import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';

/// Actionable task row with an animated check, used in the "Today" screen.
///
/// The accent color identifies the task domain (water = blue,
/// transplant = orange...).
class TaskTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String? subtitle;
  final bool checked;
  final Color accent;
  final Color deep;
  final Color soft;
  final VoidCallback? onCheck;
  final VoidCallback? onTap;

  const TaskTile({
    super.key,
    required this.emoji,
    required this.title,
    required this.accent,
    required this.deep,
    required this.soft,
    this.subtitle,
    this.checked = false,
    this.onCheck,
    this.onTap,
  });

  const TaskTile.water({
    super.key,
    required this.emoji,
    required this.title,
    this.subtitle,
    this.checked = false,
    this.onCheck,
    this.onTap,
  })  : accent = AppColors.water,
        deep = AppColors.waterDeep,
        soft = AppColors.waterSoft;

  const TaskTile.transplant({
    super.key,
    required this.emoji,
    required this.title,
    this.subtitle,
    this.checked = false,
    this.onCheck,
    this.onTap,
  })  : accent = AppColors.soil,
        deep = AppColors.soilDeep,
        soft = AppColors.soilSoft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = AppColors.softOf(context, accent, soft);
    final fg = AppColors.onSoftOf(context, deep, accent);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: checked ? 0.55 : 1,
      child: Material(
        color: bg,
        borderRadius: AppDimens.cardRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppDimens.cardRadius,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.md,
              vertical: AppDimens.md,
            ),
            child: Row(
              children: [
                _AnimatedCheck(checked: checked, accent: accent, onTap: onCheck),
                const SizedBox(width: AppDimens.md),
                Text(emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: AppDimens.md),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: fg,
                      decoration:
                          checked ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(width: AppDimens.sm),
                  Text(
                    subtitle!,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: fg.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedCheck extends StatelessWidget {
  final bool checked;
  final Color accent;
  final VoidCallback? onTap;

  const _AnimatedCheck({
    required this.checked,
    required this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: checked ? 1.1 : 1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.elasticOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: checked ? accent : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: accent,
              width: 2,
            ),
          ),
          child: checked
              ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}
