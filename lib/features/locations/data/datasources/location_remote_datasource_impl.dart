import 'package:flutter/foundation.dart';
import 'package:planticula/core/network/result.dart';
import 'package:planticula/core/network/supabase_client.dart';
import 'package:planticula/features/locations/data/datasources/location_remote_datasource.dart';
import 'package:planticula/features/locations/data/models/location_model.dart';

class LocationRemoteDataSourceImpl implements LocationRemoteDataSource {
  final AppSupabaseClient _client;

  LocationRemoteDataSourceImpl(this._client);

  String? get _userId => _client.currentUser?.id;

  @override
  Future<Result<List<LocationModel>>> getLocations(String organizationId) async {
    try {
      if (_userId == null) return const Failure('Usuario no autenticado');
      // RLS limita el SELECT a las localizaciones de organizaciones donde el
      // usuario es miembro; filtramos además por la organización activa.
      final response = await _client
          .from('locations')
          .select()
          .eq('organization_id', organizationId)
          .order('sort_order');
      final locations = (response as List)
          .map((j) => LocationModel.fromJson(j as Map<String, dynamic>))
          .toList();
      return Success(locations);
    } catch (e, st) {
      debugPrint('[LocationDS] getLocations error: $e\n$st');
      return Failure('Error al cargar localizaciones: $e');
    }
  }

  @override
  Future<Result<LocationModel>> createLocation(Map<String, dynamic> data) async {
    try {
      if (_userId == null) return const Failure('Usuario no autenticado');
      final response = await _client
          .from('locations')
          .insert(data)
          .select()
          .single();
      return Success(LocationModel.fromJson(response));
    } catch (e, st) {
      debugPrint('[LocationDS] createLocation error: $e\n$st');
      return Failure('Error al crear localización: $e');
    }
  }

  @override
  Future<Result<LocationModel>> updateLocation(LocationModel location) async {
    try {
      if (_userId == null) return const Failure('Usuario no autenticado');
      final data = location.toJson()
        ..remove('id')
        ..remove('organization_id')
        ..remove('created_at');
      final response = await _client
          .from('locations')
          .update(data)
          .eq('id', location.id)
          .select()
          .single();
      return Success(LocationModel.fromJson(response));
    } catch (e, st) {
      debugPrint('[LocationDS] updateLocation error: $e\n$st');
      return Failure('Error al actualizar localización: $e');
    }
  }

  @override
  Future<Result<void>> deleteLocation(String id) async {
    try {
      if (_userId == null) return const Failure('Usuario no autenticado');
      await _client.from('locations').delete().eq('id', id);
      return const Success(null);
    } catch (e, st) {
      debugPrint('[LocationDS] deleteLocation error: $e\n$st');
      return Failure('Error al eliminar localización: $e');
    }
  }
}
