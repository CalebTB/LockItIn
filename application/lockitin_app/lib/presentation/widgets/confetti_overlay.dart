import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Confetti overlay widget for celebrating successful actions
///
/// Displays animated confetti particles falling from the top of the screen
/// with realistic physics (gravity, rotation, horizontal drift)
class ConfettiOverlay extends StatefulWidget {
  final VoidCallback? onComplete;

  const ConfettiOverlay({
    super.key,
    this.onComplete,
  });

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late List<ConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();

    // Create animation controller (2 seconds)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Animation with fade-out at end
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    // Generate particles
    _particles = List.generate(50, (index) => ConfettiParticle());

    // Start animation
    _controller.forward();

    // Notify completion
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: ConfettiPainter(
              particles: _particles,
              progress: _animation.value,
              opacity: _animation.value < 0.8 ? 1.0 : (1.0 - (_animation.value - 0.8) * 5),
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

/// Particle data model
class ConfettiParticle {
  final double x;
  final double y;
  final double vx; // horizontal velocity
  final double vy; // vertical velocity
  final double rotation;
  final double rotationSpeed;
  final Color color;
  final double size;

  ConfettiParticle()
      : x = Random().nextDouble(),
        y = -0.1,
        vx = (Random().nextDouble() - 0.5) * 0.3,
        vy = Random().nextDouble() * 0.5 + 0.3,
        rotation = Random().nextDouble() * 2 * pi,
        rotationSpeed = (Random().nextDouble() - 0.5) * 4,
        color = _randomColor(),
        size = Random().nextDouble() * 6 + 4;

  static Color _randomColor() {
    final colors = [
      AppColors.rose500,
      AppColors.orange500,
      AppColors.memberEmerald,
      AppColors.memberViolet,
      AppColors.memberCyan,
    ];
    return colors[Random().nextInt(colors.length)];
  }
}

/// Custom painter for confetti particles
class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;
  final double opacity;

  ConfettiPainter({
    required this.particles,
    required this.progress,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      // Calculate position with physics
      final x = particle.x * size.width + particle.vx * progress * size.width;
      final y = particle.y * size.height + particle.vy * progress * size.height +
                0.5 * 9.8 * progress * progress * size.height * 0.1; // gravity

      // Skip if off screen
      if (y > size.height) continue;

      // Calculate rotation
      final rotation = particle.rotation + particle.rotationSpeed * progress * 2 * pi;

      // Draw particle
      final paint = Paint()
        ..color = particle.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      // Draw rectangle particle
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: particle.size,
          height: particle.size * 0.6,
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.opacity != opacity;
  }
}
