import 'package:flutter_test/flutter_test.dart';
import 'package:planticula/features/marketplace/data/models/marketplace_listing_model.dart';
import 'package:planticula/features/marketplace/domain/entities/marketplace_listing.dart';

void main() {
  group('MarketplaceListingModel.fromJson', () {
    test('parses a full JSON map', () {
      final json = {
        'id': 'ml-1',
        'seller_id': 'u-1',
        'seller_name': 'Juan',
        'title': 'Monstera esqueje',
        'description': 'Esqueje enraizado',
        'category': 'cutting',
        'photo_urls': ['https://example.com/img.jpg'],
        'listing_type': 'sale',
        'price': 15.50,
        'trade_for': null,
        'latitude': 40.4168,
        'longitude': -3.7038,
        'location_name': 'Madrid Centro',
        'status': 'active',
        'view_count': 10,
        'favorite_count': 3,
        'created_at': '2025-06-01T10:00:00.000Z',
        'updated_at': '2025-06-02T12:00:00.000Z',
        'expires_at': '2025-07-01T10:00:00.000Z',
        'distance_km': 2.5,
        'is_favorited': true,
      };

      final model = MarketplaceListingModel.fromJson(json);

      expect(model.id, equals('ml-1'));
      expect(model.sellerId, equals('u-1'));
      expect(model.sellerName, equals('Juan'));
      expect(model.title, equals('Monstera esqueje'));
      expect(model.category, ListingCategory.cutting);
      expect(model.photoUrls, hasLength(1));
      expect(model.listingType, ListingType.sale);
      expect(model.price, equals(15.50));
      expect(model.latitude, closeTo(40.4168, 0.001));
      expect(model.longitude, closeTo(-3.7038, 0.001));
      expect(model.status, ListingStatus.active);
      expect(model.viewCount, equals(10));
      expect(model.favoriteCount, equals(3));
      expect(model.createdAt, isNotNull);
      expect(model.updatedAt, isNotNull);
      expect(model.expiresAt, isNotNull);
      expect(model.distanceKm, equals(2.5));
      expect(model.isFavorited, isTrue);
    });

    test('uses defaults for missing optional fields', () {
      final json = {
        'id': 'ml-2',
        'seller_id': 'u-1',
        'title': 'Minimal',
        'description': 'Desc',
        'latitude': 40.0,
        'longitude': -3.0,
        'created_at': '2025-06-01T00:00:00.000Z',
      };

      final model = MarketplaceListingModel.fromJson(json);

      expect(model.category, ListingCategory.plant);
      expect(model.listingType, ListingType.sale);
      expect(model.photoUrls, isEmpty);
      expect(model.price, isNull);
      expect(model.status, ListingStatus.active);
      expect(model.viewCount, equals(0));
      expect(model.favoriteCount, equals(0));
      expect(model.updatedAt, isNull);
      expect(model.expiresAt, isNull);
      expect(model.distanceKm, isNull);
      expect(model.isFavorited, isNull);
    });
  });

  group('MarketplaceListingModel.toJson', () {
    test('serializes all fields', () {
      final now = DateTime.utc(2025, 6, 1);
      final model = MarketplaceListingModel(
        id: 'ml-1',
        sellerId: 'u-1',
        sellerName: 'Test',
        title: 'Test Listing',
        description: 'Desc',
        category: ListingCategory.tool,
        photoUrls: const ['url1', 'url2'],
        listingType: ListingType.trade,
        tradeFor: 'Something',
        latitude: 40.0,
        longitude: -3.0,
        locationName: 'Madrid',
        status: ListingStatus.reserved,
        viewCount: 5,
        favoriteCount: 2,
        createdAt: now,
        updatedAt: now,
        expiresAt: now.add(const Duration(days: 30)),
      );

      final json = model.toJson();

      expect(json['id'], equals('ml-1'));
      expect(json['seller_id'], equals('u-1'));
      expect(json['seller_name'], equals('Test'));
      expect(json['title'], equals('Test Listing'));
      expect(json['category'], equals('tool'));
      expect(json['photo_urls'], equals(['url1', 'url2']));
      expect(json['listing_type'], equals('trade'));
      expect(json['trade_for'], equals('Something'));
      expect(json['status'], equals('reserved'));
      expect(json['view_count'], equals(5));
      expect(json['created_at'], isNotNull);
    });
  });

  group('MarketplaceListingModel.fromDomain', () {
    test('converts entity to model', () {
      final now = DateTime(2025, 6, 1);
      final entity = MarketplaceListing(
        id: 'ml-1',
        sellerId: 'u-1',
        title: 'Entity',
        description: 'From domain',
        category: ListingCategory.substrate,
        listingType: ListingType.giveaway,
        latitude: 40.0,
        longitude: -3.0,
        createdAt: now,
      );

      final model = MarketplaceListingModel.fromDomain(entity);

      expect(model.id, equals(entity.id));
      expect(model.title, equals(entity.title));
      expect(model.category, equals(entity.category));
      expect(model.listingType, equals(entity.listingType));
      expect(model, isA<MarketplaceListingModel>());
    });
  });

  group('MarketplaceListingModel convenience methods', () {
    test('markAsSold changes status to sold', () {
      final now = DateTime(2025, 6, 1);
      final model = MarketplaceListingModel(
        id: 'ml-1',
        sellerId: 'u-1',
        title: 'Test',
        description: 'Desc',
        category: ListingCategory.plant,
        listingType: ListingType.sale,
        latitude: 40.0,
        longitude: -3.0,
        createdAt: now,
      );

      final sold = model.markAsSold();
      expect(sold.status, ListingStatus.sold);
    });

    test('markAsReserved changes status to reserved', () {
      final now = DateTime(2025, 6, 1);
      final model = MarketplaceListingModel(
        id: 'ml-1',
        sellerId: 'u-1',
        title: 'Test',
        description: 'Desc',
        category: ListingCategory.plant,
        listingType: ListingType.sale,
        latitude: 40.0,
        longitude: -3.0,
        createdAt: now,
      );

      final reserved = model.markAsReserved();
      expect(reserved.status, ListingStatus.reserved);
    });

    test('incrementViews increases viewCount by 1', () {
      final now = DateTime(2025, 6, 1);
      final model = MarketplaceListingModel(
        id: 'ml-1',
        sellerId: 'u-1',
        title: 'Test',
        description: 'Desc',
        category: ListingCategory.plant,
        listingType: ListingType.sale,
        latitude: 40.0,
        longitude: -3.0,
        createdAt: now,
        viewCount: 5,
      );

      final incremented = model.incrementViews();
      expect(incremented.viewCount, equals(6));
    });
  });

  group('CreateListingRequest', () {
    test('toJson serializes fields with seller info', () {
      const request = CreateListingRequest(
        title: 'Test',
        description: 'Desc',
        category: ListingCategory.cutting,
        listingType: ListingType.sale,
        price: 10.0,
        latitude: 40.0,
        longitude: -3.0,
        locationName: 'Madrid',
      );

      final json = request.toJson('u-1', 'Juan');

      expect(json['seller_id'], equals('u-1'));
      expect(json['seller_name'], equals('Juan'));
      expect(json['title'], equals('Test'));
      expect(json['category'], equals('cutting'));
      expect(json['listing_type'], equals('sale'));
      expect(json['price'], equals(10.0));
      expect(json['status'], equals('active'));
      expect(json['view_count'], equals(0));
      expect(json['favorite_count'], equals(0));
    });
  });

  group('NearbyListingsFilter', () {
    test('isValid returns true for valid filter', () {
      const filter = NearbyListingsFilter(
        latitude: 40.0,
        longitude: -3.0,
        radiusKm: 10.0,
      );
      expect(filter.isValid, isTrue);
    });

    test('isValid returns false for invalid latitude', () {
      const filter = NearbyListingsFilter(
        latitude: 91.0,
        longitude: -3.0,
      );
      expect(filter.isValid, isFalse);
    });

    test('isValid returns false for invalid longitude', () {
      const filter = NearbyListingsFilter(
        latitude: 40.0,
        longitude: 181.0,
      );
      expect(filter.isValid, isFalse);
    });

    test('isValid returns false for zero radius', () {
      const filter = NearbyListingsFilter(
        latitude: 40.0,
        longitude: -3.0,
        radiusKm: 0,
      );
      expect(filter.isValid, isFalse);
    });

    test('isValid returns false for limit > 100', () {
      const filter = NearbyListingsFilter(
        latitude: 40.0,
        longitude: -3.0,
        limit: 101,
      );
      expect(filter.isValid, isFalse);
    });
  });

  group('roundtrip', () {
    test('fromJson → toJson → fromJson produces equivalent model', () {
      final json = {
        'id': 'ml-rt',
        'seller_id': 'u-1',
        'seller_name': 'RT User',
        'title': 'Roundtrip',
        'description': 'Test',
        'category': 'tool',
        'photo_urls': <String>[],
        'listing_type': 'giveaway',
        'price': null,
        'trade_for': null,
        'latitude': 40.0,
        'longitude': -3.0,
        'location_name': 'Test',
        'status': 'active',
        'view_count': 0,
        'favorite_count': 0,
        'created_at': '2025-06-01T00:00:00.000Z',
        'updated_at': null,
        'expires_at': null,
      };

      final model1 = MarketplaceListingModel.fromJson(json);
      final serialized = model1.toJson();
      final model2 = MarketplaceListingModel.fromJson(serialized);

      expect(model1.id, equals(model2.id));
      expect(model1.title, equals(model2.title));
      expect(model1.category, equals(model2.category));
      expect(model1.listingType, equals(model2.listingType));
      expect(model1.latitude, equals(model2.latitude));
    });
  });
}
