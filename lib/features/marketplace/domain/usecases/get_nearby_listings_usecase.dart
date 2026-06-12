import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/marketplace/domain/entities/marketplace_listing.dart';
import 'package:planticula/features/marketplace/domain/repositories/marketplace_repository.dart';

class GetNearbyListingsUseCase {
  final MarketplaceRepository _repository;
  GetNearbyListingsUseCase(this._repository);

  Future<Result<List<MarketplaceListing>>> call({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
    List<ListingCategory>? categories,
    List<ListingType>? listingTypes,
    double? maxPrice,
    String? searchQuery,
    bool includeSold = false,
    int limit = 50,
    int offset = 0,
  }) => _repository.getNearbyListings(
    latitude: latitude,
    longitude: longitude,
    radiusKm: radiusKm,
    categories: categories,
    listingTypes: listingTypes,
    maxPrice: maxPrice,
    searchQuery: searchQuery,
    includeSold: includeSold,
    limit: limit,
    offset: offset,
  );
}
