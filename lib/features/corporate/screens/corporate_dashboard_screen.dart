import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/themes.dart';
import '../../../core/utils/formatters.dart';
// import '../../../core/widgets/buttons/buttons.dart'; // Available if needed
import '../providers/corporate_provider.dart';

/// Corporate dashboard: company info, employees, budget, invoices
class CorporateDashboardScreen extends ConsumerWidget {
  const CorporateDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final corpState = ref.watch(corporateControllerProvider);
    final account = corpState.account;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (account == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Corporate Account')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Corporate Account'),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: const Icon(Icons.business, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(account.companyName,
                              style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                            Text('GST: ${account.gstNumber}',
                              style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Budget meter
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Monthly Budget',
                        style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8))),
                      Text('${(account.budgetUsagePercent * 100).toStringAsFixed(0)}% used',
                        style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: account.budgetUsagePercent,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation(
                        account.budgetUsagePercent > 0.9 ? AppColors.error : Colors.white),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Used: ${Formatters.currency(account.usedBudget)}',
                        style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600)),
                      Text('Remaining: ${Formatters.currency(account.remainingBudget)}',
                        style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Employees section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Employees (${account.employees.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                TextButton.icon(
                  onPressed: () => _showAddEmployeeDialog(context, ref),
                  icon: const Icon(Icons.person_add, size: 16),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...account.employees.map((emp) => _EmployeeTile(
              employee: emp,
              isDark: isDark,
              onRemove: () => ref.read(corporateControllerProvider.notifier).removeEmployee(emp.id),
            )),
            const SizedBox(height: AppSpacing.xl),

            // Invoices
            const Text('Invoices', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...account.invoices.map((inv) => _InvoiceTile(invoice: inv, isDark: isDark)),
          ],
        ),
      ),
    );
  }

  void _showAddEmployeeDialog(BuildContext context, WidgetRef ref) {
    final nameC = TextEditingController();
    final emailC = TextEditingController();
    final phoneC = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Employee'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 8),
            TextField(controller: emailC, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 8),
            TextField(controller: phoneC, decoration: const InputDecoration(labelText: 'Phone')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(corporateControllerProvider.notifier)
                  .addEmployee(nameC.text, emailC.text, phoneC.text);
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _EmployeeTile extends StatelessWidget {
  const _EmployeeTile({required this.employee, required this.isDark, this.onRemove});
  final CorporateEmployee employee;
  final bool isDark;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withOpacity(0.12),
            child: Text(employee.name[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(employee.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text('${employee.totalRides} rides • Spent: ${Formatters.currency(employee.monthlySpent)}',
                  style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.remove_circle_outline, size: 20, color: AppColors.error), onPressed: onRemove),
        ],
      ),
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  const _InvoiceTile({required this.invoice, required this.isDark});
  final CorporateInvoice invoice;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(Icons.receipt_long, color: AppColors.info, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invoice.month, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text('${invoice.totalRides} rides • ${invoice.totalEmployees} employees',
                  style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(Formatters.currency(invoice.totalAmount),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: invoice.isPaid ? AppColors.success.withOpacity(0.12) : AppColors.warning.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(invoice.isPaid ? 'Paid' : 'Pending',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: invoice.isPaid ? AppColors.success : AppColors.warning)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
