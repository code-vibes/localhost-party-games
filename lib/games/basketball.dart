import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../core/play_mode.dart';
import '../theme.dart';
import 'engine/game_tick.dart';
import 'engine/juice.dart';
import 'game_router.dart';

/// 2.5D basketball — swipe maps to launch velocity (slingshot + flick).
class BasketballGame extends StatefulWidget {
  const BasketballGame({super.key});
  @override
  State<BasketballGame> createState() => _BasketballGameState();
}

class _BasketballGameState extends State<BasketballGame> with TickerProviderStateMixin, GameTickMixin {
  static const _cpuIndex = 1;
  static const _maxScore = 7;
  static const _shotClock = 24.0;

  final rng = Random();
  final scores = <int>[];

  int current = 0;
  bool showResult = false;
  int flash = 0;
  String? popup;
  double shotClock = _shotClock;

  double hoopSway = 0;
  double hoopPhase = 0;
  double netWave = 0;
  double netBurst = 0;
  double cameraZoom = 1;

  double bx = 0;
  double by = 40;
  double bz = 0;
  double vx = 0;
  double vy = 0;
  double vz = 0;
  bool ballLive = false;
  int rimBounces = 0;

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
    by = 40;
    bz = 0;
    vx = vy = vz = 0;
    rimBounces = 0;
    dragPull = Offset.zero;
    dragging = false;
    popup = null;
    netBurst = 0;
    shotClock = _shotClock;
  }

  /// Swipe → court-space velocity. Pull-back + release flick toward hoop.
  void _launchFromSwipe(Offset pull, Velocity flick) {
    if (pull.distance < 10 && flick.pixelsPerSecond.distance < 80) return;

    final power = ((pull.distance / 95) + (flick.pixelsPerSecond.distance / 1400)).clamp(0.32, 1.35);

    // Slingshot: pull down/back, release shoots opposite. Flick adds impulse.
    var impulse = Offset.zero;
    if (pull.distance > 8) impulse += Offset(-pull.dx, -pull.dy);
    if (flick.pixelsPerSecond.distance > 60) {
      impulse += Offset(flick.pixelsPerSecond.dx, flick.pixelsPerSecond.dy) * 0.035;
    }
    if (impulse.distance < 12) return;
    final dir = impulse / impulse.distance;

    vz = 0.48 + power * 0.92;
    final timeToRim = 1.02 / vz;

    // Lateral: swipe dx steers; blend toward hoop x at rim plane.
    final swipeSteer = dir.dx * 220 * power;
    final hoopTarget = hoopSway + swipeSteer * 0.35;
    vx = hoopTarget / timeToRim + dir.dx * 180 * power;

    // Vertical arc: upward swipe (negative screen dy) → negative vy (loft).
    vy = dir.dy * 300 * power;
    if (vy > -60) vy = -60 - 240 * power;

    ballLive = true;
    dragging = false;
    dragPull = Offset.zero;
    setState(() => popup = null);
  }

  _ShotVel _previewVel() {
    if (!dragging || dragPull.distance < 8) return _ShotVel.zero;
    final fakeFlick = Velocity(pixelsPerSecond: Offset(-dragPull.dx * 4, -dragPull.dy * 4));
    final power = (dragPull.distance / 95).clamp(0.2, 1.35);
    var impulse = Offset(-dragPull.dx, -dragPull.dy);
    if (impulse.distance < 1) return _ShotVel.zero;
    final dir = impulse / impulse.distance;
    final pvz = 0.48 + power * 0.92;
    final t = 1.02 / pvz;
    final steer = dir.dx * 220 * power;
    final pvx = (hoopSway + steer * 0.35) / t + dir.dx * 180 * power;
    var pvy = dir.dy * 300 * power;
    if (pvy > -60) pvy = -60 - 240 * power;
    return _ShotVel(pvx, pvy, pvz);
  }

  @override
  void onGameTick(double dt) {
    hoopPhase += dt;
    hoopSway = sin(hoopPhase * 0.9) * 22;
    if (netBurst > 0) {
      netBurst = max(0, netBurst - dt * 1.8);
      netWave += dt * 14;
    } else {
      netWave += dt * 2.2;
    }
    if (cameraZoom > 1) cameraZoom = max(1, cameraZoom - dt * 0.9);

    if (!ballLive && current != _cpuIndex && !showResult && !dragging) {
      shotClock -= dt;
      if (shotClock <= 0) _resolveMiss();
    }

    if (ballLive) {
      const g = 880.0;
      vy += g * dt;
      vx *= pow(0.994, dt * 60);
      bx += vx * dt;
      by += vy * dt;
      bz += vz * dt;

      const rimY = -118.0;
      final rimX = hoopSway;
      const rimR = 34.0;

      if (bz >= 0.9 && bz <= 1.12 && vy > 0) {
        final dx = bx - rimX;
        final dy = by - rimY;
        final dist = sqrt(dx * dx + dy * dy);
        if (dist < rimR + 8) {
          if (dist < rimR * 0.58 && rimBounces < 2) {
            _registerScore(bank: rimBounces > 0 || dist > rimR * 0.36);
          } else if (rimBounces < 3) {
            rimBounces++;
            popup = 'RIM!';
            final n = dist + 0.001;
            vx = (dx / n) * 95 + (rng.nextDouble() - 0.5) * 30;
            vy = -vy.abs() * 0.38;
            vz = -0.1;
            bz = 0.87;
            flash++;
          } else {
            _resolveMiss();
          }
        }
      }
      if (bz > 1.3 || by > 220) _resolveMiss();
    }

    if (mounted) setState(() {});
  }

  void _registerScore({required bool bank}) {
    ballLive = false;
    while (scores.length <= current) scores.add(0);
    scores[current]++;
    flash++;
    netBurst = 1;
    cameraZoom = 1.05;
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
    Future<void>.delayed(const Duration(milliseconds: 650), () {
      if (!mounted || showResult) return;
      _resetBall();
      current = (current + 1) % logicalPlayers;
      setState(() {});
      if (vsCpu && current == _cpuIndex) _scheduleCpuShot();
    });
  }

  void _cpuLaunch() {
    final err = (rng.nextDouble() - 0.5) * 55;
    final targetX = hoopSway + err;
    vz = 0.82 + rng.nextDouble() * 0.2;
    final t = 1.05 / vz;
    vx = targetX / t;
    vy = -260 - rng.nextDouble() * 80;
    ballLive = true;
  }

  void _scheduleCpuShot() {
    Future<void>.delayed(const Duration(milliseconds: 850), () {
      if (!mounted || showResult || ballLive || current != _cpuIndex) return;
      _cpuLaunch();
    });
  }

  void _onPanStart(DragStartDetails d) {
    if (ballLive || showResult || (current == _cpuIndex && vsCpu)) return;
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
    _launchFromSwipe(dragPull, d.velocity);
  }

  String _banner(AppState app) {
    if (vsCpu) {
      final who = current == 0 ? 'YOU' : 'CPU';
      return '$who · first to $_maxScore · ${scores[0]}-${scores[1]}';
    }
    return '${PartyTheme.playerName(current)} · swipe up toward hoop';
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    while (scores.length < logicalPlayers) scores.add(0);
    final winner = scores.isEmpty ? 0 : scores.indexOf(scores.reduce(max));
    final winnerLabel = vsCpu ? (winner == 0 ? 'You beat CPU!' : 'CPU wins') : '${PartyTheme.playerName(winner)} wins!';
    final preview = _previewVel();

    return Scaffold(
      backgroundColor: const Color(0xFF8ECAE6),
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
                          shotClock: shotClock.ceil(),
                          ballActive: ballLive,
                          ball: _BallVisual(x: bx, y: by, z: bz),
                          aimPull: dragging ? dragPull : null,
                          previewVel: preview,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
              if (dragging)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.sports_handball, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: (dragPull.distance / 140).clamp(0.0, 1.0),
                                minHeight: 12,
                                color: const Color(0xFFE85D4A),
                                backgroundColor: Colors.black12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('${(dragPull.distance).toInt()}', style: const TextStyle(fontWeight: FontWeight.w900)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pull back, flick toward hoop',
                        style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey.shade800, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  vsCpu ? 'YOU ${scores[0]}  ·  CPU ${scores.length > 1 ? scores[1] : 0}' : 'Score: ${scores[current]}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          if (popup != null)
            Positioned(
              top: 64,
              left: 0,
              right: 0,
              child: Center(child: FloatingCallout(text: popup!, color: const Color(0xFFFFB347))),
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

class _ShotVel {
  const _ShotVel(this.vx, this.vy, this.vz);
  final double vx;
  final double vy;
  final double vz;
  static const zero = _ShotVel(0, 0, 0);
}

class _BallVisual {
  const _BallVisual({required this.x, required this.y, required this.z});
  final double x;
  final double y;
  final double z;
}

class _CourtPainter extends CustomPainter {
  _CourtPainter({
    required this.hoopSway,
    required this.netWave,
    required this.netBurst,
    required this.shotClock,
    required this.ballActive,
    required this.ball,
    this.aimPull,
    required this.previewVel,
  });

  final double hoopSway;
  final double netWave;
  final double netBurst;
  final int shotClock;
  final bool ballActive;
  final _BallVisual ball;
  final Offset? aimPull;
  final _ShotVel previewVel;

  Offset _project(double x, double y, double z, Size size) {
    final cx = size.width / 2;
    final floorY = size.height * 0.82;
    final hoopY = size.height * 0.26;
    final t = z.clamp(0.0, 1.2);
    final depth = 0.5 + t * 0.5;
    final py = floorY + (hoopY - floorY) * t;
    return Offset(cx + x * depth, py + y * (1 - t * 0.82));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final floorY = size.height * 0.82;

    final sky = Rect.fromLTWH(0, 0, size.width, size.height * 0.55);
    canvas.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF7EC8E3), Color(0xFFB5E4F5)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(sky),
    );
  canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.1), 22, Paint()..color = Colors.white.withOpacity(0.95));

    // Grass + fence band
    final grassY = size.height * 0.5;
    canvas.drawRect(Rect.fromLTWH(0, grassY, size.width, floorY - grassY), Paint()..color = const Color(0xFF5CB85C));
    final fencePaint = Paint()..color = Colors.grey.shade600.withOpacity(0.65)..strokeWidth = 1.2;
    for (var x = 0.0; x < size.width; x += 14) {
      canvas.drawLine(Offset(x, grassY), Offset(x, grassY + 48), fencePaint);
    }
    for (var y = grassY; y < grassY + 48; y += 10) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), fencePaint);
    }

    // Dark asphalt court
    final court = Path()
      ..moveTo(size.width * 0.06, floorY)
      ..lineTo(size.width * 0.94, floorY)
      ..lineTo(size.width * 0.7, size.height * 0.38)
      ..lineTo(size.width * 0.3, size.height * 0.38)
      ..close();
    canvas.drawPath(court, Paint()..color = const Color(0xFF2B2B2F));
    final stripe = Paint()..color = const Color(0xFFE85D4A)..strokeWidth = 2.8;
    canvas.drawPath(court, Paint()..color = const Color(0xFFE85D4A).withOpacity(0.85)..style = PaintingStyle.stroke..strokeWidth = 3);
    canvas.drawLine(Offset(cx, floorY), Offset(cx, size.height * 0.39), stripe);
    canvas.drawLine(Offset(size.width * 0.22, floorY - 6), Offset(size.width * 0.78, floorY - 6), stripe);
    canvas.drawArc(Rect.fromCenter(center: Offset(cx, floorY - 24), width: 150, height: 58), pi, pi, false, stripe);

    final hoopCenter = _project(hoopSway, -118, 1.0, size);

    // Pole
    canvas.drawRect(Rect.fromCenter(center: hoopCenter + const Offset(0, -12), width: 8, height: 90), Paint()..color = Colors.black87);

    // Backboard + timer
    final board = RRect.fromRectAndRadius(
      Rect.fromCenter(center: hoopCenter + const Offset(0, -58), width: 102, height: 64),
      const Radius.circular(4),
    );
    canvas.drawRRect(board, Paint()..color = const Color(0xFFD94F4F));
    canvas.drawRRect(board, Paint()..color = Colors.black87..style = PaintingStyle.stroke..strokeWidth = 3);
    canvas.drawRect(Rect.fromCenter(center: hoopCenter + const Offset(0, -58), width: 34, height: 26), Paint()..color = Colors.white.withOpacity(0.9));
    final timerR = RRect.fromRectAndRadius(
      Rect.fromCenter(center: hoopCenter + const Offset(0, -98), width: 44, height: 22),
      const Radius.circular(4),
    );
    canvas.drawRRect(timerR, Paint()..color = Colors.black87);
    final tp = TextPainter(
      text: TextSpan(text: '$shotClock', style: const TextStyle(color: Color(0xFFFF4444), fontWeight: FontWeight.w900, fontSize: 14)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, hoopCenter + Offset(-tp.width / 2, -108));

    canvas.drawOval(Rect.fromCenter(center: hoopCenter, width: 76, height: 20), Paint()..color = const Color(0xFFFFB02E)..style = PaintingStyle.stroke..strokeWidth = 5);

    // Net
    final netPaint = Paint()..color = Colors.white.withOpacity(0.9)..strokeWidth = 1.1;
    for (var i = -4; i <= 4; i++) {
      final sway = sin(netWave + i * 0.55) * (3 + netBurst * 16);
      final x0 = hoopCenter.dx + i * 8.2;
      canvas.drawLine(Offset(x0, hoopCenter.dy + 3), Offset(x0 + sway, hoopCenter.dy + 38 + netBurst * 14), netPaint);
    }
    for (var row = 0; row < 5; row++) {
      final y = hoopCenter.dy + 6 + row * 7.5 + netBurst * 5;
      canvas.drawLine(Offset(hoopCenter.dx - 30, y), Offset(hoopCenter.dx + 30, y), netPaint);
    }
    for (var row = 0; row < 4; row++) {
      for (var col = -3; col <= 3; col++) {
        final x = hoopCenter.dx + col * 8.2 + sin(netWave + col) * 2;
        final y = hoopCenter.dy + 8 + row * 7.5;
        canvas.drawCircle(Offset(x, y), 0.8, netPaint);
      }
    }

    // Arc preview
    if (aimPull != null && aimPull!.distance > 10 && previewVel.vz > 0) {
      var px = 0.0;
      var py = 40.0;
      var pz = 0.0;
      var pvx = previewVel.vx;
      var pvy = previewVel.vy;
      final dotPaint = Paint()..color = Colors.yellowAccent.withOpacity(0.75);
      for (var step = 0; step < 14; step++) {
        pvy += 880 * 0.03;
        px += pvx * 0.03;
        py += pvy * 0.03;
        pz += previewVel.vz * 0.03;
        final pt = _project(px, py, pz, size);
        canvas.drawCircle(pt, 3.5 - step * 0.12, dotPaint);
      }
      final start = _project(0, 40, 0, size);
      final pull = aimPull!;
      canvas.drawLine(start, start + Offset(-pull.dx * 0.35, -pull.dy * 0.35), Paint()..color = Colors.orangeAccent..strokeWidth = 2.5);
    }

    final bpos = !ballActive && ball.z <= 0.001 ? _project(0, 40, 0, size) : _project(ball.x, ball.y, ball.z, size);
    final radius = (20 + ball.z * 14) * (0.5 + ball.z * 0.5 + 0.5);
    canvas.drawOval(
      Rect.fromCenter(center: bpos + const Offset(0, 18), width: radius * 1.6, height: radius * 0.45),
      Paint()..color = Colors.black.withOpacity(0.22),
    );
    canvas.drawCircle(
      bpos,
      radius,
      Paint()
        ..shader = const RadialGradient(colors: [Color(0xFFFF9A3C), Color(0xFFE85D00)]).createShader(Rect.fromCircle(center: bpos, radius: radius)),
    );
    canvas.drawCircle(bpos, radius, Paint()..color = Colors.black45..style = PaintingStyle.stroke..strokeWidth = 1.6);
    canvas.drawLine(bpos - Offset(radius * 0.65, 0), bpos + Offset(radius * 0.65, 0), Paint()..color = Colors.black54..strokeWidth = 1.2);
    canvas.drawLine(bpos - Offset(0, radius * 0.65), bpos + Offset(0, radius * 0.65), Paint()..color = Colors.black54..strokeWidth = 1.2);
  }

  @override
  bool shouldRepaint(covariant _CourtPainter old) => true;
}