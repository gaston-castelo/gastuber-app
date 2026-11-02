import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../models/ride_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../widgets/driver_card.dart';
import 'request_ride_screen.dart';
import 'client_tracking_screen.dart';
import '../history/ride_history_screen.dart';
import '../auth/login_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  final FirestoreService _firestoreService = FirestoreService();

  LatLng _currentPosition = const LatLng(
    LocationService.defaultLatitude,
    LocationService.defaultLongitude,
  );
  bool _isLoadingLocation = true;
  Set<Marker> _markers = {};

  StreamSubscription<RideModel?>? _activeRideSub;

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
    _listenToActiveRide();
  }

  @override
  void dispose() {
    _activeRideSub?.cancel();
    super.dispose();
  }

  void _listenToActiveRide() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        _activeRideSub = _firestoreService.streamActiveRideForClient(user.uid).listen((ride) {
          if (ride != null && mounted) {
            // Si hay un viaje activo, redirigir a la pantalla de seguimiento
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ClientTrackingScreen(initialRide: ride),
              ),
            );
          }
        });
      }
    });
  }

  Future<void> _fetchUserLocation() async {
    final pos = await LocationService.getCurrentPosition();
    if (pos != null && mounted) {
      setState(() {
        _currentPosition = LatLng(pos.latitude, pos.longitude);
        _isLoadingLocation = false;
        _updateUserMarker();
      });

      final controller = await _mapController.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentPosition, zoom: 15),
        ),
      );
    } else {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _updateUserMarker();
        });
      }
    }
  }

  void _updateUserMarker() {
    _markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: _currentPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Tu ubicación actual'),
      ),
    );
  }

  void _updateDriverMarkers(List<UserModel> drivers) {
    final markers = Set<Marker>.from(_markers);
    // Eliminar marcadores previos de choferes
    markers.removeWhere((m) => m.markerId.value.startsWith('driver_'));

    for (int i = 0; i < drivers.length; i++) {
      final d = drivers[i];
      // Si el chofer tiene coordenadas, usarlas; de lo contrario generar una posición cercana
      final lat = d.currentLat ?? (_currentPosition.latitude + (0.003 * (i % 2 == 0 ? 1 : -1) * (i + 1)));
      final lng = d.currentLng ?? (_currentPosition.longitude + (0.003 * (i % 3 == 0 ? 1 : -1) * (i + 1)));

      markers.add(
        Marker(
          markerId: MarkerId('driver_${d.uid}'),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: d.name,
            snippet: d.vehicle?.model ?? 'Auto GastUber',
          ),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Google Maps en pantalla completa
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 14.5,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: _markers,
            onMapCreated: (controller) {
              if (!_mapController.isCompleted) {
                _mapController.complete(controller);
              }
            },
          ),

          // 2. Barra Superior Flotante (Perfil, Historial y Logout)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Hola, ${user?.name.split(' ').first ?? 'Pasajero'}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 14, color: AppColors.starRating),
                                Text(
                                  ' ${user?.rating.toStringAsFixed(1) ?? '5.0'}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Botón Historial
                  _FloatingActionButton(
                    icon: Icons.history_rounded,
                    tooltip: 'Historial de viajes',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RideHistoryScreen(isDriver: false),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  // Botón Salir
                  _FloatingActionButton(
                    icon: Icons.logout_rounded,
                    tooltip: 'Cerrar sesión',
                    onTap: () async {
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
            ),
          ),

          // 3. Botón flotante para recentrar mapa
          Positioned(
            right: 16,
            bottom: 300,
            child: _FloatingActionButton(
              icon: Icons.my_location_rounded,
              tooltip: 'Mi ubicación',
              onTap: _fetchUserLocation,
            ),
          ),

          // 4. Panel Inferior (BottomSheet moderno)
          DraggableScrollableSheet(
            initialChildSize: 0.36,
            minChildSize: 0.22,
            maxChildSize: 0.65,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 15,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  children: [
                    // Manija de arrastre
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Barra "¿A dónde vas?"
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RequestRideScreen(
                              currentPosition: _currentPosition,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.inputFill,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded, color: AppColors.accentDark, size: 24),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                '¿A dónde quieres ir hoy?',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Viajar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Título de lista de conductores
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Conductores cercanos',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        StreamBuilder<List<UserModel>>(
                          stream: _firestoreService.streamAvailableDrivers(),
                          builder: (context, snapshot) {
                            final count = snapshot.data?.length ?? 0;
                            return Text(
                              '$count disponibles',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.accentDark,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Stream de conductores disponibles desde Firestore
                    StreamBuilder<List<UserModel>>(
                      stream: _firestoreService.streamAvailableDrivers(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final drivers = snapshot.data ?? [];

                        // Actualizar marcadores en el mapa
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _updateDriverMarkers(drivers);
                        });

                        if (drivers.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.inputFill,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.car_crash_outlined, size: 36, color: AppColors.textMuted),
                                SizedBox(height: 8),
                                Text(
                                  'No hay choferes activos en este momento',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Podés iniciar sesión con un usuario chofer en otro emulador/pestaña para probarlo en tiempo real.',
                                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: drivers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final driver = drivers[index];
                            final eta = '${(index + 1) * 3} min';
                            final dist = '${((index + 1) * 0.9).toStringAsFixed(1)} km';

                            return DriverCard(
                              driver: driver,
                              estimatedMinutes: eta,
                              distance: dist,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => RequestRideScreen(
                                      currentPosition: _currentPosition,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FloatingActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _FloatingActionButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        elevation: 3,
        shadowColor: Colors.black26,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
        ),
      ),
    );
  }
}
