import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_state.dart';
import 'game_router.dart';
import 'turn_loop.dart';

class GravityRunGame extends StatefulWidget {
  const GravityRunGame({super.key});
  @override State<GravityRunGame> createState() => _GravityRunGameState();
}

class _GravityRunGameState extends State<GravityRunGame> with PassAndPlayMixin {
  final prog = <int>[];
  final rng = Random();

  @override void onRoundReset() => prog.clear();

  void _boost() {
    while (prog.length <= currentPlayer) prog.add(0);
    prog[currentPlayer] += rng.nextInt(4) + 2;
    if (prog[currentPlayer] >= 30) finishMatch(currentPlayer, detail: 'Cleared the obstacle course');
    else nextPlayer();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pc = context.watch<AppState>().playerCount;
    while (prog.length < pc) prog.add(0);
    return Scaffold(
      appBar: AppBar(title: const Text('Gravity Run')),
      body: Stack(children: [
        Column(children: [
          turnBanner('Hold burst to float through gaps'),
          Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (var i = 0; i < pc; i++) LinearProgressIndicator(value: prog[i] / 30, minHeight: 12, color: Colors.indigo),
            const SizedBox(height: 8),
          ]))),
          Listener(onPointerDown: (_) => _boost(), child: const SizedBox(height: 120, child: Center(child: Text('PRESS & SURGE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20))))),
        ]),
        if (resultOverlay(() {}) != null) resultOverlay(() {})!,
      ]),
    );
  }
}
