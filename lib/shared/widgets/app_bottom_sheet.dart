import 'package:flutter/material.dart';

import '../../core/theme/app_dimens.dart';

/// Muestra un bottom sheet modal con el estilo del design system:
/// drag handle, esquinas redondeadas, título opcional (con icono) y subtítulo.
///
/// Centraliza el boilerplate que antes se repetía en cada pantalla.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  String? subtitle,
  IconData? titleIcon,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      final theme = Theme.of(context);
      return Padding(
        padding: EdgeInsets.only(
          left: AppDimens.lg,
          right: AppDimens.lg,
          top: AppDimens.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppDimens.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (title != null) ...[
              const SizedBox(height: AppDimens.md),
              Row(
                children: [
                  if (titleIcon != null) ...[
                    Icon(titleIcon, color: theme.colorScheme.primary),
                    const SizedBox(width: AppDimens.sm),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppDimens.lg),
            Flexible(child: child),
          ],
        ),
      );
    },
  );
}
