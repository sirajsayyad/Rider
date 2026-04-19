import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/config/routes.dart';
import '../../../../core/config/themes.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/buttons/buttons.dart';
import '../../../../core/widgets/inputs/inputs.dart';
import '../../ride/application/ride_controller.dart';
import '../../ride/domain/ride_models.dart';

class _HomeServiceItem {
  final String id;
  final String label;
  final IconData icon;
  final String? badgeText;
  final Color? badgeColor;

  const _HomeServiceItem({
    required this.id,
    required this.label,
    required this.icon,
    this.badgeText,
    this.badgeColor,
  });

  _HomeServiceItem copyWith({
    String? badgeText,
    Color? badgeColor,
  }) {
    return _HomeServiceItem(
      id: id,
      label: label,
      icon: icon,
      badgeText: badgeText ?? this.badgeText,
      badgeColor: badgeColor ?? this.badgeColor,
    );
  }
}

class _HomePromoOffer {
  final String title;
  final String subtitle;
  final String cta;
  final String imageUrl;
  final double discountPercent;

  const _HomePromoOffer({
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.imageUrl,
    required this.discountPercent,
  });
}

final homeServicesProvider = StateNotifierProvider.autoDispose<
    _HomeServicesNotifier, List<_HomeServiceItem>>((ref) {
  final notifier = _HomeServicesNotifier();
  ref.onDispose(notifier.dispose);
  return notifier;
});

class _HomeServicesNotifier extends StateNotifier<List<_HomeServiceItem>> {
  _HomeServicesNotifier() : super(_initialItems()) {
    _timer =
        Timer.periodic(const Duration(seconds: 12), (_) => _refreshBadges());
  }

  Timer? _timer;

  static List<_HomeServiceItem> _initialItems() {
    return const [
      _HomeServiceItem(
        id: 'ride',
        label: 'Ride',
        icon: Icons.local_taxi_outlined,
        badgeText: '40%',
        badgeColor: AppColors.error,
      ),
      _HomeServiceItem(
        id: 'intercity',
        label: 'Intercity',
        icon: Icons.directions_car_filled_outlined,
        badgeText: '40%',
        badgeColor: AppColors.error,
      ),
      _HomeServiceItem(
        id: 'rentals',
        label: 'Rentals',
        icon: Icons.car_rental_outlined,
        badgeText: '40%',
        badgeColor: AppColors.error,
      ),
      _HomeServiceItem(
        id: 'bus',
        label: 'Bus tickets',
        icon: Icons.directions_bus_filled_outlined,
        badgeText: 'Promo',
        badgeColor: AppColors.warning,
      ),
      _HomeServiceItem(
        id: 'reserve',
        label: 'Reserve',
        icon: Icons.event_available_outlined,
      ),
      _HomeServiceItem(
        id: 'teens',
        label: 'Teens',
        icon: Icons.emoji_people_outlined,
      ),
      _HomeServiceItem(
        id: 'seniors',
        label: 'Seniors',
        icon: Icons.accessibility_new_outlined,
      ),
      _HomeServiceItem(
        id: 'all',
        label: 'See all',
        icon: Icons.grid_view_rounded,
      ),
    ];
  }

