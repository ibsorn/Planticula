import 'package:flutter/material.dart';
import 'package:planticula/core/theme/app_colors.dart';
import 'package:planticula/core/theme/app_dimens.dart';

/// Selector visual genérico basado en un carrusel de tarjetas.
///
/// Encapsula todo el comportamiento común de los selectores de la app
/// (PageController, sincronización con selección externa, indicadores de
/// página, estructura de título/subtítulo y panel informativo), delegando
/// únicamente lo específico de cada dominio mediante builders:
///
/// - [cardBuilder]: construye cada tarjeta del carrusel.
/// - [infoPanelBuilder]: construye el panel informativo bajo el carrusel.
///
/// De esta forma `GrowthStageSelector`, `PotSizeSelector` y
/// `EnvironmentSelector` comparten una única implementación de la mecánica.
class CarouselSelector<T> extends StatefulWidget {
  /// Lista de elementos seleccionables (normalmente `Enum.values`).
  final List<T> items;

  /// Elemento actualmente seleccionado.
  final T? selectedItem;

  /// Elemento usado para posicionar el carrusel si [selectedItem] es null.
  final T fallbackItem;

  /// Elemento sugerido (p. ej. por IA), para resaltarlo en las tarjetas.
  final T? suggestedItem;

  /// Callback al cambiar de página/selección.
  final ValueChanged<T> onItemSelected;

  /// Título principal del selector.
  final String title;

  /// Subtítulo/descripción opcional bajo el título.
  final String? subtitle;

  /// Widget opcional a la derecha del título (p. ej. indicador de confianza).
  final Widget? titleTrailing;

  /// Badge opcional mostrado entre el subtítulo y el carrusel.
  final Widget? suggestionBadge;

  /// Altura del carrusel.
  final double carouselHeight;

  /// Fracción de viewport visible (controla cuánto se ve de las tarjetas vecinas).
  final double viewportFraction;

  /// Constructor de cada tarjeta.
  final Widget Function(
    BuildContext context,
    T item,
    bool isSelected,
    bool isSuggested,
  ) cardBuilder;

  /// Constructor del panel informativo del elemento actual (opcional).
  final Widget Function(BuildContext context, T item)? infoPanelBuilder;

  const CarouselSelector({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.fallbackItem,
    required this.onItemSelected,
    required this.title,
    required this.cardBuilder,
    this.suggestedItem,
    this.subtitle,
    this.titleTrailing,
    this.suggestionBadge,
    this.carouselHeight = 200,
    this.viewportFraction = 0.75,
    this.infoPanelBuilder,
  });

  @override
  State<CarouselSelector<T>> createState() => _CarouselSelectorState<T>();
}

class _CarouselSelectorState<T> extends State<CarouselSelector<T>> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _currentPage = _indexOf(widget.selectedItem ?? widget.fallbackItem);
    _pageController = PageController(
      initialPage: _currentPage,
      viewportFraction: widget.viewportFraction,
    );
  }

  @override
  void didUpdateWidget(CarouselSelector<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedItem != oldWidget.selectedItem &&
        widget.selectedItem != null) {
      final newPage = _indexOf(widget.selectedItem as T);
      if (newPage != _currentPage && newPage >= 0) {
        _currentPage = newPage;
        _pageController.animateToPage(
          newPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  int _indexOf(T item) {
    final i = widget.items.indexOf(item);
    return i < 0 ? 0 : i;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = widget.items;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título (+ trailing opcional)
        Row(
          children: [
            Text(
              widget.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.titleTrailing != null) ...[
              const SizedBox(width: AppDimens.sm),
              widget.titleTrailing!,
            ],
          ],
        ),

        // Subtítulo
        if (widget.subtitle != null) ...[
          const SizedBox(height: AppDimens.xs),
          Text(
            widget.subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppDimens.md),

        // Badge de sugerencia (opcional)
        if (widget.suggestionBadge != null) ...[
          widget.suggestionBadge!,
          const SizedBox(height: AppDimens.md),
        ],

        // Carrusel de tarjetas
        SizedBox(
          height: widget.carouselHeight,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
              widget.onItemSelected(items[index]);
            },
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return widget.cardBuilder(
                context,
                item,
                index == _currentPage,
                item == widget.suggestedItem,
              );
            },
          ),
        ),

        const SizedBox(height: AppDimens.md),

        // Indicadores de página
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(items.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _currentPage == index
                    ? AppColors.primary
                    : AppColors.primary.withOpacity(0.3),
              ),
            );
          }),
        ),

        // Panel informativo del elemento actual (opcional)
        if (widget.infoPanelBuilder != null) ...[
          const SizedBox(height: AppDimens.md),
          widget.infoPanelBuilder!(context, items[_currentPage]),
        ],
      ],
    );
  }
}

/// Badge reutilizable "La IA sugiere: ..." usado por los selectores.
class SuggestionBadge extends StatelessWidget {
  final String text;

  const SuggestionBadge({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.md,
        vertical: AppDimens.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimens.sm),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, size: 16, color: AppColors.success),
          const SizedBox(width: AppDimens.sm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
