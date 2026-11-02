import 'package:geolocator/geolocator.dart';

class LocationService {
  // Coordenadas por defecto (Centro de Buenos Aires / Obelisco) si no hay GPS disponible
  static const double defaultLatitude = -34.6037;
  static const double defaultLongitude = -58.3816;

  /// Obtiene la posición actual del usuario con manejo robusto de permisos
  static Future<Position?> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
    } catch (_) {
      return null;
    }
  }
}
