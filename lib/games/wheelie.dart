import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../theme.dart';
import 'game_router.dart';

class WheelieGame extends StatefulWidget {
  const WheelieGame({super.key});
  @override
  State<WheelieGame> createState() => _WheelieGameState();
}

class _WheelieGameState extends State<WheelieGame> {
  double balance = 0.45;
  double velocity = 0;
  bool holding = false;
  bool alive = true;
  double elapsed = 0;
  int current = 0;
  final scores = <double>[];
  Timer? timer;
  bool showResult = false;
  final rng = Random();

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    balance = 0.45;
    velocity = 0;
    elapsed = 0;
    alive = true;
    holding = false;
    timer?.cancel();
    timer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (!alive || !mounted) return;
      setState(() {
        final force = holding ? -0.012 : 0.010;
        velocity += force + (rng.nextDouble() - 0.5) * 0.008;
        balance = (balance + velocity).clamp(0.0, 1.0);
        elapsed += 0.033;
        if (balance <= 0.02 || balance >= 0.98) {
          alive = false;
          holding = false;
          timer?.cancel();
        }
      });
    });
  }

  void _advance() {
    while (scores.length <= current) {
      scores.add(0);
    }
    scores[current] = elapsed;
    if (current + 1 >= context.read<AppState>().playerCount) {
      setState(() => showResult = true);
    } else {
      setState(() {
        current += 1;
      });
      _start();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final winner = scores.isEmpty ? 0 : scores.indexOf(scores.reduce(max));
    return Scaffold(
      appBar: AppBar(title: const Text('WHEELIE')),
      body: Stack(
        children: [
          Column(
            children: [
              TurnBanner(
                playerIndex: current,
                message: alive
                    ? '${PartyTheme.playerName(current)} · hold in the green zone'
                    : 'Crashed!',
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFB3E0FF), Color(0xFF9A9A9A)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            Container(height: 14, decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.circular(20))),
                            Positioned(left: 90, child: Container(width: 70, height: 14, color: Colors.green.withOpacity(0.7))),
                            Positioned(
                              left: balance * 220,
                              child: const CircleAvatar(radius: 9, backgroundColor: PartyTheme.redPlayer),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Transform.rotate(
                        angle: (balance * 55 - 20) * pi / 180,
                        child: const Icon(Icons.two_wheeler, size: 80, color: PartyTheme.redPlayer),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              Text(elapsed.toStringAsFixed(1) + 's',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTapDown: (_) {
                    if (alive) setState(() => holding = true);
                  },
                  onTapUp: (_) {
                    setState(() => holding = false);
                    if (!alive) _advance();
                  },
                  onTapCancel: () => setState(() => holding = false),
                  child: Container(
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: holding ? PartyTheme.redPlayer : PartyTheme.ink,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(alive ? 'HOLD' : 'NEXT',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                  ),
                ),
              ),
            ],
          ),
          if (showResult)
            ResultOverlay(
              title: '${PartyTheme.playerName(winner)} wins!',
              detail: scores.asMap().entries.map((e) => '${PartyTheme.playerName(e.key)}: ${e.value.toStringAsFixed(1)}s').join(' · '),
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
