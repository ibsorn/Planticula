import 'package:flutter/material.dart';
import 'package:planticula/core/services/transplant_calculator.dart';
import 'package:planticula/features/plants/domain/entities/plant.dart';

class TransplantBanner extends StatelessWidget {
  final TransplantRecommendation recommendation;
  final Plant plant;
  final VoidCallback onTransplant;

  const TransplantBanner({
    super.key,
    required this.recommendation,
    required this.plant,
    required this.onTransplant,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUrgent = recommendation.isUrgent;

    final Color bannerColor = isUrgent
        ? theme.colorScheme.errorContainer
        : Colors.amber.shade50;
    final Color iconColor = isUrgent
        ? theme.colorScheme.error
        : Colors.amber.shade800;
    final Color textColor = isUrgent
        ? theme.colorScheme.onErrorContainer
        : Colors.amber.shade900;
    final Color borderColor = isUrgent
        ? theme.colorScheme.error.withAlpha(128)
        : Colors.amber.shade300;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.yard, size: 20, color: Colors.green.shade700),
            const SizedBox(width: 8),
            Text('Maceta', style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bannerColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isUrgent ? Icons.warning_amber_rounded : Icons.info_outline,
                    size: 20,
                    color: iconColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recommendation.status.displayName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        if (recommendation.reason != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            recommendation.reason!,
                            style: theme.textTheme.bodySmall?.copyWith(color: textColor),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (recommendation.recommendedPotSize != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    _PotSizeChip(
                      label: plant.plantPotSize.displayName,
                      sublabel: plant.plantPotSize.litersRange,
                      isCurrent: true,
                      color: Colors.grey,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward, size: 18, color: iconColor),
                    ),
                    _PotSizeChip(
                      label: recommendation.recommendedPotSize!.displayName,
                      sublabel: recommendation.recommendedPotSize!.litersRange,
                      isCurrent: false,
                      color: Colors.green,
                    ),
                  ],
                ),
              ],
              if (recommendation.notes != null) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.tips_and_updates, size: 14, color: textColor.withAlpha(180)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        recommendation.notes!,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: textColor.withAlpha(200),
                            fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: const Text('Registrar trasplante'),
                  onPressed: onTransplant,
                  style: FilledButton.styleFrom(
                    backgroundColor: isUrgent
                        ? theme.colorScheme.error
                        : Colors.green.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PotSizeChip extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool isCurrent;
  final Color color;

  const _PotSizeChip({
    required this.label,
    required this.sublabel,
    required this.isCurrent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isCurrent ? Colors.grey.shade100 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrent ? Colors.grey.shade400 : Colors.green.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isCurrent ? 'Actual' : 'Recomendada',
            style: theme.textTheme.labelSmall?.copyWith(
                color: color.withAlpha(180), fontSize: 10),
          ),
          Text(label,
              style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold, color: color.withAlpha(220))),
          Text(sublabel,
              style: theme.textTheme.labelSmall?.copyWith(
                  color: color.withAlpha(150), fontSize: 10)),
        ],
      ),
    );
  }
}
