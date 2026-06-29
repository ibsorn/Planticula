import 'dart:typed_data';
import 'package:planticula/core/network/datasource_mixin.dart';
import 'package:planticula/core/network/result.dart';
import 'package:planticula/core/network/supabase_client.dart';
import 'package:planticula/core/storage/storage_service.dart';
import 'package:planticula/core/utils/logger.dart';
import 'package:planticula/features/plant_identification/data/datasources/plant_identification_datasource.dart';
import 'package:planticula/features/plant_identification/data/models/plant_identification_model.dart';

class PlantIdentificationDatasourceImpl
    with DatasourceMixin
    implements PlantIdentificationDatasource {
  @override
  final AppSupabaseClient client;
  final StorageService _storage;

  PlantIdentificationDatasourceImpl(this.client)
      : _storage = StorageService(client);

  static const String _table = 'plant_identifications';
  static const String _bucket = 'plant-id-photos';

  @override
  Future<Result<List<PlantIdentificationModel>>> getRecords() async {
    return guardedCall(
      errorPrefix: 'Error al cargar identificaciones',
      operation: (uid) async {
        Logger.d('📥 Fetching plant identifications');
        final response = await client
            .from(_table)
            .select()
            .eq('user_id', uid)
            .order('created_at', ascending: false);

        final list = (response as List)
            .map((j) => PlantIdentificationModel.fromJson(j))
            .toList();
        Logger.i('✅ Fetched ${list.length} plant identifications');
        return list;
      },
    );
  }

  @override
  Future<Result<PlantIdentificationModel>> createRecord(PlantIdentificationModel model) async {
    return guardedCall(
      errorPrefix: 'Error al crear identificación',
      operation: (uid) async {
        final data = model.toJson()
          ..remove('id')
          ..remove('created_at')
          ..remove('updated_at');
        data['user_id'] = uid;

        final response = await client.from(_table).insert(data).select().single();
        return PlantIdentificationModel.fromJson(response);
      },
    );
  }

  @override
  Future<Result<PlantIdentificationModel>> updateRecord(PlantIdentificationModel model) async {
    return guardedCall(
      errorPrefix: 'Error al actualizar identificación',
      operation: (uid) async {
        final data = model.toJson()
          ..remove('id')
          ..remove('user_id')
          ..remove('created_at');

        final response = await client
            .from(_table)
            .update(data)
            .eq('id', model.id)
            .eq('user_id', uid)
            .select()
            .single();

        return PlantIdentificationModel.fromJson(response);
      },
    );
  }

  @override
  Future<Result<void>> deleteRecord(String id) async {
    return guardedCall(
      errorPrefix: 'Error al eliminar identificación',
      operation: (uid) async {
        await client
            .from(_table)
            .delete()
            .eq('id', id)
            .eq('user_id', uid);
        return null;
      },
    );
  }

  @override
  Future<Result<String>> uploadImage(Uint8List imageBytes, String fileName) {
    return _storage.uploadImage(
      bucket: _bucket,
      imageBytes: imageBytes,
      fileName: fileName,
    );
  }

  @override
  Future<Result<void>> deleteImage(String filePath) {
    final storagePath = StorageService.extractPathFromUrl(filePath, _bucket);
    if (storagePath == null) return Future.value(const Success(null));
    return _storage.deleteFile(bucket: _bucket, storagePath: storagePath);
  }
}
