import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/routes.dart';
import '../../../../core/config/themes.dart';

class PassengerServicesScreen extends StatelessWidget {
  const PassengerServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Services', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // For You Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'For you',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.lightText,
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.arrow_forward_rounded,
                      color: isDark ? Colors.white : AppColors.lightText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              
              // Grid of Services
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
                children: [
                  _ServiceBadgeCard(
                    title: 'Ride',
                    icon: Icons.directions_car_rounded,
                    badgeText: '40%',
                    badgeColor: const Color(0xFFEF4444),
                    onTap: () => context.go(Routes.passengerHomeTab), // Navigates to booking map
                  ),
                  _ServiceBadgeCard(
                    title: 'Intercity',
                    icon: Icons.directions_car_rounded,
                    badgeText: '40%',
                    badgeColor: const Color(0xFFEF4444),
                    onTap: () => context.push(Routes.serviceIntercity),
                  ),
                  _ServiceBadgeCard(
                    title: 'Rentals',
                    icon: Icons.directions_car_rounded,
                    badgeText: '40%',
                    badgeColor: const Color(0xFFEF4444),
                    onTap: () => context.push(Routes.serviceRentals),
                  ),
                  _ServiceBadgeCard(
                    title: 'Bus tickets',
                    icon: Icons.directions_bus_rounded,
                    badgeText: 'Promo',
                    badgeColor: const Color(0xFFF59E0B),
                    onTap: () => context.push(Routes.serviceBusTickets),
                  ),
                  _ServiceIconCard(
                    title: 'Reserve',
                    icon: Icons.event_available_rounded,
                    onTap: () => context.push(Routes.scheduleRide),
                  ),
                  _ServiceIconCard(
                    title: 'Teens',
                    icon: Icons.accessibility_new_rounded,
                    onTap: () => context.push(Routes.profileTeens),
                  ),
                  _ServiceIconCard(
                    title: 'Seniors',
                    icon: Icons.emoji_people_rounded,
                    onTap: () => context.push(Routes.serviceSeniors),
                  ),
                  _ServiceIconCard(
                    title: 'See all',
                    icon: Icons.grid_view_rounded,
                    onTap: () => context.push(Routes.serviceSeeAll),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceBadgeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String badgeText;
  final Color badgeColor;
  final VoidCallback onTap;

  const _ServiceBadgeCard({
    required this.title,
    required this.icon,
    required this.badgeText,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2B3648) : const Color(0xFFF1F5F9);
    final iconColor = isDark ? Colors.white : AppColors.lightText;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 38, color: iconColor),
                  Positioned(
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badgeText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700, 
                fontSize: 12,
                color: iconColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceIconCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ServiceIconCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2B3648) : const Color(0xFFF1F5F9);
    final iconColor = isDark ? Colors.white : AppColors.lightText;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: Icon(icon, size: 36, color: iconColor),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700, 
                fontSize: 12,
                color: iconColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
