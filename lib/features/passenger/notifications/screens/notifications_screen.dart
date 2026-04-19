import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/themes.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/loaders/loaders.dart';
import '../../ride/application/ride_controller.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(rideControllerProvider).notifications;
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: items.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No notifications',
              subtitle: 'Ride updates and payment alerts will appear here.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkCard
                        : AppColors.lightCard,
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.notifications_active_outlined),
                    title: Text(item.title),
                    subtitle: Text(
                      '${item.body}\n${Formatters.relativeTime(item.timestamp)}',
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
