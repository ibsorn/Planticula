import 'package:flutter_test/flutter_test.dart';
import 'package:planticula/features/pest_alerts/data/models/pest_alert_model.dart';
import 'package:planticula/features/pest_alerts/domain/entities/pest_alert.dart';

void main() {
  group('PestAlertModel.fromJson', () {
    test('parses a full JSON map', () {
      final json = {
        'id': 'pa-1',
        'user_id': 'u-1',
        'photo_url': 'https://example.com/pest.jpg',
        'pest_type': 'aphids',
        'custom_pest_name': null,
        'severity': 'high',
        'latitude': 40.4168,
        'longitude': -3.7038,
        'location_name': 'Mi jardín',
        'notes': 'On tomatoes',
        'reported_at': '2025-06-01T10:00:00.000Z',
        'updated_at': '2025-06-02T12:00:00.000Z',
        'status': 'active',
        'confirmed_by_count': 5,
        'is_resolved': false,
        'resolved_at': null,
        'distance_km': 2.3,
      };

      final model = PestAlertModel.fromJson(json);

      expect(model.id, equals('pa-1'));
      expect(model.userId, equals('u-1'));
      expect(model.photoUrl, equals('https://example.com/pest.jpg'));
      expect(model.pestType, PestType.aphids);
      expect(model.customPestName, isNull);
      expect(model.severity, Severity.high);
      expect(model.latitude, closeTo(40.4168, 0.001));
      expect(model.longitude, closeTo(-3.7038, 0.001));
      expect(model.locationName, equals('Mi jardín'));
      expect(model.notes, equals('On tomatoes'));
      expect(model.reportedAt, isNotNull);
      expect(model.updatedAt, isNotNull);
      expect(model.status, AlertStatus.active);
      expect(model.confirmedByCount, equals(5));
      expect(model.isResolved, isFalse);
      expect(model.resolvedAt, isNull);
      expect(model.distanceKm, equals(2.3));
    });

    test('uses defaults for missing optional fields', () {
      final json = {
        'id': 'pa-2',
        'user_id': 'u-1',
        'latitude': 40.0,
        'longitude': -3.0,
      };

      final model = PestAlertModel.fromJson(json);

      expect(model.pestType, PestType.other);
      expect(model.severity, Severity.medium);
      expect(model.status, AlertStatus.active);
      expect(model.isResolved, isFalse);
      expect(model.photoUrl, isNull);
      expect(model.notes, isNull);
      expect(model.confirmedByCount, isNull);
      expect(model.resolvedAt, isNull);
      expect(model.distanceKm, isNull);
    });

    test('parses resolved alert with resolvedAt', () {
      final json = {
        'id': 'pa-3',
        'user_id': 'u-1',
        'pest_type': 'mold',
        'severity': 'critical',
        'latitude': 40.0,
        'longitude': -3.0,
        'reported_at': '2025-06-01T00:00:00.000Z',
        'status': 'resolved',
        'is_resolved': true,
        'resolved_at': '2025-06-05T00:00:00.000Z',
      };

      final model = PestAlertModel.fromJson(json);

      expect(model.pestType, PestType.mold);
      expect(model.severity, Severity.critical);
      expect(model.status, AlertStatus.resolved);
      expect(model.isResolved, isTrue);
      expect(model.resolvedAt, isNotNull);
    });
  });

  group('PestAlertModel.toJson', () {
    test('serializes all fields', () {
      final now = DateTime.utc(2025, 6, 1);
      final model = PestAlertModel(
        id: 'pa-1',
        userId: 'u-1',
        photoUrl: 'https://img.com/pest.jpg',
        pestType: PestType.whiteflies,
        customPestName: null,
        severity: Severity.medium,
        latitude: 40.0,
        longitude: -3.0,
        locationName: 'Garden',
        notes: 'Notes here',
        reportedAt: now,
        updatedAt: now,
        status: AlertStatus.active,
        confirmedByCount: 2,
        isResolved: false,
      );

      final json = model.toJson();

      expect(json['id'], equals('pa-1'));
      expect(json['user_id'], equals('u-1'));
      expect(json['photo_url'], equals('https://img.com/pest.jpg'));
      expect(json['pest_type'], equals('whiteflies'));
      expect(json['severity'], equals('medium'));
      expect(json['latitude'], equals(40.0));
      expect(json['longitude'], equals(-3.0));
      expect(json['status'], equals('active'));
      expect(json['confirmed_by_count'], equals(2));
      expect(json['is_resolved'], isFalse);
      expect(json['reported_at'], isNotNull);
    });
  });

  group('PestAlertModel.fromDomain', () {
    test('converts PestAlert entity to model', () {
      final now = DateTime(2025, 6, 1);
      final entity = PestAlert(
        id: 'pa-1',
        userId: 'u-1',
        pestType: PestType.caterpillars,
        severity: Severity.low,
        latitude: 40.0,
        longitude: -3.0,
        reportedAt: now,
      );

      final model = PestAlertModel.fromDomain(entity);

      expect(model.id, equals(entity.id));
      expect(model.pestType, equals(entity.pestType));
      expect(model.severity, equals(entity.severity));
      expect(model, isA<PestAlertModel>());
    });
  });

  group('PestAlertModel convenience methods', () {
    test('markAsResolved sets status, isResolved, and resolvedAt', () {
      final now = DateTime(2025, 6, 1);
      final model = PestAlertModel(
        id: 'pa-1',
        userId: 'u-1',
        pestType: PestType.aphids,
        severity: Severity.high,
        latitude: 40.0,
        longitude: -3.0,
        reportedAt: now,
      );

      final resolved = model.markAsResolved();

      expect(resolved.status, AlertStatus.resolved);
      expect(resolved.isResolved, isTrue);
      expect(resolved.resolvedAt, isNotNull);
    });

    test('incrementConfirmations increases count by 1', () {
      final now = DateTime(2025, 6, 1);
      final model = PestAlertModel(
        id: 'pa-1',
        userId: 'u-1',
        pestType: PestType.aphids,
        severity: Severity.high,
        latitude: 40.0,
        longitude: -3.0,
        reportedAt: now,
        confirmedByCount: 3,
      );

      final incremented = model.incrementConfirmations();
      expect(incremented.confirmedByCount, equals(4));
    });

    test('incrementConfirmations handles null count', () {
      final now = DateTime(2025, 6, 1);
      final model = PestAlertModel(
        id: 'pa-1',
        userId: 'u-1',
        pestType: PestType.aphids,
        severity: Severity.high,
        latitude: 40.0,
        longitude: -3.0,
        reportedAt: now,
      );

      final incremented = model.incrementConfirmations();
      expect(incremented.confirmedByCount, equals(1));
    });
  });

  group('CreatePestAlertRequest', () {
    test('toJson serializes fields with userId', () {
      const request = CreatePestAlertRequest(
        pestType: PestType.mealybugs,
        severity: Severity.medium,
        latitude: 40.0,
        longitude: -3.0,
        locationName: 'Garden',
        notes: 'Found on leaves',
      );

      final json = request.toJson('u-1');

      expect(json['user_id'], equals('u-1'));
      expect(json['pest_type'], equals('mealybugs'));
      expect(json['severity'], equals('medium'));
      expect(json['latitude'], equals(40.0));
      expect(json['status'], equals('active'));
      expect(json['confirmed_by_count'], equals(0));
      expect(json['is_resolved'], isFalse);
    });
  });

  group('NearbyAlertsFilter', () {
    test('isValid returns true for valid filter', () {
      const filter = NearbyAlertsFilter(latitude: 40.0, longitude: -3.0);
      expect(filter.isValid, isTrue);
    });

    test('isValid returns false for out-of-range lat', () {
      const filter = NearbyAlertsFilter(latitude: 91.0, longitude: -3.0);
      expect(filter.isValid, isFalse);
    });

    test('isValid returns false for out-of-range lng', () {
      const filter = NearbyAlertsFilter(latitude: 40.0, longitude: -181.0);
      expect(filter.isValid, isFalse);
    });

    test('isValid returns false for zero radius', () {
      const filter = NearbyAlertsFilter(
        latitude: 40.0,
        longitude: -3.0,
        radiusKm: 0,
      );
      expect(filter.isValid, isFalse);
    });

    test('isValid returns false for limit > 100', () {
      const filter = NearbyAlertsFilter(
        latitude: 40.0,
        longitude: -3.0,
        limit: 200,
      );
      expect(filter.isValid, isFalse);
    });

    test('toQueryParams includes all fields', () {
      const filter = NearbyAlertsFilter(
        latitude: 40.0,
        longitude: -3.0,
        radiusKm: 5.0,
        daysLimit: 7,
        pestTypes: [PestType.aphids, PestType.mold],
        severities: [Severity.high],
        includeResolved: true,
        limit: 25,
        offset: 10,
      );

      final params = filter.toQueryParams();

      expect(params['lat'], equals(40.0));
      expect(params['lng'], equals(-3.0));
      expect(params['radius_km'], equals(5.0));
      expect(params['days'], equals(7));
      expect(params['pest_types'], equals(['aphids', 'mold']));
      expect(params['severities'], equals(['high']));
      expect(params['include_resolved'], isTrue);
      expect(params['limit'], equals(25));
      expect(params['offset'], equals(10));
    });
  });

  group('roundtrip', () {
    test('fromJson → toJson → fromJson produces equivalent model', () {
      final json = {
        'id': 'pa-rt',
        'user_id': 'u-1',
        'photo_url': 'https://example.com/rt.jpg',
        'pest_type': 'snails',
        'custom_pest_name': null,
        'severity': 'low',
        'latitude': 41.0,
        'longitude': 2.0,
        'location_name': 'Barcelona',
        'notes': 'In the garden',
        'reported_at': '2025-06-01T00:00:00.000Z',
        'updated_at': null,
        'status': 'active',
        'confirmed_by_count': 0,
        'is_resolved': false,
        'resolved_at': null,
      };

      final model1 = PestAlertModel.fromJson(json);
      final serialized = model1.toJson();
      final model2 = PestAlertModel.fromJson(serialized);

      expect(model1.id, equals(model2.id));
      expect(model1.pestType, equals(model2.pestType));
      expect(model1.severity, equals(model2.severity));
      expect(model1.latitude, equals(model2.latitude));
      expect(model1.status, equals(model2.status));
      expect(model1.isResolved, equals(model2.isResolved));
    });
  });
}
