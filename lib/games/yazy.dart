import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_state.dart';
import 'game_router.dart';
import 'turn_loop.dart';

class YazyGame extends StatefulWidget {
  const YazyGame({super.key});
  @override State<YazyGame> createState() => _YazyGameState();
}

class _YazyGameState extends State<YazyGame> with PassAndPlayMixin {
  final totals = <int>[];
  final rng = Random();
  List<int> dice = [1, 2, 3, 4, 5];

  @override void onRoundReset() { totals.clear(); dice = [1, 2, 3, 4, 5]; }

  void _roll() {
    dice = List.generate(5, (_) => rng.nextInt(6) + 1);
    final sum = dice.reduce((a, b) => a + b);
    while (totals.length <= currentPlayer) totals.add(0);
    totals[currentPlayer] += sum;
    if (totals[currentPlayer] >= 120) finishMatch(currentPlayer, detail: '${totals[currentPlayer]} on the sheet');
    else nextPlayer();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pc = context.watch<AppState>().playerCount;
    while (totals.length < pc) totals.add(0);
    return Scaffold(
      appBar: AppBar(title: const Text('Yazy')),
      body: Stack(children: [
        Column(children: [
          turnBanner('Roll five dice — race to 120'),
          Wrap(spacing: 8, children: [for (final d in dice) Chip(label: Text('$d', style: const TextStyle(fontSize: 18)))]),
          FilledButton(onPressed: _roll, child: const Text('Roll')),
          const SizedBox(height: 20),
        ]),
        if (resultOverlay(() {}) != null) resultOverlay(() {})!,
      ]),
    );
  }
}
