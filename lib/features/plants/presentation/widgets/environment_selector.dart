import 'package:flutter/material.dart';
import 'package:planticula/core/data/species/plant_species.dart';
import 'package:planticula/core/theme/app_colors.dart';
import 'package:planticula/core/theme/app_dimens.dart';
import 'package:planticula/features/plants/presentation/widgets/confidence_indicator.dart';
import 'package:planticula/shared/widgets/carousel_selector.dart';

/// Selector visual de entorno (Interior/Exterior).
///
/// Delega la mecánica de carrusel en [CarouselSelector] y aporta las tarjetas
/// (con color distintivo interior/exterior) y el panel informativo del entorno.
class EnvironmentSelector extends StatelessWidget {
  /// Entorno actualmente seleccionado
  final PlantEnvironment selectedEnvironment;

  /// Callback cuando cambia la selección
  final ValueChanged<PlantEnvironment> onEnvironmentSelected;

  /// Entorno sugerido por la IA (para mostrar preselección)
  final PlantEnvironment? suggestedEnvironment;

  /// Nivel de confianza de la sugerencia (0.0 - 1.0)
  final double? suggestionConfidence;

  /// Si mostrar el indicador de confianza
  final bool showConfidenceIndicator;

  const EnvironmentSelector({
    super.key,
    required this.selectedEnvironment,
    required this.onEnvironmentSelected,
    this.suggestedEnvironment,
    this.suggestionConfidence,
    this.showConfidenceIndicator = false,
  });

  @override
  Widget build(BuildContext context) {
    return CarouselSelector<PlantEnvironment>(
      items: const [PlantEnvironment.indoor, PlantEnvironment.outdoor],
      selectedItem: selectedEnvironment,
      fallbackItem: PlantEnvironment.indoor,
      suggestedItem: suggestedEnvironment,
      onItemSelected: onEnvironmentSelected,
      title: 'Ubicación',
      subtitle: '¿Dónde está ubicada la planta?',
      carouselHeight: 180,
      viewportFraction: 0.65,
      titleTrailing: showConfidenceIndicator && suggestionConfidence != null
          ? ConfidenceIndicator(
              confidence: suggestionConfidence!,
              size: ConfidenceSize.small,
            )
          : null,
      suggestionBadge: showConfidenceIndicator && suggestedEnvironment != null
          ? const SuggestionBadge(text: 'Sugerido por IA')
          : null,
      cardBuilder: _buildEnvironmentCard,
      infoPanelBuilder: _buildEnvironmentInfoPanel,
    );
  }

  Widget _buildEnvironmentCard(
    BuildContext context,
    PlantEnvironment environment,
    bool isSelected,
    bool isSuggested,
  ) {
    final theme = Theme.of(context);
    final isIndoor = environment == PlantEnvironment.indoor;
    final accent = isIndoor ? AppColors.primary : Colors.orange.shade600;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: EdgeInsets.symmetric(
        horizontal: AppDimens.sm,
        vertical: isSelected ? 0 : AppDimens.md,
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? (isIndoor
                ? AppColors.primary.withOpacity(0.15)
                : Colors.orange.withOpacity(0.15))
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimens.lg),
        border: Border.all(
          color: isSelected
              ? accent
              : isSuggested
                  ? AppColors.success.withOpacity(0.5)
                  : theme.colorScheme.outline.withOpacity(0.5),
          width: isSelected ? 3 : (isSuggested ? 2 : 1),
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: (isIndoor ? AppColors.primary : Colors.orange)
                      .withOpacity(0.2),
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
                  ? (isIndoor
                      ? AppColors.primary.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2))
                  : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                isIndoor ? Icons.home_rounded : Icons.wb_sunny_outlined,
                size: 40,
                color: isSelected
                    ? accent
                    : theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(height: AppDimens.md),
          Text(
            isIndoor ? 'Interior' : 'Exterior',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isSelected
                  ? (isIndoor ? AppColors.primary : Colors.orange.shade700)
                  : theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppDimens.xs),
          if (isSuggested)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppDimens.xs),
              ),
              child: Text(
                'Sugerido',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Text(
              isIndoor ? '🏠 Dentro de casa' : '🌳 En el jardín/balcón',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentInfoPanel(
    BuildContext context,
    PlantEnvironment env,
  ) {
    final theme = Theme.of(context);
    final isIndoor = env == PlantEnvironment.indoor;
    final accent = isIndoor ? AppColors.primary : Colors.orange.shade600;

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
              Icon(
                isIndoor ? Icons.home_rounded : Icons.wb_sunny_outlined,
                size: 20,
                color: accent,
              ),
              const SizedBox(width: AppDimens.sm),
              Text(
                isIndoor ? 'Ambiente interior' : 'Ambiente exterior',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.sm),
          Text(
            isIndoor
                ? 'Las plantas de interior necesitan menos riego y están protegidas del clima extremo. Ideal para la mayoría de plantas ornamentales.'
                : 'Las plantas de exterior reciben luz natural directa y están expuestas a la lluvia. Requieren más atención al riego según el clima.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppDimens.sm),
          Wrap(
            spacing: AppDimens.sm,
            runSpacing: AppDimens.sm,
            children: [
              _buildFeatureChip(
                icon: isIndoor ? Icons.thermostat : Icons.water_drop,
                label: isIndoor ? 'Temperatura estable' : 'Riego más frecuente',
                theme: theme,
              ),
              _buildFeatureChip(
                icon: isIndoor ? Icons.wb_cloudy_outlined : Icons.wb_sunny,
                label: isIndoor ? 'Luz indirecta' : 'Luz directa',
                theme: theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip({
    required IconData icon,
    required String label,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppDimens.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
