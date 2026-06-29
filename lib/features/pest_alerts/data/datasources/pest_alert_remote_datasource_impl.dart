import 'dart:typed_data';
import 'package:planticula/core/network/datasource_mixin.dart';
import 'package:planticula/core/network/result.dart';
import 'package:planticula/core/network/supabase_client.dart';
import 'package:planticula/core/storage/storage_service.dart';
import 'package:planticula/core/utils/logger.dart';
import 'package:planticula/features/pest_alerts/data/datasources/pest_alert_remote_datasource.dart';
import 'package:planticula/features/pest_alerts/data/models/pest_alert_model.dart';

/// Implementación de PestAlertRemoteDataSource usando Supabase
class PestAlertRemoteDataSourceImpl
    with DatasourceMixin
    implements PestAlertRemoteDataSource {
  @override
  final AppSupabaseClient client;
  final StorageService _storage;

  PestAlertRemoteDataSourceImpl(this.client)
      : _storage = StorageService(client);

  String get _table => 'pest_alerts';
  String get _bucket => 'pest-photos';
  String get _confirmationsTable => 'pest_alert_confirmations';

  @override
  Future<Result<PestAlertModel>> createAlert(CreatePestAlertRequest request) async {
    return guardedCall(
      errorPrefix: 'Error al crear alerta',
      operation: (uid) async {
        Logger.d('📤 Creando alerta de plaga');
        final data = request.toJson(uid);

        final response = await client
            .from(_table)
            .insert(data)
            .select()
            .single();

        final alert = PestAlertModel.fromJson(response);
        Logger.i('✅ Alerta creada: ${alert.id}');
        return alert;
      },
    );
  }

  @override
  Future<Result<PestAlertModel>> getAlertById(String id) async {
    try {
      Logger.d('📥 Obteniendo alerta: $id');

      final response = await client
          .from(_table)
          .select('''
            *,
            distance_km:0
          ''')
          .eq('id', id)
          .single();

      final alert = PestAlertModel.fromJson(response);
      return Success(alert);
    } catch (e, stackTrace) {
      Logger.e('❌ Error obteniendo alerta $id', error: e, stackTrace: stackTrace);
      return Failure('Error al cargar alerta: ${e.toString()}');
    }
  }

  @override
  Future<Result<List<PestAlertModel>>> getNearbyAlerts({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    int? daysLimit,
    List<String>? pestTypes,
    List<String>? severities,
    bool includeResolved = false,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      Logger.d('📍 Buscando alertas cercanas a ($latitude, $longitude) en ${radiusKm}km');

      // Usar la función RPC que calcula distancia con Haversine
      final params = {
        'p_latitude': latitude,
        'p_longitude': longitude,
        'p_radius_km': radiusKm,
        'p_limit': limit,
        'p_offset': offset,
        if (daysLimit != null) 'p_days_limit': daysLimit,
        if (pestTypes != null && pestTypes.isNotEmpty) 'p_pest_types': pestTypes,
        if (severities != null && severities.isNotEmpty) 'p_severities': severities,
        'p_include_resolved': includeResolved,
      };

      final response = await client.rpc('get_nearby_pest_alerts', params: params);

      final alerts = (response as List)
          .map((json) => PestAlertModel.fromJson(json))
          .toList();

      Logger.i('✅ Encontradas ${alerts.length} alertas cercanas');
      return Success(alerts);
    } catch (e, stackTrace) {
      Logger.e('❌ Error buscando alertas cercanas', error: e, stackTrace: stackTrace);

      // Fallback: query simple sin ordenamiento por distancia
      try {
        Logger.w('⚠️ Intentando query fallback sin función RPC');

        var query = client
            .from(_table)
            .select();

        // Filtros básicos (must come before order/limit)
        if (!includeResolved) {
          query = query.eq('is_resolved', false);
        }

        if (daysLimit != null) {
          final cutoffDate = DateTime.now().subtract(Duration(days: daysLimit));
          query = query.gte('reported_at', cutoffDate.toIso8601String());
        }

        if (pestTypes != null && pestTypes.isNotEmpty) {
          query = query.inFilter('pest_type', pestTypes);
        }

        if (severities != null && severities.isNotEmpty) {
          query = query.inFilter('severity', severities);
        }

        final response = await query
            .order('reported_at', ascending: false)
            .limit(limit);
        final alerts = (response as List)
            .map((json) => PestAlertModel.fromJson({...json, 'distance_km': null}))
            .toList();

        return Success(alerts);
      } catch (fallbackError) {
        return Failure('Error al cargar alertas cercanas: ${e.toString()}');
      }
    }
  }

  @override
  Future<Result<List<PestAlertModel>>> getMyAlerts({
    int limit = 50,
    int offset = 0,
  }) async {
    return guardedCall(
      errorPrefix: 'Error al cargar mis alertas',
      operation: (uid) async {
        Logger.d('📥 Obteniendo mis alertas');
        final response = await client
            .from(_table)
            .select()
            .eq('user_id', uid)
            .order('reported_at', ascending: false)
            .range(offset, offset + limit - 1);

        final alerts = (response as List)
            .map((json) => PestAlertModel.fromJson(json))
            .toList();
        Logger.i('✅ Cargadas ${alerts.length} alertas propias');
        return alerts;
      },
    );
  }

  @override
  Future<Result<PestAlertModel>> updateAlert(PestAlertModel alert) async {
    return guardedCall(
      errorPrefix: 'Error al actualizar alerta',
      operation: (uid) async {
        Logger.d('📤 Actualizando alerta: ${alert.id}');
        final data = alert.toJson();
        data.remove('id');
        data.remove('user_id');
        data.remove('reported_at');
        data['updated_at'] = DateTime.now().toIso8601String();

        final response = await client
            .from(_table)
            .update(data)
            .eq('id', alert.id)
            .eq('user_id', uid)
            .select()
            .single();

        final updated = PestAlertModel.fromJson(response);
        Logger.i('✅ Alerta actualizada: ${updated.id}');
        return updated;
      },
    );
  }

  @override
  Future<Result<PestAlertModel>> markAsResolved(String id) async {
    return guardedCall(
      errorPrefix: 'Error al marcar alerta como resuelta',
      operation: (uid) async {
        Logger.d('✅ Marcando alerta como resuelta: $id');
        final response = await client
            .from(_table)
            .update({
              'is_resolved': true,
              'resolved_at': DateTime.now().toIso8601String(),
              'status': 'resolved',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', id)
            .eq('user_id', uid)
            .select()
            .single();

        final alert = PestAlertModel.fromJson(response);
        Logger.i('✅ Alerta marcada como resuelta: $id');
        return alert;
      },
    );
  }

  @override
  Future<Result<void>> deleteAlert(String id) async {
    final authFailure = requireAuth<void>();
    if (authFailure != null) return authFailure;

    try {
      Logger.d('🗑️ Eliminando alerta: $id');

      // Obtener alerta para saber qué foto eliminar
      final alertResult = await getAlertById(id);
      if (alertResult is Success<PestAlertModel>) {
        final alert = alertResult.data;
        if (alert.photoUrl != null && alert.photoUrl!.isNotEmpty) {
          final photoPath = StorageService.extractPathFromUrl(alert.photoUrl!, _bucket);
          if (photoPath != null) {
            await _storage.deleteFile(bucket: _bucket, storagePath: photoPath);
          }
        }
      }

      await client
          .from(_table)
          .delete()
          .eq('id', id)
          .eq('user_id', userId!);

      Logger.i('✅ Alerta eliminada: $id');
      return const Success(null);
    } catch (e, stackTrace) {
      Logger.e('❌ Error eliminando alerta $id', error: e, stackTrace: stackTrace);
      return Failure('Error al eliminar alerta: ${e.toString()}');
    }
  }

  @override
  Future<Result<String>> uploadPhoto(Uint8List imageBytes, String fileName) {
    return _storage.uploadImage(
      bucket: _bucket,
      imageBytes: imageBytes,
      fileName: fileName,
    );
  }

  @override
  Future<Result<void>> deletePhoto(String filePath) {
    return _storage.deleteFile(bucket: _bucket, storagePath: filePath);
  }

  @override
  Future<Result<void>> confirmAlert(String alertId) async {
    final authFailure = requireAuth<void>();
    if (authFailure != null) return authFailure;

    try {
      Logger.d('👍 Confirmando alerta: $alertId');

      // Verificar que no sea mi propia alerta
      final alertResult = await getAlertById(alertId);
      if (alertResult is Success<PestAlertModel>) {
        if (alertResult.data.userId == userId) {
          return const Failure('No puedes confirmar tu propia alerta');
        }
      }

      // Crear registro de confirmación
      await client.from(_confirmationsTable).insert({
        'alert_id': alertId,
        'user_id': userId,
        'confirmed_at': DateTime.now().toIso8601String(),
      });

      Logger.i('✅ Alerta confirmada por usuario: $userId');
      return const Success(null);
    } catch (e, stackTrace) {
      Logger.e('❌ Error confirmando alerta $alertId', error: e, stackTrace: stackTrace);
      return Failure('Error al confirmar alerta: ${e.toString()}');
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getAreaStatistics({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    int? daysLimit,
  }) async {
    try {
      Logger.d('📊 Obteniendo estadísticas de área');

      final params = {
        'p_latitude': latitude,
        'p_longitude': longitude,
        'p_radius_km': radiusKm,
        if (daysLimit != null) 'p_days_limit': daysLimit,
      };

      final response = await client.rpc('get_pest_alerts_statistics', params: params);

      Logger.i('✅ Estadísticas obtenidas');
      return Success(response as Map<String, dynamic>);
    } catch (e, stackTrace) {
      Logger.e('❌ Error obteniendo estadísticas', error: e, stackTrace: stackTrace);
      return Failure('Error al cargar estadísticas: ${e.toString()}');
    }
  }
}