  void _refreshBadges() {
    final rng = math.Random();
    state = [
      for (final item in state)
        switch (item.id) {
          'ride' || 'intercity' || 'rentals' => item.copyWith(
              badgeText: '${rng.nextInt(4) * 10 + 10}%',
              badgeColor: AppColors.error,
            ),
          'bus' => item.copyWith(
              badgeText: rng.nextBool() ? 'Promo' : 'New',
              badgeColor:
                  rng.nextBool() ? AppColors.warning : AppColors.primary,
            ),
          _ => item,
        }
    ];
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final homePromoProvider =
    StateNotifierProvider.autoDispose<_HomePromoNotifier, _HomePromoOffer>(
        (ref) {
  final notifier = _HomePromoNotifier();
  ref.onDispose(notifier.dispose);
  return notifier;
});

class _HomePromoNotifier extends StateNotifier<_HomePromoOffer> {
  _HomePromoNotifier() : super(_offers.first) {
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _next());
  }

  static const _offers = <_HomePromoOffer>[
    _HomePromoOffer(
      title: 'Enjoy 40% off Sedan',
      subtitle: 'Intercity',
      cta: 'Book now',
      imageUrl:
          'https://images.unsplash.com/photo-1493238792000-8113da705763?auto=format&fit=crop&w=600&q=80',
      discountPercent: 40,
    ),
    _HomePromoOffer(
      title: 'Save 20% on Rentals',
      subtitle: 'Hourly packages',
      cta: 'Explore',
      imageUrl:
          'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=600&q=80',
      discountPercent: 20,
    ),
    _HomePromoOffer(
      title: 'Flat 15% off airport rides',
      subtitle: 'Limited time',
      cta: 'Apply deal',
      imageUrl:
          'https://images.unsplash.com/photo-1526662092594-e98c1e356d6a?auto=format&fit=crop&w=600&q=80',
      discountPercent: 15,
    ),
  ];

  Timer? _timer;
  int _index = 0;

  void _next() {
    _index = (_index + 1) % _offers.length;
    state = _offers[_index];
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class PassengerHomeScreen extends ConsumerStatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  ConsumerState<PassengerHomeScreen> createState() =>
      _PassengerHomeScreenState();
}

class _ServicesGrid extends StatelessWidget {
  const _ServicesGrid({required this.items, required this.onTapService});

  final List<_HomeServiceItem> items;
  final ValueChanged<_HomeServiceItem> onTapService;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'For you',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Spacer(),
            InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 6,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        GridView.count(
          crossAxisCount: 4,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: items
              .map(
                (item) => _ServiceTile(
                  label: item.label,
                  icon: item.icon,
                  badgeText: item.badgeText,
                  badgeColor: item.badgeColor,
                  onTap: () => onTapService(item),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.label,
    required this.icon,
    required this.onTap,
    this.badgeText,
    this.badgeColor,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final String? badgeText;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 26,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            if (badgeText != null && badgeText!.isNotEmpty)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? AppColors.primary).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    badgeText!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PromoBannerCard extends StatelessWidget {
  const _PromoBannerCard({required this.promo});

  final _HomePromoOffer promo;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.medium,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      promo.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      promo.subtitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: 38,
                      child: ElevatedButton(
                        onPressed: () => context.push(Routes.booking),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? AppColors.darkSurface
                              : AppColors.lightSurface,
                          foregroundColor:
                              isDark ? AppColors.darkText : AppColors.lightText,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                        ),
                        child: const Text(
                          '',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 140,
              height: 120,
              child: CachedNetworkImage(
                imageUrl: promo.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const _PromoImageShimmer(),
                errorWidget: (context, url, error) => Container(
                  color:
                      isDark ? AppColors.darkSurface : AppColors.lightSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoImageShimmer extends StatelessWidget {
  const _PromoImageShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: base.withOpacity(0.6),
      child: Container(color: base),
    );
  }
}

class _PassengerHomeScreenState extends ConsumerState<PassengerHomeScreen> {
  bool _didInitLocation = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitLocation) return;
    _didInitLocation = true;
    Future.microtask(() async {
      final locationService = ref.read(locationServiceProvider);
      await ref
          .read(rideControllerProvider.notifier)
          .setPickupFromCurrentLocation(locationService);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final ride = ref.watch(rideControllerProvider);
    final services = ref.watch(homeServicesProvider);
    final promo = ref.watch(homePromoProvider);

    return Scaffold(
      body: Stack(
        children: [
          _MapBackdrop(isDark: isDark),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: (isDark
                            ? AppColors.darkSurface
                            : AppColors.lightSurface)
                        .withOpacity(0.92),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    boxShadow: AppShadows.medium,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primary.withOpacity(0.12),
                        child: Text(
                          (user?.name ?? 'R')[0].toUpperCase(),
                          style: const TextStyle(
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
                            Text(
                              'Smart pickup',
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              ride.pickup?.address ?? 'Fetching location...',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.darkText
                                    : AppColors.lightText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CircularIconButton(
                        icon: Icons.notifications_none_rounded,
                        onPressed: () => context.push(Routes.notifications),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    boxShadow: AppShadows.large,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reliable ride booking',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'No-cancellation reassignment, fare lock, live safety, and faster matching.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      LocationInput(
                        label: 'Where to?',
                        hint: 'Enter destination',
                        value: ride.destination?.address,
                        icon: Icons.search_rounded,
                        onTap: () => context.push(Routes.booking),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _ServicesGrid(
                        items: services,
                        onTapService: (service) {
                          context.push(Routes.booking);
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _PromoBannerCard(promo: promo),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              title: 'Wallet',
                              value: Formatters.currency(ride.walletBalance),
                              icon: Icons.account_balance_wallet_outlined,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _MetricCard(
                              title: 'Rewards',
                              value: '${ride.rewardPoints} pts',
                              icon: Icons.stars_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      PrimaryButton(
                        text: ride.activeTrip == null
                            ? 'Book A Ride'
                            : 'Track Active Ride',
                        icon: Icons.local_taxi_rounded,
                        onPressed: () {
                          if (ride.activeTrip == null) {
                            context.push(Routes.booking);
                          } else {
                            context.push(
                                '/passenger/tracking/${ride.activeTrip!.id}');
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: SecondaryButton(
                              text: 'Rewards',
                              icon: Icons.stars_rounded,
                              onPressed: () => context.push(Routes.rewards),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: SecondaryButton(
                              text: 'Trips',
                              icon: Icons.history_rounded,
                              onPressed: () => context.push(Routes.tripHistory),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (ride.nearbyDrivers.isNotEmpty)
                  _NearbyDriversPreview(drivers: ride.nearbyDrivers),
                const SizedBox(height: AppSpacing.md),
                if (ride.activeTrip != null)
                  _ActiveRideTile(trip: ride.activeTrip!),
              ],
            ),
          ),
          Positioned(
            right: AppSpacing.md,
            bottom: MediaQuery.of(context).size.height * 0.14,
            child: SosButton(onPressed: () => context.push(Routes.sos)),
          ),
        ],
      ),
    );
  }
}

class _MapBackdrop extends StatelessWidget {
  const _MapBackdrop({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF0f2027), Color(0xFF203a43), Color(0xFF2c5364)]
              : const [Color(0xFFDDF2EB), Color(0xFFC9E6EF), Color(0xFFE7F0FF)],
        ),
      ),
      child: CustomPaint(
        size: Size.infinite,
        painter: _RoadPainter(isDark: isDark),
      ),
    );
  }
}

class _RoadPainter extends CustomPainter {
  const _RoadPainter({required this.isDark});
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.07)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final routePaint = Paint()
      ..color = AppColors.primary.withOpacity(0.25)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.55,
        size.width * 0.85,
        size.height * 0.3,
      );
    canvas.drawPath(path, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodySmall),
                Text(value,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NearbyDriversPreview extends StatelessWidget {
  const _NearbyDriversPreview({required this.drivers});
  final List<NearbyDriverPreview> drivers;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nearest drivers',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          ...drivers.map(
            (driver) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    child: Text(driver.name[0]),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '${driver.name} • ${driver.vehicleModel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text('${driver.etaMinutes} min'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveRideTile extends StatelessWidget {
  const _ActiveRideTile({required this.trip});
  final RideTrip trip;

  @override
  Widget build(BuildContext context) {
    final status = trip.status.name;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: AppColors.primary.withOpacity(0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pin_drop_rounded, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '${trip.driver?.name ?? 'Driver'} • ${Formatters.currency(trip.fare)} • $status',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (trip.compensations.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Compensation added: ${Formatters.currency(trip.compensations.first.amount)}',
              style: const TextStyle(
                  color: AppColors.success, fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }
}
