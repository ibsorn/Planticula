import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:planticula/core/theme/app_dimens.dart';
import 'package:planticula/features/gardens/domain/entities/garden.dart';
import 'package:planticula/features/gardens/presentation/bloc/garden_bloc.dart';
import 'package:planticula/features/gardens/presentation/screens/garden_detail_screen.dart';
import 'package:planticula/features/gardens/presentation/screens/garden_editor_screen.dart';
import 'package:planticula/features/gardens/presentation/widgets/garden_card.dart';
import 'package:planticula/shared/widgets/empty_state.dart';

/// Pantalla principal de la funcionalidad de jardines.
///
/// Lista los jardines del usuario y permite crear, editar y eliminar.
/// Al pulsar un jardín se navega al detalle del mismo.
class GardensScreen extends StatefulWidget {
  const GardensScreen({super.key});

  @override
  State<GardensScreen> createState() => _GardensScreenState();
}

class _GardensScreenState extends State<GardensScreen> {
  @override
  void initState() {
    super.initState();
    context.read<GardenBloc>().add(GardensLoadRequested());
  }

  void _openDetail(BuildContext ctx, Garden garden) {
    // No disparamos GardenSelectRequested aquí: ese evento ahora se usa
    // exclusivamente para el filtro contextual en PlantsScreen. La selección
    // visual del card se gestiona por navegación (route actual), no por estado
    // del bloc.
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => GardenDetailScreen(garden: garden),
      ),
    );
  }

  void _openCreate(BuildContext ctx) {
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => const GardenEditorScreen(),
      ),
    );
  }

  void _openEdit(BuildContext ctx, Garden garden) {
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => GardenEditorScreen(garden: garden),
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, Garden garden) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar jardín?'),
        content: Text(
          'Las plantas de "${garden.name}" quedarán sin clasificar.\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              ctx
                  .read<GardenBloc>()
                  .add(GardenDeleteRequested(garden.id));
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Jardines'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Nuevo jardín',
            onPressed: () => _openCreate(context),
          ),
        ],
      ),
      body: BlocConsumer<GardenBloc, GardenState>(
        listener: (ctx, state) {
          if (state.hasError && state.errorMessage != null) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ));
            ctx.read<GardenBloc>().add(GardenClearError());
          }
          if (state.isOpSuccess) {
            ctx.read<GardenBloc>().add(GardenClearError());
          }
        },
        builder: (ctx, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.isEmpty || state.gardens.isEmpty) {
            return EmptyState(
              emoji: '🌿',
              title: 'Sin jardines',
              message: 'Crea tu primer jardín para organizar tus plantas.',
              actionLabel: 'Crear jardín',
              actionIcon: Icons.add,
              onAction: () => _openCreate(ctx),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppDimens.lg),
            itemCount: state.gardens.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppDimens.sm),
            itemBuilder: (_, i) {
              final garden = state.gardens[i];
              return GardenCard(
                garden: garden,
                isSelected: state.selectedGarden?.id == garden.id,
                onTap: () => _openDetail(ctx, garden),
                onEdit: () => _openEdit(ctx, garden),
                onDelete: garden.isDefault
                    ? null
                    : () => _confirmDelete(ctx, garden),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreate(context),
        tooltip: 'Nuevo jardín',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
