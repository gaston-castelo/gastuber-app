import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'custom_button.dart';

class RatingDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final Future<void> Function(double rating) onSubmit;

  const RatingDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onSubmit,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  double _selectedRating = 5.0;
  bool _isSubmitting = false;

  String _getRatingText(double rating) {
    if (rating >= 5) return '¡Excelente servicio!';
    if (rating >= 4) return 'Muy buen viaje';
    if (rating >= 3) return 'Buen viaje';
    if (rating >= 2) return 'Regular';
    return 'Mala experiencia';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.starRating.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star_rounded, size: 36, color: AppColors.starRating),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              widget.subtitle,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Selector de 5 estrellas
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1.0;
                return IconButton(
                  iconSize: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  icon: Icon(
                    starValue <= _selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: AppColors.starRating,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedRating = starValue;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              _getRatingText(_selectedRating),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.accentDark,
              ),
            ),
            const SizedBox(height: 24),

            // Botón enviar
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Enviar Calificación',
                isLoading: _isSubmitting,
                onPressed: () async {
                  setState(() => _isSubmitting = true);
                  try {
                    await widget.onSubmit(_selectedRating);
                    if (mounted) Navigator.of(context).pop();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isSubmitting = false);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
