import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import 'engine/game_tick.dart';
import 'engine/juice.dart';
import 'game_router.dart';
import 'turn_loop.dart';

class GravityRunGame extends StatefulWidget {
  const GravityRunGame({super.key});
  @override
  State<GravityRunGame> createState() => _GravityRunGameState();
}

class _GravityRunGameState extends State<GravityRunGame> with TickerProviderStateMixin, GameTickMixin, PassAndPlayMixin {
  final progress = <double>[];
  double runnerY = 0;
  double vy = 0;
  bool thrust = false;
  final gaps = <double>[];
  double scroll = 0;
  int passed = 0;

  @override
  void initState() {
    super.initState();
    _resetRun();
    startTick();
  }

  @override
  void onRoundReset() {
    progress.clear();
    _resetRun();
  }

  void _resetRun() {
    runnerY = 0;
    vy = 0;
    thrust = false;
    scroll = 0;
    passed = 0;
    gaps
      ..clear()
      ..addAll(List.generate(8, (i) => 40 + (i * 37) % 90));
  }

  @override
  void onGameTick(double dt) {
    scroll += 120 * dt;
    final g = thrust ? -420.0 : 520.0;
    vy += g * dt;
    vy = vy.clamp(-280.0, 360.0);
    runnerY += vy * dt;
    runnerY = runnerY.clamp(-120.0, 90.0);
    for (var i = 0; i < gaps.length; i++) {
      final holeX = i * 140 - scroll % 140;
      if (holeX < -20 && holeX > -40) {
        gaps[i] = 30 + Random().nextDouble() * 70;
      }
      if ((holeX - 20).abs() < 14 && runnerY > gaps[i] && runnerY < gaps[i] + 50 && vy > 0) {
        passed++;
        if (passed >= 6) finishMatch(currentPlayer, detail: 'Threaded six gates');
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pc = context.watch<AppState>().playerCount;
    while (progress.length < pc) progress.add(0);
    return Scaffold(
      appBar: AppBar(title: const Text('Gravity Run')),
      body: Stack(children: [
        Column(children: [
          turnBanner('Hold to rise, release to fall through gaps'),
          Expanded(
            child: Listener(
              onPointerDown: (_) => thrust = true,
              onPointerUp: (_) => thrust = false,
              child: RepaintBoundary(
                child: Container(
                  decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFD9F7BE), Color(0xFF8BBF6A)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                  child: CustomPaint(painter: _RunPainter(runnerY: runnerY, scroll: scroll, gaps: gaps), child: const SizedBox.expand()),
                ),
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: Text('Gates: $passed/6', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20))),
        ]),
        if (resultOverlay(_resetRun) != null) resultOverlay(_resetRun)!,
      ]),
    );
  }
}

class _RunPainter extends CustomPainter {
  _RunPainter({required this.runnerY, required this.scroll, required this.gaps});
  final double runnerY;
  final double scroll;
  final List<double> gaps;

  @override
  void paint(Canvas canvas, Size size) {
    final ground = Paint()..color = const Color(0xFF5E4028);
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28), ground);
    for (var i = 0; i < gaps.length; i++) {
      final x = (i * 140 - scroll % (gaps.length * 140)) % size.width;
      canvas.drawRect(Rect.fromLTWH(x, size.height * 0.72, 48, 18), Paint()..color = Colors.black54);
      canvas.drawRect(Rect.fromLTWH(x, size.height * 0.72 + gaps[i % gaps.length] + 30, 48, size.height), Paint()..color = Colors.transparent);
    }
    final bird = Offset(64, size.height * 0.45 + runnerY);
    canvas.drawCircle(bird, 16, Paint()..color = const Color(0xFF2E73F2));
    canvas.drawCircle(bird + const Offset(10, -6), 6, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _RunPainter old) => old.runnerY != runnerY || old.scroll != scroll;
}