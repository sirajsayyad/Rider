import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/themes.dart';
import '../providers/lost_found_provider.dart';
import 'report_item_screen.dart';

/// Lost & Found screen with item list, status tracking, and report button
class LostFoundScreen extends ConsumerWidget {
  const LostFoundScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lfState = ref.watch(lostFoundControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lost & Found'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active Reports'),
              Tab(text: 'Resolved'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Active
            _ItemList(
              items: lfState.activeItems,
              isDark: isDark,
              emptyMessage: 'No active reports',
              emptyIcon: Icons.search_off_rounded,
              ref: ref,
            ),
            // Resolved
            _ItemList(
              items: lfState.resolvedItems,
              isDark: isDark,
              emptyMessage: 'No resolved items yet',
              emptyIcon: Icons.inventory_2_outlined,
              ref: ref,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReportItemScreen()),
            );
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('Report Lost Item'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}

class _ItemList extends StatelessWidget {
  const _ItemList({
    required this.items,
    required this.isDark,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.ref,
  });
  final List<LostFoundItem> items;
  final bool isDark;
  final String emptyMessage;
  final IconData emptyIcon;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(emptyIcon, size: 48, color: AppColors.lightTextTertiary),
            const SizedBox(height: 12),
            Text(emptyMessage, style: const TextStyle(fontSize: 14, color: AppColors.lightTextTertiary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _LostFoundTile(item: item, isDark: isDark, ref: ref);
      },
    );
  }
}

class _LostFoundTile extends StatelessWidget {
  const _LostFoundTile({required this.item, required this.isDark, required this.ref});
  final LostFoundItem item;
  final bool isDark;
  final WidgetRef ref;

  Color _statusColor(LostFoundStatus status) {
    switch (status) {
      case LostFoundStatus.reported: return AppColors.warning;
      case LostFoundStatus.searching: return AppColors.info;
      case LostFoundStatus.matched: return AppColors.primary;
      case LostFoundStatus.contactInitiated: return AppColors.secondary;
      case LostFoundStatus.returned: return AppColors.success;
      case LostFoundStatus.closed: return AppColors.lightTextTertiary;
    }
  }

  String _statusLabel(LostFoundStatus status) {
    switch (status) {
      case LostFoundStatus.reported: return 'Reported';
      case LostFoundStatus.searching: return 'Searching';
      case LostFoundStatus.matched: return 'Found';
      case LostFoundStatus.contactInitiated: return 'In Contact';
      case LostFoundStatus.returned: return 'Returned';
      case LostFoundStatus.closed: return 'Closed';
    }
  }

  IconData _categoryIcon(ItemCategory category) {
    switch (category) {
      case ItemCategory.phone: return Icons.phone_android;
      case ItemCategory.wallet: return Icons.account_balance_wallet;
      case ItemCategory.bag: return Icons.shopping_bag;
      case ItemCategory.keys: return Icons.key;
      case ItemCategory.clothing: return Icons.checkroom;
      case ItemCategory.documents: return Icons.description;
      case ItemCategory.electronics: return Icons.devices;
      case ItemCategory.other: return Icons.inventory_2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.small,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: _statusColor(item.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(_categoryIcon(item.category), color: _statusColor(item.status), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.description, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(
                        item.rideId != null ? 'Ride #${item.rideId} • ${item.rideDate ?? ''}' : 'No ride linked',
                        style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(item.status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(_statusLabel(item.status),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _statusColor(item.status))),
                ),
              ],
            ),
          ),

          // Timeline
          if (item.updates.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: item.updates.map((update) {
                  return _TimelineStep(
                    update: update,
                    isDark: isDark,
                    isLast: update == item.updates.last,
                    color: _statusColor(update.status),
                  );
                }).toList(),
              ),
            ),
          ],

          // Actions
          if (item.status == LostFoundStatus.matched)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => ref.read(lostFoundControllerProvider.notifier).closeReport(item.id),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Close', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => ref.read(lostFoundControllerProvider.notifier).markAsReturned(item.id),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Mark Returned', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({required this.update, required this.isDark, required this.isLast, required this.color});
  final LostFoundUpdate update;
  final bool isDark;
  final bool isLast;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            if (!isLast)
              Container(width: 2, height: 24, color: color.withOpacity(0.3)),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(update.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    Text(DateFormat.MMMd().add_jm().format(update.timestamp),
                      style: TextStyle(fontSize: 9, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary)),
                  ],
                ),
                Text(update.description,
                  style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
