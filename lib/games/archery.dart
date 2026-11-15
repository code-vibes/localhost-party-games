import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../theme.dart';
import 'engine/game_tick.dart';
import 'engine/juice.dart';
import 'game_router.dart';

class ArcheryGame extends StatefulWidget {
  const ArcheryGame({super.key});
  @override
  State<ArcheryGame> createState() => _ArcheryGameState();
}

class _ArcheryGameState extends State<ArcheryGame> with TickerProviderStateMixin, GameTickMixin {
  double aimX = 0;
  double aimY = 0;
  double power = 0;
  bool charging = false;
  bool flying = false;
  Offset arrowPos = const Offset(0, 150);
  Offset arrowVel = Offset.zero;
  int current = 0;
  int round = 0;
  late List<int> scores;
  String lastHit = '';
  bool showResult = false;
  double wobbleT = 0;
  int flash = 0;
  static const maxRounds = 3;

  @override
  void initState() {
    super.initState();
    scores = [];
    startTick();
  }

  @override
  void onGameTick(double dt) {
    wobbleT += dt;
    if (!flying) {
      aimX = sin(wobbleT * 2.1) * 32;
      aimY = cos(wobbleT * 1.6) * 14;
      if (charging) power = min(1, power + dt * 1.1);
    } else {
      arrowVel = Offset(arrowVel.dx * 0.99, arrowVel.dy + 380 * dt);
      arrowPos += arrowVel * dt;
      if (arrowVel.dy > 40 && arrowPos.dy < 20) _scoreShot();
    }
    setState(() {});
  }

  void _scoreShot() {
    flying = false;
    final target = Offset(aimX, -40 + aimY);
    final dist = sqrt(pow(arrowPos.dx - target.dx, 2) + pow(arrowPos.dy - target.dy, 2));
    var points = 0;
  var hit = 'Miss';
    if (dist < 12) {
      points = 10;
      hit = 'Bullseye +10';
    } else if (dist < 28) {
      points = 7;
      hit = 'Inner +7';
    } else if (dist < 46) {
      points = 4;
      hit = 'White +4';
    } else if (dist < 64) {
      points = 2;
      hit = 'Outer +2';
    }
    if (points > 0) flash++;
    final n = context.read<AppState>().playerCount;
    while (scores.length < n) scores.add(0);
    scores[current] += points;
    lastHit = hit;
    power = 0;
    arrowPos = const Offset(0, 150);
    if (current + 1 >= n) {
      current = 0;
      round += 1;
      if (round >= maxRounds) showResult = true;
    } else {
      current += 1;
    }
    setState(() {});
  }

  void _fire() {
    if (flying) return;
    charging = false;
    flying = true;
    final strength = 0.4 + power * 0.6;
    arrowVel = Offset(aimX * strength * 0.8, -240 - power * 120);
    arrowPos = const Offset(0, 150);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    while (scores.length < app.playerCount) scores.add(0);
    final winner = scores.isEmpty ? 0 : scores.indexOf(scores.reduce(max));
    return Scaffold(
      appBar: AppBar(title: const Text('ARCHERY')),
      body: Stack(
        children: [
          Column(
            children: [
              TurnBanner(playerIndex: current, message: '${PartyTheme.playerName(current)} · R${min(round + 1, maxRounds)}/$maxRounds · $lastHit'),
              Expanded(
                child: GestureDetector(
                  onPanStart: (_) => setState(() => charging = true),
                  onPanEnd: (_) {
                    if (charging) _fire();
                  },
                  child: RepaintBoundary(
                    child: Container(
                      color: const Color(0xFFE5F5D4),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Transform.translate(
                            offset: Offset(aimX, -40 + aimY),
                            child: HitFlash(
                              trigger: flash,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  _ring(76, Colors.blue.withOpacity(0.28)),
                                  _ring(50, Colors.white),
                                  _ring(26, Colors.red),
                                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.yellow, shape: BoxShape.circle)),
                                ],
                              ),
                            ),
                          ),
                          Transform.translate(
                            offset: flying ? arrowPos : const Offset(0, 150),
                            child: Transform.rotate(
                              angle: flying ? atan2(arrowVel.dy, arrowVel.dx) + pi / 2 : 0,
                              child: const Icon(Icons.arrow_upward, size: 42, color: Color(0xFF5A3820)),
                            ),
                          ),
                          Positioned(left: 32, right: 32, bottom: 24, child: ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: power, minHeight: 12, color: PartyTheme.redPlayer))),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(scores.asMap().entries.map((e) => '${PartyTheme.playerName(e.key)}: ${e.value}').join(' · '), style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          if (showResult)
            ResultOverlay(
              title: '${PartyTheme.playerName(winner)} wins!',
              detail: scores.asMap().entries.map((e) => '${PartyTheme.playerName(e.key)}: ${e.value}').join(' · '),
              onAgain: () => setState(() {
                scores = List.filled(app.playerCount, 0);
                current = 0;
                round = 0;
                lastHit = '';
                showResult = false;
                flying = false;
                power = 0;
              }),
              onDone: () {
                app.awardWin(winner);
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }

  Widget _ring(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(width: 2)),
      );
}