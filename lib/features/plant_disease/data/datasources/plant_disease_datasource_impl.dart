import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import 'package:planticula/core/network/result.dart';
import 'package:planticula/core/network/supabase_client.dart';
import 'package:planticula/core/utils/logger.dart';
import 'package:planticula/features/plant_disease/data/datasources/plant_disease_datasource.dart';
import 'package:planticula/features/plant_disease/data/models/plant_disease_diagnosis_model.dart';

class PlantDiseaseDatasourceImpl implements PlantDiseaseDatasource {
  final AppSupabaseClient _client;

  PlantDiseaseDatasourceImpl(this._client);

  static const String _table = 'plant_disease_diagnoses';
  static const String _bucket = 'disease-photos';

  String? get _userId => _client.currentUser?.id;

  String _storagePath(String fileName) {
    if (_userId == null) throw Exception('Usuario no autenticado');
    final ts = DateTime.now().millisecondsSinceEpoch;
    return '$_userId/${ts}_$fileName';
  }

  @override
  Future<Result<List<PlantDiseaseDiagnosisModel>>> getDiagnoses() async {
    try {
      if (_userId == null) return const Failure('Usuario no autenticado');
      Logger.d('📥 Fetching disease diagnoses');

      final response = await _client
          .from(_table)
          .select()
          .eq('user_id', _userId!)
          .order('created_at', ascending: false);

      final list = (response as List)
          .map((j) => PlantDiseaseDiagnosisModel.fromJson(j))
          .toList();

      Logger.i('✅ Fetched ${list.length} diagnoses');
      return Success(list);
    } catch (e, st) {
      Logger.e('❌ Error fetching diagnoses', error: e, stackTrace: st);
      return Failure('Error al cargar diagnósticos: $e');
    }
  }

  @override
  Future<Result<PlantDiseaseDiagnosisModel>> createDiagnosisRecord(
      PlantDiseaseDiagnosisModel model) async {
    try {
      if (_userId == null) return const Failure('Usuario no autenticado');

      final data = model.toJson()
        ..remove('id')
        ..remove('created_at')
        ..remove('updated_at');
      data['user_id'] = _userId;

      final response =
          await _client.from(_table).insert(data).select().single();

      return Success(PlantDiseaseDiagnosisModel.fromJson(response));
    } catch (e, st) {
      Logger.e('❌ Error creating diagnosis record', error: e, stackTrace: st);
      return Failure('Error al crear diagnóstico: $e');
    }
  }

  @override
  Future<Result<PlantDiseaseDiagnosisModel>> updateDiagnosis(
      PlantDiseaseDiagnosisModel model) async {
    try {
      if (_userId == null) return const Failure('Usuario no autenticado');

      final data = model.toJson()
        ..remove('id')
        ..remove('user_id')
        ..remove('created_at');

      final response = await _client
          .from(_table)
          .update(data)
          .eq('id', model.id)
          .eq('user_id', _userId!)
          .select()
          .single();

      return Success(PlantDiseaseDiagnosisModel.fromJson(response));
    } catch (e, st) {
      Logger.e('❌ Error updating diagnosis', error: e, stackTrace: st);
      return Failure('Error al actualizar diagnóstico: $e');
    }
  }

  @override
  Future<Result<void>> deleteDiagnosis(String id) async {
    try {
      if (_userId == null) return const Failure('Usuario no autenticado');

      await _client
          .from(_table)
          .delete()
          .eq('id', id)
          .eq('user_id', _userId!);

      return const Success(null);
    } catch (e, st) {
      Logger.e('❌ Error deleting diagnosis $id', error: e, stackTrace: st);
      return Failure('Error al eliminar diagnóstico: $e');
    }
  }

  @override
  Future<Result<String>> uploadImage(Uint8List imageBytes, String fileName) async {
    try {
      if (_userId == null) return const Failure('Usuario no autenticado');

      final path = _storagePath(fileName);
      await _client.storage.from(_bucket).uploadBinary(
            path,
            imageBytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      final url = _client.storage.from(_bucket).getPublicUrl(path);
      Logger.i('✅ Disease image uploaded: $url');
      return Success(url);
    } catch (e, st) {
      Logger.e('❌ Error uploading image', error: e, stackTrace: st);
      return Failure('Error al subir imagen: $e');
    }
  }

  @override
  Future<Result<void>> deleteImage(String filePath) async {
    try {
      final uri = Uri.tryParse(filePath);
      if (uri == null) return const Success(null);

      final segments = uri.pathSegments;
      final bucketIndex = segments.indexOf(_bucket);
      if (bucketIndex < 0 || bucketIndex >= segments.length - 1) {
        return const Success(null);
      }
      final storagePath = segments.sublist(bucketIndex + 1).join('/');

      await _client.storage.from(_bucket).remove([storagePath]);
      return const Success(null);
    } catch (e) {
      Logger.w('Could not delete image: $filePath');
      return const Success(null);
    }
  }
}
