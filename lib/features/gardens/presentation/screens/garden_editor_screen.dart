import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:planticula/core/theme/app_colors.dart';
import 'package:planticula/core/theme/app_dimens.dart';
import 'package:planticula/features/gardens/domain/entities/garden.dart';
import 'package:planticula/features/gardens/presentation/bloc/garden_bloc.dart';
import 'package:planticula/features/gardens/presentation/widgets/garden_icon_mapper.dart';

/// Pantalla de creación / edición de un jardín.
///
/// En modo creación [garden] es null.
/// En modo edición [garden] contiene el jardín a modificar.
class GardenEditorScreen extends StatefulWidget {
  final Garden? garden;

  const GardenEditorScreen({super.key, this.garden});

  bool get isEditing => garden != null;

  @override
  State<GardenEditorScreen> createState() => _GardenEditorScreenState();
}

class _GardenEditorScreenState extends State<GardenEditorScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _descCtrl  = TextEditingController();

  late String      _icon;
  late String      _color;
  late GardenType  _type;

  // Paleta de colores predefinidos
  static const _colors = [
    '#4CAF50', '#2196F3', '#FF9800', '#E91E63',
    '#9C27B0', '#00BCD4', '#8BC34A', '#FF5722',
    '#795548', '#607D8B',
  ];

  @override
  void initState() {
    super.initState();
    final g = widget.garden;
    _nameCtrl.text = g?.name        ?? '';
    _descCtrl.text = g?.description ?? '';
    _icon          = g?.icon        ?? 'garden';
    _color         = g?.color       ?? '#4CAF50';
    _type          = g?.type        ?? GardenType.personal;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    if (widget.isEditing) {
      final updated = widget.garden!.copyWith(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        icon: _icon,
        color: _color,
        type: _type,
      );
      context.read<GardenBloc>().add(GardenUpdateRequested(updated));
    } else {
      context.read<GardenBloc>().add(GardenCreateRequested(
            name: _nameCtrl.text.trim(),
            description: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
            icon: _icon,
            color: _color,
            type: _type,
          ));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar jardín' : 'Nuevo jardín'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Guardar'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Vista previa ───────────────────────────────────────────
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Color(int.parse(
                            'FF${_color.replaceFirst('#', '')}',
                            radix: 16))
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Color(int.parse(
                          'FF${_color.replaceFirst('#', '')}',
                          radix: 16)),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    GardenIconMapper.forKey(_icon),
                    size: 40,
                    color: Color(int.parse(
                        'FF${_color.replaceFirst('#', '')}',
                        radix: 16)),
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.xl),

              // ── Nombre ─────────────────────────────────────────────────
              Text('Nombre', style: theme.textTheme.labelLarge),
              const SizedBox(height: AppDimens.sm),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  hintText: 'Mi jardín, Balcón norte…',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'El nombre no puede estar vacío'
                    : null,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: AppDimens.lg),

              // ── Descripción ────────────────────────────────────────────
              Text('Descripción (opcional)',
                  style: theme.textTheme.labelLarge),
              const SizedBox(height: AppDimens.sm),
              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Para qué usas este jardín…',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: AppDimens.lg),

              // ── Tipo ───────────────────────────────────────────────────
              Text('Tipo', style: theme.textTheme.labelLarge),
              const SizedBox(height: AppDimens.sm),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: GardenType.values.map((t) {
                  final selected = _type == t;
                  return ChoiceChip(
                    label: Text(t.displayName),
                    selected: selected,
                    onSelected: (_) => setState(() => _type = t),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppDimens.lg),

              // ── Icono ──────────────────────────────────────────────────
              Text('Icono', style: theme.textTheme.labelLarge),
              const SizedBox(height: AppDimens.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: GardenIconMapper.all.map((e) {
                  final selected = _icon == e.key;
                  final accentColor = Color(int.parse(
                      'FF${_color.replaceFirst('#', '')}',
                      radix: 16));
                  return GestureDetector(
                    onTap: () => setState(() => _icon = e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: selected
                            ? accentColor.withOpacity(0.2)
                            : theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? accentColor : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Icon(e.icon,
                          color: selected ? accentColor : null),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppDimens.lg),

              // ── Color ──────────────────────────────────────────────────
              Text('Color', style: theme.textTheme.labelLarge),
              const SizedBox(height: AppDimens.sm),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _colors.map((c) {
                  final colorValue =
                      Color(int.parse('FF${c.replaceFirst('#', '')}', radix: 16));
                  final selected = _color == c;
                  return GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colorValue,
                        shape: BoxShape.circle,
                        border: selected
                            ? Border.all(
                                color: theme.colorScheme.onSurface,
                                width: 3)
                            : null,
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                    color: colorValue.withOpacity(0.5),
                                    blurRadius: 8)
                              ]
                            : null,
                      ),
                      child: selected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppDimens.xxl),

              // ── Botón guardar ──────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppColors.primary,
                  ),
                  child: Text(widget.isEditing
                      ? 'Guardar cambios'
                      : 'Crear jardín'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
