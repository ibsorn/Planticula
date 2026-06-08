import 'package:equatable/equatable.dart';

/// Entidad Plant - Representa una planta del usuario
///
/// Campos principales:
/// - id: UUID generado por Supabase
/// - name: Nombre personalizado de la planta
/// - scientificName: Nombre científico (opcional)
/// - speciesId: Referencia a tabla de especies (opcional)
/// - imageUrl: URL de la imagen en Storage (opcional)
/// - location: Ubicación en casa (ej: "Sala", "Terraza")
/// - notes: Notas adicionales
/// - wateringFrequency: Días entre riegos (null = sin recordatorio)
/// - lastWatered: Última fecha de riego
/// - nextWatering: Próxima fecha calculada
/// - acquiredDate: Fecha de adquisición
/// - createdAt/updatedAt: Timestamps automáticos
class Plant extends Equatable {
  final String id;
  final String name;
  final String? scientificName;
  final String? speciesId;
  final String? imageUrl;
  final String? location;
  final String? notes;
  final int? wateringFrequency; // Días entre riegos
  final DateTime? lastWatered;
  final DateTime? nextWatering; // Calculado: lastWatered + wateringFrequency
  final DateTime? acquiredDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Plant({
    required this.id,
    required this.name,
    this.scientificName,
    this.speciesId,
    this.imageUrl,
    this.location,
    this.notes,
    this.wateringFrequency,
    this.lastWatered,
    this.nextWatering,
    this.acquiredDate,
    this.createdAt,
    this.updatedAt,
  });

  /// Crea una copia con algunos campos modificados
  Plant copyWith({
    String? id,
    String? name,
    String? scientificName,
    String? speciesId,
    String? imageUrl,
    String? location,
    String? notes,
    int? wateringFrequency,
    DateTime? lastWatered,
    DateTime? nextWatering,
    DateTime? acquiredDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Plant(
      id: id ?? this.id,
      name: name ?? this.name,
      scientificName: scientificName ?? this.scientificName,
      speciesId: speciesId ?? this.speciesId,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      wateringFrequency: wateringFrequency ?? this.wateringFrequency,
      lastWatered: lastWatered ?? this.lastWatered,
      nextWatering: nextWatering ?? this.nextWatering,
      acquiredDate: acquiredDate ?? this.acquiredDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Calcula si la planta necesita riego
  bool get needsWatering {
    if (nextWatering == null) return false;
    return DateTime.now().isAfter(nextWatering!) ||
        DateTime.now().isAtSameMomentAs(nextWatering!);
  }

  /// Días restantes hasta el próximo riego (puede ser negativo si está atrasado)
  int? get daysUntilWatering {
    if (nextWatering == null) return null;
    return nextWatering!.difference(DateTime.now()).inDays;
  }

  /// Indica si tiene configurado recordatorio de riego
  bool get hasWateringReminder => wateringFrequency != null && wateringFrequency! > 0;

  @override
  List<Object?> get props => [
        id,
        name,
        scientificName,
        speciesId,
        imageUrl,
        location,
        notes,
        wateringFrequency,
        lastWatered,
        nextWatering,
        acquiredDate,
        createdAt,
        updatedAt,
      ];
}
