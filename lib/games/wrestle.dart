import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_state.dart';
import 'game_router.dart';
import 'turn_loop.dart';

class WrestleGame extends StatefulWidget {
  const WrestleGame({super.key});
  @override State<WrestleGame> createState() => _WrestleGameState();
}

class _WrestleGameState extends State<WrestleGame> with PassAndPlayMixin {
  final power = <int>[];

  @override void onRoundReset() => power.clear();

  void _mash() {
    while (power.length <= currentPlayer) power.add(0);
    power[currentPlayer]++;
    if (power[currentPlayer] >= 25) finishMatch(currentPlayer, detail: 'Pinned!');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pc = context.watch<AppState>().playerCount;
    while (power.length < pc) power.add(0);
    return Scaffold(
      appBar: AppBar(title: const Text('Wrestle')),
      body: Stack(children: [
        Column(children: [
          turnBanner('Mash PIN before the rival does'),
          Expanded(
            child: Center(
              child: FilledButton(
                onPressed: _mash,
                child: const Text('PIN!', style: TextStyle(fontSize: 28)),
              ),
            ),
          ),
          for (var i = 0; i < pc; i++) Text('P${i + 1} power: ${power[i]}'),
          const SizedBox(height: 20),
        ]),
        if (resultOverlay(() {}) != null) resultOverlay(() {})!,
      ]),
    );
  }
}
