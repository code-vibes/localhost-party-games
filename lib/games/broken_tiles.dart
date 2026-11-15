import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_state.dart';
import 'game_router.dart';
import 'turn_loop.dart';

class BrokenTilesGame extends StatefulWidget {
  const BrokenTilesGame({super.key});
  @override State<BrokenTilesGame> createState() => _BrokenTilesGameState();
}

class _BrokenTilesGameState extends State<BrokenTilesGame> with PassAndPlayMixin {
  final saved = <int>[];
  final alive = List<bool>.generate(12, (_) => true);
  Timer? timer;

  @override void onRoundReset() { saved.clear(); for (var i = 0; i < alive.length; i++) alive[i] = true; timer?.cancel(); _tick(); }

  @override void initState() { super.initState(); _tick(); }

  void _tick() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (!mounted) return;
      final i = Random().nextInt(12);
      setState(() => alive[i] = false);
    });
  }

  void _tap(int i) {
    if (!alive[i]) return;
    while (saved.length <= currentPlayer) saved.add(0);
    saved[currentPlayer]++;
    if (saved[currentPlayer] >= 6) finishMatch(currentPlayer, detail: 'Saved six tiles');
    else nextPlayer();
    setState(() {});
  }

  @override
  void dispose() { timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final pc = context.watch<AppState>().playerCount;
    while (saved.length < pc) saved.add(0);
    return Scaffold(
      appBar: AppBar(title: const Text('Broken Tiles')),
      body: Stack(children: [
        Column(children: [
          turnBanner('Tap before the tile cracks'),
          Expanded(child: GridView.count(crossAxisCount: 4, padding: const EdgeInsets.all(20), children: [
            for (var i = 0; i < 12; i++) ElevatedButton(onPressed: alive[i] ? () => _tap(i) : null, child: Text(alive[i] ? '🧊' : '💥')),
          ])),
        ]),
        if (resultOverlay(onRoundReset) != null) resultOverlay(onRoundReset)!,
      ]),
    );
  }
}
