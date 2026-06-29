import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import 'package:planticula/core/network/result.dart';
import 'package:planticula/core/network/supabase_client.dart';
import 'package:planticula/core/services/soil_analysis_ai_service.dart';
import 'package:planticula/core/utils/logger.dart';
import 'package:planticula/features/soil_analysis/data/datasources/soil_analysis_remote_datasource.dart';
import 'package:planticula/features/soil_analysis/data/models/soil_analysis_model.dart';

/// Implementación de SoilAnalysisRemoteDataSource usando Supabase
class SoilAnalysisRemoteDataSourceImpl implements SoilAnalysisRemoteDataSource {
  final AppSupabaseClient _client;
  final SoilAnalysisAIService _aiService;

  SoilAnalysisRemoteDataSourceImpl(this._client, this._aiService);

  String get _table => 'soil_analyses';
  String get _bucket => 'soil-images';

  String? get _userId => _client.currentUser?.id;

  /// Genera la ruta de almacenamiento para la imagen
  String _getStoragePath(String fileName, {String? plantId}) {
    final userId = _userId;
    if (userId == null) throw Exception('Usuario no autenticado');

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final plantFolder = plantId?.isNotEmpty == true ? '/$plantId' : '';
    return '$userId$plantFolder/${timestamp}_$fileName';
  }

  @override
  Future<Result<List<SoilAnalysisModel>>> getAnalyses() async {
    try {
      Logger.d('📥 Fetching soil analyses for user: $_userId');

      if (_userId == null) {
        return const Failure('Usuario no autenticado');
      }

      final response = await _client
          .from(_table)
          .select()
          .eq('user_id', _userId!)
          .order('created_at', ascending: false);

      final analyses = (response as List)
          .map((json) => SoilAnalysisModel.fromJson(json))
          .toList();

      Logger.i('✅ Fetched ${analyses.length} soil analyses');
      return Success(analyses);
    } catch (e, stackTrace) {
      Logger.e('❌ Error fetching soil analyses',
          error: e, stackTrace: stackTrace);
      return Failure('Error al cargar análisis: ${e.toString()}');
    }
  }

  @override
  Future<Result<SoilAnalysisModel>> getAnalysisById(String id) async {
    try {
      Logger.d('📥 Fetching soil analysis: $id');

      if (_userId == null) {
        return const Failure('Usuario no autenticado');
      }

      final response = await _client
          .from(_table)
          .select()
          .eq('id', id)
          .eq('user_id', _userId!)
          .single();

      final analysis = SoilAnalysisModel.fromJson(response);
      Logger.i('✅ Fetched soil analysis: ${analysis.id}');
      return Success(analysis);
    } catch (e, stackTrace) {
      Logger.e('❌ Error fetching soil analysis $id',
          error: e, stackTrace: stackTrace);
      return Failure('Error al cargar análisis: ${e.toString()}');
    }
  }

  @override
  Future<Result<List<SoilAnalysisModel>>> getAnalysesByPlant(
      String plantId) async {
    try {
      Logger.d('📥 Fetching soil analyses for plant: $plantId');

      if (_userId == null) {
        return const Failure('Usuario no autenticado');
      }

      final response = await _client
          .from(_table)
          .select()
          .eq('user_id', _userId!)
          .eq('plant_id', plantId)
          .order('created_at', ascending: false);

      final analyses = (response as List)
          .map((json) => SoilAnalysisModel.fromJson(json))
          .toList();

      Logger.i('✅ Fetched ${analyses.length} analyses for plant $plantId');
      return Success(analyses);
    } catch (e, stackTrace) {
      Logger.e('❌ Error fetching analyses for plant $plantId',
          error: e, stackTrace: stackTrace);
      return Failure('Error al cargar análisis: ${e.toString()}');
    }
  }

