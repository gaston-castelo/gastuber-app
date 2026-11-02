import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/ride_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../widgets/ride_card.dart';

class RideHistoryScreen extends StatelessWidget {
  final bool isDriver;

  const RideHistoryScreen({
    super.key,
    required this.isDriver,
  });

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final firestoreService = FirestoreService();
    final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isDriver ? 'Historial de Conducción' : 'Mis Viajes Realizados'),
      ),
      body: user == null
          ? const Center(child: Text('Inicia sesión para ver tu historial'))
          : StreamBuilder<List<RideModel>>(
              stream: firestoreService.streamUserHistory(
                userId: user.uid,
                isDriver: isDriver,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final rides = snapshot.data ?? [];

                if (rides.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: AppColors.textMuted.withOpacity(0.6),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Aún no tienes viajes registrados',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isDriver
                                ? 'Los viajes que completes aparecerán aquí con su recaudación.'
                                : 'Cuando completes tu primer viaje en GastUber, verás el detalle aquí.',
                            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Cálculo de métricas acumuladas
                final totalFare = rides
                    .where((r) => r.status == RideStatus.completed)
                    .fold<double>(0.0, (acc, r) => acc + r.fare);
                final completedCount = rides.where((r) => r.status == RideStatus.completed).length;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Tarjeta Resumen
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                isDriver ? 'Total Ganado' : 'Total Gastado',
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currencyFormat.format(totalFare),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Container(width: 1, height: 36, color: AppColors.primaryLight),
                          Column(
                            children: [
                              const Text(
                                'Completados',
                                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$completedCount viajes',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Detalle de Viajes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Lista de viajes
                    ...rides.map((ride) => RideCard(ride: ride, isDriverView: isDriver)),
                  ],
                );
              },
            ),
    );
  }
}
