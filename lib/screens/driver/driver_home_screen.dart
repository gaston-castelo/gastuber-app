import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/ride_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../widgets/ride_card.dart';
import 'active_ride_screen.dart';
import '../history/ride_history_screen.dart';
import '../auth/login_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isOnline = true;
  StreamSubscription<RideModel?>? _activeRideSub;

  @override
  void initState() {
    super.initState();
    _checkActiveRide();
  }

  @override
  void dispose() {
    _activeRideSub?.cancel();
    super.dispose();
  }

  void _checkActiveRide() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        _activeRideSub = _firestoreService.streamActiveRideForDriver(user.uid).listen((ride) {
          if (ride != null && mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ActiveRideScreen(initialRide: ride)),
            );
          }
        });
      }
    });
  }

  Future<void> _handleAcceptRide(RideModel ride, UserModel driver) async {
    try {
      await _firestoreService.acceptRide(rideId: ride.id, driver: driver);

      if (mounted) {
        final acceptedRide = RideModel(
          id: ride.id,
          clientId: ride.clientId,
          clientName: ride.clientName,
          clientRating: ride.clientRating,
          driverId: driver.uid,
          driverName: driver.name,
          driverVehicle: driver.vehicle != null
              ? '${driver.vehicle!.model} (${driver.vehicle!.color})'
              : 'Auto Estándar',
          driverRating: driver.rating,
          origin: ride.origin,
          destination: ride.destination,
          fare: ride.fare,
          distanceKm: ride.distanceKm,
          durationMin: ride.durationMin,
          status: RideStatus.accepted,
        );

        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ActiveRideScreen(initialRide: acceptedRide)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo aceptar el viaje: $e'),
            backgroundColor: AppColors.statusCancelled,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Panel del Conductor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Historial de viajes',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RideHistoryScreen(isDriver: true)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await authProvider.logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Tarjeta de Perfil del Chofer y Estado Conectado / Desconectado
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.accent,
                        child: Text(
                          user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'C',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? 'Conductor',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.vehicle != null
                                  ? '${user!.vehicle!.model} • ${user.vehicle!.plate}'
                                  : 'Auto no configurado',
                              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: AppColors.starRating, size: 16),
                                Text(
                                  ' ${user?.rating.toStringAsFixed(1) ?? "5.0"} (${user?.totalRatings ?? 1} calificaciones)',
                                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: AppColors.primaryLight),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _isOnline ? AppColors.accent : AppColors.textMuted,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isOnline ? 'En línea (recibiendo viajes)' : 'Desconectado',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _isOnline,
                        activeColor: AppColors.accent,
                        onChanged: (val) {
                          setState(() => _isOnline = val);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Título de Solicitudes Pendientes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Solicitudes de Viaje',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  StreamBuilder<List<RideModel>>(
                    stream: _firestoreService.streamPendingRides(),
                    builder: (context, snapshot) {
                      final count = snapshot.data?.length ?? 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: count > 0 ? AppColors.statusPending.withOpacity(0.15) : AppColors.inputFill,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$count disponibles',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: count > 0 ? AppColors.statusPending : AppColors.textSecondary,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Lista de solicitudes en tiempo real
            Expanded(
              child: !_isOnline
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.power_settings_new_rounded, size: 50, color: AppColors.textMuted),
                          SizedBox(height: 12),
                          Text(
                            'Estás desconectado',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Activa el interruptor arriba para ver solicitudes',
                            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    )
                  : StreamBuilder<List<RideModel>>(
                      stream: _firestoreService.streamPendingRides(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final rides = snapshot.data ?? [];

                        if (rides.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.search_rounded, size: 48, color: AppColors.textMuted),
                                  SizedBox(height: 12),
                                  Text(
                                    'Esperando nuevas solicitudes...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Los viajes solicitados por los clientes aparecerán aquí automáticamente en tiempo real.',
                                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: rides.length,
                          itemBuilder: (context, index) {
                            final ride = rides[index];
                            return RideCard(
                              ride: ride,
                              isDriverView: true,
                              onAccept: () {
                                if (user != null) {
                                  _handleAcceptRide(ride, user);
                                }
                              },
                              onReject: () {
                                // Ocultar o ignorar en la sesión del chofer
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Solicitud omitida'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
