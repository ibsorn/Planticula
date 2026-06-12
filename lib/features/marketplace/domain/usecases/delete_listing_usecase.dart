import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/marketplace/domain/repositories/marketplace_repository.dart';

class DeleteListingUseCase {
  final MarketplaceRepository _repository;
  DeleteListingUseCase(this._repository);

  Future<Result<void>> call(String id) => _repository.deleteListing(id);
}
