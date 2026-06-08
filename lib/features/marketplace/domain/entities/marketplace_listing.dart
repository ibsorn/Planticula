import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show Icons, IconData;

/// Entidad MarketplaceListing - Representa un anuncio en el marketplace
///
/// Tipos de anuncio:
/// - venta: Con precio fijo
/// - intercambio: Sin precio, se intercambia por otra planta/esqueje
/// - regalo: Sin precio, se regala
///
/// Categorías:
/// - esqueje: Trozos de tallo para propagar
/// - planta: Planta completa en maceta
/// - sustrato: Tierra, compost, perlita, etc.
/// - herramienta: Tijeras, regaderas, soportes, etc.
class MarketplaceListing extends Equatable {
  final String id;
  final String sellerId;
  final String? sellerName; // Denormalizado para mostrar rápido

  // Información del producto
  final String title;
  final String description;
  final ListingCategory category;
  final List<String> photoUrls; // Múltiples fotos

  // Tipo de transacción
  final ListingType listingType; // sale / trade / giveaway
  final double? price; // EUR, null si es intercambio o regalo
  final String? tradeFor; // Si es intercambio, qué acepta a cambio

  // Ubicación (para búsqueda cercana)
  final double latitude;
  final double longitude;
  final String? locationName; // Ej: "Madrid Centro", "Barrio Salamanca"

  // Estado del anuncio
  final ListingStatus status; // active / reserved / sold / inactive
  final int viewCount;
  final int favoriteCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt; // Anuncios expiran después de X días

  // Datos calculados (no persistidos)
  final double? distanceKm;
  final bool? isFavorited;

  const MarketplaceListing({
    required this.id,
    required this.sellerId,
    this.sellerName,
    required this.title,
    required this.description,
    required this.category,
    this.photoUrls = const [],
    required this.listingType,
    this.price,
    this.tradeFor,
    required this.latitude,
    required this.longitude,
    this.locationName,
    this.status = ListingStatus.active,
    this.viewCount = 0,
    this.favoriteCount = 0,
    required this.createdAt,
    this.updatedAt,
    this.expiresAt,
    this.distanceKm,
    this.isFavorited,
  });

  MarketplaceListing copyWith({
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
    return MarketplaceListing(
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

  /// Crea anuncio para nuevo listado
  factory MarketplaceListing.create({
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
    return MarketplaceListing(
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
      expiresAt: DateTime.now().add(const Duration(days: 30)), // Expira en 30 días
    );
  }

  /// Formato del precio para mostrar
  String get priceDisplay {
    switch (listingType) {
      case ListingType.giveaway:
        return 'Regalo';
      case ListingType.trade:
        return tradeFor != null ? 'Intercambio por: $tradeFor' : 'Intercambio';
      case ListingType.sale:
        if (price != null) {
          return '${price!.toStringAsFixed(2)} €';
        }
        return 'Consultar precio';
    }
  }

  /// Badge de tipo de listado
  String get typeBadge {
    switch (listingType) {
      case ListingType.giveaway:
        return '🎁 Regalo';
      case ListingType.trade:
        return '🔄 Intercambio';
      case ListingType.sale:
        return price != null && price! > 0 ? '💰 Venta' : '💰 Consultar';
    }
  }

  /// Color del badge según tipo
  int get typeColor {
    switch (listingType) {
      case ListingType.giveaway:
        return 0xFF4CAF50; // Verde
      case ListingType.trade:
        return 0xFFFF9800; // Naranja
      case ListingType.sale:
        return 0xFF2196F3; // Azul
    }
  }

  /// Formato de distancia
  String? get distanceDisplay {
    if (distanceKm == null) return null;
    if (distanceKm! < 1) {
      return '${(distanceKm! * 1000).toStringAsFixed(0)} m';
    }
    return '${distanceKm!.toStringAsFixed(1)} km';
  }

  /// Indica si el anuncio es del usuario actual
  bool isOwnedBy(String userId) => sellerId == userId;

  /// Indica si está disponible para transacción
  bool get isAvailable => status == ListingStatus.active;

  /// Indica si ha expirado
  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());

  @override
  List<Object?> get props => [
        id,
        sellerId,
        sellerName,
        title,
        description,
        category,
        photoUrls,
        listingType,
        price,
        tradeFor,
        latitude,
        longitude,
        locationName,
        status,
        viewCount,
        favoriteCount,
        createdAt,
        updatedAt,
        expiresAt,
        distanceKm,
        isFavorited,
      ];
}

/// Categorías de productos en el marketplace
enum ListingCategory {
  cutting('Esqueje', 'Trozos de tallo para propagar', Icons.cut),
  plant('Planta', 'Planta completa en maceta', Icons.local_florist),
  substrate('Sustrato', 'Tierra, compost, perlita, vermiculita', Icons.landscape),
  tool('Herramienta', 'Tijeras, regaderas, soportes, macetas', Icons.build);

  final String displayName;
  final String description;
  final dynamic icon; // IconData

  const ListingCategory(this.displayName, this.description, this.icon);
}

/// Tipos de transacción
enum ListingType {
  sale('Venta', 'Precio fijo'),
  trade('Intercambio', 'Cambio por otra planta/esqueje'),
  giveaway('Regalo', 'Sin coste');

  final String displayName;
  final String description;

  const ListingType(this.displayName, this.description);
}

/// Estados del anuncio
enum ListingStatus {
  active('Activo', 'Disponible'),
  reserved('Reservado', 'Alguien está interesado'),
  sold('Vendido', 'Transacción completada'),
  inactive('Inactivo', 'Anuncio pausado o expirado');

  final String displayName;
  final String description;

  const ListingStatus(this.displayName, this.description);
}

// Extensiones para parsear enums
extension ListingCategoryExtension on String {
  ListingCategory toListingCategory() {
    return ListingCategory.values.firstWhere(
      (e) => e.name == this,
      orElse: () => ListingCategory.plant,
    );
  }
}

extension ListingTypeExtension on String {
  ListingType toListingType() {
    return ListingType.values.firstWhere(
      (e) => e.name == this,
      orElse: () => ListingType.sale,
    );
  }
}

extension ListingStatusExtension on String {
  ListingStatus toListingStatus() {
    return ListingStatus.values.firstWhere(
      (e) => e.name == this,
      orElse: () => ListingStatus.active,
    );
  }
}


