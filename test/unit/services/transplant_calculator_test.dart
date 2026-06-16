import 'package:flutter_test/flutter_test.dart';
import 'package:planticula/core/constants/app_constants.dart';
import 'package:planticula/core/data/species/plant_species.dart';
import 'package:planticula/core/services/transplant_calculator.dart';

void main() {
  group('TransplantCalculator', () {
    const testSpeciesWithSchedule = PlantSpecies(
      id: 'test_transplant',
      commonName: 'Test',
      scientificName: 'Testus transplantus',
      category: 'indoor',
      wateringFrequencyIndoor: 7,
      wateringFrequencyOutdoor: 5,
      sunlightHoursMin: 4,
      sunlightHoursMax: 8,
      sunlightLevel: SunlightLevel.medium,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.mature, durationMonths: 0),
      ],
      transplantSchedule: [
        TransplantPhaseInfo(
          stage: GrowthStage.mature,
          minPotSize: PotSize.small,
          idealPotSize: PotSize.medium,
          triggerAfterMonths: 12,
        ),
      ],
    );

    const testSpeciesWithoutSchedule = PlantSpecies(
      id: 'test_no_schedule',
      commonName: 'Test No Schedule',
      scientificName: 'Testus noschedule',
      category: 'indoor',
      wateringFrequencyIndoor: 7,
      wateringFrequencyOutdoor: 5,
      sunlightHoursMin: 4,
      sunlightHoursMax: 8,
      sunlightLevel: SunlightLevel.medium,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.mature, durationMonths: 0),
      ],
    );

    const testSpeciesNeverTransplant = PlantSpecies(
      id: 'test_never',
      commonName: 'Test Never',
      scientificName: 'Testus neverus',
      category: 'outdoor',
      wateringFrequencyIndoor: 7,
      wateringFrequencyOutdoor: 5,
      sunlightHoursMin: 6,
      sunlightHoursMax: 10,
      sunlightLevel: SunlightLevel.fullSun,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.mature, durationMonths: 0),
      ],
      transplantSchedule: [
        TransplantPhaseInfo(
          stage: GrowthStage.mature,
          minPotSize: PotSize.medium,
          idealPotSize: PotSize.large,
          triggerAfterMonths: AppConstants.neverTransplant,
        ),
      ],
    );

    test('species without schedule returns status == TransplantStatus.none', () {
      final result = TransplantCalculator.evaluate(
        species: testSpeciesWithoutSchedule,
        currentPotSize: PotSize.small,
        currentStage: GrowthStage.mature,
      );

      expect(result.status, equals(TransplantStatus.none));
      expect(result.needsAction, isFalse);
    });

    test('triggerAfterMonths == neverTransplant (999) returns status == TransplantStatus.none', () {
      final result = TransplantCalculator.evaluate(
        species: testSpeciesNeverTransplant,
        currentPotSize: PotSize.medium, // medium >= medium (minPotSize) so pot size check passes
        currentStage: GrowthStage.mature,
        plantedDate: DateTime.now().subtract(const Duration(days: 365)),
      );

      expect(result.status, equals(TransplantStatus.none));
      expect(result.needsAction, isFalse);
    });

    test('current pot too small (currentPotSize < minPotSize) returns status == TransplantStatus.urgent', () {
      final result = TransplantCalculator.evaluate(
        species: testSpeciesWithSchedule,
        currentPotSize: PotSize.extraSmall, // extraSmall < small (minPotSize)
        currentStage: GrowthStage.mature,
      );

      expect(result.status, equals(TransplantStatus.urgent));
      expect(result.needsAction, isTrue);
      expect(result.isUrgent, isTrue);
    });

    test('no reference date + pot < ideal returns status == TransplantStatus.due', () {
      final result = TransplantCalculator.evaluate(
        species: testSpeciesWithSchedule,
        currentPotSize: PotSize.small, // small < medium (ideal)
        currentStage: GrowthStage.mature,
        // No plantedDate or lastTransplanted
      );

      expect(result.status, equals(TransplantStatus.due));
      expect(result.needsAction, isTrue);
      expect(result.recommendedPotSize, equals(PotSize.medium));
    });

    test('no reference date + pot >= ideal returns status == TransplantStatus.none', () {
      final result = TransplantCalculator.evaluate(
        species: testSpeciesWithSchedule,
        currentPotSize: PotSize.medium, // medium >= medium (ideal)
        currentStage: GrowthStage.mature,
        // No plantedDate or lastTransplanted
      );

      expect(result.status, equals(TransplantStatus.none));
      expect(result.needsAction, isFalse);
    });

    test('13 months ago + triggerAfterMonths 12 + pot < ideal returns status due or urgent', () {
      final thirteenMonthsAgo = DateTime.now().subtract(const Duration(days: 395));

      final result = TransplantCalculator.evaluate(
        species: testSpeciesWithSchedule,
        currentPotSize: PotSize.small,
        currentStage: GrowthStage.mature,
        plantedDate: thirteenMonthsAgo,
      );

      // 13 months - 12 months trigger = 1 month overdue (not yet urgent)
      expect(result.status, equals(TransplantStatus.due));
      expect(result.needsAction, isTrue);
      expect(result.monthsInCurrentStage, equals(13));
      expect(result.monthsOverdue, equals(1));
    });

    test('16 months ago (3+ months overdue) returns status == TransplantStatus.urgent', () {
      final sixteenMonthsAgo = DateTime.now().subtract(const Duration(days: 487));

      final result = TransplantCalculator.evaluate(
        species: testSpeciesWithSchedule,
        currentPotSize: PotSize.small,
        currentStage: GrowthStage.mature,
        plantedDate: sixteenMonthsAgo,
      );

      // 16 months - 12 months trigger = 4 months overdue (>= 3 makes it urgent)
      expect(result.status, equals(TransplantStatus.urgent));
      expect(result.needsAction, isTrue);
      expect(result.isUrgent, isTrue);
      expect(result.monthsInCurrentStage, equals(16));
      expect(result.monthsOverdue, greaterThanOrEqualTo(3));
    });

    test('11 months ago + triggerAfterMonths 12 + pot < ideal returns status == TransplantStatus.upcoming', () {
      final elevenMonthsAgo = DateTime.now().subtract(const Duration(days: 335));

      final result = TransplantCalculator.evaluate(
        species: testSpeciesWithSchedule,
        currentPotSize: PotSize.small,
        currentStage: GrowthStage.mature,
        plantedDate: elevenMonthsAgo,
      );

      // 12 - 11 = 1 month until due (within 1 month makes it upcoming)
      expect(result.status, equals(TransplantStatus.upcoming));
      expect(result.needsAction, isTrue); // upcoming is not none, so it needs action (preview)
      expect(result.monthsUntilDue, equals(1));
    });

    test('6 months ago + triggerAfterMonths 12 returns status == TransplantStatus.none', () {
      final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 183));

      final result = TransplantCalculator.evaluate(
        species: testSpeciesWithSchedule,
        currentPotSize: PotSize.small,
        currentStage: GrowthStage.mature,
        plantedDate: sixMonthsAgo,
      );

      // 6 months is well before the 12 month trigger
      expect(result.status, equals(TransplantStatus.none));
      expect(result.needsAction, isFalse);
    });

    test('pot already at ideal or larger returns status == TransplantStatus.none even if time passed', () {
      final sixteenMonthsAgo = DateTime.now().subtract(const Duration(days: 487));

      final result = TransplantCalculator.evaluate(
        species: testSpeciesWithSchedule,
        currentPotSize: PotSize.large, // large > medium (ideal)
        currentStage: GrowthStage.mature,
        plantedDate: sixteenMonthsAgo,
      );

      // Even though time has passed, pot is already larger than ideal
      expect(result.status, equals(TransplantStatus.none));
      expect(result.needsAction, isFalse);
    });

    test('uses lastTransplanted over plantedDate when available', () {
      final tenMonthsAgo = DateTime.now().subtract(const Duration(days: 304));
      final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 91));

      // If we only consider plantedDate (10 months ago), it would be due
      // But lastTransplanted (3 months ago) should take precedence
      final result = TransplantCalculator.evaluate(
        species: testSpeciesWithSchedule,
        currentPotSize: PotSize.small,
        currentStage: GrowthStage.mature,
        plantedDate: tenMonthsAgo,
        lastTransplanted: threeMonthsAgo,
      );

      // Should use lastTransplanted (3 months), not plantedDate (10 months)
      // 3 months < 12 months trigger, so no action needed yet
      expect(result.status, equals(TransplantStatus.none));
      expect(result.needsAction, isFalse);
    });

    test('juvenile stage with different schedule', () {
      const speciesWithJuvenileSchedule = PlantSpecies(
        id: 'test_juvenile',
        commonName: 'Test Juvenile',
        scientificName: 'Testus juvenilus',
        category: 'indoor',
        wateringFrequencyIndoor: 7,
        wateringFrequencyOutdoor: 5,
        sunlightHoursMin: 4,
        sunlightHoursMax: 8,
        sunlightLevel: SunlightLevel.medium,
        growthPhases: [
          GrowthPhaseInfo(stage: GrowthStage.development, durationMonths: 6, wateringMultiplier: 0.85),
          GrowthPhaseInfo(stage: GrowthStage.mature, durationMonths: 0),
        ],
        transplantSchedule: [
          TransplantPhaseInfo(
            stage: GrowthStage.development,
            minPotSize: PotSize.extraSmall,
            idealPotSize: PotSize.small,
            triggerAfterMonths: 3,
          ),
          TransplantPhaseInfo(
            stage: GrowthStage.mature,
            minPotSize: PotSize.small,
            idealPotSize: PotSize.medium,
            triggerAfterMonths: 12,
          ),
        ],
      );

      final fourMonthsAgo = DateTime.now().subtract(const Duration(days: 122));

      final result = TransplantCalculator.evaluate(
        species: speciesWithJuvenileSchedule,
        currentPotSize: PotSize.extraSmall,
        currentStage: GrowthStage.development,
        plantedDate: fourMonthsAgo,
      );

      // 4 months - 3 months trigger = 1 month overdue, pot < ideal
      expect(result.status, equals(TransplantStatus.due));
      expect(result.needsAction, isTrue);
    });

    test('seedling stage with triggerAfterMonths 0 alerts immediately', () {
      const speciesWithSeedlingSchedule = PlantSpecies(
        id: 'test_seedling',
        commonName: 'Test Seedling',
        scientificName: 'Testus seedlingus',
        category: 'indoor',
        wateringFrequencyIndoor: 7,
        wateringFrequencyOutdoor: 5,
        sunlightHoursMin: 4,
        sunlightHoursMax: 8,
        sunlightLevel: SunlightLevel.medium,
        growthPhases: [
          GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 3, wateringMultiplier: 0.7),
          GrowthPhaseInfo(stage: GrowthStage.mature, durationMonths: 0),
        ],
        transplantSchedule: [
          TransplantPhaseInfo(
            stage: GrowthStage.seedling,
            minPotSize: PotSize.extraSmall,
            idealPotSize: PotSize.small,
            // triggerAfterMonths: 0 is the default - alert fires immediately
          ),
        ],
      );

      // Just planted today
      final result = TransplantCalculator.evaluate(
        species: speciesWithSeedlingSchedule,
        currentPotSize: PotSize.extraSmall,
        currentStage: GrowthStage.seedling,
        plantedDate: DateTime.now(),
      );

      // triggerAfterMonths: 0 means alert as soon as stage starts
      // But pot is at min, not ideal, so it should be due
      expect(result.status, equals(TransplantStatus.due));
      expect(result.needsAction, isTrue);
    });
  });
}
