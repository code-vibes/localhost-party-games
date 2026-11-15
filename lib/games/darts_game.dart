import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_state.dart';
import 'game_router.dart';
import 'turn_loop.dart';

class DartsGame extends StatefulWidget {
  const DartsGame({super.key});
  @override State<DartsGame> createState() => _DartsGameState();
}

class _DartsGameState extends State<DartsGame> with PassAndPlayMixin {
  final totals = <int>[];
  final rng = Random();
  Offset? mark;

  @override void onRoundReset() { totals.clear(); mark = null; }

  void _throw(Offset p) {
    final dist = (p - const Offset(150, 150)).distance;
    final score = max(0, 50 - dist ~/ 4);
    while (totals.length <= currentPlayer) totals.add(0);
    totals[currentPlayer] += score;
    if (totals[currentPlayer] >= 120) finishMatch(currentPlayer, detail: '${totals[currentPlayer]} pts');
    else { nextPlayer(); mark = null; }
    setState(() => mark = p);
  }

  @override
  Widget build(BuildContext context) {
    final pc = context.watch<AppState>().playerCount;
    while (totals.length < pc) totals.add(0);
    return Scaffold(
      appBar: AppBar(title: const Text('Darts')),
      body: Stack(children: [
        Column(children: [
          turnBanner('Tap the board — first to 120'),
          Expanded(child: Center(child: GestureDetector(
            onTapDown: (d) => _throw(d.localPosition),
            child: Container(width: 300, height: 300, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF2E2E3A)), child: CustomPaint(painter: _BoardPainter(mark))),
          ))),
        ]),
        if (resultOverlay(() => mark = null) != null) resultOverlay(() => mark = null)!,
      ]),
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter(this.mark);
  final Offset? mark;
  @override
  void paint(Canvas c, Size s) {
    c.drawCircle(Offset(s.width/2, s.height/2), 40, Paint()..color = Colors.red);
    c.drawCircle(Offset(s.width/2, s.height/2), 80, Paint()..color = Colors.green);
    if (mark != null) c.drawCircle(mark!, 6, Paint()..color = Colors.yellow);
  }
  @override
  bool shouldRepaint(covariant _BoardPainter old) => old.mark != mark;
}
