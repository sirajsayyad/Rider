import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/themes.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/cards/cards.dart';

/// Driver earnings screen with analytics
class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Demo data
    const totalEarnings = 15680.0;
    const todayEarnings = 1256.0;
    const weeklyEarnings = 8450.0;

    final dailyEarnings = [
      {'day': 'Mon', 'amount': 1200.0},
      {'day': 'Tue', 'amount': 1580.0},
      {'day': 'Wed', 'amount': 980.0},
      {'day': 'Thu', 'amount': 1450.0},
      {'day': 'Fri', 'amount': 1780.0},
      {'day': 'Sat', 'amount': 2100.0},
      {'day': 'Sun', 'amount': 1256.0},
    ];

    final maxEarning = dailyEarnings
        .map((e) => e['amount'] as double)
        .reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {},
            tooltip: 'Download Report',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total earnings card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: AppShadows.glow,
              ),
              child: Column(
                children: [
                  const Text(
                    'Total Earnings',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    Formatters.currency(totalEarnings),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _EarningsStat(
                        label: 'Today',
                        value: Formatters.currency(todayEarnings),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.white24,
                      ),
                      _EarningsStat(
                        label: 'This Week',
                        value: Formatters.currency(weeklyEarnings),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Stats row
            const Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Total Trips',
                    value: '156',
                    icon: Icons.directions_car,
                    iconColor: AppColors.primary,
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: StatCard(
                    title: 'Online Hours',
                    value: '42.5h',
                    icon: Icons.access_time,
                    iconColor: AppColors.secondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // Weekly chart
            Text(
              'This Week',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadows.small,
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 180,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: dailyEarnings.map((data) {
                        final amount = data['amount'] as double;
                        final heightPercent = amount / maxEarning;
                        final isToday = data['day'] == 'Sun';

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  Formatters.compactNumber(amount),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                    color: isToday
                                        ? AppColors.primary
                                        : (isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  height: 120 * heightPercent,
                                  decoration: BoxDecoration(
                                    gradient: isToday
                                        ? AppColors.primaryGradient
                                        : null,
                                    color: isToday
                                        ? null
                                        : (isDark
                                            ? AppColors.darkBorder
                                            : AppColors.lightBorder),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  data['day'] as String,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isToday
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isToday
                                        ? AppColors.primary
                                        : (isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Recent transactions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),

            const _TransactionItem(
              type: 'ride',
              title: 'Ride Completed',
              subtitle: 'CP to India Gate',
              amount: 156.0,
              time: 'Today, 2:30 PM',
            ),
            const _TransactionItem(
              type: 'ride',
              title: 'Ride Completed',
              subtitle: 'Nehru Place to Saket',
              amount: 234.0,
              time: 'Today, 11:45 AM',
            ),
            const _TransactionItem(
              type: 'bonus',
              title: 'Peak Hour Bonus',
              subtitle: '10 rides completed',
              amount: 100.0,
              time: 'Yesterday',
            ),
            const _TransactionItem(
              type: 'withdrawal',
              title: 'Withdrawal',
              subtitle: 'Bank Transfer',
              amount: -5000.0,
              time: 'Jan 28',
            ),
          ],
        ),
      ),
    );
  }
}

class _EarningsStat extends StatelessWidget {
  final String label;
  final String value;

  const _EarningsStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final String type;
  final String title;
  final String subtitle;
  final double amount;
  final String time;

  const _TransactionItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.time,
  });

  IconData get _icon {
    switch (type) {
      case 'ride':
        return Icons.directions_car;
      case 'bonus':
        return Icons.card_giftcard;
      case 'withdrawal':
        return Icons.account_balance;
      default:
        return Icons.receipt;
    }
  }

  Color get _iconColor {
    switch (type) {
      case 'ride':
        return AppColors.primary;
      case 'bonus':
        return AppColors.warning;
      case 'withdrawal':
        return AppColors.info;
      default:
        return AppColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPositive = amount >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(_icon, color: _iconColor, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPositive ? '+' : ''}${Formatters.currency(amount)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isPositive ? AppColors.success : AppColors.error,
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
