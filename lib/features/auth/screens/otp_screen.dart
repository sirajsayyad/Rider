import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../core/config/routes.dart';
import '../../../core/config/themes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/buttons/buttons.dart';

/// OTP verification screen
class OtpScreen extends ConsumerStatefulWidget {
  final String phoneNumber;

  const OtpScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen>
    with SingleTickerProviderStateMixin {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  static const int _resendDuration = 30;
  int _resendTimer = _resendDuration;
  Timer? _timer;
  bool _canResend = false;
  double _resendProgress = 1.0;
  late final AnimationController _backgroundController;

  @override
  void initState() {
    super.initState();
    _otpController.addListener(_onOtpChanged);
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _startResendTimer();
  }

  void _onOtpChanged() => setState(() {});

  void _startResendTimer() {
    _timer?.cancel();
    setState(() {
      _resendTimer = _resendDuration;
      _canResend = false;
      _resendProgress = 1.0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 1) {
        setState(() {
          _resendTimer--;
          _resendProgress = _resendTimer / _resendDuration;
        });
      } else {
        timer.cancel();
        setState(() {
          _resendTimer = 0;
          _resendProgress = 0;
          _canResend = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _otpController.removeListener(_onOtpChanged);
    _timer?.cancel();
    _backgroundController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6) return;

    setState(() => _isLoading = true);

    final success = await ref.read(authServiceProvider.notifier).verifyOtp(
      widget.phoneNumber,
      _otpController.text,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      // Check if user needs to select role
      final user = ref.read(currentUserProvider);
      if (user?.role == 'driver') {
        context.go(Routes.driverHome);
      } else if (user?.role == 'admin') {
        context.go(Routes.adminDashboard);
      } else {
        context.go(Routes.passengerHome);
      }
    } else if (mounted) {
      _otpController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid OTP. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    setState(() => _isLoading = true);

    final success = await ref.read(authServiceProvider.notifier).sendOtp(
      widget.phoneNumber,
    );

    setState(() => _isLoading = false);

    if (success) {
      _startResendTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isOtpComplete = _otpController.text.length == 6;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          _AnimatedOtpBackground(animation: _backgroundController),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    (isDark
                            ? AppColors.darkBackground
                            : AppColors.lightBackground)
                        .withOpacity(0.85),
                    isDark
                        ? AppColors.darkBackground
                        : AppColors.lightBackground,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      color: isDark
                          ? AppColors.darkSurface.withOpacity(0.85)
                          : Colors.white.withOpacity(0.9),
                      boxShadow: AppShadows.large,
                      border: Border.all(
                        color: (isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder)
                            .withOpacity(0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.primaryGradient,
                              ),
                              child: const Icon(
                                Icons.lock,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Secure Verification',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkText
                                    : AppColors.lightText,
                              ),
                            ),
                            const Spacer(),
                            const _InstantBadge(),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Verify Phone',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkText
                                : AppColors.lightText,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text.rich(
                          TextSpan(
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                            children: [
                              const TextSpan(
                                  text: 'Enter the 6-digit code sent to '),
                              TextSpan(
                                text: '+91 ${widget.phoneNumber}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.darkText
                                      : AppColors.lightText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.lg,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      color: isDark
                          ? AppColors.darkSurface.withOpacity(0.9)
                          : AppColors.lightSurface,
                      boxShadow: AppShadows.medium,
                    ),
                    child: PinCodeTextField(
                      appContext: context,
                      length: 6,
                      controller: _otpController,
                      animationType: AnimationType.fade,
                      keyboardType: TextInputType.number,
                      autoFocus: true,
                      cursorColor: AppColors.primary,
                      animationDuration: const Duration(milliseconds: 200),
                      enableActiveFill: true,
                      onCompleted: (_) => _verifyOtp(),
                      onChanged: (_) {},
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        fieldHeight: 56,
                        fieldWidth: 48,
                        activeFillColor: isDark
                            ? AppColors.darkCard
                            : AppColors.lightSurface,
                        inactiveFillColor: isDark
                            ? AppColors.darkCard
                            : AppColors.lightSurface,
                        selectedFillColor: isDark
                            ? AppColors.darkCard
                            : AppColors.lightSurface,
                        activeColor: AppColors.primary,
                        inactiveColor: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                        selectedColor: AppColors.primary,
                      ),
                      textStyle: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkText
                            : AppColors.lightText,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  Center(
                    child: _ResendCountdownBadge(
                      canResend: _canResend,
                      secondsLeft: _resendTimer,
                      progress: _resendProgress,
                      onResend: _resendOtp,
                    ),
                  ),

                  const Spacer(),

                  PrimaryButton(
                    text: 'Verify',
                    onPressed: isOtpComplete && !_isLoading ? _verifyOtp : null,
                    isLoading: _isLoading,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: AppColors.info.withOpacity(0.3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.info,
                          size: 20,
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Demo OTP: 123456',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedOtpBackground extends StatelessWidget {
  final Animation<double> animation;

  const _AnimatedOtpBackground({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = animation.value;
        final colorA = Color.lerp(AppColors.primary, AppColors.secondary, t)!;
        final colorB =
            Color.lerp(AppColors.primaryDark, AppColors.accent, 1 - t)!;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colorA, colorB],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -60 + (t * 20),
                left: -40,
                child: _BlurredOrb(
                  diameter: 180,
                  color: colorB.withOpacity(0.35),
                ),
              ),
              Positioned(
                bottom: -40,
                right: -20,
                child: _BlurredOrb(
                  diameter: 200,
                  color: colorA.withOpacity(0.25),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BlurredOrb extends StatelessWidget {
  final double diameter;
  final Color color;

  const _BlurredOrb({required this.diameter, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 80,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }
}

class _ResendCountdownBadge extends StatelessWidget {
  final bool canResend;
  final int secondsLeft;
  final double progress;
  final VoidCallback onResend;

  const _ResendCountdownBadge({
    required this.canResend,
    required this.secondsLeft,
    required this.progress,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: canResend
          ? ElevatedButton.icon(
              key: const ValueKey('resend_btn'),
              onPressed: onResend,
              icon: const Icon(Icons.refresh),
              label: const Text('Resend OTP'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            )
          : Container(
              key: const ValueKey('resend_timer'),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.full),
                color: Colors.white.withOpacity(0.08),
              ),
              child: SizedBox(
                height: 64,
                width: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ShaderMask(
                      shaderCallback: (rect) {
                        return AppColors.primaryGradient
                            .createShader(rect);
                      },
                      child: CircularProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        strokeWidth: 4,
                        backgroundColor: Colors.white24,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${secondsLeft}s',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'Resend',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _InstantBadge extends StatelessWidget {
  const _InstantBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.full)),
        color: Color(0x1A6366F1),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bolt,
            size: 14,
            color: AppColors.primary,
          ),
          SizedBox(width: 4),
          Text(
            'Instant',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
