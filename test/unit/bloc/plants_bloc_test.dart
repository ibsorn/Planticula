import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:planticula/core/network/result.dart';
import 'package:planticula/core/services/notification_service.dart';
import 'package:planticula/features/plants/domain/entities/plant.dart';
import 'package:planticula/features/plants/domain/repositories/plants_repository.dart';
import 'package:planticula/features/plants/presentation/bloc/plants_bloc.dart';

class MockPlantsRepository extends Mock implements PlantsRepository {}

class FakePlant extends Fake implements Plant {}

/// No-op notifications para tests (no toca canales de plataforma).
class FakeNotificationService implements NotificationService {
  @override
  dynamic noSuchMethod(Invocation invocation) async {}
}

void main() {
  late MockPlantsRepository mockPlantsRepository;
  late FakeNotificationService fakeNotifications;

  final testPlant1 = Plant(
    id: '1',
    name: 'Test Plant 1',
    scientificName: 'Testus plantus 1',
    speciesId: 'species-1',
    wateringFrequency: 7,
    lastWatered: DateTime.now().subtract(const Duration(days: 3)),
    nextWatering: DateTime.now().add(const Duration(days: 4)),
  );

  final testPlant2 = Plant(
    id: '2',
    name: 'Test Plant 2',
    scientificName: 'Testus plantus 2',
    speciesId: 'species-2',
    wateringFrequency: 5,
    lastWatered: DateTime.now().subtract(const Duration(days: 5)),
    nextWatering: DateTime.now(),
  );

  final testPlants = [testPlant1, testPlant2];

  setUpAll(() {
    registerFallbackValue(FakePlant());
  });

  setUp(() {
    mockPlantsRepository = MockPlantsRepository();
    fakeNotifications = FakeNotificationService();
  });

  tearDown(() {
    reset(mockPlantsRepository);
  });

  group('PlantsBloc', () {
    test('initial state has status PlantsStatus.initial', () {
      final bloc = PlantsBloc(mockPlantsRepository, fakeNotifications);
      expect(bloc.state.status, PlantsStatus.initial);
      expect(bloc.state.plants, isEmpty);
      expect(bloc.state.selectedPlant, isNull);
      bloc.close();
    });

    blocTest<PlantsBloc, PlantsState>(
      'PlantsLoadRequested success emits [loading, loaded] with plants list',
      setUp: () {
        when(() => mockPlantsRepository.getPlants())
            .thenAnswer((_) async => Success(testPlants));
      },
      build: () => PlantsBloc(mockPlantsRepository, fakeNotifications),
      act: (bloc) => bloc.add(PlantsLoadRequested()),
      expect: () => [
        const PlantsState(status: PlantsStatus.loading),
        PlantsState(
          status: PlantsStatus.loaded,
          plants: testPlants,
        ),
      ],
    );

    blocTest<PlantsBloc, PlantsState>(
      'PlantsLoadRequested with empty list emits [loading, empty]',
      setUp: () {
        when(() => mockPlantsRepository.getPlants())
            .thenAnswer((_) async => const Success<List<Plant>>([]));
      },
      build: () => PlantsBloc(mockPlantsRepository, fakeNotifications),
      act: (bloc) => bloc.add(PlantsLoadRequested()),
      expect: () => [
        const PlantsState(status: PlantsStatus.loading),
        const PlantsState(status: PlantsStatus.empty),
      ],
    );

    blocTest<PlantsBloc, PlantsState>(
      'PlantsLoadRequested failure emits [loading, error]',
      setUp: () {
        when(() => mockPlantsRepository.getPlants())
            .thenAnswer((_) async => const Failure('Failed to load plants'));
      },
      build: () => PlantsBloc(mockPlantsRepository, fakeNotifications),
      act: (bloc) => bloc.add(PlantsLoadRequested()),
      expect: () => [
        const PlantsState(status: PlantsStatus.loading),
        const PlantsState(
          status: PlantsStatus.error,
          errorMessage: 'Failed to load plants',
        ),
      ],
    );

    blocTest<PlantsBloc, PlantsState>(
      'PlantsSearchRequested with query returns filtered plants',
      setUp: () {
        when(() => mockPlantsRepository.searchPlants('Test Plant 1'))
            .thenAnswer((_) async => Success([testPlant1]));
      },
      build: () => PlantsBloc(mockPlantsRepository, fakeNotifications),
      act: (bloc) => bloc.add(const PlantsSearchRequested('Test Plant 1')),
      expect: () => [
        const PlantsState(status: PlantsStatus.loading),
        PlantsState(
          status: PlantsStatus.loaded,
          plants: [testPlant1],
        ),
      ],
    );

    blocTest<PlantsBloc, PlantsState>(
      'PlantsSearchRequested with empty query reloads all plants',
      setUp: () {
        when(() => mockPlantsRepository.getPlants())
            .thenAnswer((_) async => Success(testPlants));
      },
      build: () => PlantsBloc(mockPlantsRepository, fakeNotifications),
      act: (bloc) => bloc.add(const PlantsSearchRequested('')),
      expect: () => [
        const PlantsState(status: PlantsStatus.loading),
        PlantsState(
          status: PlantsStatus.loaded,
          plants: testPlants,
        ),
      ],
    );

    blocTest<PlantsBloc, PlantsState>(
      'PlantCreateRequested success emits operationStatus success and adds plant to list',
      setUp: () {
        when(() => mockPlantsRepository.createPlant(
              name: any(named: 'name'),
              scientificName: any(named: 'scientificName'),
              speciesId: any(named: 'speciesId'),
              speciesCategory: any(named: 'speciesCategory'),
              imageUrl: any(named: 'imageUrl'),
              location: any(named: 'location'),
              notes: any(named: 'notes'),
              wateringFrequency: any(named: 'wateringFrequency'),
              acquiredDate: any(named: 'acquiredDate'),
              environment: any(named: 'environment'),
              growthStage: any(named: 'growthStage'),
              potSize: any(named: 'potSize'),
              latitude: any(named: 'latitude'),
              longitude: any(named: 'longitude'),
            )).thenAnswer((_) async => Success(testPlant1));
      },
      build: () => PlantsBloc(mockPlantsRepository, fakeNotifications),
      act: (bloc) => bloc.add(const PlantCreateRequested(name: 'Test Plant 1')),
      expect: () => [
        const PlantsState(operationStatus: PlantsOperationStatus.loading),
        PlantsState(
          plants: [testPlant1],
          status: PlantsStatus.loaded,
          operationStatus: PlantsOperationStatus.success,
        ),
      ],
    );

    blocTest<PlantsBloc, PlantsState>(
      'PlantCreateRequested failure emits operationStatus error',
      setUp: () {
        when(() => mockPlantsRepository.createPlant(
              name: any(named: 'name'),
              scientificName: any(named: 'scientificName'),
              speciesId: any(named: 'speciesId'),
              speciesCategory: any(named: 'speciesCategory'),
              imageUrl: any(named: 'imageUrl'),
              location: any(named: 'location'),
              notes: any(named: 'notes'),
              wateringFrequency: any(named: 'wateringFrequency'),
              acquiredDate: any(named: 'acquiredDate'),
              environment: any(named: 'environment'),
              growthStage: any(named: 'growthStage'),
              potSize: any(named: 'potSize'),
              latitude: any(named: 'latitude'),
              longitude: any(named: 'longitude'),
            )).thenAnswer((_) async => const Failure('Failed to create plant'));
      },
      build: () => PlantsBloc(mockPlantsRepository, fakeNotifications),
      act: (bloc) => bloc.add(const PlantCreateRequested(name: 'Test Plant')),
      expect: () => [
        const PlantsState(operationStatus: PlantsOperationStatus.loading),
        const PlantsState(
          operationStatus: PlantsOperationStatus.error,
          errorMessage: 'Failed to create plant',
        ),
      ],
    );

    blocTest<PlantsBloc, PlantsState>(
      'PlantWaterRequested success updates plant in list',
      setUp: () {
        final wateredPlant = testPlant2.copyWith(
          lastWatered: DateTime.now(),
          nextWatering: DateTime.now().add(const Duration(days: 5)),
        );
        when(() => mockPlantsRepository.waterPlant('2'))
            .thenAnswer((_) async => Success(wateredPlant));
      },
      seed: () => PlantsState(
        status: PlantsStatus.loaded,
        plants: testPlants,
      ),
      build: () => PlantsBloc(mockPlantsRepository, fakeNotifications),
      act: (bloc) => bloc.add(const PlantWaterRequested('2')),
      expect: () => [
        PlantsState(
          status: PlantsStatus.loaded,
          plants: testPlants,
          operationStatus: PlantsOperationStatus.loading,
        ),
        isA<PlantsState>()
            .having((s) => s.operationStatus, 'operationStatus', PlantsOperationStatus.success)
            .having((s) => s.plants.length, 'plants length', 2)
            .having((s) => s.plants.any((p) => p.id == '2'), 'has plant 2', true),
      ],
    );

    blocTest<PlantsBloc, PlantsState>(
      'PlantDeleteRequested success removes plant from list',
      setUp: () {
        when(() => mockPlantsRepository.deletePlant('1'))
            .thenAnswer((_) async => const Success(null));
      },
      seed: () => PlantsState(
        status: PlantsStatus.loaded,
        plants: testPlants,
      ),
      build: () => PlantsBloc(mockPlantsRepository, fakeNotifications),
      act: (bloc) => bloc.add(const PlantDeleteRequested('1')),
      expect: () => [
        PlantsState(
          status: PlantsStatus.loaded,
          plants: testPlants,
          operationStatus: PlantsOperationStatus.loading,
        ),
        PlantsState(
          status: PlantsStatus.loaded,
          plants: [testPlant2],
          operationStatus: PlantsOperationStatus.success,
        ),
      ],
    );

    blocTest<PlantsBloc, PlantsState>(
      'PlantDeleteRequested success with last plant emits empty status',
      setUp: () {
        when(() => mockPlantsRepository.deletePlant('1'))
            .thenAnswer((_) async => const Success(null));
      },
      seed: () => PlantsState(
        status: PlantsStatus.loaded,
        plants: [testPlant1],
      ),
      build: () => PlantsBloc(mockPlantsRepository, fakeNotifications),
      act: (bloc) => bloc.add(const PlantDeleteRequested('1')),
      expect: () => [
        PlantsState(
          status: PlantsStatus.loaded,
          plants: [testPlant1],
          operationStatus: PlantsOperationStatus.loading,
        ),
        const PlantsState(
          status: PlantsStatus.empty,
          operationStatus: PlantsOperationStatus.success,
        ),
      ],
    );

    blocTest<PlantsBloc, PlantsState>(
      'PlantSelectRequested with valid id sets selectedPlant',
      seed: () => PlantsState(
        status: PlantsStatus.loaded,
        plants: testPlants,
      ),
      build: () => PlantsBloc(mockPlantsRepository, fakeNotifications),
      act: (bloc) => bloc.add(const PlantSelectRequested('1')),
      expect: () => [
        PlantsState(
          status: PlantsStatus.loaded,
          plants: testPlants,
          selectedPlant: testPlant1,
        ),
      ],
    );

    blocTest<PlantsBloc, PlantsState>(
      'PlantSelectRequested with invalid id selects first plant',
      seed: () => PlantsState(
        status: PlantsStatus.loaded,
        plants: testPlants,
      ),
      build: () => PlantsBloc(mockPlantsRepository, fakeNotifications),
      act: (bloc) => bloc.add(const PlantSelectRequested('invalid-id')),
      expect: () => [
        PlantsState(
          status: PlantsStatus.loaded,
          plants: testPlants,
          selectedPlant: testPlant1,
        ),
      ],
    );

    blocTest<PlantsBloc, PlantsState>(
      'PlantUpdateRequested success updates plant in list',
      setUp: () {
        final updatedPlant = testPlant1.copyWith(name: 'Updated Plant 1');
        when(() => mockPlantsRepository.updatePlant(any()))
            .thenAnswer((_) async => Success(updatedPlant));
      },
      seed: () => PlantsState(
        status: PlantsStatus.loaded,
        plants: testPlants,
      ),
      build: () => PlantsBloc(mockPlantsRepository, fakeNotifications),
      act: (bloc) => bloc.add(PlantUpdateRequested(testPlant1.copyWith(name: 'Updated Plant 1'))),
      expect: () => [
        PlantsState(
          status: PlantsStatus.loaded,
          plants: testPlants,
          operationStatus: PlantsOperationStatus.loading,
        ),
        isA<PlantsState>()
            .having((s) => s.operationStatus, 'operationStatus', PlantsOperationStatus.success)
            .having((s) => s.plants.length, 'plants length', 2)
            .having(
              (s) => s.plants.firstWhere((p) => p.id == '1').name,
              'updated plant name',
              'Updated Plant 1',
            ),
      ],
    );

    blocTest<PlantsBloc, PlantsState>(
      'PlantTransplantRequested success updates plant in list',
      setUp: () {
        final transplantedPlant = testPlant1.copyWith(
          potSize: 'large',
          lastTransplanted: DateTime.now(),
        );
        when(() => mockPlantsRepository.transplantPlant('1', 'large'))
            .thenAnswer((_) async => Success(transplantedPlant));
      },
      seed: () => PlantsState(
        status: PlantsStatus.loaded,
        plants: testPlants,
      ),
      build: () => PlantsBloc(mockPlantsRepository, fakeNotifications),
      act: (bloc) => bloc.add(const PlantTransplantRequested(id: '1', newPotSize: 'large')),
      expect: () => [
        PlantsState(
          status: PlantsStatus.loaded,
          plants: testPlants,
          operationStatus: PlantsOperationStatus.loading,
        ),
        isA<PlantsState>()
            .having((s) => s.operationStatus, 'operationStatus', PlantsOperationStatus.success)
            .having((s) => s.plants.length, 'plants length', 2)
            .having(
              (s) => s.plants.firstWhere((p) => p.id == '1').potSize,
              'transplanted plant potSize',
              'large',
            ),
      ],
    );

    blocTest<PlantsBloc, PlantsState>(
      'PlantsClearError clears error state',
      seed: () => const PlantsState(
        status: PlantsStatus.error,
        errorMessage: 'Some error',
      ),
      build: () => PlantsBloc(mockPlantsRepository, fakeNotifications),
      act: (bloc) => bloc.add(PlantsClearError()),
      expect: () => [
        const PlantsState(),
      ],
    );
  });
}
