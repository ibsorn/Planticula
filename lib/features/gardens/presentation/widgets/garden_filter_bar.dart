import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:planticula/core/constants/app_constants.dart';
import 'package:planticula/core/theme/app_dimens.dart';
import 'package:planticula/features/gardens/domain/entities/garden.dart';
import 'package:planticula/features/gardens/domain/entities/garden_group.dart';
import 'package:planticula/features/gardens/presentation/bloc/garden_bloc.dart';
import 'package:planticula/features/gardens/presentation/widgets/garden_icon_mapper.dart';
import 'package:planticula/features/gardens/presentation/widgets/group_chip.dart';
import 'package:planticula/features/plants/presentation/bloc/plants_bloc.dart';

/// Barra de filtro contextual que organiza las plantas por jardín y grupo.
///
/// Se renderiza dentro de [PlantsScreen] encima de la lista de plantas.
/// - Si no hay jardines cargados, no se muestra (zero ruido).
/// - "Todas" muestra todas las plantas del usuario (sin filtro de jardín).
/// - Al seleccionar un jardín, aparece una segunda barra con sus grupos.
/// - El botón ⚙ navega a la pantalla de gestión de jardines (/gardens).
///
/// La selección del jardín se delega al [GardenBloc] vía
/// [GardenSelectRequested]; un [BlocListener] en [PlantsScreen] reacciona
/// a ese cambio y dispara el filtro correspondiente al [PlantsBloc].
/// La selección del grupo es estado local de este widget y dispara
/// directamente [PlantsFilterByGroup] al [PlantsBloc].
class GardenFilterBar extends StatefulWidget {
  const GardenFilterBar({super.key});

  @override
  State<GardenFilterBar> createState() => _GardenFilterBarState();
}

class _GardenFilterBarState extends State<GardenFilterBar> {
  /// Grupo seleccionado localmente (null = "Todos" dentro del jardín).
  GardenGroup? _selectedGroup;

  @override
  void initState() {
    super.initState();
    // Cargar jardines si aún no se han cargado.
    final state = context.read<GardenBloc>().state;
    if (state.status == GardenStatus.initial) {
      context.read<GardenBloc>().add(GardensLoadRequested());
    }
  }

  void _selectGarden(Garden? garden) {
    setState(() => _selectedGroup = null);
    context.read<GardenBloc>().add(GardenSelectRequested(garden));
    // El BlocListener de PlantsScreen reaccionará al cambio de selectedGarden
    // y disparará PlantsFilterByGarden o PlantsLoadRequested según corresponda.
  }

  void _selectGroup(GardenGroup? group, Garden parentGarden) {
    setState(() => _selectedGroup = group);
    if (group == null) {
      context
          .read<PlantsBloc>()
          .add(PlantsFilterByGarden(parentGarden.id));
    } else {
      context.read<PlantsBloc>().add(PlantsFilterByGroup(group.id));
    }
  }

  void _openManagement() {
    context.push(AppConstants.routeGardens);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GardenBloc, GardenState>(
      buildWhen: (p, c) =>
          p.gardens != c.gardens ||
          p.selectedGarden != c.selectedGarden ||
          p.groups != c.groups ||
          p.status != c.status,
      builder: (ctx, state) {
        // Mientras carga o no hay jardines → no mostrar nada.
        if (state.status == GardenStatus.loading ||
            state.status == GardenStatus.initial ||
            state.gardens.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            _buildGardenRow(context, state),
            if (state.selectedGarden != null && state.groups.isNotEmpty)
              _buildGroupRow(context, state),
          ],
        );
      },
    );
  }

  // ── Barra de jardines ──────────────────────────────────────────────────

  Widget _buildGardenRow(BuildContext context, GardenState state) {
    final theme = Theme.of(context);
    final selectedGarden = state.selectedGarden;

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
        children: [
          // Chip "Todas"
          _PillChip(
            label: 'Todas',
            icon: Icons.local_florist_outlined,
            color: theme.colorScheme.primary,
            isSelected: selectedGarden == null,
            onTap: () => _selectGarden(null),
          ),
          const SizedBox(width: AppDimens.sm),
          ...state.gardens.map((garden) {
            return Padding(
              padding: const EdgeInsets.only(right: AppDimens.sm),
              child: _PillChip(
                label: garden.name,
                icon: GardenIconMapper.forKey(garden.icon),
                color: Color(garden.colorValue),
                isSelected: selectedGarden?.id == garden.id,
                onTap: () => _selectGarden(garden),
              ),
            );
          }),
          // Botón gestionar ⚙
          Padding(
            padding: const EdgeInsets.only(left: AppDimens.xs),
            child: _ManageButton(onTap: _openManagement),
          ),
        ],
      ),
    );
  }

  // ── Barra de grupos ────────────────────────────────────────────────────

  Widget _buildGroupRow(BuildContext context, GardenState state) {
    final garden = state.selectedGarden!;

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
        children: [
          // Chip "Todos" (grupos)
          GroupChip(
            group: GardenGroup(
              id: '__all__',
              gardenId: garden.id,
              userId: '',
              name: 'Todos',
            ),
            parentGarden: garden,
            isSelected: _selectedGroup == null,
            onTap: () => _selectGroup(null, garden),
          ),
          const SizedBox(width: AppDimens.sm),
          ...state.groups.map((group) {
            return Padding(
              padding: const EdgeInsets.only(right: AppDimens.sm),
              child: GroupChip(
                group: group,
                parentGarden: garden,
                isSelected: _selectedGroup?.id == group.id,
                onTap: () => _selectGroup(group, garden),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Chips privados ────────────────────────────────────────────────────────

/// Chip pill reutilizable para la barra de jardines.
/// Replica el estilo visual de [GroupChip] pero para jardines.
class _PillChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PillChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.2)
              : theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? color
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? color
                    : theme.colorScheme.onSurface.withValues(alpha: 0.75),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón circular con icono de ajustes para abrir la gestión de jardines.
class _ManageButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ManageButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: 'Gestionar jardines',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.4),
            ),
          ),
          child: Icon(
            Icons.tune_rounded,
            size: 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
