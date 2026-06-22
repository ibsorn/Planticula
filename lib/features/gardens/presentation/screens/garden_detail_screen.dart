import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:planticula/core/constants/app_constants.dart';
import 'package:planticula/core/theme/app_dimens.dart';
import 'package:planticula/features/gardens/domain/entities/garden.dart';
import 'package:planticula/features/gardens/domain/entities/garden_group.dart';
import 'package:planticula/features/gardens/presentation/bloc/garden_bloc.dart';
import 'package:planticula/features/gardens/presentation/screens/garden_editor_screen.dart';
import 'package:planticula/features/gardens/presentation/widgets/group_chip.dart';
import 'package:planticula/features/plants/domain/entities/plant.dart';
import 'package:planticula/features/plants/presentation/bloc/plants_bloc.dart';
import 'package:planticula/shared/widgets/empty_state.dart';
import 'package:planticula/shared/widgets/status_ring.dart';

/// Pantalla de detalle de un jardín.
/// Muestra los grupos del jardín como chips filtrables y la lista de plantas.
class GardenDetailScreen extends StatefulWidget {
  final Garden garden;

  const GardenDetailScreen({super.key, required this.garden});

  @override
  State<GardenDetailScreen> createState() => _GardenDetailScreenState();
}

class _GardenDetailScreenState extends State<GardenDetailScreen> {
  GardenGroup? _selectedGroup; // null = mostrar todas

  @override
  void initState() {
    super.initState();
    // Cargar grupos del jardín
    context.read<GardenBloc>().add(
          GardenGroupsLoadRequested(widget.garden.id),
        );
    // Cargar plantas del jardín via PlantsBloc
    context.read<PlantsBloc>().add(
          PlantsFilterByGarden(widget.garden.id),
        );
  }

  void _showAddGroupDialog(BuildContext ctx) {
    final ctrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Nuevo grupo'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Tomates, Suculentas, Zona exterior…',
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                ctx.read<GardenBloc>().add(GardenGroupCreateRequested(
                      gardenId: widget.garden.id,
                      name: ctrl.text.trim(),
                    ));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _deleteGroup(BuildContext ctx, GardenGroup group) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar grupo?'),
        content: Text(
            'Las plantas de "${group.name}" quedarán sin grupo pero no se eliminarán.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              ctx
                  .read<GardenBloc>()
                  .add(GardenGroupDeleteRequested(group.id));
              if (_selectedGroup?.id == group.id) {
                setState(() => _selectedGroup = null);
              }
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final garden   = widget.garden;
    final color    = Color(garden.colorValue);

    return Scaffold(
      appBar: AppBar(
        title: Text(garden.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar jardín',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GardenEditorScreen(garden: garden),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppConstants.routePlantEditor),
        icon: const Icon(Icons.add),
        label: const Text('Añadir planta'),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ── Barra de grupos ──────────────────────────────────────────
          BlocBuilder<GardenBloc, GardenState>(
            builder: (ctx, gState) {
              final groups = gState.groups;
              if (groups.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppDimens.lg, AppDimens.sm, AppDimens.lg, 0),
                  child: Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => _showAddGroupDialog(ctx),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Añadir grupo'),
                      ),
                    ],
                  ),
                );
              }
              return SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.lg, vertical: 8),
                  children: [
                    // Chip "Todos"
                    GroupChip(
                      group: GardenGroup(
                          id: '__all__',
                          gardenId: garden.id,
                          userId: '',
                          name: 'Todos'),
                      parentGarden: garden,
                      isSelected: _selectedGroup == null,
                      onTap: () {
                        setState(() => _selectedGroup = null);
                        ctx.read<PlantsBloc>().add(
                              PlantsFilterByGarden(garden.id),
                            );
                      },
                    ),
                    const SizedBox(width: 6),
                    ...groups.map((g) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GroupChip(
                            group: g,
                            parentGarden: garden,
                            isSelected: _selectedGroup?.id == g.id,
                            onTap: () {
                              setState(() => _selectedGroup = g);
                              ctx.read<PlantsBloc>().add(
                                    PlantsFilterByGroup(g.id),
                                  );
                            },
                            onLongPress: () => _deleteGroup(ctx, g),
                          ),
                        )),
                    // Botón añadir grupo
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _showAddGroupDialog(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: theme.colorScheme.outline
                                  .withOpacity(0.4)),
                        ),
                        child: Row(children: [
                          Icon(Icons.add,
                              size: 14,
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.5)),
                          const SizedBox(width: 4),
                          Text('Grupo',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.5),
                              )),
                        ]),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // ── Lista de plantas ─────────────────────────────────────────
          Expanded(
            child: BlocBuilder<PlantsBloc, PlantsState>(
              builder: (ctx, pState) {
                if (pState.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                final plants = _applyGroupFilter(pState.plants);
                if (plants.isEmpty) {
                  return EmptyState(
                    emoji: '🌱',
                    title: _selectedGroup == null
                        ? 'Este jardín está vacío'
                        : 'No hay plantas en este grupo',
                    message: 'Añade tu primera planta con el botón +',
                    actionLabel: 'Añadir planta',
                    actionIcon: Icons.add,
                    onAction: () =>
                        context.push(AppConstants.routePlantEditor),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppDimens.lg),
                  itemCount: plants.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppDimens.sm),
                  itemBuilder: (_, i) =>
                      _PlantTile(plant: plants[i], gardenColor: color),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Plant> _applyGroupFilter(List<Plant> plants) {
    if (_selectedGroup == null) return plants;
    return plants.where((p) => p.groupId == _selectedGroup!.id).toList();
  }
}

// ── Tile de planta dentro del detalle de jardín ──────────────────────────────

class _PlantTile extends StatelessWidget {
  final Plant plant;
  final Color gardenColor;

  const _PlantTile({required this.plant, required this.gardenColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        onTap: () => context.push('/plants/${plant.id}', extra: plant),
        leading: plant.imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  plant.imageUrl!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(),
                ),
              )
            : _placeholder(),
        title: Text(plant.displayName,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: plant.scientificName != null
            ? Text(plant.scientificName!,
                style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic))
            : null,
        trailing: plant.needsWatering
            ? const StatusRing(
                progress: 1.0,
                size: 36,
                child: Icon(Icons.water_drop, size: 16,
                    color: Colors.blue),
              )
            : null,
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: gardenColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.local_florist_outlined,
            color: gardenColor, size: 22),
      );
}
