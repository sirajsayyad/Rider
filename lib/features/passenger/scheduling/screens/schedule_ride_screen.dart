import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/themes.dart';
import '../../../../core/widgets/buttons/buttons.dart';
import '../models/schedule_models.dart';
import '../providers/schedule_provider.dart';

/// Ride scheduling screen with 7-day calendar and time slot picker
class ScheduleRideScreen extends ConsumerWidget {
  const ScheduleRideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleState = ref.watch(scheduleControllerProvider);
    final controller = ref.read(scheduleControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Schedule a Ride')),
      body: Column(
        children: [
          // 7-day calendar strip
          Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              boxShadow: AppShadows.small,
            ),
            child: SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: 7,
                itemBuilder: (context, index) {
                  final date = DateTime.now().add(Duration(days: index + 1));
                  final isSelected = _isSameDay(date, scheduleState.selectedDate);
                  return GestureDetector(
                    onTap: () => controller.selectDate(date),
                    child: Container(
                      width: 60,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? AppColors.darkCard : AppColors.lightCard),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: isSelected
                            ? null
                            : Border.all(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder,
                              ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat.E().format(date),
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected
                                  ? Colors.white70
                                  : (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat.d().format(date),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                      ? AppColors.darkText
                                      : AppColors.lightText),
                            ),
                          ),
                          Text(
                            DateFormat.MMM().format(date),
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected
                                  ? Colors.white70
                                  : (isDark
                                      ? AppColors.darkTextTertiary
                                      : AppColors.lightTextTertiary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Time slots
          Expanded(
            child: scheduleState.availableSlots.isEmpty
                ? const Center(child: Text('No available slots for this date'))
                : GridView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2.2,
                    ),
                    itemCount: scheduleState.availableSlots.length,
                    itemBuilder: (context, index) {
                      final slot = scheduleState.availableSlots[index];
                      final isSelected =
                          scheduleState.selectedSlot?.time == slot.time;
                      return GestureDetector(
                        onTap: slot.isAvailable
                            ? () => controller.selectSlot(slot)
                            : null,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : slot.isAvailable
                                    ? (isDark
                                        ? AppColors.darkCard
                                        : AppColors.lightCard)
                                    : (isDark
                                        ? AppColors.darkCard.withOpacity(0.5)
                                        : AppColors.lightBorder
                                            .withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: isSelected
                                ? Border.all(
                                    color: AppColors.primaryLight,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                DateFormat.jm().format(slot.time),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : slot.isAvailable
                                          ? null
                                          : (isDark
                                              ? AppColors.darkTextTertiary
                                              : AppColors.lightTextTertiary),
                                ),
                              ),
                              if (slot.isAvailable)
                                Text(
                                  '${slot.availableDrivers} drivers',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: isSelected
                                        ? Colors.white70
                                        : AppColors.success,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Upcoming scheduled rides
          if (scheduleState.upcomingRides.isNotEmpty) ...[
            const Divider(height: 1),
            Container(
              constraints: const BoxConstraints(maxHeight: 160),
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.sm),
                shrinkWrap: true,
                itemCount: scheduleState.upcomingRides.length,
                itemBuilder: (context, index) {
                  final ride = scheduleState.upcomingRides[index];
                  return _ScheduledRideTile(
                    ride: ride,
                    onCancel: () => controller.cancelScheduledRide(ride.id),
                  );
                },
              ),
            ),
          ],

          // Bottom action
          Container(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              MediaQuery.of(context).padding.bottom + AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              boxShadow: AppShadows.large,
            ),
            child: Column(
              children: [
                if (scheduleState.selectedSlot != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Scheduled for ${DateFormat.yMMMd().add_jm().format(scheduleState.selectedSlot!.time)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                PrimaryButton(
                  text: scheduleState.isLoading
                      ? 'Scheduling...'
                      : 'Schedule Ride',
                  icon: Icons.calendar_month_outlined,
                  onPressed: scheduleState.selectedSlot == null ||
                          scheduleState.isLoading
                      ? null
                      : () async {
                          final ride = await controller.scheduleRide(
                            pickupAddress: 'Current Location',
                            pickupLat: 17.8844,
                            pickupLng: 75.0227,
                            destinationAddress: 'Pune, Maharashtra',
                            destLat: 18.5204,
                            destLng: 73.8567,
                            rideType: 'economy',
                            estimatedFare: 245.0,
                          );
                          if (ride != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Ride scheduled for ${DateFormat.jm().format(ride.scheduledAt)}! You\'ll get a reminder 15 min before.',
                                ),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _ScheduledRideTile extends StatelessWidget {
  const _ScheduledRideTile({required this.ride, required this.onCancel});
  final ScheduledRide ride;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(Icons.schedule, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat.yMMMd().add_jm().format(ride.scheduledAt),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${ride.pickupAddress} → ${ride.destinationAddress}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (ride.assignedDriverName != null)
                  Text(
                    'Driver: ${ride.assignedDriverName}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.success,
                    ),
                  ),
              ],
            ),
          ),
          if (ride.status != ScheduleStatus.cancelled)
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: AppColors.error),
              onPressed: onCancel,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}
