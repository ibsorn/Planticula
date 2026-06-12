import 'package:planticula/core/network/result.dart';
import 'package:planticula/core/network/supabase_client.dart';
import 'package:planticula/core/utils/logger.dart';
import 'package:planticula/features/plants/data/datasources/plant_remote_datasource.dart';
import 'package:planticula/features/plants/data/models/plant_model.dart';

/// Implementación de PlantRemoteDataSource usando Supabase
class PlantRemoteDataSourceImpl implements PlantRemoteDataSource {
  final AppSupabaseClient _client;

  PlantRemoteDataSourceImpl(this._client);

  String get _table => 'plants';

  String? get _userId => _client.currentUser?.id;

  @override
  Future<Result<List<PlantModel>>> getPlants() async {
    try {
      Logger.d('📥 Fetching plants for user: $_userId');

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

      Logger.i('✅ Fetched ${plants.length} plants');
      return Success(plants);
    } catch (e, stackTrace) {
      Logger.e('❌ Error fetching plants', error: e, stackTrace: stackTrace);
      return Failure('Error al cargar plantas: ${e.toString()}');
    }
  }

  @override
  Future<Result<PlantModel>> getPlantById(String id) async {
    try {
      Logger.d('📥 Fetching plant: $id');

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
      Logger.i('✅ Fetched plant: ${plant.name}');
      return Success(plant);
    } catch (e, stackTrace) {
      Logger.e('❌ Error fetching plant $id', error: e, stackTrace: stackTrace);
      return Failure('Error al cargar planta: ${e.toString()}');
    }
  }

  @override
  Future<Result<PlantModel>> createPlant(PlantModel plant) async {
    try {
      Logger.d('📤 Creating plant: ${plant.name}');

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
      Logger.i('✅ Created plant: ${createdPlant.name} (${createdPlant.id})');
      return Success(createdPlant);
    } catch (e, stackTrace) {
      Logger.e('❌ Error creating plant', error: e, stackTrace: stackTrace);
      return Failure('Error al crear planta: ${e.toString()}');
    }
  }

  @override
  Future<Result<PlantModel>> updatePlant(PlantModel plant) async {
    try {
      Logger.d('📤 Updating plant: ${plant.id}');

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
      Logger.i('✅ Updated plant: ${updatedPlant.name}');
      return Success(updatedPlant);
    } catch (e, stackTrace) {
      Logger.e('❌ Error updating plant ${plant.id}',
          error: e, stackTrace: stackTrace);
      return Failure('Error al actualizar planta: ${e.toString()}');
    }
  }

  @override
  Future<Result<void>> deletePlant(String id) async {
    try {
      Logger.d('🗑️ Deleting plant: $id');

      if (_userId == null) {
        return const Failure('Usuario no autenticado');
      }

      await _client
          .from(_table)
          .delete()
          .eq('id', id)
          .eq('user_id', _userId!);

      Logger.i('✅ Deleted plant: $id');
      return const Success(null);
    } catch (e, stackTrace) {
      Logger.e('❌ Error deleting plant $id', error: e, stackTrace: stackTrace);
      return Failure('Error al eliminar planta: ${e.toString()}');
    }
  }

  @override
  Future<Result<List<PlantModel>>> searchPlants(String query) async {
    try {
      Logger.d('🔍 Searching plants: "$query"');

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

      Logger.i('✅ Found ${plants.length} plants matching "$query"');
      return Success(plants);
    } catch (e, stackTrace) {
      Logger.e('❌ Error searching plants', error: e, stackTrace: stackTrace);
      return Failure('Error al buscar plantas: ${e.toString()}');
    }
  }

  @override
  Future<Result<PlantModel>> waterPlant(String id) async {
    try {
      Logger.d('💧 Watering plant: $id');

      // Obtener la planta actual
      final plantResult = await getPlantById(id);
      if (plantResult is Failure<PlantModel>) {
        return plantResult;
      }

      final plant = (plantResult as Success<PlantModel>).data;

      if (plant.wateringFrequency == null || plant.wateringFrequency! <= 0) {
        return const Failure('La planta no tiene configurada frecuencia de riego');
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
      Logger.i('✅ Watered plant: ${updatedPlant.name}. Next: $nextWatering');
      return Success(updatedPlant);
    } catch (e, stackTrace) {
      Logger.e('❌ Error watering plant $id', error: e, stackTrace: stackTrace);
      return Failure('Error al registrar riego: ${e.toString()}');
    }
  }

  @override
  Future<Result<PlantModel>> transplantPlant(String id, String newPotSize) async {
    try {
      Logger.d('🪴 Transplanting plant: $id to pot size: $newPotSize');

      if (_userId == null) {
        return const Failure('Usuario no autenticado');
      }

      final now = DateTime.now();

      // Actualizar tamaño de maceta y fecha de trasplante
      final updateData = {
        'pot_size': newPotSize,
        'last_transplanted': now.toIso8601String(),
      };

      final response = await _client
          .from(_table)
          .update(updateData)
          .eq('id', id)
          .eq('user_id', _userId!)
          .select()
          .single();

      final updatedPlant = PlantModel.fromJson(response);
      Logger.i('✅ Transplanted plant: ${updatedPlant.name}. New pot size: $newPotSize');
      return Success(updatedPlant);
    } catch (e, stackTrace) {
      Logger.e('❌ Error transplanting plant $id', error: e, stackTrace: stackTrace);
      return Failure('Error al registrar trasplante: ${e.toString()}');
    }
  }
}
