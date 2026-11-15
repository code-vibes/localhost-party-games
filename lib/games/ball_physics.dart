import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_state.dart';
import 'game_router.dart';
import 'turn_loop.dart';

class BallPhysicsGame extends StatefulWidget {
  const BallPhysicsGame({super.key});
  @override State<BallPhysicsGame> createState() => _BallPhysicsGameState();
}

class _BallPhysicsGameState extends State<BallPhysicsGame> with PassAndPlayMixin {
  final goals = <int>[];
  final rng = Random();

  @override void onRoundReset() => goals.clear();

  void _kick() {
    while (goals.length <= currentPlayer) goals.add(0);
    if (rng.nextDouble() > 0.35) goals[currentPlayer]++;
    if (goals[currentPlayer] >= 3) finishMatch(currentPlayer, detail: 'Hat-trick');
    else nextPlayer();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pc = context.watch<AppState>().playerCount;
    while (goals.length < pc) goals.add(0);
    return Scaffold(
      appBar: AppBar(title: const Text('Ball Physics')),
      body: Stack(children: [
        Column(children: [
          turnBanner('Flick shots past the keeper'),
          const Expanded(child: Center(child: Text('⚽', style: TextStyle(fontSize: 80)))),
          FilledButton(onPressed: _kick, child: const Text('Shoot!')),
          const SizedBox(height: 20),
        ]),
        if (resultOverlay(() {}) != null) resultOverlay(() {})!,
      ]),
    );
  }
}
