import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _steps = [
    (
      art: 'track',
      title: 'Track every dollar',
      body: "Log expenses in seconds. Auto-categorised so you don't have to "
          'think about it.',
    ),
    (
      art: 'budget',
      title: 'Set budgets that stick',
      body: 'Monthly limits per category. Flo nudges you long before you '
          'overspend.',
    ),
    (
      art: 'goal',
      title: 'Reach the goals that matter',
      body: 'Save toward a trip, a buffer, a big move. Watch your future fill '
          'in.',
    ),
  ];

  bool get _isLast => _page == _steps.length - 1;

  Future<void> _finish() async {
    await ref.read(onboardingSeenProvider.notifier).complete();
    if (mounted) context.go(AppRoutes.login);
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: AnimatedOpacity(
                opacity: _isLast ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: TextButton(
                  onPressed: _isLast ? null : _finish,
                  child: Text('Skip',
                      style: TextStyle(color: theme.hintColor)),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _steps.length,
                itemBuilder: (context, i) {
                  final step = _steps[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _OnboardArt(kind: step.art),
                        const SizedBox(height: AppSpacing.xxl),
                        Text(step.title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium),
                        const SizedBox(height: AppSpacing.sm),
                        Text(step.body,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(color: theme.hintColor, height: 1.5)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _steps.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _page ? 26 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _page
                                ? theme.colorScheme.primary
                                : AppColors.trackLight,
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: _next,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_isLast ? 'Get started' : 'Continue'),
                        const SizedBox(width: AppSpacing.sm),
                        const Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lightweight, on-brand illustrations for each onboarding step.
class _OnboardArt extends StatelessWidget {
  const _OnboardArt({required this.kind});

  final String kind;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 220, child: Center(child: _build(context)));
  }

  Widget _build(BuildContext context) {
    final theme = Theme.of(context);
    final border = Border.all(color: theme.dividerColor);
    switch (kind) {
      case 'budget':
        return SizedBox(
          width: 200,
          height: 200,
          child: CustomPaint(
            painter: _RingArtPainter(
              progress: 0.68,
              color: theme.colorScheme.primary,
              track: AppColors.trackLight,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('68%', style: theme.textTheme.headlineMedium),
                  Text('of budget',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor)),
                ],
              ),
            ),
          ),
        );
      case 'goal':
        return Container(
          width: 260,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: border,
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tokyo trip',
                      style: theme.textTheme.titleMedium),
                  Text('72%',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: AppColors.success)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.pill),
                child: const LinearProgressIndicator(
                  value: 0.72,
                  minHeight: 12,
                  backgroundColor: AppColors.trackLight,
                  valueColor: AlwaysStoppedAnimation(AppColors.success),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(r'$2,160 of $3,000',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor)),
            ],
          ),
        );
      case 'track':
      default:
        return Container(
          width: 240,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: border,
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
          child: Column(
            children: [
              for (final c in const [
                ('food', AppColors.warning),
                ('transport', Color(0xFF3B82F6)),
                ('shopping', Color(0xFFEC4899)),
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: c.$2.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                                height: 9,
                                width: 90,
                                color: theme.dividerColor),
                            const SizedBox(height: 6),
                            Container(
                                height: 7,
                                width: 56,
                                color: AppColors.trackLight),
                          ],
                        ),
                      ),
                      Container(
                          height: 9, width: 36, color: theme.dividerColor),
                    ],
                  ),
                ),
            ],
          ),
        );
    }
  }
}

class _RingArtPainter extends CustomPainter {
  _RingArtPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - 16) / 2;
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, base..color = track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      progress * 2 * math.pi,
      false,
      base..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _RingArtPainter old) =>
      old.progress != progress;
}
