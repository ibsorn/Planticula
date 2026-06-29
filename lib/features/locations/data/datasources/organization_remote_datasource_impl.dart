import 'package:flutter/foundation.dart';
import 'package:planticula/core/network/result.dart';
import 'package:planticula/core/network/supabase_client.dart';
import 'package:planticula/features/locations/data/datasources/organization_remote_datasource.dart';
import 'package:planticula/features/locations/data/models/organization_model.dart';

class OrganizationRemoteDataSourceImpl implements OrganizationRemoteDataSource {
  final AppSupabaseClient _client;

  OrganizationRemoteDataSourceImpl(this._client);

  String? get _userId => _client.currentUser?.id;

  @override
  Future<Result<List<OrganizationModel>>> getMyOrganizations() async {
    try {
      if (_userId == null) return const Failure('Usuario no autenticado');
      // RLS limita el SELECT a las organizaciones donde el usuario es miembro.
      final response = await _client
          .from('organizations')
          .select()
          .order('created_at');
      final orgs = (response as List)
          .map((j) => OrganizationModel.fromJson(j as Map<String, dynamic>))
          .toList();
      return Success(orgs);
    } catch (e, st) {
      debugPrint('[OrgDS] getMyOrganizations error: $e\n$st');
      return Failure('Error al cargar organizaciones: $e');
    }
  }

  @override
  Future<Result<OrganizationModel>> getOrCreateDefaultOrganization() async {
    try {
      if (_userId == null) return const Failure('Usuario no autenticado');
      final response =
          await _client.rpc('get_or_create_default_organization');
      final list = response as List;
      if (list.isEmpty) {
        return const Failure('No se pudo obtener la organización por defecto');
      }
      return Success(
          OrganizationModel.fromJson(list.first as Map<String, dynamic>));
    } catch (e, st) {
      debugPrint('[OrgDS] getOrCreateDefaultOrganization error: $e\n$st');
      return Failure('Error al obtener organización por defecto: $e');
    }
  }
}
