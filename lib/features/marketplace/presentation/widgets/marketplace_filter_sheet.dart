import 'package:flutter/material.dart';
import 'package:planticula/features/marketplace/domain/entities/marketplace_listing.dart';
import 'package:planticula/features/marketplace/presentation/bloc/marketplace_bloc.dart';

class MarketplaceFilterSheet extends StatefulWidget {
  final ScrollController scrollController;
  final ValueChanged<MarketplaceFilterChanged> onApply;

  const MarketplaceFilterSheet({
    super.key,
    required this.scrollController,
    required this.onApply,
  });

  @override
  State<MarketplaceFilterSheet> createState() => _MarketplaceFilterSheetState();
}

class _MarketplaceFilterSheetState extends State<MarketplaceFilterSheet> {
  double _radiusKm = 10;
  List<ListingCategory> _selectedCategories = [];
  List<ListingType> _selectedTypes = [];
  double? _maxPrice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        controller: widget.scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtros',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                TextButton(
                  onPressed: _reset,
                  child: const Text('Restablecer'),
                ),
              ],
            ),
            const Divider(),

            // Radio
            Text('Distancia máxima: ${_radiusKm.toStringAsFixed(1)} km'),
            Slider(
              value: _radiusKm,
              min: 1,
              max: 50,
              divisions: 49,
              label: '${_radiusKm.toStringAsFixed(1)} km',
              onChanged: (v) => setState(() => _radiusKm = v),
            ),
            const SizedBox(height: 16),

            // Categorías
            Text('Categorías', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ListingCategory.values.map((cat) {
                final isSelected = _selectedCategories.contains(cat);
                return FilterChip(
                  label: Text(cat.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedCategories.add(cat);
                      } else {
                        _selectedCategories.remove(cat);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Tipo
            Text('Tipo de transacción', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ListingType.values.map((type) {
                final isSelected = _selectedTypes.contains(type);
                return FilterChip(
                  label: Text(type.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTypes.add(type);
                      } else {
                        _selectedTypes.remove(type);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Precio máximo
            Text('Precio máximo', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.euro),
                hintText: 'Sin límite',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                setState(() => _maxPrice = double.tryParse(v));
              },
            ),
            const SizedBox(height: 24),

            // Aplicar
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  widget.onApply(MarketplaceFilterChanged(
                    radiusKm: _radiusKm,
                    categories: _selectedCategories.isEmpty ? null : _selectedCategories,
                    listingTypes: _selectedTypes.isEmpty ? null : _selectedTypes,
                    maxPrice: _maxPrice,
                  ));
                  Navigator.pop(context);
                },
                child: const Text('Aplicar filtros'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _reset() {
    setState(() {
      _radiusKm = 10;
      _selectedCategories = [];
      _selectedTypes = [];
      _maxPrice = null;
    });
  }
}
