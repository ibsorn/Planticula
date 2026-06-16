import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import 'package:planticula/core/network/result.dart';
import 'package:planticula/core/network/supabase_client.dart';
import 'package:planticula/core/utils/logger.dart';
import 'package:planticula/features/seed_identification/data/datasources/seed_identification_datasource.dart';
import 'package:planticula/features/seed_identification/data/models/seed_identification_model.dart';

class SeedIdentificationDatasourceImpl implements SeedIdentificationDatasource {
  final AppSupabaseClient _client;

  SeedIdentificationDatasourceImpl(this._client);

  static const String _table = 'seed_identifications';
  static const String _bucket = 'seed-id-photos';

  String? get _userId => _client.currentUser?.id;

  String _storagePath(String fileName) {
    if (_userId == null) throw Exception('Usuario no autenticado');
    final ts = DateTime.now().millisecondsSinceEpoch;
    return '$_userId/${ts}_$fileName';
  }

  @override
  Future<Result<List<SeedIdentificationModel>>> getRecords() async {
    try {
      if (_userId == null) return const Failure('Usuario no autenticado');
      Logger.d('📥 Fetching seed identifications');

      final response = await _client
          .from(_table)
          .select()
          .eq('user_id', _userId!)
          .order('created_at', ascending: false);

      final list = (response as List)
          .map((j) => SeedIdentificationModel.fromJson(j))
          .toList();

      Logger.i('✅ Fetched ${list.length} seed identifications');
      return Success(list);
    } catch (e, st) {
      Logger.e('❌ Error fetching seed identifications', error: e, stackTrace: st);
      return Failure('Error al cargar identificaciones: $e');
    }
  }

  @override
  Future<Result<SeedIdentificationModel>> createRecord(SeedIdentificationModel model) async {
    try {
      if (_userId == null) return const Failure('Usuario no autenticado');

      final data = model.toJson()
        ..remove('id')
        ..remove('created_at')
        ..remove('updated_at');
      data['user_id'] = _userId;

      final response = await _client.from(_table).insert(data).select().single();
      return Success(SeedIdentificationModel.fromJson(response));
    } catch (e, st) {
      Logger.e('❌ Error creating seed identification record', error: e, stackTrace: st);
      return Failure('Error al crear identificación: $e');
    }
  }

  @override
  Future<Result<SeedIdentificationModel>> updateRecord(SeedIdentificationModel model) async {
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

      return Success(SeedIdentificationModel.fromJson(response));
    } catch (e, st) {
      Logger.e('❌ Error updating seed identification', error: e, stackTrace: st);
      return Failure('Error al actualizar identificación: $e');
    }
  }

  @override
  Future<Result<void>> deleteRecord(String id) async {
    try {
      if (_userId == null) return const Failure('Usuario no autenticado');

      await _client
          .from(_table)
          .delete()
          .eq('id', id)
          .eq('user_id', _userId!);

      return const Success(null);
    } catch (e, st) {
      Logger.e('❌ Error deleting seed identification $id', error: e, stackTrace: st);
      return Failure('Error al eliminar identificación: $e');
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
      Logger.i('✅ Seed ID image uploaded: $url');
      return Success(url);
    } catch (e, st) {
      Logger.e('❌ Error uploading seed ID image', error: e, stackTrace: st);
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
      Logger.w('Could not delete seed ID image: $filePath');
      return const Success(null);
    }
  }
}
