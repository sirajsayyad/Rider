import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/themes.dart';
import '../../../../core/widgets/buttons/buttons.dart';
import '../providers/rating_provider.dart';

/// Post-ride 5-star rating screen with optional text review and category badges
class RatingScreen extends ConsumerStatefulWidget {
  const RatingScreen({
    super.key,
    required this.rideId,
    required this.driverId,
    required this.driverName,
  });

  final String rideId;
  final String driverId;
  final String driverName;

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  final _reviewController = TextEditingController();

  static const _badges = [
    {'label': 'Polite', 'icon': Icons.sentiment_satisfied_alt},
    {'label': 'Clean Car', 'icon': Icons.local_car_wash},
    {'label': 'Safe Driving', 'icon': Icons.shield_outlined},
    {'label': 'Punctual', 'icon': Icons.schedule},
    {'label': 'Good Music', 'icon': Icons.music_note},
    {'label': 'AC Worked Well', 'icon': Icons.ac_unit},
  ];

  @override
  void initState() {
    super.initState();
    ref.read(ratingControllerProvider.notifier).resetRating();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ratingState = ref.watch(ratingControllerProvider);
    final controller = ref.read(ratingControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (ratingState.isSubmitted) {
      return _SubmittedView(driverName: widget.driverName);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Rate Your Ride')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.lg),

            // Driver avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: AppShadows.glow,
              ),
              child: Center(
                child: Text(
                  widget.driverName[0],
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Text(
              'How was your ride with ${widget.driverName}?',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Star rating
            RatingBar.builder(
              initialRating: ratingState.selectedStars,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemSize: 48,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4),
              itemBuilder: (context, _) => const Icon(
                Icons.star_rounded,
                color: AppColors.accent,
              ),
              unratedColor: isDark
                  ? AppColors.darkBorder
                  : AppColors.lightBorder,
              onRatingUpdate: controller.setStars,
            ),
            const SizedBox(height: 8),

            Text(
              _ratingLabel(ratingState.selectedStars),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _ratingColor(ratingState.selectedStars),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Category badges
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _badges.map((badge) {
                final label = badge['label'] as String;
                final icon = badge['icon'] as IconData;
                final isSelected = ratingState.selectedBadges.contains(label);
                return FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 16,
                        color: isSelected ? Colors.white : AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(label),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (_) => controller.toggleBadge(label),
                  selectedColor: AppColors.primary,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : null,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Text review
            TextField(
              controller: _reviewController,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'Share your experience (optional)',
                prefixIcon: const Icon(Icons.edit_note, color: AppColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              onChanged: controller.setReview,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Submit button
            PrimaryButton(
              text: ratingState.isSubmitting ? 'Submitting...' : 'Submit Rating',
              icon: Icons.send_rounded,
              onPressed: ratingState.selectedStars == 0 || ratingState.isSubmitting
                  ? null
                  : () async {
                      await controller.submitRating(
                        rideId: widget.rideId,
                        driverId: widget.driverId,
                        driverName: widget.driverName,
                      );
                    },
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Skip for now'),
            ),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(double stars) {
    if (stars >= 5) return 'Excellent! ⭐';
    if (stars >= 4) return 'Great!';
    if (stars >= 3) return 'Good';
    if (stars >= 2) return 'Fair';
    if (stars >= 1) return 'Poor';
    return 'Tap to rate';
  }

  Color _ratingColor(double stars) {
    if (stars >= 4) return AppColors.success;
    if (stars >= 3) return AppColors.accent;
    if (stars >= 1) return AppColors.error;
    return AppColors.lightTextTertiary;
  }
}

class _SubmittedView extends StatelessWidget {
  const _SubmittedView({required this.driverName});
  final String driverName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 48,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Thank you!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your feedback helps $driverName and improves ride quality for everyone.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                text: 'Done',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
