import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/ride_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _ridesCol =>
      _firestore.collection('rides');

  /// 1. Crear una nueva solicitud de viaje (Cliente)
  Future<String> requestRide(RideModel ride) async {
    final docRef = _ridesCol.doc();
    final rideWithId = RideModel(
      id: docRef.id,
      clientId: ride.clientId,
      clientName: ride.clientName,
      clientRating: ride.clientRating,
      origin: ride.origin,
      destination: ride.destination,
      fare: ride.fare,
      distanceKm: ride.distanceKm,
      durationMin: ride.durationMin,
      status: RideStatus.pending,
    );

    await docRef.set(rideWithId.toMap());
    return docRef.id;
  }

  /// 2. Stream de choferes disponibles en el mapa
  Stream<List<UserModel>> streamAvailableDrivers() {
    return _usersCol
        .where('role', isEqualTo: 'driver')
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// 3. Stream de solicitudes pendientes para que los choferes las vean
  Stream<List<RideModel>> streamPendingRides() {
    return _ridesCol
        .where('status', isEqualTo: RideStatus.pending.name)
        .snapshots()
        .map((snapshot) {
          final rides = snapshot.docs
              .map((doc) => RideModel.fromMap(doc.data(), doc.id))
              .toList();
          // Ordenar en memoria por fecha más reciente
          rides.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return rides;
        });
  }

  /// 4. Stream del viaje activo de un cliente (para seguimiento)
  Stream<RideModel?> streamActiveRideForClient(String clientId) {
    return _ridesCol
        .where('clientId', isEqualTo: clientId)
        .where('status', whereIn: [
          RideStatus.pending.name,
          RideStatus.accepted.name,
          RideStatus.inProgress.name,
        ])
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return RideModel.fromMap(
            snapshot.docs.first.data(),
            snapshot.docs.first.id,
          );
        });
  }

  /// 5. Stream del viaje activo de un chofer
  Stream<RideModel?> streamActiveRideForDriver(String driverId) {
    return _ridesCol
        .where('driverId', isEqualTo: driverId)
        .where('status', whereIn: [
          RideStatus.accepted.name,
          RideStatus.inProgress.name,
        ])
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return RideModel.fromMap(
            snapshot.docs.first.data(),
            snapshot.docs.first.id,
          );
        });
  }

  /// 6. Stream de un viaje específico por ID
  Stream<RideModel?> streamRideById(String rideId) {
    return _ridesCol.doc(rideId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return RideModel.fromMap(doc.data()!, doc.id);
    });
  }

  /// 7. Chofer acepta un viaje
  Future<void> acceptRide({
    required String rideId,
    required UserModel driver,
  }) async {
    final vehicleDesc = driver.vehicle != null
        ? '${driver.vehicle!.model} (${driver.vehicle!.color}) - ${driver.vehicle!.plate}'
        : 'Auto Estándar';

    await _ridesCol.doc(rideId).update({
      'driverId': driver.uid,
      'driverName': driver.name,
      'driverVehicle': vehicleDesc,
      'driverRating': driver.rating,
      'status': RideStatus.accepted.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// 8. Cambiar estado del viaje (ej: de aceptado a en curso, o finalizado)
  Future<void> updateRideStatus(String rideId, RideStatus status) async {
    await _ridesCol.doc(rideId).update({
      'status': status.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// 9. Cancelar viaje
  Future<void> cancelRide(String rideId) async {
    await _ridesCol.doc(rideId).update({
      'status': RideStatus.cancelled.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// 10. Calificar al conductor o al cliente
  Future<void> rateRide({
    required String rideId,
    required String targetUserId,
    required bool isClientRatingDriver,
    required double rating,
  }) async {
    final updateField = isClientRatingDriver ? 'ratingForDriver' : 'ratingForClient';

    // Actualizar registro del viaje
    await _ridesCol.doc(rideId).update({
      updateField: rating,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    // Actualizar promedio del usuario calificado
    final userDoc = await _usersCol.doc(targetUserId).get();
    if (userDoc.exists && userDoc.data() != null) {
      final data = userDoc.data()!;
      final currentRating = (data['rating'] as num?)?.toDouble() ?? 5.0;
      final totalRatings = (data['totalRatings'] as int?) ?? 1;

      final newTotal = totalRatings + 1;
      final newAverage = ((currentRating * totalRatings) + rating) / newTotal;

      await _usersCol.doc(targetUserId).update({
        'rating': double.parse(newAverage.toStringAsFixed(2)),
        'totalRatings': newTotal,
      });
    }
  }

  /// 11. Historial de viajes del usuario
  Stream<List<RideModel>> streamUserHistory({
    required String userId,
    required bool isDriver,
  }) {
    final field = isDriver ? 'driverId' : 'clientId';

    return _ridesCol
        .where(field, isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => RideModel.fromMap(doc.data(), doc.id))
              .where((r) => r.status == RideStatus.completed || r.status == RideStatus.cancelled)
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  /// 12. Actualizar ubicación del chofer (para mostrar en vivo)
  Future<void> updateDriverLocation({
    required String driverId,
    required double lat,
    required double lng,
  }) async {
    await _usersCol.doc(driverId).update({
      'currentLat': lat,
      'currentLng': lng,
    });
  }
}
