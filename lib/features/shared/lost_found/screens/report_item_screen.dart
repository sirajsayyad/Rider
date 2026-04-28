import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/themes.dart';
import '../../../../core/widgets/buttons/buttons.dart';
import '../providers/lost_found_provider.dart';

/// Report lost/found item form screen
class ReportItemScreen extends ConsumerStatefulWidget {
  const ReportItemScreen({super.key});

  @override
  ConsumerState<ReportItemScreen> createState() => _ReportItemScreenState();
}

class _ReportItemScreenState extends ConsumerState<ReportItemScreen> {
  final _descController = TextEditingController();
  final _rideIdController = TextEditingController();
  ItemCategory _selectedCategory = ItemCategory.other;

  static const _categories = [
    {'category': ItemCategory.phone, 'label': 'Phone', 'icon': Icons.phone_android},
    {'category': ItemCategory.wallet, 'label': 'Wallet', 'icon': Icons.account_balance_wallet},
    {'category': ItemCategory.bag, 'label': 'Bag', 'icon': Icons.shopping_bag},
    {'category': ItemCategory.keys, 'label': 'Keys', 'icon': Icons.key},
    {'category': ItemCategory.clothing, 'label': 'Clothing', 'icon': Icons.checkroom},
    {'category': ItemCategory.documents, 'label': 'Documents', 'icon': Icons.description},
    {'category': ItemCategory.electronics, 'label': 'Electronics', 'icon': Icons.devices},
    {'category': ItemCategory.other, 'label': 'Other', 'icon': Icons.inventory_2},
  ];

  @override
  void dispose() {
    _descController.dispose();
    _rideIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(lostFoundControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Report Lost Item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.info.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: AppColors.info.withOpacity(0.7)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'We\'ll contact your driver immediately and help recover your item.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Category selector
            const Text('What did you lose?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final category = cat['category'] as ItemCategory;
                final label = cat['label'] as String;
                final icon = cat['icon'] as IconData;
                final isSelected = _selectedCategory == category;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.primary),
                      const SizedBox(width: 4),
                      Text(label),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedCategory = category),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : null,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Description
            const Text('Description', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 3,
              maxLength: 300,
              decoration: InputDecoration(
                hintText: 'Describe your lost item (color, brand, etc.)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Ride ID (optional)
            const Text('Ride Reference (optional)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: _rideIdController,
              decoration: InputDecoration(
                hintText: 'e.g., ride_089',
                prefixIcon: const Icon(Icons.directions_car, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Submit
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                text: isLoading ? 'Reporting...' : 'Submit Report',
                icon: Icons.send_rounded,
                onPressed: isLoading || _descController.text.trim().isEmpty
                    ? null
                    : () async {
                        final item = await ref
                            .read(lostFoundControllerProvider.notifier)
                            .reportLostItem(
                              description: _descController.text.trim(),
                              category: _selectedCategory,
                              rideId: _rideIdController.text.isNotEmpty
                                  ? _rideIdController.text.trim()
                                  : null,
                            );
                        if (item != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Report submitted! We\'ll contact the driver.'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          Navigator.of(context).pop();
                        }
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
