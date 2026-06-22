import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:planticula/core/constants/app_constants.dart';
import 'package:planticula/core/theme/app_colors.dart';
import 'package:planticula/core/theme/app_dimens.dart';
import 'package:planticula/features/plant_disease/domain/entities/plant_disease_diagnosis.dart';
import 'package:planticula/features/plant_disease/presentation/bloc/plant_disease_bloc.dart';
import 'package:planticula/shared/widgets/app_bottom_sheet.dart';
import 'package:planticula/shared/widgets/app_button.dart';
import 'package:planticula/shared/widgets/empty_state.dart';

class PlantDiseaseScreen extends StatefulWidget {
  const PlantDiseaseScreen({super.key});

  @override
  State<PlantDiseaseScreen> createState() => _PlantDiseaseScreenState();
}

class _PlantDiseaseScreenState extends State<PlantDiseaseScreen> {
  @override
  void initState() {
    super.initState();
    final bloc = context.read<PlantDiseaseBloc>();
    if (bloc.state.status == PlantDiseaseStatus.initial) {
      bloc.add(PlantDiseaseLoadRequested());
    }
  }

  void _showImageSourceSheet() {
    showAppBottomSheet(
      context: context,
      title: 'Fotografiar planta',
      titleIcon: Icons.bug_report_outlined,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Tomar foto'),
            subtitle: const Text('Fotografía la zona afectada'),
            onTap: () {
              Navigator.pop(context);
              context
                  .read<PlantDiseaseBloc>()
                  .add(PlantDiseaseImageCaptureRequested());
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Elegir de galería'),
            subtitle: const Text('Seleccionar foto existente'),
            onTap: () {
              Navigator.pop(context);
              context
                  .read<PlantDiseaseBloc>()
                  .add(PlantDiseaseImagePickRequested());
            },
          ),
          const SizedBox(height: AppDimens.sm),
        ],
      ),
    );
  }

  void _onSubmit() {
    context
        .read<PlantDiseaseBloc>()
        .add(const PlantDiagnosisSubmitRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnóstico de Plantas'),
        centerTitle: false,
      ),
      body: BlocConsumer<PlantDiseaseBloc, PlantDiseaseState>(
        listenWhen: (previous, current) =>
            previous.submitStatus != current.submitStatus ||
            previous.errorMessage != current.errorMessage,
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }

          // Navigate to result screen when analysis completes
          if (state.isSuccess && state.lastDiagnosis != null) {
            context.push(
              AppConstants.routePlantDiagnosisResult,
              extra: state.lastDiagnosis,
            );
          }
        },
        builder: (context, state) {
          // Image selected — show preview + submit button
          if (state.hasImage) {
            return _buildImagePreview(state);
          }

          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.isEmpty) {
            return _buildEmptyState();
          }

          return _buildHistoryList(state.diagnoses);
        },
      ),
      floatingActionButton: BlocBuilder<PlantDiseaseBloc, PlantDiseaseState>(
        builder: (context, state) {
          if (state.hasImage) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: _showImageSourceSheet,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('Diagnosticar'),
            backgroundColor: AppColors.pest,
            foregroundColor: Colors.white,
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // State builders
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState() {
    return const EmptyState(
      icon: Icons.bug_report_outlined,
      iconColor: AppColors.pest,
      title: 'Sin diagnósticos',
      message:
          'Fotografía las hojas, tallos o raíces afectadas y la IA identificará el problema y te recomendará remedios.',
    );
  }

  Widget _buildImagePreview(PlantDiseaseState state) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(state.imageBytes!, fit: BoxFit.contain),
              Positioned(
                top: AppDimens.lg,
                right: AppDimens.lg,
                child: IconButton.filled(
                  onPressed: () =>
                      context.read<PlantDiseaseBloc>().add(PlantDiseaseClearImage()),
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
          padding: const EdgeInsets.all(AppDimens.lg),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: state.isAnalyzing
                ? _buildProgress(theme, state)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '¿Diagnosticar esta imagen?',
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppDimens.xs),
                      Text(
                        'La IA analizará la imagen en busca de plagas, enfermedades o deficiencias.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppDimens.lg),
                      AppButton(
                        text: 'Analizar con IA',
                        onPressed: _onSubmit,
                        icon: Icons.bug_report_outlined,
                        backgroundColor: AppColors.pest,
                      ),
                      const SizedBox(height: AppDimens.sm),
                      TextButton(
                        onPressed: () => context
                            .read<PlantDiseaseBloc>()
                            .add(PlantDiseaseClearImage()),
                        child: const Text('Cancelar'),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  /// Progress UI shown while the AI is analysing the image.
  Widget _buildProgress(ThemeData theme, PlantDiseaseState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimens.sm),
          child: LinearProgressIndicator(
            value: state.progress > 0 ? state.progress : null,
            minHeight: 6,
            backgroundColor: AppColors.pestSoft,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.pest),
          ),
        ),
        const SizedBox(height: AppDimens.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.pest),
              ),
            ),
            const SizedBox(width: AppDimens.md),
            Flexible(
              child: Text(
                state.progressMessage.isNotEmpty
                    ? state.progressMessage
                    : 'Preparando...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHistoryList(List<PlantDiseaseDiagnosis> diagnoses) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.lg,
            AppDimens.lg,
            AppDimens.lg,
            AppDimens.xl,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final d = diagnoses[index];
                return _DiagnosisHistoryCard(
                  diagnosis: d,
                  onTap: () => context.push(
                    AppConstants.routePlantDiagnosisResult,
                    extra: d,
                  ),
                  onDelete: () => context
                      .read<PlantDiseaseBloc>()
                      .add(PlantDiagnosisDeleteRequested(d.id)),
                );
              },
              childCount: diagnoses.length,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// History card widget
// =============================================================================

class _DiagnosisHistoryCard extends StatelessWidget {
  final PlantDiseaseDiagnosis diagnosis;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DiagnosisHistoryCard({
    required this.diagnosis,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final severity = diagnosis.severity;
    final severityColor = severity != null
        ? Color(severity.colorValue)
        : AppColors.pest;

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimens.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Severity indicator + type icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimens.radiusCard - 4),
                ),
                child: Icon(
                  _iconForType(diagnosis.diagnosisType),
                  color: severityColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppDimens.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      diagnosis.displayProblemName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (diagnosis.diagnosisType != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        diagnosis.diagnosisType!.displayName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppDimens.xs),
                    Row(
                      children: [
                        if (severity != null) ...[
                          _SeverityChip(severity: severity),
                          const SizedBox(width: AppDimens.sm),
                        ],
                        Text(
                          _formatDate(diagnosis.createdAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  size: 20,
                ),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(DiagnosisType? type) {
    switch (type) {
      case DiagnosisType.pest:
        return Icons.bug_report_outlined;
      case DiagnosisType.disease:
        return Icons.coronavirus_outlined;
      case DiagnosisType.deficiency:
        return Icons.water_drop_outlined;
      case DiagnosisType.environmentalStress:
        return Icons.wb_sunny_outlined;
      case DiagnosisType.healthy:
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Hoy';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _SeverityChip extends StatelessWidget {
  final ProblemSeverity severity;

  const _SeverityChip({required this.severity});

  @override
  Widget build(BuildContext context) {
    final color = Color(severity.colorValue);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimens.radiusChip),
      ),
      child: Text(
        severity.displayName,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
