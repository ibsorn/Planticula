import 'package:flutter/foundation.dart';
import 'package:planticula/core/network/result.dart';
import 'package:planticula/core/network/supabase_client.dart';
import 'package:planticula/features/gardens/data/datasources/garden_remote_datasource.dart';
import 'package:planticula/features/gardens/data/models/garden_model.dart';
import 'package:planticula/features/gardens/data/models/garden_group_model.dart';

class GardenRemoteDataSourceImpl implements GardenRemoteDataSource {
  final AppSupabaseClient _client;

  GardenRemoteDataSourceImpl(this._client);

  String? get _userId => _client.currentUser?.id;

  // ── JARDINES ─────────────────────────────────────────────────────────────

  @override
  Future<Result<List<GardenModel>>> getGardens() async {
    try {
      if (_userId == null) return const Failure('Usuario no autenticado');
      final response = await _client
          .from('gardens')
          .select()
          .eq('user_id', _userId!)
          .order('sort_order');
      final gardens = (response as List)
          .map((j) => GardenModel.fromJson(j as Map<String, dynamic>))
          .toList();
      return Success(gardens);
    } catch (e, st) {
      debugPrint('[GardenDS] getGardens error: $e\n$st');
      return Failure('Error al cargar jardines: $e');
    }
  }

  @override
  Future<Result<GardenModel>> getGardenById(String id) async {
    try {
      if (_userId == null) return const Failure('Usuario no autenticado');
      final response = await _client
          .from('gardens')
          .select()
          .eq('id', id)
          .eq('user_id', _userId!)
          .single();
      return Success(GardenModel.fromJson(response));
    } catch (e, st) {
      debugPrint('[GardenDS] getGardenById error: $e\n$st');
      return Failure('Error al cargar jardín: $e');
    }
  }

  @override
  Future<Result<GardenModel>> createGarden(Map<String, dynamic> data) async {
    try {
      if (_userId == null) return const Failure('Usuario no autenticado');
      data['user_id'] = _userId; // siempre inyectamos el usuario actual
      final response = await _client
          .from('gardens')
          .insert(data)
          .select()
          .single();
      return Success(GardenModel.fromJson(response));
    } catch (e, st) {
      debugPrint('[GardenDS] createGarden error: $e\n$st');
      return Failure('Error al crear jardín: $e');
    }
  }

  @override
  Future<Result<GardenModel>> updateGarden(GardenModel garden) async {
    try {
      if (_userId == null) return const Failure('Usuario no autenticado');
      final data = garden.toJson()
        ..remove('id')
        ..remove('user_id')
        ..remove('created_at')
        ..remove('is_default'); // is_default no se puede cambiar desde el cliente
      final response = await _client
          .from('gardens')
          .update(data)
          .eq('id', garden.id)
          .eq('user_id', _userId!)
          .select()
          .single();
      return Success(GardenModel.fromJson(response));
    } catch (e, st) {
      debugPrint('[GardenDS] updateGarden error: $e\n$st');
      return Failure('Error al actualizar jardín: $e');
    }
  }

  @override
  Future<Result<void>> deleteGarden(String id) async {
    try {
      if (_userId == null) return const Failure('Usuario no autenticado');
      await _client
          .from('gardens')
          .delete()
          .eq('id', id)
          .eq('user_id', _userId!)
          .neq('is_default', true); // protección: no borrar el jardín por defecto
      return const Success(null);
    } catch (e, st) {
      debugPrint('[GardenDS] deleteGarden error: $e\n$st');
      return Failure('Error al eliminar jardín: $e');
    }
  }

  @override
  Future<Result<GardenModel>> getOrCreateDefaultGarden() async {
    try {
      if (_userId == null) return const Failure('Usuario no autenticado');
      final response = await _client.rpc('get_or_create_default_garden');
      final list = response as List;
      if (list.isEmpty) return const Failure('No se pudo obtener el jardín por defecto');
      return Success(GardenModel.fromJson(list.first as Map<String, dynamic>));
    } catch (e, st) {
      debugPrint('[GardenDS] getOrCreateDefaultGarden error: $e\n$st');
      return Failure('Error al obtener jardín por defecto: $e');
    }
  }

  // ── GRUPOS ───────────────────────────────────────────────────────────────

  @override
  Future<Result<List<GardenGroupModel>>> getGroupsByGarden(String gardenId) async {
    try {
      if (_userId == null) return const Failure('Usuario no autenticado');
      final response = await _client
          .from('garden_groups')
          .select()
          .eq('garden_id', gardenId)
          .eq('user_id', _userId!)
          .order('sort_order');
      final groups = (response as List)
          .map((j) => GardenGroupModel.fromJson(j as Map<String, dynamic>))
          .toList();
      return Success(groups);
    } catch (e, st) {
      debugPrint('[GardenDS] getGroupsByGarden error: $e\n$st');
      return Failure('Error al cargar grupos: $e');
    }
  }

  @override
  Future<Result<GardenGroupModel>> createGroup(Map<String, dynamic> data) async {
    try {
      if (_userId == null) return const Failure('Usuario no autenticado');
      data['user_id'] = _userId; // siempre inyectamos el usuario actual
      final response = await _client
          .from('garden_groups')
          .insert(data)
          .select()
          .single();
      return Success(GardenGroupModel.fromJson(response));
    } catch (e, st) {
      debugPrint('[GardenDS] createGroup error: $e\n$st');
      return Failure('Error al crear grupo: $e');
    }
  }

  @override
  Future<Result<GardenGroupModel>> updateGroup(GardenGroupModel group) async {
    try {
      if (_userId == null) return const Failure('Usuario no autenticado');
      final data = group.toJson()
        ..remove('id')
        ..remove('user_id')
        ..remove('garden_id')
        ..remove('created_at');
      final response = await _client
          .from('garden_groups')
          .update(data)
          .eq('id', group.id)
          .eq('user_id', _userId!)
          .select()
          .single();
      return Success(GardenGroupModel.fromJson(response));
    } catch (e, st) {
      debugPrint('[GardenDS] updateGroup error: $e\n$st');
      return Failure('Error al actualizar grupo: $e');
    }
  }

  @override
  Future<Result<void>> deleteGroup(String id) async {
    try {
      if (_userId == null) return const Failure('Usuario no autenticado');
      await _client
          .from('garden_groups')
          .delete()
          .eq('id', id)
          .eq('user_id', _userId!);
      return const Success(null);
    } catch (e, st) {
      debugPrint('[GardenDS] deleteGroup error: $e\n$st');
      return Failure('Error al eliminar grupo: $e');
    }
  }
}
