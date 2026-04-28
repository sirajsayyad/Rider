import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/routes.dart';
import '../../../../core/config/themes.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/widgets/buttons/buttons.dart';

class PassengerProfileScreen extends ConsumerWidget {
  const PassengerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Account', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Rider',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : AppColors.lightCard,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            boxShadow: AppShadows.small,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 18, color: AppColors.warning),
                              const SizedBox(width: 4),
                              Text(
                                '4.95',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkText : AppColors.lightText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                    child: Text(
                      (user?.name ?? 'R')[0].toUpperCase(),
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Top Action Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: _TopActionCard(
                      icon: Icons.help_outline_rounded,
                      title: 'Help',
                      onTap: () => context.push(Routes.sos),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _TopActionCard(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Wallet',
                      onTap: () => context.push(Routes.paymentMethods),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _TopActionCard(
                      icon: Icons.history_rounded,
                      title: 'Activity',
                      onTap: () => context.push(Routes.tripHistory),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Info Cards (Horizontal list)
            SizedBox(
              height: 140,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                children: [
                  _PromoCard(
                    title: 'You have multiple promos',
                    subtitle: 'Apply them to save on your next rides.',
                    imageIcon: Icons.local_offer_rounded,
                    color: AppColors.primary,
                    onTap: () => context.push(Routes.rewards),
                  ),
                  _PromoCard(
                    title: 'Earn by driving or delivering',
                    subtitle: 'Join Serene as a professional partner.',
                    imageIcon: Icons.drive_eta_rounded,
                    color: AppColors.info,
                    onTap: () => context.push(Routes.profileEarnDriving),
                  ),
                  _PromoCard(
                    title: 'Estimated CO2 saved',
                    subtitle: '12.4 kg saved by riding electric.',
                    imageIcon: Icons.eco_rounded,
                    color: AppColors.success,
                    onTap: () => context.push(Routes.profileCo2Saved),
                  ),
                  _PromoCard(
                    title: 'Send a gift',
                    subtitle: 'Gift rides to your loved ones.',
                    imageIcon: Icons.card_giftcard_rounded,
                    color: AppColors.accent,
                    onTap: () => context.push(Routes.profileSendGift),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
            Divider(thickness: 8, color: isDark ? Colors.black26 : Colors.black.withOpacity(0.04)),

            // Services & features list
            _buildListTile(context, 'Inbox', Icons.inbox_rounded, onTap: () => context.push(Routes.notifications)),

            Divider(thickness: 8, color: isDark ? Colors.black26 : Colors.black.withOpacity(0.04)),

            const _SectionHeader(title: 'Safety'),
            _buildListTile(context, 'Safety check up', Icons.shield_rounded, onTap: () => context.push(Routes.profileSafetyCheckup)),
            _buildListTile(context, 'Serene Insurance', Icons.health_and_safety_rounded, onTap: () => context.push(Routes.profileInsurance)),

            const _SectionHeader(title: 'Family & Teens'),
            _buildListTile(context, 'Family', Icons.family_restroom_rounded, onTap: () => context.push(Routes.profileFamily)),
            _buildListTile(context, 'Serene for teens', Icons.child_care_rounded, onTap: () => context.push(Routes.profileTeens)),

            const _SectionHeader(title: 'Business'),
            _buildListTile(context, 'Account for business', Icons.business_center_rounded, onTap: () => context.push(Routes.corporateDashboard)),
            _buildListTile(context, 'Set up your business profile', Icons.add_business_rounded, onTap: () => context.push(Routes.profileBusinessSetup)),

            const _SectionHeader(title: 'Account Settings'),
            _buildListTile(context, 'Manage account', Icons.manage_accounts_rounded, onTap: () => context.push(Routes.profileManageAccount)),
            _buildListTile(context, 'Saved group', Icons.group_rounded, onTap: () => context.push(Routes.profileSavedGroup)),
            _buildListTile(context, 'Settings', Icons.settings_rounded, onTap: () => context.push(Routes.profileSettings)),
            _buildListTile(context, 'Simple mode', Icons.smartphone_rounded, onTap: () => context.push(Routes.profileSimpleMode)),
            _buildListTile(context, 'Legal', Icons.gavel_rounded, onTap: () => context.push(Routes.profileLegal)),

            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: SecondaryButton(
                text: 'Logout',
                icon: Icons.logout_rounded,
                onPressed: () => _showLogoutConfirmation(context, ref),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out of your Serene account?'),
        actionsPadding: const EdgeInsets.only(right: AppSpacing.md, bottom: AppSpacing.md),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authServiceProvider.notifier).logout();
              if (context.mounted) {
                // Routinely ensure we completely clear to login screen
                context.go(Routes.login);
              }
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(BuildContext context, String title, IconData icon, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, size: 28),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 22, color: Colors.grey),
      onTap: onTap ?? () {},
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
    );
  }
}

class _TopActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _TopActionCard({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppShadows.small,
        ),
        child: Column(
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: AppSpacing.sm),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData imageIcon;
  final Color color;
  final VoidCallback onTap;

  const _PromoCard({
    required this.title,
    required this.subtitle,
    required this.imageIcon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        margin: const EdgeInsets.only(right: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodySmall?.color),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(imageIcon, size: 32, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.lg,
        bottom: AppSpacing.sm,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
