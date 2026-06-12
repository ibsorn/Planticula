import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/marketplace/domain/entities/marketplace_listing.dart';
import 'package:planticula/features/marketplace/domain/repositories/marketplace_repository.dart';

class GetFavoriteListingsUseCase {
  final MarketplaceRepository _repository;
  GetFavoriteListingsUseCase(this._repository);

  Future<Result<List<MarketplaceListing>>> call() => _repository.getFavoriteListings();
}
