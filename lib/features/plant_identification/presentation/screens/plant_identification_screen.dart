import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:planticula/core/constants/app_constants.dart';
import 'package:planticula/core/services/plant_identification_standalone_ai_service.dart';
import 'package:planticula/core/theme/app_colors.dart';
import 'package:planticula/core/theme/app_dimens.dart';
import 'package:planticula/features/plant_identification/domain/entities/plant_identification_result.dart';
import 'package:planticula/features/plant_identification/presentation/bloc/plant_identification_bloc.dart';
import 'package:planticula/shared/widgets/app_bottom_sheet.dart';
import 'package:planticula/shared/widgets/app_button.dart';
import 'package:planticula/shared/widgets/empty_state.dart';

class PlantIdentificationV2Screen extends StatefulWidget {
  const PlantIdentificationV2Screen({super.key});

  @override
  State<PlantIdentificationV2Screen> createState() =>
      _PlantIdentificationV2ScreenState();
}

class _PlantIdentificationV2ScreenState
    extends State<PlantIdentificationV2Screen> {
  @override
  void initState() {
    super.initState();
    context.read<PlantIdentificationBloc>().add(PlantIdentificationLoadRequested());
  }

  void _showImageSourceSheet() {
    showAppBottomSheet(
      context: context,
      title: 'Fotografiar planta',
      titleIcon: Icons.local_florist_outlined,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Tomar foto'),
            subtitle: const Text('Fotografía la planta completa'),
            onTap: () {
              Navigator.pop(context);
              context
                  .read<PlantIdentificationBloc>()
                  .add(PlantIdentificationImageCaptureRequested());
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Elegir de galería'),
            subtitle: const Text('Seleccionar foto existente'),
            onTap: () {
              Navigator.pop(context);
              context
                  .read<PlantIdentificationBloc>()
                  .add(PlantIdentificationImagePickRequested());
            },
          ),
          const SizedBox(height: AppDimens.sm),
        ],
      ),
    );
  }

  void _onSubmit() {
    context
        .read<PlantIdentificationBloc>()
        .add(const PlantIdentificationSubmitRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Identificar Planta'),
        centerTitle: false,
      ),
      body: BlocConsumer<PlantIdentificationBloc, PlantIdentificationState>(
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

          if (state.isSuccess && state.lastRecord != null) {
            context.push(
              AppConstants.routePlantIdentificationResult,
              extra: state.lastRecord,
            );
          }
        },
        builder: (context, state) {
          if (state.hasImage) {
            return _buildImagePreview(state);
          }

          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.isEmpty || state.records.isEmpty) {
            return _buildEmptyState();
          }

          return _buildHistoryList(state.records);
        },
      ),
      floatingActionButton: BlocBuilder<PlantIdentificationBloc, PlantIdentificationState>(
        builder: (context, state) {
          if (state.hasImage) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: _showImageSourceSheet,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('Identificar'),
            backgroundColor: AppColors.primary,
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
    return EmptyState(
      icon: Icons.local_florist_outlined,
      iconColor: AppColors.primary,
      title: 'Sin identificaciones',
      message:
          'Fotografía cualquier planta y la IA la identificará al instante: nombre, cuidados, toxicidad y más.',
      actionLabel: 'Identificar planta',
      actionIcon: Icons.add_a_photo_outlined,
      onAction: _showImageSourceSheet,
    );
  }

  Widget _buildImagePreview(PlantIdentificationState state) {
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
                  onPressed: () => context
                      .read<PlantIdentificationBloc>()
                      .add(PlantIdentificationClearImage()),
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
                        '¿Identificar esta planta?',
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppDimens.xs),
                      Text(
                        'La IA analizará la imagen e identificará la especie, cuidados, toxicidad y más.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppDimens.lg),
                      AppButton(
                        text: 'Identificar con IA',
                        onPressed: _onSubmit,
                        icon: Icons.local_florist_outlined,
                        backgroundColor: AppColors.primary,
                      ),
                      const SizedBox(height: AppDimens.sm),
                      TextButton(
                        onPressed: () => context
                            .read<PlantIdentificationBloc>()
                            .add(PlantIdentificationClearImage()),
                        child: const Text('Cancelar'),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgress(ThemeData theme, PlantIdentificationState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimens.sm),
          child: LinearProgressIndicator(
            value: state.progress > 0 ? state.progress : null,
            minHeight: 6,
            backgroundColor: AppColors.primarySoft,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
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
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
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

  Widget _buildHistoryList(List<PlantIdentificationRecord> records) {
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
                final r = records[index];
                return _PlantIdHistoryCard(
                  record: r,
                  onTap: () => context.push(
                    AppConstants.routePlantIdentificationResult,
                    extra: r,
                  ),
                  onDelete: () => context
                      .read<PlantIdentificationBloc>()
                      .add(PlantIdentificationDeleteRequested(r.id)),
                );
              },
              childCount: records.length,
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

class _PlantIdHistoryCard extends StatelessWidget {
  final PlantIdentificationRecord record;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PlantIdHistoryCard({
    required this.record,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimens.radiusCard - 4),
                ),
                child: const Icon(
                  Icons.local_florist_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppDimens.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (record.scientificName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        record.scientificName!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: AppDimens.xs),
                    Row(
                      children: [
                        if (record.careLevel != null) ...[
                          _CareLevelChip(careLevel: record.careLevel!),
                          const SizedBox(width: AppDimens.sm),
                        ],
                        Text(
                          _formatDate(record.createdAt),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Hoy';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _CareLevelChip extends StatelessWidget {
  final PlantIdCareLevel careLevel;

  const _CareLevelChip({required this.careLevel});

  Color get _color {
    switch (careLevel) {
      case PlantIdCareLevel.easy:
        return AppColors.primary;
      case PlantIdCareLevel.moderate:
        return AppColors.sun;
      case PlantIdCareLevel.difficult:
        return AppColors.soil;
      case PlantIdCareLevel.expert:
        return AppColors.pest;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimens.radiusChip),
      ),
      child: Text(
        careLevel.displayName,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}


