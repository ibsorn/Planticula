import 'package:flutter_test/flutter_test.dart';
import 'package:planticula/features/gardens/data/models/garden_model.dart';
import 'package:planticula/features/gardens/domain/entities/garden.dart';

void main() {
  group('GardenModel.fromJson', () {
    test('parses a full JSON map', () {
      final json = {
        'id': 'g-1',
        'user_id': 'u-1',
        'name': 'Mi Jardín',
        'description': 'Descripción',
        'icon': 'flower',
        'color': '#FF0000',
        'type': 'greenhouse',
        'is_default': true,
        'sort_order': 3,
        'plant_count': 12,
        'group_count': 4,
        'created_at': '2025-06-01T10:00:00.000Z',
        'updated_at': '2025-06-02T12:00:00.000Z',
      };

      final model = GardenModel.fromJson(json);

      expect(model.id, equals('g-1'));
      expect(model.userId, equals('u-1'));
      expect(model.name, equals('Mi Jardín'));
      expect(model.description, equals('Descripción'));
      expect(model.icon, equals('flower'));
      expect(model.color, equals('#FF0000'));
      expect(model.type, GardenType.greenhouse);
      expect(model.isDefault, isTrue);
      expect(model.sortOrder, equals(3));
      expect(model.plantCount, equals(12));
      expect(model.groupCount, equals(4));
      expect(model.createdAt, isNotNull);
      expect(model.updatedAt, isNotNull);
    });

    test('uses defaults for missing optional fields', () {
      final json = {
        'id': 'g-2',
        'user_id': 'u-1',
        'name': 'Minimal',
      };

      final model = GardenModel.fromJson(json);

      expect(model.icon, equals('garden'));
      expect(model.color, equals('#4CAF50'));
      expect(model.type, GardenType.personal);
      expect(model.isDefault, isFalse);
      expect(model.sortOrder, equals(0));
      expect(model.plantCount, equals(0));
      expect(model.groupCount, equals(0));
      expect(model.description, isNull);
      expect(model.createdAt, isNull);
      expect(model.updatedAt, isNull);
    });

    test('handles unknown type string gracefully', () {
      final json = {
        'id': 'g-3',
        'user_id': 'u-1',
        'name': 'Test',
        'type': 'nonexistent_type',
      };
      final model = GardenModel.fromJson(json);
      expect(model.type, GardenType.personal);
    });
  });

  group('GardenModel.toJson', () {
    test('serializes all fields to snake_case JSON', () {
      final now = DateTime.utc(2025, 6, 1, 10, 0);
      final model = GardenModel(
        id: 'g-1',
        userId: 'u-1',
        name: 'Test Garden',
        description: 'desc',
        icon: 'herb',
        color: '#00FF00',
        type: GardenType.indoor,
        isDefault: false,
        sortOrder: 1,
        createdAt: now,
        updatedAt: now,
      );

      final json = model.toJson();

      expect(json['id'], equals('g-1'));
      expect(json['user_id'], equals('u-1'));
      expect(json['name'], equals('Test Garden'));
      expect(json['description'], equals('desc'));
      expect(json['icon'], equals('herb'));
      expect(json['color'], equals('#00FF00'));
      expect(json['type'], equals('indoor'));
      expect(json['is_default'], isFalse);
      expect(json['sort_order'], equals(1));
      expect(json['created_at'], equals(now.toIso8601String()));
      expect(json['updated_at'], equals(now.toIso8601String()));
    });

    test('null timestamps serialize as null', () {
      const model = GardenModel(
        id: 'g-1',
        userId: 'u-1',
        name: 'No Timestamps',
      );
      final json = model.toJson();
      expect(json['created_at'], isNull);
      expect(json['updated_at'], isNull);
    });
  });

  group('GardenModel.fromDomain', () {
    test('converts a Garden entity to GardenModel', () {
      const entity = Garden(
        id: 'g-1',
        userId: 'u-1',
        name: 'Domain Garden',
        type: GardenType.balcony,
        icon: 'balcony',
        color: '#AABBCC',
        isDefault: true,
        sortOrder: 5,
        plantCount: 7,
        groupCount: 2,
      );

      final model = GardenModel.fromDomain(entity);

      expect(model.id, equals(entity.id));
      expect(model.name, equals(entity.name));
      expect(model.type, equals(entity.type));
      expect(model.icon, equals(entity.icon));
      expect(model.isDefault, isTrue);
      expect(model.plantCount, equals(7));
      expect(model, isA<GardenModel>());
    });
  });

  group('GardenModel.createJson', () {
    test('generates insert JSON without id and timestamps', () {
      final json = GardenModel.createJson(
        userId: 'u-1',
        name: 'New Garden',
        description: 'Fresh garden',
        icon: 'potted',
        color: '#123456',
        type: GardenType.terrace,
        isDefault: false,
        sortOrder: 2,
      );

      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('created_at'), isFalse);
      expect(json.containsKey('updated_at'), isFalse);
      expect(json['user_id'], equals('u-1'));
      expect(json['name'], equals('New Garden'));
      expect(json['type'], equals('terrace'));
      expect(json['sort_order'], equals(2));
    });

    test('uses default values when optional params omitted', () {
      final json = GardenModel.createJson(
        userId: 'u-1',
        name: 'Minimal',
      );

      expect(json['icon'], equals('garden'));
      expect(json['color'], equals('#4CAF50'));
      expect(json['type'], equals('personal'));
      expect(json['is_default'], isFalse);
      expect(json['sort_order'], equals(0));
    });
  });

  group('roundtrip', () {
    test('fromJson → toJson → fromJson produces equivalent model', () {
      final json = {
        'id': 'g-rt',
        'user_id': 'u-1',
        'name': 'Roundtrip',
        'description': 'test roundtrip',
        'icon': 'forest',
        'color': '#ABCDEF',
        'type': 'outdoor',
        'is_default': false,
        'sort_order': 7,
        'plant_count': 3,
        'group_count': 1,
        'created_at': '2025-01-15T08:30:00.000Z',
        'updated_at': '2025-02-20T14:45:00.000Z',
      };

      final model1 = GardenModel.fromJson(json);
      final serialized = model1.toJson();
      final model2 = GardenModel.fromJson(serialized);

      expect(model1.id, equals(model2.id));
      expect(model1.name, equals(model2.name));
      expect(model1.type, equals(model2.type));
      expect(model1.color, equals(model2.color));
      expect(model1.createdAt, equals(model2.createdAt));
    });
  });
}
