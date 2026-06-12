import 'package:flutter/material.dart';

import '../../core/theme/app_dimens.dart';

/// Section title with optional emoji, trailing info and "see all" action.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? emoji;
  final String? trailing;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.emoji,
    this.trailing,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        top: AppDimens.xl,
        bottom: AppDimens.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              emoji != null ? '$title $emoji' : title,
              style: theme.textTheme.headlineSmall,
            ),
          ),
          if (trailing != null)
            Text(trailing!, style: theme.textTheme.labelMedium),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
