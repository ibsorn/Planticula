import 'package:flutter_test/flutter_test.dart';
import 'package:planticula/features/pest_alerts/domain/entities/pest_alert.dart';

void main() {
  final now = DateTime(2025, 6, 15, 12, 0);

  final alert = PestAlert(
    id: 'pa-1',
    userId: 'u-1',
    photoUrl: 'https://example.com/pest.jpg',
    pestType: PestType.aphids,
    severity: Severity.high,
    latitude: 40.4168,
    longitude: -3.7038,
    locationName: 'Mi jardín',
    notes: 'Detected on tomatoes',
    reportedAt: now,
    status: AlertStatus.active,
    confirmedByCount: 3,
    isResolved: false,
    distanceKm: 1.5,
  );

  group('PestAlert.pestTypeDisplay', () {
    test('returns displayName for non-other type', () {
      expect(alert.pestTypeDisplay, equals('Pulgón'));
    });

    test('returns customPestName for other type', () {
      final custom = alert.copyWith(
        pestType: PestType.other,
        customPestName: 'Polilla rara',
      );
      expect(custom.pestTypeDisplay, equals('Polilla rara'));
    });

    test('returns Otra when other type and no custom name', () {
      final other = PestAlert(
        id: 'x',
        userId: 'u',
        pestType: PestType.other,
        severity: Severity.low,
        latitude: 0,
        longitude: 0,
        reportedAt: now,
      );
      expect(other.pestTypeDisplay, equals('Otra'));
    });
  });

  group('PestAlert.locationDisplay', () {
    test('returns locationName when present', () {
      expect(alert.locationDisplay, equals('Mi jardín'));
    });

    test('returns lat/lng when locationName is null', () {
      final noLoc = PestAlert(
        id: 'x',
        userId: 'u',
        pestType: PestType.aphids,
        severity: Severity.low,
        latitude: 40.4168,
        longitude: -3.7038,
        reportedAt: now,
      );
      expect(noLoc.locationDisplay, contains('40.4168'));
      expect(noLoc.locationDisplay, contains('-3.7038'));
    });

    test('returns lat/lng when locationName is empty', () {
      final emptyLoc = alert.copyWith(locationName: '');
      expect(emptyLoc.locationDisplay, contains('40.4168'));
    });
  });

  group('PestAlert.distanceDisplay', () {
    test('returns km format for >= 1 km', () {
      expect(alert.distanceDisplay, equals('1.5 km'));
    });

    test('returns meters for < 1 km', () {
      final close = alert.copyWith(distanceKm: 0.25);
      expect(close.distanceDisplay, equals('250 m'));
    });

    test('returns null when distanceKm is null', () {
      final noDistance = PestAlert(
        id: 'x',
        userId: 'u',
        pestType: PestType.aphids,
        severity: Severity.low,
        latitude: 0,
        longitude: 0,
        reportedAt: now,
      );
      expect(noDistance.distanceDisplay, isNull);
    });
  });

  group('PestAlert.isOwnedBy', () {
    test('returns true for matching userId', () {
      expect(alert.isOwnedBy('u-1'), isTrue);
    });

    test('returns false for different userId', () {
      expect(alert.isOwnedBy('u-999'), isFalse);
    });
  });

  group('PestAlert.canBeConfirmedBy', () {
    test('returns true for different user on active non-resolved alert', () {
      expect(alert.canBeConfirmedBy('u-2'), isTrue);
    });

    test('returns false for own alert', () {
      expect(alert.canBeConfirmedBy('u-1'), isFalse);
    });

    test('returns false when alert is resolved', () {
      final resolved = alert.copyWith(isResolved: true);
      expect(resolved.canBeConfirmedBy('u-2'), isFalse);
    });

    test('returns false when alert status is not active', () {
      final underReview = alert.copyWith(status: AlertStatus.underReview);
      expect(underReview.canBeConfirmedBy('u-2'), isFalse);
    });
  });

  group('PestAlert.create factory', () {
    test('creates alert with empty id and current timestamp', () {
      final created = PestAlert.create(
        userId: 'u-1',
        pestType: PestType.mealybugs,
        severity: Severity.medium,
        latitude: 40.0,
        longitude: -3.0,
        notes: 'Found on succulent',
      );

      expect(created.id, isEmpty);
      expect(created.userId, equals('u-1'));
      expect(created.pestType, PestType.mealybugs);
      expect(created.severity, Severity.medium);
      expect(created.notes, equals('Found on succulent'));
      expect(created.status, AlertStatus.active);
      expect(created.isResolved, isFalse);
    });
  });

  group('PestAlert.copyWith', () {
    test('preserves unchanged fields', () {
      final copy = alert.copyWith(notes: 'Updated notes');
      expect(copy.notes, equals('Updated notes'));
      expect(copy.id, equals(alert.id));
      expect(copy.pestType, equals(alert.pestType));
      expect(copy.severity, equals(alert.severity));
      expect(copy.latitude, equals(alert.latitude));
    });
  });

  group('Equatable', () {
    test('same data are equal', () {
      final copy = alert.copyWith();
      expect(alert, equals(copy));
    });

    test('different data are not equal', () {
      final other = alert.copyWith(severity: Severity.low);
      expect(alert, isNot(equals(other)));
    });
  });

  group('Enum extensions', () {
    test('toPestType parses valid string', () {
      expect('aphids'.toPestType(), PestType.aphids);
      expect('mealybugs'.toPestType(), PestType.mealybugs);
      expect('rootRot'.toPestType(), PestType.rootRot);
    });

    test('toPestType defaults to other for unknown', () {
      expect('unknown'.toPestType(), PestType.other);
    });

    test('toSeverity parses valid string', () {
      expect('low'.toSeverity(), Severity.low);
      expect('medium'.toSeverity(), Severity.medium);
      expect('high'.toSeverity(), Severity.high);
      expect('critical'.toSeverity(), Severity.critical);
    });

    test('toSeverity defaults to medium for unknown', () {
      expect('unknown'.toSeverity(), Severity.medium);
    });

    test('toAlertStatus parses valid string', () {
      expect('active'.toAlertStatus(), AlertStatus.active);
      expect('resolved'.toAlertStatus(), AlertStatus.resolved);
      expect('falsePositive'.toAlertStatus(), AlertStatus.falsePositive);
    });

    test('toAlertStatus defaults to active for unknown', () {
      expect('unknown'.toAlertStatus(), AlertStatus.active);
    });
  });

  group('Enum properties', () {
    test('PestType has displayName and description', () {
      expect(PestType.aphids.displayName, equals('Pulgón'));
      expect(PestType.aphids.description, isNotEmpty);
    });

    test('Severity has displayName, description, and colorValue', () {
      expect(Severity.high.displayName, equals('Alta'));
      expect(Severity.high.colorValue, equals(0xFFF44336));
    });

    test('AlertStatus has displayName and description', () {
      expect(AlertStatus.active.displayName, equals('Activa'));
      expect(AlertStatus.resolved.displayName, equals('Resuelta'));
    });
  });
}
