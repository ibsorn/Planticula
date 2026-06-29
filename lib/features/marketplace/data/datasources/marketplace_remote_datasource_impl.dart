import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import 'package:planticula/core/network/result.dart';
import 'package:planticula/core/network/supabase_client.dart';
import 'package:planticula/core/utils/logger.dart';
import 'package:planticula/features/marketplace/data/datasources/marketplace_remote_datasource.dart';
import 'package:planticula/features/marketplace/data/models/marketplace_listing_model.dart';

/// Implementación de MarketplaceRemoteDataSource usando Supabase
class MarketplaceRemoteDataSourceImpl implements MarketplaceRemoteDataSource {
  final AppSupabaseClient _client;

  MarketplaceRemoteDataSourceImpl(this._client);

  String get _table => 'marketplace_listings';
  String get _bucket => 'marketplace-photos';
  String get _favoritesTable => 'marketplace_favorites';

  String? get _userId => _client.currentUser?.id;

  @override
  Future<Result<MarketplaceListingModel>> createListing(CreateListingRequest request) async {
    try {
      Logger.d('📤 Creando anuncio: ${request.title}');

      if (_userId == null) {
        return const Failure('Usuario no autenticado');
      }

      // Obtener nombre del perfil del usuario
      String? sellerName;
      try {
        final profile = await _client
            .from('profiles')
            .select('username, full_name')
            .eq('id', _userId!)
            .single();
        sellerName = profile['username'] ?? profile['full_name'];
      } catch (e) {
        Logger.d('Profile not found for user $_userId, proceeding without name: $e');
        sellerName = null;
      }

      final data = request.toJson(_userId!, sellerName);

      final response = await _client
          .from(_table)
          .insert(data)
          .select()
          .single();

      final listing = MarketplaceListingModel.fromJson(response);
      Logger.i('✅ Anuncio creado: ${listing.id}');
      return Success(listing);
    } catch (e, stackTrace) {
      Logger.e('❌ Error creando anuncio', error: e, stackTrace: stackTrace);
      return Failure('Error al crear anuncio: ${e.toString()}');
    }
  }

  @override
  Future<Result<MarketplaceListingModel>> getListingById(String id) async {
    try {
      Logger.d('📥 Obteniendo anuncio: $id');

      final response = await _client
          .from(_table)
          .select('''
            *,
            is_favorited:marketplace_favorites!left(id)
          ''')
          .eq('id', id)
          .single();

      // Verificar si es favorito
      final isFav = response['is_favorited'] != null &&
          (response['is_favorited'] as List).isNotEmpty;

      final listing = MarketplaceListingModel.fromJson({
        ...response,
        'is_favorited': isFav,
      });

      // Incrementar vistas en background (no esperamos respuesta)
      _incrementViewCountAsync(id);

      return Success(listing);
    } catch (e, stackTrace) {
      Logger.e('❌ Error obteniendo anuncio $id', error: e, stackTrace: stackTrace);
      return Failure('Error al cargar anuncio: ${e.toString()}');
    }
  }

  @override
  Future<Result<List<MarketplaceListingModel>>> getNearbyListings({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    List<String>? categories,
    List<String>? listingTypes,
    double? maxPrice,
    String? searchQuery,
    bool includeSold = false,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      Logger.d('📍 Buscando anuncios cercanos en ${radiusKm}km');

      final params = {
        'p_latitude': latitude,
        'p_longitude': longitude,
        'p_radius_km': radiusKm,
        'p_limit': limit,
        'p_offset': offset,
        if (categories != null && categories.isNotEmpty) 'p_categories': categories,
        if (listingTypes != null && listingTypes.isNotEmpty) 'p_listing_types': listingTypes,
        if (maxPrice != null) 'p_max_price': maxPrice,
        if (searchQuery != null && searchQuery.isNotEmpty) 'p_search': searchQuery,
        'p_include_sold': includeSold,
      };

      final response = await _client.rpc('get_nearby_listings', params: params);

      final listings = (response as List)
          .map((json) => MarketplaceListingModel.fromJson(json))
          .toList();

      Logger.i('✅ Encontrados ${listings.length} anuncios cercanos');
      return Success(listings);
    } catch (e, stackTrace) {
      Logger.e('❌ Error buscando anuncios cercanos', error: e, stackTrace: stackTrace);

      // Fallback simple
      try {
        var query = _client
            .from(_table)
            .select()
            .eq('status', 'active');

        if (categories != null && categories.isNotEmpty) {
          query = query.inFilter('category', categories);
        }
        if (listingTypes != null && listingTypes.isNotEmpty) {
          query = query.inFilter('listing_type', listingTypes);
        }
        if (maxPrice != null) {
          query = query.lte('price', maxPrice);
        }

        final response = await query
            .order('created_at', ascending: false)
            .limit(limit);
        final listings = (response as List)
            .map((json) => MarketplaceListingModel.fromJson({...json, 'distance_km': null}))
            .toList();

        return Success(listings);
      } catch (fallbackError) {
        return Failure('Error al cargar anuncios: ${e.toString()}');
      }
    }
  }

