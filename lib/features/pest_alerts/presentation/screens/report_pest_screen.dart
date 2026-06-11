import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:planticula/features/pest_alerts/domain/entities/pest_alert.dart';
import 'package:planticula/features/pest_alerts/presentation/bloc/pest_alerts_bloc.dart';
import 'package:planticula/shared/widgets/app_button.dart';

class ReportPestScreen extends StatefulWidget {
  const ReportPestScreen({super.key});

  @override
  State<ReportPestScreen> createState() => _ReportPestScreenState();
}

class _ReportPestScreenState extends State<ReportPestScreen> {
  final _formKey = GlobalKey<FormState>();
  PestType _selectedPestType = PestType.aphids;
  String? _customPestName;
  Severity _selectedSeverity = Severity.medium;
  final _locationNameController = TextEditingController();
  final _notesController = TextEditingController();
  double? _latitude;
  double? _longitude;
  bool _isGettingLocation = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _locationNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
      _locationError = null;
    });

    try {
      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permiso de ubicación denegado');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permiso de ubicación denegado permanentemente');
      }

      // Obtener posición
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isGettingLocation = false;
      });

      // Actualizar en BLoC también
      context.read<PestAlertsBloc>().add(PestAlertsUpdateUserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      ));

    } catch (e) {
      setState(() {
        _locationError = e.toString();
        _isGettingLocation = false;
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () {
                Navigator.pop(context);
                context.read<PestAlertsBloc>().add(PestAlertsPhotoPickRequested());
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () {
                Navigator.pop(context);
                context.read<PestAlertsBloc>().add(PestAlertsPhotoCaptureRequested());
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _submitReport(Uint8List? photoBytes) {
    if (!_formKey.currentState!.validate()) return;
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Se requiere ubicación para reportar')),
      );
      return;
    }

    context.read<PestAlertsBloc>().add(PestAlertsReportSubmitted(
      pestType: _selectedPestType,
      customPestName: _selectedPestType == PestType.other ? _customPestName : null,
      severity: _selectedSeverity,
      latitude: _latitude!,
      longitude: _longitude!,
      locationName: _locationNameController.text.isEmpty ? null : _locationNameController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportar Plaga'),
      ),
      body: BlocConsumer<PestAlertsBloc, PestAlertsState>(
        listener: (context, state) {
          if (state.errorMessage != null && !state.isSubmitting) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }

          if (state.isSubmissionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Alerta reportada correctamente'),
                backgroundColor: Colors.green,
              ),
            );
            context.pop();
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Foto de la plaga
                  _buildPhotoSection(state),
                  const SizedBox(height: 24),

                  // Tipo de plaga
                  Text(
                    'Tipo de Plaga',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _buildPestTypeSelector(),
                  const SizedBox(height: 16),

                  // Nombre personalizado si es "Otra"
                  if (_selectedPestType == PestType.other)
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la plaga',
                        hintText: 'Ej: Escarabajo de la hoja',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (_selectedPestType == PestType.other &&
                            (value == null || value.isEmpty)) {
                          return 'Especifica el nombre de la plaga';
                        }
                        return null;
                      },
                      onChanged: (value) => _customPestName = value,
                    ),
                  const SizedBox(height: 24),

                  // Severidad
                  Text(
                    'Gravedad de la Infestación',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _buildSeveritySelector(),
                  const SizedBox(height: 24),

                  // Ubicación
                  Text(
                    'Ubicación',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _buildLocationSection(),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _locationNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del lugar (opcional)',
                      hintText: 'Ej: Mi jardín trasero',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Notas adicionales
                  Text(
                    'Notas Adicionales',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Describe lo que observas: comportamiento de la plaga, daños en la planta, etc.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Botón de enviar
                  AppButton(
                    text: 'Reportar Plaga',
                    onPressed: state.isSubmitting
                        ? null
                        : () => _submitReport(state.selectedPhotoBytes),
                    isLoading: state.isSubmitting,
                    icon: Icons.warning_amber,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhotoSection(PestAlertsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Foto de la Plaga',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        if (state.hasPhotoSelected)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  state.selectedPhotoBytes!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filled(
                  onPressed: () {
                    context.read<PestAlertsBloc>().add(PestAlertsClearPhoto());
                  },
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          )
        else
          InkWell(
            onTap: _showImageSourceDialog,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toca para añadir foto',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Recomendado para identificación',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPestTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PestType.values.map((type) {
        final isSelected = _selectedPestType == type;
        return ChoiceChip(
          label: Text(type.displayName),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() => _selectedPestType = type);
            }
          },
          tooltip: type.description,
        );
      }).toList(),
    );
  }

  Widget _buildSeveritySelector() {
    return Column(
      children: Severity.values.map((severity) {
        return RadioListTile<Severity>(
          title: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Color(severity.colorValue),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(severity.displayName),
            ],
          ),
          subtitle: Text(
            severity.description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          value: severity,
          // ignore: deprecated_member_use
          groupValue: _selectedSeverity,
          // ignore: deprecated_member_use
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedSeverity = value);
            }
          },
          activeColor: Color(severity.colorValue),
        );
      }).toList(),
    );
  }

  Widget _buildLocationSection() {
    if (_isGettingLocation) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Obteniendo ubicación...'),
          ],
        ),
      );
    }

    if (_locationError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Error de ubicación',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  const SizedBox(height: 4),
                  ElevatedButton(
                    onPressed: _getCurrentLocation,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_latitude != null && _longitude != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ubicación obtenida',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _getCurrentLocation,
              child: const Text('Actualizar'),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_off),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Ubicación no disponible'),
          ),
          ElevatedButton(
            onPressed: _getCurrentLocation,
            child: const Text('Obtener'),
          ),
        ],
      ),
    );
  }
}
