import 'package:flutter/material.dart';
import 'package:planticula/core/data/species/plant_species.dart';

class SpeciesCard extends StatelessWidget {
  final PlantSpecies species;
  final VoidCallback onTap;

  const SpeciesCard({super.key, required this.species, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(Icons.local_florist,
                    color: theme.colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(species.commonName,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        if (species.hasVarieties) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.tertiary.withAlpha(26),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('${species.varieties.length} var.',
                                style: TextStyle(fontSize: 10, color: theme.colorScheme.tertiary)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(species.scientificName,
                        style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSurface.withAlpha(153))),
                  ],
                ),
              ),
              if (species.hasVarieties)
                Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withAlpha(128)),
            ],
          ),
        ),
      ),
    );
  }
}