  @override
  Future<Result<List<MarketplaceListingModel>>> getMyListings({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      Logger.d('📥 Obteniendo mis anuncios');

      if (_userId == null) {
        return const Failure('Usuario no autenticado');
      }

      final response = await _client
          .from(_table)
          .select()
          .eq('seller_id', _userId!)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final listings = (response as List)
          .map((json) => MarketplaceListingModel.fromJson(json))
          .toList();

      Logger.i('✅ Cargados ${listings.length} anuncios propios');
      return Success(listings);
    } catch (e, stackTrace) {
      Logger.e('❌ Error obteniendo mis anuncios', error: e, stackTrace: stackTrace);
      return Failure('Error al cargar mis anuncios: ${e.toString()}');
    }
  }

  @override
  Future<Result<List<MarketplaceListingModel>>> getFavoriteListings() async {
    try {
      Logger.d('📥 Obteniendo favoritos');

      if (_userId == null) {
        return const Failure('Usuario no autenticado');
      }

      final response = await _client
          .from(_favoritesTable)
          .select('listing:marketplace_listings(*)')
          .eq('user_id', _userId!)
          .order('created_at', ascending: false);

      final listings = (response as List)
          .map((json) => MarketplaceListingModel.fromJson({
                ...json['listing'],
                'is_favorited': true,
              }))
          .toList();

      return Success(listings);
    } catch (e, stackTrace) {
      Logger.e('❌ Error obteniendo favoritos', error: e, stackTrace: stackTrace);
      return Failure('Error al cargar favoritos: ${e.toString()}');
    }
  }

  @override
  Future<Result<MarketplaceListingModel>> updateListing(MarketplaceListingModel listing) async {
    try {
      Logger.d('📤 Actualizando anuncio: ${listing.id}');

      if (_userId == null) {
        return const Failure('Usuario no autenticado');
      }

      final data = listing.toJson();
      data.remove('id');
      data.remove('seller_id');
      data.remove('created_at');
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from(_table)
          .update(data)
          .eq('id', listing.id)
          .eq('seller_id', _userId!)
          .select()
          .single();

      final updated = MarketplaceListingModel.fromJson(response);
      Logger.i('✅ Anuncio actualizado');
      return Success(updated);
    } catch (e, stackTrace) {
      Logger.e('❌ Error actualizando anuncio', error: e, stackTrace: stackTrace);
      return Failure('Error al actualizar anuncio: ${e.toString()}');
    }
  }

  @override
  Future<Result<MarketplaceListingModel>> updateListingStatus(String id, String status) async {
    try {
      Logger.d('📤 Cambiando estado de $id a $status');

      if (_userId == null) {
        return const Failure('Usuario no autenticado');
      }

      final response = await _client
          .from(_table)
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .eq('seller_id', _userId!)
          .select()
          .single();

      final updated = MarketplaceListingModel.fromJson(response);
      Logger.i('✅ Estado actualizado a $status');
      return Success(updated);
    } catch (e, stackTrace) {
      Logger.e('❌ Error cambiando estado', error: e, stackTrace: stackTrace);
      return Failure('Error al actualizar estado: ${e.toString()}');
    }
  }

