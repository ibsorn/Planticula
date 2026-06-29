import 'package:flutter_test/flutter_test.dart';
import 'package:planticula/features/gardens/domain/entities/garden.dart';
import 'package:planticula/features/gardens/domain/entities/garden_group.dart';

void main() {
  group('GardenType', () {
    test('displayName returns localized labels', () {
      expect(GardenType.personal.displayName, equals('Personal'));
      expect(GardenType.balcony.displayName, equals('Balcón'));
      expect(GardenType.greenhouse.displayName, equals('Invernadero'));
      expect(GardenType.indoor.displayName, equals('Interior'));
      expect(GardenType.outdoor.displayName, equals('Exterior'));
      expect(GardenType.allotment.displayName, equals('Huerto'));
      expect(GardenType.other.displayName, equals('Otro'));
    });

    test('defaultIcon returns a valid string key per type', () {
      expect(GardenType.personal.defaultIcon, equals('garden'));
      expect(GardenType.balcony.defaultIcon, equals('balcony'));
      expect(GardenType.greenhouse.defaultIcon, equals('greenhouse'));
      expect(GardenType.allotment.defaultIcon, equals('vegetable'));
    });

    test('fromString parses known values', () {
      expect(GardenType.fromString('greenhouse'), GardenType.greenhouse);
      expect(GardenType.fromString('indoor'), GardenType.indoor);
    });

    test('fromString falls back to personal for unknown value', () {
      expect(GardenType.fromString('unknown'), GardenType.personal);
      expect(GardenType.fromString(null), GardenType.personal);
    });
  });

  group('GardenIcon', () {
    test('fromString parses known values', () {
      expect(GardenIcon.fromString('flower'), GardenIcon.flower);
      expect(GardenIcon.fromString('herb'), GardenIcon.herb);
    });

    test('fromString falls back to garden for unknown value', () {
      expect(GardenIcon.fromString('spaceship'), GardenIcon.garden);
      expect(GardenIcon.fromString(null), GardenIcon.garden);
    });
  });

  group('Garden', () {
    final now = DateTime(2025, 6, 1, 12, 0);

    final garden = Garden(
      id: 'g-1',
      userId: 'u-1',
      name: 'Mi Terraza',
      description: 'Plantas en la terraza',
      icon: 'terrace',
      color: '#FF5722',
      type: GardenType.terrace,
      isDefault: false,
      sortOrder: 2,
      plantCount: 5,
      groupCount: 2,
      createdAt: now,
      updatedAt: now,
    );

    test('displayName returns name', () {
      expect(garden.displayName, equals('Mi Terraza'));
    });

    test('colorValue parses hex color to int with FF alpha', () {
      expect(garden.colorValue, equals(0xFFFF5722));
    });

    test('colorValue handles default green color', () {
      const defaultGarden = Garden(
        id: 'g-2',
        userId: 'u-1',
        name: 'Default',
      );
      expect(defaultGarden.colorValue, equals(0xFF4CAF50));
    });

    test('gardenIcon parses icon string', () {
      expect(garden.gardenIcon, GardenIcon.terrace);
    });

    test('gardenIcon returns garden for unknown icon string', () {
      final g = garden.copyWith(icon: 'nonexistent');
      expect(g.gardenIcon, GardenIcon.garden);
    });

    test('copyWith preserves unchanged fields', () {
      final copy = garden.copyWith(name: 'Nuevo Nombre');
      expect(copy.name, equals('Nuevo Nombre'));
      expect(copy.id, equals(garden.id));
      expect(copy.userId, equals(garden.userId));
      expect(copy.color, equals(garden.color));
      expect(copy.type, equals(garden.type));
      expect(copy.plantCount, equals(garden.plantCount));
    });

    test('copyWith can change all fields', () {
      final copy = garden.copyWith(
        id: 'g-new',
        userId: 'u-new',
        description: 'New desc',
        icon: 'flower',
        color: '#000000',
        type: GardenType.greenhouse,
        isDefault: true,
        sortOrder: 0,
        plantCount: 10,
        groupCount: 3,
      );
      expect(copy.id, equals('g-new'));
      expect(copy.type, GardenType.greenhouse);
      expect(copy.isDefault, isTrue);
      expect(copy.plantCount, equals(10));
    });

    test('Equatable: same props are equal', () {
      final copy = garden.copyWith();
      expect(garden, equals(copy));
    });

    test('Equatable: different props are not equal', () {
      final other = garden.copyWith(name: 'Different');
      expect(garden, isNot(equals(other)));
    });

    test('default constructor values', () {
      const g = Garden(id: 'x', userId: 'u', name: 'Test');
      expect(g.icon, equals('garden'));
      expect(g.color, equals('#4CAF50'));
      expect(g.type, GardenType.personal);
      expect(g.isDefault, isFalse);
      expect(g.sortOrder, equals(0));
      expect(g.plantCount, equals(0));
      expect(g.groupCount, equals(0));
      expect(g.description, isNull);
      expect(g.createdAt, isNull);
      expect(g.updatedAt, isNull);
    });
  });

  group('GardenGroup', () {
    final now = DateTime(2025, 6, 1, 12, 0);

    final group = GardenGroup(
      id: 'gg-1',
      gardenId: 'g-1',
      userId: 'u-1',
      name: 'Tomates',
      description: 'Zona de tomates',
      icon: 'vegetable',
      color: '#F44336',
      sortOrder: 1,
      plantCount: 3,
      createdAt: now,
      updatedAt: now,
    );

    test('displayName returns name', () {
      expect(group.displayName, equals('Tomates'));
    });

    test('colorValue parses hex color', () {
      expect(group.colorValue, equals(0xFFF44336));
    });

    test('colorValue returns null when color is null', () {
      // copyWith doesn't clear color since it uses ?? operator,
      // so create a group without color directly
      const noColorGroup = GardenGroup(
        id: 'gg-2',
        gardenId: 'g-1',
        userId: 'u-1',
        name: 'No Color',
      );
      expect(noColorGroup.colorValue, isNull);
    });

    test('copyWith preserves unchanged fields', () {
      final copy = group.copyWith(name: 'Cherry Tomatoes');
      expect(copy.name, equals('Cherry Tomatoes'));
      expect(copy.gardenId, equals(group.gardenId));
      expect(copy.plantCount, equals(group.plantCount));
    });

    test('Equatable: same props are equal', () {
      final copy = group.copyWith();
      expect(group, equals(copy));
    });

    test('default constructor values', () {
      const g = GardenGroup(
        id: 'gg',
        gardenId: 'g',
        userId: 'u',
        name: 'Test',
      );
      expect(g.sortOrder, equals(0));
      expect(g.plantCount, equals(0));
      expect(g.description, isNull);
      expect(g.icon, isNull);
      expect(g.color, isNull);
    });
  });
}
