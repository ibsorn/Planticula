import 'dart:typed_data';
import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/marketplace/domain/entities/marketplace_listing.dart';
import 'package:planticula/features/marketplace/domain/repositories/marketplace_repository.dart';

class CreateListingUseCase {
  final MarketplaceRepository _repository;
  CreateListingUseCase(this._repository);

  Future<Result<MarketplaceListing>> call({
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
  }) => _repository.createListing(
    title: title,
    description: description,
    category: category,
    photos: photos,
    listingType: listingType,
    price: price,
    tradeFor: tradeFor,
    latitude: latitude,
    longitude: longitude,
    locationName: locationName,
  );
}
