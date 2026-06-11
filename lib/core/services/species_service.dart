import 'package:flutter/foundation.dart';
import 'package:planticula/core/data/species/plant_species.dart';
import 'package:planticula/core/data/species/local_species_catalog.dart';
import 'package:planticula/core/data/species/species_remote_datasource.dart';
import 'package:planticula/core/network/supabase_client.dart';

/// Service that manages plant species data.
/// Priority: Supabase DB > Local catalog (offline fallback)
class SpeciesService {
  final SpeciesRemoteDatasource _remoteDatasource;

  // In-memory cache to avoid repeated DB calls
  List<PlantSpecies>? _cachedSpecies;
  DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 30);

  SpeciesService({SpeciesRemoteDatasource? remoteDatasource})
      : _remoteDatasource = remoteDatasource ??
            SpeciesRemoteDatasource(AppSupabaseClient.instance);

  /// Search species by query. Uses cached data if available.
  Future<List<PlantSpecies>> searchSpecies(String query) async {
    final allSpecies = await _getAllSpecies();

    if (query.trim().isEmpty) {
      return allSpecies;
    }

    final q = query.toLowerCase();
    final results = <PlantSpecies>[];

    for (final species in allSpecies) {
      // Check parent match
      if (species.commonName.toLowerCase().contains(q) ||
          species.scientificName.toLowerCase().contains(q) ||
          (species.description?.toLowerCase().contains(q) ?? false)) {
        results.add(species);
        continue; // Don't double-add
      }
      // Check if any variety matches -> add parent with all varieties visible
      final hasMatchingVariety = species.varieties.any((v) =>
          v.commonName.toLowerCase().contains(q) ||
          v.scientificName.toLowerCase().contains(q) ||
          (v.description?.toLowerCase().contains(q) ?? false));
      if (hasMatchingVariety) {
        results.add(species);
      }
    }
    return results;
  }

  /// Get a specific species by ID (checks varieties too)
  Future<PlantSpecies?> getSpeciesById(String id) async {
    final allSpecies = await _getAllSpecies();

    for (final species in allSpecies) {
      if (species.id == id) return species;
      for (final variety in species.varieties) {
        if (variety.id == id) return variety;
      }
    }
    return null;
  }

  /// Get all species, using cache or fetching from remote/local
  Future<List<PlantSpecies>> _getAllSpecies() async {
    // Return cache if fresh
    if (_cachedSpecies != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cachedSpecies!;
    }

    // Try remote (Supabase)
    try {
      final remoteSpecies = await _remoteDatasource.getAllSpecies();
      if (remoteSpecies.isNotEmpty) {
        _cachedSpecies = remoteSpecies;
        _cacheTime = DateTime.now();
        return remoteSpecies;
      }
    } catch (e) {
      debugPrint('Remote species fetch failed, using local fallback: $e');
    }

    // Fallback to local catalog
    _cachedSpecies = LocalSpeciesCatalog.species;
    _cacheTime = DateTime.now();
    return _cachedSpecies!;
  }

  /// Force refresh from remote
  Future<void> refresh() async {
    _cachedSpecies = null;
    _cacheTime = null;
    await _getAllSpecies();
  }

  void dispose() {
    _cachedSpecies = null;
  }
}
