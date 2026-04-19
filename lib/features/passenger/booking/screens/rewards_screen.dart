import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/themes.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/app_models.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../ride/application/ride_controller.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ride = ref.watch(rideControllerProvider);
    final rewards = ref.watch(availableRewardsProvider);
    final promos = ref.watch(appControllerProvider).promoCodes;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Gradient header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      const Icon(
                        Icons.stars_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AnimatedCount(
                        count: ride.rewardPoints,
                        suffix: ' pts',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'Loyalty Points',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              title: const Text('Rewards'),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Wallet balance card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    gradient: AppColors.successGradient,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Wallet Balance',
                              style:
                                  TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            Text(
                              Formatters.currency(ride.walletBalance),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: ride.rewardPoints >= 100
                            ? () {
                                ref
                                    .read(rideControllerProvider.notifier)
                                    .redeemRewardPoints();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.success,
                        ),
                        child: const Text('Redeem'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // How it works
                _HowItWorksCard(isDark: isDark),

                const SizedBox(height: AppSpacing.lg),

                // Available rewards
                const SectionHeader(
                  title: 'Available Rewards',
                  icon: Icons.card_giftcard_rounded,
                ),
                const SizedBox(height: AppSpacing.sm),

                ...rewards.map(
                  (reward) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _RewardCard(
                      reward: reward,
                      currentPoints: ride.rewardPoints,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Promo codes
                const SectionHeader(
                  title: 'Promo Codes',
                  icon: Icons.local_offer_rounded,
                ),
                const SizedBox(height: AppSpacing.sm),

                ...promos.map(
                  (promo) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _PromoCard(promo: promo),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Earning history
                const SectionHeader(
                  title: 'Recent Earnings',
                  icon: Icons.history_rounded,
                ),
                const SizedBox(height: AppSpacing.sm),

                if (ride.compensationHistory.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Center(
                      child: Text('Complete rides to earn reward points!'),
                    ),
                  )
                else
                  ...ride.compensationHistory.take(5).map(
                        (comp) => Container(
                          margin:
                              const EdgeInsets.only(bottom: AppSpacing.sm),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkCard
                                : AppColors.lightCard,
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor:
                                    AppColors.success.withOpacity(0.12),
                                radius: 20,
                                child: const Icon(
                                  Icons.add_circle_outline,
                                  color: AppColors.success,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      comp.reason,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      Formatters.relativeTime(comp.createdAt),
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '+${Formatters.currency(comp.amount)}',
                                style: const TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                const SizedBox(height: AppSpacing.xxl),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  final bool isDark;
  const _HowItWorksCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How Loyalty Works',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: AppSpacing.md),
          _step(Icons.local_taxi_rounded, 'Complete Rides',
              'Earn points for every ride you take.'),
          _step(Icons.stars_rounded, 'Collect Points',
              '1 point for every Rs 18 spent on rides.'),
          _step(Icons.card_giftcard_rounded, 'Redeem Rewards',
              'Use points for discounts, free rides, and more.'),
        ],
      ),
    );
  }

  Widget _step(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final LoyaltyReward reward;
  final int currentPoints;

  const _RewardCard({required this.reward, required this.currentPoints});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canRedeem = currentPoints >= reward.pointsRequired;
    final progress = (currentPoints / reward.pointsRequired).clamp(0.0, 1.0);

    final iconData = switch (reward.type) {
      RewardType.discount => Icons.percent_rounded,
      RewardType.freeRide => Icons.local_taxi_rounded,
      RewardType.cashback => Icons.payments_rounded,
      RewardType.upgrade => Icons.upgrade_rounded,
    };

    final accentColor = switch (reward.type) {
      RewardType.discount => AppColors.accent,
      RewardType.freeRide => AppColors.success,
      RewardType.cashback => AppColors.info,
      RewardType.upgrade => AppColors.primary,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: canRedeem
            ? Border.all(color: accentColor.withOpacity(0.4))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(iconData, color: accentColor),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reward.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      reward.description,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: accentColor.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation(accentColor),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                '${reward.pointsRequired} pts',
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  final PromoCode promo;
  const _PromoCard({required this.promo});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.3),
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              promo.code,
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  promo.description,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Max discount: ${Formatters.currency(promo.maxDiscount)} • Expires ${Formatters.date(promo.expiresAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (promo.isValid)
            const Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.success,
            )
          else
            const Icon(
              Icons.cancel_outlined,
              color: AppColors.error,
            ),
        ],
      ),
    );
  }
}
