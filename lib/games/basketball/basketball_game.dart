import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/play_mode.dart';
import '../../theme.dart';
import '../engine/game_tick.dart';
import '../engine/juice.dart';
import '../game_router.dart';
import 'ball_sim.dart';
import 'court_painter.dart';

class BasketballGame extends StatefulWidget {
  const BasketballGame({super.key});
  @override
  State<BasketballGame> createState() => _BasketballGameState();
}

class _BasketballGameState extends State<BasketballGame> with TickerProviderStateMixin, GameTickMixin {
  static const _cpu = 1;
  static const _maxScore = 7;
  static const _shotClockMax = 24.0;

  final rng = Random();
  final sim = BallSim();
  final scores = <int>[];

  int current = 0;
  bool showResult = false;
  int flash = 0;
  String? popup;
  double shotClock = _shotClockMax;
  double hoopX = 0;
  double hoopPhase = 0;
  double netWave = 0;
  double netBurst = 0;
  double cameraZoom = 1;
  double ballSpin = 0;

  Offset dragStart = Offset.zero;
  Offset dragPull = Offset.zero;
  bool dragging = false;
  List<Vec3> previewArc = const [];

  bool get vsCpu {
    final app = context.read<AppState>();
    return app.playMode == PlayMode.solo || app.playerCount == 1;
  }

  int get players => vsCpu ? 2 : context.read<AppState>().playerCount;

  @override
  void initState() {
    super.initState();
    startTick();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resetMatch());
  }

  void _resetMatch() {
    scores
      ..clear()
      ..addAll(List.filled(players, 0));
    current = 0;
    showResult = false;
    _resetPossession();
    if (vsCpu && current == _cpu) _scheduleCpu();
  }

  void _resetPossession() {
    sim.reset();
    dragPull = Offset.zero;
    dragging = false;
    previewArc = const [];
    popup = null;
    netBurst = 0;
    shotClock = _shotClockMax;
    ballSpin = 0;
  }

  @override
  void onGameTick(double dt) {
    hoopPhase += dt;
    hoopX = sin(hoopPhase * 0.85) * 0.9;
    if (netBurst > 0) {
      netBurst = max(0, netBurst - dt * 1.7);
      netWave += dt * 16;
    } else {
      netWave += dt * 2;
    }
    if (cameraZoom > 1) cameraZoom = max(1, cameraZoom - dt * 1.1);

    if (!sim.live && !showResult && current != _cpu && !dragging) {
      shotClock -= dt;
      if (shotClock <= 0) _onShot(ShotEvent.miss());
    }

    if (sim.live) {
      for (var i = 0; i < 3; i++) {
        final ev = sim.step(hoopX);
        if (ev != null) {
          _onShot(ev);
          break;
        }
      }
      ballSpin = sim.spin;
    }

    if (dragging) {
      previewArc = sim.predictArc(dragPull, Offset(-dragPull.dx * 8, -dragPull.dy * 8), hoopX);
    }

    if (mounted) setState(() {});
  }

  void _onShot(ShotEvent ev) {
    switch (ev.kind) {
      case ShotKind.scored:
        while (scores.length <= current) scores.add(0);
        scores[current]++;
        flash++;
        netBurst = 1;
        cameraZoom = 1.06;
        popup = ev.bank ? 'BANK!' : 'SWISH!';
        if (scores[current] >= _maxScore) {
          showResult = true;
          return;
        }
        _handoff();
      case ShotKind.rim:
        popup = 'RIM!';
        flash++;
        return;
      case ShotKind.miss:
        if (popup == null) popup = 'MISS';
        if (!sim.live) _handoff();
        return;
    }
  }

  void _handoff() {
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (!mounted || showResult) return;
      _resetPossession();
      current = (current + 1) % players;
      setState(() {});
      if (vsCpu && current == _cpu) _scheduleCpu();
    });
  }

  void _scheduleCpu() {
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted || showResult || sim.live || current != _cpu) return;
      sim.launchCpu(rng, hoopX);
    });
  }

  void _onPanStart(DragStartDetails d) {
    if (sim.live || showResult || (vsCpu && current == _cpu)) return;
    dragStart = d.localPosition;
    dragging = true;
    dragPull = Offset.zero;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (!dragging) return;
    dragPull = d.localPosition - dragStart;
    previewArc = sim.predictArc(dragPull, Offset.zero, hoopX);
  }

  void _onPanEnd(DragEndDetails d) {
    if (!dragging || sim.live) return;
    sim.launchFromSwipe(dragPull, d.velocity.pixelsPerSecond);
    dragging = false;
    previewArc = const [];
    popup = null;
    ballSpin = sim.spin;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    while (scores.length < players) scores.add(0);
    final winner = scores.isEmpty ? 0 : scores.indexOf(scores.reduce(max));
    final title = vsCpu ? 'BASKETBALL · VS CPU' : 'BASKETBALL HOOPS';
    final winLabel = vsCpu ? (winner == 0 ? 'You beat CPU!' : 'CPU wins') : '${PartyTheme.playerName(winner)} wins!';

    final ball = Vec3(sim.x, sim.y, sim.z);

    return Scaffold(
      backgroundColor: const Color(0xFF7AB8DC),
      appBar: AppBar(title: Text(title)),
      body: Stack(
        children: [
          Column(
            children: [
              TurnBanner(
                playerIndex: current,
                message: vsCpu
                    ? '${current == 0 ? "YOU" : "CPU"} · first to $_maxScore · ${scores[0]}-${scores.length > 1 ? scores[1] : 0}'
                    : '${PartyTheme.playerName(current)} · pull back & flick',
              ),
              Expanded(
                child: Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (e) => _onPanStart(DragStartDetails(globalPosition: e.position, localPosition: e.localPosition)),
                  onPointerMove: (e) {
                    if (dragging) {
                      _onPanUpdate(DragUpdateDetails(globalPosition: e.position, localPosition: e.localPosition, delta: e.delta));
                    }
                  },
                  onPointerUp: (e) => _onPanEnd(DragEndDetails(velocity: Velocity.zero, primaryVelocity: 0)),
                  child: RepaintBoundary(
                    child: Transform.scale(
                      scale: cameraZoom,
                      child: CustomPaint(
                        painter: CourtPainter(
                          hoopX: hoopX,
                          netWave: netWave,
                          netBurst: netBurst,
                          shotClock: shotClock.ceil().clamp(0, 99),
                          ball: ball,
                          ballLive: sim.live,
                          previewArc: previewArc,
                          aimPull: dragging ? dragPull : null,
                          spin: ballSpin,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
              if (dragging)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (dragPull.distance / 140).clamp(0, 1),
                            minHeight: 12,
                            color: const Color(0xFFE04D3A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('${dragPull.distance.toInt()}', style: const TextStyle(fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  vsCpu ? 'YOU ${scores[0]} · CPU ${scores.length > 1 ? scores[1] : 0}' : 'Pts ${scores[current]}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          if (popup != null)
            Positioned(
              top: 64,
              left: 0,
              right: 0,
              child: Center(child: FloatingCallout(text: popup!, color: const Color(0xFFFFB347))),
            ),
          if (showResult)
            ResultOverlay(
              title: winLabel,
              detail: vsCpu ? 'Final ${scores[0]} – ${scores[1]}' : scores.asMap().entries.map((e) => '${PartyTheme.playerName(e.key)}: ${e.value}').join(' · '),
              onAgain: () {
                setState(() => showResult = false);
                _resetMatch();
              },
              onDone: () {
                if (!vsCpu) app.awardWin(winner);
                else if (winner == 0) app.awardWin(0);
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }
}