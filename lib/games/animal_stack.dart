import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../theme.dart';
import 'engine/game_tick.dart';
import 'engine/juice.dart';
import 'game_router.dart';

class AnimalStackGame extends StatefulWidget {
  const AnimalStackGame({super.key});
  @override
  State<AnimalStackGame> createState() => _AnimalStackGameState();
}

class _AnimalStackGameState extends State<AnimalStackGame> with TickerProviderStateMixin, GameTickMixin {
  final animals = ['🐱', '🐶', '🐯', '🐮', '🐸', '🐧', '🦊', '🐷'];
  final stack = <double>[];
  double fallingX = 0;
  double fallingY = -120;
  double direction = 1;
  int current = 0;
  final scores = <int>[];
  bool alive = true;
  bool dropping = false;
  bool showResult = false;
  int landFlash = 0;

  @override
  void initState() {
    super.initState();
    startTick();
    _start();
  }

  void _start() {
    stack.clear();
    fallingX = 0;
    fallingY = -120;
    direction = 1;
    alive = true;
    dropping = false;
  }

  @override
  void onGameTick(double dt) {
    if (!alive) return;
    if (!dropping) {
      fallingX += direction * 140 * dt;
      if (fallingX.abs() > 118) direction *= -1;
    } else {
      fallingY += 520 * dt;
      if (fallingY >= 0) {
        dropping = false;
        _land();
      }
    }
    setState(() {});
  }

  void _drop() {
    if (!alive || dropping) return;
    setState(() {
      dropping = true;
      fallingY = -40;
    });
  }

  void _land() {
    final prev = stack.isEmpty ? 0.0 : stack.last;
    if (stack.isNotEmpty && (fallingX - prev).abs() > 46) {
      setState(() => alive = false);
      Future<void>.delayed(const Duration(milliseconds: 400), _finish);
      return;
    }
    landFlash++;
    stack.add(fallingX);
    fallingY = -120;
    if (stack.length >= 12) _finish();
    setState(() {});
  }

  void _finish() {
    while (scores.length <= current) scores.add(0);
    scores[current] = stack.length;
    if (current + 1 >= context.read<AppState>().playerCount) {
      setState(() => showResult = true);
    } else {
      setState(() => current += 1);
      _start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final winner = scores.isEmpty ? 0 : scores.indexOf(scores.reduce((a, b) => a > b ? a : b));
    return Scaffold(
      appBar: AppBar(title: const Text('ANIMAL STACK')),
      body: Stack(
        children: [
          Column(
            children: [
              TurnBanner(playerIndex: current, message: '${PartyTheme.playerName(current)} · tap when aligned'),
              Expanded(
                child: GestureDetector(
                  onTap: _drop,
                  child: RepaintBoundary(
                    child: Container(
                      color: const Color(0xFFE0F2FF),
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Positioned(bottom: 30, child: Container(width: 180, height: 18, decoration: BoxDecoration(color: Colors.green.shade700, borderRadius: BorderRadius.circular(6)))),
                          for (var i = 0; i < stack.length; i++)
                            Positioned(
                              bottom: 52.0 + i * 36,
                              left: 0,
                              right: 0,
                              child: Transform.translate(
                                offset: Offset(stack[i], 0),
                                child: Center(child: Text(animals[i % animals.length], style: const TextStyle(fontSize: 32))),
                              ),
                            ),
                          if (alive)
                            Positioned(
                              top: 80 + fallingY,
                              left: 0,
                              right: 0,
                              child: Transform.translate(
                                offset: Offset(fallingX, 0),
                                child: Center(
                                  child: HitFlash(
                                    trigger: landFlash,
                                    child: Text(animals[stack.length % animals.length], style: TextStyle(fontSize: dropping ? 38 : 34)),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Text('Stack: ${stack.length}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
            ],
          ),
          if (showResult)
            ResultOverlay(
              title: '${PartyTheme.playerName(winner)} wins!',
              detail: scores.asMap().entries.map((e) => '${PartyTheme.playerName(e.key)}: ${e.value}').join(' · '),
              onAgain: () {
                setState(() {
                  scores.clear();
                  current = 0;
                  showResult = false;
                });
                _start();
              },
              onDone: () {
                app.awardWin(winner);
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }
}