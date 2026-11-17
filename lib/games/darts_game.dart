import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import 'engine/game_tick.dart';
import 'engine/juice.dart';
import 'game_router.dart';
import 'turn_loop.dart';

class DartsGame extends StatefulWidget {
  const DartsGame({super.key});
  @override
  State<DartsGame> createState() => _DartsGameState();
}

class _DartsGameState extends State<DartsGame> with TickerProviderStateMixin, GameTickMixin, PassAndPlayMixin {
  final totals = <int>[];
  Offset drag = Offset.zero;
  Offset dartPos = const Offset(150, 280);
  Offset dartVel = Offset.zero;
  bool flying = false;
  int flash = 0;
  static const board = Offset(150, 150);

  @override
  void initState() {
    super.initState();
    startTick();
  }

  @override
  void onRoundReset() {
    totals.clear();
    _resetDart();
  }

  void _resetDart() {
    dartPos = const Offset(150, 280);
    dartVel = Offset.zero;
    flying = false;
    drag = Offset.zero;
  }

  @override
  void onGameTick(double dt) {
    if (!flying) return;
    dartVel *= 0.985;
    dartPos += dartVel * dt;
    if (dartVel.distance < 40) {
      flying = false;
      _score();
    }
    setState(() {});
  }

  void _score() {
    final dist = (dartPos - board).distance;
    final score = max(0, (50 - dist / 3).round());
    while (totals.length <= currentPlayer) totals.add(0);
    totals[currentPlayer] += score;
    if (score > 15) flash++;
    if (totals[currentPlayer] >= 120) {
      finishMatch(currentPlayer, detail: '$score pts — board cleared');
    } else {
      nextPlayer();
      _resetDart();
    }
    setState(() {});
  }

  void _throw() {
    if (flying) return;
    flying = true;
    dartVel = Offset(-drag.dx * 2.2, -drag.dy * 2.2 - 180);
    setState(() => drag = Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    final pc = context.watch<AppState>().playerCount;
    while (totals.length < pc) totals.add(0);
    return Scaffold(
      appBar: AppBar(title: const Text('Darts')),
      body: Stack(children: [
        Column(children: [
          turnBanner('Drag back, release — first to 120'),
          Expanded(
            child: GestureDetector(
              onPanUpdate: (d) => setState(() => drag += d.delta),
              onPanEnd: (_) => _throw(),
              child: RepaintBoundary(
                child: Container(
                  color: const Color(0xFF2A2535),
                  child: CustomPaint(
                    painter: _DartBoardPainter(dart: dartPos, board: board, flash: flash),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
          Text('P${currentPlayer + 1}: ${totals.length > currentPlayer ? totals[currentPlayer] : 0}', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 12),
        ]),
        if (resultOverlay(_resetDart) != null) resultOverlay(_resetDart)!,
      ]),
    );
  }
}

class _DartBoardPainter extends CustomPainter {
  _DartBoardPainter({required this.dart, required this.board, required this.flash});
  final Offset dart;
  final Offset board;
  final int flash;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(board, 70, Paint()..color = Colors.green.shade900);
    canvas.drawCircle(board, 52, Paint()..color = Colors.black);
    canvas.drawCircle(board, 34, Paint()..color = Colors.red);
    canvas.drawCircle(board, 12, Paint()..color = Colors.yellow);
    canvas.drawCircle(dart, 6, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _DartBoardPainter old) => old.dart != dart || old.flash != flash;
}