import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/themes.dart';
import '../../../../core/utils/formatters.dart';
import '../../ride/application/ride_controller.dart';
import '../../ride/domain/ride_models.dart';

class ReceiptScreen extends ConsumerWidget {
  const ReceiptScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(rideControllerProvider).activeTrip;
    final receipt = trip?.receipt;
    if (trip == null || receipt == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Receipt')),
        body: const Center(child: Text('Receipt not available yet.')),
      );
    }

    final isRefunded = receipt.paymentStatus == TransactionStatus.refunded;

    return Scaffold(
      appBar: AppBar(title: const Text('Ride Receipt')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: isRefunded ? AppColors.primaryGradient : AppColors.successGradient,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              children: [
                Icon(
                  isRefunded ? Icons.account_balance_wallet_outlined : Icons.check_circle_outline,
                  color: Colors.white,
                  size: 38,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  isRefunded ? 'Refund Issued' : 'Payment Successful',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.currency(receipt.total),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkCard
                  : AppColors.lightCard,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              children: [
                _row('Ride ID', receipt.rideId.substring(0, 8)),
                _row('Generated', Formatters.dateTime(receipt.generatedAt)),
                _row('Payment', receipt.paymentMethod.name.toUpperCase()),
                _row('Status', receipt.paymentStatus.name.toUpperCase()),
                const Divider(height: 26),
                _row('Base Fare', Formatters.currency(receipt.baseFare)),
                _row('Distance Fare', Formatters.currency(receipt.distanceFare)),
                _row('Service Fee', Formatters.currency(receipt.serviceFee)),
                _row('Tax', Formatters.currency(receipt.tax)),
                const Divider(height: 26),
                _row('Total', Formatters.currency(receipt.total), bold: true),
                const SizedBox(height: AppSpacing.sm),
                _row('Paid Amount', Formatters.currency(receipt.paidAmount)),
                _row('Refunded Amount', Formatters.currency(receipt.refundedAmount)),
                _row('Reward Points', '${receipt.rewardPointsEarned} pts'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String key, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(key)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.w700 : null)),
        ],
      ),
    );
  }
}
