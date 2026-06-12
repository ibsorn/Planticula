import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/marketplace/domain/entities/marketplace_listing.dart';
import 'package:planticula/features/marketplace/domain/repositories/marketplace_repository.dart';

class GetMyListingsUseCase {
  final MarketplaceRepository _repository;
  GetMyListingsUseCase(this._repository);

  Future<Result<List<MarketplaceListing>>> call({
    int limit = 50,
    int offset = 0,
  }) => _repository.getMyListings(
    limit: limit,
    offset: offset,
  );
}
