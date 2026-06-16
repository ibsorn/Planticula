import 'package:flutter/material.dart';
import 'package:planticula/core/services/watering_calculator.dart';

class WateringRecommendationCard extends StatelessWidget {
  final WateringRecommendation recommendation;

  const WateringRecommendationCard({super.key, required this.recommendation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Watering frequency
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.water_drop, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Riego',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withAlpha(153))),
                      Text(recommendation.frequencyDescription,
                          style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Water amount
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.local_drink, color: theme.colorScheme.secondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cantidad por riego',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withAlpha(153))),
                      Text(recommendation.waterMlRange,
                          style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Sunlight
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.wb_sunny, color: theme.colorScheme.tertiary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sol necesario',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withAlpha(153))),
                      Text(recommendation.sunlightDescription,
                          style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
