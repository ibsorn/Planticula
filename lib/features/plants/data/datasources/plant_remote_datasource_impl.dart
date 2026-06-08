import 'package:planticula/core/network/result.dart';
import 'package:planticula/core/network/supabase_client.dart';
import 'package:planticula/core/utils/logger.dart';
import 'package:planticula/features/plants/data/datasources/plant_remote_datasource.dart';
import 'package:planticula/features/plants/data/models/plant_model.dart';

/// Implementación de PlantRemoteDataSource usando Supabase
class PlantRemoteDataSourceImpl implements PlantRemoteDataSource {
  final SupabaseClient _client;
  final Logger _logger;

  PlantRemoteDataSourceImpl(this._client) : _logger = Logger();

  String get _table => 'plants';

  String? get _userId => _client.currentUser?.id;

  @override
  Future<Result<List<PlantModel>>> getPlants() async {
    try {
      _logger.d('📥 Fetching plants for user: $_userId');

      if (_userId == null) {
        return const Failure('Usuario no autenticado');
      }

      final response = await _client
          .from(_table)
          .select()
          .eq('user_id', _userId!)
          .order('created_at', ascending: false);

      final plants = (response as List)
          .map((json) => PlantModel.fromJson(json))
          .toList();

      _logger.i('✅ Fetched ${plants.length} plants');
      return Success(plants);
    } catch (e, stackTrace) {
      _logger.e('❌ Error fetching plants', error: e, stackTrace: stackTrace);
      return Failure('Error al cargar plantas: ${e.toString()}');
    }
  }

  @override
  Future<Result<PlantModel>> getPlantById(String id) async {
    try {
      _logger.d('📥 Fetching plant: $id');

      if (_userId == null) {
        return const Failure('Usuario no autenticado');
      }

      final response = await _client
          .from(_table)
          .select()
          .eq('id', id)
          .eq('user_id', _userId!)
          .single();

      final plant = PlantModel.fromJson(response);
      _logger.i('✅ Fetched plant: ${plant.name}');
      return Success(plant);
    } catch (e, stackTrace) {
      _logger.e('❌ Error fetching plant $id', error: e, stackTrace: stackTrace);
      return Failure('Error al cargar planta: ${e.toString()}');
    }
  }

  @override
  Future<Result<PlantModel>> createPlant(PlantModel plant) async {
    try {
      _logger.d('📤 Creating plant: ${plant.name}');

      if (_userId == null) {
        return const Failure('Usuario no autenticado');
      }

      // Preparar datos para inserción
      final data = plant.toJson();
      data['user_id'] = _userId;

      // Calcular next_watering si hay frecuencia
      if (plant.wateringFrequency != null && plant.wateringFrequency! > 0) {
        final lastWatered = plant.lastWatered ?? DateTime.now();
        data['last_watered'] = lastWatered.toIso8601String();
        data['next_watering'] = lastWatered
            .add(Duration(days: plant.wateringFrequency!))
            .toIso8601String();
      }

      // Remover campos que no deben enviarse
      data.remove('id'); // Se genera automáticamente
      data.remove('created_at');
      data.remove('updated_at');

      final response = await _client
          .from(_table)
          .insert(data)
          .select()
          .single();

      final createdPlant = PlantModel.fromJson(response);
      _logger.i('✅ Created plant: ${createdPlant.name} (${createdPlant.id})');
      return Success(createdPlant);
    } catch (e, stackTrace) {
      _logger.e('❌ Error creating plant', error: e, stackTrace: stackTrace);
      return Failure('Error al crear planta: ${e.toString()}');
    }
  }

  @override
  Future<Result<PlantModel>> updatePlant(PlantModel plant) async {
    try {
      _logger.d('📤 Updating plant: ${plant.id}');

      if (_userId == null) {
        return const Failure('Usuario no autenticado');
      }

      // Preparar datos para actualización
      final data = plant.toJson();

      // Recalcular next_watering si cambió la frecuencia o last_watered
      if (plant.wateringFrequency != null && plant.wateringFrequency! > 0) {
        final lastWatered = plant.lastWatered ?? DateTime.now();
        data['next_watering'] = lastWatered
            .add(Duration(days: plant.wateringFrequency!))
            .toIso8601String();
      } else {
        data['next_watering'] = null;
      }

      // Remover campos que no deben actualizarse
      data.remove('id');
      data.remove('user_id');
      data.remove('created_at');

      final response = await _client
          .from(_table)
          .update(data)
          .eq('id', plant.id)
          .eq('user_id', _userId!)
          .select()
          .single();

      final updatedPlant = PlantModel.fromJson(response);
      _logger.i('✅ Updated plant: ${updatedPlant.name}');
      return Success(updatedPlant);
    } catch (e, stackTrace) {
      _logger.e('❌ Error updating plant ${plant.id}',
          error: e, stackTrace: stackTrace);
      return Failure('Error al actualizar planta: ${e.toString()}');
    }
  }

  @override
  Future<Result<void>> deletePlant(String id) async {
    try {
      _logger.d('🗑️ Deleting plant: $id');

      if (_userId == null) {
        return const Failure('Usuario no autenticado');
      }

      await _client
          .from(_table)
          .delete()
          .eq('id', id)
          .eq('user_id', _userId!);

      _logger.i('✅ Deleted plant: $id');
      return const Success(null);
    } catch (e, stackTrace) {
      _logger.e('❌ Error deleting plant $id', error: e, stackTrace: stackTrace);
      return Failure('Error al eliminar planta: ${e.toString()}');
    }
  }

  @override
  Future<Result<List<PlantModel>>> searchPlants(String query) async {
    try {
      _logger.d('🔍 Searching plants: "$query"');

      if (_userId == null) {
        return const Failure('Usuario no autenticado');
      }

      final response = await _client
          .from(_table)
          .select()
          .eq('user_id', _userId!)
          .ilike('name', '%$query%')
          .order('created_at', ascending: false);

      final plants = (response as List)
          .map((json) => PlantModel.fromJson(json))
          .toList();

      _logger.i('✅ Found ${plants.length} plants matching "$query"');
      return Success(plants);
    } catch (e, stackTrace) {
      _logger.e('❌ Error searching plants', error: e, stackTrace: stackTrace);
      return Failure('Error al buscar plantas: ${e.toString()}');
    }
  }

  @override
  Future<Result<PlantModel>> waterPlant(String id) async {
    try {
      _logger.d('💧 Watering plant: $id');

      // Obtener la planta actual
      final plantResult = await getPlantById(id);
      if (plantResult is Failure<PlantModel>) {
        return plantResult;
      }

      final plant = (plantResult as Success<PlantModel>).data;

      if (plant.wateringFrequency == null || plant.wateringFrequency! <= 0) {
        return Failure('La planta no tiene configurada frecuencia de riego');
      }

      final now = DateTime.now();
      final nextWatering = now.add(Duration(days: plant.wateringFrequency!));

      // Actualizar fechas de riego
      final updateData = {
        'last_watered': now.toIso8601String(),
        'next_watering': nextWatering.toIso8601String(),
      };

      final response = await _client
          .from(_table)
          .update(updateData)
          .eq('id', id)
          .eq('user_id', _userId!)
          .select()
          .single();

      final updatedPlant = PlantModel.fromJson(response);
      _logger.i('✅ Watered plant: ${updatedPlant.name}. Next: $nextWatering');
      return Success(updatedPlant);
    } catch (e, stackTrace) {
      _logger.e('❌ Error watering plant $id', error: e, stackTrace: stackTrace);
      return Failure('Error al registrar riego: ${e.toString()}');
    }
  }
}
