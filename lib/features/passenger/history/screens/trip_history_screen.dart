import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/routes.dart';
import '../../../../core/config/themes.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/dialogs/dialogs.dart';
import '../../../../core/widgets/loaders/loaders.dart';
import '../../ride/application/ride_controller.dart';
import '../../ride/domain/ride_models.dart';

class TripHistoryScreen extends ConsumerWidget {
  const TripHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(rideControllerProvider).tripHistory;

    return Scaffold(
      appBar: AppBar(title: const Text('Trip History')),
      body: trips.isEmpty
          ? const EmptyState(
              icon: Icons.history_rounded,
              title: 'No rides yet',
              subtitle: 'Completed rides will appear here.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: trips.length,
              itemBuilder: (context, index) {
                final trip = trips[index];
                return _TripListTile(trip: trip);
              },
            ),
    );
  }
}

class _TripListTile extends ConsumerWidget {
  const _TripListTile({required this.trip});
  final RideTrip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusChip(status: trip.status),
              const Spacer(),
              Text(
                Formatters.dateTime(trip.createdAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Route visualization
          Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.pickupMarker,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 24,
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  const Icon(Icons.location_on,
                      color: AppColors.dropMarker, size: 14),
                ],
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.pickup.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      trip.destination.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Ride type icon + stats
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _rideIcon(trip.rideType),
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trip.rideType.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${Formatters.distance(trip.distanceKm)} • ${Formatters.duration(trip.durationMinutes)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Fare + reward + rebook
          Row(
            children: [
              Text(
                Formatters.currency(trip.fare),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '+${trip.rewardPointsEarned} pts',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              // Rebook button
              TextButton.icon(
                onPressed: () => _rebookTrip(context, ref, trip),
                icon: const Icon(Icons.replay_rounded, size: 16),
                label: const Text('Rebook'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),

          if (trip.compensations.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_outlined,
                      color: AppColors.success, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Compensation: ${Formatters.currency(trip.compensations.first.amount)}',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Driver info if available
          if (trip.driver != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurface
                    : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    child: Text(
                      trip.driver!.name[0],
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${trip.driver!.name} • ${trip.driver!.vehicleModel}',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppColors.accent, size: 14),
                      Text(
                        trip.driver!.rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _rebookTrip(BuildContext context, WidgetRef ref, RideTrip trip) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Rebook This Ride?',
      message:
          'Book a new ride from ${trip.pickup.address} to ${trip.destination.address}?',
      confirmLabel: 'Rebook',
      icon: Icons.replay_rounded,
    );

    if (confirmed != true || !context.mounted) return;

    final controller = ref.read(rideControllerProvider.notifier);
    controller.setPickup(trip.pickup);
    controller.setDestination(trip.destination);
    await controller.loadQuotes();
    if (context.mounted) {
      context.push(Routes.booking);
    }
  }

  IconData _rideIcon(RideType type) {
    switch (type) {
      case RideType.bike:
        return Icons.two_wheeler_rounded;
      case RideType.premium:
        return Icons.directions_car_rounded;
      case RideType.suv:
        return Icons.airport_shuttle_rounded;
      case RideType.economy:
        return Icons.local_taxi_rounded;
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final RideLifecycleStatus status;

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (status) {
      case RideLifecycleStatus.completed:
        color = AppColors.success;
        icon = Icons.check_circle_outline;
        break;
      case RideLifecycleStatus.cancelled:
        color = AppColors.error;
        icon = Icons.cancel_outlined;
        break;
      default:
        color = AppColors.warning;
        icon = Icons.schedule_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            status.name.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
