import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import 'engine/game_tick.dart';
import 'engine/juice.dart';
import 'game_router.dart';
import 'turn_loop.dart';

class NutsBoltsGame extends StatefulWidget {
  const NutsBoltsGame({super.key});
  @override State<NutsBoltsGame> createState() => _NutsBoltsGameState();
}

class _NutsBoltsGameState extends State<NutsBoltsGame> with TickerProviderStateMixin, GameTickMixin, PassAndPlayMixin {
  final points = <int>[];
  final colors = [Colors.red, Colors.green, Colors.blue, Colors.amber];
  final nutPos = <Offset>[];
  final boltY = <double>[];
  Color target = Colors.red;
  int flash = 0;
  final rng = Random();

  @override
  void initState() {
    super.initState();
    _spawn();
    startTick();
  }

  void _spawn() {
    target = colors[rng.nextInt(colors.length)];
    nutPos
      ..clear()
      ..addAll(List.generate(3, (_) => Offset(rng.nextDouble() * 220 - 110, rng.nextDouble() * 40)));
    boltY
      ..clear()
      ..addAll(List.generate(3, (i) => 120 + i * 38.0));
  }

  @override void onRoundReset() { points.clear(); _spawn(); }

  @override
  void onGameTick(double dt) {
    for (var i = 0; i < nutPos.length; i++) {
      nutPos[i] = Offset(nutPos[i].dx, nutPos[i].dy + 60 * dt);
      if (nutPos[i].dy > boltY[i] - 8 && nutPos[i].dy < boltY[i] + 18 && (nutPos[i].dx - (-80 + i * 80)).abs() < 24) {
        nutPos[i] = Offset(nutPos[i].dx, boltY[i]);
      }
    }
    setState(() {});
  }

  void _snap(int i) {
    final boltX = -80 + i * 80.0;
    final hit = colors[i];
    nutPos[i] = Offset(boltX, boltY[i]);
    while (points.length <= currentPlayer) points.add(0);
    if (hit == target) {
      points[currentPlayer]++;
      flash++;
      if (points[currentPlayer] >= 8) finishMatch(currentPlayer, detail: 'Bolt boss');
      else {
        nextPlayer();
        _spawn();
      }
    } else {
      _spawn();
      nextPlayer();
    }
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
          turnBanner('Drop on the bolt matching the lit nut'),
          Expanded(
            child: RepaintBoundary(
              child: Container(
                color: const Color(0xFF2D1440),
                child: Stack(children: [
                  for (var i = 0; i < 3; i++)
                    Positioned(
                      left: MediaQuery.sizeOf(context).width / 2 + (-80 + i * 80) - 8,
                      top: boltY[i],
                      child: Container(width: 16, height: 80, color: Colors.grey.shade400),
                    ),
                  for (var i = 0; i < nutPos.length; i++)
                    Positioned(
                      left: MediaQuery.sizeOf(context).width / 2 + nutPos[i].dx,
                      top: 40 + nutPos[i].dy,
                      child: GestureDetector(
                        onTap: () => _snap(i),
                        child: HitFlash(
                          trigger: flash,
                          child: Container(width: 28, height: 28, decoration: BoxDecoration(color: colors[i], shape: BoxShape.circle, border: Border.all(color: colors[i] == target ? Colors.white : Colors.black26, width: 3))),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
          ),
        ]),
        if (resultOverlay(_spawn) != null) resultOverlay(_spawn)!,
      ]),
    );
  }
}