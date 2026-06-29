import 'dart:typed_data';
import 'package:planticula/core/network/datasource_mixin.dart';
import 'package:planticula/core/network/result.dart';
import 'package:planticula/core/network/supabase_client.dart';
import 'package:planticula/core/services/soil_analysis_ai_service.dart';
import 'package:planticula/core/storage/storage_service.dart';
import 'package:planticula/core/utils/logger.dart';
import 'package:planticula/features/soil_analysis/data/datasources/soil_analysis_remote_datasource.dart';
import 'package:planticula/features/soil_analysis/data/models/soil_analysis_model.dart';

/// Implementación de SoilAnalysisRemoteDataSource usando Supabase
class SoilAnalysisRemoteDataSourceImpl
    with DatasourceMixin
    implements SoilAnalysisRemoteDataSource {
  @override
  final AppSupabaseClient client;
  final SoilAnalysisAIService _aiService;
  final StorageService _storage;

  SoilAnalysisRemoteDataSourceImpl(this.client, this._aiService)
      : _storage = StorageService(client);

  String get _table => 'soil_analyses';
  String get _bucket => 'soil-images';

  @override
  Future<Result<List<SoilAnalysisModel>>> getAnalyses() async {
    return guardedCall(
      errorPrefix: 'Error al cargar análisis',
      operation: (uid) async {
        Logger.d('📥 Fetching soil analyses for user: $uid');
        final response = await client
            .from(_table)
            .select()
            .eq('user_id', uid)
            .order('created_at', ascending: false);

        final analyses = (response as List)
            .map((json) => SoilAnalysisModel.fromJson(json))
            .toList();
        Logger.i('✅ Fetched ${analyses.length} soil analyses');
        return analyses;
      },
    );
  }

  @override
  Future<Result<SoilAnalysisModel>> getAnalysisById(String id) async {
    return guardedCall(
      errorPrefix: 'Error al cargar análisis',
      operation: (uid) async {
        Logger.d('📥 Fetching soil analysis: $id');
        final response = await client
            .from(_table)
            .select()
            .eq('id', id)
            .eq('user_id', uid)
            .single();

        final analysis = SoilAnalysisModel.fromJson(response);
        Logger.i('✅ Fetched soil analysis: ${analysis.id}');
        return analysis;
      },
    );
  }

  @override
  Future<Result<List<SoilAnalysisModel>>> getAnalysesByPlant(
      String plantId) async {
    return guardedCall(
      errorPrefix: 'Error al cargar análisis',
      operation: (uid) async {
        Logger.d('📥 Fetching soil analyses for plant: $plantId');
        final response = await client
            .from(_table)
            .select()
            .eq('user_id', uid)
            .eq('plant_id', plantId)
            .order('created_at', ascending: false);

        final analyses = (response as List)
            .map((json) => SoilAnalysisModel.fromJson(json))
            .toList();
        Logger.i('✅ Fetched ${analyses.length} analyses for plant $plantId');
        return analyses;
      },
    );
  }

  @override
  Future<Result<SoilAnalysisModel>> createAnalysis(
      SoilAnalysisModel analysis) async {
    return guardedCall(
      errorPrefix: 'Error al crear análisis',
      operation: (uid) async {
        Logger.d('📤 Creating soil analysis record');
        final data = analysis.toJson();
        data['user_id'] = uid;
        data.remove('id');
        data.remove('created_at');
        data.remove('updated_at');

        final response = await client
            .from(_table)
            .insert(data)
            .select()
            .single();

        final createdAnalysis = SoilAnalysisModel.fromJson(response);
        Logger.i(
            '✅ Created soil analysis: ${createdAnalysis.id} (${createdAnalysis.imageUrl})');
        return createdAnalysis;
      },
    );
  }

  @override
  Future<Result<SoilAnalysisModel>> updateAnalysis(
      SoilAnalysisModel analysis) async {
    return guardedCall(
      errorPrefix: 'Error al actualizar análisis',
      operation: (uid) async {
        Logger.d('📤 Updating soil analysis: ${analysis.id}');
        final data = analysis.toJson();
        data.remove('id');
        data.remove('user_id');
        data.remove('created_at');

        final response = await client
            .from(_table)
            .update(data)
            .eq('id', analysis.id)
            .eq('user_id', uid)
            .select()
            .single();

        final updatedAnalysis = SoilAnalysisModel.fromJson(response);
        Logger.i('✅ Updated soil analysis: ${updatedAnalysis.id}');
        return updatedAnalysis;
      },
    );
  }

  @override
  Future<Result<void>> deleteAnalysis(String id) async {
    final authFailure = requireAuth<void>();
    if (authFailure != null) return authFailure;

    try {
      Logger.d('🗑️ Deleting soil analysis: $id');

      // Primero obtener el análisis para saber qué imagen eliminar
      final analysisResult = await getAnalysisById(id);
      if (analysisResult is Failure<SoilAnalysisModel>) {
        return Failure(analysisResult.message,
            code: analysisResult.code, error: analysisResult.error);
      }

      final analysis = (analysisResult as Success<SoilAnalysisModel>).data;

      // Eliminar imagen de Storage
      if (analysis.imageUrl.isNotEmpty) {
        final imagePath = StorageService.extractPathFromUrl(analysis.imageUrl, _bucket);
        if (imagePath != null) {
          await _storage.deleteFile(bucket: _bucket, storagePath: imagePath);
        }
      }

      // Eliminar registro de la tabla
      await client
          .from(_table)
          .delete()
          .eq('id', id)
          .eq('user_id', userId!);

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
  }) {
    return _storage.uploadImage(
      bucket: _bucket,
      imageBytes: imageBytes,
      fileName: fileName,
      subfolder: plantId,
    );
  }

  @override
  Future<Result<void>> deleteImage(String filePath) {
    return _storage.deleteFile(bucket: _bucket, storagePath: filePath);
  }

  @override
  Future<Result<SoilAnalysisModel>> analyzeImage(
    String analysisId,
    Uint8List imageBytes, {
    SoilAnalysisProgress? onProgress,
  }) async {
    final authFailure = requireAuth<SoilAnalysisModel>();
    if (authFailure != null) return authFailure;

    try {
      Logger.d('🔬 Starting AI analysis for: $analysisId');

      // Get the analysis to confirm it exists
      final analysisResult = await getAnalysisById(analysisId);
      if (analysisResult is Failure<SoilAnalysisModel>) {
        return analysisResult;
      }

      // Update status to processing
      await client
          .from(_table)
          .update({'status': 'processing'})
          .eq('id', analysisId)
          .eq('user_id', userId!);

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
        await client.from(_table).update({
          'status': 'completed',
          'analyzed_at': DateTime.now().toIso8601String(),
          'soil_type': aiResult.soilType?.name,
          'ph_level': aiResult.phLevel,
          'moisture_level': aiResult.moistureLevel?.name,
          'drainage_quality': aiResult.drainageQuality?.name,
          'organic_matter': aiResult.organicMatter?.name,
          'recommendations': aiResult.recommendations,
          'analysis_notes': aiResult.analysisNotes,
        }).eq('id', analysisId).eq('user_id', userId!);

        Logger.i('✅ AI analysis completed for: $analysisId');
      } else {
        // Mark as error with AI error message
        await client
            .from(_table)
            .update({
              'status': 'error',
              'analysis_notes': aiResult.errorMessage ?? 'Error en análisis IA',
            })
            .eq('id', analysisId)
            .eq('user_id', userId!);

        return Failure(aiResult.errorMessage ?? 'Error en análisis IA');
      }

      // Return the updated analysis
      return await getAnalysisById(analysisId);
    } catch (e, stackTrace) {
      Logger.e('❌ Error in AI analysis for $analysisId',
          error: e, stackTrace: stackTrace);

      // Mark as error
      await client
          .from(_table)
          .update({
            'status': 'error',
            'analysis_notes': 'Error en análisis: ${e.toString()}',
          })
          .eq('id', analysisId)
          .eq('user_id', userId!);

      return Failure('Error en análisis: ${e.toString()}');
    }
  }
}
