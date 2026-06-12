import 'package:flutter/material.dart';

class MarketplaceLocationRequired extends StatelessWidget {
  final VoidCallback onRetry;

  const MarketplaceLocationRequired({
    super.key,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text('Ubicación requerida'),
            const SizedBox(height: 8),
            const Text(
              'Necesitamos tu ubicación para mostrar anuncios cercanos',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.my_location),
              label: const Text('Obtener ubicación'),
            ),
          ],
        ),
      ),
    );
  }
}
