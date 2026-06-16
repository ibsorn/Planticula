import 'package:flutter/material.dart';
import 'package:planticula/core/data/species/plant_species.dart';
import 'package:planticula/core/theme/app_colors.dart';
import 'package:planticula/core/theme/app_dimens.dart';
import 'package:planticula/shared/widgets/carousel_selector.dart';

/// Selector visual de etapa de crecimiento.
///
/// Delega la mecánica de carrusel en [CarouselSelector] y aporta las tarjetas,
/// el badge de confianza de IA y el panel informativo de cada etapa.
class GrowthStageSelector extends StatelessWidget {
  /// Etapa actualmente seleccionada
  final GrowthStage? selectedStage;

  /// Callback cuando cambia la selección
  final ValueChanged<GrowthStage> onStageSelected;

  /// Etapa sugerida por la IA (para mostrar preselección)
  final GrowthStage? suggestedStage;

  /// Nivel de confianza de la sugerencia (0.0 - 1.0)
  final double? suggestionConfidence;

  /// Si mostrar el indicador de confianza
  final bool showConfidenceIndicator;

  const GrowthStageSelector({
    super.key,
    this.selectedStage,
    required this.onStageSelected,
    this.suggestedStage,
    this.suggestionConfidence,
    this.showConfidenceIndicator = true,
  });

  bool get _showSuggestion =>
      showConfidenceIndicator &&
      suggestedStage != null &&
      suggestionConfidence != null;

  @override
  Widget build(BuildContext context) {
    return CarouselSelector<GrowthStage>(
      items: GrowthStage.orderedStages,
      selectedItem: selectedStage,
      fallbackItem: suggestedStage ?? GrowthStage.development,
      suggestedItem: suggestedStage,
      onItemSelected: onStageSelected,
      title: '¿En qué etapa está?',
      carouselHeight: 220,
      suggestionBadge: _showSuggestion ? _buildSuggestionBadge(context) : null,
      cardBuilder: _buildStageCard,
      infoPanelBuilder: _buildStageInfoPanel,
    );
  }

  Widget _buildSuggestionBadge(BuildContext context) {
    final theme = Theme.of(context);
    final confidence = suggestionConfidence ?? 0.0;
    final confidencePercent = (confidence * 100).toInt();

    String confidenceText;
    Color confidenceColor;
    if (confidence >= 0.8) {
      confidenceText = 'Muy probable';
      confidenceColor = AppColors.success;
    } else if (confidence >= 0.6) {
      confidenceText = 'Probable';
      confidenceColor = AppColors.sun;
    } else {
      confidenceText = 'Posible';
      confidenceColor = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.md,
        vertical: AppDimens.sm,
      ),
      decoration: BoxDecoration(
        color: confidenceColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimens.sm),
        border: Border.all(color: confidenceColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, size: 16, color: confidenceColor),
          const SizedBox(width: AppDimens.sm),
          Expanded(
            child: Text(
              'La IA sugiere: ${suggestedStage!.displayName} '
              '($confidenceText - $confidencePercent%)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: confidenceColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageCard(
    BuildContext context,
    GrowthStage stage,
    bool isSelected,
    bool isSuggested,
  ) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: EdgeInsets.symmetric(
        horizontal: AppDimens.sm,
        vertical: isSelected ? 0 : AppDimens.md,
      ),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primarySoft : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimens.lg),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : isSuggested
                  ? AppColors.success.withOpacity(0.5)
                  : theme.colorScheme.outline.withOpacity(0.5),
          width: isSelected ? 2 : (isSuggested ? 2 : 1),
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.2)
                  : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(stage.icon, style: const TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(height: AppDimens.md),
          Text(
            stage.displayName,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.primary : null,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimens.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.md),
            child: Text(
              stage.shortDescription,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isSuggested) ...[
            const SizedBox(height: AppDimens.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Sugerido',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStageInfoPanel(BuildContext context, GrowthStage stage) {
    final theme = Theme.of(context);
    return Container(
      padding: AppDimens.cardPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppDimens.md),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(stage.icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: AppDimens.sm),
              Expanded(
                child: Text(
                  stage.displayName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.sm),
          Text(stage.extendedDescription, style: theme.textTheme.bodySmall),
          if (stage.supportsAdvancedTechniques) ...[
            const SizedBox(height: AppDimens.md),
            Container(
              padding: const EdgeInsets.all(AppDimens.sm),
              decoration: BoxDecoration(
                color: AppColors.primarySoft.withOpacity(0.5),
                borderRadius: BorderRadius.circular(AppDimens.sm),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.tips_and_updates,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppDimens.sm),
                  Expanded(
                    child: Text(
                      'Técnicas recomendadas: ${stage.techniquesDescription}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppDimens.md),
          _buildCareNeedsRow(context, stage),
        ],
      ),
    );
  }

  Widget _buildCareNeedsRow(BuildContext context, GrowthStage stage) {
    final theme = Theme.of(context);
    final waterPercent = (stage.wateringFrequencyMultiplier * 100).toInt();
    final lightPercent = (stage.lightNeedsMultiplier * 100).toInt();

    String waterLabel;
    IconData waterIcon;
    if (stage.wateringFrequencyMultiplier < 0.8) {
      waterLabel = 'Riego ligero';
      waterIcon = Icons.water_drop_outlined;
    } else if (stage.wateringFrequencyMultiplier > 1.0) {
      waterLabel = 'Riego frecuente';
      waterIcon = Icons.water_drop;
    } else {
      waterLabel = 'Riego normal';
      waterIcon = Icons.water_drop;
    }

    String lightLabel;
    IconData lightIcon;
    if (stage.lightNeedsMultiplier < 0.8) {
      lightLabel = 'Luz moderada';
      lightIcon = Icons.wb_cloudy_outlined;
    } else if (stage.lightNeedsMultiplier > 1.0) {
      lightLabel = 'Mucha luz';
      lightIcon = Icons.wb_sunny;
    } else {
      lightLabel = 'Luz normal';
      lightIcon = Icons.wb_sunny_outlined;
    }

    return Row(
      children: [
        Expanded(
          child: _buildCareNeedItem(
            icon: waterIcon,
            label: waterLabel,
            percent: waterPercent,
            color: Colors.blue,
            theme: theme,
          ),
        ),
        const SizedBox(width: AppDimens.md),
        Expanded(
          child: _buildCareNeedItem(
            icon: lightIcon,
            label: lightLabel,
            percent: lightPercent,
            color: AppColors.sun,
            theme: theme,
          ),
        ),
      ],
    );
  }

  Widget _buildCareNeedItem({
    required IconData icon,
    required String label,
    required int percent,
    required Color color,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppDimens.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: percent / 100,
                  minHeight: 4,
                  backgroundColor: color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
