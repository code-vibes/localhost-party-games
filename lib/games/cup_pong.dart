import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../theme.dart';
import 'game_router.dart';

class CupPongGame extends StatefulWidget {
  const CupPongGame({super.key});
  @override
  State<CupPongGame> createState() => _CupPongGameState();
}

class _CupPongGameState extends State<CupPongGame> {
  late List<bool> cups;
  int current = 0;
  Offset ball = Offset.zero;
  Offset aim = Offset.zero;
  bool flying = false;
  String message = 'Drag and release to throw';
  int? winner;

  static const cupPos = [
    Offset(-40, -10), Offset(0, -10), Offset(40, -10),
    Offset(-20, 30), Offset(20, 30), Offset(0, 70),
  ];

  @override
  void initState() {
    super.initState();
    cups = List.filled(6, true);
  }

  void _reset() {
    setState(() {
      cups = List.filled(6, true);
      current = 0;
      ball = Offset.zero;
      aim = Offset.zero;
      flying = false;
      message = 'Drag and release to throw';
      winner = null;
    });
  }

  Future<void> _throw(Offset translation) async {
    if (flying || winner != null) return;
    setState(() {
      flying = true;
      message = 'Ball in flight…';
      aim = Offset.zero;
      ball = Offset(translation.dx * 0.9, -180 + translation.dy * 0.2);
    });
    await Future<void>.delayed(const Duration(milliseconds: 550));
    final point = Offset(ball.dx, ball.dy + 160);
    var hit = -1;
    for (var i = 0; i < cupPos.length; i++) {
      if (!cups[i]) continue;
      final c = Offset(cupPos[i].dx, cupPos[i].dy + 40);
      if ((point - c).distance < 38) {
        hit = i;
        break;
      }
    }
    setState(() {
      if (hit >= 0) {
        cups[hit] = false;
        message = 'Cup down!';
      } else {
        message = 'Miss — next player';
        current = (current + 1) % context.read<AppState>().playerCount;
      }
      ball = Offset.zero;
      flying = false;
      if (cups.every((c) => !c)) winner = current;
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
                    if (flying || winner != null) return;
                    setState(() => aim = Offset(d.delta.dx * 0.2 + aim.dx, (aim.dy + d.delta.dy * 0.2).clamp(-80, 0)));
                  },
                  onPanEnd: (d) => _throw(d.velocity.pixelsPerSecond / 8 + aim * 3),
                  child: Container(
                    color: const Color(0xFFD7F2EC),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 220,
                          height: 180,
                          decoration: BoxDecoration(
                            color: const Color(0xFF26736B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                        ),
                        for (var i = 0; i < cupPos.length; i++)
                          if (cups[i])
                            Transform.translate(
                              offset: cupPos[i],
                              child: Container(
                                width: 34,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(width: 2),
                                ),
                              ),
                            ),
                        Transform.translate(
                          offset: Offset(ball.dx + aim.dx, 160 + ball.dy + aim.dy),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(width: 2),
                              boxShadow: const [BoxShadow(blurRadius: 3, offset: Offset(0, 2))],
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
                child: Text('Cups left: ${cups.where((c) => c).length}',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
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
