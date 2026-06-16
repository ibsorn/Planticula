import 'package:flutter/material.dart';
import 'package:planticula/core/data/species/plant_species.dart';

class GrowthProgressBar extends StatelessWidget {
  final GrowthStage currentStage;

  const GrowthProgressBar({super.key, required this.currentStage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const stages = GrowthStage.values;
    final currentIndex = stages.indexOf(currentStage);

    return Row(
      children: stages.asMap().entries.map((entry) {
        final index = entry.key;
        final stage = entry.value;
        final isActive = index <= currentIndex;
        final isCurrent = index == currentIndex;

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (index > 0)
                    Expanded(
                      child: Container(
                        height: 3,
                        color: isActive ? theme.colorScheme.primary : theme.colorScheme.outline.withAlpha(51),
                      ),
                    ),
                  Container(
                    width: isCurrent ? 32 : 24,
                    height: isCurrent ? 32 : 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? theme.colorScheme.primary : theme.colorScheme.surface,
                      border: Border.all(
                        color: isActive ? theme.colorScheme.primary : theme.colorScheme.outline.withAlpha(77),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _stageIcon(stage),
                      size: isCurrent ? 16 : 12,
                      color: isActive ? theme.colorScheme.onPrimary : theme.colorScheme.outline,
                    ),
                  ),
                  if (index < stages.length - 1)
                    Expanded(
                      child: Container(
                        height: 3,
                        color: index < currentIndex
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withAlpha(51),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(stage.displayName,
                  style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface.withAlpha(102))),
            ],
          ),
        );
      }).toList(),
    );
  }

  IconData _stageIcon(GrowthStage stage) {
    // Nuevo sistema de 5 etapas
    switch (stage) {
      case GrowthStage.germination: return Icons.spa;        // Germinando
      case GrowthStage.seedling: return Icons.grass;         // Plántula
      case GrowthStage.development: return Icons.eco;        // Desarrollo
      case GrowthStage.mature: return Icons.park;            // Madura
      case GrowthStage.flowering: return Icons.local_florist; // Floración
    }
  }
}
