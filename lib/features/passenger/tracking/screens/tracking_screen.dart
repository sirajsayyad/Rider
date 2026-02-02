import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/routes.dart';
import '../../../../core/config/themes.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/buttons/buttons.dart';

/// Live ride tracking screen
class TrackingScreen extends ConsumerStatefulWidget {
  final String rideId;

  const TrackingScreen({super.key, required this.rideId});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  // Demo ride data
  String _rideStatus = 'arriving'; // arriving, started, completed
  int _eta = 5;
  final _driverName = 'Raj Kumar';
  final _driverRating = 4.8;
  final _vehicleNumber = 'DL 01 AB 1234';
  final _vehicleModel = 'Maruti Swift';

  @override
  void initState() {
    super.initState();
    _simulateRideProgress();
  }

  void _simulateRideProgress() {
    // Simulate driver arriving after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _rideStatus = 'started';
          _eta = 15;
        });
      }
    });

    // Simulate ride completion after 15 seconds
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted) {
        setState(() {
          _rideStatus = 'completed';
        });
      }
    });
  }

  Color _getStatusColor() {
    switch (_rideStatus) {
      case 'arriving':
        return AppColors.warning;
      case 'started':
        return AppColors.primary;
      case 'completed':
        return AppColors.success;
      default:
        return AppColors.info;
    }
  }

  String _getStatusText() {
    switch (_rideStatus) {
      case 'arriving':
        return 'Driver is arriving';
      case 'started':
        return 'Trip in progress';
      case 'completed':
        return 'Trip completed';
      default:
        return 'Processing';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Map placeholder
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [const Color(0xFF1a1a2e), const Color(0xFF16213e)]
                    : [const Color(0xFFe8f4ea), const Color(0xFFd4e6d9)],
              ),
            ),
            child: CustomPaint(
              painter: _MapGridPainter(isDark: isDark),
            ),
          ),

          // Route line visualization
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pickup marker
                const _MapMarker(
                  icon: Icons.circle,
                  color: AppColors.pickupMarker,
                  label: 'Pickup',
                ),
                Container(
                  width: 3,
                  height: 100,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.pickupMarker,
                        AppColors.primary,
                        AppColors.dropMarker,
                      ],
                    ),
                  ),
                ),
                // Drop marker
                const _MapMarker(
                  icon: Icons.location_on,
                  color: AppColors.dropMarker,
                  label: 'Drop',
                ),
              ],
            ),
          ),

          // Driver car icon (animated position would be implemented with real maps)
          Positioned(
            left: MediaQuery.of(context).size.width * 0.4,
            top: MediaQuery.of(context).size.height * 0.35,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: AppShadows.glow,
              ),
              child: const Icon(
                Icons.directions_car,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),

          // Back button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: CircularIconButton(
                icon: Icons.arrow_back,
                onPressed: () => context.go(Routes.passengerHome),
              ),
            ),
          ),

          // Bottom info panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xl),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag handle
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getStatusColor(),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getStatusText(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _getStatusColor(),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (_rideStatus != 'completed') ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Arriving in $_eta min',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkText
                                : AppColors.lightText,
                          ),
                        ),
                      ],

                      const SizedBox(height: AppSpacing.lg),

                      // Driver info
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCard
                              : AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              child: Text(
                                _driverName[0],
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        _driverName,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? AppColors.darkText
                                              : AppColors.lightText,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.warning.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              size: 12,
                                              color: AppColors.warning,
                                            ),
                                            const SizedBox(width: 2),
                                            Text(
                                              Formatters.rating(_driverRating),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.warning,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$_vehicleModel • $_vehicleNumber',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Action buttons
                      if (_rideStatus != 'completed')
                        Row(
                          children: [
                            Expanded(
                              child: SecondaryButton(
                                text: 'Chat',
                                icon: Icons.chat_bubble_outline,
                                onPressed: () {},
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: PrimaryButton(
                                text: 'Call',
                                icon: Icons.call,
                                onPressed: () {},
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                gradient: AppColors.successGradient,
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  SizedBox(width: AppSpacing.sm),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Trip Completed!',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        'Total Fare: ₹156',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            PrimaryButton(
                              text: 'Rate Your Trip',
                              icon: Icons.star,
                              onPressed: () {
                                context.go(Routes.passengerHome);
                              },
                            ),
                          ],
                        ),

                      // SOS button for active rides
                      if (_rideStatus != 'completed') ...[
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton.icon(
                              onPressed: () => context.push(Routes.sos),
                              icon: const Icon(
                                Icons.emergency,
                                color: AppColors.error,
                                size: 18,
                              ),
                              label: const Text(
                                'Emergency SOS',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _MapMarker({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppShadows.small,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Icon(icon, color: color, size: 16),
      ],
    );
  }
}

// Map grid painter
class _MapGridPainter extends CustomPainter {
  final bool isDark;

  _MapGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.grey).withOpacity(0.1)
      ..strokeWidth = 1;

    const gridSize = 40.0;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
