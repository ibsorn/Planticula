import 'package:flutter/material.dart';

import '../../core/theme/app_dimens.dart';

/// Small solid pill badge (e.g. distance over a photo, price, status).
class AppBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color foreground;
  final String? emoji;

  const AppBadge({
    super.key,
    required this.label,
    required this.color,
    this.foreground = Colors.white,
    this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.sm + 2,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppDimens.radiusChip),
      ),
      child: Text(
        emoji != null ? '$emoji $label' : label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
