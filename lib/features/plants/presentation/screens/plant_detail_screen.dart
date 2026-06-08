import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:planticula/features/plants/domain/entities/plant.dart';
import 'package:planticula/features/plants/presentation/bloc/plants_bloc.dart';

class PlantDetailScreen extends StatelessWidget {
  final Plant plant;

  const PlantDetailScreen({
    super.key,
    required this.plant,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar con imagen expandible
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: plant.imageUrl != null
                  ? Image.network(
                      plant.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholder(context),
                    )
                  : _buildPlaceholder(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  // TODO: Editar planta
                  _showNotImplemented(context);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _showDeleteConfirmation(context),
              ),
            ],
          ),

          // Contenido
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre y badges
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plant.name,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            if (plant.scientificName != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                plant.scientificName!,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.7),
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (plant.needsWatering)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.water_drop,
                                size: 16,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '¡Riego!',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Info cards en grid
                  Row(
                    children: [
                      if (plant.location != null)
                        Expanded(
                          child: _buildInfoCard(
                            context,
                            icon: Icons.location_on_outlined,
                            title: 'Ubicación',
                            value: plant.location!,
                          ),
                        ),
                      if (plant.location != null && plant.acquiredDate != null)
                        const SizedBox(width: 12),
                      if (plant.acquiredDate != null)
                        Expanded(
                          child: _buildInfoCard(
                            context,
                            icon: Icons.calendar_today_outlined,
                            title: 'Adquirida',
                            value:
                                '${plant.acquiredDate!.day}/${plant.acquiredDate!.month}/${plant.acquiredDate!.year}',
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Info de riego
                  if (plant.hasWateringReminder) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            context,
                            icon: Icons.water_drop_outlined,
                            title: 'Frecuencia',
                            value: 'Cada ${plant.wateringFrequency} días',
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            context,
                            icon: plant.needsWatering
                                ? Icons.warning_amber
                                : Icons.event_available,
                            title: 'Próximo riego',
                            value: _formatNextWatering(),
                            color: plant.needsWatering
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Botón de regar
                  if (plant.hasWateringReminder)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _onWaterPlant(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: plant.needsWatering
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.surface,
                          foregroundColor: plant.needsWatering
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurface,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: Icon(
                          Icons.water_drop,
                          color: plant.needsWatering ? null : Colors.blue,
                        ),
                        label: Text(
                          plant.needsWatering
                              ? '¡Regar ahora!'
                              : 'Registrar riego',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  if (plant.hasWateringReminder) const SizedBox(height: 24),

                  // Notas
                  if (plant.notes != null && plant.notes!.isNotEmpty) ...[
                    Text(
                      'Notas',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        plant.notes!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Fechas del sistema
                  Text(
                    'Información del sistema',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (plant.createdAt != null)
                    Text(
                      'Creada: ${plant.createdAt!.day}/${plant.createdAt!.month}/${plant.createdAt!.year}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                    ),
                  if (plant.updatedAt != null)
                    Text(
                      'Actualizada: ${plant.updatedAt!.day}/${plant.updatedAt!.month}/${plant.updatedAt!.year}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Icon(
        Icons.local_florist,
        size: 80,
        color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.5),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    Color? color,
  }) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: effectiveColor, size: 24),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: effectiveColor,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _formatNextWatering() {
    if (plant.nextWatering == null) return 'No programado';

    final now = DateTime.now();
    final next = plant.nextWatering!;
    final difference = next.difference(now).inDays;

    if (difference < 0) return 'Atrasado ${difference.abs()} días';
    if (difference == 0) return 'Hoy';
    if (difference == 1) return 'Mañana';
    return 'En $difference días';
  }

  void _onWaterPlant(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar riego'),
        content: Text('¿Marcar "${plant.name}" como regada?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<PlantsBloc>().add(PlantWaterRequested(plant.id));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('¡Riego registrado!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar planta?'),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${plant.name}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              context.read<PlantsBloc>().add(PlantDeleteRequested(plant.id));
              Navigator.pop(context);
              context.pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${plant.name}" eliminada'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showNotImplemented(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad disponible en próxima versión'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
