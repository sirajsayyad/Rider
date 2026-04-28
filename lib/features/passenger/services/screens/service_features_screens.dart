import 'package:flutter/material.dart';
import '../../../../core/config/themes.dart';

class _BaseServiceScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;
  final String actionText;

  const _BaseServiceScreen({
    required this.title,
    required this.icon,
    required this.description,
    required this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 80, color: AppColors.primary),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                description,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(actionText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IntercityScreen extends StatelessWidget {
  const IntercityScreen({super.key});
  @override
  Widget build(BuildContext context) => const _BaseServiceScreen(
    title: 'Intercity Rides',
    icon: Icons.airport_shuttle_rounded,
    description: 'Book comfortable rides across cities. Enjoy door-to-door pickup and fixed pricing.',
    actionText: 'Plan a Trip',
  );
}

class RentalsScreen extends StatelessWidget {
  const RentalsScreen({super.key});
  @override
  Widget build(BuildContext context) => const _BaseServiceScreen(
    title: 'Car Rentals',
    icon: Icons.car_rental_rounded,
    description: 'Keep a car and driver for multiple hours. Perfect for meetings, shopping, or sightseeing.',
    actionText: 'Book a Rental',
  );
}

class BusTicketsScreen extends StatelessWidget {
  const BusTicketsScreen({super.key});
  @override
  Widget build(BuildContext context) => const _BaseServiceScreen(
    title: 'Bus Tickets',
    icon: Icons.directions_bus_rounded,
    description: 'Book affordable and comfortable bus tickets to your favorite destinations.',
    actionText: 'Search Buses',
  );
}

class SeniorsScreen extends StatelessWidget {
  const SeniorsScreen({super.key});
  @override
  Widget build(BuildContext context) => const _BaseServiceScreen(
    title: 'Serene for Seniors',
    icon: Icons.elderly_rounded,
    description: 'Specially trained drivers and simplified tools designed to help elderly passengers travel safely and comfortably.',
    actionText: 'Learn More',
  );
}

class SeeAllServicesScreen extends StatelessWidget {
  const SeeAllServicesScreen({super.key});
  @override
  Widget build(BuildContext context) => const _BaseServiceScreen(
    title: 'All Services',
    icon: Icons.grid_view_rounded,
    description: 'Explore the entire suite of Serene services, from package delivery to luxury vehicles.',
    actionText: 'Explore Directory',
  );
}
