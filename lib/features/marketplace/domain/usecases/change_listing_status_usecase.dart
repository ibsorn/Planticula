import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/marketplace/domain/entities/marketplace_listing.dart';
import 'package:planticula/features/marketplace/domain/repositories/marketplace_repository.dart';

class ChangeListingStatusUseCase {
  final MarketplaceRepository _repository;
  ChangeListingStatusUseCase(this._repository);

  Future<Result<MarketplaceListing>> call(String id, ListingStatus status) =>
      _repository.changeListingStatus(id, status);
}
