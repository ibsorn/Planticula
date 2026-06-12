import 'package:planticula/core/constants/app_constants.dart';
import 'package:planticula/core/data/species/plant_species.dart';

/// Calculates whether a plant needs to be transplanted to a larger pot,
/// based on its species transplant schedule, current pot size, growth stage,
/// and how long it has been in the current stage.
///
/// Design: pure functions, no state. Takes what it needs, returns a
/// [TransplantRecommendation] that the UI and notification systems can consume.
class TransplantCalculator {
  /// Evaluate whether a plant needs transplanting.
  ///
  /// [species]          - the plant's species, carrying the transplant schedule
  /// [currentPotSize]   - the pot the plant is currently in
  /// [currentStage]     - the plant's current growth stage
  /// [plantedDate]      - when the plant was acquired / first potted (used to
  ///                      estimate time in current stage)
  /// [lastTransplanted] - last time the user registered a transplant (optional)
  static TransplantRecommendation evaluate({
    required PlantSpecies species,
    required PotSize currentPotSize,
    required GrowthStage currentStage,
    DateTime? plantedDate,
    DateTime? lastTransplanted,
  }) {
    // No schedule defined → nothing to say
    if (!species.hasTransplantSchedule) {
      return const TransplantRecommendation._none();
    }

    final phaseInfo = species.getTransplantInfo(currentStage);
    if (phaseInfo == null) {
      return const TransplantRecommendation._none();
    }

    // --- 1. Check if current pot is already too small (urgent) ---
    final potIndex = PotSize.values.indexOf(currentPotSize);
    final minIndex = PotSize.values.indexOf(phaseInfo.minPotSize);

    if (potIndex < minIndex) {
      return TransplantRecommendation(
        status: TransplantStatus.urgent,
        currentPotSize: currentPotSize,
        recommendedPotSize: phaseInfo.idealPotSize,
        minPotSize: phaseInfo.minPotSize,
        reason: 'La maceta actual es demasiado pequeña para la fase ${currentStage.displayName}',
        notes: phaseInfo.notes,
      );
    }

    // --- 1b. neverTransplant sentinel: skip time-based logic entirely ---
    if (phaseInfo.triggerAfterMonths == AppConstants.neverTransplant) {
      return const TransplantRecommendation._none();
    }

    // --- 2. Time-based check: has the plant been in this stage long enough? ---
    // We estimate time in current stage from: lastTransplanted ?? plantedDate
    final referenceDate = lastTransplanted ?? plantedDate;
    if (referenceDate == null) {
      // No date info: give a gentle suggestion if pot is below ideal
      if (potIndex < PotSize.values.indexOf(phaseInfo.idealPotSize)) {
        return TransplantRecommendation(
          status: TransplantStatus.due,
          currentPotSize: currentPotSize,
          recommendedPotSize: phaseInfo.idealPotSize,
          minPotSize: phaseInfo.minPotSize,
          reason: 'La maceta ideal para esta fase es ${phaseInfo.idealPotSize.displayName}',
          notes: phaseInfo.notes,
        );
      }
      return const TransplantRecommendation._none();
    }

    final monthsInStage = _monthsBetween(referenceDate, DateTime.now());

    if (monthsInStage >= phaseInfo.triggerAfterMonths) {
      // Pot is at or above ideal → no action needed
      final idealIndex = PotSize.values.indexOf(phaseInfo.idealPotSize);
      if (potIndex >= idealIndex) {
        return const TransplantRecommendation._none();
      }

      // How overdue?
      final monthsOverdue = monthsInStage - phaseInfo.triggerAfterMonths;
      final status = monthsOverdue >= 3
          ? TransplantStatus.urgent
          : TransplantStatus.due;

      return TransplantRecommendation(
        status: status,
        currentPotSize: currentPotSize,
        recommendedPotSize: phaseInfo.idealPotSize,
        minPotSize: phaseInfo.minPotSize,
        monthsInCurrentStage: monthsInStage,
        monthsOverdue: monthsOverdue > 0 ? monthsOverdue : null,
        reason: monthsOverdue >= 3
            ? 'Llevas $monthsInStage meses en esta maceta, es momento de un trasplante'
            : 'La planta esta lista para una maceta mas grande',
        notes: phaseInfo.notes,
      );
    }

    // Not yet time — give a preview if it's approaching (within 1 month)
    final monthsUntilDue = phaseInfo.triggerAfterMonths - monthsInStage;
    if (monthsUntilDue <= 1 &&
        potIndex < PotSize.values.indexOf(phaseInfo.idealPotSize)) {
      return TransplantRecommendation(
        status: TransplantStatus.upcoming,
        currentPotSize: currentPotSize,
        recommendedPotSize: phaseInfo.idealPotSize,
        minPotSize: phaseInfo.minPotSize,
        monthsInCurrentStage: monthsInStage,
        monthsUntilDue: monthsUntilDue,
        reason: 'En aproximadamente $monthsUntilDue mes tendra que trasplantar',
        notes: phaseInfo.notes,
      );
    }

    return const TransplantRecommendation._none();
  }

  static int _monthsBetween(DateTime from, DateTime to) {
    return (to.year - from.year) * 12 + (to.month - from.month);
  }
}

/// The urgency level of a transplant recommendation.
enum TransplantStatus {
  /// No action needed.
  none,

  /// Within the next month — give the user a heads-up.
  upcoming,

  /// Time to transplant now.
  due,

  /// Pot is too small or significantly overdue — act soon.
  urgent;

  String get displayName {
    switch (this) {
      case TransplantStatus.none:
        return 'Sin cambios necesarios';
      case TransplantStatus.upcoming:
        return 'Proximamente';
      case TransplantStatus.due:
        return 'Es hora de trasplantar';
      case TransplantStatus.urgent:
        return 'Trasplante urgente';
    }
  }
}

/// Result of [TransplantCalculator.evaluate]. Immutable value object.
class TransplantRecommendation {
  final TransplantStatus status;
  final PotSize? currentPotSize;
  final PotSize? recommendedPotSize;
  final PotSize? minPotSize;
  final String? reason;
  final String? notes;
  final int? monthsInCurrentStage;
  final int? monthsOverdue;
  final int? monthsUntilDue;

  const TransplantRecommendation({
    required this.status,
    this.currentPotSize,
    this.recommendedPotSize,
    this.minPotSize,
    this.reason,
    this.notes,
    this.monthsInCurrentStage,
    this.monthsOverdue,
    this.monthsUntilDue,
  });

  /// Convenience constructor for "no action needed"
  const TransplantRecommendation._none()
      : status = TransplantStatus.none,
        currentPotSize = null,
        recommendedPotSize = null,
        minPotSize = null,
        reason = null,
        notes = null,
        monthsInCurrentStage = null,
        monthsOverdue = null,
        monthsUntilDue = null;

  bool get needsAction => status != TransplantStatus.none;
  bool get isUrgent => status == TransplantStatus.urgent;
  bool get isDue => status == TransplantStatus.due || status == TransplantStatus.urgent;
}
