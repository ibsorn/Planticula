import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/marketplace/domain/repositories/marketplace_repository.dart';

class ToggleFavoriteUseCase {
  final MarketplaceRepository _repository;
  ToggleFavoriteUseCase(this._repository);

  Future<Result<bool>> call(String listingId) => _repository.toggleFavorite(listingId);
}
