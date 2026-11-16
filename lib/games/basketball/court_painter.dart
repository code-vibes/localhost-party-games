import 'dart:math';

import 'package:flutter/material.dart';

import 'ball_sim.dart';

class CourtPainter extends CustomPainter {
  CourtPainter({
    required this.hoopX,
    required this.netWave,
    required this.netBurst,
    required this.shotClock,
    required this.ball,
    required this.ballLive,
    required this.previewArc,
    this.aimPull,
    this.spin = 0,
  });

  final double hoopX;
  final double netWave;
  final double netBurst;
  final int shotClock;
  final Vec3 ball;
  final bool ballLive;
  final List<Vec3> previewArc;
  final Offset? aimPull;
  final double spin;

  Offset _project(double x, double y, double z, Size size) {
    final t = (z / 10).clamp(0.0, 1.2);
    final cx = size.width / 2;
    final floor = size.height * 0.84;
    final horizon = size.height * 0.27;
    final depth = 1.0 - t * 0.48;
    return Offset(cx + x * 52 * depth, floor + (horizon - floor) * t - y * 34 * depth);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final floor = size.height * 0.84;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.52),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF6BB8E8), Color(0xFFB8E4F8)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.52)),
    );
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.09), 20, Paint()..color = Colors.white);

    final grassTop = size.height * 0.48;
    canvas.drawRect(Rect.fromLTWH(0, grassTop, size.width, floor - grassTop), Paint()..color = const Color(0xFF52A852));
    final fence = Paint()..color = Colors.grey.shade700.withOpacity(0.55)..strokeWidth = 1.1;
    for (var x = 0.0; x < size.width; x += 12) {
      canvas.drawLine(Offset(x, grassTop), Offset(x, grassTop + 44), fence);
    }
    for (var y = grassTop; y < grassTop + 44; y += 9) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), fence);
    }

    final court = Path()
      ..moveTo(size.width * 0.05, floor)
      ..lineTo(size.width * 0.95, floor)
      ..lineTo(size.width * 0.71, size.height * 0.36)
      ..lineTo(size.width * 0.29, size.height * 0.36)
      ..close();
    canvas.drawPath(court, Paint()..color = const Color(0xFF252528));
    canvas.drawPath(court, Paint()..color = const Color(0xFFE04D3A)..style = PaintingStyle.stroke..strokeWidth = 2.8);
    final line = Paint()..color = const Color(0xFFE04D3A)..strokeWidth = 2.4;
    canvas.drawLine(Offset(cx, floor), Offset(cx, size.height * 0.37), line);
    canvas.drawLine(Offset(size.width * 0.2, floor - 5), Offset(size.width * 0.8, floor - 5), line);
    canvas.drawArc(Rect.fromCenter(center: Offset(cx, floor - 22), width: 148, height: 56), pi, pi, false, line);

    final hoop = _project(hoopX, BallSim.rimY, BallSim.rimZ, size);
    canvas.drawRect(Rect.fromCenter(center: hoop + const Offset(0, -18), width: 9, height: 100), Paint()..color = Colors.black87);

    final board = RRect.fromRectAndRadius(
      Rect.fromCenter(center: hoop + const Offset(0, -62), width: 104, height: 62),
      const Radius.circular(4),
    );
    canvas.drawRRect(board, Paint()..color = const Color(0xFFD44545));
    canvas.drawRRect(board, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 2.5);
    canvas.drawRect(Rect.fromCenter(center: hoop + const Offset(0, -62), width: 36, height: 24), Paint()..color = Colors.white70);

    final timerBox = RRect.fromRectAndRadius(
      Rect.fromCenter(center: hoop + const Offset(0, -102), width: 46, height: 22),
      const Radius.circular(3),
    );
    canvas.drawRRect(timerBox, Paint()..color = Colors.black);
    final tp = TextPainter(
      text: TextSpan(text: '$shotClock', style: const TextStyle(color: Color(0xFFFF3B30), fontWeight: FontWeight.w900, fontSize: 13)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, hoop + Offset(-tp.width / 2, -110));

    canvas.drawOval(Rect.fromCenter(center: hoop, width: 78, height: 19), Paint()..color = const Color(0xFFFFA726)..style = PaintingStyle.stroke..strokeWidth = 5);

    _drawNet(canvas, hoop);

    if (previewArc.length > 1) {
      final path = Path();
      for (var i = 0; i < previewArc.length; i++) {
        final p = _project(previewArc[i].x, previewArc[i].y, previewArc[i].z, size);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
        canvas.drawCircle(p, 3.2 - i * 0.08, Paint()..color = Colors.yellowAccent.withOpacity(0.85 - i * 0.02));
      }
      canvas.drawPath(path, Paint()..color = Colors.yellowAccent.withOpacity(0.35)..strokeWidth = 2..style = PaintingStyle.stroke);
    }

    if (aimPull != null && aimPull!.distance > 10) {
      final start = _project(0, 2, 0, size);
      final pull = aimPull!;
      canvas.drawLine(start, start + Offset(-pull.dx * 0.32, -pull.dy * 0.32), Paint()..color = Colors.orangeAccent..strokeWidth = 3);
    }

    final bpos = _project(ball.x, ball.y, ball.z, size);
    final t = (ball.z / 10).clamp(0.0, 1.0);
    final radius = 19 * (0.55 + (1 - t) * 0.55);

    canvas.drawOval(
      Rect.fromCenter(center: bpos + Offset(0, radius * 0.85), width: radius * 1.7, height: radius * 0.4),
      Paint()..color = Colors.black.withOpacity(0.25),
    );

    canvas.save();
    canvas.translate(bpos.dx, bpos.dy);
    canvas.rotate(spin);
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..shader = RadialGradient(colors: [Color.lerp(Colors.orange.shade200, Colors.deepOrange, t)!, const Color(0xFFE65100)])
            .createShader(Rect.fromCircle(center: Offset.zero, radius: radius)),
    );
    canvas.drawCircle(Offset.zero, radius, Paint()..color = Colors.black45..style = PaintingStyle.stroke..strokeWidth = 1.4);
    canvas.drawLine(Offset(-radius * 0.65, 0), Offset(radius * 0.65, 0), Paint()..color = Colors.black54..strokeWidth = 1.2);
    canvas.drawLine(Offset(0, -radius * 0.65), Offset(0, radius * 0.65), Paint()..color = Colors.black54..strokeWidth = 1.2);
    canvas.restore();
  }

  void _drawNet(Canvas canvas, Offset hoop) {
    final net = Paint()..color = Colors.white.withOpacity(0.92)..strokeWidth = 1.1;
    for (var i = -4; i <= 4; i++) {
      final sway = sin(netWave + i * 0.6) * (2 + netBurst * 18);
      final x0 = hoop.dx + i * 8.0;
      canvas.drawLine(Offset(x0, hoop.dy + 2), Offset(x0 + sway, hoop.dy + 36 + netBurst * 16), net);
    }
    for (var r = 0; r < 5; r++) {
      final y = hoop.dy + 6 + r * 7 + netBurst * 6;
      canvas.drawLine(Offset(hoop.dx - 30, y), Offset(hoop.dx + 30, y), net);
    }
  }

  @override
  bool shouldRepaint(covariant CourtPainter old) => true;
}