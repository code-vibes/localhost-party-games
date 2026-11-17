import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../theme.dart';
import 'engine/game_tick.dart';
import 'engine/juice.dart';
import 'game_router.dart';

class BrainrotStackGame extends StatefulWidget {
  const BrainrotStackGame({super.key});
  @override
  State<BrainrotStackGame> createState() => _BrainrotStackGameState();
}

class _BrainrotStackGameState extends State<BrainrotStackGame> with TickerProviderStateMixin, GameTickMixin {
  final bits = ['☕', '🛞', '🪿', '🐸', '📦', '🧢', '🍌', '🗿'];
  final layers = <_Layer>[];
  double slider = 0;
  double direction = 1;
  double dropY = -80;
  bool dropping = false;
  int current = 0;
  final scores = <int>[];
  bool showResult = false;
  int flash = 0;

  @override
  void initState() {
    super.initState();
    startTick();
    _start();
  }

  void _start() {
    layers.clear();
    slider = 0;
    direction = 1;
    dropY = -80;
    dropping = false;
  }

  @override
  void onGameTick(double dt) {
    if (!dropping) {
      slider += direction * 155 * dt;
      if (slider.abs() > 120) direction *= -1;
    } else {
      dropY += 480 * dt;
      if (dropY >= 0) {
        dropping = false;
        _commitDrop();
      }
    }
    setState(() {});
  }

  void _drop() {
    if (dropping) return;
    setState(() {
      dropping = true;
      dropY = -30;
    });
  }

  void _commitDrop() {
    final width = (140 - layers.length * 8).clamp(48, 140).toDouble();
    final baseX = layers.isEmpty ? 0.0 : layers.last.x;
    if (layers.isNotEmpty && (slider - baseX).abs() > width * 0.55) {
      _finish();
      return;
    }
    flash++;
    layers.add(_Layer(bits[layers.length % bits.length], width, slider, Colors.primaries[layers.length % Colors.primaries.length]));
    dropY = -80;
    if (layers.length >= 10) _finish();
    setState(() {});
  }

  void _finish() {
    while (scores.length <= current) {
      scores.add(0);
    }
    scores[current] = layers.length;
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
    final winner = scores.isEmpty ? 0 : scores.indexOf(scores.reduce((a, b) => a > b ? a : b));
    return Scaffold(
      appBar: AppBar(title: const Text('BRAINROT STACK')),
      body: Stack(
        children: [
          Column(
            children: [
              TurnBanner(playerIndex: current, message: '${PartyTheme.playerName(current)} · drop the brainrot'),
              Expanded(
                child: GestureDetector(
                  onTap: _drop,
                  child: RepaintBoundary(
                    child: Container(
                    color: const Color(0xFFE6E9FF),
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Positioned(bottom: 40, child: Container(width: 160, height: 16, color: Colors.green)),
                        ...layers.reversed.toList().asMap().entries.map((e) {
                          final i = layers.length - 1 - e.key;
                          final layer = layers[i];
                          return Positioned(
                            bottom: 60.0 + i * 38,
                            left: 0,
                            right: 0,
                            child: Transform.translate(
                              offset: Offset(layer.x, 0),
                              child: Center(
                                child: Container(
                                  width: layer.width,
                                  height: 34,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: layer.color.withOpacity(0.85),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(width: 2),
                                  ),
                                  child: Text(layer.emoji, style: const TextStyle(fontSize: 22)),
                                ),
                              ),
                            ),
                          );
                        }),
                        Positioned(
                          top: 50 + dropY,
                          left: 0,
                          right: 0,
                          child: Transform.translate(
                            offset: Offset(slider, 0),
                            child: Center(
                              child: HitFlash(
                                trigger: flash,
                                child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(width: 2),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6)],
                                ),
                                child: Text(bits[layers.length % bits.length], style: const TextStyle(fontSize: 32)),
                              ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text('Height ${layers.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
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

class _Layer {
  _Layer(this.emoji, this.width, this.x, this.color);
  final String emoji;
  final double width;
  final double x;
  final Color color;
}
