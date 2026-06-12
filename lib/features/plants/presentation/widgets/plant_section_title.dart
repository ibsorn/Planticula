import 'package:flutter/material.dart';

class PlantSectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const PlantSectionTitle({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold)),
      ],
    );
  }
}
