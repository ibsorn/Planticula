import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:planticula/features/soil_analysis/domain/entities/soil_analysis.dart';
import 'package:planticula/features/soil_analysis/presentation/bloc/soil_analysis_bloc.dart';

class AnalysisDetailScreen extends StatelessWidget {
  final SoilAnalysis analysis;

  const AnalysisDetailScreen({
    super.key,
    required this.analysis,
  });

  void _onRequestAnalysis(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Analizar imagen'),
        content: const Text(
          'Se procesará la imagen para determinar el tipo de sustrato, nivel de pH, humedad y otras características.\n\nEste proceso puede tardar unos segundos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<SoilAnalysisBloc>().add(
                    SoilAnalysisRequestAnalysis(analysis.id),
                  );
            },
            child: const Text('Analizar'),
          ),
        ],
      ),
    );
  }

  void _onDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar análisis'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar este análisis? La imagen también se eliminará permanentemente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              context.read<SoilAnalysisBloc>().add(
                    SoilAnalysisDeleteRequested(analysis.id),
                  );
              Navigator.pop(dialogContext);
              context.pop();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar con imagen expandible
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                analysis.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.broken_image,
                    size: 64,
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimaryContainer
                        .withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            actions: [
              if (analysis.isPending || analysis.hasError)
                IconButton(
                  icon: const Icon(Icons.science),
                  tooltip: 'Analizar',
                  onPressed: () => _onRequestAnalysis(context),
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Eliminar',
                onPressed: () => _onDelete(context),
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
                  // Header con estado
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Análisis de Sustrato',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDateTime(analysis.createdAt),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusChip(context),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Botón de análisis si está pendiente
                  if (analysis.isPending || analysis.hasError) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.science,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  analysis.isPending
                                      ? 'Esta imagen está esperando ser analizada por la IA'
                                      : 'El análisis anterior falló. Puedes intentarlo nuevamente.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () => _onRequestAnalysis(context),
                              icon: const Icon(Icons.science),
                              label: const Text('Analizar Imagen'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Resultados del análisis
                  if (analysis.isCompleted) ...[
                    Text(
                      'Resultados del Análisis',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),

                    if (analysis.soilType != null)
                      _buildResultCard(
                        context,
                        icon: Icons.grass,
                        title: 'Tipo de Sustrato',
                        value: analysis.soilType!.displayName,
                        description: analysis.soilType!.description,
                        color: Colors.brown,
                      ),

                    if (analysis.phLevel != null)
                      _buildResultCard(
                        context,
                        icon: Icons.science,
                        title: 'Nivel de pH',
                        value: analysis.phFormatted!,
                        description: _getPhDescription(analysis.phLevel!),
                        color: _getPhColor(analysis.phLevel!),
                      ),

                    if (analysis.moistureLevel != null)
                      _buildResultCard(
                        context,
                        icon: Icons.water_drop,
                        title: 'Nivel de Humedad',
                        value: analysis.moistureLevel!.displayName,
                        description: analysis.moistureLevel!.recommendation,
                        color: _getMoistureColor(analysis.moistureLevel!),
                      ),

                    if (analysis.drainageQuality != null)
                      _buildResultCard(
                        context,
                        icon: Icons.water,
                        title: 'Calidad de Drenaje',
                        value: analysis.drainageQuality!.displayName,
                        description: analysis.drainageQuality!.implication,
                        color: _getDrainageColor(analysis.drainageQuality!),
                      ),

                    if (analysis.organicMatter != null)
                      _buildResultCard(
                        context,
                        icon: Icons.compost,
                        title: 'Materia Orgánica',
                        value: analysis.organicMatter!.displayName,
                        description: analysis.organicMatter!.recommendation,
                        color: _getNutrientColor(analysis.organicMatter!),
                      ),

                    const SizedBox(height: 24),
                  ],

                  // Recomendaciones
                  if (analysis.recommendations != null &&
                      analysis.recommendations!.isNotEmpty) ...[
                    Text(
                      'Recomendaciones',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: analysis.recommendations!
                            .map((rec) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        size: 20,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          rec,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Notas del análisis
                  if (analysis.analysisNotes != null &&
                      analysis.analysisNotes!.isNotEmpty) ...[
                    Text(
                      'Notas del Análisis',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      analysis.analysisNotes!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Fecha de análisis
                  if (analysis.analyzedAt != null) ...[
                    Text(
                      'Analizado el ${_formatDateTime(analysis.analyzedAt!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    final (color, text) = switch (analysis.status) {
      AnalysisStatus.pending => (Colors.orange, 'Pendiente'),
      AnalysisStatus.processing => (Colors.blue, 'Analizando'),
      AnalysisStatus.completed => (Colors.green, 'Completado'),
      AnalysisStatus.error => (Colors.red, 'Error'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildResultCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required String description,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getPhDescription(double ph) {
    if (ph < 5.5) return 'Ácido - Ideal para plantas como azaleas, arándanos';
    if (ph < 6.5) return 'Ligeramente ácido - Adecuado para la mayoría de plantas';
    if (ph < 7.5) return 'Neutro - Óptimo para la mayoría de plantas de interior';
    return 'Alcalino - Adecuado para lavanda, tomates';
  }

  Color _getPhColor(double ph) {
    if (ph < 5.5) return Colors.red;
    if (ph < 6.5) return Colors.orange;
    if (ph < 7.5) return Colors.green;
    return Colors.blue;
  }

  Color _getMoistureColor(MoistureLevel level) {
    return switch (level) {
      MoistureLevel.veryDry => Colors.red,
      MoistureLevel.dry => Colors.orange,
      MoistureLevel.slightlyDry => Colors.yellow.shade700,
      MoistureLevel.optimal => Colors.green,
      MoistureLevel.moist => Colors.blue,
      MoistureLevel.wet => Colors.indigo,
      MoistureLevel.waterlogged => Colors.purple,
    };
  }

  Color _getDrainageColor(DrainageQuality quality) {
    return switch (quality) {
      DrainageQuality.excellent => Colors.green,
      DrainageQuality.good => Colors.lightGreen,
      DrainageQuality.moderate => Colors.yellow.shade700,
      DrainageQuality.poor => Colors.orange,
      DrainageQuality.veryPoor => Colors.red,
    };
  }

  Color _getNutrientColor(NutrientLevel level) {
    return switch (level) {
      NutrientLevel.veryLow => Colors.red,
      NutrientLevel.low => Colors.orange,
      NutrientLevel.moderate => Colors.yellow.shade700,
      NutrientLevel.high => Colors.green,
      NutrientLevel.veryHigh => Colors.purple,
    };
  }
}
