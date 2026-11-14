import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../theme.dart';
import 'game_router.dart';

class ArcheryGame extends StatefulWidget {
  const ArcheryGame({super.key});
  @override
  State<ArcheryGame> createState() => _ArcheryGameState();
}

class _ArcheryGameState extends State<ArcheryGame> {
  double aimX = 0;
  double aimY = 0;
  double power = 0;
  bool charging = false;
  bool flying = false;
  Offset arrow = Offset.zero;
  int current = 0;
  int round = 0;
  late List<int> scores;
  String lastHit = '';
  bool showResult = false;
  Timer? wobble;
  static const maxRounds = 3;

  @override
  void initState() {
    super.initState();
    scores = [];
    wobble = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (flying || !mounted) return;
      final t = DateTime.now().millisecondsSinceEpoch / 1000;
      setState(() {
        aimX = sin(t * 1.7) * 28;
        aimY = cos(t * 1.3) * 12;
      });
    });
  }

  void _ensureScores(int n) {
    while (scores.length < n) {
      scores.add(0);
    }
  }

  Future<void> _fire() async {
    if (flying) return;
    setState(() {
      charging = false;
      flying = true;
      arrow = const Offset(0, 170);
    });
    final strength = 0.35 + power * 0.65;
    final target = Offset(aimX * (1.2 - strength), -40 + aimY * (1.1 - strength));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    setState(() => arrow = target);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final dist = sqrt(target.dx * target.dx + pow(target.dy + 40, 2));
    var points = 0;
    var hit = 'Miss';
    if (dist < 14) {
      points = 10;
      hit = 'Bullseye! +10';
    } else if (dist < 32) {
      points = 7;
      hit = 'Inner ring +7';
    } else if (dist < 52) {
      points = 4;
      hit = 'White +4';
    } else if (dist < 72) {
      points = 2;
      hit = 'Blue +2';
    }
    final n = context.read<AppState>().playerCount;
    _ensureScores(n);
    setState(() {
      scores[current] += points;
      lastHit = hit;
      power = 0;
    });
    await Future<void>.delayed(const Duration(milliseconds: 550));
    setState(() {
      flying = false;
      if (current + 1 >= n) {
        current = 0;
        round += 1;
        if (round >= maxRounds) showResult = true;
      } else {
        current += 1;
      }
    });
  }

  @override
  void dispose() {
    wobble?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    _ensureScores(app.playerCount);
    final winner = scores.indexOf(scores.reduce(max));
    return Scaffold(
      appBar: AppBar(title: const Text('ARCHERY')),
      body: Stack(
        children: [
          Column(
            children: [
              TurnBanner(
                playerIndex: current,
                message:
                    '${PartyTheme.playerName(current)} · round ${min(round + 1, maxRounds)}/$maxRounds · $lastHit',
              ),
              Expanded(
                child: GestureDetector(
                  onPanUpdate: (_) {
                    if (flying || showResult) return;
                    setState(() {
                      charging = true;
                      power = min(1, power + 0.02);
                    });
                  },
                  onPanEnd: (_) {
                    if (charging) _fire();
                  },
                  child: Container(
                    color: const Color(0xFFE5F5D4),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.translate(
                          offset: Offset(aimX, -40 + aimY),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              _ring(70, Colors.blue.withOpacity(0.25)),
                              _ring(46, Colors.white),
                              _ring(22, Colors.red),
                              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.yellow, shape: BoxShape.circle)),
                            ],
                          ),
                        ),
                        Transform.translate(
                          offset: flying ? arrow : const Offset(0, 170),
                          child: Opacity(
                            opacity: flying ? 1 : 0.35,
                            child: const Icon(Icons.arrow_upward, size: 40),
                          ),
                        ),
                        Positioned(
                          left: 40,
                          right: 40,
                          bottom: 20,
                          child: LinearProgressIndicator(value: power, color: PartyTheme.redPlayer, minHeight: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  scores.isEmpty ? 'Hold to draw, release to fire' : scores.asMap().entries.map((e) => '${PartyTheme.playerName(e.key)}: ${e.value}').join(' · '),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
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
