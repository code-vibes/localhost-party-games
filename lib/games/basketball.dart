import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../theme.dart';
import 'engine/game_tick.dart';
import 'engine/juice.dart';
import 'game_router.dart';

class BasketballGame extends StatefulWidget {
  const BasketballGame({super.key});
  @override
  State<BasketballGame> createState() => _BasketballGameState();
}

class _BasketballGameState extends State<BasketballGame> with TickerProviderStateMixin, GameTickMixin {
  final scores = <int>[];
  int current = 0;
  double timeLeft = 12;
  double hoopX = 0;
  double hoopPhase = 0;
  Offset ball = const Offset(0, 110);
  Offset vel = Offset.zero;
  bool airborne = false;
  bool showResult = false;
  int flash = 0;
  String? popup;
  final rng = Random();

  @override
  void initState() {
    super.initState();
    startTick();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startTurn());
  }

  void _startTurn() {
    while (scores.length <= current) scores.add(0);
    timeLeft = 12;
    ball = const Offset(0, 110);
    vel = Offset.zero;
    airborne = false;
    popup = null;
    hoopX = rng.nextDouble() * 180 - 90;
  }

  @override
  void onGameTick(double dt) {
    hoopPhase += dt;
    hoopX += sin(hoopPhase * 1.4) * 45 * dt;
    if (!airborne && timeLeft > 0) timeLeft -= dt;
    if (timeLeft <= 0 && !airborne) {
      _endTurn();
      return;
    }
    if (airborne) {
      vel = Offset(vel.dx * 0.995, vel.dy + 900 * dt);
      ball += vel * dt;
      final hoop = Offset(hoopX, -85);
      if (ball.dy < hoop.dy + 10 && ball.dy > hoop.dy - 30 && (ball.dx - hoop.dx).abs() < 28 && vel.dy > 0) {
        scores[current]++;
        flash++;
        popup = 'SWISH!';
        airborne = false;
        ball = const Offset(0, 110);
        vel = Offset.zero;
      } else if (ball.dy > 140) {
        popup = 'Rim out';
        airborne = false;
        ball = const Offset(0, 110);
        vel = Offset.zero;
      }
    }
    if (mounted) setState(() {});
  }

  void _shoot(Offset velocity) {
    if (airborne || timeLeft <= 0) return;
    vel = Offset(velocity.dx * 0.05, velocity.dy * 0.05 - 420);
    airborne = true;
    setState(() => popup = null);
  }

  void _endTurn() {
    airborne = false;
    if (current + 1 >= context.read<AppState>().playerCount) {
      setState(() => showResult = true);
    } else {
      setState(() => current += 1);
      _startTurn();
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final winner = scores.isEmpty ? 0 : scores.indexOf(scores.reduce(max));
    return Scaffold(
      appBar: AppBar(title: const Text('BASKETBALL HOOPS')),
      body: Stack(
        children: [
          Column(
            children: [
              TurnBanner(playerIndex: current, message: '${PartyTheme.playerName(current)} · flick up · ${timeLeft.ceil()}s'),
              Expanded(
                child: GestureDetector(
                  onPanEnd: (d) => _shoot(d.velocity.pixelsPerSecond),
                  child: RepaintBoundary(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF9FD4FF), Color(0xFFE9F5FF)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Transform.translate(
                            offset: Offset(hoopX, -85),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(width: 92, height: 56, color: Colors.red.shade700),
                                Container(
                                  width: 66,
                                  height: 66,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.orange, width: 6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Transform.translate(
                            offset: ball,
                            child: HitFlash(
                              trigger: flash,
                              child: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(colors: [Colors.orange.shade300, Colors.deepOrange]),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black54, width: 2),
                                ),
                              ),
                            ),
                          ),
                          if (popup != null) Positioned(top: 18, child: FloatingCallout(text: popup!)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Text('Score: ${scores.length > current ? scores[current] : 0}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
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
                _startTurn();
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