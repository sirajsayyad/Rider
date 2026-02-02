import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/themes.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/buttons/buttons.dart';
import '../../../../core/widgets/cards/cards.dart';
import '../../../../core/widgets/loaders/loaders.dart';

/// Booking screen with vehicle selection and fare estimation
class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  final _pickupController = TextEditingController(text: 'Current Location');
  final _dropController = TextEditingController();
  String? _selectedVehicleType;
  bool _isSearchingDrivers = false;

  // Demo data
  final double _distance = 12.5; // km
  final int _duration = 25; // minutes

  final List<VehicleType> _vehicleTypes = [
    VehicleType(
      type: 'auto',
      name: 'Auto',
      description: 'Affordable auto rickshaw',
      icon: Icons.electric_rickshaw,
      capacity: 3,
    ),
    VehicleType(
      type: 'mini',
      name: 'Mini',
      description: 'Compact and economical',
      icon: Icons.directions_car,
      capacity: 4,
    ),
    VehicleType(
      type: 'sedan',
      name: 'Sedan',
      description: 'Comfortable AC sedan',
      icon: Icons.directions_car_filled,
      capacity: 4,
    ),
    VehicleType(
      type: 'suv',
      name: 'SUV',
      description: 'Spacious for families',
      icon: Icons.airport_shuttle,
      capacity: 6,
    ),
    VehicleType(
      type: 'premium',
      name: 'Premium',
      description: 'Luxury ride experience',
      icon: Icons.local_taxi,
      capacity: 4,
    ),
  ];

  @override
  void dispose() {
    _pickupController.dispose();
    _dropController.dispose();
    super.dispose();
  }

  void _bookRide() {
    if (_selectedVehicleType == null || _dropController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter destination and select a vehicle'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSearchingDrivers = true);

    // Simulate driver search
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isSearchingDrivers = false);
        context.go('/passenger/tracking/demo-ride-123');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Book Ride'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location inputs
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: AppShadows.small,
                  ),
                  child: Column(
                    children: [
                      _buildLocationRow(
                        controller: _pickupController,
                        label: 'Pickup',
                        icon: Icons.circle,
                        iconColor: AppColors.pickupMarker,
                        isDark: isDark,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 2,
                              height: 30,
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.swap_vert),
                              onPressed: () {
                                final temp = _pickupController.text;
                                _pickupController.text = _dropController.text;
                                _dropController.text = temp;
                              },
                              tooltip: 'Swap locations',
                            ),
                          ],
                        ),
                      ),
                      _buildLocationRow(
                        controller: _dropController,
                        label: 'Drop',
                        icon: Icons.location_on,
                        iconColor: AppColors.dropMarker,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Trip info
                if (_dropController.text.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _TripInfoChip(
                        icon: Icons.route,
                        label: Formatters.distance(_distance),
                        subtitle: 'Distance',
                      ),
                      _TripInfoChip(
                        icon: Icons.access_time,
                        label: Formatters.duration(_duration),
                        subtitle: 'Duration',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Vehicle selection
                Text(
                  'Choose Vehicle',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                ..._vehicleTypes.map((vehicle) {
                  final fare = Helpers.calculateFare(
                    distanceKm: _distance,
                    vehicleType: vehicle.type,
                  );
                  final eta = Helpers.calculateETA(_distance) + 5; // +5 for driver arrival

                  return VehicleTypeCard(
                    type: vehicle.type,
                    name: vehicle.name,
                    description: vehicle.description,
                    icon: vehicle.icon,
                    fare: fare,
                    eta: eta,
                    isSelected: _selectedVehicleType == vehicle.type,
                    onTap: () {
                      setState(() => _selectedVehicleType = vehicle.type);
                    },
                  );
                }),

                const SizedBox(height: AppSpacing.xl),

                // Payment method
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: AppShadows.small,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(
                          Icons.money,
                          color: AppColors.success,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment Method',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                            Text(
                              'Cash',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkText
                                    : AppColors.lightText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 100), // Space for bottom button
              ],
            ),
          ),

          // Bottom book button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
                top: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_selectedVehicleType != null) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total Fare',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        Text(
                          Formatters.currency(Helpers.calculateFare(
                            distanceKm: _distance,
                            vehicleType: _selectedVehicleType!,
                          )),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkText
                                : AppColors.lightText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.lg),
                  ],
                  Expanded(
                    child: PrimaryButton(
                      text: 'Book Now',
                      onPressed: _selectedVehicleType != null ? _bookRide : null,
                      icon: Icons.check,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Searching drivers overlay
          if (_isSearchingDrivers)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(AppSpacing.xl),
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SearchingDriverLoader(),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Finding your ride',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.darkText
                              : AppColors.lightText,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Looking for nearby drivers...',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SecondaryButton(
                        text: 'Cancel',
                        onPressed: () {
                          setState(() => _isSearchingDrivers = false);
                        },
                        isFullWidth: false,
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

  Widget _buildLocationRow({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 14),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Enter $label location',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }
}

class _TripInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;

  const _TripInfoChip({
    required this.icon,
    required this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              Text(
                subtitle,
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
}

class VehicleType {
  final String type;
  final String name;
  final String description;
  final IconData icon;
  final int capacity;

  VehicleType({
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    required this.capacity,
  });
}
