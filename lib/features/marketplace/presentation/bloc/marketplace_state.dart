part of 'marketplace_bloc.dart';

enum MarketplaceStatus {
  initial,
  loading,
  loaded,
  empty,
  error,
}

enum PhotoStatus {
  initial,
  picking,
  selected,
  error,
}

enum SubmissionStatus {
  initial,
  submitting,
  success,
  error,
}

enum ActionStatus {
  initial,
  processing,
  success,
  error,
}

enum MarketplaceTab {
  nearby,
  myListings,
  favorites,
}

class MarketplaceState extends Equatable {
  // Listas
  final List<MarketplaceListing> nearbyListings;
  final List<MarketplaceListing> myListings;
  final List<MarketplaceListing> favoriteListings;

  // Estados
  final MarketplaceStatus nearbyStatus;
  final MarketplaceStatus myListingsStatus;
  final MarketplaceStatus favoritesStatus;
  final PhotoStatus photoStatus;
  final SubmissionStatus submissionStatus;
  final ActionStatus actionStatus;
  final String? errorMessage;

  // Tab seleccionado
  final MarketplaceTab activeTab;

  // Ubicación
  final double? userLatitude;
  final double? userLongitude;

  // Filtros
  final double filterRadiusKm;
  final List<ListingCategory> filterCategories;
  final List<ListingType> filterListingTypes;
  final double? filterMaxPrice;
  final String? searchQuery;

  // Selección
  final MarketplaceListing? selectedListing;
  final List<Uint8List>? selectedPhotos;
  final MarketplaceListing? lastCreatedListing;

  const MarketplaceState({
    this.nearbyListings = const [],
    this.myListings = const [],
    this.favoriteListings = const [],
    this.nearbyStatus = MarketplaceStatus.initial,
    this.myListingsStatus = MarketplaceStatus.initial,
    this.favoritesStatus = MarketplaceStatus.initial,
    this.photoStatus = PhotoStatus.initial,
    this.submissionStatus = SubmissionStatus.initial,
    this.actionStatus = ActionStatus.initial,
    this.errorMessage,
    this.activeTab = MarketplaceTab.nearby,
    this.userLatitude,
    this.userLongitude,
    this.filterRadiusKm = 10.0,
    this.filterCategories = const [],
    this.filterListingTypes = const [],
    this.filterMaxPrice,
    this.searchQuery,
    this.selectedListing,
    this.selectedPhotos,
    this.lastCreatedListing,
  });

  // Getters de conveniencia
  bool get isNearbyLoading => nearbyStatus == MarketplaceStatus.loading;
  bool get isMyListingsLoading => myListingsStatus == MarketplaceStatus.loading;
  bool get isFavoritesLoading => favoritesStatus == MarketplaceStatus.loading;
  bool get isNearbyEmpty => nearbyStatus == MarketplaceStatus.empty;
  bool get isMyListingsEmpty => myListingsStatus == MarketplaceStatus.empty;
  bool get hasError => errorMessage != null;
  bool get hasPhotosSelected => selectedPhotos != null && selectedPhotos!.isNotEmpty;
  int get photoCount => selectedPhotos?.length ?? 0;
  bool get isSubmitting => submissionStatus == SubmissionStatus.submitting;
  bool get isSubmissionSuccess => submissionStatus == SubmissionStatus.success;
  bool get isProcessingAction => actionStatus == ActionStatus.processing;
  bool get hasLocation => userLatitude != null && userLongitude != null;

  /// Anuncios cercanos ordenados por distancia
  List<MarketplaceListing> get sortedNearbyListings => nearbyListings;

  /// Anuncios de venta
  List<MarketplaceListing> get saleListings => nearbyListings
      .where((l) => l.listingType == ListingType.sale)
      .toList();

  /// Anuncios de intercambio
  List<MarketplaceListing> get tradeListings => nearbyListings
      .where((l) => l.listingType == ListingType.trade)
      .toList();

  /// Regalos
  List<MarketplaceListing> get giveawayListings => nearbyListings
      .where((l) => l.listingType == ListingType.giveaway)
      .toList();

  MarketplaceState copyWith({
    List<MarketplaceListing>? nearbyListings,
    List<MarketplaceListing>? myListings,
    List<MarketplaceListing>? favoriteListings,
    MarketplaceStatus? nearbyStatus,
    MarketplaceStatus? myListingsStatus,
    MarketplaceStatus? favoritesStatus,
    PhotoStatus? photoStatus,
    SubmissionStatus? submissionStatus,
    ActionStatus? actionStatus,
    String? errorMessage,
    MarketplaceTab? activeTab,
    double? userLatitude,
    double? userLongitude,
    double? filterRadiusKm,
    List<ListingCategory>? filterCategories,
    List<ListingType>? filterListingTypes,
    double? filterMaxPrice,
    String? searchQuery,
    MarketplaceListing? selectedListing,
    List<Uint8List>? selectedPhotos,
    MarketplaceListing? lastCreatedListing,
  }) {
    return MarketplaceState(
      nearbyListings: nearbyListings ?? this.nearbyListings,
      myListings: myListings ?? this.myListings,
      favoriteListings: favoriteListings ?? this.favoriteListings,
      nearbyStatus: nearbyStatus ?? this.nearbyStatus,
      myListingsStatus: myListingsStatus ?? this.myListingsStatus,
      favoritesStatus: favoritesStatus ?? this.favoritesStatus,
      photoStatus: photoStatus ?? this.photoStatus,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      actionStatus: actionStatus ?? this.actionStatus,
      errorMessage: errorMessage,
      activeTab: activeTab ?? this.activeTab,
      userLatitude: userLatitude ?? this.userLatitude,
      userLongitude: userLongitude ?? this.userLongitude,
      filterRadiusKm: filterRadiusKm ?? this.filterRadiusKm,
      filterCategories: filterCategories ?? this.filterCategories,
      filterListingTypes: filterListingTypes ?? this.filterListingTypes,
      filterMaxPrice: filterMaxPrice ?? this.filterMaxPrice,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedListing: selectedListing ?? this.selectedListing,
      selectedPhotos: selectedPhotos ?? this.selectedPhotos,
      lastCreatedListing: lastCreatedListing ?? this.lastCreatedListing,
    );
  }

  @override
  List<Object?> get props => [
        nearbyListings,
        myListings,
        favoriteListings,
        nearbyStatus,
        myListingsStatus,
        favoritesStatus,
        photoStatus,
        submissionStatus,
        actionStatus,
        errorMessage,
        activeTab,
        userLatitude,
        userLongitude,
        filterRadiusKm,
        filterCategories,
        filterListingTypes,
        filterMaxPrice,
        searchQuery,
        selectedListing,
        selectedPhotos,
        lastCreatedListing,
      ];
}
