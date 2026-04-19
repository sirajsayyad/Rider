import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/routes.dart';
import '../../../core/config/themes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/buttons/buttons.dart';
import '../../../core/widgets/inputs/inputs.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _usePhone = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    final id = _usePhone ? _phoneController.text.trim() : _emailController.text.trim();

    setState(() => _isLoading = true);
    final ok = await ref.read(authServiceProvider.notifier).sendOtp(id);
    setState(() => _isLoading = false);
    if (!mounted) return;

    if (ok) {
      context.push(Routes.otp, extra: id);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send OTP')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xl),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: const Icon(Icons.local_taxi_rounded, color: Colors.white, size: 36),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text('Sign in', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 6),
                      Text(
                        'Phone or email verification',
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(value: true, label: Text('Phone')),
                    ButtonSegment<bool>(value: false, label: Text('Email')),
                  ],
                  selected: {_usePhone},
                  onSelectionChanged: (set) => setState(() => _usePhone = set.first),
                ),
                const SizedBox(height: AppSpacing.md),
                if (_usePhone)
                  PhoneInput(
                    controller: _phoneController,
                    validator: Validators.phone,
                    autofocus: true,
                  )
                else
                  CustomTextField(
                    label: 'Email',
                    hint: 'you@example.com',
                    controller: _emailController,
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) return 'Email is required';
                      return Validators.email(value);
                    },
                    keyboardType: TextInputType.emailAddress,
                    autofocus: true,
                  ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  text: 'Send OTP',
                  icon: Icons.arrow_forward_rounded,
                  isLoading: _isLoading,
                  onPressed: _sendOtp,
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    color: AppColors.info.withOpacity(0.12),
                  ),
                  child: const Text(
                    'Demo OTP: 123456',
                    style: TextStyle(color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
