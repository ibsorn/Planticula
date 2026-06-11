import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:planticula/features/soil_analysis/domain/entities/soil_analysis.dart';
import 'package:planticula/features/soil_analysis/presentation/bloc/soil_analysis_bloc.dart';
import 'package:planticula/features/soil_analysis/presentation/screens/analysis_detail_screen.dart';
import 'package:planticula/shared/widgets/app_button.dart';

class SoilAnalysisScreen extends StatefulWidget {
  final String? plantId; // Opcional - si viene de una planta específica

  const SoilAnalysisScreen({super.key, this.plantId});

  @override
  State<SoilAnalysisScreen> createState() => _SoilAnalysisScreenState();
}

class _SoilAnalysisScreenState extends State<SoilAnalysisScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.plantId != null) {
      context
          .read<SoilAnalysisBloc>()
          .add(SoilAnalysisLoadByPlantRequested(widget.plantId!));
    } else {
      context.read<SoilAnalysisBloc>().add(SoilAnalysisLoadRequested());
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              subtitle: const Text('Seleccionar imagen existente'),
              onTap: () {
                Navigator.pop(context);
                context
                    .read<SoilAnalysisBloc>()
                    .add(SoilAnalysisImagePickRequested());
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              subtitle: const Text('Tomar foto nueva'),
              onTap: () {
                Navigator.pop(context);
                context
                    .read<SoilAnalysisBloc>()
                    .add(SoilAnalysisImageCaptureRequested());
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _onUpload(Uint8List? imageBytes) {
    if (imageBytes == null) return;

    context.read<SoilAnalysisBloc>().add(SoilAnalysisUploadRequested(
          plantId: widget.plantId,
        ));
  }

  void _onAnalysisTap(SoilAnalysis analysis) {
    context.read<SoilAnalysisBloc>().add(SoilAnalysisSelectRequested(analysis.id));
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AnalysisDetailScreen(analysis: analysis),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análisis de Sustrato'),
      ),
      body: BlocConsumer<SoilAnalysisBloc, SoilAnalysisState>(
        listener: (context, state) {
          if (state.errorMessage != null && !state.isLoading) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }

          if (state.isOperationSuccess && state.lastCreatedAnalysis != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Imagen subida correctamente'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.hasError) {
            return _buildErrorState(state.errorMessage ?? 'Error desconocido');
          }

          // Mostrar preview de imagen seleccionada
          if (state.hasImageSelected) {
            return _buildImagePreview(state);
          }

          if (state.isEmpty) {
            return _buildEmptyState();
          }

          return _buildAnalysisList(state.analyses);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showImageSourceDialog,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Nuevo'),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                context.read<SoilAnalysisBloc>().add(SoilAnalysisLoadRequested());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.science_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin análisis de sustrato',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Toma una foto del sustrato de tu planta para analizarlo',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showImageSourceDialog,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Tomar Foto'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(SoilAnalysisState state) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(
                state.selectedImageBytes!,
                fit: BoxFit.contain,
              ),
              Positioned(
                top: 16,
                right: 16,
                child: IconButton.filled(
                  onPressed: () {
                    context.read<SoilAnalysisBloc>().add(SoilAnalysisClearError());
                  },
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '¿Subir esta imagen?',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                AppButton(
                  text: 'Subir Imagen',
                  onPressed: () => _onUpload(state.selectedImageBytes),
                  isLoading: state.isUploading,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    context.read<SoilAnalysisBloc>().add(SoilAnalysisClearError());
                  },
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisList(List<SoilAnalysis> analyses) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: analyses.length,
      itemBuilder: (context, index) {
        final analysis = analyses[index];
        return _AnalysisCard(
          analysis: analysis,
          onTap: () => _onAnalysisTap(analysis),
        );
      },
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  final SoilAnalysis analysis;
  final VoidCallback onTap;

  const _AnalysisCard({
    required this.analysis,
    required this.onTap,
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
            // Imagen con estado overlay
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    analysis.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: colorScheme.primaryContainer,
                      child: Icon(
                        Icons.broken_image,
                        size: 48,
                        color: colorScheme.onPrimaryContainer.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                // Badge de estado
                Positioned(
                  top: 8,
                  left: 8,
                  child: _StatusBadge(status: analysis.status),
                ),
              ],
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _getTitle(),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      Text(
                        _formatDate(analysis.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Resultados si está completado
                  if (analysis.isCompleted) ...[
                    if (analysis.soilType != null)
                      _buildResultRow(
                        context,
                        icon: Icons.grass,
                        label: 'Tipo:',
                        value: analysis.soilType!.displayName,
                      ),
                    if (analysis.phLevel != null)
                      _buildResultRow(
                        context,
                        icon: Icons.science,
                        label: 'pH:',
                        value: analysis.phFormatted!,
                      ),
                    if (analysis.moistureLevel != null)
                      _buildResultRow(
                        context,
                        icon: Icons.water_drop,
                        label: 'Humedad:',
                        value: analysis.moistureLevel!.displayName,
                      ),
                  ] else if (analysis.isPending) ...[
                    Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Esperando análisis...',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                        ),
                      ],
                    ),
                  ] else if (analysis.hasError) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 16,
                          color: colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Error en análisis',
                            style: TextStyle(color: colorScheme.error),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    if (analysis.isCompleted && analysis.soilType != null) {
      return 'Análisis: ${analysis.soilType!.displayName}';
    }
    return 'Análisis de Sustrato';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildResultRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final AnalysisStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, text, icon) = switch (status) {
      AnalysisStatus.pending => (
          Colors.orange,
          'Pendiente',
          Icons.hourglass_empty
        ),
      AnalysisStatus.processing => (
          Colors.blue,
          'Analizando',
          Icons.science
        ),
      AnalysisStatus.completed => (
          Colors.green,
          'Completado',
          Icons.check_circle
        ),
      AnalysisStatus.error => (
          Colors.red,
          'Error',
          Icons.error
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
