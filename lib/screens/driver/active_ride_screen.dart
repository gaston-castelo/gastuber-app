import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/ride_model.dart';
import '../../services/firestore_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/rating_dialog.dart';

class ActiveRideScreen extends StatefulWidget {
  final RideModel initialRide;

  const ActiveRideScreen({
    super.key,
    required this.initialRide,
  });

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final Completer<GoogleMapController> _mapController = Completer();

  late Stream<RideModel?> _rideStream;
  bool _isUpdating = false;
  bool _hasPromptedRating = false;

  @override
  void initState() {
    super.initState();
    _rideStream = _firestoreService.streamRideById(widget.initialRide.id);
  }

  Future<void> _advanceRideStatus(RideModel ride) async {
    setState(() => _isUpdating = true);

    try {
      if (ride.status == RideStatus.accepted) {
        // Pasa a "En curso"
        await _firestoreService.updateRideStatus(ride.id, RideStatus.inProgress);
      } else if (ride.status == RideStatus.inProgress) {
        // Pasa a "Finalizado"
        await _firestoreService.updateRideStatus(ride.id, RideStatus.completed);
        if (!_hasPromptedRating) {
          _hasPromptedRating = true;
          if (mounted) _showRatingDialog(ride);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar estado: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _showRatingDialog(RideModel ride) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => RatingDialog(
        title: 'Viaje Finalizado',
        subtitle: '¿Cómo fue la experiencia con el pasajero ${ride.clientName}?',
        onSubmit: (rating) async {
          await _firestoreService.rateRide(
            rideId: ride.id,
            targetUserId: ride.clientId,
            isClientRatingDriver: false,
            rating: rating,
          );
          if (mounted) {
            Navigator.of(context).pop(); // Cierra dialog
            Navigator.of(context).pop(); // Vuelve a DriverHomeScreen
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 0);

    return WillPopScope(
      onWillPop: () async => false, // Evitar salir accidentalmente del viaje en curso
      child: Scaffold(
        body: StreamBuilder<RideModel?>(
          stream: _rideStream,
          initialData: widget.initialRide,
          builder: (context, snapshot) {
            final ride = snapshot.data ?? widget.initialRide;

            final originPos = LatLng(ride.origin.latitude, ride.origin.longitude);
            final destPos = LatLng(ride.destination.latitude, ride.destination.longitude);

            final markers = {
              Marker(
                markerId: const MarkerId('origin'),
                position: originPos,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                infoWindow: InfoWindow(title: 'Punto de Encuentro', snippet: ride.origin.address),
              ),
              Marker(
                markerId: const MarkerId('destination'),
                position: destPos,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                infoWindow: InfoWindow(title: 'Destino', snippet: ride.destination.address),
              ),
            };

            // Determinar texto y acción del botón principal
            String buttonText = 'Iniciar Viaje';
            IconData buttonIcon = Icons.navigation_rounded;
            Color buttonColor = AppColors.accent;

            if (ride.status == RideStatus.inProgress) {
              buttonText = 'Finalizar Viaje';
              buttonIcon = Icons.flag_rounded;
              buttonColor = AppColors.statusCompleted;
            }

            return Stack(
              children: [
                // Mapa interactivo
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: originPos,
                    zoom: 14,
                  ),
                  markers: markers,
                  onMapCreated: (controller) {
                    if (!_mapController.isCompleted) {
                      _mapController.complete(controller);
                    }
                  },
                ),

                // Barra superior de estado
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 3)),
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
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Panel Inferior con controles del chofer
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
                        children: [
                          // Info Pasajero
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.primary,
                                child: Text(
                                  ride.clientName.isNotEmpty ? ride.clientName[0].toUpperCase() : 'P',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ride.clientName,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded, size: 16, color: AppColors.starRating),
                                        Text(
                                          ' ${ride.clientRating.toStringAsFixed(1)}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.inputFill,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${ride.distanceKm} km',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24, color: AppColors.divider),

                          // Dirección a la que debe ir el conductor según el estado
                          Row(
                            children: [
                              Icon(
                                ride.status == RideStatus.accepted ? Icons.my_location : Icons.location_on,
                                color: ride.status == RideStatus.accepted ? AppColors.accentDark : AppColors.statusCancelled,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ride.status == RideStatus.accepted
                                          ? 'Punto de recogida del pasajero'
                                          : 'Destino final del viaje',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                    Text(
                                      ride.status == RideStatus.accepted
                                          ? ride.origin.address
                                          : ride.destination.address,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Botón de avance de estado
                          SizedBox(
                            width: double.infinity,
                            child: CustomButton(
                              text: buttonText,
                              icon: buttonIcon,
                              backgroundColor: buttonColor,
                              isLoading: _isUpdating,
                              onPressed: () => _advanceRideStatus(ride),
                            ),
                          ),
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
