import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_state.dart';
import 'game_router.dart';
import 'turn_loop.dart';

class SnakesGame extends StatefulWidget {
  const SnakesGame({super.key});
  @override State<SnakesGame> createState() => _SnakesGameState();
}

class _SnakesGameState extends State<SnakesGame> with PassAndPlayMixin {
  final lengths = <int>[];
  final rng = Random();

  @override void onRoundReset() { lengths.clear(); }

  void _grow() {
    while (lengths.length <= currentPlayer) lengths.add(3);
    lengths[currentPlayer] += rng.nextInt(3) + 1;
    if (lengths[currentPlayer] >= 18) finishMatch(currentPlayer, detail: 'Longest neon snake');
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
          turnBanner('Tap to stretch your snake'),
          Expanded(child: Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < pc; i++) Column(mainAxisSize: MainAxisSize.min, children: [
              Text('P${i + 1}', style: const TextStyle(fontWeight: FontWeight.w900)),
              ...List.generate(min(lengths[i], 12), (_) => const Text('🟦', style: TextStyle(fontSize: 18))),
              if (lengths[i] > 12) Text('+${lengths[i] - 12}')
            ]),
          ]))),
          FilledButton(onPressed: _grow, child: const Text('Slither +')),
          const SizedBox(height: 20),
        ]),
        if (resultOverlay(() {}) != null) resultOverlay(() {})!,
      ]),
    );
  }
}
