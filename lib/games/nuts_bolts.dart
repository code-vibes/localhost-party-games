import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_state.dart';
import 'game_router.dart';
import 'turn_loop.dart';

class NutsBoltsGame extends StatefulWidget {
  const NutsBoltsGame({super.key});
  @override State<NutsBoltsGame> createState() => _NutsBoltsGameState();
}

class _NutsBoltsGameState extends State<NutsBoltsGame> with PassAndPlayMixin {
  final rng = Random();
  final points = <int>[];
  final colors = [Colors.red, Colors.green, Colors.blue, Colors.amber];
  late Color nut;
  late Color bolt;

  @override void initState() { super.initState(); _newPair(); }
  @override void onRoundReset() { points.clear(); _newPair(); }

  void _newPair() { nut = colors[rng.nextInt(colors.length)]; bolt = colors[rng.nextInt(colors.length)]; }

  void _tap(Color c) {
    while (points.length <= currentPlayer) points.add(0);
    if (c == nut) points[currentPlayer]++;
    if (points[currentPlayer] >= 8) finishMatch(currentPlayer, detail: 'Fastest assembler');
    else { nextPlayer(); _newPair(); }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pc = context.watch<AppState>().playerCount;
    while (points.length < pc) points.add(0);
    return Scaffold(
      appBar: AppBar(title: const Text('Nuts & Bolts')),
      body: Stack(children: [
        Column(children: [
          turnBanner('Match the colored nut'),
          const SizedBox(height: 40),
          Container(width: 60, height: 60, decoration: BoxDecoration(color: nut, shape: BoxShape.circle)),
          const SizedBox(height: 30),
          Wrap(spacing: 12, alignment: WrapAlignment.center, children: [
            for (final c in colors) ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: c), onPressed: () => _tap(c), child: const SizedBox(width: 40, height: 40)),
          ]),
        ]),
        if (resultOverlay(_newPair) != null) resultOverlay(_newPair)!,
      ]),
    );
  }
}
