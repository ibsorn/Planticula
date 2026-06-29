import 'dart:typed_data';
import 'package:planticula/core/network/datasource_mixin.dart';
import 'package:planticula/core/network/result.dart';
import 'package:planticula/core/network/supabase_client.dart';
import 'package:planticula/core/storage/storage_service.dart';
import 'package:planticula/core/utils/logger.dart';
import 'package:planticula/features/seed_identification/data/datasources/seed_identification_datasource.dart';
import 'package:planticula/features/seed_identification/data/models/seed_identification_model.dart';

class SeedIdentificationDatasourceImpl
    with DatasourceMixin
    implements SeedIdentificationDatasource {
  @override
  final AppSupabaseClient client;
  final StorageService _storage;

  SeedIdentificationDatasourceImpl(this.client)
      : _storage = StorageService(client);

  static const String _table = 'seed_identifications';
  static const String _bucket = 'seed-id-photos';

  @override
  Future<Result<List<SeedIdentificationModel>>> getRecords() async {
    return guardedCall(
      errorPrefix: 'Error al cargar identificaciones',
      operation: (uid) async {
        Logger.d('📥 Fetching seed identifications');
        final response = await client
            .from(_table)
            .select()
            .eq('user_id', uid)
            .order('created_at', ascending: false);

        final list = (response as List)
            .map((j) => SeedIdentificationModel.fromJson(j))
            .toList();
        Logger.i('✅ Fetched ${list.length} seed identifications');
        return list;
      },
    );
  }

  @override
  Future<Result<SeedIdentificationModel>> createRecord(SeedIdentificationModel model) async {
    return guardedCall(
      errorPrefix: 'Error al crear identificación',
      operation: (uid) async {
        final data = model.toJson()
          ..remove('id')
          ..remove('created_at')
          ..remove('updated_at');
        data['user_id'] = uid;

        final response = await client.from(_table).insert(data).select().single();
        return SeedIdentificationModel.fromJson(response);
      },
    );
  }

  @override
  Future<Result<SeedIdentificationModel>> updateRecord(SeedIdentificationModel model) async {
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

        return SeedIdentificationModel.fromJson(response);
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
