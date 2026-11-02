import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/ride_model.dart';
import 'custom_button.dart';

class RideCard extends StatelessWidget {
  final RideModel ride;
  final bool isDriverView;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onTap;

  const RideCard({
    super.key,
    required this.ride,
    this.isDriverView = false,
    this.onAccept,
    this.onReject,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM/yyyy • HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado: Estado / Fecha y Tarifa
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: ride.statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ride.statusLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: ride.statusColor,
                      ),
                    ),
                  ),
                  Text(
                    currencyFormat.format(ride.fare),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Detalles de Ruta (Origen -> Destino)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      const Icon(Icons.circle, size: 10, color: AppColors.accent),
                      Container(
                        width: 2,
                        height: 24,
                        color: AppColors.divider,
                      ),
                      const Icon(Icons.location_on, size: 14, color: AppColors.statusCancelled),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride.origin.address,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          ride.destination.address,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
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
              const Divider(height: 24, color: AppColors.divider),

              // Info adicional (Pasajero/Chofer, distancia y tiempo)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        isDriverView ? ride.clientName : (ride.driverName ?? 'Buscando chofer...'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.straighten, size: 15, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${ride.distanceKm} km',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.access_time, size: 15, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${ride.durationMin} min',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),

              // Botones de acción si es chofer y el viaje está pendiente
              if (isDriverView && ride.status == RideStatus.pending && onAccept != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (onReject != null) ...[
                      Expanded(
                        child: CustomButton(
                          text: 'Rechazar',
                          isOutlined: true,
                          backgroundColor: AppColors.statusCancelled,
                          textColor: AppColors.statusCancelled,
                          onPressed: onReject,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: CustomButton(
                        text: 'Aceptar Viaje',
                        backgroundColor: AppColors.accent,
                        onPressed: onAccept,
                      ),
                    ),
                  ],
                ),
              ],

              // Fecha al pie en historial
              if (ride.status == RideStatus.completed || ride.status == RideStatus.cancelled) ...[
                const SizedBox(height: 8),
                Text(
                  dateFormat.format(ride.createdAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