  @override
  Future<Result<SoilAnalysisModel>> createAnalysis(
      SoilAnalysisModel analysis) async {
    try {
      Logger.d('📤 Creating soil analysis record');

      if (_userId == null) {
        return const Failure('Usuario no autenticado');
      }

      // Preparar datos para inserción
      final data = analysis.toJson();
      data['user_id'] = _userId;

      // Remover campos que no deben enviarse
      data.remove('id');
      data.remove('created_at');
      data.remove('updated_at');

      final response = await _client
          .from(_table)
          .insert(data)
          .select()
          .single();

      final createdAnalysis = SoilAnalysisModel.fromJson(response);
      Logger.i(
          '✅ Created soil analysis: ${createdAnalysis.id} (${createdAnalysis.imageUrl})');
      return Success(createdAnalysis);
    } catch (e, stackTrace) {
      Logger.e('❌ Error creating soil analysis', error: e, stackTrace: stackTrace);
      return Failure('Error al crear análisis: ${e.toString()}');
    }
  }

  @override
  Future<Result<SoilAnalysisModel>> updateAnalysis(
      SoilAnalysisModel analysis) async {
    try {
      Logger.d('📤 Updating soil analysis: ${analysis.id}');

      if (_userId == null) {
        return const Failure('Usuario no autenticado');
      }

      final data = analysis.toJson();
      data.remove('id');
      data.remove('user_id');
      data.remove('created_at');

      final response = await _client
          .from(_table)
          .update(data)
          .eq('id', analysis.id)
          .eq('user_id', _userId!)
          .select()
          .single();

      final updatedAnalysis = SoilAnalysisModel.fromJson(response);
      Logger.i('✅ Updated soil analysis: ${updatedAnalysis.id}');
      return Success(updatedAnalysis);
    } catch (e, stackTrace) {
      Logger.e('❌ Error updating soil analysis ${analysis.id}',
          error: e, stackTrace: stackTrace);
      return Failure('Error al actualizar análisis: ${e.toString()}');
    }
  }

  @override
  Future<Result<void>> deleteAnalysis(String id) async {
    try {
      Logger.d('🗑️ Deleting soil analysis: $id');

      if (_userId == null) {
        return const Failure('Usuario no autenticado');
      }

      // Primero obtener el análisis para saber qué imagen eliminar
      final analysisResult = await getAnalysisById(id);
      if (analysisResult is Failure<SoilAnalysisModel>) {
        return Failure(analysisResult.message,
            code: analysisResult.code, error: analysisResult.error);
      }

      final analysis = (analysisResult as Success<SoilAnalysisModel>).data;

      // Eliminar imagen de Storage
      if (analysis.imageUrl.isNotEmpty) {
        final imagePath = _extractPathFromUrl(analysis.imageUrl);
        if (imagePath != null) {
          await deleteImage(imagePath);
        }
      }

      // Eliminar registro de la tabla
      await _client
          .from(_table)
          .delete()
          .eq('id', id)
          .eq('user_id', _userId!);

      Logger.i('✅ Deleted soil analysis: $id');
      return const Success(null);
    } catch (e, stackTrace) {
      Logger.e('❌ Error deleting soil analysis $id',
          error: e, stackTrace: stackTrace);
      return Failure('Error al eliminar análisis: ${e.toString()}');
    }
  }

