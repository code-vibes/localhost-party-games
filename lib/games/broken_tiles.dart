import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import 'engine/game_tick.dart';
import 'engine/juice.dart';
import 'game_router.dart';
import 'turn_loop.dart';

class BrokenTilesGame extends StatefulWidget {
  const BrokenTilesGame({super.key});
  @override State<BrokenTilesGame> createState() => _BrokenTilesGameState();
}

class _BrokenTilesGameState extends State<BrokenTilesGame> with TickerProviderStateMixin, GameTickMixin, PassAndPlayMixin {
  final saved = <int>[];
  final alive = List<bool>.generate(12, (_) => true);
  final crack = List<double>.generate(12, (_) => 0);
  int flash = 0;

  @override
  void initState() {
    super.initState();
    startTick();
  }

  @override void onRoundReset() {
    saved.clear();
    for (var i = 0; i < alive.length; i++) {
      alive[i] = true;
      crack[i] = 0;
    }
  }

  @override
  void onGameTick(double dt) {
    final i = Random().nextInt(12);
    if (alive[i]) crack[i] += dt * 0.9;
    if (crack[i] >= 1) {
      alive[i] = false;
      crack[i] = 0;
    }
    setState(() {});
  }

  void _tap(int i) {
    if (!alive[i] || crack[i] > 0.85) return;
    while (saved.length <= currentPlayer) saved.add(0);
    saved[currentPlayer]++;
    flash++;
    crack[i] = 0;
    if (saved[currentPlayer] >= 6) finishMatch(currentPlayer, detail: 'Saved six tiles');
    else nextPlayer();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pc = context.watch<AppState>().playerCount;
    while (saved.length < pc) saved.add(0);
    return Scaffold(
      appBar: AppBar(title: const Text('Broken Tiles')),
      body: Stack(children: [
        Column(children: [
          turnBanner('Tap before the crack spreads'),
          Expanded(
            child: GridView.count(
              crossAxisCount: 4,
              padding: const EdgeInsets.all(20),
              children: [
                for (var i = 0; i < 12; i++)
                  GestureDetector(
                    onTap: () => _tap(i),
                    child: HitFlash(
                      trigger: flash + i,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        margin: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: alive[i] ? Color.lerp(Colors.cyan.shade200, Colors.grey.shade600, crack[i]) : Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: alive[i] ? [BoxShadow(color: Colors.cyan.withOpacity(0.3), blurRadius: 6)] : null,
                        ),
                        child: Center(child: Text(alive[i] ? '🧊' : '💥', style: const TextStyle(fontSize: 26))),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ]),
        if (resultOverlay(onRoundReset) != null) resultOverlay(onRoundReset)!,
      ]),
    );
  }
}