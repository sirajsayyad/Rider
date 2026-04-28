import 'package:flutter/material.dart';
import '../../../../../core/config/themes.dart';

class _BaseFeatureScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;
  final String actionText;

  const _BaseFeatureScreen({
    required this.title,
    required this.icon,
    required this.description,
    required this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 80, color: AppColors.primary),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                description,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(actionText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 1. Earn by driving
class EarnDrivingScreen extends StatelessWidget {
  const EarnDrivingScreen({super.key});
  @override
  Widget build(BuildContext context) => const _BaseFeatureScreen(
    title: 'Earn with Serene',
    icon: Icons.drive_eta_rounded,
    description: 'Join thousands of professional drivers. Drive on your own schedule and earn competitive rates.',
    actionText: 'Start Application Process',
  );
}

// 2. CO2 Saved
class CO2SavedScreen extends StatelessWidget {
  const CO2SavedScreen({super.key});
  @override
  Widget build(BuildContext context) => const _BaseFeatureScreen(
    title: 'Your Impact',
    icon: Icons.eco_rounded,
    description: 'You have saved 12.4 kg of CO2 by riding electric with Serene. Thank you for contributing to a greener planet!',
    actionText: 'Share Milestone',
  );
}

// 3. Send a Gift
class SendGiftScreen extends StatelessWidget {
  const SendGiftScreen({super.key});
  @override
  Widget build(BuildContext context) => const _BaseFeatureScreen(
    title: 'Gift a Ride',
    icon: Icons.card_giftcard_rounded,
    description: 'Send Serene credits to your friends and family instantly safely from your wallet.',
    actionText: 'Choose a Gift Card',
  );
}

// 4. Safety Check up
class SafetyCheckupScreen extends StatelessWidget {
  const SafetyCheckupScreen({super.key});
  @override
  Widget build(BuildContext context) => const _BaseFeatureScreen(
    title: 'Safety Check-Up',
    icon: Icons.shield_rounded,
    description: 'Review your trusted contacts, ride verification settings, and emergency details to stay safe.',
    actionText: 'Review Settings',
  );
}

// 5. Serene Insurance
class SereneInsuranceScreen extends StatelessWidget {
  const SereneInsuranceScreen({super.key});
  @override
  Widget build(BuildContext context) => const _BaseFeatureScreen(
    title: 'Serene Insurance',
    icon: Icons.health_and_safety_rounded,
    description: 'Every ride you take is covered by our comprehensive rider insurance policy. View your coverage details.',
    actionText: 'View Policy details',
  );
}

// 6. Family
class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key});
  @override
  Widget build(BuildContext context) => const _BaseFeatureScreen(
    title: 'Family Profile',
    icon: Icons.family_restroom_rounded,
    description: 'Manage a shared payment method, receive ride updates, and organize trips for your family members.',
    actionText: 'Invite Family Members',
  );
}

// 7. Serene for teens
class TeensScreen extends StatelessWidget {
  const TeensScreen({super.key});
  @override
  Widget build(BuildContext context) => const _BaseFeatureScreen(
    title: 'Serene for Teens',
    icon: Icons.child_care_rounded,
    description: 'Give your teenagers independence while you stay informed with real-time tracking and trusted drivers.',
    actionText: 'Set Up Teen Account',
  );
}

// 8. Business Profile Setup
class BusinessProfileSetupScreen extends StatelessWidget {
  const BusinessProfileSetupScreen({super.key});
  @override
  Widget build(BuildContext context) => const _BaseFeatureScreen(
    title: 'Business Profile',
    icon: Icons.add_business_rounded,
    description: 'Separate your work rides from personal ones. Automatically forward receipts to your company expense system.',
    actionText: 'Add Work Email',
  );
}

// 9. Manage Account
class ManageAccountScreen extends StatelessWidget {
  const ManageAccountScreen({super.key});
  @override
  Widget build(BuildContext context) => const _BaseFeatureScreen(
    title: 'Manage Account',
    icon: Icons.manage_accounts_rounded,
    description: 'Update your personal details, email, phone number, and password in one place.',
    actionText: 'Edit Details',
  );
}

// 10. Saved Group
class SavedGroupScreen extends StatelessWidget {
  const SavedGroupScreen({super.key});
  @override
  Widget build(BuildContext context) => const _BaseFeatureScreen(
    title: 'Saved Groups',
    icon: Icons.group_rounded,
    description: 'Organize your frequent co-riders into groups for quick split-fare and multi-stop rides.',
    actionText: 'Create a Group',
  );
}

// 11. Settings
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => const _BaseFeatureScreen(
    title: 'App Settings',
    icon: Icons.settings_rounded,
    description: 'Customize notifications, privacy preferences, app language, and accessibility options.',
    actionText: 'Update Preferences',
  );
}

// 12. Simple Mode
class SimpleModeScreen extends StatelessWidget {
  const SimpleModeScreen({super.key});
  @override
  Widget build(BuildContext context) => const _BaseFeatureScreen(
    title: 'Simple Mode',
    icon: Icons.smartphone_rounded,
    description: 'Switch to Simple Mode for a bold, high-contrast interface with larger text for an easier booking experience.',
    actionText: 'Enable Simple Mode',
  );
}

// 13. Legal
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});
  @override
  Widget build(BuildContext context) => const _BaseFeatureScreen(
    title: 'Legal & Privacy',
    icon: Icons.gavel_rounded,
    description: 'Read our Terms of Service, Privacy Policy, and open source licenses.',
    actionText: 'Read Terms of Service',
  );
}
