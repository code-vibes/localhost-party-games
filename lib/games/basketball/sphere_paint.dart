import 'dart:math';

import 'package:flutter/material.dart';

import 'physics_ball.dart';

/// Shaded sphere + curved seams (no flat “plus” mark).
class SpherePaint {
  static void draw(
    Canvas canvas,
    Offset center,
    double radius,
    BallRotation rot, {
    double depthScale = 1,
  }) {
    final r = radius * depthScale;
    final shadow = Rect.fromCenter(
      center: center + Offset(0, r * 0.92),
      width: r * 1.75,
      height: r * 0.38,
    );
    canvas.drawOval(shadow, Paint()..color = Colors.black.withOpacity(0.28));

    final rect = Rect.fromCircle(center: center, radius: r);
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.42, -0.48),
          radius: 1.05,
          colors: const [
            Color(0xFFFFE0B2),
            Color(0xFFFF8F00),
            Color(0xFFE65100),
            Color(0xFF4E342E),
          ],
          stops: const [0.05, 0.42, 0.82, 1.0],
        ).createShader(rect),
    );

    canvas.drawCircle(
      center + Offset(-r * 0.38, -r * 0.42),
      r * 0.14,
      Paint()..color = Colors.white.withOpacity(0.5),
    );

    final seam = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.2, r * 0.07)
      ..strokeCap = StrokeCap.round;

    _seamArc(canvas, center, r, rot.yaw, rot.pitch, seam);
    _seamArc(canvas, center, r, rot.yaw + pi / 2, -rot.pitch * 0.7, seam);

    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = Colors.black.withOpacity(0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  static void _seamArc(
    Canvas canvas,
    Offset c,
    double r,
    double yaw,
    double pitch,
    Paint paint,
  ) {
    final path = Path();
    for (var t = -pi * 0.48; t <= pi * 0.48; t += 0.07) {
      final sx = sin(t + yaw);
      final sy = cos(t * 0.5 + pitch) * sin(t + yaw) * 0.35;
      final fore = cos(t) * 0.25 + 0.85;
      final p = Offset(c.dx + sx * r * fore, c.dy + sy * r);
      if (t == -pi * 0.48) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(path, paint);
  }
}