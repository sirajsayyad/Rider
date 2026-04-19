import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/themes.dart';
import '../../../../core/utils/formatters.dart';
import '../../ride/application/ride_controller.dart';
import '../../ride/domain/ride_models.dart';

class BillingScreen extends ConsumerWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rideControllerProvider);
    final trip = state.activeTrip;
    final receipt = trip?.receipt;

    return Scaffold(
      appBar: AppBar(title: const Text('Billing')),
      body: trip == null
          ? const Center(child: Text('No ride details available.'))
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
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
                      _row('Ride Fare', Formatters.currency(trip.fare)),
                      const SizedBox(height: AppSpacing.sm),
                      _row('Payment Method', trip.paymentMethod.name.toUpperCase()),
                      const SizedBox(height: AppSpacing.sm),
                      _row('Base Fare', Formatters.currency(trip.fareBreakdown.baseFare)),
                      _row('Distance Fare', Formatters.currency(trip.fareBreakdown.distanceFare)),
                      _row('Time Fare', Formatters.currency(trip.fareBreakdown.timeFare)),
                      _row('Surge', Formatters.currency(trip.fareBreakdown.surgeAmount)),
                      _row('Platform Fee', Formatters.currency(trip.fareBreakdown.platformFee)),
                      _row('Taxes', Formatters.currency(trip.fareBreakdown.tax)),
                      const Divider(height: 24),
                      _row('Total', Formatters.currency(trip.fareBreakdown.total), bold: true),
                      if (trip.fareLock != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _row('Fare Lock', Formatters.currency(trip.fareLock!.lockedFare)),
                      ],
                    ],
                  ),
                ),
                if (trip.compensations.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Compensation',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ...trip.compensations.map(
                          (comp) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _row(comp.reason, Formatters.currency(comp.amount)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (receipt != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _PaymentStatusCard(receipt: receipt),
                ],
                if (state.transactions.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text('Transaction history', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  ...state.transactions.take(5).map(
                        (item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.title),
                          subtitle: Text(Formatters.dateTime(item.createdAt)),
                          trailing: Text(
                            '${Formatters.currency(item.amount)} • ${item.status.name}',
                          ),
                        ),
                      ),
                ],
              ],
            ),
    );
  }

  Widget _row(String title, String value, {bool bold = false}) {
    return Row(
      children: [
        Expanded(child: Text(title)),
        Text(
          value,
          style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500),
        ),
      ],
    );
  }
}

class _PaymentStatusCard extends StatelessWidget {
  const _PaymentStatusCard({required this.receipt});
  final RideReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final color = switch (receipt.paymentStatus) {
      TransactionStatus.success => AppColors.success,
      TransactionStatus.failed => AppColors.error,
      TransactionStatus.refunded => AppColors.info,
      TransactionStatus.pending => AppColors.warning,
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment status', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          Text(receipt.paymentStatus.name.toUpperCase()),
          if (receipt.refundedAmount > 0)
            Text('Refunded instantly: ${Formatters.currency(receipt.refundedAmount)}'),
          if (receipt.paidAmount > 0)
            Text('Paid: ${Formatters.currency(receipt.paidAmount)}'),
        ],
      ),
    );
  }
}
