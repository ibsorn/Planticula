import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:planticula/features/marketplace/domain/entities/marketplace_listing.dart';
import 'package:planticula/features/marketplace/presentation/bloc/marketplace_bloc.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _tradeForController = TextEditingController();
  final _locationNameController = TextEditingController();

  ListingCategory _selectedCategory = ListingCategory.plant;
  ListingType _selectedType = ListingType.sale;
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
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _tradeForController.dispose();
    _locationNameController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
      _locationError = null;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permiso de ubicación denegado');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permiso denegado permanentemente');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isGettingLocation = false;
      });

      context.read<MarketplaceBloc>().add(MarketplaceUpdateUserLocation(
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

  void _showImagePicker() {
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
                context.read<MarketplaceBloc>().add(MarketplacePhotoPickRequested());
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () {
                Navigator.pop(context);
                context.read<MarketplaceBloc>().add(MarketplacePhotoCaptureRequested());
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _submitListing() {
    if (!_formKey.currentState!.validate()) return;
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Se requiere ubicación')),
      );
      return;
    }

    double? price;
    if (_selectedType == ListingType.sale) {
      price = double.tryParse(_priceController.text);
    }

    context.read<MarketplaceBloc>().add(MarketplaceListingSubmitted(
      title: _titleController.text,
      description: _descriptionController.text,
      category: _selectedCategory,
      listingType: _selectedType,
      price: price,
      tradeFor: _selectedType == ListingType.trade ? _tradeForController.text : null,
      latitude: _latitude!,
      longitude: _longitude!,
      locationName: _locationNameController.text.isEmpty ? null : _locationNameController.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Anuncio'),
      ),
      body: BlocConsumer<MarketplaceBloc, MarketplaceState>(
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
                content: Text('✅ Anuncio publicado'),
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
                  // Fotos
                  _buildPhotosSection(state),
                  const SizedBox(height: 24),

                  // Título
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Título del anuncio *',
                      hintText: 'Ej: Esqueje de Monstera variegata',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El título es obligatorio';
                      }
                      if (value.length < 5) {
                        return 'Mínimo 5 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Descripción
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Descripción *',
                      hintText: 'Describe tu producto: estado, tamaño, cuidados especiales...',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'La descripción es obligatoria';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Categoría
                  Text(
                    'Categoría *',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _buildCategorySelector(),
                  const SizedBox(height: 24),

                  // Tipo de transacción
                  Text(
                    'Tipo de transacción *',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _buildTypeSelector(),
                  const SizedBox(height: 16),

                  // Precio (si es venta)
                  if (_selectedType == ListingType.sale)
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Precio (€) *',
                        hintText: 'Ej: 15.00',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.euro),
                      ),
                      validator: (value) {
                        if (_selectedType == ListingType.sale) {
                          if (value == null || value.isEmpty) {
                            return 'El precio es obligatorio para ventas';
                          }
                          final price = double.tryParse(value);
                          if (price == null || price < 0) {
                            return 'Precio inválido';
                          }
                        }
                        return null;
                      },
                    ),

                  // Intercambio por (si es intercambio)
                  if (_selectedType == ListingType.trade)
                    TextFormField(
                      controller: _tradeForController,
                      decoration: const InputDecoration(
                        labelText: 'Acepto intercambio por',
                        hintText: 'Ej: Cactus San Pedro, Aloe vera...',
                        border: OutlineInputBorder(),
                      ),
                    ),

                  if (_selectedType == ListingType.giveaway)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Este anuncio aparecerá como "Regalo" y no incluirá precio.',
                              style: TextStyle(color: Colors.green.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Ubicación
                  Text(
                    'Ubicación *',
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
                      hintText: 'Ej: Barrio Salamanca, Madrid',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Botón enviar
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: state.isSubmitting ? null : _submitListing,
                      icon: state.isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.publish),
                      label: Text(state.isSubmitting ? 'Publicando...' : 'Publicar Anuncio'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhotosSection(MarketplaceState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fotos',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        if (state.hasPhotosSelected)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: state.photoCount + 1,
              itemBuilder: (context, index) {
                if (index == state.photoCount) {
                  // Botón añadir más
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: _showImagePicker,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: const Icon(Icons.add_a_photo, size: 32),
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          state.selectedPhotos![index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton.filled(
                          onPressed: () {
                            context.read<MarketplaceBloc>().add(MarketplaceRemovePhoto(index));
                          },
                          icon: const Icon(Icons.close, size: 16),
                          style: IconButton.styleFrom(
                            minimumSize: const Size(24, 24),
                            backgroundColor: Colors.black54,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          )
        else
          InkWell(
            onTap: _showImagePicker,
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text('Añadir fotos'),
                  Text(
                    'Máximo 5 fotos recomendado',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ListingCategory.values.map((category) {
        final isSelected = _selectedCategory == category;
        return ChoiceChip(
          label: Text(category.displayName),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() => _selectedCategory = category);
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      children: ListingType.values.map((type) {
        final isSelected = _selectedType == type;
        return RadioListTile<ListingType>(
          title: Text(type.displayName),
          subtitle: Text(type.description),
          value: type,
          groupValue: _selectedType,
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedType = value);
            }
          },
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
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
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
                  Text('Error de ubicación', style: TextStyle(color: Theme.of(context).colorScheme.error)),
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
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ubicación obtenida', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                  Text('${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}'),
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
          const Expanded(child: Text('Ubicación no disponible')),
          ElevatedButton(
            onPressed: _getCurrentLocation,
            child: const Text('Obtener'),
          ),
        ],
      ),
    );
  }
}
