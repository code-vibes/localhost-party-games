import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import 'engine/game_tick.dart';
import 'engine/juice.dart';
import 'game_router.dart';
import 'turn_loop.dart';

class BallPhysicsGame extends StatefulWidget {
  const BallPhysicsGame({super.key});
  @override
  State<BallPhysicsGame> createState() => _BallPhysicsGameState();
}

class _BallPhysicsGameState extends State<BallPhysicsGame> with TickerProviderStateMixin, GameTickMixin, PassAndPlayMixin {
  final goals = <int>[];
  Offset ball = const Offset(40, 0);
  Offset vel = Offset.zero;
  bool kicked = false;
  double keeperX = 0;
  int flash = 0;
  String? popup;

  @override
  void initState() {
    super.initState();
    startTick();
  }

  @override
  void onRoundReset() {
    goals.clear();
    _resetBall();
  }

  void _resetBall() {
    ball = const Offset(40, 0);
    vel = Offset.zero;
    kicked = false;
    keeperX = 0;
    popup = null;
  }

  @override
  void onGameTick(double dt) {
    keeperX += sin(DateTime.now().millisecondsSinceEpoch / 400.0) * 80 * dt;
    if (kicked) {
      vel = Offset(vel.dx * 0.992, vel.dy + 620 * dt);
      ball += vel * dt;
      if (ball.dx > 200 && ball.dx < 260 && ball.dy < -80 && ball.dy > -120 && (ball.dx - keeperX).abs() > 35) {
        while (goals.length <= currentPlayer) goals.add(0);
        goals[currentPlayer]++;
        flash++;
        popup = 'GOAL!';
        kicked = false;
        if (goals[currentPlayer] >= 3) finishMatch(currentPlayer, detail: 'Hat-trick');
        else {
          nextPlayer();
          _resetBall();
        }
      } else if (ball.dy > 60 || ball.dx > 300) {
        popup = 'Saved';
        kicked = false;
        nextPlayer();
        _resetBall();
      }
    }
    setState(() {});
  }

  void _kick(Offset v) {
    if (kicked) return;
    vel = Offset(v.dx * 0.04 + 220, v.dy * 0.04 - 380);
    kicked = true;
    setState(() => popup = null);
  }

  @override
  Widget build(BuildContext context) {
    final pc = context.watch<AppState>().playerCount;
    while (goals.length < pc) goals.add(0);
    return Scaffold(
      appBar: AppBar(title: const Text('Ball Physics')),
      body: Stack(children: [
        Column(children: [
          turnBanner('Flick toward the net — beat the keeper'),
          Expanded(
            child: GestureDetector(
              onPanEnd: (d) => _kick(d.velocity.pixelsPerSecond),
              child: RepaintBoundary(
                child: Container(
                  decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF8EE07A), Color(0xFF3E8A3A)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                  child: Stack(children: [
                    Positioned(top: 60, left: 200, child: Container(width: 90, height: 50, color: Colors.white24)),
                    Positioned(top: 105, left: keeperX + 210, child: const Text('🧤', style: TextStyle(fontSize: 36))),
                    Positioned(left: ball.dx, bottom: 120 - ball.dy, child: HitFlash(trigger: flash, child: const Text('⚽', style: TextStyle(fontSize: 42)))),
                    if (popup != null) Positioned(top: 24, left: 0, right: 0, child: Center(child: FloatingCallout(text: popup!))),
                  ]),
                ),
              ),
            ),
          ),
        ]),
        if (resultOverlay(_resetBall) != null) resultOverlay(_resetBall)!,
      ]),
    );
  }
}