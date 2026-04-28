import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/themes.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/subscription_provider.dart';

/// Subscription plans screen with plan cards and active subscription status
class SubscriptionPlansScreen extends ConsumerWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subState = ref.watch(subscriptionControllerProvider);
    final controller = ref.read(subscriptionControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeSub = subState.activeSubscription;

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription Plans')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active subscription
            if (activeSub != null && activeSub.isActive) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: AppColors.successGradient,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_rounded, color: Colors.white, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          activeSub.plan.name,
                          style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: const Text('Active',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        _SubMetric(
                          label: 'Free Rides Left',
                          value: '${activeSub.freeRidesRemaining}',
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        _SubMetric(
                          label: 'Days Left',
                          value: '${activeSub.daysRemaining}',
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        _SubMetric(
                          label: 'Total Saved',
                          value: Formatters.currency(activeSub.totalSaved),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          controller.cancelSubscription();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Subscription cancelled'), backgroundColor: AppColors.warning),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                        ),
                        child: const Text('Cancel Subscription'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],

            // Available plans
            const Text('Choose a Plan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              'Unlock exclusive perks and save on every ride',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            ...subState.availablePlans.map((plan) {
              final isActive = activeSub?.plan.id == plan.id && activeSub!.isActive;
              final isPopular = plan.tier == SubscriptionTier.pro;
              return _PlanCard(
                plan: plan,
                isActive: isActive,
                isPopular: isPopular,
                isDark: isDark,
                isLoading: subState.isLoading,
                onSubscribe: isActive
                    ? null
                    : () async {
                        await controller.subscribeToPlan(plan);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Subscribed to ${plan.name}!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _SubMetric extends StatelessWidget {
  const _SubMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        Text(label,
          style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.7))),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isActive,
    required this.isPopular,
    required this.isDark,
    required this.isLoading,
    this.onSubscribe,
  });
  final SubscriptionPlan plan;
  final bool isActive;
  final bool isPopular;
  final bool isDark;
  final bool isLoading;
  final VoidCallback? onSubscribe;

  Color get _tierColor {
    switch (plan.tier) {
      case SubscriptionTier.basic: return AppColors.info;
      case SubscriptionTier.pro: return AppColors.primary;
      case SubscriptionTier.premium: return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: isPopular ? _tierColor : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isPopular ? 2 : 1,
        ),
        boxShadow: isPopular ? AppShadows.medium : AppShadows.small,
      ),
      child: Column(
        children: [
          if (isPopular)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: _tierColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl - 2)),
              ),
              child: const Text(
                '⭐ MOST POPULAR',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(plan.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _tierColor)),
                          Text(plan.description,
                            style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₹${plan.monthlyPrice.toInt()}',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _tierColor)),
                        Text('/month',
                          style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Perks
                ...plan.perks.map((perk) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, size: 16, color: _tierColor),
                      const SizedBox(width: 8),
                      Text(perk, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                )),
                const SizedBox(height: AppSpacing.md),

                SizedBox(
                  width: double.infinity,
                  child: isActive
                      ? OutlinedButton(
                          onPressed: null,
                          child: const Text('Currently Active'),
                        )
                      : ElevatedButton(
                          onPressed: isLoading ? null : onSubscribe,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _tierColor,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(isLoading ? 'Processing...' : 'Subscribe Now'),
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
