import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:planticula/core/utils/image_picker_helper.dart';
import 'package:planticula/features/marketplace/domain/entities/marketplace_listing.dart';
import 'package:planticula/features/marketplace/domain/repositories/marketplace_repository.dart';

part 'marketplace_event.dart';
part 'marketplace_state.dart';

class MarketplaceBloc extends Bloc<MarketplaceEvent, MarketplaceState> {
  final MarketplaceRepository _repository;
  final ImagePickerHelper _imagePickerHelper;

  MarketplaceBloc(this._repository)
      : _imagePickerHelper = ImagePickerHelper(),
        super(const MarketplaceState()) {
    on<MarketplaceLoadNearby>(_onLoadNearby);
    on<MarketplaceLoadMyListings>(_onLoadMyListings);
    on<MarketplaceLoadFavorites>(_onLoadFavorites);
    on<MarketplaceRefresh>(_onRefresh);
    on<MarketplacePhotoPickRequested>(_onPhotoPickRequested);
    on<MarketplacePhotoCaptureRequested>(_onPhotoCaptureRequested);
    on<MarketplaceRemovePhoto>(_onRemovePhoto);
    on<MarketplaceListingSubmitted>(_onListingSubmitted);
    on<MarketplaceFilterChanged>(_onFilterChanged);
    on<MarketplaceSearchQueryChanged>(_onSearchQueryChanged);
    on<MarketplaceListingSelected>(_onListingSelected);
    on<MarketplaceChangeStatus>(_onChangeStatus);
    on<MarketplaceDeleteListing>(_onDeleteListing);
    on<MarketplaceToggleFavorite>(_onToggleFavorite);
    on<MarketplaceUpdateUserLocation>(_onUpdateUserLocation);
    on<MarketplaceClearError>(_onClearError);
  }

  Future<void> _onLoadNearby(
    MarketplaceLoadNearby event,
    Emitter<MarketplaceState> emit,
  ) async {
    await _loadNearbyListings(emit);
  }

