import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/ride_model.dart';
import '../../services/firestore_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/rating_dialog.dart';

class ClientTrackingScreen extends StatefulWidget {
  final RideModel initialRide;

  const ClientTrackingScreen({
    super.key,
    required this.initialRide,
  });

  @override
  State<ClientTrackingScreen> createState() => _ClientTrackingScreenState();
}

class _ClientTrackingScreenState extends State<ClientTrackingScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final Completer<GoogleMapController> _mapController = Completer();

  late Stream<RideModel?> _rideStream;
  RideStatus? _previousStatus;
  bool _hasPromptedRating = false;

  @override
  void initState() {
    super.initState();
    _previousStatus = widget.initialRide.status;
    _rideStream = _firestoreService.streamRideById(widget.initialRide.id);
  }

  void _handleStatusChange(RideModel ride) {
    if (_previousStatus != ride.status) {
      _previousStatus = ride.status;

      // Notificación visual in-app cuando es aceptado
      if (ride.status == RideStatus.accepted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '¡${ride.driverName ?? "Tu chofer"} ha aceptado tu viaje!',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.accentDark,
              duration: const Duration(seconds: 4),
            ),
          );
        });
      }

      // Si el viaje se completó y aún no calificamos
      if (ride.status == RideStatus.completed && !_hasPromptedRating) {
        _hasPromptedRating = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showRatingDialog(ride);
        });
      }
    }
  }

  void _showRatingDialog(RideModel ride) {
    if (ride.driverId == null) {
      Navigator.of(context).pop();
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => RatingDialog(
        title: '¿Cómo estuvo tu viaje?',
        subtitle: 'Califica a tu conductor ${ride.driverName ?? ""}',
        onSubmit: (rating) async {
          await _firestoreService.rateRide(
            rideId: ride.id,
            targetUserId: ride.driverId!,
            isClientRatingDriver: true,
            rating: rating,
          );
          if (mounted) {
            Navigator.of(context).pop(); // Cierra pantalla de tracking y vuelve a Home
          }
        },
      ),
    );
  }

  Future<void> _handleCancel(RideModel ride) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cancelar viaje?'),
        content: const Text('¿Estás seguro de que deseas cancelar la solicitud de viaje?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No, continuar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusCancelled),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firestoreService.cancelRide(ride.id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 0);

    return WillPopScope(
      onWillPop: () async => false, // Evita volver atrás accidentalmente durante un viaje activo
      child: Scaffold(
        body: StreamBuilder<RideModel?>(
          stream: _rideStream,
          initialData: widget.initialRide,
          builder: (context, snapshot) {
            final ride = snapshot.data ?? widget.initialRide;
            _handleStatusChange(ride);

            final originPos = LatLng(ride.origin.latitude, ride.origin.longitude);
            final destPos = LatLng(ride.destination.latitude, ride.destination.longitude);

            final markers = {
              Marker(
                markerId: const MarkerId('origin'),
                position: originPos,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                infoWindow: InfoWindow(title: 'Origen', snippet: ride.origin.address),
              ),
              Marker(
                markerId: const MarkerId('destination'),
                position: destPos,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                infoWindow: InfoWindow(title: 'Destino', snippet: ride.destination.address),
              ),
            };

            return Stack(
              children: [
                // Mapa con origen y destino
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: originPos,
                    zoom: 13.5,
                  ),
                  markers: markers,
                  onMapCreated: (controller) {
                    if (!_mapController.isCompleted) {
                      _mapController.complete(controller);
                    }
                  },
                ),

                // Tarjeta de estado flotante arriba
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: ride.statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              ride.statusLabel,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            currencyFormat.format(ride.fare),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.accentDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Panel Inferior con detalles del viaje y chofer
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, -3)),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Si está pendiente: Animación de búsqueda
                          if (ride.status == RideStatus.pending) ...[
                            const Center(
                              child: SizedBox(
                                height: 40,
                                width: 40,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Conectando con choferes de la zona...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Te avisaremos en cuanto un conductor acepte tu solicitud',
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            CustomButton(
                              text: 'Cancelar Solicitud',
                              isOutlined: true,
                              backgroundColor: AppColors.statusCancelled,
                              textColor: AppColors.statusCancelled,
                              onPressed: () => _handleCancel(ride),
                            ),
                          ],

                          // Si ya fue aceptado o está en curso: Info del Chofer
                          if (ride.status == RideStatus.accepted || ride.status == RideStatus.inProgress) ...[
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: AppColors.primary,
                                  child: const Icon(Icons.person, color: Colors.white, size: 30),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ride.driverName ?? 'Conductor asignado',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        ride.driverVehicle ?? 'Auto Estándar',
                                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                      ),
                                      if (ride.driverRating != null) ...[
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(Icons.star_rounded, size: 16, color: AppColors.starRating),
                                            Text(
                                              ' ${ride.driverRating!.toStringAsFixed(1)}',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24, color: AppColors.divider),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Destino', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                    Text(
                                      ride.destination.address,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${ride.durationMin} min',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentDark),
                                  ),
                                ),
                              ],
                            ),
                            if (ride.status == RideStatus.accepted) ...[
                              const SizedBox(height: 16),
                              CustomButton(
                                text: 'Cancelar Viaje',
                                isOutlined: true,
                                backgroundColor: AppColors.statusCancelled,
                                textColor: AppColors.statusCancelled,
                                onPressed: () => _handleCancel(ride),
                              ),
                            ],
                          ],

                          // Si fue cancelado
                          if (ride.status == RideStatus.cancelled) ...[
                            const Icon(Icons.cancel_rounded, size: 48, color: AppColors.statusCancelled),
                            const SizedBox(height: 12),
                            const Text(
                              'El viaje fue cancelado',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            CustomButton(
                              text: 'Volver al Inicio',
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
