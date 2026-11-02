import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

enum RideStatus {
  pending,      // Solicitado por cliente, esperando chofer
  accepted,     // Chofer aceptó el viaje
  inProgress,   // Chofer inició el viaje
  completed,    // Viaje finalizado
  cancelled,    // Cancelado
}

class RideLocation {
  final String address;
  final double latitude;
  final double longitude;

  RideLocation({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory RideLocation.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return RideLocation(address: 'Ubicación desconocida', latitude: 0, longitude: 0);
    }
    return RideLocation(
      address: map['address'] ?? 'Ubicación',
      latitude: (map['latitude'] is num) ? (map['latitude'] as num).toDouble() : 0.0,
      longitude: (map['longitude'] is num) ? (map['longitude'] as num).toDouble() : 0.0,
    );
  }
}

class RideModel {
  final String id;
  final String clientId;
  final String clientName;
  final double clientRating;
  final String? driverId;
  final String? driverName;
  final String? driverVehicle;
  final double? driverRating;
  final RideLocation origin;
  final RideLocation destination;
  final double fare;
  final double distanceKm;
  final int durationMin;
  final RideStatus status;
  final double? ratingForDriver;
  final double? ratingForClient;
  final DateTime createdAt;
  final DateTime updatedAt;

  RideModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    this.clientRating = 5.0,
    this.driverId,
    this.driverName,
    this.driverVehicle,
    this.driverRating,
    required this.origin,
    required this.destination,
    required this.fare,
    required this.distanceKm,
    required this.durationMin,
    this.status = RideStatus.pending,
    this.ratingForDriver,
    this.ratingForClient,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String get statusLabel {
    switch (status) {
      case RideStatus.pending:
        return 'Buscando conductor...';
      case RideStatus.accepted:
        return 'Conductor en camino';
      case RideStatus.inProgress:
        return 'En viaje';
      case RideStatus.completed:
        return 'Viaje finalizado';
      case RideStatus.cancelled:
        return 'Cancelado';
    }
  }

  Color get statusColor {
    switch (status) {
      case RideStatus.pending:
        return AppColors.statusPending;
      case RideStatus.accepted:
        return AppColors.statusAccepted;
      case RideStatus.inProgress:
        return AppColors.statusInProgress;
      case RideStatus.completed:
        return AppColors.statusCompleted;
      case RideStatus.cancelled:
        return AppColors.statusCancelled;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'clientRating': clientRating,
      'driverId': driverId,
      'driverName': driverName,
      'driverVehicle': driverVehicle,
      'driverRating': driverRating,
      'origin': origin.toMap(),
      'destination': destination.toMap(),
      'fare': fare,
      'distanceKm': distanceKm,
      'durationMin': durationMin,
      'status': status.name,
      'ratingForDriver': ratingForDriver,
      'ratingForClient': ratingForClient,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory RideModel.fromMap(Map<String, dynamic> map, String id) {
    return RideModel(
      id: id,
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? 'Cliente',
      clientRating: (map['clientRating'] is num) ? (map['clientRating'] as num).toDouble() : 5.0,
      driverId: map['driverId'],
      driverName: map['driverName'],
      driverVehicle: map['driverVehicle'],
      driverRating: (map['driverRating'] is num) ? (map['driverRating'] as num).toDouble() : null,
      origin: RideLocation.fromMap(map['origin']),
      destination: RideLocation.fromMap(map['destination']),
      fare: (map['fare'] is num) ? (map['fare'] as num).toDouble() : 0.0,
      distanceKm: (map['distanceKm'] is num) ? (map['distanceKm'] as num).toDouble() : 0.0,
      durationMin: (map['durationMin'] is num) ? (map['durationMin'] as num).toInt() : 0,
      status: RideStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RideStatus.pending,
      ),
      ratingForDriver: (map['ratingForDriver'] is num) ? (map['ratingForDriver'] as num).toDouble() : null,
      ratingForClient: (map['ratingForClient'] is num) ? (map['ratingForClient'] as num).toDouble() : null,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
