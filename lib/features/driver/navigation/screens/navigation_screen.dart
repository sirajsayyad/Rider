import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../core/config/themes.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/buttons/buttons.dart';

/// Driver navigation screen with turn-by-turn guidance
class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key, this.rideId});

  final String? rideId;

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  // Simulated navigation state
  double _distanceRemainingKm = 12.4;
  int _etaMinutes = 28;
  int _currentStepIndex = 0;
  bool _isNavigating = true;
  String _currentSpeed = '32 km/h';

  final List<_NavigationStep> _steps = const [
    _NavigationStep(
      instruction: 'Head north on MG Road',
      distance: '500 m',
      icon: Icons.arrow_upward_rounded,
      road: 'MG Road',
    ),
    _NavigationStep(
      instruction: 'Turn right onto Ring Road',
      distance: '2.1 km',
      icon: Icons.turn_right_rounded,
      road: 'Ring Road',
    ),
    _NavigationStep(
      instruction: 'Continue on NH-48',
      distance: '6.8 km',
      icon: Icons.straight_rounded,
      road: 'NH-48',
    ),
    _NavigationStep(
      instruction: 'Take exit towards Sector 15',
      distance: '1.2 km',
      icon: Icons.fork_right_rounded,
      road: 'Exit 12',
    ),
    _NavigationStep(
      instruction: 'Turn left onto Main Street',
      distance: '800 m',
      icon: Icons.turn_left_rounded,
      road: 'Main Street',
    ),
    _NavigationStep(
      instruction: 'Arrive at destination',
      distance: '100 m',
      icon: Icons.flag_rounded,
      road: 'Drop-off Point',
    ),
  ];

  Timer? _simulationTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Simulate navigation progress
    _simulationTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _advanceNavigation(),
    );
  }

  void _advanceNavigation() {
    if (!_isNavigating || !mounted) return;
    setState(() {
      _distanceRemainingKm = (_distanceRemainingKm - 0.8).clamp(0.0, 100.0);
      _etaMinutes = (_etaMinutes - 2).clamp(0, 120);
      _currentSpeed = '${(25 + (15 * (_currentStepIndex % 3))).toInt()} km/h';
      if (_currentStepIndex < _steps.length - 1) {
        _currentStepIndex++;
      } else {
        _isNavigating = false;
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _simulationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentStep = _steps[_currentStepIndex];

    return Scaffold(
      body: Stack(
        children: [
          // Map placeholder
          _NavigationMapMock(isDark: isDark, stepIndex: _currentStepIndex),

          // Top bar: back + speed
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  CircularIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  // Speed indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.darkSurface : Colors.white)
                          .withOpacity(0.92),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      boxShadow: AppShadows.small,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.speed_rounded,
                            color: AppColors.primary, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          _currentSpeed,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Current instruction banner
          Positioned(
            top: MediaQuery.of(context).padding.top + 64,
            left: AppSpacing.md,
            right: AppSpacing.md,
            child: _InstructionBanner(
              step: currentStep,
              isDark: isDark,
            ),
          ),

          // Bottom panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.xl)),
                boxShadow: AppShadows.large,
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ETA + Distance row
                    Row(
                      children: [
                        _NavMetric(
                          label: 'Distance',
                          value: Formatters.distance(_distanceRemainingKm),
                          icon: Icons.route_rounded,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        _NavMetric(
                          label: 'ETA',
                          value: Formatters.duration(_etaMinutes),
                          icon: Icons.schedule_rounded,
                          color: AppColors.info,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        _NavMetric(
                          label: 'Step',
                          value:
                              '${_currentStepIndex + 1}/${_steps.length}',
                          icon: Icons.format_list_numbered_rounded,
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Upcoming steps
                    if (_currentStepIndex < _steps.length - 1) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Next',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...List.generate(
                        (_steps.length - _currentStepIndex - 1)
                            .clamp(0, 2),
                        (i) {
                          final step =
                              _steps[_currentStepIndex + 1 + i];
                          return _UpcomingStepTile(
                            step: step,
                            isDark: isDark,
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Action buttons
                    if (_isNavigating)
                      Row(
                        children: [
                          Expanded(
                            child: SecondaryButton(
                              text: 'Stop Navigation',
                              icon: Icons.close_rounded,
                              height: 48,
                              onPressed: () {
                                setState(() => _isNavigating = false);
                                Navigator.pop(context);
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: PrimaryButton(
                              text: 'Arrived',
                              icon: Icons.check_circle_outline_rounded,
                              height: 48,
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'You have arrived at the destination!'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ],
                      )
                    else
                      PrimaryButton(
                        text: 'Ride Complete',
                        icon: Icons.check_rounded,
                        onPressed: () => Navigator.pop(context),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationStep {
  final String instruction;
  final String distance;
  final IconData icon;
  final String road;

  const _NavigationStep({
    required this.instruction,
    required this.distance,
    required this.icon,
    required this.road,
  });
}

class _InstructionBanner extends StatelessWidget {
  final _NavigationStep step;
  final bool isDark;

  const _InstructionBanner({required this.step, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.glow,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(step.icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.instruction,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${step.distance} • ${step.road}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
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

class _NavMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _NavMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: color,
                fontSize: 14,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingStepTile extends StatelessWidget {
  final _NavigationStep step;
  final bool isDark;

  const _UpcomingStepTile({required this.step, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(step.icon, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              step.instruction,
              style: const TextStyle(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            step.distance,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationMapMock extends StatelessWidget {
  final bool isDark;
  final int stepIndex;

  const _NavigationMapMock({
    required this.isDark,
    required this.stepIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF0f2027), Color(0xFF203a43), Color(0xFF2c5364)]
              : const [Color(0xFFE2F4FD), Color(0xFFDDF2EB), Color(0xFFE8F9ED)],
        ),
      ),
      child: CustomPaint(
        painter: _NavGridPainter(isDark: isDark, progress: stepIndex / 5.0),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _NavGridPainter extends CustomPainter {
  final bool isDark;
  final double progress;

  const _NavGridPainter({required this.isDark, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.06)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Route path
    final routePaint = Paint()
      ..color = AppColors.primary.withOpacity(0.3)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final route = Path()
      ..moveTo(size.width * 0.5, size.height * 0.85)
      ..cubicTo(
        size.width * 0.3, size.height * 0.65,
        size.width * 0.7, size.height * 0.45,
        size.width * 0.5, size.height * 0.25,
      );
    canvas.drawPath(route, routePaint);

    // Progress indicator (driven path)
    final drivenPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final pathMetrics = route.computeMetrics().first;
    final drivenPath = pathMetrics.extractPath(
      0,
      pathMetrics.length * progress,
    );
    canvas.drawPath(drivenPath, drivenPaint);

    // Current position dot
    if (progress > 0 && progress < 1.0) {
      final tangent =
          pathMetrics.getTangentForOffset(pathMetrics.length * progress);
      if (tangent != null) {
        canvas.drawCircle(
          tangent.position,
          10,
          Paint()..color = AppColors.primary,
        );
        canvas.drawCircle(
          tangent.position,
          6,
          Paint()..color = Colors.white,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NavGridPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
