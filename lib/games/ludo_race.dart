import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_state.dart';
import 'game_router.dart';
import 'turn_loop.dart';

class LudoRaceGame extends StatefulWidget {
  const LudoRaceGame({super.key});
  @override State<LudoRaceGame> createState() => _LudoRaceGameState();
}

class _LudoRaceGameState extends State<LudoRaceGame> with PassAndPlayMixin {
  final progress = <int>[];
  final rng = Random();

  @override void onRoundReset() => progress.clear();

  void _roll() {
    while (progress.length <= currentPlayer) progress.add(0);
    progress[currentPlayer] += rng.nextInt(6) + 1;
    if (progress[currentPlayer] >= 24) finishMatch(currentPlayer, detail: 'Lap complete');
    else nextPlayer();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pc = context.watch<AppState>().playerCount;
    while (progress.length < pc) progress.add(0);
    return Scaffold(
      appBar: AppBar(title: const Text('Ludo Race')),
      body: Stack(children: [
        Column(children: [
          turnBanner('Roll and sprint around the loop'),
          Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (var i = 0; i < pc; i++) Text('P${i + 1}: space ${progress[i]} / 24', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ]))),
          FilledButton(onPressed: _roll, child: const Text('Roll die')),
          const SizedBox(height: 20),
        ]),
        if (resultOverlay(() {}) != null) resultOverlay(() {})!,
      ]),
    );
  }
}
