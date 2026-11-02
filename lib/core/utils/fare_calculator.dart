import 'dart:math';

class FareCalculator {
  // Constantes de tarifa base
  static const double baseFare = 1500.0;     // Tarifa base inicial ($)
  static const double pricePerKm = 500.0;    // Precio por kilómetro ($)
  static const double pricePerMinute = 80.0; // Precio por minuto ($)
  static const double averageSpeedKmh = 28.0;// Velocidad promedio en ciudad (km/h)

  /// Calcula la distancia en kilómetros usando la fórmula de Haversine
  static double calculateDistanceKm({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    const earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(endLat - startLat);
    final dLng = _degreesToRadians(endLng - startLng);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(startLat)) *
            cos(_degreesToRadians(endLat)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final distance = earthRadiusKm * c;

    // Redondear a 1 decimal y asegurar un mínimo de 0.5 km
    return max(0.5, double.parse(distance.toStringAsFixed(1)));
  }

  /// Calcula el tiempo estimado en minutos
  static int calculateEstimatedMinutes(double distanceKm) {
    final hours = distanceKm / averageSpeedKmh;
    final minutes = (hours * 60).round() + 3; // +3 min de margen por semáforos/tráfico
    return max(5, minutes);
  }

  /// Calcula la tarifa total estimada
  static double calculateEstimatedFare({
    required double distanceKm,
    required int durationMin,
  }) {
    final fare = baseFare + (distanceKm * pricePerKm) + (durationMin * pricePerMinute);
    // Redondear a números múltiplos de 50 para precios realistas
    return (fare / 50).round() * 50.0;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
}
