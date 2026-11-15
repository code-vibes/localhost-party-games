import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_state.dart';
import 'game_router.dart';
import 'turn_loop.dart';

class SeaBattleGame extends StatefulWidget {
  const SeaBattleGame({super.key});
  @override State<SeaBattleGame> createState() => _SeaBattleGameState();
}

class _SeaBattleGameState extends State<SeaBattleGame> with PassAndPlayMixin {
  final hits = <int>[];
  final rng = Random();
  final cells = List<bool>.generate(16, (_) => false);

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 4; i++) cells[rng.nextInt(16)] = true;
  }

  @override void onRoundReset() {
    hits.clear();
    for (var i = 0; i < cells.length; i++) cells[i] = false;
    for (var i = 0; i < 4; i++) cells[rng.nextInt(16)] = true;
  }

  void _fire(int i) {
    while (hits.length <= currentPlayer) hits.add(0);
    if (cells[i]) { hits[currentPlayer]++; cells[i] = false; }
    if (hits[currentPlayer] >= 3) finishMatch(currentPlayer, detail: 'Three naval hits');
    else nextPlayer();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pc = context.watch<AppState>().playerCount;
    while (hits.length < pc) hits.add(0);
    return Scaffold(
      appBar: AppBar(title: const Text('Sea Battle')),
      body: Stack(children: [
        Column(children: [
          turnBanner('Tap grid cells to hunt ships'),
          Expanded(child: GridView.count(crossAxisCount: 4, padding: const EdgeInsets.all(24), children: [
            for (var i = 0; i < 16; i++) ElevatedButton(onPressed: () => _fire(i), child: Text(cells[i] ? '🚢' : '💧')),
          ])),
        ]),
        if (resultOverlay(onRoundReset) != null) resultOverlay(onRoundReset)!,
      ]),
    );
  }
}
