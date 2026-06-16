import 'package:flutter/material.dart';

import '../../core/theme/app_dimens.dart';

/// Estado vacío/error reutilizable: emoji o icono grande, mensaje y una
/// acción opcional (botón).
///
/// Soporta tres usos:
/// - Vacío con emoji: `EmptyState(emoji: '🌱', title: ...)`
/// - Vacío con icono: `EmptyState(icon: Icons.storefront, title: ...)`
/// - Error con reintento: `EmptyState.error(message: ..., onRetry: ...)`
class EmptyState extends StatelessWidget {
  final String? emoji;
  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  const EmptyState({
    super.key,
    this.emoji,
    this.icon,
    this.iconColor,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
  }) : assert(emoji != null || icon != null,
            'EmptyState requires either an emoji or an icon');

  /// Variante de error con botón de reintento.
  const EmptyState.error({
    super.key,
    required String message,
    required VoidCallback onRetry,
    String title = 'Error',
  })  : emoji = null,
        icon = Icons.error_outline,
        iconColor = null,
        title = title,
        message = message,
        actionLabel = 'Reintentar',
        onAction = onRetry,
        actionIcon = Icons.refresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isError = icon == Icons.error_outline && emoji == null;
    final resolvedIconColor = iconColor ??
        (isError
            ? theme.colorScheme.error
            : theme.colorScheme.onSurface.withOpacity(0.3));

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null)
              Text(emoji!, style: const TextStyle(fontSize: 64))
            else
              Icon(icon, size: 64, color: resolvedIconColor),
            const SizedBox(height: AppDimens.lg),
            Text(
              title,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: AppDimens.sm),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: AppDimens.xl),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: Icon(actionIcon ?? Icons.add_rounded),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
