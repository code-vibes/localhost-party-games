import 'package:flutter/material.dart';

import 'net_mesh.dart';
import 'physics_ball.dart';
import 'sphere_paint.dart';
import 'world.dart';

class CourtScenePainter extends CustomPainter {
  CourtScenePainter({
    required this.hoopX,
    required this.timeLeft,
    required this.baskets,
    required this.flying,
    required this.readyPos,
    required this.showReady,
    required this.previewArc,
    required this.net,
    required this.aimPull,
    required this.dragging,
  });

  final double hoopX;
  final double timeLeft;
  final int baskets;
  final List<FlyingBall> flying;
  final Vec3 readyPos;
  final bool showReady;
  final List<Vec3> previewArc;
  final NetMesh net;
  final Offset? aimPull;
  final bool dragging;

  @override
  void paint(Canvas canvas, Size size) {
    _skyAndCourt(canvas, size);
    final hoopScreen = CourtWorld.project(Vec3(hoopX, CourtWorld.rimY, CourtWorld.rimZ), size);
    final cord = Paint()
      ..color = Colors.white.withOpacity(0.88)
      ..strokeWidth = 1.15;
    net.paint(canvas, cord);

    _backboard(canvas, hoopScreen);
    _rim(canvas, hoopScreen);

    if (previewArc.length > 1) {
      final arcPaint = Paint()..color = Colors.amberAccent.withOpacity(0.4)..strokeWidth = 2;
      final path = Path();
      for (var i = 0; i < previewArc.length; i++) {
        final p = CourtWorld.project(previewArc[i], size);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
        canvas.drawCircle(p, 3 - i * 0.05, Paint()..color = Colors.amber.withOpacity(0.9 - i * 0.025));
      }
      canvas.drawPath(path, arcPaint);
    }

    final sorted = [...flying]..sort((a, b) => a.z.compareTo(b.z));
    for (final b in sorted) {
      final center = CourtWorld.project(Vec3(b.x, b.y, b.z), size);
      SpherePaint.draw(canvas, center, CourtWorld.ballRadius(Vec3(b.x, b.y, b.z)), b.rotation);
    }
    if (showReady) {
      final center = CourtWorld.project(readyPos, size);
      SpherePaint.draw(canvas, center, CourtWorld.ballRadius(readyPos), BallRotation());
    }

    if (dragging && aimPull != null) {
      final start = CourtWorld.project(readyPos, size);
      canvas.drawLine(start, start - aimPull! * 0.35, Paint()..color = Colors.orangeAccent..strokeWidth = 3.5);
    }

    _hud(canvas, size);
  }

  void _skyAndCourt(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.5),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5BA3E8), Color(0xFF9AD4F8), Color(0xFFCDE9F8)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.5)),
    );

    final vanish = size.height * 0.34;
    final floor = size.height * 0.87;
    final court = Path()
      ..moveTo(size.width * 0.04, floor)
      ..lineTo(size.width * 0.96, floor)
      ..lineTo(size.width * 0.72, vanish)
      ..lineTo(size.width * 0.28, vanish)
      ..close();
    canvas.drawPath(court, Paint()..color = const Color(0xFF1E1E22));
    final stripe = Paint()..color = const Color(0xFFE53935)..strokeWidth = 3;
    canvas.drawPath(court, stripe..style = PaintingStyle.stroke);

    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.46, size.width, floor - size.height * 0.46),
      Paint()..color = const Color(0xFF3D9E48),
    );
  }

  void _backboard(Canvas canvas, Offset hoop) {
    final board = RRect.fromRectAndRadius(
      Rect.fromCenter(center: hoop + const Offset(0, -58), width: 108, height: 64),
      const Radius.circular(5),
    );
    canvas.drawRRect(board, Paint()..color = const Color(0xFFD32F2F));
    canvas.drawRRect(board, Paint()..color = Colors.white70..style = PaintingStyle.stroke..strokeWidth = 3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: hoop + const Offset(0, -58), width: 40, height: 26),
        const Radius.circular(2),
      ),
      Paint()..color = Colors.white.withOpacity(0.85),
    );
    canvas.drawRect(Rect.fromCenter(center: hoop + const Offset(0, -18), width: 8, height: 96), Paint()..color = const Color(0xFF212121));
  }

  void _rim(Canvas canvas, Offset hoop) {
    canvas.drawOval(
      Rect.fromCenter(center: hoop, width: 78, height: 20),
      Paint()..color = const Color(0xFFFF9800)..style = PaintingStyle.stroke..strokeWidth = 5.5,
    );
  }

  void _hud(Canvas canvas, Size size) {
    final timer = TextPainter(
      text: TextSpan(
        text: '${timeLeft.ceil().clamp(0, 99)}s',
        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, shadows: [Shadow(blurRadius: 6)]),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    timer.paint(canvas, Offset(size.width - timer.width - 16, 12));

    final score = TextPainter(
      text: TextSpan(
        text: '$baskets',
        style: const TextStyle(color: Color(0xFFFFEB3B), fontSize: 36, fontWeight: FontWeight.w900, shadows: [Shadow(blurRadius: 8)]),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    score.paint(canvas, const Offset(16, 8));
  }

  @override
  bool shouldRepaint(covariant CourtScenePainter old) => true;
}
