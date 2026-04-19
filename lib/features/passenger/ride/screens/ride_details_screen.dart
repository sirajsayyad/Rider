import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/themes.dart';
import '../../../../core/utils/formatters.dart';
import '../../ride/application/ride_controller.dart';

class RideDetailsScreen extends ConsumerWidget {
  const RideDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(rideControllerProvider).activeTrip;

    return Scaffold(
      appBar: AppBar(title: const Text('Ride Details')),
      body: trip == null
          ? const Center(child: Text('No active trip.'))
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _DetailCard(
                  title: 'Trip',
                  rows: [
                    _row('Ride ID', trip.id.substring(0, 8)),
                    _row('From', trip.pickup.address),
                    _row('To', trip.destination.address),
                    _row('Distance', Formatters.distance(trip.distanceKm)),
                    _row('Duration', Formatters.duration(trip.durationMinutes)),
                    _row('Reassignments', '${trip.reassignmentCount}'),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _DetailCard(
                  title: 'Driver',
                  rows: [
                    _row('Name', trip.driver?.name ?? 'TBD'),
                    _row('Vehicle',
                        '${trip.driver?.vehicleModel ?? ''} ${trip.driver?.vehicleNumber ?? ''}'),
                    _row('Rating', (trip.driver?.rating ?? 0).toStringAsFixed(1)),
                    _row(
                      'Acceptance rate',
                      '${(((trip.driver?.acceptanceRate ?? 0) * 100)).round()}%',
                    ),
                    _row('Masked phone', trip.driver?.maskedPhone ?? '--'),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _DetailCard(
                  title: 'Ride experience',
                  rows: [
                    _row('AC ride', trip.preferences.acRide ? 'Yes' : 'No'),
                    _row('Silent ride', trip.preferences.silentRide ? 'Yes' : 'No'),
                    _row('Music', trip.preferences.musicOn ? 'Yes' : 'No'),
                    _row('Live tracking', 'Enabled'),
                    _row('Trip shared with', trip.sharedContacts.join(', ')),
                    _row('Route deviation', trip.routeDeviationDetected ? 'Detected' : 'No'),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _DetailCard(
                  title: 'Billing',
                  rows: [
                    _row('Estimated Fare', Formatters.currency(trip.fare)),
                    _row('Payment', trip.paymentMethod.name.toUpperCase()),
                    if (trip.fareLock != null)
                      _row(
                        'Fare lock',
                        'Locked at ${Formatters.currency(trip.fareLock!.lockedFare)}',
                      ),
                    _row('Reward points', '${trip.rewardPointsEarned}'),
                  ],
                ),
              ],
            ),
    );
  }

  MapEntry<String, String> _row(String k, String v) => MapEntry(k, v);
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.title, required this.rows});

  final String title;
  final List<MapEntry<String, String>> rows;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(child: Text(row.key)),
                  Expanded(
                    child: Text(
                      row.value,
                      textAlign: TextAlign.end,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