  @override
  Future<Result<String>> uploadImage(
    Uint8List imageBytes,
    String fileName, {
    String? plantId,
  }) async {
    try {
      Logger.d('📤 Uploading image to Storage: $fileName');

      if (_userId == null) {
        return const Failure('Usuario no autenticado');
      }

      final path = _getStoragePath(fileName, plantId: plantId);

      // Subir imagen
      await _client.storage.from(_bucket).uploadBinary(
            path,
            imageBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
            ),
          );

      // Obtener URL pública
      final imageUrl = _client.storage.from(_bucket).getPublicUrl(path);

      Logger.i('✅ Image uploaded: $imageUrl');
      return Success(imageUrl);
    } catch (e, stackTrace) {
      Logger.e('❌ Error uploading image', error: e, stackTrace: stackTrace);
      return Failure('Error al subir imagen: ${e.toString()}');
    }
  }

  @override
  Future<Result<void>> deleteImage(String filePath) async {
    try {
      Logger.d('🗑️ Deleting image from Storage: $filePath');

      await _client.storage.from(_bucket).remove([filePath]);

      Logger.i('✅ Deleted image: $filePath');
      return const Success(null);
    } catch (e, stackTrace) {
      Logger.e('❌ Error deleting image $filePath',
          error: e, stackTrace: stackTrace);
      return Failure('Error al eliminar imagen: ${e.toString()}');
    }
  }

  @override
  Future<Result<SoilAnalysisModel>> analyzeImage(
    String analysisId,
    Uint8List imageBytes, {
    SoilAnalysisProgress? onProgress,
  }) async {
    try {
      Logger.d('🔬 Starting AI analysis for: $analysisId');

      if (_userId == null) {
        return const Failure('Usuario no autenticado');
      }

      // Get the analysis to confirm it exists
      final analysisResult = await getAnalysisById(analysisId);
      if (analysisResult is Failure<SoilAnalysisModel>) {
        return analysisResult;
      }

      // Update status to processing
      await _client
          .from(_table)
          .update({'status': 'processing'})
          .eq('id', analysisId)
          .eq('user_id', _userId!);

      // Call the AI service — map its stage progress into the 0.3..0.9 band,
      // same range used by Plant Identification and Plant Disease so the
      // progress bar is always determinate and never goes backwards.
      final aiResult = await _aiService.analyzeFromBytes(
        imageBytes,
        onProgress: (stage, message, progress) =>
            onProgress?.call(0.3 + 0.6 * progress, message),
      );

      if (aiResult.isSuccessful) {
        // Update the analysis with AI results
        await _client.from(_table).update({
          'status': 'completed',
          'analyzed_at': DateTime.now().toIso8601String(),
          'soil_type': aiResult.soilType?.name,
          'ph_level': aiResult.phLevel,
          'moisture_level': aiResult.moistureLevel?.name,
          'drainage_quality': aiResult.drainageQuality?.name,
          'organic_matter': aiResult.organicMatter?.name,
          'recommendations': aiResult.recommendations,
          'analysis_notes': aiResult.analysisNotes,
        }).eq('id', analysisId).eq('user_id', _userId!);

        Logger.i('✅ AI analysis completed for: $analysisId');
      } else {
        // Mark as error with AI error message
        await _client
            .from(_table)
            .update({
              'status': 'error',
              'analysis_notes': aiResult.errorMessage ?? 'Error en análisis IA',
            })
            .eq('id', analysisId)
            .eq('user_id', _userId!);

        return Failure(aiResult.errorMessage ?? 'Error en análisis IA');
      }

      // Return the updated analysis
      return await getAnalysisById(analysisId);
    } catch (e, stackTrace) {
      Logger.e('❌ Error in AI analysis for $analysisId',
          error: e, stackTrace: stackTrace);

      // Mark as error
      await _client
          .from(_table)
          .update({
            'status': 'error',
            'analysis_notes': 'Error en análisis: ${e.toString()}',
          })
          .eq('id', analysisId)
          .eq('user_id', _userId!);

      return Failure('Error en análisis: ${e.toString()}');
    }
  }

  /// Extrae el path del bucket desde una URL pública
  String? _extractPathFromUrl(String url) {
    try {
      // La URL tiene formato: https://project.supabase.co/storage/v1/object/public/soil-images/path
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      // Buscar el índice de 'soil-images' y tomar todo después
      final bucketIndex = pathSegments.indexOf(_bucket);
      if (bucketIndex >= 0 && bucketIndex < pathSegments.length - 1) {
        return pathSegments.sublist(bucketIndex + 1).join('/');
      }
      return null;
    } catch (e) {
      Logger.w('Could not extract path from URL: $url');
      return null;
    }
  }
}
