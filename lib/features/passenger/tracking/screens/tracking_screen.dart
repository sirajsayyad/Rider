import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/routes.dart';
import '../../../../core/config/themes.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/buttons/buttons.dart';
import '../../../../core/widgets/dialogs/dialogs.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../ride/application/ride_controller.dart';
import '../../ride/domain/ride_models.dart';
import '../widgets/live_tracking_map.dart';
import '../../pooling/widgets/pool_widgets.dart';

class TrackingScreen extends ConsumerWidget {
  const TrackingScreen({super.key, required this.rideId});

  final String rideId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rideControllerProvider);
    final controller = ref.read(rideControllerProvider.notifier);
    final trip = state.activeTrip;
    if (trip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ride Tracking')),
        body: const Center(child: Text('No active ride found.')),
      );
    }

    final statusColor = _statusColor(trip.status);
    final isDone = trip.status == RideLifecycleStatus.completed;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          LiveTrackingMap(trip: trip),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  CircularIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => context.go(Routes.passengerHome),
                  ),
                  const Spacer(),
                  // Chat button
                  if (!isDone) ...[
                    CircularIconButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      onPressed: () {
                        ref.read(appControllerProvider.notifier).openChat(
                              trip.driver?.id ?? 'driver',
                            );
                        context.push(Routes.chat);
                      },
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  CircularIconButton(
                    icon: Icons.shield_outlined,
                    backgroundColor: state.safetyState.routeDeviationDetected
                        ? AppColors.error
                        : null,
                    iconColor: state.safetyState.routeDeviationDetected
                        ? Colors.white
                        : null,
                    onPressed: () => context.push(Routes.sos),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
                boxShadow: AppShadows.large,
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Status + ETA row
                    Row(
                      children: [
                        _AnimatedStatusBadge(
                          status: trip.status,
                          color: statusColor,
                        ),
                        const Spacer(),
                        if (!isDone)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.schedule_rounded,
                                    size: 14, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'ETA: ${state.trackingEtaMinutes} min',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (state.safetyState.routeAlert != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      _AlertBanner(
                        color: AppColors.error,
                        title: 'Route deviation detected',
                        body: state.safetyState.routeAlert!,
                        actionLabel: 'Dismiss',
                        onAction: controller.clearRouteAlert,
                      ),
                    ],
                    if (trip.compensations.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      _AlertBanner(
                        color: AppColors.success,
                        title: 'No-cancellation guarantee',
                        body:
                            'Replacement driver assigned and ${Formatters.currency(trip.compensations.first.amount)} added as wallet credit.',
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    
                    if (trip.rideType == RideType.pool) ...[
                      const PoolSummaryCard(),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Enhanced driver card
                    _DriverCard(trip: trip, isDark: isDark),

                    const SizedBox(height: AppSpacing.md),
                    _AddressRow(
                      icon: Icons.my_location,
                      color: AppColors.pickupMarker,
                      text: trip.pickup.address,
                    ),
                    const SizedBox(height: 6),
                    _AddressRow(
                      icon: Icons.location_on_outlined,
                      color: AppColors.dropMarker,
                      text: trip.destination.address,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Action buttons row 1: Call + Chat + Share
                    if (!isDone)
                      Row(
                        children: [
                          _ActionIconButton(
                            icon: Icons.call_outlined,
                            label: 'Call',
                            color: AppColors.success,
                            onTap: () {
                              context.push(Routes.voiceCall);
                            },
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _ActionIconButton(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: 'Chat',
                            color: AppColors.info,
                            onTap: () {
                              ref
                                  .read(appControllerProvider.notifier)
                                  .openChat(trip.driver?.id ?? 'driver');
                              context.push(Routes.chat);
                            },
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _ActionIconButton(
                            icon: Icons.share_outlined,
                            label: 'Share',
                            color: AppColors.primary,
                            onTap: controller.shareTripWithContacts,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _ActionIconButton(
                            icon: Icons.shield_outlined,
                            label: 'SOS',
                            color: AppColors.error,
                            onTap: () => context.push(Routes.sos),
                          ),
                        ],
                      ),

                    const SizedBox(height: AppSpacing.md),

                    // Quick messages
                    if (!isDone) ...[
                      Text('Quick messages',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: state.quickMessages.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            return ActionChip(
                              label: Text(
                                state.quickMessages[index],
                                style: const TextStyle(fontSize: 12),
                              ),
                              onPressed: () => controller
                                  .sendQuickMessage(state.quickMessages[index]),
                              visualDensity: VisualDensity.compact,
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.md),
                    if (!isDone)
                      Row(
                        children: [
                          Expanded(
                            child: SecondaryButton(
                              text: 'Cancel Ride',
                              icon: Icons.close_rounded,
                              onPressed: () async {
                                final confirm = await showConfirmDialog(
                                  context,
                                  title: 'Cancel Ride?',
                                  message:
                                      'Are you sure you want to cancel this ride? Cancellation fees may apply.',
                                  confirmLabel: 'Yes, Cancel',
                                  confirmColor: AppColors.error,
                                  icon: Icons.cancel_outlined,
                                );
                                if (confirm == true && context.mounted) {
                                  controller.cancelActiveRide();
                                  context.go(Routes.passengerHome);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: PrimaryButton(
                              text: 'Ride Details',
                              icon: Icons.receipt_long_outlined,
                              onPressed: () => context.push(Routes.rideDetails),
                            ),
                          ),
                        ],
                      )
                    else ...[
                      // Rating prompt for completed ride
                      _RatingPromptCard(
                        driverName: trip.driver?.name ?? 'Driver',
                        onRate: () {
                          context.push(Routes.rateDriver.replaceFirst(':rideId', trip.id));
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: SecondaryButton(
                              text: 'Done',
                              onPressed: () {
                                ref
                                    .read(appControllerProvider.notifier)
                                    .clearChat();
                                controller.clearActiveRide();
                                context.go(Routes.passengerHome);
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: PrimaryButton(
                              text: 'View Receipt',
                              icon: Icons.receipt_rounded,
                              onPressed: () => context.push(Routes.receipt),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    SecondaryButton(
                      text: 'Billing & Payments',
                      icon: Icons.request_quote_outlined,
                      onPressed: () => context.push(Routes.billing),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(RideLifecycleStatus status) {
    switch (status) {
      case RideLifecycleStatus.searching:
        return AppColors.warning;
      case RideLifecycleStatus.driverAssigned:
      case RideLifecycleStatus.arriving:
        return AppColors.info;
      case RideLifecycleStatus.inProgress:
        return AppColors.primary;
      case RideLifecycleStatus.completed:
        return AppColors.success;
      case RideLifecycleStatus.cancelled:
        return AppColors.error;
      case RideLifecycleStatus.idle:
        return Colors.grey;
    }
  }
}

class _AnimatedStatusBadge extends StatelessWidget {
  final RideLifecycleStatus status;
  final Color color;

  const _AnimatedStatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == RideLifecycleStatus.inProgress ||
              status == RideLifecycleStatus.arriving)
            _PulsingIndicator(color: color)
          else
            Icon(_statusIcon(status), color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            _statusText(status),
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  IconData _statusIcon(RideLifecycleStatus status) {
    switch (status) {
      case RideLifecycleStatus.completed:
        return Icons.check_circle_rounded;
      case RideLifecycleStatus.cancelled:
        return Icons.cancel_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  String _statusText(RideLifecycleStatus status) {
    switch (status) {
      case RideLifecycleStatus.searching:
        return 'Searching';
      case RideLifecycleStatus.driverAssigned:
        return 'Driver Assigned';
      case RideLifecycleStatus.arriving:
        return 'Driver Arriving';
      case RideLifecycleStatus.inProgress:
        return 'In Progress';
      case RideLifecycleStatus.completed:
        return 'Completed';
      case RideLifecycleStatus.cancelled:
        return 'Cancelled';
      case RideLifecycleStatus.idle:
        return 'Idle';
    }
  }
}

class _PulsingIndicator extends StatefulWidget {
  final Color color;
  const _PulsingIndicator({required this.color});

  @override
  State<_PulsingIndicator> createState() => _PulsingIndicatorState();
}

class _PulsingIndicatorState extends State<_PulsingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.4 + _controller.value * 0.6),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(_controller.value * 0.4),
                blurRadius: 6,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DriverCard extends StatelessWidget {
  final RideTrip trip;
  final bool isDark;

  const _DriverCard({required this.trip, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.small,
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primary.withOpacity(0.12),
                child: Text(
                  (trip.driver?.name ?? 'D')[0],
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Colors.white, size: 10),
                      Text(
                        trip.driver?.rating.toStringAsFixed(1) ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.driver?.name ?? 'Driver',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      _rideTypeIcon(trip.rideType),
                      size: 14,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${trip.driver?.vehicleModel ?? ''} • ${trip.driver?.vehicleNumber ?? ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
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
                Formatters.currency(trip.fare),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Text(
                trip.paymentMethod.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _rideTypeIcon(RideType type) {
    switch (type) {
      case RideType.bike:
        return Icons.two_wheeler_rounded;
      case RideType.premium:
        return Icons.directions_car_rounded;
      case RideType.suv:
        return Icons.airport_shuttle_rounded;
      case RideType.economy:
        return Icons.local_taxi_rounded;
      case RideType.pool:
        return Icons.group_rounded;
    }
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionIconButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingPromptCard extends StatelessWidget {
  final String driverName;
  final VoidCallback onRate;

  const _RatingPromptCard({
    required this.driverName,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.glow,
      ),
      child: Row(
        children: [
          const Icon(Icons.star_rounded, color: Colors.white, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rate your ride',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'How was your experience with $driverName?',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onRate,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Rate'),
          ),
        ],
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({
    required this.color,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final Color color;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(body),
              ],
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

// _TrackingMapMock and _TrackingGridPainter removed – replaced by LiveTrackingMap.

class _AddressRow extends StatelessWidget {
  const _AddressRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
