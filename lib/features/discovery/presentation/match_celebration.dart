import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons.dart';

/// "It's a Match!" full-screen celebration with confetti (custom painter —
/// zero asset dependencies; swapped for a static card under reduce-motion).
Future<void> showMatchCelebration(
  BuildContext context, {
  required String otherName,
  required String conversationId,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.75),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, _, _) => _MatchDialog(
        otherName: otherName, conversationId: conversationId),
  );
}

class _MatchDialog extends StatefulWidget {
  const _MatchDialog({required this.otherName, required this.conversationId});

  final String otherName;
  final String conversationId;

  @override
  State<_MatchDialog> createState() => _MatchDialogState();
}

class _MatchDialogState extends State<_MatchDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    Widget heart = Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        gradient: AppColors.ctaGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.5),
              blurRadius: 40,
              offset: const Offset(0, 10)),
        ],
      ),
      child: const Icon(Icons.favorite, size: 56, color: AppColors.onPrimary),
    );
    if (!reduceMotion) {
      heart = heart
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 0.92, end: 1.08, duration: 700.ms, curve: Curves.easeInOut);
    }

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          if (!reduceMotion)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _confetti,
                  builder: (_, _) => CustomPaint(
                      painter: _ConfettiPainter(progress: _confetti.value)),
                ),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  heart,
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l10n.itsAMatch,
                    textAlign: TextAlign.center,
                    style: AppTypography.display
                        .copyWith(color: AppColors.onPrimary, fontSize: 40),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.matchBody(widget.otherName),
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyLarge
                        .copyWith(color: AppColors.onPrimary.withValues(alpha: 0.85)),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  PrimaryButton(
                    label: l10n.sayHi,
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push(Routes.chat(widget.conversationId));
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.keepSwiping,
                        style: const TextStyle(color: AppColors.onPrimary)),
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

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress});

  final double progress;
  static final _rng = math.Random(7);
  static final List<_Particle> _particles = List.generate(90, (i) {
    return _Particle(
      x: _rng.nextDouble(),
      speed: 0.4 + _rng.nextDouble() * 0.8,
      phase: _rng.nextDouble(),
      size: 5 + _rng.nextDouble() * 7,
      color: [
        AppColors.cyanBright,
        AppColors.primary,
        AppColors.cyan100,
        AppColors.poke,
        AppColors.warning,
      ][i % 5],
      sway: 0.02 + _rng.nextDouble() * 0.05,
      rotation: _rng.nextDouble() * math.pi,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in _particles) {
      final t = (progress * p.speed + p.phase) % 1.0;
      final dx =
          (p.x + math.sin(t * math.pi * 4) * p.sway) * size.width;
      final dy = t * (size.height + 40) - 20;
      paint.color = p.color.withValues(alpha: (1 - t) * 0.9 + 0.1);
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(p.rotation + t * math.pi * 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset.zero, width: p.size, height: p.size * 0.6),
            const Radius.circular(2)),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _Particle {
  const _Particle({
    required this.x,
    required this.speed,
    required this.phase,
    required this.size,
    required this.color,
    required this.sway,
    required this.rotation,
  });

  final double x;
  final double speed;
  final double phase;
  final double size;
  final Color color;
  final double sway;
  final double rotation;
}
