import 'package:flutter_test/flutter_test.dart';
import 'package:planticula/core/data/species/plant_species.dart';
import 'package:planticula/features/plants/domain/entities/plant.dart';

void main() {
  group('Plant', () {
    final now = DateTime(2025, 6, 15, 12, 0);

    final plant = Plant(
      id: 'p-1',
      name: 'Monstera',
      customName: 'Big Leaf',
      scientificName: 'Monstera deliciosa',
      speciesId: 'sp-1',
      wateringFrequency: 7,
      lastWatered: now.subtract(const Duration(days: 3)),
      nextWatering: now.add(const Duration(days: 4)),
      environment: 'indoor',
      growthStage: 'mature',
      potSize: 'large',
      gardenId: 'g-1',
      groupId: 'gg-1',
    );

    test('displayName returns customName when present', () {
      expect(plant.displayName, equals('Big Leaf'));
    });

    test('displayName returns name when customName is null', () {
      const p = Plant(id: 'p-2', name: 'Cactus');
      expect(p.displayName, equals('Cactus'));
    });

    test('displayName returns name when customName is empty', () {
      const p = Plant(id: 'p-3', name: 'Fern', customName: '');
      expect(p.displayName, equals('Fern'));
    });

    test('hasCustomName is true when customName is not empty', () {
      expect(plant.hasCustomName, isTrue);
    });

    test('hasCustomName is false when customName is null', () {
      const p = Plant(id: 'p-2', name: 'X');
      expect(p.hasCustomName, isFalse);
    });

    test('hasCustomName is false when customName is empty', () {
      const p = Plant(id: 'p-3', name: 'X', customName: '');
      expect(p.hasCustomName, isFalse);
    });

    test('needsWatering is false when nextWatering is in the future', () {
      final notThirsty = plant.copyWith(
        nextWatering: DateTime.now().add(const Duration(days: 5)),
      );
      expect(notThirsty.needsWatering, isFalse);
    });

    test('needsWatering is true when nextWatering is in the past', () {
      final thirsty = plant.copyWith(
        nextWatering: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(thirsty.needsWatering, isTrue);
    });

    test('needsWatering is false when nextWatering is null', () {
      const p = Plant(id: 'x', name: 'X');
      expect(p.needsWatering, isFalse);
    });

    test('daysUntilWatering returns positive for future watering', () {
      final p = Plant(
        id: 'x',
        name: 'X',
        nextWatering: DateTime.now().add(const Duration(days: 5)),
      );
      expect(p.daysUntilWatering, greaterThanOrEqualTo(4));
    });

    test('daysUntilWatering returns negative for overdue watering', () {
      final p = Plant(
        id: 'x',
        name: 'X',
        nextWatering: DateTime.now().subtract(const Duration(days: 3)),
      );
      expect(p.daysUntilWatering, lessThan(0));
    });

    test('daysUntilWatering returns null when nextWatering is null', () {
      const p = Plant(id: 'x', name: 'X');
      expect(p.daysUntilWatering, isNull);
    });

    test('hasWateringReminder is true when frequency > 0', () {
      expect(plant.hasWateringReminder, isTrue);
    });

    test('hasWateringReminder is false when frequency is null', () {
      const p = Plant(id: 'x', name: 'X');
      expect(p.hasWateringReminder, isFalse);
    });

    test('hasWateringReminder is false when frequency is 0', () {
      const p = Plant(id: 'x', name: 'X', wateringFrequency: 0);
      expect(p.hasWateringReminder, isFalse);
    });

    test('plantEnvironment returns outdoor for outdoor string', () {
      const p = Plant(id: 'x', name: 'X', environment: 'outdoor');
      expect(p.plantEnvironment, PlantEnvironment.outdoor);
    });

    test('plantEnvironment defaults to indoor', () {
      const p = Plant(id: 'x', name: 'X');
      expect(p.plantEnvironment, PlantEnvironment.indoor);
    });

    test('isOutdoor returns true for outdoor environment', () {
      const p = Plant(id: 'x', name: 'X', environment: 'outdoor');
      expect(p.isOutdoor, isTrue);
    });

    test('isOutdoor returns false for indoor environment', () {
      expect(plant.isOutdoor, isFalse);
    });

    test('plantGrowthStage parses string to enum', () {
      expect(plant.plantGrowthStage, GrowthStage.mature);
    });

    test('plantGrowthStage defaults to mature when growthStage is null', () {
      // Plant.plantGrowthStage calls GrowthStage.fromString('adult')
      // which maps to GrowthStage.mature
      const p = Plant(id: 'x', name: 'X');
      expect(p.plantGrowthStage, GrowthStage.mature);
    });

    test('plantPotSize parses string to enum', () {
      expect(plant.plantPotSize, PotSize.large);
    });

    test('plantPotSize defaults to medium when null', () {
      const p = Plant(id: 'x', name: 'X');
      expect(p.plantPotSize, PotSize.medium);
    });

    test('copyWith preserves unchanged fields', () {
      final copy = plant.copyWith(name: 'Updated');
      expect(copy.name, equals('Updated'));
      expect(copy.id, equals(plant.id));
      expect(copy.customName, equals(plant.customName));
      expect(copy.gardenId, equals(plant.gardenId));
    });

    test('copyWith clearGardenId sets gardenId to null', () {
      final copy = plant.copyWith(clearGardenId: true);
      expect(copy.gardenId, isNull);
      expect(copy.groupId, equals(plant.groupId));
    });

    test('copyWith clearGroupId sets groupId to null', () {
      final copy = plant.copyWith(clearGroupId: true);
      expect(copy.groupId, isNull);
      expect(copy.gardenId, equals(plant.gardenId));
    });

    test('copyWith both clear flags set both to null', () {
      final copy = plant.copyWith(clearGardenId: true, clearGroupId: true);
      expect(copy.gardenId, isNull);
      expect(copy.groupId, isNull);
    });

    test('Equatable: same data are equal', () {
      final copy = plant.copyWith();
      expect(plant, equals(copy));
    });

    test('Equatable: different data are not equal', () {
      final other = plant.copyWith(name: 'Different');
      expect(plant, isNot(equals(other)));
    });
  });
}
