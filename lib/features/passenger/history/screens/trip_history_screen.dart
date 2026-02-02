import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/themes.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/cards/cards.dart';
import '../../../../core/widgets/loaders/loaders.dart';

/// Trip history screen showing all past rides
class TripHistoryScreen extends ConsumerWidget {
  const TripHistoryScreen({super.key});

  // Demo trip data
  static final List<Map<String, dynamic>> _trips = [
    {
      'id': '1',
      'pickup': 'Connaught Place, New Delhi',
      'drop': 'India Gate, New Delhi',
      'date': DateTime.now().subtract(const Duration(hours: 2)),
      'status': 'completed',
      'fare': 156.0,
    },
    {
      'id': '2',
      'pickup': 'Nehru Place Metro Station',
      'drop': 'Select Citywalk, Saket',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'status': 'completed',
      'fare': 234.0,
    },
    {
      'id': '3',
      'pickup': 'IGI Airport Terminal 3',
      'drop': 'Taj Palace Hotel, Chanakyapuri',
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'status': 'cancelled',
      'fare': 0.0,
    },
    {
      'id': '4',
      'pickup': 'Hauz Khas Village',
      'drop': 'Greater Kailash 1',
      'date': DateTime.now().subtract(const Duration(days: 3)),
      'status': 'completed',
      'fare': 189.0,
    },
    {
      'id': '5',
      'pickup': 'DLF Cyber City, Gurugram',
      'drop': 'Rajiv Chowk Metro Station',
      'date': DateTime.now().subtract(const Duration(days: 5)),
      'status': 'completed',
      'fare': 456.0,
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterSheet(context);
            },
          ),
        ],
      ),
      body: _trips.isEmpty
          ? const EmptyState(
              icon: Icons.directions_car_outlined,
              title: 'No trips yet',
              subtitle: 'Your trip history will appear here',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _trips.length,
              itemBuilder: (context, index) {
                final trip = _trips[index];
                return TripCard(
                  rideId: trip['id'],
                  pickup: trip['pickup'],
                  drop: trip['drop'],
                  date: Formatters.dateTime(trip['date']),
                  status: trip['status'],
                  fare: trip['fare'],
                  onTap: () {
                    _showTripDetails(context, trip, isDark);
                  },
                );
              },
            ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Trips',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                FilterChip(label: const Text('All'), onSelected: (_) {}),
                FilterChip(label: const Text('Completed'), onSelected: (_) {}),
                FilterChip(label: const Text('Cancelled'), onSelected: (_) {}),
                FilterChip(label: const Text('This Week'), onSelected: (_) {}),
                FilterChip(label: const Text('This Month'), onSelected: (_) {}),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  void _showTripDetails(BuildContext context, Map<String, dynamic> trip, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ListView(
            controller: scrollController,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Trip Details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: trip['status'] == 'completed'
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      trip['status'].toString().toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: trip['status'] == 'completed'
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Date
              _DetailRow(
                icon: Icons.calendar_today,
                label: 'Date',
                value: Formatters.dateTime(trip['date']),
              ),

              // Locations
              const Divider(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        height: 40,
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.dropMarker,
                          shape: BoxShape.circle,
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
                          trip['pickup'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.darkText : AppColors.lightText,
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          trip['drop'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.darkText : AppColors.lightText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Fare
              if (trip['status'] == 'completed') ...[
                const Divider(height: 32),
                _DetailRow(
                  icon: Icons.receipt,
                  label: 'Total Fare',
                  value: Formatters.currency(trip['fare']),
                  valueStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              // Actions
              if (trip['status'] == 'completed')
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.receipt_long),
                        label: const Text('Invoice'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.support_agent),
                        label: const Text('Support'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              Text(
                value,
                style: valueStyle ??
                    TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
