import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/themes.dart';
import '../../../../core/utils/formatters.dart';
import '../../ride/application/ride_controller.dart';
import '../../ride/domain/ride_models.dart';

class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rideControllerProvider);
    final controller = ref.read(rideControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Payment Methods')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _PaymentTile(
            icon: Icons.money,
            label: 'Cash',
            selected: state.paymentMethod == RiderPaymentMethod.cash,
            onTap: () => controller.selectPaymentMethod(RiderPaymentMethod.cash),
          ),
          _PaymentTile(
            icon: Icons.account_balance_wallet_outlined,
            label: 'UPI',
            selected: state.paymentMethod == RiderPaymentMethod.upi,
            subtitle: 'user@upi',
            onTap: () => controller.selectPaymentMethod(RiderPaymentMethod.upi),
          ),
          _PaymentTile(
            icon: Icons.credit_card_outlined,
            label: 'Card',
            selected: state.paymentMethod == RiderPaymentMethod.card,
            subtitle: '**** **** **** 2245',
            onTap: () => controller.selectPaymentMethod(RiderPaymentMethod.card),
          ),
          _PaymentTile(
            icon: Icons.savings_outlined,
            label: 'Wallet',
            selected: state.paymentMethod == RiderPaymentMethod.wallet,
            subtitle: 'Balance ${Formatters.currency(state.walletBalance)}',
            onTap: () => controller.selectPaymentMethod(RiderPaymentMethod.wallet),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Recent transactions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          if (state.transactions.isEmpty)
            const _EmptyTransactions()
          else
            ...state.transactions.take(6).map(
                  (tx) => _TransactionTile(record: tx),
                ),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withOpacity(0.11)
            : (isDark ? AppColors.darkCard : AppColors.lightCard),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: selected ? AppColors.primary : Colors.transparent),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: selected
            ? const Icon(Icons.check_circle, color: AppColors.primary)
            : const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.record});
  final TransactionRecord record;

  @override
  Widget build(BuildContext context) {
    final color = switch (record.status) {
      TransactionStatus.success => AppColors.success,
      TransactionStatus.failed => AppColors.error,
      TransactionStatus.refunded => AppColors.info,
      TransactionStatus.pending => AppColors.warning,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkCard
            : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(Icons.receipt_long_outlined, color: color),
        ),
        title: Text(record.title),
        subtitle: Text('${record.subtitle}\n${Formatters.dateTime(record.createdAt)}'),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(Formatters.currency(record.amount)),
            Text(
              record.status.name.toUpperCase(),
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkCard
            : AppColors.lightCard,
      ),
      child: const Text(
        'Payments, refunds, and wallet credits will appear here.',
      ),
    );
  }
}
