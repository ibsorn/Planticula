import 'package:planticula/features/marketplace/domain/entities/marketplace_listing.dart';

/// Modelo de datos para MarketplaceListing - Mapeo con tabla Supabase
///
/// Tabla: marketplace_listings
class MarketplaceListingModel extends MarketplaceListing {
  const MarketplaceListingModel({
    required super.id,
    required super.sellerId,
    super.sellerName,
    required super.title,
    required super.description,
    required super.category,
    super.photoUrls = const [],
    required super.listingType,
    super.price,
    super.tradeFor,
    required super.latitude,
    required super.longitude,
    super.locationName,
    super.status = ListingStatus.active,
    super.viewCount = 0,
    super.favoriteCount = 0,
    required super.createdAt,
    super.updatedAt,
    super.expiresAt,
    super.distanceKm,
    super.isFavorited,
  });

  /// Crea modelo desde JSON de Supabase
  factory MarketplaceListingModel.fromJson(Map<String, dynamic> json) {
    return MarketplaceListingModel(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String,
      sellerName: json['seller_name'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      category: (json['category'] as String?)?.toListingCategory() ?? ListingCategory.plant,
      photoUrls: (json['photo_urls'] as List<dynamic>?)?.cast<String>() ?? [],
      listingType: (json['listing_type'] as String?)?.toListingType() ?? ListingType.sale,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      tradeFor: json['trade_for'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      locationName: json['location_name'] as String?,
      status: (json['status'] as String?)?.toListingStatus() ?? ListingStatus.active,
      viewCount: json['view_count'] as int? ?? 0,
      favoriteCount: json['favorite_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      distanceKm: json['distance_km'] != null
          ? (json['distance_km'] as num).toDouble()
          : null,
      isFavorited: json['is_favorited'] as bool?,
    );
  }

  /// Convierte a JSON para enviar a Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      'seller_name': sellerName,
      'title': title,
      'description': description,
      'category': category.name,
      'photo_urls': photoUrls,
      'listing_type': listingType.name,
      'price': price,
      'trade_for': tradeFor,
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
      'status': status.name,
      'view_count': viewCount,
      'favorite_count': favoriteCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  /// Crea modelo desde entidad de dominio
  factory MarketplaceListingModel.fromDomain(MarketplaceListing listing) {
    return MarketplaceListingModel(
      id: listing.id,
      sellerId: listing.sellerId,
      sellerName: listing.sellerName,
      title: listing.title,
      description: listing.description,
      category: listing.category,
      photoUrls: listing.photoUrls,
      listingType: listing.listingType,
      price: listing.price,
      tradeFor: listing.tradeFor,
      latitude: listing.latitude,
      longitude: listing.longitude,
      locationName: listing.locationName,
      status: listing.status,
      viewCount: listing.viewCount,
      favoriteCount: listing.favoriteCount,
      createdAt: listing.createdAt,
      updatedAt: listing.updatedAt,
      expiresAt: listing.expiresAt,
      distanceKm: listing.distanceKm,
      isFavorited: listing.isFavorited,
    );
  }

  /// Crea modelo para nuevo anuncio
  factory MarketplaceListingModel.create({
    required String sellerId,
    String? sellerName,
    required String title,
    required String description,
    required ListingCategory category,
    List<String>? photoUrls,
    required ListingType listingType,
    double? price,
    String? tradeFor,
    required double latitude,
    required double longitude,
    String? locationName,
  }) {
    return MarketplaceListingModel(
      id: '', // Se genera en BD
      sellerId: sellerId,
      sellerName: sellerName,
      title: title,
      description: description,
      category: category,
      photoUrls: photoUrls ?? [],
      listingType: listingType,
      price: price,
      tradeFor: tradeFor,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );
  }

  MarketplaceListingModel copyWithModel({
    String? id,
    String? sellerId,
    String? sellerName,
    String? title,
    String? description,
    ListingCategory? category,
    List<String>? photoUrls,
    ListingType? listingType,
    double? price,
    String? tradeFor,
    double? latitude,
    double? longitude,
    String? locationName,
    ListingStatus? status,
    int? viewCount,
    int? favoriteCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
    double? distanceKm,
    bool? isFavorited,
  }) {
    return MarketplaceListingModel(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      photoUrls: photoUrls ?? this.photoUrls,
      listingType: listingType ?? this.listingType,
      price: price ?? this.price,
      tradeFor: tradeFor ?? this.tradeFor,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      status: status ?? this.status,
      viewCount: viewCount ?? this.viewCount,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      distanceKm: distanceKm ?? this.distanceKm,
      isFavorited: isFavorited ?? this.isFavorited,
    );
  }

  /// Marca como vendido/intercambiado
  MarketplaceListingModel markAsSold() {
    return copyWithModel(
      status: ListingStatus.sold,
    );
  }

  /// Marca como reservado
  MarketplaceListingModel markAsReserved() {
    return copyWithModel(
      status: ListingStatus.reserved,
    );
  }

  /// Incrementa contador de vistas
  MarketplaceListingModel incrementViews() {
    return copyWithModel(
      viewCount: viewCount + 1,
    );
  }
}

/// Request para crear anuncio
class CreateListingRequest {
  final String title;
  final String description;
  final ListingCategory category;
  final List<String>? photoUrls;
  final ListingType listingType;
  final double? price;
  final String? tradeFor;
  final double latitude;
  final double longitude;
  final String? locationName;

  const CreateListingRequest({
    required this.title,
    required this.description,
    required this.category,
    this.photoUrls,
    required this.listingType,
    this.price,
    this.tradeFor,
    required this.latitude,
    required this.longitude,
    this.locationName,
  });

  Map<String, dynamic> toJson(String sellerId, String? sellerName) {
    return {
      'seller_id': sellerId,
      'seller_name': sellerName,
      'title': title,
      'description': description,
      'category': category.name,
      'photo_urls': photoUrls ?? [],
      'listing_type': listingType.name,
      'price': price,
      'trade_for': tradeFor,
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
      'status': ListingStatus.active.name,
      'view_count': 0,
      'favorite_count': 0,
    };
  }
}

/// Filtros para consultar anuncios cercanos
class NearbyListingsFilter {
  final double latitude;
  final double longitude;
  final double radiusKm;
  final List<ListingCategory>? categories;
  final List<ListingType>? listingTypes;
  final double? maxPrice;
  final String? searchQuery;
  final bool includeSold;
  final int limit;
  final int offset;

  const NearbyListingsFilter({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 10.0,
    this.categories,
    this.listingTypes,
    this.maxPrice,
    this.searchQuery,
    this.includeSold = false,
    this.limit = 50,
    this.offset = 0,
  });

  bool get isValid {
    return latitude >= -90 && latitude <= 90 &&
           longitude >= -180 && longitude <= 180 &&
           radiusKm > 0 &&
           limit > 0 && limit <= 100;
  }
}
