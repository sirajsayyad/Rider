import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/themes.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/buttons/buttons.dart';
import '../../../../core/widgets/loaders/loaders.dart';

/// Incoming ride request model
class RideRequest {
  final String id;
  final String passengerName;
  final double passengerRating;
  final String pickupAddress;
  final String dropAddress;
  final double distanceKm;
  final int durationMinutes;
  final double fare;
  final String rideType;
  final double pickupDistanceKm;
  final int pickupEtaMinutes;
  final DateTime requestedAt;

  const RideRequest({
    required this.id,
    required this.passengerName,
    required this.passengerRating,
    required this.pickupAddress,
    required this.dropAddress,
    required this.distanceKm,
    required this.durationMinutes,
    required this.fare,
    required this.rideType,
    required this.pickupDistanceKm,
    required this.pickupEtaMinutes,
    required this.requestedAt,
  });
}

/// Demo state for ride requests
class _RideRequestsState {
  final List<RideRequest> pending;
  final List<RideRequest> completed;
  final bool isOnline;

  const _RideRequestsState({
    this.pending = const [],
    this.completed = const [],
    this.isOnline = true,
  });
}

final _rideRequestsProvider = StateProvider<_RideRequestsState>((ref) {
  return _RideRequestsState(
    pending: [
      RideRequest(
        id: 'req_001',
        passengerName: 'Arjun K.',
        passengerRating: 4.8,
        pickupAddress: 'Connaught Place, New Delhi',
        dropAddress: 'Hauz Khas Village, South Delhi',
        distanceKm: 12.4,
        durationMinutes: 28,
        fare: 185,
        rideType: 'Economy',
        pickupDistanceKm: 1.2,
        pickupEtaMinutes: 4,
        requestedAt: DateTime.now().subtract(const Duration(seconds: 15)),
      ),
      RideRequest(
        id: 'req_002',
        passengerName: 'Priya S.',
        passengerRating: 4.6,
        pickupAddress: 'Saket Metro Station',
        dropAddress: 'DLF CyberCity, Gurgaon',
        distanceKm: 22.1,
        durationMinutes: 45,
        fare: 340,
        rideType: 'Premium',
        pickupDistanceKm: 2.8,
        pickupEtaMinutes: 8,
        requestedAt: DateTime.now().subtract(const Duration(seconds: 5)),
      ),
    ],
    completed: [
      RideRequest(
        id: 'req_003',
        passengerName: 'Rahul M.',
        passengerRating: 4.9,
        pickupAddress: 'Nehru Place',
        dropAddress: 'IGI Airport T3',
        distanceKm: 18.5,
        durationMinutes: 35,
        fare: 420,
        rideType: 'SUV',
        pickupDistanceKm: 0.5,
        pickupEtaMinutes: 2,
        requestedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ],
  );
});

class RideRequestsScreen extends ConsumerWidget {
  const RideRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_rideRequestsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ride Requests'),
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Pending'),
                    if (state.pending.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          '${state.pending.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Tab(text: 'Completed'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Pending requests
            state.pending.isEmpty
                ? const EmptyState(
                    icon: Icons.inbox_rounded,
                    title: 'No pending requests',
                    subtitle: 'New ride requests will appear here.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: state.pending.length,
                    itemBuilder: (context, index) {
                      return _IncomingRequestCard(
                        request: state.pending[index],
                        isDark: isDark,
                        onAccept: () {
                          final updated = List<RideRequest>.from(state.pending);
                          final accepted = updated.removeAt(index);
                          ref.read(_rideRequestsProvider.notifier).state =
                              _RideRequestsState(
                            pending: updated,
                            completed: [accepted, ...state.completed],
                            isOnline: state.isOnline,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Ride accepted! Navigating to ${accepted.passengerName}'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        },
                        onDecline: () {
                          final updated = List<RideRequest>.from(state.pending);
                          updated.removeAt(index);
                          ref.read(_rideRequestsProvider.notifier).state =
                              _RideRequestsState(
                            pending: updated,
                            completed: state.completed,
                            isOnline: state.isOnline,
                          );
                        },
                      );
                    },
                  ),

            // Completed requests
            state.completed.isEmpty
                ? const EmptyState(
                    icon: Icons.check_circle_outline_rounded,
                    title: 'No completed rides',
                    subtitle: 'Accepted rides will appear here.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: state.completed.length,
                    itemBuilder: (context, index) {
                      return _CompletedRequestTile(
                        request: state.completed[index],
                        isDark: isDark,
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

class _IncomingRequestCard extends StatelessWidget {
  final RideRequest request;
  final bool isDark;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _IncomingRequestCard({
    required this.request,
    required this.isDark,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.medium,
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // Header: passenger + fare
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.xl),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    request.passengerName[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.passengerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Colors.amber, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            '${request.passengerRating}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                            ),
                            child: Text(
                              request.rideType,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.currency(request.fare),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      Formatters.relativeTime(request.requestedAt),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Route info
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
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
                          height: 20,
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
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
                            request.pickupAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            request.dropAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Trip metrics
                Row(
                  children: [
                    _Metric(
                      icon: Icons.navigation_outlined,
                      label: 'Pickup',
                      value:
                          '${Formatters.distance(request.pickupDistanceKm)} • ${request.pickupEtaMinutes} min',
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _Metric(
                      icon: Icons.route_outlined,
                      label: 'Trip',
                      value:
                          '${Formatters.distance(request.distanceKm)} • ${Formatters.duration(request.durationMinutes)}',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        text: 'Decline',
                        icon: Icons.close_rounded,
                        height: 48,
                        onPressed: onDecline,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: PrimaryButton(
                        text: 'Accept',
                        icon: Icons.check_rounded,
                        height: 48,
                        onPressed: onAccept,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletedRequestTile extends StatelessWidget {
  final RideRequest request;
  final bool isDark;

  const _CompletedRequestTile({
    required this.request,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.success.withOpacity(0.12),
            child: const Icon(Icons.check, color: AppColors.success, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${request.passengerName} • ${request.rideType}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${request.pickupAddress} → ${request.dropAddress}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            Formatters.currency(request.fare),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
