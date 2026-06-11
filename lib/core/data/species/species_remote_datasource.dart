import 'package:planticula/core/data/species/plant_species.dart';
import 'package:planticula/core/network/supabase_client.dart';
import 'package:planticula/core/utils/logger.dart';

/// Remote datasource for species catalog - fetches from Supabase
class SpeciesRemoteDatasource {
  final AppSupabaseClient _client;

  static const String _table = 'species_catalog';

  SpeciesRemoteDatasource(this._client);

  /// Fetch all species from the database (parent species only, with varieties nested)
  Future<List<PlantSpecies>> getAllSpecies() async {
    try {
      Logger.d('Fetching species catalog from Supabase...');

      // Fetch all species rows
      final response = await _client
          .from(_table)
          .select()
          .order('common_name');

      final allRows = response as List;

      // Separate parents and children
      final parentRows = allRows.where((r) => r['parent_id'] == null).toList();
      final childRows = allRows.where((r) => r['parent_id'] != null).toList();

      // Build parent -> children map
      final childrenMap = <String, List<Map<String, dynamic>>>{};
      for (final child in childRows) {
        final parentId = child['parent_id'] as String;
        childrenMap.putIfAbsent(parentId, () => []);
        childrenMap[parentId]!.add(child as Map<String, dynamic>);
      }

      // Build PlantSpecies list with nested varieties
      final species = parentRows.map((row) {
        final id = row['id'] as String;
        final varieties = (childrenMap[id] ?? [])
            .map((v) => _rowToSpecies(v, parentId: id))
            .toList();
        return _rowToSpecies(row as Map<String, dynamic>, varieties: varieties);
      }).toList();

      Logger.i('Loaded ${species.length} species (${childRows.length} varieties)');
      return species;
    } catch (e, stackTrace) {
      Logger.e('Error fetching species catalog', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Search species by query
  Future<List<PlantSpecies>> searchSpecies(String query) async {
    try {
      if (query.isEmpty) return await getAllSpecies();

      final response = await _client
          .from(_table)
          .select()
          .or('common_name.ilike.%$query%,scientific_name.ilike.%$query%,description.ilike.%$query%')
          .order('common_name');

      final allRows = response as List;

      // Collect parent IDs for any matched children (to load full parent with all varieties)
      final matchedParentIds = <String>{};
      final directMatches = <Map<String, dynamic>>[];

      for (final row in allRows) {
        final parentId = row['parent_id'] as String?;
        if (parentId != null) {
          matchedParentIds.add(parentId);
        } else {
          directMatches.add(row as Map<String, dynamic>);
          matchedParentIds.add(row['id'] as String);
        }
      }

      // Now fetch parents + all their children to show complete info
      final result = <PlantSpecies>[];

      for (final parentRow in directMatches) {
        final id = parentRow['id'] as String;
        // Fetch children for this parent
        final childResponse = await _client
            .from(_table)
            .select()
            .eq('parent_id', id)
            .order('common_name');

        final children = (childResponse as List)
            .map((v) => _rowToSpecies(v as Map<String, dynamic>, parentId: id))
            .toList();

        result.add(_rowToSpecies(parentRow, varieties: children));
      }

      // For child matches whose parents weren't in directMatches, add individual varieties
      for (final row in allRows) {
        final parentId = row['parent_id'] as String?;
        if (parentId != null &&
            !directMatches.any((p) => p['id'] == parentId)) {
          result.add(_rowToSpecies(row as Map<String, dynamic>, parentId: parentId));
        }
      }

      return result;
    } catch (e, stackTrace) {
      Logger.e('Error searching species', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Find species by ID
  Future<PlantSpecies?> getSpeciesById(String id) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      // If it's a parent, load its varieties
      if (response['parent_id'] == null) {
        final childResponse = await _client
            .from(_table)
            .select()
            .eq('parent_id', id)
            .order('common_name');

        final children = (childResponse as List)
            .map((v) => _rowToSpecies(v as Map<String, dynamic>, parentId: id))
            .toList();

        return _rowToSpecies(response, varieties: children);
      }

      return _rowToSpecies(response, parentId: response['parent_id'] as String?);
    } catch (e, stackTrace) {
      Logger.e('Error getting species by id: $id', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Convert a database row to PlantSpecies
  PlantSpecies _rowToSpecies(
    Map<String, dynamic> row, {
    String? parentId,
    List<PlantSpecies> varieties = const [],
  }) {
    // Parse growth phases from JSONB
    final growthPhasesJson = row['growth_phases'];
    List<GrowthPhaseInfo> growthPhases = GrowthPhaseInfo.defaultPhases;

    if (growthPhasesJson != null) {
      if (growthPhasesJson is List) {
        growthPhases = growthPhasesJson
            .map((e) => GrowthPhaseInfo.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }

    return PlantSpecies(
      id: row['id'] as String,
      commonName: row['common_name'] as String,
      scientificName: row['scientific_name'] as String,
      imageUrl: row['image_url'] as String?,
      parentId: parentId ?? row['parent_id'] as String?,
      description: row['description'] as String?,
      category: row['category'] as String?,
      isEdible: row['is_edible'] as bool? ?? false,
      varieties: varieties,
      wateringFrequencyIndoor: row['watering_frequency_indoor'] as int? ?? 7,
      wateringFrequencyOutdoor: row['watering_frequency_outdoor'] as int? ?? 5,
      sunlightHoursMin: (row['sunlight_hours_min'] as num?)?.toDouble() ?? 4,
      sunlightHoursMax: (row['sunlight_hours_max'] as num?)?.toDouble() ?? 8,
      sunlightLevel: SunlightLevel.fromString(row['sunlight_level'] as String? ?? 'medium'),
      growthPhases: growthPhases,
      minTemperature: row['min_temperature'] as int? ?? 5,
      maxTemperature: row['max_temperature'] as int? ?? 35,
      droughtTolerant: row['drought_tolerant'] as bool? ?? false,
      humidityLoving: row['humidity_loving'] as bool? ?? false,
      hotWeatherMultiplier: (row['hot_weather_multiplier'] as num?)?.toDouble() ?? 0.7,
      coldWeatherMultiplier: (row['cold_weather_multiplier'] as num?)?.toDouble() ?? 1.5,
      rainReductionDays: (row['rain_reduction_days'] as num?)?.toDouble() ?? 2,
    );
  }
}
