import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/themes.dart';
import '../../../../core/utils/formatters.dart';
import '../../../passenger/ride/domain/ride_models.dart';
import '../providers/multistop_provider.dart';

/// Widget for displaying and managing multi-stop ride stops
class StopListWidget extends ConsumerWidget {
  const StopListWidget({
    super.key,
    this.pickup,
    this.destination,
    this.onAddStop,
  });

  final RidePoint? pickup;
  final RidePoint? destination;
  final VoidCallback? onAddStop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final multiStop = ref.watch(multiStopControllerProvider);
    final controller = ref.read(multiStopControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
              const Icon(Icons.route_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Route Stops',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (multiStop.canAddStop)
                TextButton.icon(
                  onPressed: onAddStop,
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: const Text('Add Stop', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Pickup
          _RouteStopRow(
            icon: Icons.my_location,
            iconColor: AppColors.pickupMarker,
            title: 'Pickup',
            address: pickup?.address ?? 'Set pickup location',
            isFirst: true,
          ),

          // Intermediate stops
          ...List.generate(multiStop.stops.length, (index) {
            final stop = multiStop.stops[index];
            final legFare = multiStop.legFares[index];
            final legEta = multiStop.legEtaMinutes[index];
            return _RouteStopRow(
              icon: Icons.circle,
              iconColor: AppColors.accent,
              title: 'Stop ${index + 1}',
              address: stop.address,
              legInfo: legFare != null
                  ? '${Formatters.currency(legFare)} • ${legEta ?? 0} min'
                  : null,
              onRemove: () => controller.removeStop(index),
            );
          }),

          // Destination
          _RouteStopRow(
            icon: Icons.location_on,
            iconColor: AppColors.dropMarker,
            title: 'Drop-off',
            address: destination?.address ?? 'Set destination',
            isLast: true,
            legInfo: multiStop.legFares.isNotEmpty
                ? '${Formatters.currency(multiStop.legFares[multiStop.stops.length] ?? 0)} • ${multiStop.legEtaMinutes[multiStop.stops.length] ?? 0} min'
                : null,
          ),

          // Total summary
          if (multiStop.stops.isNotEmpty) ...[
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${multiStop.stops.length + 2} stops • ${Formatters.distance(multiStop.totalDistanceKm)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                if (multiStop.totalFare > 0)
                  Text(
                    'Total: ${Formatters.currency(multiStop.totalFare)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RouteStopRow extends StatelessWidget {
  const _RouteStopRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.address,
    this.legInfo,
    this.onRemove,
    this.isFirst = false,
    this.isLast = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String address;
  final String? legInfo;
  final VoidCallback? onRemove;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Column(
            children: [
              if (!isFirst)
                Container(
                  width: 2,
                  height: 12,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              Icon(icon, color: iconColor, size: 14),
              if (!isLast)
                Container(
                  width: 2,
                  height: 12,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    if (legInfo != null) ...[
                      const Spacer(),
                      Text(
                        legInfo!,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  address,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.close, size: 16, color: AppColors.error),
              onPressed: onRemove,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
        ],
      ),
    );
  }
}
