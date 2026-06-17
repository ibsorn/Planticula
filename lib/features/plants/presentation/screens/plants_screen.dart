import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:planticula/core/constants/app_constants.dart';
import 'package:planticula/core/constants/app_strings.dart';
import 'package:planticula/core/theme/app_colors.dart';
import 'package:planticula/core/theme/app_dimens.dart';
import 'package:planticula/features/plants/domain/entities/plant.dart';
import 'package:planticula/features/plants/presentation/bloc/plants_bloc.dart';
import 'package:planticula/shared/widgets/app_bottom_sheet.dart';
import 'package:planticula/shared/widgets/empty_state.dart';
import 'package:planticula/shared/widgets/status_ring.dart';

enum _GardenFilter { all, indoor, outdoor, thirsty }

class PlantsScreen extends StatefulWidget {
  const PlantsScreen({super.key});

  @override
  State<PlantsScreen> createState() => _PlantsScreenState();
}

class _PlantsScreenState extends State<PlantsScreen> {
  final _searchController = TextEditingController();
  bool _searchVisible = false;
  bool _gridMode = true;
  _GardenFilter _filter = _GardenFilter.all;

  @override
  void initState() {
    super.initState();
    context.read<PlantsBloc>().add(PlantsLoadRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    context.read<PlantsBloc>().add(PlantsSearchRequested(query));
  }

  void _onAddPlant() {
    // Mostrar opciones: Escanear con IA o Añadir manualmente
    showAppBottomSheet(
      context: context,
      title: 'Añadir nueva planta',
      subtitle: 'Elige cómo quieres añadir tu planta',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AddPlantOption(
            icon: Icons.camera_alt_outlined,
            iconColor: AppColors.primary,
            title: 'Escanear con IA',
            subtitle: 'Toma una foto y la IA identificará la planta',
            onTap: () {
              Navigator.pop(context);
              _navigateToIdentification();
            },
          ),
          const SizedBox(height: AppDimens.md),
          _AddPlantOption(
            icon: Icons.edit_outlined,
            iconColor: AppColors.success,
            title: 'Añadir manualmente',
            subtitle: 'Selecciona tú mismo los datos de la planta',
            onTap: () {
              Navigator.pop(context);
              context.push(AppConstants.routePlantEditor);
            },
          ),
        ],
      ),
    );
  }

  void _navigateToIdentification() {
    context.push(AppConstants.routePlantIdentification);
  }

  void _onPlantTap(Plant plant) {
    context.read<PlantsBloc>().add(PlantSelectRequested(plant.id));
    context.push(
      '/plants/${plant.id}',
      extra: plant,
    );
  }

  void _onEditPlant(Plant plant) {
    showDialog(
      context: context,
      builder: (context) => _EditPlantNameDialog(
        plant: plant,
        onSave: (customName) {
          final updatedPlant = plant.copyWith(customName: customName);
          context.read<PlantsBloc>().add(PlantUpdateRequested(updatedPlant));
        },
      ),
    );
  }

  void _onDeletePlant(Plant plant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar planta?'),
        content: Text('¿Estás seguro de que quieres eliminar "${plant.displayName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<PlantsBloc>().add(PlantDeleteRequested(plant.id));
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

  void _onWaterPlant(Plant plant) {
    context.read<PlantsBloc>().add(PlantWaterRequested(plant.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('¡${plant.displayName} regada! 💧')),
    );
  }

  void _onWaterPlantWithDate(Plant plant, int daysAgo) {
    context.read<PlantsBloc>().add(
      PlantWaterOnDateRequested(id: plant.id, daysAgo: daysAgo),
    );
    final message = daysAgo == 0
        ? '¡${plant.displayName} regada hoy! 💧'
        : daysAgo == 1
            ? 'Riego registrado: ayer 💧'
            : 'Riego registrado: hace $daysAgo días 💧';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  List<Plant> _applyFilter(List<Plant> plants) {
    final filtered = switch (_filter) {
      _GardenFilter.all => plants,
      _GardenFilter.indoor => plants.where((p) => !p.isOutdoor).toList(),
      _GardenFilter.outdoor => plants.where((p) => p.isOutdoor).toList(),
      _GardenFilter.thirsty => plants.where((p) => p.needsWatering).toList(),
    };
    // Most urgent watering first.
    final sorted = [...filtered]..sort((a, b) {
        final da = a.daysUntilWatering ?? 9999;
        final db = b.daysUntilWatering ?? 9999;
        return da.compareTo(db);
      });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Jardín 🌿'),
        actions: [
          IconButton(
            icon: Icon(_searchVisible
                ? Icons.search_off_rounded
                : Icons.search_rounded),
            onPressed: () {
              setState(() => _searchVisible = !_searchVisible);
              if (!_searchVisible && _searchController.text.isNotEmpty) {
                _searchController.clear();
                _onSearch('');
              }
            },
          ),
          IconButton(
            icon: Icon(
                _gridMode ? Icons.view_list_rounded : Icons.grid_view_rounded),
            onPressed: () => setState(() => _gridMode = !_gridMode),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_searchVisible)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppDimens.lg, 0, AppDimens.lg, AppDimens.sm),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: AppStrings.plantsSearchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            _onSearch('');
                          },
                        )
                      : null,
                ),
                onChanged: _onSearch,
              ),
            ),
          _buildFilterChips(),
          Expanded(
            child: BlocConsumer<PlantsBloc, PlantsState>(
              listener: (context, state) {
                if (state.errorMessage != null && !state.isLoading) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.errorMessage!),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.hasError) {
                  return EmptyState(
                    emoji: '🥀',
                    title: 'Algo no ha ido bien',
                    message: state.errorMessage ?? AppStrings.unknownError,
                    actionLabel: AppStrings.plantsErrorRetry,
                    actionIcon: Icons.refresh_rounded,
                    onAction: () =>
                        context.read<PlantsBloc>().add(PlantsLoadRequested()),
                  );
                }
                if (state.isEmpty) {
                  return EmptyState(
                    emoji: '🌱',
                    title: AppStrings.plantsEmptyTitle,
                    message: AppStrings.plantsEmptySubtitle,
                    actionLabel: AppStrings.plantsAddPlantButton,
                    onAction: _onAddPlant,
                  );
                }

                final plants = _applyFilter(state.plants);
                if (plants.isEmpty) {
                  return const EmptyState(
                    emoji: '🔍',
                    title: 'Nada por aquí',
                    message: 'Ninguna planta coincide con este filtro.',
                  );
                }
                return _gridMode
                    ? _buildPlantGrid(plants)
                    : _buildPlantList(plants);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onAddPlant,
        icon: const Icon(Icons.add_rounded),
        label: const Text(AppStrings.plantsAddButton),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = {
      _GardenFilter.all: 'Todas',
      _GardenFilter.indoor: '🏠 Interior',
      _GardenFilter.outdoor: '🌤 Exterior',
      _GardenFilter.thirsty: '💧 Con sed',
    };

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
        children: [
          for (final entry in filters.entries)
            Padding(
              padding: const EdgeInsets.only(right: AppDimens.sm),
              child: FilterChip(
                label: Text(entry.value),
                selected: _filter == entry.key,
                showCheckmark: false,
                onSelected: (_) => setState(() => _filter = entry.key),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlantGrid(List<Plant> plants) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.lg, AppDimens.sm, AppDimens.lg, 96),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppDimens.md,
        crossAxisSpacing: AppDimens.md,
        childAspectRatio: 0.78,
      ),
      itemCount: plants.length,
      itemBuilder: (context, index) => _PlantGridCard(
        plant: plants[index],
        onTap: () => _onPlantTap(plants[index]),
        onEdit: () => _onEditPlant(plants[index]),
        onDelete: () => _onDeletePlant(plants[index]),
        onWater: () => _onWaterPlant(plants[index]),
        onWaterWithDate: (daysAgo) => _onWaterPlantWithDate(plants[index], daysAgo),
      ),
    );
  }

  Widget _buildPlantList(List<Plant> plants) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.lg, AppDimens.sm, AppDimens.lg, 96),
      itemCount: plants.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppDimens.md),
      itemBuilder: (context, index) => _PlantListCard(
        plant: plants[index],
        onTap: () => _onPlantTap(plants[index]),
        onEdit: () => _onEditPlant(plants[index]),
        onDelete: () => _onDeletePlant(plants[index]),
        onWater: () => _onWaterPlant(plants[index]),
        onWaterWithDate: (daysAgo) => _onWaterPlantWithDate(plants[index], daysAgo),
      ),
    );
  }
}

