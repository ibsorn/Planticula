import 'package:flutter/material.dart';
import 'package:planticula/core/data/species/plant_species.dart';
import 'package:planticula/core/theme/app_colors.dart';
import 'package:planticula/core/theme/app_dimens.dart';
import 'package:planticula/shared/widgets/carousel_selector.dart';

/// Selector visual de tamaño de maceta.
///
/// Delega toda la mecánica de carrusel en [CarouselSelector] y solo aporta
/// las tarjetas y el panel informativo específicos de las macetas.
class PotSizeSelector extends StatelessWidget {
  /// Tamaño actualmente seleccionado
  final PotSize? selectedSize;

  /// Callback cuando cambia la selección
  final ValueChanged<PotSize> onSizeSelected;

  /// Tamaño sugerido (opcional, para preselección)
  final PotSize? suggestedSize;

  /// Si mostrar el indicador de sugerencia
  final bool showSuggestionIndicator;

  const PotSizeSelector({
    super.key,
    this.selectedSize,
    required this.onSizeSelected,
    this.suggestedSize,
    this.showSuggestionIndicator = false,
  });

  @override
  Widget build(BuildContext context) {
    return CarouselSelector<PotSize>(
      items: PotSize.values,
      selectedItem: selectedSize,
      fallbackItem: suggestedSize ?? PotSize.medium,
      suggestedItem: suggestedSize,
      onItemSelected: onSizeSelected,
      title: '¿En qué maceta está?',
      subtitle: 'El tamaño afecta la frecuencia y cantidad de riego',
      suggestionBadge: showSuggestionIndicator && suggestedSize != null
          ? SuggestionBadge(text: 'La IA sugiere: ${suggestedSize!.displayName}')
          : null,
      cardBuilder: _buildSizeCard,
      infoPanelBuilder: _buildSizeInfoPanel,
    );
  }

  Widget _buildSizeCard(
    BuildContext context,
    PotSize size,
    bool isSelected,
    bool isSuggested,
  ) {
    final theme = Theme.of(context);
    final double iconSize = _getIconSize(size);

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
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.2)
                  : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(size.icon, style: TextStyle(fontSize: iconSize)),
            ),
          ),
          const SizedBox(height: AppDimens.md),
          Text(
            size.displayName,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.primary : null,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimens.xs),
          Text(
            size.litersRange,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
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

  Widget _buildSizeInfoPanel(BuildContext context, PotSize size) {
    final theme = Theme.of(context);
    String description;
    String useCase;

    switch (size) {
      case PotSize.extraSmall:
        description = 'Maceta muy pequeña, ideal para germinación y esquejes.';
        useCase = 'Perfecta para iniciar semillas y esquejes pequeños.';
      case PotSize.small:
        description = 'Maceta pequeña, adecuada para plántulas jóvenes.';
        useCase = 'Ideal para plantas jóvenes que están estableciéndose.';
      case PotSize.medium:
        description = 'Maceta mediana, el tamaño más común para plantas de interior.';
        useCase = 'El estándar para la mayoría de plantas de interior.';
      case PotSize.large:
        description = 'Maceta grande, para plantas establecidas y arbustos.';
        useCase = 'Para plantas grandes o cuando quieres que crezcan más.';
      case PotSize.extraLarge:
        description = 'Maceta muy grande o suelo directo, para árboles y cultivos extensos.';
        useCase = 'Árboles, arbustos grandes o cultivos en tierra.';
    }

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
              Text(size.icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: AppDimens.sm),
              Expanded(
                child: Text(
                  size.displayName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.sm),
          Text(description, style: theme.textTheme.bodySmall),
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
                  Icons.lightbulb_outline,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppDimens.sm),
                Expanded(
                  child: Text(
                    useCase,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.md),
          _buildWateringInfo(context, size),
        ],
      ),
    );
  }

  Widget _buildWateringInfo(BuildContext context, PotSize size) {
    final theme = Theme.of(context);
    String frequencyText;
    IconData frequencyIcon;
    Color frequencyColor;

    switch (size) {
      case PotSize.extraSmall:
        frequencyText = 'Riego frecuente';
        frequencyIcon = Icons.water_drop;
        frequencyColor = Colors.blue;
      case PotSize.small:
        frequencyText = 'Riego regular';
        frequencyIcon = Icons.water_drop;
        frequencyColor = Colors.blue;
      case PotSize.medium:
        frequencyText = 'Riego estándar';
        frequencyIcon = Icons.water_drop_outlined;
        frequencyColor = Colors.blue;
      case PotSize.large:
        frequencyText = 'Riego menos frecuente';
        frequencyIcon = Icons.water_drop_outlined;
        frequencyColor = Colors.blue.shade700;
      case PotSize.extraLarge:
        frequencyText = 'Riego ocasional';
        frequencyIcon = Icons.water_drop_outlined;
        frequencyColor = Colors.blue.shade800;
    }

    return Row(
      children: [
        Icon(frequencyIcon, size: 18, color: frequencyColor),
        const SizedBox(width: AppDimens.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(frequencyText, style: theme.textTheme.labelSmall),
              const SizedBox(height: 2),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: _getWateringBarValue(size),
                  minHeight: 4,
                  backgroundColor: frequencyColor.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(frequencyColor),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppDimens.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${size.baseWaterMl} ml',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'por riego',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  double _getIconSize(PotSize size) {
    switch (size) {
      case PotSize.extraSmall:
        return 32;
      case PotSize.small:
        return 40;
      case PotSize.medium:
        return 48;
      case PotSize.large:
        return 56;
      case PotSize.extraLarge:
        return 64;
    }
  }

  double _getWateringBarValue(PotSize size) {
    switch (size) {
      case PotSize.extraSmall:
        return 0.9;
      case PotSize.small:
        return 0.75;
      case PotSize.medium:
        return 0.5;
      case PotSize.large:
        return 0.35;
      case PotSize.extraLarge:
        return 0.2;
    }
  }
}
