import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../theme.dart';
import 'game_router.dart';

class AnimalStackGame extends StatefulWidget {
  const AnimalStackGame({super.key});
  @override
  State<AnimalStackGame> createState() => _AnimalStackGameState();
}

class _AnimalStackGameState extends State<AnimalStackGame> {
  final animals = ['🐱', '🐶', '🐯', '🐮', '🐸', '🐧', '🦊', '🐷'];
  final stack = <double>[];
  double fallingX = 0;
  double direction = 1;
  int current = 0;
  final scores = <int>[];
  bool alive = true;
  bool showResult = false;
  Timer? ticker;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    stack.clear();
    fallingX = 0;
    direction = 1;
    alive = true;
    ticker?.cancel();
    ticker = Timer.periodic(const Duration(milliseconds: 25), (_) {
      if (!alive || !mounted) return;
      setState(() {
        fallingX += direction * 3.2;
        if (fallingX.abs() > 110) direction *= -1;
      });
    });
  }

  void _drop() {
    if (!alive) return;
    final prev = stack.isEmpty ? 0.0 : stack.last;
    if (stack.isNotEmpty && (fallingX - prev).abs() > 48) {
      setState(() => alive = false);
      ticker?.cancel();
      Future<void>.delayed(const Duration(milliseconds: 500), _finish);
      return;
    }
    setState(() => stack.add(fallingX));
    if (stack.length >= 12) _finish();
  }

  void _finish() {
    while (scores.length <= current) {
      scores.add(0);
    }
    scores[current] = stack.length;
    if (current + 1 >= context.read<AppState>().playerCount) {
      setState(() => showResult = true);
    } else {
      setState(() => current += 1);
      _start();
    }
  }

  @override
  void dispose() {
    ticker?.cancel();
    super.dispose();
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
              TurnBanner(playerIndex: current, message: '${PartyTheme.playerName(current)} · tap to drop'),
              Expanded(
                child: GestureDetector(
                  onTap: _drop,
                  child: Container(
                    color: const Color(0xFFE0F2FF),
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Positioned(
                          bottom: 30,
                          child: Container(width: 160, height: 16, color: Colors.green),
                        ),
                        for (var i = 0; i < stack.length; i++)
                          Positioned(
                            bottom: 50.0 + i * 36,
                            left: 0,
                            right: 0,
                            child: Transform.translate(
                              offset: Offset(stack[i], 0),
                              child: Center(child: Text(animals[i % animals.length], style: const TextStyle(fontSize: 30))),
                            ),
                          ),
                        if (alive)
                          Positioned(
                            top: 60,
                            left: 0,
                            right: 0,
                            child: Transform.translate(
                              offset: Offset(fallingX, 0),
                              child: Center(
                                child: Text(animals[stack.length % animals.length], style: const TextStyle(fontSize: 34)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text('Stack: ${stack.length}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              ),
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
