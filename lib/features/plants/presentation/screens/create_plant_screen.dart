import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:planticula/features/plants/presentation/bloc/plants_bloc.dart';
import 'package:planticula/shared/widgets/app_button.dart';
import 'package:planticula/shared/widgets/app_text_field.dart';

class CreatePlantScreen extends StatefulWidget {
  const CreatePlantScreen({super.key});

  @override
  State<CreatePlantScreen> createState() => _CreatePlantScreenState();
}

class _CreatePlantScreenState extends State<CreatePlantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _scientificNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  int? _wateringFrequency;
  DateTime? _acquiredDate;

  final List<int> _frequencyOptions = [1, 2, 3, 4, 5, 7, 10, 14, 21, 30];

  @override
  void dispose() {
    _nameController.dispose();
    _scientificNameController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<PlantsBloc>().add(PlantCreateRequested(
            name: _nameController.text.trim(),
            scientificName: _scientificNameController.text.trim().isEmpty
                ? null
                : _scientificNameController.text.trim(),
            location: _locationController.text.trim().isEmpty
                ? null
                : _locationController.text.trim(),
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
            wateringFrequency: _wateringFrequency,
            acquiredDate: _acquiredDate,
          ));
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _acquiredDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Fecha de adquisición',
    );
    if (picked != null) {
      setState(() {
        _acquiredDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Añadir Planta'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<PlantsBloc, PlantsState>(
        listener: (context, state) {
          if (state.isOperationSuccess) {
            context.pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Planta añadida correctamente'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          if (state.errorMessage != null && state.operationStatus == PlantsOperationStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Imagen placeholder
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        // TODO: Implementar selector de imagen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Selector de imagen próximamente'),
                          ),
                        );
                      },
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: Icon(
                          Icons.add_a_photo,
                          size: 40,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Añadir foto',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nombre (requerido)
                  AppTextField(
                    controller: _nameController,
                    label: 'Nombre *',
                    hint: 'Ej: Monstera de la sala',
                    prefixIcon: Icons.local_florist,
                    validator: (value) {
                      if (value?.trim().isEmpty ?? true) {
                        return 'El nombre es obligatorio';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Nombre científico
                  AppTextField(
                    controller: _scientificNameController,
                    label: 'Nombre científico',
                    hint: 'Ej: Monstera deliciosa',
                    prefixIcon: Icons.science,
                  ),
                  const SizedBox(height: 16),

                  // Ubicación
                  AppTextField(
                    controller: _locationController,
                    label: 'Ubicación',
                    hint: 'Ej: Sala de estar, Terraza...',
                    prefixIcon: Icons.location_on,
                  ),
                  const SizedBox(height: 16),

                  // Fecha de adquisición
                  InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Fecha de adquisición',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _acquiredDate != null
                            ? '${_acquiredDate!.day}/${_acquiredDate!.month}/${_acquiredDate!.year}'
                            : 'Seleccionar fecha',
                        style: TextStyle(
                          color: _acquiredDate != null
                              ? null
                              : Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Frecuencia de riego
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Frecuencia de riego',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Sin recordatorio'),
                            selected: _wateringFrequency == null,
                            onSelected: (selected) {
                              setState(() {
                                _wateringFrequency = null;
                              });
                            },
                          ),
                          ..._frequencyOptions.map((days) {
                            return ChoiceChip(
                              label: Text('$days días'),
                              selected: _wateringFrequency == days,
                              onSelected: (selected) {
                                setState(() {
                                  _wateringFrequency = selected ? days : null;
                                });
                              },
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Notas
                  AppTextField(
                    controller: _notesController,
                    label: 'Notas',
                    hint: 'Información adicional...',
                    prefixIcon: Icons.notes,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),

                  // Botón guardar
                  AppButton(
                    text: 'Guardar Planta',
                    onPressed: _onSave,
                    isLoading: state.isOperationLoading,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
