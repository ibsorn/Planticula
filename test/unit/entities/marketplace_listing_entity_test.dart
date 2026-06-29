import 'package:flutter_test/flutter_test.dart';
import 'package:planticula/features/marketplace/domain/entities/marketplace_listing.dart';

void main() {
  final now = DateTime(2025, 6, 15, 12, 0);

  final saleListing = MarketplaceListing(
    id: 'ml-1',
    sellerId: 'u-1',
    sellerName: 'Juan',
    title: 'Monstera esqueje',
    description: 'Esqueje enraizado',
    category: ListingCategory.cutting,
    photoUrls: ['https://example.com/img1.jpg'],
    listingType: ListingType.sale,
    price: 15.50,
    latitude: 40.4168,
    longitude: -3.7038,
    locationName: 'Madrid Centro',
    status: ListingStatus.active,
    viewCount: 10,
    favoriteCount: 3,
    createdAt: now,
    expiresAt: now.add(const Duration(days: 30)),
    distanceKm: 2.5,
    isFavorited: true,
  );

  final tradeListing = MarketplaceListing(
    id: 'ml-2',
    sellerId: 'u-2',
    title: 'Pothos intercambio',
    description: 'Cambio por suculenta',
    category: ListingCategory.plant,
    listingType: ListingType.trade,
    tradeFor: 'Echeveria',
    latitude: 41.0,
    longitude: 2.0,
    createdAt: now,
  );

  final giveawayListing = MarketplaceListing(
    id: 'ml-3',
    sellerId: 'u-3',
    title: 'Sustrato gratis',
    description: 'Sobra sustrato',
    category: ListingCategory.substrate,
    listingType: ListingType.giveaway,
    latitude: 39.0,
    longitude: -1.0,
    createdAt: now,
  );

  group('MarketplaceListing.priceDisplay', () {
    test('sale with price shows formatted price', () {
      expect(saleListing.priceDisplay, equals('15.50 €'));
    });

    test('sale without price shows consultar', () {
      final noPriceListing = MarketplaceListing(
        id: 'x',
        sellerId: 'u',
        title: 'T',
        description: 'D',
        category: ListingCategory.plant,
        listingType: ListingType.sale,
        latitude: 0,
        longitude: 0,
        createdAt: now,
      );
      expect(noPriceListing.priceDisplay, equals('Consultar precio'));
    });

    test('trade with tradeFor shows trade info', () {
      expect(tradeListing.priceDisplay, equals('Intercambio por: Echeveria'));
    });

    test('trade without tradeFor shows generic text', () {
      final noTradeFor = MarketplaceListing(
        id: 'x',
        sellerId: 'u',
        title: 'T',
        description: 'D',
        category: ListingCategory.plant,
        listingType: ListingType.trade,
        latitude: 0,
        longitude: 0,
        createdAt: now,
      );
      expect(noTradeFor.priceDisplay, equals('Intercambio'));
    });

    test('giveaway shows Regalo', () {
      expect(giveawayListing.priceDisplay, equals('Regalo'));
    });
  });

  group('MarketplaceListing.typeBadge', () {
    test('sale with price > 0 shows Venta badge', () {
      expect(saleListing.typeBadge, contains('Venta'));
    });

    test('trade shows Intercambio badge', () {
      expect(tradeListing.typeBadge, contains('Intercambio'));
    });

    test('giveaway shows Regalo badge', () {
      expect(giveawayListing.typeBadge, contains('Regalo'));
    });
  });

  group('MarketplaceListing.typeColor', () {
    test('giveaway is green', () {
      expect(giveawayListing.typeColor, equals(0xFF4CAF50));
    });

    test('trade is orange', () {
      expect(tradeListing.typeColor, equals(0xFFFF9800));
    });

    test('sale is blue', () {
      expect(saleListing.typeColor, equals(0xFF2196F3));
    });
  });

  group('MarketplaceListing.distanceDisplay', () {
    test('returns km format for >= 1 km', () {
      expect(saleListing.distanceDisplay, equals('2.5 km'));
    });

    test('returns meters for < 1 km', () {
      final close = saleListing.copyWith(distanceKm: 0.35);
      expect(close.distanceDisplay, equals('350 m'));
    });

    test('returns null when distanceKm is null', () {
      expect(tradeListing.distanceDisplay, isNull);
    });
  });

  group('MarketplaceListing.isOwnedBy', () {
    test('returns true for matching userId', () {
      expect(saleListing.isOwnedBy('u-1'), isTrue);
    });

    test('returns false for different userId', () {
      expect(saleListing.isOwnedBy('u-999'), isFalse);
    });
  });

  group('MarketplaceListing.isAvailable', () {
    test('returns true for active status', () {
      expect(saleListing.isAvailable, isTrue);
    });

    test('returns false for sold status', () {
      final sold = saleListing.copyWith(status: ListingStatus.sold);
      expect(sold.isAvailable, isFalse);
    });

    test('returns false for reserved status', () {
      final reserved = saleListing.copyWith(status: ListingStatus.reserved);
      expect(reserved.isAvailable, isFalse);
    });
  });

  group('MarketplaceListing.isExpired', () {
    test('returns true when expiresAt is in the past', () {
      final expired = saleListing.copyWith(
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(expired.isExpired, isTrue);
    });

    test('returns false when expiresAt is in the future', () {
      final future = saleListing.copyWith(
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
      expect(future.isExpired, isFalse);
    });

    test('returns false when expiresAt is null', () {
      expect(tradeListing.isExpired, isFalse);
    });
  });

  group('MarketplaceListing.copyWith', () {
    test('preserves unchanged fields', () {
      final copy = saleListing.copyWith(title: 'New Title');
      expect(copy.title, equals('New Title'));
      expect(copy.id, equals(saleListing.id));
      expect(copy.price, equals(saleListing.price));
      expect(copy.sellerId, equals(saleListing.sellerId));
    });
  });

  group('MarketplaceListing.create', () {
    test('creates listing with empty id and expiration in 30 days', () {
      final listing = MarketplaceListing.create(
        sellerId: 'u-1',
        title: 'New Listing',
        description: 'Fresh listing',
        category: ListingCategory.tool,
        listingType: ListingType.sale,
        price: 25.0,
        latitude: 40.0,
        longitude: -3.0,
      );

      expect(listing.id, isEmpty);
      expect(listing.sellerId, equals('u-1'));
      expect(listing.title, equals('New Listing'));
      expect(listing.category, ListingCategory.tool);
      expect(listing.price, equals(25.0));
      expect(listing.expiresAt, isNotNull);
      expect(
        listing.expiresAt!.difference(listing.createdAt).inDays,
        equals(30),
      );
    });
  });

  group('Enum extensions', () {
    test('toListingCategory parses valid string', () {
      expect('cutting'.toListingCategory(), ListingCategory.cutting);
      expect('plant'.toListingCategory(), ListingCategory.plant);
      expect('substrate'.toListingCategory(), ListingCategory.substrate);
      expect('tool'.toListingCategory(), ListingCategory.tool);
    });

    test('toListingCategory defaults to plant for unknown', () {
      expect('unknown'.toListingCategory(), ListingCategory.plant);
    });

    test('toListingType parses valid string', () {
      expect('sale'.toListingType(), ListingType.sale);
      expect('trade'.toListingType(), ListingType.trade);
      expect('giveaway'.toListingType(), ListingType.giveaway);
    });

    test('toListingType defaults to sale for unknown', () {
      expect('unknown'.toListingType(), ListingType.sale);
    });

    test('toListingStatus parses valid string', () {
      expect('active'.toListingStatus(), ListingStatus.active);
      expect('reserved'.toListingStatus(), ListingStatus.reserved);
      expect('sold'.toListingStatus(), ListingStatus.sold);
      expect('inactive'.toListingStatus(), ListingStatus.inactive);
    });

    test('toListingStatus defaults to active for unknown', () {
      expect('unknown'.toListingStatus(), ListingStatus.active);
    });
  });

  group('Equatable', () {
    test('same data are equal', () {
      final copy = saleListing.copyWith();
      expect(saleListing, equals(copy));
    });

    test('different data are not equal', () {
      final other = saleListing.copyWith(title: 'Different');
      expect(saleListing, isNot(equals(other)));
    });
  });
}