/// Watering progress 0 (just watered) -> 1 (due now or overdue).
double _wateringProgress(Plant plant) {
  final frequency = plant.wateringFrequency;
  if (frequency == null || frequency <= 0 || plant.nextWatering == null) {
    return 0;
  }
  if (plant.needsWatering) return 1;
  final remaining = plant.nextWatering!.difference(DateTime.now()).inHours / 24;
  return (1 - remaining / frequency).clamp(0.0, 1.0);
}

String _wateringLabel(Plant plant) {
  if (plant.needsWatering) return '¡Riega hoy!';
  final days = plant.daysUntilWatering;
  if (days == null) return 'Sin recordatorio';
  if (days == 0) return 'Riega hoy';
  if (days == 1) return 'Riego mañana';
  return 'Riego en $days días';
}

/// Widget para opción de añadir planta (IA o manual)
class _AddPlantOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AddPlantOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.md),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.md),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(AppDimens.md),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimens.sm),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}

/// Diálogo para editar el nombre personalizado de una planta
class _EditPlantNameDialog extends StatefulWidget {
  final Plant plant;
  final ValueChanged<String?> onSave;

  const _EditPlantNameDialog({
    required this.plant,
    required this.onSave,
  });

  @override
  State<_EditPlantNameDialog> createState() => _EditPlantNameDialogState();
}

