import 'package:flutter/material.dart';

import '../../core/theme/app_dimens.dart';

/// Shows a modal bottom sheet styled by the design system (drag handle,
/// rounded top corners, optional title).
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        left: AppDimens.lg,
        right: AppDimens.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppDimens.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppDimens.lg),
          ],
          Flexible(child: child),
        ],
      ),
    ),
  );
}
