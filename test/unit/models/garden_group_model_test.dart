import 'package:flutter_test/flutter_test.dart';
import 'package:planticula/features/gardens/data/models/garden_group_model.dart';
import 'package:planticula/features/gardens/domain/entities/garden_group.dart';

void main() {
  group('GardenGroupModel.fromJson', () {
    test('parses a full JSON map', () {
      final json = {
        'id': 'gg-1',
        'garden_id': 'g-1',
        'user_id': 'u-1',
        'name': 'Tomates',
        'description': 'Zona de tomates',
        'icon': 'vegetable',
        'color': '#F44336',
        'sort_order': 2,
        'plant_count': 5,
        'created_at': '2025-06-01T10:00:00.000Z',
        'updated_at': '2025-06-02T12:00:00.000Z',
      };

      final model = GardenGroupModel.fromJson(json);

      expect(model.id, equals('gg-1'));
      expect(model.gardenId, equals('g-1'));
      expect(model.userId, equals('u-1'));
      expect(model.name, equals('Tomates'));
      expect(model.description, equals('Zona de tomates'));
      expect(model.icon, equals('vegetable'));
      expect(model.color, equals('#F44336'));
      expect(model.sortOrder, equals(2));
      expect(model.plantCount, equals(5));
      expect(model.createdAt, isNotNull);
      expect(model.updatedAt, isNotNull);
    });

    test('uses defaults for missing optional fields', () {
      final json = {
        'id': 'gg-2',
        'garden_id': 'g-1',
        'user_id': 'u-1',
        'name': 'Minimal Group',
      };

      final model = GardenGroupModel.fromJson(json);

      expect(model.description, isNull);
      expect(model.icon, isNull);
      expect(model.color, isNull);
      expect(model.sortOrder, equals(0));
      expect(model.plantCount, equals(0));
      expect(model.createdAt, isNull);
      expect(model.updatedAt, isNull);
    });
  });

  group('GardenGroupModel.toJson', () {
    test('serializes all fields', () {
      final now = DateTime.utc(2025, 6, 1);
      final model = GardenGroupModel(
        id: 'gg-1',
        gardenId: 'g-1',
        userId: 'u-1',
        name: 'Herbs',
        description: 'Herbs section',
        icon: 'herb',
        color: '#009688',
        sortOrder: 3,
        createdAt: now,
        updatedAt: now,
      );

      final json = model.toJson();

      expect(json['id'], equals('gg-1'));
      expect(json['garden_id'], equals('g-1'));
      expect(json['user_id'], equals('u-1'));
      expect(json['name'], equals('Herbs'));
      expect(json['description'], equals('Herbs section'));
      expect(json['icon'], equals('herb'));
      expect(json['color'], equals('#009688'));
      expect(json['sort_order'], equals(3));
      expect(json['created_at'], equals(now.toIso8601String()));
    });

    test('null optional fields serialize as null', () {
      const model = GardenGroupModel(
        id: 'gg-2',
        gardenId: 'g-1',
        userId: 'u-1',
        name: 'No extras',
      );
      final json = model.toJson();
      expect(json['description'], isNull);
      expect(json['icon'], isNull);
      expect(json['color'], isNull);
      expect(json['created_at'], isNull);
    });
  });

  group('GardenGroupModel.fromDomain', () {
    test('converts a GardenGroup entity to model', () {
      const entity = GardenGroup(
        id: 'gg-1',
        gardenId: 'g-1',
        userId: 'u-1',
        name: 'Succulents',
        description: 'Succulent zone',
        sortOrder: 1,
        plantCount: 4,
      );

      final model = GardenGroupModel.fromDomain(entity);

      expect(model.id, equals(entity.id));
      expect(model.gardenId, equals(entity.gardenId));
      expect(model.name, equals(entity.name));
      expect(model.plantCount, equals(4));
      expect(model, isA<GardenGroupModel>());
    });
  });

  group('GardenGroupModel.createJson', () {
    test('generates insert JSON without id and timestamps', () {
      final json = GardenGroupModel.createJson(
        userId: 'u-1',
        gardenId: 'g-1',
        name: 'New Group',
        description: 'Fresh group',
        icon: 'flower',
        color: '#E91E63',
        sortOrder: 5,
      );

      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('created_at'), isFalse);
      expect(json['user_id'], equals('u-1'));
      expect(json['garden_id'], equals('g-1'));
      expect(json['name'], equals('New Group'));
      expect(json['icon'], equals('flower'));
      expect(json['sort_order'], equals(5));
    });

    test('optional params default to null/0', () {
      final json = GardenGroupModel.createJson(
        userId: 'u-1',
        gardenId: 'g-1',
        name: 'Minimal',
      );

      expect(json['description'], isNull);
      expect(json['icon'], isNull);
      expect(json['color'], isNull);
      expect(json['sort_order'], equals(0));
    });
  });

  group('roundtrip', () {
    test('fromJson → toJson → fromJson produces equivalent model', () {
      final json = {
        'id': 'gg-rt',
        'garden_id': 'g-1',
        'user_id': 'u-1',
        'name': 'Roundtrip Group',
        'description': 'test',
        'icon': 'herb',
        'color': '#AABBCC',
        'sort_order': 4,
        'plant_count': 2,
        'created_at': '2025-03-10T09:00:00.000Z',
        'updated_at': '2025-03-11T10:00:00.000Z',
      };

      final model1 = GardenGroupModel.fromJson(json);
      final serialized = model1.toJson();
      final model2 = GardenGroupModel.fromJson(serialized);

      expect(model1.id, equals(model2.id));
      expect(model1.gardenId, equals(model2.gardenId));
      expect(model1.name, equals(model2.name));
      expect(model1.color, equals(model2.color));
      expect(model1.createdAt, equals(model2.createdAt));
    });
  });
}
