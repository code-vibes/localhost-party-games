import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../core/play_mode.dart';
import '../theme.dart';
import 'engine/game_tick.dart';
import 'engine/juice.dart';
import 'game_router.dart';

/// 2.5D basketball with rim physics, hanging net, and solo vs CPU.
class BasketballGame extends StatefulWidget {
  const BasketballGame({super.key});
  @override
  State<BasketballGame> createState() => _BasketballGameState();
}

class _BasketballGameState extends State<BasketballGame> with TickerProviderStateMixin, GameTickMixin {
  static const _cpuIndex = 1;
  static const _maxScore = 7;

  final rng = Random();
  final scores = <int>[];

  int current = 0;
  bool showResult = false;
  int flash = 0;
  String? popup;

  // Court / hoop
  double hoopSway = 0;
  double hoopPhase = 0;
  double netWave = 0;
  double netBurst = 0;
  double cameraZoom = 1;

  // Ball — court space (x lateral, y vertical arc, z depth 0..1 toward hoop)
  double bx = 0;
  double by = 0;
  double bz = 0;
  double vx = 0;
  double vy = 0;
  double vz = 0;
  bool ballLive = false;
  int rimBounces = 0;

  // Aim
  Offset dragStart = Offset.zero;
  Offset dragPull = Offset.zero;
  bool dragging = false;

  bool get vsCpu {
    final app = context.read<AppState>();
    return app.playMode == PlayMode.solo || app.playerCount == 1;
  }

  int get logicalPlayers => vsCpu ? 2 : context.read<AppState>().playerCount;

