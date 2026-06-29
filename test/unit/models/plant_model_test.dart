import 'package:flutter_test/flutter_test.dart';
import 'package:planticula/features/plants/data/models/plant_model.dart';
import 'package:planticula/features/plants/domain/entities/plant.dart';

void main() {
  group('PlantModel.fromJson', () {
    test('parses a full JSON map', () {
      final json = {
        'id': 'p-1',
        'name': 'Monstera',
        'custom_name': 'Mi Monstera',
        'scientific_name': 'Monstera deliciosa',
        'species_id': 'sp-1',
        'species_category': 'indoor',
        'image_url': 'https://example.com/img.jpg',
        'location': 'Salón',
        'notes': 'Crece bien',
        'watering_frequency': 7,
        'last_watered': '2025-06-01T08:00:00.000Z',
        'next_watering': '2025-06-08T08:00:00.000Z',
        'acquired_date': '2025-01-15T00:00:00.000Z',
        'environment': 'indoor',
        'growth_stage': 'mature',
        'pot_size': 'large',
        'last_transplanted': '2025-03-01T00:00:00.000Z',
        'latitude': 40.4168,
        'longitude': -3.7038,
        'created_at': '2025-01-15T10:00:00.000Z',
        'updated_at': '2025-06-01T12:00:00.000Z',
        'garden_id': 'g-1',
        'group_id': 'gg-1',
      };

      final model = PlantModel.fromJson(json);

      expect(model.id, equals('p-1'));
      expect(model.name, equals('Monstera'));
      expect(model.customName, equals('Mi Monstera'));
      expect(model.scientificName, equals('Monstera deliciosa'));
      expect(model.speciesId, equals('sp-1'));
      expect(model.speciesCategory, equals('indoor'));
      expect(model.imageUrl, equals('https://example.com/img.jpg'));
      expect(model.location, equals('Salón'));
      expect(model.notes, equals('Crece bien'));
      expect(model.wateringFrequency, equals(7));
      expect(model.lastWatered, isNotNull);
      expect(model.nextWatering, isNotNull);
      expect(model.acquiredDate, isNotNull);
      expect(model.environment, equals('indoor'));
      expect(model.growthStage, equals('mature'));
      expect(model.potSize, equals('large'));
      expect(model.lastTransplanted, isNotNull);
      expect(model.latitude, closeTo(40.4168, 0.001));
      expect(model.longitude, closeTo(-3.7038, 0.001));
      expect(model.createdAt, isNotNull);
      expect(model.updatedAt, isNotNull);
      expect(model.gardenId, equals('g-1'));
      expect(model.groupId, equals('gg-1'));
    });

    test('handles minimal JSON with only required fields', () {
      final json = {
        'id': 'p-2',
        'name': 'Unknown Plant',
      };

      final model = PlantModel.fromJson(json);

      expect(model.id, equals('p-2'));
      expect(model.name, equals('Unknown Plant'));
      expect(model.customName, isNull);
      expect(model.scientificName, isNull);
      expect(model.speciesId, isNull);
      expect(model.wateringFrequency, isNull);
      expect(model.lastWatered, isNull);
      expect(model.gardenId, isNull);
      expect(model.groupId, isNull);
      expect(model.latitude, isNull);
    });
  });

  group('PlantModel.toJson', () {
    test('serializes all fields correctly', () {
      final now = DateTime.utc(2025, 6, 1, 10, 0);
      final model = PlantModel(
        id: 'p-1',
        name: 'Rose',
        customName: 'My Rose',
        scientificName: 'Rosa sp.',
        speciesId: 'sp-rose',
        speciesCategory: 'outdoor',
        imageUrl: 'https://img.com/rose.jpg',
        location: 'Terraza',
        notes: 'Fragrant',
        wateringFrequency: 3,
        lastWatered: now,
        nextWatering: now.add(const Duration(days: 3)),
        acquiredDate: now,
        environment: 'outdoor',
        growthStage: 'mature',
        potSize: 'medium',
        lastTransplanted: now,
        latitude: 41.0,
        longitude: 2.0,
        createdAt: now,
        updatedAt: now,
        gardenId: 'g-1',
        groupId: 'gg-1',
      );

      final json = model.toJson();

      expect(json['id'], equals('p-1'));
      expect(json['name'], equals('Rose'));
      expect(json['custom_name'], equals('My Rose'));
      expect(json['scientific_name'], equals('Rosa sp.'));
      expect(json['species_id'], equals('sp-rose'));
      expect(json['species_category'], equals('outdoor'));
      expect(json['watering_frequency'], equals(3));
      expect(json['environment'], equals('outdoor'));
      expect(json['garden_id'], equals('g-1'));
      expect(json['group_id'], equals('gg-1'));
      expect(json['latitude'], equals(41.0));
      expect(json['longitude'], equals(2.0));
      expect(json['last_watered'], isNotNull);
      expect(json['created_at'], isNotNull);
    });

    test('null optional fields serialize as null', () {
      const model = PlantModel(id: 'p-2', name: 'Minimal');
      final json = model.toJson();

      expect(json['custom_name'], isNull);
      expect(json['scientific_name'], isNull);
      expect(json['garden_id'], isNull);
      expect(json['group_id'], isNull);
      expect(json['latitude'], isNull);
      expect(json['last_watered'], isNull);
      expect(json['created_at'], isNull);
    });
  });

  group('PlantModel.fromDomain', () {
    test('converts a Plant entity preserving all fields', () {
      const entity = Plant(
        id: 'p-1',
        name: 'Cactus',
        customName: 'Spike',
        environment: 'indoor',
        potSize: 'small',
        gardenId: 'g-1',
        groupId: 'gg-1',
      );

      final model = PlantModel.fromDomain(entity);

      expect(model.id, equals('p-1'));
      expect(model.name, equals('Cactus'));
      expect(model.customName, equals('Spike'));
      expect(model.environment, equals('indoor'));
      expect(model.potSize, equals('small'));
      expect(model.gardenId, equals('g-1'));
      expect(model.groupId, equals('gg-1'));
      expect(model, isA<PlantModel>());
    });
  });

  group('PlantModel.copyWithModel', () {
    test('creates a copy with modified fields', () {
      const model = PlantModel(
        id: 'p-1',
        name: 'Original',
        potSize: 'small',
      );

      final copy = model.copyWithModel(
        name: 'Updated',
        potSize: 'large',
        gardenId: 'g-new',
      );

      expect(copy.id, equals('p-1'));
      expect(copy.name, equals('Updated'));
      expect(copy.potSize, equals('large'));
      expect(copy.gardenId, equals('g-new'));
    });
  });

  group('PlantModel.create', () {
    test('generates model with empty id and specified fields', () {
      final model = PlantModel.create(
        name: 'New Plant',
        scientificName: 'Plantus newus',
        environment: 'outdoor',
        wateringFrequency: 5,
        gardenId: 'g-1',
        groupId: 'gg-2',
      );

      expect(model.id, isEmpty);
      expect(model.name, equals('New Plant'));
      expect(model.scientificName, equals('Plantus newus'));
      expect(model.environment, equals('outdoor'));
      expect(model.wateringFrequency, equals(5));
      expect(model.gardenId, equals('g-1'));
      expect(model.groupId, equals('gg-2'));
      expect(model.createdAt, isNull);
    });
  });

  group('roundtrip', () {
    test('fromJson → toJson → fromJson produces equivalent model', () {
      final json = {
        'id': 'p-rt',
        'name': 'Roundtrip Plant',
        'custom_name': 'RT',
        'scientific_name': 'Roundtripus',
        'species_id': 'sp-rt',
        'species_category': 'indoor',
        'image_url': 'https://example.com/rt.jpg',
        'location': 'Office',
        'notes': 'Test roundtrip',
        'watering_frequency': 10,
        'last_watered': '2025-05-01T00:00:00.000Z',
        'next_watering': '2025-05-11T00:00:00.000Z',
        'acquired_date': '2025-01-01T00:00:00.000Z',
        'environment': 'indoor',
        'growth_stage': 'seedling',
        'pot_size': 'extra_small',
        'last_transplanted': '2025-04-01T00:00:00.000Z',
        'latitude': 35.0,
        'longitude': -120.0,
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': '2025-06-01T00:00:00.000Z',
        'garden_id': 'g-rt',
        'group_id': 'gg-rt',
      };

      final model1 = PlantModel.fromJson(json);
      final serialized = model1.toJson();
      final model2 = PlantModel.fromJson(serialized);

      expect(model1.id, equals(model2.id));
      expect(model1.name, equals(model2.name));
      expect(model1.customName, equals(model2.customName));
      expect(model1.wateringFrequency, equals(model2.wateringFrequency));
      expect(model1.gardenId, equals(model2.gardenId));
      expect(model1.groupId, equals(model2.groupId));
      expect(model1.latitude, equals(model2.latitude));
      expect(model1.createdAt, equals(model2.createdAt));
    });
  });
}
