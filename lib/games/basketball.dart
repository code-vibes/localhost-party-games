import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../theme.dart';
import 'game_router.dart';

class BasketballGame extends StatefulWidget {
  const BasketballGame({super.key});
  @override
  State<BasketballGame> createState() => _BasketballGameState();
}

class _BasketballGameState extends State<BasketballGame> {
  final scores = <int>[];
  int current = 0;
  double timeLeft = 12;
  Offset ball = Offset.zero;
  bool flying = false;
  double hoopX = 0;
  bool showResult = false;
  Timer? timer;
  Timer? hoopTimer;
  final rng = Random();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startTurn());
  }

  void _startTurn() {
    while (scores.length <= current) {
      scores.add(0);
    }
    timeLeft = 12;
    ball = Offset.zero;
    flying = false;
    timer?.cancel();
    hoopTimer?.cancel();
    timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() {
        timeLeft -= 0.1;
        if (timeLeft <= 0) {
          timer?.cancel();
          hoopTimer?.cancel();
          _endTurn();
        }
      });
    });
    hoopTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (!mounted) return;
      setState(() => hoopX = rng.nextDouble() * 220 - 110);
    });
  }

  Future<void> _shoot(Offset translation) async {
    if (flying || timeLeft <= 0) return;
    setState(() {
      flying = true;
      ball = Offset(translation.dx * 0.8 + hoopX * 0.2, -260 + min(0, translation.dy));
    });
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final dx = ball.dx - hoopX;
    final dy = (150 + ball.dy) + 80;
    if (dx.abs() < 36 && dy.abs() < 50) {
      setState(() => scores[current] += 1);
    }
    setState(() {
      ball = Offset.zero;
      flying = false;
    });
  }

  void _endTurn() {
    if (current + 1 >= context.read<AppState>().playerCount) {
      setState(() => showResult = true);
    } else {
      setState(() => current += 1);
      _startTurn();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    hoopTimer?.cancel();
    super.dispose();
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
              TurnBanner(
                playerIndex: current,
                message: '${PartyTheme.playerName(current)} · swipe up · ${timeLeft.ceil()}s',
              ),
              Expanded(
                child: GestureDetector(
                  onPanEnd: (d) => _shoot(d.velocity.pixelsPerSecond / 10),
                  child: Container(
                    color: const Color(0xFFE8F0FF),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.translate(
                          offset: Offset(hoopX, -80),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 90, height: 54, color: Colors.red),
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.orange, width: 6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Transform.translate(
                          offset: Offset(ball.dx, 150 + ball.dy),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black54, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Text('Score ${scores.length > current ? scores[current] : 0}',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
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
