import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/gardens/domain/entities/garden.dart';
import 'package:planticula/features/gardens/domain/entities/garden_group.dart';
import 'package:planticula/features/gardens/domain/repositories/garden_repository.dart';
import 'package:planticula/features/gardens/presentation/bloc/garden_bloc.dart';

class MockGardenRepository extends Mock implements GardenRepository {}

class FakeGarden extends Fake implements Garden {}

class FakeGardenGroup extends Fake implements GardenGroup {}

void main() {
  late MockGardenRepository mockRepo;

  const testGarden1 = Garden(
    id: 'g-1',
    userId: 'u-1',
    name: 'Terraza',
    type: GardenType.terrace,
    isDefault: false,
  );

  const testGarden2 = Garden(
    id: 'g-2',
    userId: 'u-1',
    name: 'Interior',
    type: GardenType.indoor,
    isDefault: true,
  );

  const testGroup1 = GardenGroup(
    id: 'gg-1',
    gardenId: 'g-1',
    userId: 'u-1',
    name: 'Tomates',
  );

  const testGroup2 = GardenGroup(
    id: 'gg-2',
    gardenId: 'g-1',
    userId: 'u-1',
    name: 'Hierbas',
  );

  setUpAll(() {
    registerFallbackValue(FakeGarden());
    registerFallbackValue(FakeGardenGroup());
    registerFallbackValue(GardenType.personal);
  });

  setUp(() {
    mockRepo = MockGardenRepository();
  });

  tearDown(() {
    reset(mockRepo);
  });

  group('GardenBloc', () {
    test('initial state has status GardenStatus.initial', () {
      final bloc = GardenBloc(mockRepo);
      expect(bloc.state.status, GardenStatus.initial);
      expect(bloc.state.gardens, isEmpty);
      expect(bloc.state.groups, isEmpty);
      expect(bloc.state.selectedGarden, isNull);
      bloc.close();
    });

    // ── Load gardens ────────────────────────────────────────────────────────

    blocTest<GardenBloc, GardenState>(
      'GardensLoadRequested success emits [loading, loaded]',
      setUp: () {
        when(() => mockRepo.getOrCreateDefaultGarden())
            .thenAnswer((_) async => const Success(testGarden2));
        when(() => mockRepo.getGardens())
            .thenAnswer((_) async => const Success([testGarden1, testGarden2]));
      },
      build: () => GardenBloc(mockRepo),
      act: (bloc) => bloc.add(GardensLoadRequested()),
      expect: () => [
        const GardenState(status: GardenStatus.loading),
        const GardenState(
          status: GardenStatus.loaded,
          gardens: [testGarden1, testGarden2],
        ),
      ],
    );

    blocTest<GardenBloc, GardenState>(
      'GardensLoadRequested with empty list emits [loading, empty]',
      setUp: () {
        when(() => mockRepo.getOrCreateDefaultGarden())
            .thenAnswer((_) async => const Success(testGarden2));
        when(() => mockRepo.getGardens())
            .thenAnswer((_) async => const Success(<Garden>[]));
      },
      build: () => GardenBloc(mockRepo),
      act: (bloc) => bloc.add(GardensLoadRequested()),
      expect: () => [
        const GardenState(status: GardenStatus.loading),
        const GardenState(status: GardenStatus.empty),
      ],
    );

    blocTest<GardenBloc, GardenState>(
      'GardensLoadRequested failure emits [loading, error]',
      setUp: () {
        when(() => mockRepo.getOrCreateDefaultGarden())
            .thenAnswer((_) async => const Success(testGarden2));
        when(() => mockRepo.getGardens())
            .thenAnswer((_) async => const Failure('DB error'));
      },
      build: () => GardenBloc(mockRepo),
      act: (bloc) => bloc.add(GardensLoadRequested()),
      expect: () => [
        const GardenState(status: GardenStatus.loading),
        const GardenState(
          status: GardenStatus.error,
          errorMessage: 'DB error',
        ),
      ],
    );

    // ── Create garden ───────────────────────────────────────────────────────

    blocTest<GardenBloc, GardenState>(
      'GardenCreateRequested success prepends garden and emits opStatus success',
      setUp: () {
        when(() => mockRepo.createGarden(
              name: any(named: 'name'),
              description: any(named: 'description'),
              icon: any(named: 'icon'),
              color: any(named: 'color'),
              type: any(named: 'type'),
            )).thenAnswer((_) async => const Success(testGarden1));
      },
      build: () => GardenBloc(mockRepo),
      act: (bloc) => bloc.add(const GardenCreateRequested(name: 'Terraza')),
      expect: () => [
        const GardenState(opStatus: GardenOpStatus.loading),
        const GardenState(
          gardens: [testGarden1],
          status: GardenStatus.loaded,
          opStatus: GardenOpStatus.success,
        ),
      ],
    );

    blocTest<GardenBloc, GardenState>(
      'GardenCreateRequested failure emits opStatus error',
      setUp: () {
        when(() => mockRepo.createGarden(
              name: any(named: 'name'),
              description: any(named: 'description'),
              icon: any(named: 'icon'),
              color: any(named: 'color'),
              type: any(named: 'type'),
            )).thenAnswer((_) async => const Failure('Create failed'));
      },
      build: () => GardenBloc(mockRepo),
      act: (bloc) => bloc.add(const GardenCreateRequested(name: 'Fail')),
      expect: () => [
        const GardenState(opStatus: GardenOpStatus.loading),
        const GardenState(
          opStatus: GardenOpStatus.error,
          errorMessage: 'Create failed',
        ),
      ],
    );

    // ── Update garden ───────────────────────────────────────────────────────

    blocTest<GardenBloc, GardenState>(
      'GardenUpdateRequested success updates garden in list',
      setUp: () {
        final updated = testGarden1.copyWith(name: 'Terraza Renovada');
        when(() => mockRepo.updateGarden(any()))
            .thenAnswer((_) async => Success(updated));
      },
      seed: () => const GardenState(
        status: GardenStatus.loaded,
        gardens: [testGarden1, testGarden2],
      ),
      build: () => GardenBloc(mockRepo),
      act: (bloc) => bloc.add(GardenUpdateRequested(
        testGarden1.copyWith(name: 'Terraza Renovada'),
      )),
      expect: () => [
        const GardenState(
          status: GardenStatus.loaded,
          gardens: [testGarden1, testGarden2],
          opStatus: GardenOpStatus.loading,
        ),
        isA<GardenState>()
            .having((s) => s.opStatus, 'opStatus', GardenOpStatus.success)
            .having((s) => s.gardens.length, 'count', 2)
            .having(
              (s) => s.gardens.firstWhere((g) => g.id == 'g-1').name,
              'updated name',
              'Terraza Renovada',
            ),
      ],
    );

    // ── Delete garden ───────────────────────────────────────────────────────

    blocTest<GardenBloc, GardenState>(
      'GardenDeleteRequested on default garden emits error without calling repo',
      build: () => GardenBloc(mockRepo),
      seed: () => const GardenState(
        status: GardenStatus.loaded,
        gardens: [testGarden1, testGarden2],
      ),
      act: (bloc) => bloc.add(const GardenDeleteRequested('g-2')),
      expect: () => [
        isA<GardenState>()
            .having((s) => s.opStatus, 'opStatus', GardenOpStatus.error)
            .having((s) => s.errorMessage, 'msg',
                'No se puede eliminar el jardín por defecto'),
      ],
    );

    blocTest<GardenBloc, GardenState>(
      'GardenDeleteRequested success removes garden from list',
      setUp: () {
        when(() => mockRepo.deleteGarden(any()))
            .thenAnswer((_) async => const Success(null));
      },
      seed: () => const GardenState(
        status: GardenStatus.loaded,
        gardens: [testGarden1, testGarden2],
      ),
      build: () => GardenBloc(mockRepo),
      act: (bloc) => bloc.add(const GardenDeleteRequested('g-1')),
      expect: () => [
        const GardenState(
          status: GardenStatus.loaded,
          gardens: [testGarden1, testGarden2],
          opStatus: GardenOpStatus.loading,
        ),
        const GardenState(
          status: GardenStatus.loaded,
          gardens: [testGarden2],
          opStatus: GardenOpStatus.success,
        ),
      ],
    );

    // ── Select garden ───────────────────────────────────────────────────────

    blocTest<GardenBloc, GardenState>(
      'GardenSelectRequested sets selectedGarden and clears groups',
      setUp: () {
        when(() => mockRepo.getGroupsByGarden(any()))
            .thenAnswer((_) async => const Success([testGroup1, testGroup2]));
      },
      seed: () => const GardenState(
        status: GardenStatus.loaded,
        gardens: [testGarden1, testGarden2],
        groups: [testGroup2],
      ),
      build: () => GardenBloc(mockRepo),
      act: (bloc) => bloc.add(const GardenSelectRequested(testGarden1)),
      expect: () => [
        const GardenState(
          status: GardenStatus.loaded,
          gardens: [testGarden1, testGarden2],
          selectedGarden: testGarden1,
          groups: [],
        ),
        const GardenState(
          status: GardenStatus.loaded,
          gardens: [testGarden1, testGarden2],
          selectedGarden: testGarden1,
          groups: [testGroup1, testGroup2],
        ),
      ],
    );

    blocTest<GardenBloc, GardenState>(
      'GardenSelectRequested with null clears selection',
      seed: () => const GardenState(
        status: GardenStatus.loaded,
        gardens: [testGarden1],
        selectedGarden: testGarden1,
        groups: [testGroup1],
      ),
      build: () => GardenBloc(mockRepo),
      act: (bloc) => bloc.add(const GardenSelectRequested(null)),
      expect: () => [
        const GardenState(
          status: GardenStatus.loaded,
          gardens: [testGarden1],
          groups: [],
        ),
      ],
    );

    // ── Group CRUD ──────────────────────────────────────────────────────────

    blocTest<GardenBloc, GardenState>(
      'GardenGroupCreateRequested success appends group',
      setUp: () {
        when(() => mockRepo.createGroup(
              gardenId: any(named: 'gardenId'),
              name: any(named: 'name'),
              description: any(named: 'description'),
              icon: any(named: 'icon'),
              color: any(named: 'color'),
            )).thenAnswer((_) async => const Success(testGroup1));
      },
      seed: () => const GardenState(
        status: GardenStatus.loaded,
        gardens: [testGarden1],
      ),
      build: () => GardenBloc(mockRepo),
      act: (bloc) => bloc.add(const GardenGroupCreateRequested(
        gardenId: 'g-1',
        name: 'Tomates',
      )),
      expect: () => [
        const GardenState(
          status: GardenStatus.loaded,
          gardens: [testGarden1],
          opStatus: GardenOpStatus.loading,
        ),
        const GardenState(
          status: GardenStatus.loaded,
          gardens: [testGarden1],
          groups: [testGroup1],
          opStatus: GardenOpStatus.success,
        ),
      ],
    );

    blocTest<GardenBloc, GardenState>(
      'GardenGroupDeleteRequested success removes group',
      setUp: () {
        when(() => mockRepo.deleteGroup(any()))
            .thenAnswer((_) async => const Success(null));
      },
      seed: () => const GardenState(
        status: GardenStatus.loaded,
        gardens: [testGarden1],
        groups: [testGroup1, testGroup2],
      ),
      build: () => GardenBloc(mockRepo),
      act: (bloc) => bloc.add(const GardenGroupDeleteRequested('gg-1')),
      expect: () => [
        const GardenState(
          status: GardenStatus.loaded,
          gardens: [testGarden1],
          groups: [testGroup1, testGroup2],
          opStatus: GardenOpStatus.loading,
        ),
        const GardenState(
          status: GardenStatus.loaded,
          gardens: [testGarden1],
          groups: [testGroup2],
          opStatus: GardenOpStatus.success,
        ),
      ],
    );

    blocTest<GardenBloc, GardenState>(
      'GardenGroupUpdateRequested success updates group in list',
      setUp: () {
        final updated = testGroup1.copyWith(name: 'Cherry Tomatoes');
        when(() => mockRepo.updateGroup(any()))
            .thenAnswer((_) async => Success(updated));
      },
      seed: () => const GardenState(
        status: GardenStatus.loaded,
        gardens: [testGarden1],
        groups: [testGroup1, testGroup2],
      ),
      build: () => GardenBloc(mockRepo),
      act: (bloc) => bloc.add(GardenGroupUpdateRequested(
        testGroup1.copyWith(name: 'Cherry Tomatoes'),
      )),
      expect: () => [
        const GardenState(
          status: GardenStatus.loaded,
          gardens: [testGarden1],
          groups: [testGroup1, testGroup2],
          opStatus: GardenOpStatus.loading,
        ),
        isA<GardenState>()
            .having((s) => s.opStatus, 'opStatus', GardenOpStatus.success)
            .having(
              (s) => s.groups.firstWhere((g) => g.id == 'gg-1').name,
              'updated name',
              'Cherry Tomatoes',
            ),
      ],
    );

    // ── Clear error ─────────────────────────────────────────────────────────

    blocTest<GardenBloc, GardenState>(
      'GardenClearError resets error and opStatus',
      seed: () => const GardenState(
        status: GardenStatus.error,
        opStatus: GardenOpStatus.error,
        errorMessage: 'Some error',
      ),
      build: () => GardenBloc(mockRepo),
      act: (bloc) => bloc.add(GardenClearError()),
      expect: () => [
        const GardenState(
          status: GardenStatus.error,
          opStatus: GardenOpStatus.initial,
        ),
      ],
    );
  });

  group('GardenState helpers', () {
    test('isLoading / isEmpty / hasError reflect status', () {
      const loading = GardenState(status: GardenStatus.loading);
      const empty = GardenState(status: GardenStatus.empty);
      const error = GardenState(status: GardenStatus.error);

      expect(loading.isLoading, isTrue);
      expect(empty.isEmpty, isTrue);
      expect(error.hasError, isTrue);
    });

    test('isOpLoading / isOpSuccess reflect opStatus', () {
      const opLoading = GardenState(opStatus: GardenOpStatus.loading);
      const opSuccess = GardenState(opStatus: GardenOpStatus.success);

      expect(opLoading.isOpLoading, isTrue);
      expect(opSuccess.isOpSuccess, isTrue);
    });

    test('defaultGarden returns first isDefault garden', () {
      const state = GardenState(gardens: [testGarden1, testGarden2]);
      expect(state.defaultGarden?.id, equals('g-2'));
    });

    test('defaultGarden returns first garden when none is default', () {
      const noDefault = Garden(
        id: 'g-x',
        userId: 'u-1',
        name: 'X',
        isDefault: false,
      );
      const state = GardenState(gardens: [noDefault]);
      expect(state.defaultGarden?.id, equals('g-x'));
    });

    test('defaultGarden returns null for empty list', () {
      const state = GardenState();
      expect(state.defaultGarden, isNull);
    });
  });
}
