import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_state.dart';
import '../theme.dart';
import 'game_router.dart';
import 'turn_loop.dart';

class FarkleGame extends StatefulWidget {
  const FarkleGame({super.key});
  @override
  State<FarkleGame> createState() => _FarkleGameState();
}

class _FarkleGameState extends State<FarkleGame> with PassAndPlayMixin {
  final rng = Random();
  final totals = <int>[];
  List<int> dice = [1, 1, 1, 1, 1, 1];
  int turnScore = 0;

  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {})); }

  @override
  void onRoundReset() { turnScore = 0; totals.clear(); }

  int scoreDice(List<int> d) {
    final c = List<int>.filled(7, 0);
    for (final v in d) c[v]++;
    var s = 0;
    for (var i = 1; i <= 6; i++) {
      if (c[i] >= 3) s += i == 1 ? 1000 : i * 100;
      else if (i == 1) s += c[i] * 100;
      else if (i == 5) s += c[i] * 50;
    }
    return s;
  }

  void _roll() {
    setState(() {
      dice = List.generate(6, (_) => rng.nextInt(6) + 1);
      final s = scoreDice(dice);
      if (s == 0) {
        turnScore = 0;
        nextPlayer();
      } else {
        turnScore += s;
      }
    });
  }

  void _bank() {
    while (totals.length <= currentPlayer) totals.add(0);
    totals[currentPlayer] += turnScore;
    turnScore = 0;
    final target = 1500;
  final winner = totals.indexWhere((t) => t >= target);
    if (winner >= 0) {
      finishMatch(winner, detail: '${totals[winner]} pts');
    } else {
      nextPlayer();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pc = context.watch<AppState>().playerCount;
    while (totals.length < pc) totals.add(0);
    return Scaffold(
      appBar: AppBar(title: const Text('Farkle')),
      body: Stack(children: [
        Column(children: [
          turnBanner('Roll hot dice — bank at 1500'),
          Expanded(child: Center(child: Wrap(spacing: 8, children: [
            for (final d in dice) Chip(label: Text('$d', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18))),
          ]))),
          Text('Turn +$turnScore', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            FilledButton(onPressed: _roll, child: const Text('Roll')),
            const SizedBox(width: 12),
            OutlinedButton(onPressed: turnScore > 0 ? _bank : null, child: const Text('Bank')),
          ]),
          const SizedBox(height: 12),
          for (var i = 0; i < pc; i++) Text('${PartyTheme.playerName(i)}: ${totals[i]}', style: TextStyle(fontWeight: i == currentPlayer ? FontWeight.w900 : FontWeight.w500)),
          const SizedBox(height: 16),
        ]),
        if (resultOverlay(() {}) != null) resultOverlay(() {})!,
      ]),
    );
  }
}
