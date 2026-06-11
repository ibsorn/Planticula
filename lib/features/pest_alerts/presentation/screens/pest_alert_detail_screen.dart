import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:planticula/features/pest_alerts/domain/entities/pest_alert.dart';
import 'package:planticula/features/pest_alerts/presentation/bloc/pest_alerts_bloc.dart';

class PestAlertDetailScreen extends StatelessWidget {
  final PestAlert alert;

  const PestAlertDetailScreen({
    super.key,
    required this.alert,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar con imagen
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: alert.photoUrl != null
                  ? Image.network(
                      alert.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
          ),

          // Contenido
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con tipo y severidad
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alert.pestTypeDisplay,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      _SeverityChip(severity: alert.severity),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Info cards
                  Row(
                    children: [
                      _buildInfoCard(
                        context,
                        icon: Icons.location_on,
                        title: 'Ubicación',
                        value: alert.locationDisplay,
                      ),
                      const SizedBox(width: 12),
                      if (alert.distanceDisplay != null)
                        _buildInfoCard(
                          context,
                          icon: Icons.near_me,
                          title: 'Distancia',
                          value: alert.distanceDisplay!,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _buildInfoCard(
                        context,
                        icon: Icons.calendar_today,
                        title: 'Reportado',
                        value: _formatDateFull(alert.reportedAt),
                      ),
                      const SizedBox(width: 12),
                      if (alert.confirmedByCount != null && alert.confirmedByCount! > 0)
                        _buildInfoCard(
                          context,
                          icon: Icons.people,
                          title: 'Confirmaciones',
                          value: '${alert.confirmedByCount}',
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Estado
                  if (alert.isResolved)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Plaga resuelta',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                                if (alert.resolvedAt != null)
                                  Text(
                                    'Resuelto el ${_formatDateFull(alert.resolvedAt!)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Notas
                  if (alert.notes != null && alert.notes!.isNotEmpty) ...[
                    Text(
                      'Observaciones',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(alert.notes!),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Acciones
                  Text(
                    'Acciones',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildActions(context),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.bug_report,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin foto disponible',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary, semanticLabel: title),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return BlocBuilder<PestAlertsBloc, PestAlertsState>(
      builder: (context, state) {
        final isMyAlert = alert.isOwnedBy(state.userLatitude.toString());
        // Nota: El userId real debería venir del auth, esto es simplificado

        if (isMyAlert) {
          // Acciones para mi alerta
          return Column(
            children: [
              if (!alert.isResolved)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: state.isProcessingAction
                        ? null
                        : () {
                            context.read<PestAlertsBloc>().add(
                                  PestAlertsMarkResolved(alert.id),
                                );
                            Navigator.pop(context);
                          },
                    icon: const Icon(Icons.check),
                    label: const Text('Marcar como resuelta'),
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: state.isProcessingAction
                      ? null
                      : () {
                          _showDeleteDialog(context);
                        },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Eliminar alerta'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ],
          );
        } else {
          // Acciones para alerta de otro
          return Column(
            children: [
              if (!alert.isResolved)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: state.isProcessingAction
                        ? null
                        : () {
                            context.read<PestAlertsBloc>().add(
                                  PestAlertsConfirmAlert(alert.id),
                                );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Has confirmado esta alerta'),
                              ),
                            );
                          },
                    icon: const Icon(Icons.thumb_up),
                    label: const Text('Confirmar que vi esta plaga'),
                  ),
                ),
            ],
          );
        }
      },
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar alerta'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar esta alerta? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              context.read<PestAlertsBloc>().add(PestAlertsDeleteAlert(alert.id));
              Navigator.pop(context); // Cerrar dialog
              Navigator.pop(context); // Cerrar detail screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Alerta eliminada')),
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

  String _formatDateFull(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 365) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()} meses atrás';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} ${diff.inDays == 1 ? 'día' : 'días'} atrás';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} ${diff.inHours == 1 ? 'hora' : 'horas'} atrás';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} min atrás';
    } else {
      return 'Ahora mismo';
    }
  }
}

class _SeverityChip extends StatelessWidget {
  final Severity severity;

  const _SeverityChip({required this.severity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(severity.colorValue),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            severity.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
