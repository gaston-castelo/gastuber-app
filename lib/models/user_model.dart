enum UserRole { client, driver }

class VehicleInfo {
  final String model;
  final String plate;
  final String color;

  VehicleInfo({
    required this.model,
    required this.plate,
    required this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'model': model,
      'plate': plate,
      'color': color,
    };
  }

  factory VehicleInfo.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return VehicleInfo(model: 'Auto Estándar', plate: '---', color: 'Gris');
    }
    return VehicleInfo(
      model: map['model'] ?? 'Auto Estándar',
      plate: map['plate'] ?? '---',
      color: map['color'] ?? 'Gris',
    );
  }
}

class UserModel {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final double rating;
  final int totalRatings;
  final VehicleInfo? vehicle;
  final bool isAvailable;
  final double? currentLat;
  final double? currentLng;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.rating = 5.0,
    this.totalRatings = 1,
    this.vehicle,
    this.isAvailable = true,
    this.currentLat,
    this.currentLng,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isDriver => role == UserRole.driver;
  bool get isClient => role == UserRole.client;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role.name,
      'rating': rating,
      'totalRatings': totalRatings,
      'vehicle': vehicle?.toMap(),
      'isAvailable': isAvailable,
      'currentLat': currentLat,
      'currentLng': currentLng,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      name: map['name'] ?? 'Usuario',
      email: map['email'] ?? '',
      role: (map['role'] == 'driver') ? UserRole.driver : UserRole.client,
      rating: (map['rating'] is num) ? (map['rating'] as num).toDouble() : 5.0,
      totalRatings: map['totalRatings'] ?? 1,
      vehicle: map['vehicle'] != null ? VehicleInfo.fromMap(map['vehicle']) : null,
      isAvailable: map['isAvailable'] ?? true,
      currentLat: (map['currentLat'] is num) ? (map['currentLat'] as num).toDouble() : null,
      currentLng: (map['currentLng'] is num) ? (map['currentLng'] as num).toDouble() : null,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
