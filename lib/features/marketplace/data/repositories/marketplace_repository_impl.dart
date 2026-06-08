import 'dart:typed_data';
import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/marketplace/data/datasources/marketplace_remote_datasource.dart';
import 'package:planticula/features/marketplace/data/models/marketplace_listing_model.dart';
import 'package:planticula/features/marketplace/domain/entities/marketplace_listing.dart';
import 'package:planticula/features/marketplace/domain/repositories/marketplace_repository.dart';

/// Implementación del repositorio del marketplace
class MarketplaceRepositoryImpl implements MarketplaceRepository {
  final MarketplaceRemoteDataSource _dataSource;

  MarketplaceRepositoryImpl(this._dataSource);

  @override
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
  }) async {
    // Subir fotos primero si existen
    List<String>? photoUrls;
    if (photos != null && photos.isNotEmpty) {
      final uploadResult = await _dataSource.uploadPhotos(photos);
      if (uploadResult is Failure<List<String>>) {
        return Failure(uploadResult.message);
      }
      photoUrls = (uploadResult as Success<List<String>>).data;
    }

    // Crear request
    final request = CreateListingRequest(
      title: title,
      description: description,
      category: category,
      photoUrls: photoUrls,
      listingType: listingType,
      price: price,
      tradeFor: tradeFor,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
    );

    return await _dataSource.createListing(request);
  }

  @override
  Future<Result<List<MarketplaceListing>>> getNearbyListings({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    List<ListingCategory>? categories,
    List<ListingType>? listingTypes,
    double? maxPrice,
    String? searchQuery,
    bool includeSold = false,
    int limit = 50,
    int offset = 0,
  }) async {
    return await _dataSource.getNearbyListings(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      categories: categories?.map((e) => e.name).toList(),
      listingTypes: listingTypes?.map((e) => e.name).toList(),
      maxPrice: maxPrice,
      searchQuery: searchQuery,
      includeSold: includeSold,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<Result<List<MarketplaceListing>>> getMyListings({
    int limit = 50,
    int offset = 0,
  }) async {
    return await _dataSource.getMyListings(limit: limit, offset: offset);
  }

  @override
  Future<Result<List<MarketplaceListing>>> getFavoriteListings() async {
    return await _dataSource.getFavoriteListings();
  }

  @override
  Future<Result<MarketplaceListing>> getListingById(String id) async {
    return await _dataSource.getListingById(id);
  }

  @override
  Future<Result<MarketplaceListing>> updateListing(MarketplaceListing listing) async {
    final model = MarketplaceListingModel.fromDomain(listing);
    return await _dataSource.updateListing(model);
  }

  @override
  Future<Result<MarketplaceListing>> changeListingStatus(String id, ListingStatus status) async {
    return await _dataSource.updateListingStatus(id, status.name);
  }

  @override
  Future<Result<void>> deleteListing(String id) async {
    return await _dataSource.deleteListing(id);
  }

  @override
  Future<Result<bool>> toggleFavorite(String listingId) async {
    return await _dataSource.toggleFavorite(listingId);
  }

  @override
  Future<Result<Map<String, dynamic>>> getAreaStatistics({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    return await _dataSource.getAreaStatistics(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );
  }
}
