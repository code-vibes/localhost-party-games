import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_state.dart';
import 'game_router.dart';
import 'turn_loop.dart';

class SolitaireLiteGame extends StatefulWidget {
  const SolitaireLiteGame({super.key});
  @override State<SolitaireLiteGame> createState() => _SolitaireLiteGameState();
}

class _SolitaireLiteGameState extends State<SolitaireLiteGame> with PassAndPlayMixin {
  final pairs = <int>[];
  final cards = ['🂡', '🂱', '🂲', '🂳', '🂴', '🂵'];
  final open = <int>{};
  int? first;
  final rng = Random();

  @override void onRoundReset() { pairs.clear(); open.clear(); first = null; }

  void _flip(int i) {
    if (open.contains(i)) return;
    if (first == null) { setState(() => first = i); return; }
    if (cards[first!] == cards[i]) {
      open.addAll([first!, i]);
      while (pairs.length <= currentPlayer) pairs.add(0);
      pairs[currentPlayer]++;
      if (pairs[currentPlayer] >= 2) finishMatch(currentPlayer, detail: 'Matched the deck');
      else nextPlayer();
    }
    setState(() => first = null);
  }

  @override
  Widget build(BuildContext context) {
    final pc = context.watch<AppState>().playerCount;
    while (pairs.length < pc) pairs.add(0);
    return Scaffold(
      appBar: AppBar(title: const Text('Solitaire Lite')),
      body: Stack(children: [
        Column(children: [
          turnBanner('Find matching card pairs'),
          Expanded(child: GridView.count(crossAxisCount: 3, padding: const EdgeInsets.all(24), children: [
            for (var i = 0; i < cards.length; i++) ElevatedButton(
              onPressed: () => _flip(i),
              child: Text(open.contains(i) || first == i ? cards[i] : '🂠', style: const TextStyle(fontSize: 24)),
            ),
          ])),
        ]),
        if (resultOverlay(() { open.clear(); first = null; }) != null) resultOverlay(() { open.clear(); first = null; })!,
      ]),
    );
  }
}
