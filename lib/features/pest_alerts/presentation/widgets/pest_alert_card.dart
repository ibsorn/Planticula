import 'package:flutter/material.dart';
import 'package:planticula/core/theme/app_colors.dart';
import 'package:planticula/features/pest_alerts/domain/entities/pest_alert.dart';
import 'package:planticula/features/pest_alerts/presentation/widgets/severity_badge.dart';
import 'package:planticula/shared/widgets/app_badge.dart';
import 'package:planticula/shared/widgets/domain_chip.dart';

class PestAlertCard extends StatelessWidget {
  final PestAlert alert;
  final bool showDistance;
  final VoidCallback onTap;
  final VoidCallback? onConfirm;
  final VoidCallback? onMarkResolved;
  final VoidCallback? onDelete;

  const PestAlertCard({
    super.key,
    required this.alert,
    required this.showDistance,
    required this.onTap,
    this.onConfirm,
    this.onMarkResolved,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con foto o placeholder
            Stack(
              children: [
                Container(
                  height: 160,
                  width: double.infinity,
                  color: Color(alert.severity.colorValue).withValues(alpha: 0.1),
                  child: alert.photoUrl != null
                      ? Image.network(
                          alert.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                ),
                // Badge de severidad
                Positioned(
                  top: 8,
                  left: 8,
                  child: SeverityBadge(severity: alert.severity),
                ),
                // Badge de distancia
                if (showDistance && alert.distanceDisplay != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: AppBadge(
                      label: alert.distanceDisplay!,
                      emoji: '📍',
                      color: Colors.black87,
                    ),
                  ),
              ],
            ),

            // Contenido
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alert.pestTypeDisplay,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      if (alert.confirmedByCount != null && alert.confirmedByCount! > 0)
                        DomainChip.primary(
                          label: '${alert.confirmedByCount}',
                          emoji: '👥',
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.locationDisplay,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(alert.reportedAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (alert.isResolved) ...[
                        const SizedBox(width: 12),
                        const Text(
                          '✅ Resuelta',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Acciones
                  if (onConfirm != null || onMarkResolved != null || onDelete != null)
                    Row(
                      children: [
                        if (onConfirm != null)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onConfirm,
                              icon: const Icon(Icons.thumb_up, size: 16),
                              label: const Text('Confirmar'),
                            ),
                          ),
                        if (onMarkResolved != null) ...[
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: onMarkResolved,
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('Resuelta'),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (onDelete != null)
                          IconButton(
                            onPressed: onDelete,
                            icon: const Icon(Icons.delete_outline),
                            color: colorScheme.error,
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🐛', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 8),
          Text(
            'Sin foto',
            style: TextStyle(
              color: Color(alert.severity.colorValue).withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
