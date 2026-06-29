import 'package:planticula/core/network/result.dart';
import 'package:planticula/core/network/supabase_client.dart';
import 'package:planticula/core/utils/logger.dart';
import 'package:planticula/features/plants/data/datasources/plant_remote_datasource.dart';
import 'package:planticula/features/plants/data/models/care_log_model.dart';
import 'package:planticula/features/plants/data/models/plant_model.dart';
import 'package:planticula/features/plants/domain/entities/care_log.dart';

/// Implementación de PlantRemoteDataSource usando Supabase
class PlantRemoteDataSourceImpl implements PlantRemoteDataSource {
  final AppSupabaseClient _client;

  PlantRemoteDataSourceImpl(this._client);

  String get _table => 'plants';

  String? get _userId => _client.currentUser?.id;

  /// Inserta una entrada en care_logs (mejor esfuerzo: no rompe la operación
  /// principal si falla el registro del historial).
  Future<void> _logCare(
    PlantModel plant,
    CareLogType type, {
    DateTime? eventDate,
    String? note,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _client.from('care_logs').insert({
        'plant_id': plant.id,
        'user_id': _userId,
        'organization_id': plant.organizationId,
        'type': type.name,
        'event_date': (eventDate ?? DateTime.now()).toIso8601String(),
        if (note != null) 'note': note,
        if (metadata != null) 'metadata': metadata,
      });
    } catch (e, st) {
      Logger.e('⚠️ Error logging care event (${type.name})', error: e, stackTrace: st);
    }
  }

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
      if (plantResult is! Success<PlantModel>) {
        return plantResult;
      }

      final plant = plantResult.data;

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
      await _logCare(updatedPlant, CareLogType.watering, eventDate: now);
      Logger.i('✅ Watered plant: ${updatedPlant.name}. Next: $nextWatering');
      return Success(updatedPlant);
    } catch (e, stackTrace) {
      Logger.e('❌ Error watering plant $id', error: e, stackTrace: stackTrace);
      return Failure('Error al registrar riego: ${e.toString()}');
    }
  }

  @override
  Future<Result<PlantModel>> waterPlantWithDate(String id, int daysAgo) async {
    try {
      Logger.d('💧 Watering plant: $id with date $daysAgo days ago');

      if (_userId == null) {
        return const Failure('Usuario no autenticado');
      }

      // Obtener la planta actual
      final plantResult = await getPlantById(id);
      if (plantResult is! Success<PlantModel>) {
        return plantResult;
      }

      final plant = plantResult.data;

      if (plant.wateringFrequency == null || plant.wateringFrequency! <= 0) {
        return const Failure('La planta no tiene configurada frecuencia de riego');
      }

      // Calcular fecha de riego (hoy - daysAgo días)
      final lastWatered = DateTime.now().subtract(Duration(days: daysAgo));
      // Calcular siguiente riego: desde el último riego + frecuencia
      final nextWatering = lastWatered.add(Duration(days: plant.wateringFrequency!));

      // Actualizar fechas de riego
      final updateData = {
        'last_watered': lastWatered.toIso8601String(),
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
      await _logCare(updatedPlant, CareLogType.watering, eventDate: lastWatered);
      Logger.i('✅ Watered plant: ${updatedPlant.name} with date $daysAgo days ago. Next: $nextWatering');
      return Success(updatedPlant);
    } catch (e, stackTrace) {
      Logger.e('❌ Error watering plant $id with date', error: e, stackTrace: stackTrace);
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
      await _logCare(updatedPlant, CareLogType.transplant,
          eventDate: now, metadata: {'pot_size': newPotSize});
      Logger.i('✅ Transplanted plant: ${updatedPlant.name}. New pot size: $newPotSize');
      return Success(updatedPlant);
    } catch (e, stackTrace) {
      Logger.e('❌ Error transplanting plant $id', error: e, stackTrace: stackTrace);
      return Failure('Error al registrar trasplante: ${e.toString()}');
    }
  }

  @override
  Future<Result<List<PlantModel>>> getPlantsByLocationIds(
    List<String> locationIds,
  ) async {
    try {
      if (_userId == null) return const Failure('Usuario no autenticado');
      if (locationIds.isEmpty) return const Success([]);
      final response = await _client
          .from(_table)
          .select()
          .eq('user_id', _userId!)
          .inFilter('location_id', locationIds)
          .order('created_at', ascending: false);
      final plants = (response as List).map((j) => PlantModel.fromJson(j)).toList();
      return Success(plants);
    } catch (e, st) {
      Logger.e('❌ Error fetching plants by location', error: e, stackTrace: st);
      return Failure('Error al cargar plantas de la localización: ${e.toString()}');
    }
  }

  @override
  Future<Result<PlantModel>> assignPlantToLocation(
    String plantId, {
    String? locationId,
  }) async {
    try {
      if (_userId == null) return const Failure('Usuario no autenticado');
      final data = <String, dynamic>{'location_id': locationId};
      final response = await _client
          .from(_table)
          .update(data)
          .eq('id', plantId)
          .eq('user_id', _userId!)
          .select()
          .single();
      final plant = PlantModel.fromJson(response);
      Logger.i('✅ Assigned plant ${plant.name} to location $locationId');
      return Success(plant);
    } catch (e, st) {
      Logger.e('❌ Error assigning plant to location', error: e, stackTrace: st);
      return Failure('Error al asignar planta a la localización: ${e.toString()}');
    }
  }

  @override
  Future<Result<List<CareLogModel>>> getCareLogs(String plantId) async {
    try {
      if (_userId == null) return const Failure('Usuario no autenticado');
      final response = await _client
          .from('care_logs')
          .select()
          .eq('plant_id', plantId)
          .order('event_date', ascending: false);
      final logs = (response as List)
          .map((j) => CareLogModel.fromJson(j as Map<String, dynamic>))
          .toList();
      return Success(logs);
    } catch (e, st) {
      Logger.e('❌ Error fetching care logs', error: e, stackTrace: st);
      return Failure('Error al cargar el historial: ${e.toString()}');
    }
  }

  @override
  Future<Result<CareLogModel>> addCareLog({
    required String plantId,
    required CareLogType type,
    DateTime? eventDate,
    String? note,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (_userId == null) return const Failure('Usuario no autenticado');
      // organization_id se hereda de la planta para mantener el aislamiento.
      final plantResult = await getPlantById(plantId);
      final orgId =
          plantResult is Success<PlantModel> ? plantResult.data.organizationId : null;
      final response = await _client
          .from('care_logs')
          .insert({
            'plant_id': plantId,
            'user_id': _userId,
            'organization_id': orgId,
            'type': type.name,
            'event_date': (eventDate ?? DateTime.now()).toIso8601String(),
            if (note != null) 'note': note,
            if (metadata != null) 'metadata': metadata,
          })
          .select()
          .single();
      return Success(CareLogModel.fromJson(response));
    } catch (e, st) {
      Logger.e('❌ Error adding care log', error: e, stackTrace: st);
      return Failure('Error al guardar en el historial: ${e.toString()}');
    }
  }

  @override
  Future<Result<void>> deleteCareLog(String id) async {
    try {
      if (_userId == null) return const Failure('Usuario no autenticado');
      await _client.from('care_logs').delete().eq('id', id);
      return const Success(null);
    } catch (e, st) {
      Logger.e('❌ Error deleting care log', error: e, stackTrace: st);
      return Failure('Error al eliminar del historial: ${e.toString()}');
    }
  }
}
