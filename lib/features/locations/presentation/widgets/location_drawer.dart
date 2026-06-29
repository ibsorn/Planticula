import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:planticula/core/theme/app_dimens.dart';
import 'package:planticula/features/locations/domain/entities/location.dart';
import 'package:planticula/features/locations/presentation/bloc/location_bloc.dart';
import 'package:planticula/features/locations/presentation/widgets/location_icon_mapper.dart';

/// Drawer lateral que muestra el árbol de localización (vivero > zona > mesa)
/// de la organización activa y permite seleccionar un nodo para filtrar las
/// plantas, además de gestionar (crear/editar/eliminar) localizaciones in-place.
class LocationDrawer extends StatelessWidget {
  const LocationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      child: SafeArea(
        child: BlocBuilder<LocationBloc, LocationState>(
          builder: (ctx, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Cabecera: organización activa ──────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppDimens.lg, AppDimens.lg, AppDimens.lg, AppDimens.sm),
                  child: Row(
                    children: [
                      Icon(Icons.business_rounded, color: theme.colorScheme.primary),
                      const SizedBox(width: AppDimens.sm),
                      Expanded(
                        child: Text(
                          state.organization?.name ?? 'Mi organización',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // ── "Todas las plantas" ─────────────────────────────────────
                ListTile(
                  leading: const Icon(Icons.local_florist_outlined),
                  title: const Text('Todas las plantas'),
                  selected: state.selectedLocation == null,
                  onTap: () {
                    ctx.read<LocationBloc>().add(const LocationSelectRequested(null));
                    Navigator.pop(ctx);
                  },
                ),
                const Divider(height: 1),
                // ── Árbol de localizaciones ─────────────────────────────────
                Expanded(
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          padding: const EdgeInsets.only(bottom: AppDimens.lg),
                          children: [
                            for (final root in state.roots)
                              _LocationNode(node: root, depth: 0, state: state),
                            if (state.roots.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(AppDimens.lg),
                                child: Text(
                                  'Aún no tienes viveros. Crea el primero para '
                                  'organizar tus plantas por ubicación.',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                          ],
                        ),
                ),
                const Divider(height: 1),
                // ── Añadir vivero raíz ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(AppDimens.sm),
                  child: FilledButton.tonalIcon(
                    onPressed: () => _showCreateDialog(
                      ctx,
                      parent: null,
                      kind: LocationKind.site,
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Añadir vivero'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Un nodo del árbol con sus hijos (recursivo) usando indentación por profundidad.
class _LocationNode extends StatelessWidget {
  final Location node;
  final int depth;
  final LocationState state;

  const _LocationNode({
    required this.node,
    required this.depth,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final children = state.childrenOf(node.id);
    final isSelected = state.selectedLocation?.id == node.id;
    final color = Color(node.colorValue);

    final tile = ListTile(
      contentPadding: EdgeInsets.only(left: AppDimens.lg + depth * 16.0, right: AppDimens.sm),
      leading: Icon(LocationIconMapper.forKey(node.icon), color: color),
      title: Text(node.name),
      subtitle: Text(node.kind.displayName),
      selected: isSelected,
      onTap: () {
        context.read<LocationBloc>().add(LocationSelectRequested(node));
        Navigator.pop(context);
      },
      trailing: _NodeMenu(node: node),
    );

    if (children.isEmpty) return tile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        tile,
        for (final child in children)
          _LocationNode(node: child, depth: depth + 1, state: state),
      ],
    );
  }
}

class _NodeMenu extends StatelessWidget {
  final Location node;
  const _NodeMenu({required this.node});

  @override
  Widget build(BuildContext context) {
    final childKind = node.kind.childKind;
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      onSelected: (value) {
        switch (value) {
          case 'add':
            _showCreateDialog(context, parent: node, kind: childKind!);
            break;
          case 'edit':
            _showRenameDialog(context, node);
            break;
          case 'delete':
            _confirmDelete(context, node);
            break;
        }
      },
      itemBuilder: (_) => [
        if (childKind != null)
          PopupMenuItem(
            value: 'add',
            child: Row(children: [
              const Icon(Icons.add, size: 18),
              const SizedBox(width: 8),
              Text('Añadir ${childKind.displayName.toLowerCase()}'),
            ]),
          ),
        const PopupMenuItem(
          value: 'edit',
          child: Row(children: [
            Icon(Icons.edit_outlined, size: 18),
            SizedBox(width: 8),
            Text('Renombrar'),
          ]),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            Icon(Icons.delete_outline, size: 18),
            SizedBox(width: 8),
            Text('Eliminar'),
          ]),
        ),
      ],
    );
  }
}

// ── Diálogos ────────────────────────────────────────────────────────────────

void _showCreateDialog(
  BuildContext context, {
  required Location? parent,
  required LocationKind kind,
}) {
  final ctrl = TextEditingController();
  final bloc = context.read<LocationBloc>();
  showDialog(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: Text('Nuevo ${kind.displayName.toLowerCase()}'),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          hintText: switch (kind) {
            LocationKind.site  => 'Vivero norte, Invernadero A…',
            LocationKind.zone  => 'Zona de sombra, Sector 2…',
            LocationKind.bench => 'Mesa 1, Hilera A…',
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (ctrl.text.trim().isNotEmpty) {
              bloc.add(LocationCreateRequested(
                parentId: parent?.id,
                kind: kind,
                name: ctrl.text.trim(),
                icon: parent?.icon ?? 'garden',
                color: parent != null ? parent.color : '#4CAF50',
              ));
            }
            Navigator.pop(dialogCtx);
          },
          child: const Text('Crear'),
        ),
      ],
    ),
  );
}

void _showRenameDialog(BuildContext context, Location node) {
  final ctrl = TextEditingController(text: node.name);
  final bloc = context.read<LocationBloc>();
  showDialog(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: const Text('Renombrar'),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (ctrl.text.trim().isNotEmpty) {
              bloc.add(LocationUpdateRequested(node.copyWith(name: ctrl.text.trim())));
            }
            Navigator.pop(dialogCtx);
          },
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
}

void _confirmDelete(BuildContext context, Location node) {
  final bloc = context.read<LocationBloc>();
  showDialog(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: Text('¿Eliminar "${node.name}"?'),
      content: const Text(
        'Se eliminarán también sus sub-localizaciones. Las plantas no se '
        'borran, pero quedarán sin localización.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(dialogCtx).colorScheme.error,
          ),
          onPressed: () {
            bloc.add(LocationDeleteRequested(node.id));
            Navigator.pop(dialogCtx);
          },
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
}
