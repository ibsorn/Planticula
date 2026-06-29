import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import 'package:planticula/core/network/result.dart';
import 'package:planticula/core/network/supabase_client.dart';
import 'package:planticula/core/utils/logger.dart';

/// Shared service for Supabase Storage operations (upload, delete, URL parsing).
///
/// Eliminates duplicated storage logic across datasource implementations.
class StorageService {
  final AppSupabaseClient _client;

  StorageService(this._client);

  String? get _userId => _client.currentUser?.id;

  /// Generates a unique storage path: `<userId>/<timestamp>_<fileName>`.
  ///
  /// Optionally nests under [subfolder] (e.g. a plantId).
  String buildPath({
    required String userId,
    required String fileName,
    String? subfolder,
  }) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final sub = (subfolder != null && subfolder.isNotEmpty) ? '/$subfolder' : '';
    return '$userId$sub/${ts}_$fileName';
  }

  /// Uploads [imageBytes] to [bucket] and returns the public URL.
  Future<Result<String>> uploadImage({
    required String bucket,
    required Uint8List imageBytes,
    required String fileName,
    String? subfolder,
    String contentType = 'image/jpeg',
  }) async {
    try {
      if (_userId == null) {
        return const Failure('Usuario no autenticado');
      }

      final path = buildPath(
        userId: _userId!,
        fileName: fileName,
        subfolder: subfolder,
      );

      await _client.storage.from(bucket).uploadBinary(
            path,
            imageBytes,
            fileOptions: FileOptions(contentType: contentType),
          );

      final url = _client.storage.from(bucket).getPublicUrl(path);
      Logger.i('✅ Image uploaded to $bucket: $url');
      return Success(url);
    } catch (e, st) {
      Logger.e('❌ Error uploading image to $bucket', error: e, stackTrace: st);
      return Failure('Error al subir imagen: $e');
    }
  }

  /// Uploads multiple images and returns their public URLs.
  Future<Result<List<String>>> uploadImages({
    required String bucket,
    required List<Uint8List> imageBytesList,
    String contentType = 'image/jpeg',
  }) async {
    try {
      if (_userId == null) {
        return const Failure('Usuario no autenticado');
      }

      final urls = <String>[];
      for (int i = 0; i < imageBytesList.length; i++) {
        final ts = DateTime.now().millisecondsSinceEpoch;
        final path = '$_userId/${ts}_$i.jpg';

        await _client.storage.from(bucket).uploadBinary(
              path,
              imageBytesList[i],
              fileOptions: FileOptions(contentType: contentType),
            );

        final url = _client.storage.from(bucket).getPublicUrl(path);
        urls.add(url);
      }

      Logger.i('✅ ${urls.length} images uploaded to $bucket');
      return Success(urls);
    } catch (e, st) {
      Logger.e('❌ Error uploading images to $bucket', error: e, stackTrace: st);
      return Failure('Error al subir imágenes: $e');
    }
  }

  /// Deletes a file at [storagePath] from [bucket].
  ///
  /// Returns [Success] even on error to avoid blocking the caller.
  Future<Result<void>> deleteFile({
    required String bucket,
    required String storagePath,
  }) async {
    try {
      await _client.storage.from(bucket).remove([storagePath]);
      Logger.i('✅ Deleted file from $bucket: $storagePath');
      return const Success(null);
    } catch (e, st) {
      Logger.e('❌ Error deleting file from $bucket', error: e, stackTrace: st);
      return const Success(null);
    }
  }

  /// Deletes multiple files from [bucket].
  Future<Result<void>> deleteFiles({
    required String bucket,
    required List<String> storagePaths,
  }) async {
    try {
      await _client.storage.from(bucket).remove(storagePaths);
      return const Success(null);
    } catch (_) {
      return const Success(null);
    }
  }

  /// Extracts the storage path from a Supabase public URL.
  ///
  /// Given a URL like `https://project.supabase.co/storage/v1/object/public/<bucket>/path/file.jpg`,
  /// returns `path/file.jpg`.
  static String? extractPathFromUrl(String url, String bucket) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      final bucketIndex = segments.indexOf(bucket);
      if (bucketIndex >= 0 && bucketIndex < segments.length - 1) {
        return segments.sublist(bucketIndex + 1).join('/');
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