class _EditPlantNameDialogState extends State<_EditPlantNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.plant.customName ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Editar nombre'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Especie: ${widget.plant.name}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppDimens.md),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 100,
            decoration: const InputDecoration(
              hintText: 'Nombre personalizado (opcional)',
              helperText: 'Deja vacío para usar el nombre de la especie',
              prefixIcon: Icon(Icons.edit_rounded),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final customName = _controller.text.trim();
            Navigator.pop(context);
            widget.onSave(customName.isEmpty ? null : customName);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

void _showPlantActionSheet({
  required BuildContext context,
  required Plant plant,
  VoidCallback? onWater,
  ValueChanged<int>? onWaterWithDate,
  VoidCallback? onEdit,
  VoidCallback? onDelete,
}) {
  if (onEdit == null &&
      onDelete == null &&
      onWater == null &&
      onWaterWithDate == null) {
    return;
  }

  final theme = Theme.of(context);

  showModalBottomSheet(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.75,
    ),
    builder: (sheetContext) => ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(
        AppDimens.lg,
        0,
        AppDimens.lg,
        AppDimens.lg,
      ),
      children: [
        Text(plant.displayName, style: theme.textTheme.titleLarge),
        if (plant.hasCustomName)
          Text(
            plant.name,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        const SizedBox(height: AppDimens.md),
        if (onWater != null || onWaterWithDate != null) ...[
          _SheetSectionLabel(
            icon: Icons.water_drop_rounded,
            label: 'Riego',
            color: theme.colorScheme.primary,
          ),
          if (onWater != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.water_drop_rounded,
                  color: theme.colorScheme.primary),
              title: const Text('Regar hoy'),
              subtitle: const Text('Marcar como regada ahora'),
              onTap: () {
                Navigator.pop(sheetContext);
                onWater();
              },
            ),
          if (onWaterWithDate != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.history_rounded,
                  color: theme.colorScheme.secondary),
              title: const Text('Riego pasado'),
              subtitle: const Text('Indicar hace cuantos dias se rego'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showWaterDateSheet(
                  context: context,
                  onSelect: onWaterWithDate,
                );
              },
            ),
        ],
        if ((onWater != null || onWaterWithDate != null) &&
            (onEdit != null || onDelete != null))
          const Divider(height: AppDimens.lg),
        if (onEdit != null || onDelete != null) ...[
          _SheetSectionLabel(
            icon: Icons.settings_rounded,
            label: 'Gestion',
            color: theme.colorScheme.onSurfaceVariant,
          ),
          if (onEdit != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Editar nombre'),
              onTap: () {
                Navigator.pop(sheetContext);
                onEdit();
              },
            ),
          if (onDelete != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.delete_rounded,
                  color: theme.colorScheme.error),
              title: Text(
                'Eliminar',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              subtitle: const Text('Esta accion no se puede deshacer'),
              onTap: () {
                Navigator.pop(sheetContext);
                onDelete();
              },
            ),
        ],
      ],
    ),
  );
}

