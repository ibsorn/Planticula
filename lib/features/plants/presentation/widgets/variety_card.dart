import 'package:flutter/material.dart';
import 'package:planticula/core/data/species/plant_species.dart';

class VarietyCard extends StatelessWidget {
  final PlantSpecies variety;
  final VoidCallback onTap;

  const VarietyCard({super.key, required this.variety, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(variety.commonName,
                        style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold)),
                  ),
                  // Watering info
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.water_drop, size: 14, color: Colors.blue.shade300),
                      const SizedBox(width: 2),
                      Text('${variety.wateringFrequencyIndoor}d',
                          style: theme.textTheme.bodySmall),
                      const SizedBox(width: 8),
                      Icon(Icons.wb_sunny, size: 14, color: Colors.orange.shade300),
                      const SizedBox(width: 2),
                      Text('${variety.sunlightHoursMin.round()}-${variety.sunlightHoursMax.round()}h',
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
              if (variety.description != null) ...[
                const SizedBox(height: 6),
                Text(variety.description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(179)),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 6),
              // Temperature range chip
              Wrap(
                spacing: 6,
                children: [
                  _MiniChip(
                    icon: Icons.thermostat,
                    label: '${variety.minTemperature}-${variety.maxTemperature}C',
                    color: Colors.deepOrange,
                  ),
                  if (variety.growthPhases.isNotEmpty && variety.growthPhases.last.description != null)
                    _MiniChip(
                      icon: Icons.timer,
                      label: variety.growthPhases.last.description!,
                      color: Colors.teal,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
