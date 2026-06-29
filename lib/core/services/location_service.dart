import 'package:geolocator/geolocator.dart';
import 'package:planticula/core/utils/logger.dart';

/// Coordenadas geográficas simples.
class GeoCoordinates {
  final double latitude;
  final double longitude;

  const GeoCoordinates({required this.latitude, required this.longitude});
}

/// Encapsula el acceso a la API de geolocalización de la plataforma.
///
/// Mantiene el manejo de permisos y la obtención de posición fuera de la capa
/// de UI, de modo que las pantallas no dependan directamente de [Geolocator]
/// y la lógica sea testeable/mockeable.
class LocationService {
  /// Solicita permisos (si hace falta) y devuelve la posición actual.
  ///
  /// Devuelve `null` si el permiso es denegado o si ocurre cualquier error,
  /// permitiendo a quien lo llama degradar de forma elegante.
  Future<GeoCoordinates?> getCurrentCoordinates() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition();
        return GeoCoordinates(latitude: pos.latitude, longitude: pos.longitude);
      }
    } catch (e) {
      Logger.w('Location unavailable: $e');
    }
    return null;
  }
}