void _showWaterDateSheet({
  required BuildContext context,
  required ValueChanged<int> onSelect,
}) {
  final theme = Theme.of(context);
  final options = [
    (days: 0, label: 'Hoy', icon: Icons.today_rounded),
    (days: 1, label: 'Ayer', icon: Icons.calendar_today_outlined),
    (days: 2, label: 'Anteayer', icon: Icons.calendar_today_outlined),
    (days: 3, label: 'Hace 3 dias', icon: Icons.calendar_today_outlined),
    (days: 5, label: 'Hace 5 dias', icon: Icons.calendar_today_outlined),
    (days: 7, label: 'Hace 1 semana', icon: Icons.calendar_today_outlined),
    (days: 14, label: 'Hace 2 semanas', icon: Icons.calendar_today_outlined),
    (days: 30, label: 'Hace 1 mes', icon: Icons.calendar_today_outlined),
  ];

  showModalBottomSheet(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.75,
    ),
    builder: (sheetContext) => ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(
        AppDimens.lg,
        0,
        AppDimens.lg,
        AppDimens.lg,
      ),
      children: [
        Text('Cuando se rego?', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppDimens.xs),
        Text(
          'Asi calculamos el proximo riego desde la fecha real.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppDimens.md),
        for (final option in options)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              option.icon,
              color: option.days == 0
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            title: Text(option.label),
            onTap: () {
              Navigator.pop(sheetContext);
              onSelect(option.days);
            },
          ),
      ],
    ),
  );
}

class _SheetSectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SheetSectionLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.xs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppDimens.sm),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlantGridCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onWater;
  final Function(int daysAgo)? onWaterWithDate;

  const _PlantGridCard({
    required this.plant,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onWater,
    this.onWaterWithDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _showContextMenu(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _PlantImage(plant: plant),
                  Positioned(
                    top: AppDimens.sm,
                    right: AppDimens.sm,
                    child: _RingBadge(plant: plant),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimens.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.displayName,
                    style: theme.textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (plant.hasCustomName) ...[
                    const SizedBox(height: 2),
                    Text(
                      plant.name,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    '${plant.isOutdoor ? '🌤' : '🏠'} ${_wateringLabel(plant)}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: plant.needsWatering
                          ? AppColors.error
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight:
                          plant.needsWatering ? FontWeight.w700 : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    _showPlantActionSheet(
      context: context,
      plant: plant,
      onWater: onWater,
      onWaterWithDate: onWaterWithDate,
      onEdit: onEdit,
      onDelete: onDelete,
    );
  }

}

class _PlantListCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onWater;
  final Function(int daysAgo)? onWaterWithDate;

  const _PlantListCard({
    required this.plant,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onWater,
    this.onWaterWithDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _showContextMenu(context),
        child: Row(
          children: [
            SizedBox(
              width: 88,
              height: 88,
              child: _PlantImage(plant: plant),
            ),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.displayName,
                    style: theme.textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (plant.hasCustomName) ...[
                    const SizedBox(height: 2),
                    Text(
                      plant.name,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    '${plant.isOutdoor ? '🌤 Exterior' : '🏠 Interior'}'
                    '${plant.location != null ? ' · ${plant.location}' : ''}',
                    style: theme.textTheme.labelMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _wateringLabel(plant),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: plant.needsWatering
                          ? AppColors.error
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight:
                          plant.needsWatering ? FontWeight.w700 : null,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimens.md),
              child: _RingBadge(plant: plant),
            ),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    _showPlantActionSheet(
      context: context,
      plant: plant,
      onWater: onWater,
      onWaterWithDate: onWaterWithDate,
      onEdit: onEdit,
      onDelete: onDelete,
    );
  }

}

class _RingBadge extends StatelessWidget {
  final Plant plant;

  const _RingBadge({required this.plant});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.75),
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(2),
      child: StatusRing(
        progress: _wateringProgress(plant),
        size: 36,
        strokeWidth: 3.5,
        child: const Text('💧', style: TextStyle(fontSize: 12)),
      ),
    );
  }
}

class _PlantImage extends StatelessWidget {
  final Plant plant;

  const _PlantImage({required this.plant});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (plant.imageUrl != null) {
      return Image.network(
        plant.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(theme),
      );
    }
    return _placeholder(theme);
  }

  Widget _placeholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      alignment: Alignment.center,
      child: const Text('🪴', style: TextStyle(fontSize: 40)),
    );
  }
}
