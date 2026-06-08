import 'dart:typed_data';
import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/marketplace/data/models/marketplace_listing_model.dart';

/// Contrato para fuente de datos del marketplace
abstract class MarketplaceRemoteDataSource {
  /// Crea un nuevo anuncio
  Future<Result<MarketplaceListingModel>> createListing(CreateListingRequest request);

  /// Obtiene un anuncio por ID
  Future<Result<MarketplaceListingModel>> getListingById(String id);

  /// Obtiene anuncios cercanos ordenados por distancia
  Future<Result<List<MarketplaceListingModel>>> getNearbyListings({
    required double latitude,
    required double longitude,
    double radiusKm,
    List<String>? categories,
    List<String>? listingTypes,
    double? maxPrice,
    String? searchQuery,
    bool includeSold,
    int limit,
    int offset,
  });

  /// Obtiene anuncios del usuario
  Future<Result<List<MarketplaceListingModel>>> getMyListings({
    int limit,
    int offset,
  });

  /// Obtiene anuncios favoritos del usuario
  Future<Result<List<MarketplaceListingModel>>> getFavoriteListings();

  /// Actualiza un anuncio
  Future<Result<MarketplaceListingModel>> updateListing(MarketplaceListingModel listing);

  /// Marca como vendido/reservado
  Future<Result<MarketplaceListingModel>> updateListingStatus(String id, String status);

  /// Elimina un anuncio
  Future<Result<void>> deleteListing(String id);

  /// Sube fotos a Storage
  Future<Result<List<String>>> uploadPhotos(List<Uint8List> imageBytesList);

  /// Elimina fotos de Storage
  Future<Result<void>> deletePhotos(List<String> filePaths);

  /// Incrementa contador de vistas
  Future<Result<void>> incrementViewCount(String listingId);

  /// Toggle favorito
  Future<Result<bool>> toggleFavorite(String listingId);

  /// Obtiene estadísticas del marketplace en un área
  Future<Result<Map<String, dynamic>>> getAreaStatistics({
    required double latitude,
    required double longitude,
    double radiusKm,
  });
}