  Future<void> _loadNearbyListings(Emitter<MarketplaceState> emit) async {
    emit(state.copyWith(
      nearbyStatus: MarketplaceStatus.loading,
    ));

    if (state.userLatitude == null || state.userLongitude == null) {
      emit(state.copyWith(
        nearbyStatus: MarketplaceStatus.error,
        errorMessage: 'Se requiere ubicación para ver anuncios cercanos',
      ));
      return;
    }

    final result = await _repository.getNearbyListings(
      latitude: state.userLatitude!,
      longitude: state.userLongitude!,
      radiusKm: state.filterRadiusKm,
      categories: state.filterCategories,
      listingTypes: state.filterListingTypes,
      maxPrice: state.filterMaxPrice,
      searchQuery: state.searchQuery?.isNotEmpty == true ? state.searchQuery : null,
      includeSold: false,
      limit: 50,
    );

    result.when(
      success: (listings) {
        emit(state.copyWith(
          nearbyListings: listings,
          nearbyStatus: listings.isEmpty ? MarketplaceStatus.empty : MarketplaceStatus.loaded,
        ));
      },
      failure: (message, code, error) {
        emit(state.copyWith(
          nearbyStatus: MarketplaceStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onLoadMyListings(
    MarketplaceLoadMyListings event,
    Emitter<MarketplaceState> emit,
  ) async {
    await _loadMyListings(emit);
  }

  Future<void> _loadMyListings(Emitter<MarketplaceState> emit) async {
    emit(state.copyWith(
      myListingsStatus: MarketplaceStatus.loading,
    ));

    final result = await _repository.getMyListings(limit: 50);

    result.when(
      success: (listings) {
        emit(state.copyWith(
          myListings: listings,
          myListingsStatus: listings.isEmpty ? MarketplaceStatus.empty : MarketplaceStatus.loaded,
        ));
      },
      failure: (message, code, error) {
        emit(state.copyWith(
          myListingsStatus: MarketplaceStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onLoadFavorites(
    MarketplaceLoadFavorites event,
    Emitter<MarketplaceState> emit,
  ) async {
    await _loadFavorites(emit);
  }

  Future<void> _loadFavorites(Emitter<MarketplaceState> emit) async {
    emit(state.copyWith(
      favoritesStatus: MarketplaceStatus.loading,
    ));

    final result = await _repository.getFavoriteListings();

    result.when(
      success: (listings) {
        emit(state.copyWith(
          favoriteListings: listings,
          favoritesStatus: listings.isEmpty ? MarketplaceStatus.empty : MarketplaceStatus.loaded,
        ));
      },
      failure: (message, code, error) {
        emit(state.copyWith(
          favoritesStatus: MarketplaceStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onRefresh(
    MarketplaceRefresh event,
    Emitter<MarketplaceState> emit,
  ) async {
    switch (state.activeTab) {
      case MarketplaceTab.nearby:
        await _loadNearbyListings(emit);
        break;
      case MarketplaceTab.myListings:
        await _loadMyListings(emit);
        break;
      case MarketplaceTab.favorites:
        await _loadFavorites(emit);
        break;
    }
  }

  Future<void> _onPhotoPickRequested(
    MarketplacePhotoPickRequested event,
    Emitter<MarketplaceState> emit,
  ) async {
    try {
      emit(state.copyWith(photoStatus: PhotoStatus.picking));

      final bytes = await _imagePickerHelper.pickMultipleImages();

      if (bytes.isNotEmpty) {
        final currentPhotos = state.selectedPhotos ?? [];
        emit(state.copyWith(
          selectedPhotos: [...currentPhotos, ...bytes],
          photoStatus: PhotoStatus.selected,
        ));
      } else {
        emit(state.copyWith(photoStatus: PhotoStatus.initial));
      }
    } catch (e) {
      emit(state.copyWith(
        photoStatus: PhotoStatus.error,
        errorMessage: 'Error al seleccionar fotos: ${e.toString()}',
      ));
    }
  }

  Future<void> _onPhotoCaptureRequested(
    MarketplacePhotoCaptureRequested event,
    Emitter<MarketplaceState> emit,
  ) async {
    try {
      emit(state.copyWith(photoStatus: PhotoStatus.picking));

      final bytes = await _imagePickerHelper.pickSingleImage(
        source: ImageSource.camera,
      );

      if (bytes != null) {
        final currentPhotos = state.selectedPhotos ?? [];
        emit(state.copyWith(
          selectedPhotos: [...currentPhotos, bytes],
          photoStatus: PhotoStatus.selected,
        ));
      } else {
        emit(state.copyWith(photoStatus: PhotoStatus.initial));
      }
    } catch (e) {
      emit(state.copyWith(
        photoStatus: PhotoStatus.error,
        errorMessage: 'Error al capturar foto: ${e.toString()}',
      ));
    }
  }

  void _onRemovePhoto(
    MarketplaceRemovePhoto event,
    Emitter<MarketplaceState> emit,
  ) {
    final currentPhotos = state.selectedPhotos ?? [];
    if (event.index >= 0 && event.index < currentPhotos.length) {
      final newPhotos = List<Uint8List>.from(currentPhotos)..removeAt(event.index);
      emit(state.copyWith(
        selectedPhotos: newPhotos.isEmpty ? null : newPhotos,
        photoStatus: newPhotos.isEmpty ? PhotoStatus.initial : PhotoStatus.selected,
      ));
    }
  }

  Future<void> _onListingSubmitted(
    MarketplaceListingSubmitted event,
    Emitter<MarketplaceState> emit,
  ) async {
    emit(state.copyWith(
      submissionStatus: SubmissionStatus.submitting,
    ));

    final result = await _repository.createListing(
      title: event.title,
      description: event.description,
      category: event.category,
      photos: state.selectedPhotos,
      listingType: event.listingType,
      price: event.price,
      tradeFor: event.tradeFor,
      latitude: event.latitude,
      longitude: event.longitude,
      locationName: event.locationName,
    );

    result.when(
      success: (listing) {
        emit(state.copyWith(
          submissionStatus: SubmissionStatus.success,
          photoStatus: PhotoStatus.initial,
          myListings: [listing, ...state.myListings],
          lastCreatedListing: listing,
        ));
      },
      failure: (message, code, error) {
        emit(state.copyWith(
          submissionStatus: SubmissionStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onFilterChanged(
    MarketplaceFilterChanged event,
    Emitter<MarketplaceState> emit,
  ) async {
    emit(state.copyWith(
      filterRadiusKm: event.radiusKm ?? state.filterRadiusKm,
      filterCategories: event.categories ?? state.filterCategories,
      filterListingTypes: event.listingTypes ?? state.filterListingTypes,
      filterMaxPrice: event.maxPrice ?? state.filterMaxPrice,
    ));
    await _loadNearbyListings(emit);
  }

  Future<void> _onSearchQueryChanged(
    MarketplaceSearchQueryChanged event,
    Emitter<MarketplaceState> emit,
  ) async {
    emit(state.copyWith(searchQuery: event.query));
    if (event.query.length >= 3 || event.query.isEmpty) {
      await _loadNearbyListings(emit);
    }
  }

  void _onListingSelected(
    MarketplaceListingSelected event,
    Emitter<MarketplaceState> emit,
  ) {
    final listing = state.nearbyListings.firstWhere(
      (l) => l.id == event.listingId,
      orElse: () => state.myListings.firstWhere(
        (l) => l.id == event.listingId,
        orElse: () => state.nearbyListings.first,
      ),
    );
    emit(state.copyWith(selectedListing: listing));
  }

  Future<void> _onChangeStatus(
    MarketplaceChangeStatus event,
    Emitter<MarketplaceState> emit,
  ) async {
    emit(state.copyWith(actionStatus: ActionStatus.processing));

    final result = await _repository.changeListingStatus(event.listingId, event.status);

    result.when(
      success: (listing) {
        final updatedNearby = state.nearbyListings
            .map((l) => l.id == listing.id ? listing : l)
            .toList();
        final updatedMy = state.myListings
            .map((l) => l.id == listing.id ? listing : l)
            .toList();

        emit(state.copyWith(
          nearbyListings: updatedNearby,
          myListings: updatedMy,
          selectedListing: state.selectedListing?.id == listing.id ? listing : state.selectedListing,
          actionStatus: ActionStatus.success,
        ));
      },
      failure: (message, code, error) {
        emit(state.copyWith(
          actionStatus: ActionStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onDeleteListing(
    MarketplaceDeleteListing event,
    Emitter<MarketplaceState> emit,
  ) async {
    emit(state.copyWith(actionStatus: ActionStatus.processing));

    final result = await _repository.deleteListing(event.listingId);

    result.when(
      success: (_) {
        final updatedNearby = state.nearbyListings
            .where((l) => l.id != event.listingId)
            .toList();
        final updatedMy = state.myListings
            .where((l) => l.id != event.listingId)
            .toList();
        final updatedFav = state.favoriteListings
            .where((l) => l.id != event.listingId)
            .toList();

        emit(state.copyWith(
          nearbyListings: updatedNearby,
          myListings: updatedMy,
          favoriteListings: updatedFav,
          selectedListing: state.selectedListing?.id == event.listingId
              ? null
              : state.selectedListing,
          actionStatus: ActionStatus.success,
        ));
      },
      failure: (message, code, error) {
        emit(state.copyWith(
          actionStatus: ActionStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onToggleFavorite(
    MarketplaceToggleFavorite event,
    Emitter<MarketplaceState> emit,
  ) async {
    final result = await _repository.toggleFavorite(event.listingId);

    result.when(
      success: (isFavorited) {
        // Actualizar en listas
        final updatedNearby = state.nearbyListings.map((l) {
          if (l.id == event.listingId) {
            return l.copyWith(
              isFavorited: isFavorited,
              favoriteCount: isFavorited
                  ? (l.favoriteCount + 1)
                  : (l.favoriteCount - 1),
            );
          }
          return l;
        }).toList();

        emit(state.copyWith(
          nearbyListings: updatedNearby,
          selectedListing: state.selectedListing?.id == event.listingId
              ? state.selectedListing!.copyWith(isFavorited: isFavorited)
              : state.selectedListing,
        ));
      },
      failure: (message, code, error) {
        // Silencioso, no mostrar error
      },
    );
  }

  Future<void> _onUpdateUserLocation(
    MarketplaceUpdateUserLocation event,
    Emitter<MarketplaceState> emit,
  ) async {
    emit(state.copyWith(
      userLatitude: event.latitude,
      userLongitude: event.longitude,
    ));
    await _loadNearbyListings(emit);
  }

  void _onClearError(
    MarketplaceClearError event,
    Emitter<MarketplaceState> emit,
  ) {
    emit(state.copyWith(
      submissionStatus: SubmissionStatus.initial,
      actionStatus: ActionStatus.initial,
    ));
  }
}
