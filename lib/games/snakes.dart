import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../theme.dart';
import 'engine/game_tick.dart';
import 'engine/juice.dart';
import 'game_router.dart';
import 'turn_loop.dart';

class SnakesGame extends StatefulWidget {
  const SnakesGame({super.key});
  @override State<SnakesGame> createState() => _SnakesGameState();
}

class _SnakesGameState extends State<SnakesGame> with TickerProviderStateMixin, GameTickMixin, PassAndPlayMixin {
  final lengths = <double>[];
  final headX = <double>[];
  final dirs = <double>[];
  int flash = 0;

  @override
  void initState() {
    super.initState();
    startTick();
  }

  @override
  void onRoundReset() {
    lengths.clear();
    headX.clear();
    dirs.clear();
  }

  @override
  void onGameTick(double dt) {
    final pc = context.read<AppState>().playerCount;
    while (lengths.length < pc) {
      lengths.add(3);
      headX.add(0);
      dirs.add(1);
    }
    for (var i = 0; i < pc; i++) {
      headX[i] += dirs[i] * 90 * dt;
      if (headX[i].abs() > 120) {
        dirs[i] *= -1;
        lengths[i] -= 0.4;
        if (lengths[i] <= 0) lengths[i] = 0;
      }
    }
    setState(() {});
  }

  void _boost() {
    while (lengths.length <= currentPlayer) lengths.add(3);
    lengths[currentPlayer] += 1.6;
    flash++;
    if (lengths[currentPlayer] >= 16) finishMatch(currentPlayer, detail: 'Neon king snake');
    else nextPlayer();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pc = context.watch<AppState>().playerCount;
    while (lengths.length < pc) lengths.add(3);
    return Scaffold(
      appBar: AppBar(title: const Text('Snakes')),
      body: Stack(children: [
        Column(children: [
          turnBanner('Tap to surge — dodge the walls'),
          Expanded(
            child: RepaintBoundary(
              child: Container(
                color: const Color(0xFF101828),
                child: CustomPaint(painter: _SnakePainter(lengths: lengths, headX: headX, colors: List.generate(pc, PartyTheme.playerColor)), child: const SizedBox.expand()),
              ),
            ),
          ),
          JuiceButton(label: 'SLITHER', color: PartyTheme.playerColor(currentPlayer), onPressed: _boost),
          const SizedBox(height: 16),
        ]),
        if (resultOverlay(() {}) != null) resultOverlay(() {})!,
      ]),
    );
  }
}

class _SnakePainter extends CustomPainter {
  _SnakePainter({required this.lengths, required this.headX, required this.colors});
  final List<double> lengths;
  final List<double> headX;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;
    for (var p = 0; p < lengths.length; p++) {
      final segs = lengths[p].clamp(0, 20).floor();
      for (var s = 0; s < segs; s++) {
        final x = size.width / 2 + headX[p] - s * 14;
        final y = mid + (p - lengths.length / 2) * 50;
        canvas.drawCircle(Offset(x, y), 8, Paint()..color = colors[p % colors.length]);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SnakePainter old) => true;
}