  @override
  Future<Result<void>> deleteListing(String id) async {
    try {
      Logger.d('🗑️ Eliminando anuncio: $id');

      if (_userId == null) {
        return const Failure('Usuario no autenticado');
      }

      // Obtener fotos para eliminar después
      final listingResult = await getListingById(id);
      List<String> photoUrls = [];
      if (listingResult is Success<MarketplaceListingModel>) {
        photoUrls = listingResult.data.photoUrls;
      }

      await _client
          .from(_table)
          .delete()
          .eq('id', id)
          .eq('seller_id', _userId!);

      // Eliminar fotos en background
      for (final url in photoUrls) {
        final path = _extractPathFromUrl(url);
        if (path != null) {
          _deletePhotoAsync(path);
        }
      }

      Logger.i('✅ Anuncio eliminado');
      return const Success(null);
    } catch (e, stackTrace) {
      Logger.e('❌ Error eliminando anuncio', error: e, stackTrace: stackTrace);
      return Failure('Error al eliminar anuncio: ${e.toString()}');
    }
  }

  @override
  Future<Result<List<String>>> uploadPhotos(List<Uint8List> imageBytesList) async {
    try {
      Logger.d('📤 Subiendo ${imageBytesList.length} fotos');

      if (_userId == null) {
        return const Failure('Usuario no autenticado');
      }

      final urls = <String>[];

      for (int i = 0; i < imageBytesList.length; i++) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final path = '$_userId/${timestamp}_$i.jpg';

        await _client.storage.from(_bucket).uploadBinary(
              path,
              imageBytesList[i],
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
              ),
            );

        final url = _client.storage.from(_bucket).getPublicUrl(path);
        urls.add(url);
      }

      Logger.i('✅ ${urls.length} fotos subidas');
      return Success(urls);
    } catch (e, stackTrace) {
      Logger.e('❌ Error subiendo fotos', error: e, stackTrace: stackTrace);
      return Failure('Error al subir fotos: ${e.toString()}');
    }
  }

  @override
  Future<Result<void>> deletePhotos(List<String> filePaths) async {
    try {
      Logger.d('🗑️ Eliminando ${filePaths.length} fotos');
      await _client.storage.from(_bucket).remove(filePaths);
      return const Success(null);
    } catch (e) {
      Logger.w('Error deleting photos: $e');
      return Failure('Error al eliminar fotos: ${e.toString()}');
    }
  }

  @override
  Future<Result<void>> incrementViewCount(String listingId) async {
    try {
      // Usar RPC para evitar race conditions
      await _client.rpc('increment_listing_views', params: {'p_listing_id': listingId});
      return const Success(null);
    } catch (e) {
      Logger.w('Error incrementing view count for $listingId: $e');
      return Failure('Error al incrementar vistas: ${e.toString()}');
    }
  }

  @override
  Future<Result<bool>> toggleFavorite(String listingId) async {
    try {
      Logger.d('❤️ Toggle favorito: $listingId');

      if (_userId == null) {
        return const Failure('Usuario no autenticado');
      }

      final result = await _client.rpc('toggle_listing_favorite', params: {
        'p_user_id': _userId,
        'p_listing_id': listingId,
      });

      final isNowFavorited = result as bool;
      Logger.i('✅ Favorito: $isNowFavorited');
      return Success(isNowFavorited);
    } catch (e, stackTrace) {
      Logger.e('❌ Error toggle favorito', error: e, stackTrace: stackTrace);
      return Failure('Error: ${e.toString()}');
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getAreaStatistics({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    try {
      final params = {
        'p_latitude': latitude,
        'p_longitude': longitude,
        'p_radius_km': radiusKm,
      };

      final response = await _client.rpc('get_marketplace_statistics', params: params);
      return Success(response as Map<String, dynamic>);
    } catch (e, stackTrace) {
      Logger.e('❌ Error estadísticas', error: e, stackTrace: stackTrace);
      return Failure('Error al cargar estadísticas: ${e.toString()}');
    }
  }

  // Helpers privados
  void _incrementViewCountAsync(String listingId) {
    // Fire and forget
    incrementViewCount(listingId);
  }

  void _deletePhotoAsync(String path) {
    deletePhotos([path]);
  }

  String? _extractPathFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf(_bucket);
      if (bucketIndex >= 0 && bucketIndex < pathSegments.length - 1) {
        return pathSegments.sublist(bucketIndex + 1).join('/');
      }
      return null;
    } catch (e) {
      Logger.w('Could not extract path from URL: $url — $e');
      return null;
    }
  }
}
