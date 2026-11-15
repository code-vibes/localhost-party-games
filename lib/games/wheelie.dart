import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../theme.dart';
import 'engine/game_tick.dart';
import 'engine/juice.dart';
import 'game_router.dart';

class WheelieGame extends StatefulWidget {
  const WheelieGame({super.key});
  @override
  State<WheelieGame> createState() => _WheelieGameState();
}

class _WheelieGameState extends State<WheelieGame> with TickerProviderStateMixin, GameTickMixin {
  double balance = 0.45;
  double velocity = 0;
  bool holding = false;
  bool alive = true;
  double elapsed = 0;
  int current = 0;
  final scores = <double>[];
  bool showResult = false;
  int crashFlash = 0;
  final rng = Random();

  @override
  void initState() {
    super.initState();
    startTick();
    _start();
  }

  void _start() {
    balance = 0.45;
    velocity = 0;
    elapsed = 0;
    alive = true;
    holding = false;
    tickPaused = false;
  }

  @override
  void onGameTick(double dt) {
    if (!alive) return;
    final force = holding ? -22 : 18;
    velocity += (force + (rng.nextDouble() - 0.5) * 10) * dt;
    velocity *= 0.985;
    balance = (balance + velocity * dt).clamp(0.0, 1.0);
    elapsed += dt;
    if (balance <= 0.03 || balance >= 0.97) {
      alive = false;
      crashFlash++;
      tickPaused = true;
    }
    setState(() {});
  }

  void _advance() {
    while (scores.length <= current) scores.add(0);
    scores[current] = elapsed;
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
    final winner = scores.isEmpty ? 0 : scores.indexOf(scores.reduce(max));
    final tilt = (balance * 50 - 22) * pi / 180;
    return Scaffold(
      appBar: AppBar(title: const Text('WHEELIE')),
      body: Stack(
        children: [
          Column(
            children: [
              TurnBanner(
                playerIndex: current,
                message: alive ? '${PartyTheme.playerName(current)} · float in the green lane' : 'Spill! Tap NEXT',
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFFB3E0FF), Color(0xFF7A7A7A)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 36),
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            Container(height: 16, decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.circular(20))),
                            Positioned(left: 82, child: Container(width: 76, height: 16, decoration: BoxDecoration(color: Colors.green.withOpacity(0.75), borderRadius: BorderRadius.circular(8)))),
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 16),
                              curve: Curves.linear,
                              left: balance * 250,
                              child: Container(width: 18, height: 18, decoration: const BoxDecoration(color: PartyTheme.redPlayer, shape: BoxShape.circle, boxShadow: [BoxShadow(blurRadius: 4)])),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      HitFlash(
                        trigger: crashFlash,
                        child: Transform.rotate(
                          angle: tilt,
                          child: const Icon(Icons.two_wheeler, size: 88, color: PartyTheme.redPlayer),
                        ),
                      ),
                      if (!alive) const Padding(padding: EdgeInsets.only(top: 8), child: FloatingCallout(text: 'WIPEOUT!', color: Colors.orange)),
                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
              Text('${elapsed.toStringAsFixed(1)}s', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Listener(
                  onPointerDown: (_) {
                    if (alive) setState(() => holding = true);
                  },
                  onPointerUp: (_) {
                    setState(() => holding = false);
                    if (!alive) _advance();
                  },
                  child: JuiceButton(
                    label: alive ? 'HOLD TO LEAN' : 'NEXT RIDER',
                    color: holding ? PartyTheme.redPlayer : PartyTheme.ink,
                    onPressed: () {},
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