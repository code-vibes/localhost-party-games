import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../theme.dart';
import 'engine/game_tick.dart';
import 'engine/juice.dart';
import 'game_router.dart';

class CupPongGame extends StatefulWidget {
  const CupPongGame({super.key});
  @override
  State<CupPongGame> createState() => _CupPongGameState();
}

class _CupPongGameState extends State<CupPongGame> with TickerProviderStateMixin, GameTickMixin {
  static const _cupPos = [
    Offset(-40, -10), Offset(0, -10), Offset(40, -10),
    Offset(-20, 30), Offset(20, 30), Offset(0, 70),
  ];
  static const _gravity = 720.0;

  late List<bool> cups;
  late List<double> cupWobble;
  int current = 0;
  Offset ballPos = const Offset(0, 120);
  Offset ballVel = Offset.zero;
  Offset aim = Offset.zero;
  bool simulating = false;
  String message = 'Drag and flick to throw';
  int? winner;
  int flash = 0;
  String? popup;

  @override
  void initState() {
    super.initState();
    cups = List.filled(6, true);
    cupWobble = List.filled(6, 0);
    startTick();
  }

  @override
  void onGameTick(double dt) {
    if (!simulating) return;
    ballVel = Offset(ballVel.dx * 0.998, ballVel.dy + _gravity * dt);
    ballPos += ballVel * dt;
    if (ballPos.dy > 155) {
      _resolveLanding();
      return;
    }
    setState(() {});
  }

  void _resolveLanding() {
    simulating = false;
    tickPaused = true;
    var hit = -1;
    final point = Offset(ballPos.dx, ballPos.dy - 10);
    for (var i = 0; i < _cupPos.length; i++) {
      if (!cups[i]) continue;
      final c = _cupPos[i] + const Offset(0, 40);
      if ((point - c).distance < 34) {
        hit = i;
        break;
      }
    }
    setState(() {
      if (hit >= 0) {
        cups[hit] = false;
        cupWobble[hit] = 1;
        message = 'Splash!';
        popup = 'CUP!';
        flash++;
      } else {
        message = 'Miss — hand off';
        popup = 'MISS';
        current = (current + 1) % context.read<AppState>().playerCount;
      }
      ballPos = const Offset(0, 120);
      ballVel = Offset.zero;
      aim = Offset.zero;
      if (cups.every((c) => !c)) winner = current;
    });
    Future<void>.delayed(const Duration(milliseconds: 420), () {
      if (mounted) setState(() => popup = null);
    });
    tickPaused = false;
  }

  void _reset() {
    setState(() {
      cups = List.filled(6, true);
      cupWobble = List.filled(6, 0);
      current = 0;
      ballPos = const Offset(0, 120);
      ballVel = Offset.zero;
      aim = Offset.zero;
      simulating = false;
      message = 'Drag and flick to throw';
      winner = null;
      popup = null;
    });
  }

  void _throw(Offset velocity) {
    if (simulating || winner != null) return;
    final v = Offset(velocity.dx * 0.06 + aim.dx * 2.4, velocity.dy * 0.06 + aim.dy * 2.4 - 280);
    setState(() {
      simulating = true;
      ballVel = v;
      message = 'In the air…';
      aim = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('CUP PONG')),
      body: Stack(
        children: [
          Column(
            children: [
              TurnBanner(playerIndex: current, message: '${PartyTheme.playerName(current)} · $message'),
              Expanded(
                child: GestureDetector(
                  onPanUpdate: (d) {
                    if (simulating || winner != null) return;
                    setState(() => aim += d.delta * 0.35);
                  },
                  onPanEnd: (d) => _throw(d.velocity.pixelsPerSecond),
                  child: RepaintBoundary(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFB8F0E4), Color(0xFF7CC7B8)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 240,
                            height: 190,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E665E),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                          ),
                          for (var i = 0; i < _cupPos.length; i++)
                            if (cups[i])
                              _CupSprite(
                                offset: _cupPos[i],
                                wobble: cupWobble[i] + sin(DateTime.now().millisecondsSinceEpoch / 180.0 + i) * 0.02,
                              ),
                          Transform.translate(
                            offset: simulating ? ballPos : Offset(ballPos.dx + aim.dx * 0.4, ballPos.dy + aim.dy * 0.2),
                            child: HitFlash(
                              trigger: flash,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black87, width: 2),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3))],
                                ),
                              ),
                            ),
                          ),
                          if (popup != null)
                            Positioned(top: 24, child: FloatingCallout(text: popup!, color: popup == 'CUP!' ? Colors.limeAccent : Colors.orangeAccent)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text('Cups left: ${cups.where((c) => c).length}', style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          if (winner != null)
            ResultOverlay(
              title: '${PartyTheme.playerName(winner!)} wins!',
              detail: 'Cleared the cup triangle.',
              onAgain: _reset,
              onDone: () {
                app.awardWin(winner!);
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }
}

class _CupSprite extends StatelessWidget {
  const _CupSprite({required this.offset, required this.wobble});
  final Offset offset;
  final double wobble;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: Transform.scale(
        scale: 1 + wobble * 0.08,
        child: Container(
          width: 36,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFF5C5C), Color(0xFFCC2222)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(width: 2, color: Colors.white),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2))],
          ),
        ),
      ),
    );
  }
}