import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:planticula/features/pest_alerts/domain/entities/pest_alert.dart';
import 'package:planticula/features/pest_alerts/presentation/bloc/pest_alerts_bloc.dart';

class PestAlertsFiltersSheet extends StatefulWidget {
  const PestAlertsFiltersSheet({super.key});

  @override
  State<PestAlertsFiltersSheet> createState() => _PestAlertsFiltersSheetState();
}

class _PestAlertsFiltersSheetState extends State<PestAlertsFiltersSheet> {
  double _radiusKm = 10.0;
  int _daysLimit = 30;
  List<PestType> _selectedTypes = [];
  List<Severity> _selectedSeverities = [];
  bool _includeResolved = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<PestAlertsBloc>().state;
    _radiusKm = state.filterRadiusKm;
    _daysLimit = state.filterDaysLimit;
    _selectedTypes = List.from(state.filterPestTypes);
    _selectedSeverities = List.from(state.filterSeverities);
    _includeResolved = state.includeResolved;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Filtros',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _radiusKm = 10.0;
                        _daysLimit = 30;
                        _selectedTypes = [];
                        _selectedSeverities = [];
                        _includeResolved = false;
                      });
                    },
                    child: const Text('Reiniciar'),
                  ),
                ],
              ),
              const Divider(),

              // Contenido scrollable
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Radio de distancia
                    Text(
                      'Distancia máxima: ${_radiusKm.toStringAsFixed(0)} km',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Slider(
                      value: _radiusKm,
                      min: 1,
                      max: 50,
                      divisions: 49,
                      label: '${_radiusKm.toStringAsFixed(0)} km',
                      onChanged: (value) => setState(() => _radiusKm = value),
                    ),
                    const SizedBox(height: 16),

                    // Días límite
                    Text(
                      'Alertas de los últimos $_daysLimit días',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Slider(
                      value: _daysLimit.toDouble(),
                      min: 1,
                      max: 90,
                      divisions: 89,
                      label: '$_daysLimit días',
                      onChanged: (value) => setState(() => _daysLimit = value.toInt()),
                    ),
                    const SizedBox(height: 16),

                    // Tipos de plaga
                    Text(
                      'Tipos de plaga',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: PestType.values.map((type) {
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

                    // Severidades
                    Text(
                      'Gravedad',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: Severity.values.map((severity) {
                        final isSelected = _selectedSeverities.contains(severity);
                        return FilterChip(
                          label: Text(severity.displayName),
                          selected: isSelected,
                          selectedColor: Color(severity.colorValue).withValues(alpha: 0.2),
                          checkmarkColor: Color(severity.colorValue),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedSeverities.add(severity);
                              } else {
                                _selectedSeverities.remove(severity);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Incluir resueltas
                    SwitchListTile(
                      title: const Text('Incluir alertas resueltas'),
                      value: _includeResolved,
                      onChanged: (value) => setState(() => _includeResolved = value),
                    ),
                  ],
                ),
              ),

              // Botón aplicar
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    context.read<PestAlertsBloc>().add(PestAlertsFilterChanged(
                      radiusKm: _radiusKm,
                      daysLimit: _daysLimit,
                      pestTypes: _selectedTypes.isEmpty ? null : _selectedTypes,
                      severities: _selectedSeverities.isEmpty ? null : _selectedSeverities,
                      includeResolved: _includeResolved,
                    ));
                    Navigator.pop(context);
                  },
                  child: const Text('Aplicar Filtros'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