  @override
  void initState() {
    super.initState();
    startTick();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resetMatch());
  }

  void _resetMatch() {
    scores
      ..clear()
      ..addAll(List.filled(logicalPlayers, 0));
    current = 0;
    showResult = false;
    _resetBall();
    if (vsCpu && current == _cpuIndex) _scheduleCpuShot();
  }

  void _resetBall() {
    ballLive = false;
    bx = 0;
    by = 0;
    bz = 0;
    vx = vy = vz = 0;
    rimBounces = 0;
    dragPull = Offset.zero;
    dragging = false;
    popup = null;
    netBurst = 0;
  }

  void _launchBall({required double power, required double angle, double lateral = 0}) {
    final p = power.clamp(0.35, 1.15);
    vx = lateral * 0.9 + sin(angle) * 140 * p;
    vy = -380 * p - 40;
    vz = 1.05 * p;
    ballLive = true;
    dragging = false;
    dragPull = Offset.zero;
    setState(() => popup = null);
  }

  @override
  void onGameTick(double dt) {
    hoopPhase += dt;
    hoopSway = sin(hoopPhase * 1.1) * 18;
    if (netBurst > 0) {
      netBurst = max(0, netBurst - dt * 1.8);
      netWave += dt * 14;
    } else {
      netWave += dt * 2.5;
    }
    if (cameraZoom > 1) cameraZoom = max(1, cameraZoom - dt * 0.9);

    if (ballLive) {
      const g = 920.0;
      vy += g * dt;
      vx *= pow(0.992, dt * 60);
      bx += vx * dt;
      by += vy * dt;
      bz += vz * dt;

      final rimY = -118;
      final rimX = hoopSway;
      const rimR = 34.0;

      if (bz >= 0.88 && bz <= 1.08 && vy > 0) {
        final dx = bx - rimX;
        final dy = by - rimY;
        final dist = sqrt(dx * dx + dy * dy);
        if (dist < rimR + 6) {
          if (dist < rimR * 0.62 && rimBounces < 2) {
            _registerScore(bank: rimBounces > 0 || dist > rimR * 0.38);
          } else if (rimBounces < 3) {
            rimBounces++;
            popup = 'RIM!';
            final n = sqrt(dx * dx + dy * dy);
            final nx = dx / (n + 0.001);
            vx = nx * 120 + (rng.nextDouble() - 0.5) * 40;
            vy = -vy.abs() * 0.42;
            vz = -0.12;
            bz = 0.86;
            flash++;
          } else {
            _resolveMiss();
          }
        }
      }
      if (bz > 1.25 || by > 200) _resolveMiss();
    }

    if (mounted) setState(() {});
  }

  void _registerScore({required bool bank}) {
    ballLive = false;
    while (scores.length <= current) scores.add(0);
    scores[current]++;
    flash++;
    netBurst = 1;
    cameraZoom = 1.06;
    popup = bank ? 'BANK!' : 'SWISH!';
    if (scores[current] >= _maxScore) {
      setState(() => showResult = true);
      return;
    }
    _nextTurn();
  }

  void _resolveMiss() {
    ballLive = false;
    popup = 'MISS';
    _nextTurn();
  }

  void _nextTurn() {
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (!mounted || showResult) return;
      _resetBall();
      current = (current + 1) % logicalPlayers;
      setState(() {});
      if (vsCpu && current == _cpuIndex) _scheduleCpuShot();
    });
  }

  void _scheduleCpuShot() {
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted || showResult || ballLive || current != _cpuIndex) return;
      final power = 0.72 + rng.nextDouble() * 0.28;
      final aimError = (rng.nextDouble() - 0.5) * 0.55;
      _launchBall(power: power, angle: -pi / 2 + aimError, lateral: hoopSway * 0.3);
    });
  }

  void _onPanStart(DragStartDetails d) {
    if (ballLive || showResult || current == _cpuIndex && vsCpu) return;
    dragStart = d.localPosition;
    dragging = true;
    dragPull = Offset.zero;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (!dragging) return;
    dragPull = d.localPosition - dragStart;
  }

  void _onPanEnd(DragEndDetails d) {
    if (!dragging || ballLive) return;
    final pull = dragPull;
    final power = (pull.distance / 130).clamp(0.35, 1.15);
    final angle = atan2(pull.dx, -pull.dy.clamp(1, 999));
    _launchBall(power: power, angle: angle, lateral: pull.dx * 0.15);
  }

  String _banner(AppState app) {
    if (vsCpu) {
      final who = current == 0 ? 'YOU' : 'CPU';
      return '$who · first to $_maxScore · ${scores[0]}-${scores[1]}';
    }
    return '${PartyTheme.playerName(current)} · ${scores[current]} pts · swipe to shoot';
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    while (scores.length < logicalPlayers) scores.add(0);
    final winner = scores.isEmpty ? 0 : scores.indexOf(scores.reduce(max));
    final winnerLabel = vsCpu ? (winner == 0 ? 'You beat CPU!' : 'CPU wins') : '${PartyTheme.playerName(winner)} wins!';

    return Scaffold(
      appBar: AppBar(title: Text(vsCpu ? 'BASKETBALL · VS CPU' : 'BASKETBALL HOOPS')),
      body: Stack(
        children: [
          Column(
            children: [
              TurnBanner(playerIndex: current, message: _banner(app)),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: RepaintBoundary(
                    child: Transform.scale(
                      scale: cameraZoom,
                      child: CustomPaint(
                        painter: _CourtPainter(
                          hoopSway: hoopSway,
                          netWave: netWave,
                          netBurst: netBurst,
                          ballActive: ballLive,
                          ball: _BallVisual(x: bx, y: by, z: bz, flash: flash),
                          aim: dragging ? dragPull : null,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
              if (dragging)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (dragPull.distance / 160).clamp(0.0, 1.0),
                            minHeight: 10,
                            color: PartyTheme.orangePlayer,
                            backgroundColor: Colors.white24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('${dragPull.distance.toInt()} power', style: const TextStyle(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  vsCpu ? 'YOU ${scores[0]}  ·  CPU ${scores.length > 1 ? scores[1] : 0}' : 'Score: ${scores[current]}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          if (popup != null)
            Positioned(
              top: 72,
              left: 0,
              right: 0,
              child: Center(child: FloatingCallout(text: popup!, color: Colors.orangeAccent)),
            ),
          if (showResult)
            ResultOverlay(
              title: winnerLabel,
              detail: vsCpu ? 'Final ${scores[0]} – ${scores[1]}' : scores.asMap().entries.map((e) => '${PartyTheme.playerName(e.key)}: ${e.value}').join(' · '),
              onAgain: () {
                setState(() => showResult = false);
                _resetMatch();
              },
              onDone: () {
                if (!vsCpu) app.awardWin(winner);
                else if (winner == 0) app.awardWin(0);
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }
}

class _BallVisual {
  _BallVisual({required this.x, required this.y, required this.z, required this.flash});
  final double x;
  final double y;
  final double z;
  final int flash;
}

class _CourtPainter extends CustomPainter {
  _CourtPainter({
    required this.hoopSway,
    required this.netWave,
    required this.netBurst,
    required this.ballActive,
    required this.ball,
    this.aim,
  });

  final double hoopSway;
  final double netWave;
  final double netBurst;
  final bool ballActive;
  final _BallVisual ball;
  final Offset? aim;

  Offset _project(double x, double y, double z, Size size) {
    final cx = size.width / 2;
    final floorY = size.height * 0.78;
    final hoopY = size.height * 0.22;
    final t = z.clamp(0.0, 1.15);
    final depth = 0.55 + t * 0.45;
    final py = floorY + (hoopY - floorY) * t;
    return Offset(cx + x * depth, py + y * (1 - t * 0.85));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    // Sky
    final sky = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(sky, Paint()..shader = const LinearGradient(colors: [Color(0xFF87CEEB), Color(0xFFBFE8FF)], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(sky));

    // Hardwood (perspective trapezoid)
    final floorY = size.height * 0.78;
    final path = Path()
      ..moveTo(size.width * 0.05, floorY)
      ..lineTo(size.width * 0.95, floorY)
      ..lineTo(size.width * 0.72, size.height * 0.35)
      ..lineTo(size.width * 0.28, size.height * 0.35)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFC68642));
    canvas.drawPath(path, Paint()..color = const Color(0xFF9B5E2E).withOpacity(0.25)..style = PaintingStyle.stroke..strokeWidth = 2);

    // Court lines
    final line = Paint()..color = Colors.white.withOpacity(0.75)..strokeWidth = 2;
    canvas.drawLine(Offset(cx, floorY), Offset(cx, size.height * 0.38), line);
    canvas.drawLine(Offset(size.width * 0.2, floorY - 8), Offset(size.width * 0.8, floorY - 8), line);
    canvas.drawArc(Rect.fromCenter(center: Offset(cx, floorY - 20), width: 140, height: 60), pi, pi, false, line);

    final hoopCenter = _project(hoopSway, -118, 1.0, size);
    final backboardW = 110 * (0.55 + 0.45);
    const backboardH = 68.0;

    // Backboard
    final board = RRect.fromRectAndRadius(
      Rect.fromCenter(center: hoopCenter + const Offset(0, -52), width: backboardW, height: backboardH),
      const Radius.circular(6),
    );
    canvas.drawRRect(board, Paint()..color = Colors.white);
    canvas.drawRRect(board, Paint()..color = Colors.red.shade700..style = PaintingStyle.stroke..strokeWidth = 4);
    canvas.drawRect(Rect.fromCenter(center: hoopCenter + const Offset(0, -52), width: 36, height: 28), Paint()..color = Colors.orange.shade700);

    // Rim (ellipse for depth)
    canvas.drawOval(Rect.fromCenter(center: hoopCenter, width: 74, height: 22), Paint()..color = Colors.orange.shade800..style = PaintingStyle.stroke..strokeWidth = 5);

    // Net
    final netPaint = Paint()..color = Colors.white.withOpacity(0.85)..strokeWidth = 1.2;
    for (var i = -3; i <= 3; i++) {
      final sway = sin(netWave + i * 0.7) * (4 + netBurst * 18);
      final x0 = hoopCenter.dx + i * 9.0;
      canvas.drawLine(Offset(x0, hoopCenter.dy + 4), Offset(x0 + sway, hoopCenter.dy + 34 + netBurst * 12), netPaint);
    }
    for (var row = 0; row < 4; row++) {
      final y = hoopCenter.dy + 8 + row * 8 + netBurst * 6;
      canvas.drawLine(Offset(hoopCenter.dx - 28, y), Offset(hoopCenter.dx + 28, y), netPaint);
    }

    // Aim helper
    if (aim != null && aim!.distance > 8) {
      final start = _project(0, 40, 0, size);
      final pull = aim!;
      final end = start + Offset(pull.dx * 0.5, pull.dy * 0.35);
      canvas.drawLine(start, end, Paint()..color = Colors.yellowAccent.withOpacity(0.8)..strokeWidth = 3);
      canvas.drawCircle(end, 6, Paint()..color = Colors.yellowAccent);
    }

    // Ball
    final bpos = !ballActive && ball.z <= 0.001
        ? _project(0, 40, 0, size)
        : _project(ball.x, ball.y, ball.z, size);
    final scale = 0.85 + ball.z * 0.55;
    final radius = 18 * scale;
    canvas.drawCircle(
      bpos,
      radius,
      Paint()
        ..shader = RadialGradient(colors: [Colors.orange.shade200, Colors.deepOrange.shade800]).createShader(Rect.fromCircle(center: bpos, radius: radius)),
    );
    canvas.drawCircle(bpos, radius, Paint()..color = Colors.black26..style = PaintingStyle.stroke..strokeWidth = 1.5);
    canvas.drawLine(bpos - Offset(radius * 0.6, 0), bpos + Offset(radius * 0.6, 0), Paint()..color = Colors.black38..strokeWidth = 1);

    // Player shadow
    final shadow = _project(0, 40, 0, size);
    canvas.drawOval(Rect.fromCenter(center: shadow + const Offset(0, 26), width: 80, height: 22), Paint()..color = Colors.black.withOpacity(0.18));
  }

  @override
  bool shouldRepaint(covariant _CourtPainter old) =>
      old.hoopSway != hoopSway ||
      old.netBurst != netBurst ||
      old.ballActive != ballActive ||
      old.ball.x != ball.x ||
      old.ball.y != ball.y ||
      old.ball.z != ball.z ||
      old.aim != aim;
}