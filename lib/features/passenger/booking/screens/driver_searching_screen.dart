import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/routes.dart';
import '../../../../core/config/themes.dart';
import '../../../../core/utils/formatters.dart';
import '../../ride/application/ride_controller.dart';
import '../../ride/domain/ride_models.dart';

class DriverSearchingScreen extends ConsumerStatefulWidget {
  const DriverSearchingScreen({super.key});

  @override
  ConsumerState<DriverSearchingScreen> createState() =>
      _DriverSearchingScreenState();
}

class _DriverSearchingScreenState
    extends ConsumerState<DriverSearchingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _startRideRequest();
  }

  void _startRideRequest() async {
    final controller = ref.read(rideControllerProvider.notifier);
    final rideId = await controller.requestRide();
    if (!mounted) return;

    if (rideId != null) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        context.go('/passenger/tracking/$rideId');
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(rideControllerProvider);
    final isSearching = state.isSearchingDriver;
    final trip = state.activeTrip;

    // Auto-navigate when driver is found
    if (trip != null && !isSearching) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/passenger/tracking/${trip.id}');
        }
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          _AnimatedBackground(isDark: isDark, controller: _rotateController),

          // Content
          SafeArea(
            child: Column(
              children: [
                // App bar
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      _GlassIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () {
                          ref
                              .read(rideControllerProvider.notifier)
                              .cancelActiveRide();
                          context.go(Routes.passengerHome);
                        },
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius:
                              BorderRadius.circular(AppRadius.full),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isSearching
                                    ? AppColors.accent
                                    : AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isSearching
                                  ? 'Searching...'
                                  : 'Driver Found!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Searching animation
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.5),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _slideController,
                    curve: Curves.easeOutCubic,
                  )),
                  child: _SearchingPulse(
                    controller: _pulseController,
                    isSearching: isSearching,
                    quote: state.selectedQuote,
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Ride info
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _slideController,
                    curve: const Interval(0.3, 1.0,
                        curve: Curves.easeOutCubic),
                  )),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppRadius.xl),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.my_location,
                                  color: AppColors.pickupMarker,
                                  size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  state.pickup?.address ?? 'Pickup',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 8, top: 4, bottom: 4),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: 1.5,
                                height: 20,
                                color: Colors.white24,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  color: AppColors.dropMarker,
                                  size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  state.destination?.address ??
                                      'Destination',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (state.selectedQuote != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            Container(
                              height: 1,
                              color: Colors.white12,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceAround,
                              children: [
                                _InfoPill(
                                  icon: Icons.local_taxi_rounded,
                                  label: state
                                          .selectedQuote!.label,
                                ),
                                _InfoPill(
                                  icon:
                                      Icons.attach_money_rounded,
                                  label: Formatters.currency(
                                      state.selectedQuote!.fare),
                                ),
                                _InfoPill(
                                  icon: Icons.schedule_rounded,
                                  label:
                                      '${state.selectedQuote!.etaMinutes} min',
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Tips
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl),
                  child: Text(
                    isSearching
                        ? 'We\'re matching you with the best nearby driver.\nThis usually takes under 30 seconds.'
                        : 'Your driver has been found!\nRedirecting to tracking...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Cancel button
                if (isSearching)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          ref
                              .read(rideControllerProvider.notifier)
                              .cancelActiveRide();
                          context.go(Routes.passengerHome);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side:
                              const BorderSide(color: Colors.white38),
                          padding: const EdgeInsets.symmetric(
                              vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppRadius.md),
                          ),
                        ),
                        child: const Text('Cancel Search'),
                      ),
                    ),
                  ),

                SizedBox(
                  height:
                      MediaQuery.of(context).padding.bottom + AppSpacing.lg,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedBackground extends StatelessWidget {
  final bool isDark;
  final AnimationController controller;

  const _AnimatedBackground({
    required this.isDark,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1a1a3e),
                Color.lerp(
                  const Color(0xFF2d1b69),
                  const Color(0xFF0d2137),
                  (sin(controller.value * pi * 2) + 1) / 2,
                )!,
                const Color(0xFF0a1628),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SearchingPulse extends StatelessWidget {
  final AnimationController controller;
  final bool isSearching;
  final RideTypeQuote? quote;

  const _SearchingPulse({
    required this.controller,
    required this.isSearching,
    this.quote,
  });

  @override
  Widget build(BuildContext context) {
    final rideIcon = switch (quote?.type) {
      RideType.bike => Icons.two_wheeler_rounded,
      RideType.premium => Icons.directions_car_rounded,
      RideType.suv => Icons.airport_shuttle_rounded,
      _ => Icons.local_taxi_rounded,
    };

    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ripples
          ...List.generate(3, (index) {
            return AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                final delay = index * 0.3;
                final value =
                    ((controller.value + delay) % 1.0);
                return Transform.scale(
                  scale: 0.5 + value * 0.7,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (isSearching
                                ? AppColors.primary
                                : AppColors.success)
                            .withOpacity((1 - value) * 0.4),
                        width: 2,
                      ),
                    ),
                  ),
                );
              },
            );
          }),

          // Center icon
          AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              final scale = isSearching
                  ? 1.0 + controller.value * 0.08
                  : 1.15;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: isSearching
                        ? AppColors.primaryGradient
                        : AppColors.successGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isSearching
                                ? AppColors.primary
                                : AppColors.success)
                            .withOpacity(0.4),
                        blurRadius: 24,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: Icon(
                    isSearching
                        ? rideIcon
                        : Icons.check_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
