part of 'marketplace_bloc.dart';

abstract class MarketplaceEvent extends Equatable {
  const MarketplaceEvent();

  @override
  List<Object?> get props => [];
}

/// Cargar anuncios cercanos
class MarketplaceLoadNearby extends MarketplaceEvent {}

/// Cargar anuncios del usuario
class MarketplaceLoadMyListings extends MarketplaceEvent {}

/// Cargar favoritos del usuario
class MarketplaceLoadFavorites extends MarketplaceEvent {}

/// Recargar según tab activo
class MarketplaceRefresh extends MarketplaceEvent {}

/// Seleccionar fotos desde galería
class MarketplacePhotoPickRequested extends MarketplaceEvent {}

/// Capturar foto desde cámara
class MarketplacePhotoCaptureRequested extends MarketplaceEvent {}

/// Eliminar foto seleccionada
class MarketplaceRemovePhoto extends MarketplaceEvent {
  final int index;

  const MarketplaceRemovePhoto(this.index);

  @override
  List<Object?> get props => [index];
}

/// Crear anuncio
class MarketplaceListingSubmitted extends MarketplaceEvent {
  final String title;
  final String description;
  final ListingCategory category;
  final ListingType listingType;
  final double? price;
  final String? tradeFor;
  final double latitude;
  final double longitude;
  final String? locationName;

  const MarketplaceListingSubmitted({
    required this.title,
    required this.description,
    required this.category,
    required this.listingType,
    this.price,
    this.tradeFor,
    required this.latitude,
    required this.longitude,
    this.locationName,
  });

  @override
  List<Object?> get props => [
        title,
        description,
        category,
        listingType,
        price,
        tradeFor,
        latitude,
        longitude,
        locationName,
      ];
}

/// Cambiar filtros
class MarketplaceFilterChanged extends MarketplaceEvent {
  final double? radiusKm;
  final List<ListingCategory>? categories;
  final List<ListingType>? listingTypes;
  final double? maxPrice;

  const MarketplaceFilterChanged({
    this.radiusKm,
    this.categories,
    this.listingTypes,
    this.maxPrice,
  });

  @override
  List<Object?> get props => [radiusKm, categories, listingTypes, maxPrice];
}

/// Cambiar búsqueda
class MarketplaceSearchQueryChanged extends MarketplaceEvent {
  final String query;

  const MarketplaceSearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Seleccionar anuncio
class MarketplaceListingSelected extends MarketplaceEvent {
  final String listingId;

  const MarketplaceListingSelected(this.listingId);

  @override
  List<Object?> get props => [listingId];
}

/// Cambiar estado del anuncio
class MarketplaceChangeStatus extends MarketplaceEvent {
  final String listingId;
  final ListingStatus status;

  const MarketplaceChangeStatus({
    required this.listingId,
    required this.status,
  });

  @override
  List<Object?> get props => [listingId, status];
}

/// Eliminar anuncio
class MarketplaceDeleteListing extends MarketplaceEvent {
  final String listingId;

  const MarketplaceDeleteListing(this.listingId);

  @override
  List<Object?> get props => [listingId];
}

/// Toggle favorito
class MarketplaceToggleFavorite extends MarketplaceEvent {
  final String listingId;

  const MarketplaceToggleFavorite(this.listingId);

  @override
  List<Object?> get props => [listingId];
}

/// Actualizar ubicación
class MarketplaceUpdateUserLocation extends MarketplaceEvent {
  final double latitude;
  final double longitude;

  const MarketplaceUpdateUserLocation({
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [latitude, longitude];
}

/// Limpiar error
class MarketplaceClearError extends MarketplaceEvent {}
