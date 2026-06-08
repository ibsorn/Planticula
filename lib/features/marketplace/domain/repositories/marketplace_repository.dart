import 'dart:typed_data';
import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/marketplace/domain/entities/marketplace_listing.dart';

/// Contrato para el repositorio del marketplace
abstract class MarketplaceRepository {
  /// Crea un nuevo anuncio (sube fotos si hay)
  Future<Result<MarketplaceListing>> createListing({
    required String title,
    required String description,
    required ListingCategory category,
    List<Uint8List>? photos,
    required ListingType listingType,
    double? price,
    String? tradeFor,
    required double latitude,
    required double longitude,
    String? locationName,
  });

  /// Obtiene anuncios cercanos
  Future<Result<List<MarketplaceListing>>> getNearbyListings({
    required double latitude,
    required double longitude,
    double radiusKm,
    List<ListingCategory>? categories,
    List<ListingType>? listingTypes,
    double? maxPrice,
    String? searchQuery,
    bool includeSold,
    int limit,
    int offset,
  });

  /// Obtiene anuncios del usuario
  Future<Result<List<MarketplaceListing>>> getMyListings({
    int limit,
    int offset,
  });

  /// Obtiene favoritos del usuario
  Future<Result<List<MarketplaceListing>>> getFavoriteListings();

  /// Obtiene un anuncio por ID
  Future<Result<MarketplaceListing>> getListingById(String id);

  /// Actualiza un anuncio
  Future<Result<MarketplaceListing>> updateListing(MarketplaceListing listing);

  /// Cambia el estado del anuncio (active/reserved/sold/inactive)
  Future<Result<MarketplaceListing>> changeListingStatus(String id, ListingStatus status);

  /// Elimina un anuncio
  Future<Result<void>> deleteListing(String id);

  /// Marca/desmarca como favorito
  Future<Result<bool>> toggleFavorite(String listingId);

  /// Obtiene estadísticas del área
  Future<Result<Map<String, dynamic>>> getAreaStatistics({
    required double latitude,
    required double longitude,
    double radiusKm,
  });
}
