import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_state.dart';
import '../theme.dart';
import 'game_router.dart';
import 'turn_loop.dart';

class TripleMatchGame extends StatefulWidget {
  const TripleMatchGame({super.key});
  @override State<TripleMatchGame> createState() => _TripleMatchGameState();
}

class _TripleMatchGameState extends State<TripleMatchGame> with PassAndPlayMixin {
  final rng = Random();
  final symbols = ['◇', '○', '△', '★'];
  final counts = <int>[];
  int picks = 0;
  String? pickA;
  String? pickB;

  @override void onRoundReset() { counts.clear(); picks = 0; pickA = pickB = null; }

  void _tap(String s) {
    if (pickA == null) { setState(() => pickA = s); return; }
    if (pickB == null) { setState(() => pickB = s); }
    if (pickA == pickB) {
      while (counts.length <= currentPlayer) counts.add(0);
      counts[currentPlayer] += 1;
      if (counts[currentPlayer] >= 5) finishMatch(currentPlayer, detail: 'Matched five triples');
      else nextPlayer();
    }
    setState(() { pickA = pickB = null; picks++; });
  }

  @override
  Widget build(BuildContext context) {
    final pc = context.watch<AppState>().playerCount;
    while (counts.length < pc) counts.add(0);
    final board = List.generate(9, (_) => symbols[rng.nextInt(symbols.length)]);
    return Scaffold(
      appBar: AppBar(title: const Text('Triple')),
      body: Stack(children: [
        Column(children: [
          turnBanner('Tap two matching symbols'),
          Expanded(child: GridView.count(crossAxisCount: 3, padding: const EdgeInsets.all(24), children: [
            for (final s in board) ElevatedButton(onPressed: () => _tap(s), child: Text(s, style: const TextStyle(fontSize: 28))),
          ])),
        ]),
        if (resultOverlay(() {}) != null) resultOverlay(() {})!,
      ]),
    );
  }
}
