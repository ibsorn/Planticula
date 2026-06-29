import 'dart:typed_data';
import 'package:planticula/core/network/datasource_mixin.dart';
import 'package:planticula/core/network/result.dart';
import 'package:planticula/core/network/supabase_client.dart';
import 'package:planticula/core/storage/storage_service.dart';
import 'package:planticula/core/utils/logger.dart';
import 'package:planticula/features/marketplace/data/datasources/marketplace_remote_datasource.dart';
import 'package:planticula/features/marketplace/data/models/marketplace_listing_model.dart';

/// Implementación de MarketplaceRemoteDataSource usando Supabase
class MarketplaceRemoteDataSourceImpl
    with DatasourceMixin
    implements MarketplaceRemoteDataSource {
  @override
  final AppSupabaseClient client;
  final StorageService _storage;

  MarketplaceRemoteDataSourceImpl(this.client)
      : _storage = StorageService(client);

  String get _table => 'marketplace_listings';
  String get _bucket => 'marketplace-photos';
  String get _favoritesTable => 'marketplace_favorites';

  @override
  Future<Result<MarketplaceListingModel>> createListing(CreateListingRequest request) async {
    return guardedCall(
      errorPrefix: 'Error al crear anuncio',
      operation: (uid) async {
        Logger.d('📤 Creando anuncio: ${request.title}');

        // Obtener nombre del perfil del usuario
        String? sellerName;
        try {
          final profile = await client
              .from('profiles')
              .select('username, full_name')
              .eq('id', uid)
              .single();
          sellerName = profile['username'] ?? profile['full_name'];
        } catch (_) {
          sellerName = null;
        }

        final data = request.toJson(uid, sellerName);

        final response = await client
            .from(_table)
            .insert(data)
            .select()
            .single();

        final listing = MarketplaceListingModel.fromJson(response);
        Logger.i('✅ Anuncio creado: ${listing.id}');
        return listing;
      },
    );
  }

  @override
  Future<Result<MarketplaceListingModel>> getListingById(String id) async {
    try {
      Logger.d('📥 Obteniendo anuncio: $id');

      final response = await client
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

      final response = await client.rpc('get_nearby_listings', params: params);

      final listings = (response as List)
          .map((json) => MarketplaceListingModel.fromJson(json))
          .toList();

      Logger.i('✅ Encontrados ${listings.length} anuncios cercanos');
      return Success(listings);
    } catch (e, stackTrace) {
      Logger.e('❌ Error buscando anuncios cercanos', error: e, stackTrace: stackTrace);

      // Fallback simple
      try {
        var query = client
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
    return guardedCall(
      errorPrefix: 'Error al cargar mis anuncios',
      operation: (uid) async {
        Logger.d('📥 Obteniendo mis anuncios');
        final response = await client
            .from(_table)
            .select()
            .eq('seller_id', uid)
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);

        final listings = (response as List)
            .map((json) => MarketplaceListingModel.fromJson(json))
            .toList();
        Logger.i('✅ Cargados ${listings.length} anuncios propios');
        return listings;
      },
    );
  }

  @override
  Future<Result<List<MarketplaceListingModel>>> getFavoriteListings() async {
    return guardedCall(
      errorPrefix: 'Error al cargar favoritos',
      operation: (uid) async {
        Logger.d('📥 Obteniendo favoritos');
        final response = await client
            .from(_favoritesTable)
            .select('listing:marketplace_listings(*)')
            .eq('user_id', uid)
            .order('created_at', ascending: false);

        final listings = (response as List)
            .map((json) => MarketplaceListingModel.fromJson({
                  ...json['listing'],
                  'is_favorited': true,
                }))
            .toList();
        return listings;
      },
    );
  }

  @override
  Future<Result<MarketplaceListingModel>> updateListing(MarketplaceListingModel listing) async {
    return guardedCall(
      errorPrefix: 'Error al actualizar anuncio',
      operation: (uid) async {
        Logger.d('📤 Actualizando anuncio: ${listing.id}');
        final data = listing.toJson();
        data.remove('id');
        data.remove('seller_id');
        data.remove('created_at');
        data['updated_at'] = DateTime.now().toIso8601String();

        final response = await client
            .from(_table)
            .update(data)
            .eq('id', listing.id)
            .eq('seller_id', uid)
            .select()
            .single();

        final updated = MarketplaceListingModel.fromJson(response);
        Logger.i('✅ Anuncio actualizado');
        return updated;
      },
    );
  }

  @override
  Future<Result<MarketplaceListingModel>> updateListingStatus(String id, String status) async {
    return guardedCall(
      errorPrefix: 'Error al actualizar estado',
      operation: (uid) async {
        Logger.d('📤 Cambiando estado de $id a $status');
        final response = await client
            .from(_table)
            .update({
              'status': status,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', id)
            .eq('seller_id', uid)
            .select()
            .single();

        final updated = MarketplaceListingModel.fromJson(response);
        Logger.i('✅ Estado actualizado a $status');
        return updated;
      },
    );
  }

  @override
  Future<Result<void>> deleteListing(String id) async {
    final authFailure = requireAuth<void>();
    if (authFailure != null) return authFailure;

    try {
      Logger.d('🗑️ Eliminando anuncio: $id');

      // Obtener fotos para eliminar después
      final listingResult = await getListingById(id);
      List<String> photoUrls = [];
      if (listingResult is Success<MarketplaceListingModel>) {
        photoUrls = listingResult.data.photoUrls;
      }

      await client
          .from(_table)
          .delete()
          .eq('id', id)
          .eq('seller_id', userId!);

      // Eliminar fotos en background
      for (final url in photoUrls) {
        final path = StorageService.extractPathFromUrl(url, _bucket);
        if (path != null) {
          _storage.deleteFile(bucket: _bucket, storagePath: path);
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
  Future<Result<List<String>>> uploadPhotos(List<Uint8List> imageBytesList) {
    return _storage.uploadImages(
      bucket: _bucket,
      imageBytesList: imageBytesList,
    );
  }

  @override
  Future<Result<void>> deletePhotos(List<String> filePaths) {
    return _storage.deleteFiles(bucket: _bucket, storagePaths: filePaths);
  }

  @override
  Future<Result<void>> incrementViewCount(String listingId) async {
    try {
      await client.rpc('increment_listing_views', params: {'p_listing_id': listingId});
      return const Success(null);
    } catch (e) {
      return const Success(null);
    }
  }

  @override
  Future<Result<bool>> toggleFavorite(String listingId) async {
    return guardedCall(
      errorPrefix: 'Error toggle favorito',
      operation: (uid) async {
        Logger.d('❤️ Toggle favorito: $listingId');
        final result = await client.rpc('toggle_listing_favorite', params: {
          'p_user_id': uid,
          'p_listing_id': listingId,
        });

        final isNowFavorited = result as bool;
        Logger.i('✅ Favorito: $isNowFavorited');
        return isNowFavorited;
      },
    );
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

      final response = await client.rpc('get_marketplace_statistics', params: params);
      return Success(response as Map<String, dynamic>);
    } catch (e, stackTrace) {
      Logger.e('❌ Error estadísticas', error: e, stackTrace: stackTrace);
      return Failure('Error al cargar estadísticas: ${e.toString()}');
    }
  }

  void _incrementViewCountAsync(String listingId) {
    incrementViewCount(listingId);
  }
}
