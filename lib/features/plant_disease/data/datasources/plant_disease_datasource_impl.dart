import 'dart:typed_data';
import 'package:planticula/core/network/datasource_mixin.dart';
import 'package:planticula/core/network/result.dart';
import 'package:planticula/core/network/supabase_client.dart';
import 'package:planticula/core/storage/storage_service.dart';
import 'package:planticula/core/utils/logger.dart';
import 'package:planticula/features/plant_disease/data/datasources/plant_disease_datasource.dart';
import 'package:planticula/features/plant_disease/data/models/plant_disease_diagnosis_model.dart';

class PlantDiseaseDatasourceImpl
    with DatasourceMixin
    implements PlantDiseaseDatasource {
  @override
  final AppSupabaseClient client;
  final StorageService _storage;

  PlantDiseaseDatasourceImpl(this.client)
      : _storage = StorageService(client);

  static const String _table = 'plant_disease_diagnoses';
  static const String _bucket = 'disease-photos';

  @override
  Future<Result<List<PlantDiseaseDiagnosisModel>>> getDiagnoses() async {
    return guardedCall(
      errorPrefix: 'Error al cargar diagnósticos',
      operation: (uid) async {
        Logger.d('📥 Fetching disease diagnoses');
        final response = await client
            .from(_table)
            .select()
            .eq('user_id', uid)
            .order('created_at', ascending: false);

        final list = (response as List)
            .map((j) => PlantDiseaseDiagnosisModel.fromJson(j))
            .toList();
        Logger.i('✅ Fetched ${list.length} diagnoses');
        return list;
      },
    );
  }

  @override
  Future<Result<PlantDiseaseDiagnosisModel>> createDiagnosisRecord(
      PlantDiseaseDiagnosisModel model) async {
    return guardedCall(
      errorPrefix: 'Error al crear diagnóstico',
      operation: (uid) async {
        final data = model.toJson()
          ..remove('id')
          ..remove('created_at')
          ..remove('updated_at');
        data['user_id'] = uid;

        final response =
            await client.from(_table).insert(data).select().single();
        return PlantDiseaseDiagnosisModel.fromJson(response);
      },
    );
  }

  @override
  Future<Result<PlantDiseaseDiagnosisModel>> updateDiagnosis(
      PlantDiseaseDiagnosisModel model) async {
    return guardedCall(
      errorPrefix: 'Error al actualizar diagnóstico',
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

        return PlantDiseaseDiagnosisModel.fromJson(response);
      },
    );
  }

  @override
  Future<Result<void>> deleteDiagnosis(String id) async {
    return guardedCall(
      errorPrefix: 'Error al eliminar diagnóstico',
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
