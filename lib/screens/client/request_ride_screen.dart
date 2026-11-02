import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/fare_calculator.dart';
import '../../models/ride_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../widgets/custom_button.dart';
import 'client_tracking_screen.dart';

class RequestRideScreen extends StatefulWidget {
  final LatLng currentPosition;

  const RequestRideScreen({
    super.key,
    required this.currentPosition,
  });

  @override
  State<RequestRideScreen> createState() => _RequestRideScreenState();
}

class _RequestRideScreenState extends State<RequestRideScreen> {
  final _originController = TextEditingController(text: 'Mi ubicación actual');
  final _destinationController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  LatLng? _destinationCoordinates;
  double _distanceKm = 4.5;
  int _durationMin = 14;
  double _fare = 3500.0;
  bool _isRequesting = false;
  int _selectedVehicleType = 0; // 0: Estándar (GastUber X), 1: Confort

  // Destinos sugeridos para facilitar la prueba
  final List<Map<String, dynamic>> _suggestedDestinations = [
    {
      'title': 'Universidad / Facultad',
      'address': 'Av. Paseo Colón 850',
      'latOffset': 0.025,
      'lngOffset': -0.015,
    },
    {
      'title': 'Centro Comercial Shopping',
      'address': 'Av. Santa Fe 3253',
      'latOffset': -0.030,
      'lngOffset': 0.020,
    },
    {
      'title': 'Aeropuerto Internacional',
      'address': 'Autopista Tte. Gral. Ricchieri Km 33.5',
      'latOffset': 0.120,
      'lngOffset': -0.090,
    },
    {
      'title': 'Terminal de Ómnibus',
      'address': 'Av. Antártida Argentina',
      'latOffset': 0.018,
      'lngOffset': 0.012,
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectSuggestedDestination(_suggestedDestinations.first);
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _selectSuggestedDestination(Map<String, dynamic> dest) {
    _destinationController.text = dest['address'];
    final destLat = widget.currentPosition.latitude + (dest['latOffset'] as double);
    final destLng = widget.currentPosition.longitude + (dest['lngOffset'] as double);
    _destinationCoordinates = LatLng(destLat, destLng);

    _calculateTripValues();
  }

  void _calculateTripValues() {
    if (_destinationCoordinates == null) return;

    final dist = FareCalculator.calculateDistanceKm(
      startLat: widget.currentPosition.latitude,
      startLng: widget.currentPosition.longitude,
      endLat: _destinationCoordinates!.latitude,
      endLng: _destinationCoordinates!.longitude,
    );

    final dur = FareCalculator.calculateEstimatedMinutes(dist);
    var calculatedFare = FareCalculator.calculateEstimatedFare(
      distanceKm: dist,
      durationMin: dur,
    );

    // Si es confort suma 25%
    if (_selectedVehicleType == 1) {
      calculatedFare = (calculatedFare * 1.25 / 50).round() * 50.0;
    }

    setState(() {
      _distanceKm = dist;
      _durationMin = dur;
      _fare = calculatedFare;
    });
  }

  Future<void> _handleRequestRide() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    if (_destinationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un destino.')),
      );
      return;
    }

    setState(() => _isRequesting = true);

    try {
      final ride = RideModel(
        id: '',
        clientId: user.uid,
        clientName: user.name,
        clientRating: user.rating,
        origin: RideLocation(
          address: _originController.text.trim(),
          latitude: widget.currentPosition.latitude,
          longitude: widget.currentPosition.longitude,
        ),
        destination: RideLocation(
          address: _destinationController.text.trim(),
          latitude: _destinationCoordinates?.latitude ?? (widget.currentPosition.latitude + 0.03),
          longitude: _destinationCoordinates?.longitude ?? (widget.currentPosition.longitude + 0.02),
        ),
        fare: _fare,
        distanceKm: _distanceKm,
        durationMin: _durationMin,
        status: RideStatus.pending,
      );

      final rideId = await _firestoreService.requestRide(ride);

      if (mounted) {
        final createdRide = RideModel(
          id: rideId,
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

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ClientTrackingScreen(initialRide: createdRide),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al solicitar viaje: $e'),
            backgroundColor: AppColors.statusCancelled,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Solicitar Viaje'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tarjeta de Origen y Destino
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Origen
                          Row(
                            children: [
                              const Icon(Icons.circle, size: 14, color: AppColors.accent),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _originController,
                                  decoration: const InputDecoration(
                                    labelText: 'Punto de partida',
                                    isDense: true,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20, color: AppColors.divider),
                          // Destino
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: AppColors.statusCancelled),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _destinationController,
                                  autofocus: false,
                                  decoration: const InputDecoration(
                                    labelText: '¿A dónde vas?',
                                    isDense: true,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onSubmitted: (val) {
                                    _calculateTripValues();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Destinos rápidos sugeridos
                    const Text(
                      'Destinos sugeridos para probar',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _suggestedDestinations.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final item = _suggestedDestinations[index];
                          final isSelected = _destinationController.text == item['address'];
                          return ChoiceChip(
                            label: Text(item['title']),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            backgroundColor: AppColors.surface,
                            onSelected: (_) => _selectSuggestedDestination(item),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Opciones de Viaje (Tipo de Vehículo)
                    const Text(
                      'Elige tu categoría',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _CategoryOption(
                      title: 'GastUber X',
                      subtitle: 'Viajes rápidos y económicos',
                      eta: '3-5 min de llegada',
                      price: currencyFormat.format(_selectedVehicleType == 0 ? _fare : _fare / 1.25),
                      icon: Icons.directions_car_rounded,
                      isSelected: _selectedVehicleType == 0,
                      onTap: () {
                        setState(() {
                          _selectedVehicleType = 0;
                          _calculateTripValues();
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    _CategoryOption(
                      title: 'GastUber Confort',
                      subtitle: 'Autos más amplios y choferes top',
                      eta: '2-4 min de llegada',
                      price: currencyFormat.format(_selectedVehicleType == 1 ? _fare : _fare * 1.25),
                      icon: Icons.airport_shuttle_rounded,
                      isSelected: _selectedVehicleType == 1,
                      onTap: () {
                        setState(() {
                          _selectedVehicleType = 1;
                          _calculateTripValues();
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Resumen de tiempo y distancia estimada
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.straighten, size: 18, color: AppColors.accentDark),
                              const SizedBox(width: 6),
                              Text(
                                '$_distanceKm km distancia',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ],
                          ),
                          Container(width: 1, height: 20, color: AppColors.divider),
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 18, color: AppColors.accentDark),
                              const SizedBox(width: 6),
                              Text(
                                '$_durationMin min viaje',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Barra inferior con Precio Total y Botón de Solicitar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2)),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Estimado',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          currencyFormat.format(_fare),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: 'Solicitar GastUber',
                        isLoading: _isRequesting,
                        icon: Icons.check_circle_outline_rounded,
                        onPressed: _handleRequestRide,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final String eta;
  final String price;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryOption({
    required this.title,
    required this.subtitle,
    required this.eta,
    required this.price,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withOpacity(0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 36, color: isSelected ? AppColors.accentDark : AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    eta,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.accentDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
